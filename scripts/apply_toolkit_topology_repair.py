"""One-shot Fulcrum Toolkit topology migration.

Concurrency contract: this migration serializes with cooperating Toolkit writers
that honor `.SNL_Doc/.data-write.lock`. A same-UID process that deliberately
renames private mode-0700 staging dirents or lock inodes is outside the contract;
such a process already has arbitrary write authority over the repository. The
transaction avoids pathname-based recursive deletion and retains ambiguous
states, but does not claim containment against a malicious same-UID namespace
adversary.
"""

#!/usr/bin/env python3
from __future__ import annotations

if not __debug__:
    raise RuntimeError("Toolkit topology repair must run without Python optimization")

import ctypes
import hashlib
import json
import os
import shutil
import socket
import tempfile
import uuid
from datetime import datetime, timezone
from pathlib import Path

from verify_toolkit_topology import (
    EXPECTED_CANONICAL_TREE_DIGEST,
    assert_document_tree,
    manifest_digest,
    scan_document_tree,
    validate_document_manifest,
    validate_repair_authority,
    verify,
)

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / ".SNL_Doc"


def _strict_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError(f"duplicate JSON key: {key}")
        value[key] = item
    return value


def _reject_constant(value: str):
    raise ValueError(f"non-finite JSON constant: {value}")


def load(path: Path):
    return json.loads(
        path.read_text(encoding="utf-8"),
        object_pairs_hook=_strict_object,
        parse_constant=_reject_constant,
    )


def write(path: Path, value) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def node_id_for(entry_id: str) -> str:
    return "n_sub_" + hashlib.sha256(("snl-subentry\0" + entry_id).encode("utf-8")).hexdigest()[:12]


def add_schema_version(path: Path, expected_format: str, expected_schema: int) -> bool:
    value = load(path)
    assert value.get("format") == expected_format and value.get("version") == 1, path
    if value.get("schema_version") == expected_schema:
        return False
    assert "schema_version" not in value, path
    updated = {}
    for key, item in value.items():
        updated[key] = item
        if key == "version":
            updated["schema_version"] = expected_schema
    assert updated.get("schema_version") == expected_schema
    write(path, updated)
    return True


def repair_graphs(doc: Path, authority: dict) -> int:
    repairs = 0
    for graph_path in sorted((doc / "libraries").glob("*/graph.json")):
        graph = load(graph_path)
        repairs_before_graph = repairs
        nodes = graph["nodes"]
        relationships = graph["relationships"]
        node_by_id = {node["id"]: node for node in nodes}

        exact_parent = authority["exact_parent"]
        target_ids = {
            node["id"] for node in nodes
            if node.get("props", {}).get("entryId") == exact_parent["entry_id"]
        }
        canonical_parent_ids = {
            node["id"] for node in nodes
            if node.get("props", {}).get("entryId") == exact_parent["parent_entry_id"]
        }
        if target_ids and canonical_parent_ids:
            filtered = [
                relation for relation in relationships
                if not (
                    relation.get("label") == "branch"
                    and relation.get("to") in target_ids
                    and relation.get("from") not in canonical_parent_ids
                )
            ]
            repairs += len(relationships) - len(filtered)
            relationships[:] = filtered

        assert authority["deduplicate_relationships"] is True
        deduplicated_relationships = []
        for relation in relationships:
            if relation not in deduplicated_relationships:
                deduplicated_relationships.append(relation)
        if deduplicated_relationships != relationships:
            repairs += len(relationships) - len(deduplicated_relationships)
            relationships[:] = deduplicated_relationships

        # Reused parent Entries need distinct child occurrences, not a shared
        # child node with two incoming branch edges.
        for child_node in list(nodes):
            incoming = [
                relation for relation in relationships
                if relation.get("label") == "branch" and relation.get("to") == child_node["id"]
            ]
            if len(incoming) <= 1:
                continue
            parent_entry_ids = {
                node_by_id[relation["from"]].get("props", {}).get("entryId")
                for relation in incoming
            }
            duplicate_spec = authority["duplicate_children_per_parent_occurrence"]
            child_entry_id = child_node.get("props", {}).get("entryId")
            assert parent_entry_ids == {duplicate_spec["parent_entry_id"]}, f"ambiguous multi-parent graph node: {graph_path}:{child_node['id']}"
            assert child_entry_id in duplicate_spec["entry_ids"], f"unapproved repeated child occurrence: {graph_path}:{child_node['id']}"
            for relation in incoming[1:]:
                duplicate_id = node_id_for(f'{child_node["props"]["entryId"]}@{relation["from"]}')
                duplicate = {
                    "id": duplicate_id,
                    "label": child_node["label"],
                    "props": dict(child_node["props"]),
                }
                existing = next((node for node in nodes if node["id"] == duplicate_id), None)
                if existing is None:
                    nodes.append(duplicate)
                    node_by_id[duplicate_id] = duplicate
                else:
                    assert existing == duplicate
                relation["to"] = duplicate_id
                repairs += 1
        if repairs != repairs_before_graph:
            write(graph_path, graph)
    return repairs


def transform(doc: Path) -> dict[str, int]:
    authority = load(ROOT / "scripts" / "toolkit-topology-repair.json")
    validate_repair_authority(authority)
    entry_schema = sum(add_schema_version(path, "snl-entry", authority["entry_schema_version"]) for path in sorted((doc / "entries").glob("*.json")))
    macro_schema = sum(add_schema_version(path, "snl-macro", authority["macro_schema_version"]) for path in sorted((doc / "macros").glob("*.json")))

    style_renames = 0
    kind_repairs = 0
    for path in sorted((doc / "macros").glob("*.json")):
        envelope = load(path)
        macro = envelope["macro"]
        changed = False
        kind_spec = authority["macro_kind_renames"].get(macro.get("name"))
        if kind_spec and macro.get("kind") == kind_spec["from"]:
            macro["kind"] = kind_spec["to"]
            kind_repairs += 1
            changed = True
        style_migrations = authority["style_renames"]
        for style in macro.get("styles", []):
            old_name = style.get("style_name")
            if old_name in style_migrations:
                style["style_name"] = style_migrations[old_name]
                style_renames += 1
                changed = True
        if changed:
            write(path, envelope)

    payload_repairs = 0
    by_name = {}
    for path in sorted((doc / "macros").glob("*.json")):
        envelope = load(path)
        by_name[envelope["macro"]["name"]] = (path, envelope)
    for spec in authority["macro_payload_updates"]:
        path, envelope = by_name[spec["name"]]
        assert envelope["package"] == spec["package"]
        current = envelope["macro"]
        current_hash = hashlib.sha256(json.dumps(current, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        canonical_hash = hashlib.sha256(json.dumps(spec["canonical"], ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        assert current_hash in {*spec["accepted_predecessor_hashes"], canonical_hash}, f"Macro payload repair drift: {spec['name']}"
        if json.dumps(current, ensure_ascii=False, separators=(",", ":")) != json.dumps(spec["canonical"], ensure_ascii=False, separators=(",", ":")):
            envelope["macro"] = spec["canonical"]
            write(path, envelope)
            payload_repairs += 1

    entry_payload_repairs = 0
    entries_by_id = {}
    for path in sorted((doc / "entries").glob("*.json")):
        envelope = load(path)
        entries_by_id[envelope["entry"]["id"]] = (path, envelope)
    for spec in authority["entry_payload_updates"]:
        path, envelope = entries_by_id[spec["id"]]
        assert envelope["package"] == spec["package"]
        current = envelope["entry"]
        current_hash = hashlib.sha256(json.dumps(current, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        canonical_hash = hashlib.sha256(json.dumps(spec["canonical"], ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        assert current_hash in {*spec["accepted_predecessor_hashes"], canonical_hash}, f"Entry payload repair drift: {spec['id']}"
        if json.dumps(current, ensure_ascii=False, separators=(",", ":")) != json.dumps(spec["canonical"], ensure_ascii=False, separators=(",", ":")):
            envelope["entry"] = spec["canonical"]
            write(path, envelope)
            entry_payload_repairs += 1

    config_path = doc / "config.json"
    config = load(config_path)
    legacy_entries = load(doc / "entries.json")
    assert len(legacy_entries) == authority["legacy_entry_count"]
    config["entity_storage"]["receipt"]["entry_count"] = authority["legacy_entry_count"]
    macro_kinds = config["macro_kinds"]
    configured_kind_spec = next(iter(authority["macro_kind_renames"].values()))
    old_kinds = [item for item in macro_kinds if item.get("id") == configured_kind_spec["from"]]
    new_kinds = [item for item in macro_kinds if item.get("id") == configured_kind_spec["to"]]
    if old_kinds:
        assert len(old_kinds) == 1 and not new_kinds
        old_kinds[0]["id"] = configured_kind_spec["to"]
        old_kinds[0]["name"] = "Subtree"
        old_kinds[0]["description"] = "Helper subtree that is not a complete syntactic node and should not attract independent interaction."
    else:
        assert len(new_kinds) == 1
    write(config_path, config)

    for library_id, metadata in authority["library_metadata"].items():
        meta_path = doc / "libraries" / library_id / "meta.json"
        if meta_path.exists():
            assert load(meta_path) == metadata
        else:
            write(meta_path, metadata)

    graph_repairs = repair_graphs(doc, authority)
    verify(doc)
    return {
        "entry_schema_repairs": entry_schema,
        "macro_schema_repairs": macro_schema,
        "style_renames": style_renames,
        "kind_repairs": kind_repairs,
        "payload_repairs": payload_repairs,
        "entry_payload_repairs": entry_payload_repairs,
        "graph_repairs": graph_repairs,
    }


def renameat2(source_dir_fd: int, source_name: str, target_dir_fd: int, target_name: str, flags: int) -> None:
    libc = ctypes.CDLL(None, use_errno=True)
    function = getattr(libc, "renameat2", None)
    if function is None:
        raise RuntimeError("renameat2 is required for atomic Toolkit topology publication")
    function.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    function.restype = ctypes.c_int
    result = function(source_dir_fd, os.fsencode(source_name), target_dir_fd, os.fsencode(target_name), flags)
    if result != 0:
        errno = ctypes.get_errno()
        raise OSError(errno, os.strerror(errno))


def exchange_entries(source_dir_fd: int, source_name: str, target_dir_fd: int, target_name: str) -> None:
    renameat2(source_dir_fd, source_name, target_dir_fd, target_name, 2)  # RENAME_EXCHANGE


def move_noreplace(source_dir_fd: int, source_name: str, target_dir_fd: int, target_name: str) -> None:
    renameat2(source_dir_fd, source_name, target_dir_fd, target_name, 1)  # RENAME_NOREPLACE


def document_manifest(doc: Path, *, allow_writer_lock: bool = False) -> dict[str, str]:
    files, _ = scan_document_tree(doc, allow_writer_lock=allow_writer_lock)
    return files


def acquire_writer_lock() -> tuple[int, str]:
    lock_path = DOC / ".data-write.lock"
    token = str(uuid.uuid4())
    record = {
        "version": 1,
        "pid": os.getpid(),
        "hostname": socket.gethostname(),
        "token": token,
        "purpose": "toolkit-topology-repair",
        "createdAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }
    try:
        descriptor = os.open(lock_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError as error:
        raise RuntimeError(f"SNL workspace data is locked: {lock_path}") from error
    try:
        if os.environ.get("SNL_TEST_SUBSTITUTE_INITIAL_LOCK_ON_WRITE_FAILURE") == "1":
            owned = DOC / ".owned-initial-lock"
            lock_path.rename(owned)
            lock_path.write_text("unrelated replacement\n")
            raise OSError("injected initial lock write failure after substitution")
        if os.environ.get("SNL_TEST_FAIL_INITIAL_LOCK_WRITE") == "1":
            raise OSError("injected initial lock write failure")
        os.write(descriptor, (json.dumps(record, separators=(",", ":")) + "\n").encode())
        os.fsync(descriptor)
    except BaseException as error:
        os.close(descriptor)
        # Never unlink a reusable pathname after a failed write: it may no
        # longer name the inode created above. Retain the lock state so a human
        # can inspect/recover it without losing either inode.
        raise RuntimeError(f"writer-lock initialization failed; retained lock state at {lock_path}") from error
    return descriptor, token


def same_inode(left: os.stat_result, right: os.stat_result) -> bool:
    return (left.st_dev, left.st_ino) == (right.st_dev, right.st_ino)


def emergency_lock(directory_fd: int, token: str) -> None:
    record = {
        "version": 1,
        "pid": os.getpid(),
        "hostname": socket.gethostname(),
        "token": token,
        "purpose": "toolkit-topology-repair-recovery",
        "createdAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }
    try:
        descriptor = os.open(
            ".data-write.lock",
            os.O_WRONLY | os.O_CREAT | os.O_EXCL,
            0o600,
            dir_fd=directory_fd,
        )
    except FileExistsError:
        return
    try:
        os.write(descriptor, (json.dumps(record, separators=(",", ":")) + "\n").encode())
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def move_owned_lock(
    source_doc_fd: int,
    target_dir_fd: int,
    target_name: str,
    lock_fd: int,
    token: str,
) -> int:
    expected = os.fstat(lock_fd)
    move_noreplace(source_doc_fd, ".data-write.lock", target_dir_fd, target_name)
    observed = os.stat(target_name, dir_fd=target_dir_fd, follow_symlinks=False)
    if not same_inode(expected, observed):
        emergency_lock(source_doc_fd, token)
        raise RuntimeError("writer-lock inode changed during descriptor-bound release")
    os.close(lock_fd)
    return -1


def close_quietly(descriptor: int) -> None:
    if descriptor >= 0:
        try:
            os.close(descriptor)
        except OSError:
            pass


def zero_result() -> dict[str, int]:
    return {
        "entry_schema_repairs": 0,
        "macro_schema_repairs": 0,
        "style_renames": 0,
        "kind_repairs": 0,
        "payload_repairs": 0,
        "entry_payload_repairs": 0,
        "graph_repairs": 0,
    }


def emit_nonfatal(payload: str) -> None:
    try:
        if os.environ.get("SNL_TEST_BROKEN_OUTPUT") == "1":
            raise BrokenPipeError("injected broken output channel after commit")
        print(payload, flush=True)
    except OSError:
        # Publication has committed. A broken output channel must not turn the
        # durable result into a reported transaction failure.
        try:
            import sys
            sys.stdout = open(os.devnull, "w")
        except OSError:
            pass


def main() -> None:
    authority = load(ROOT / "scripts" / "toolkit-topology-repair.json")
    validate_repair_authority(authority)
    manifest_authority = load(ROOT / "scripts" / "fulcrum-doc-manifest.json")
    validate_document_manifest(manifest_authority)
    canonical = manifest_authority["canonical_files"]
    assert manifest_digest(canonical) == EXPECTED_CANONICAL_TREE_DIGEST, "independent canonical tree digest drift"

    # This is a one-shot owning migration, not a general verifier. Refusing an
    # already-canonical tree is the only zero-write result compatible with the
    # Toolkit's create/unlink lock protocol: claiming PASS without taking that
    # lock would race a cooperating writer, while taking it is not read-only.
    lock_path = DOC / ".data-write.lock"
    if lock_path.exists():
        raise RuntimeError(f"SNL workspace data is locked: {lock_path}")
    if document_manifest(DOC) == canonical:
        assert_document_tree(DOC, canonical)
        verify(DOC)
        raise RuntimeError("Toolkit topology is already canonical; no migration was performed")

    parent_fd = os.open(DOC.parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    staged_root = Path(tempfile.mkdtemp(prefix=".SNL_Doc-toolkit-repair-", dir=DOC.parent))
    staged_root_fd = os.open(staged_root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    vault = staged_root / "lock-vault"
    vault.mkdir(mode=0o700)
    vault_fd = os.open(vault, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    descriptor = -1
    old_doc_fd = -1
    new_doc_fd = -1
    copied_lock_fd = -1
    exchanged = False
    committed = False
    try:
        descriptor, token = acquire_writer_lock()
        old_doc_fd = os.open(DOC, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        source_manifest = document_manifest(DOC, allow_writer_lock=True)
        matching_predecessors = [
            manifest for manifest in authority["predecessor_manifests"].values()
            if manifest == source_manifest
        ]
        assert len(matching_predecessors) == 1, "unrecognized complete Toolkit topology predecessor"
        assert_document_tree(DOC, matching_predecessors[0], allow_writer_lock=True)

        staged = staged_root / ".SNL_Doc"
        shutil.copytree(DOC, staged, ignore=shutil.ignore_patterns(".data-write.lock"))
        result = transform(staged)
        assert_document_tree(staged, canonical)
        shutil.copy2(DOC / ".data-write.lock", staged / ".data-write.lock")
        new_doc_fd = os.open(staged, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        copied_lock_fd = os.open(".data-write.lock", os.O_RDONLY | os.O_NOFOLLOW, dir_fd=new_doc_fd)
        os.fsync(copied_lock_fd)
        if os.environ.get("SNL_TEST_FAIL_BEFORE_EXCHANGE") == "1":
            raise RuntimeError("injected failure before atomic Toolkit publication")

        old_identity = os.fstat(old_doc_fd)
        new_identity = os.fstat(new_doc_fd)
        exchange_entries(parent_fd, ".SNL_Doc", staged_root_fd, ".SNL_Doc")
        exchanged = True
        assert same_inode(os.stat(".SNL_Doc", dir_fd=parent_fd, follow_symlinks=False), new_identity)
        assert same_inode(os.stat(".SNL_Doc", dir_fd=staged_root_fd, follow_symlinks=False), old_identity)
        assert_document_tree(DOC, canonical, allow_writer_lock=True)
        verify(DOC, allow_writer_lock=True)
        if os.environ.get("SNL_TEST_FAIL_AFTER_EXCHANGE") == "1":
            raise RuntimeError("injected failure after atomic Toolkit publication")

        if os.environ.get("SNL_TEST_REPLACE_STAGE_PATH_AFTER_EXCHANGE") == "1":
            owned_location = Path(str(staged_root) + ".owned")
            staged_root.rename(owned_location)
            staged_root.mkdir(mode=0o700)
            (staged_root / "unrelated").write_text("must not be removed\n")
        assert same_inode(os.stat(staged_root, follow_symlinks=False), os.fstat(staged_root_fd)), "retained predecessor root pathname changed"
        assert same_inode(os.stat(".SNL_Doc", dir_fd=staged_root_fd, follow_symlinks=False), old_identity), "retained predecessor entry changed"

        output = json.dumps({
            "status": "PASS",
            **result,
            "retained_predecessor": str(staged_root / ".SNL_Doc"),
        }, ensure_ascii=False)
        # Descriptor-bound no-replace move is the commit point. It removes the
        # successor's visible lock without unlinking any pathname. The complete
        # predecessor and both lock records remain retained for audit/recovery.
        assert same_inode(os.stat(".SNL_Doc", dir_fd=parent_fd, follow_symlinks=False), new_identity)
        if os.environ.get("SNL_TEST_SUBSTITUTE_LOCK_BEFORE_COMMIT") == "1":
            os.rename(
                ".data-write.lock",
                ".attacker-moved-lock",
                src_dir_fd=new_doc_fd,
                dst_dir_fd=new_doc_fd,
            )
            unrelated = os.open(
                ".data-write.lock",
                os.O_WRONLY | os.O_CREAT | os.O_EXCL,
                0o600,
                dir_fd=new_doc_fd,
            )
            os.write(unrelated, b"unrelated replacement\n")
            os.close(unrelated)
        copied_lock_fd = move_owned_lock(
            new_doc_fd,
            vault_fd,
            f"released-successor-lock-{token}",
            copied_lock_fd,
            token,
        )
        committed = True
        close_quietly(descriptor)
        descriptor = -1
        emit_nonfatal(output)
        return
    except BaseException as primary_error:
        if not exchanged and descriptor >= 0:
            try:
                descriptor = move_owned_lock(
                    old_doc_fd,
                    vault_fd,
                    f"released-source-lock-{token}",
                    descriptor,
                    token,
                )
            except BaseException as release_error:
                raise ExceptionGroup(
                    "Toolkit migration failed and descriptor-bound lock release also failed",
                    [primary_error, release_error],
                )
        # Once exchange occurs there is no pathname-CAS primitive strong enough
        # for an automatic rollback against same-user namespace substitution.
        # Preserve the locked successor and predecessor for explicit recovery.
        raise
    finally:
        close_quietly(copied_lock_fd)
        close_quietly(descriptor)
        close_quietly(new_doc_fd)
        close_quietly(old_doc_fd)
        close_quietly(vault_fd)
        close_quietly(staged_root_fd)
        close_quietly(parent_fd)


if __name__ == "__main__":
    main()
