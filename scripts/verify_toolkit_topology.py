#!/usr/bin/env python3
from __future__ import annotations

if not __debug__:
    raise RuntimeError("Toolkit topology verification requires assertions")

import hashlib
import json
import os
import re
import stat
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / ".SNL_Doc"
STYLE_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


HEX64 = re.compile(r"[0-9a-f]{64}")
EXPECTED_CANONICAL_TREE_DIGEST = "d4ced20872746e76a5653c364e9799989c65b620903f7c68b15fafc08975ea00"
EXPECTED_REPAIR_AUTHORITY_DIGEST = "0562d0feea947ba8288289274b959ba6d381441b72c9707304d653876087eb13"
EXPECTED_DOCUMENT_MANIFEST_DIGEST = "7dc7f31cd37b75ae2000e166391cdfd624560f520ee351125d64b8aa490cbe88"
CRITICAL_MACRO_HASHES = {
    "Topology.mapLimit": "9b1cdcd05a7d478c018ada52e99056a5c4c1428adf91095e75cd3a4b990d7dc8",
}
CRITICAL_ENTRY_HASHES = {
    "Lambda.def.eta": "bcae420051c42f6cffd70cac4b9b15f2e8951866b72b37b7a0229151211cdac5",
}


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


def payload_hash(value) -> str:
    raw = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode()).hexdigest()


def manifest_digest(manifest: dict[str, str]) -> str:
    raw = "".join(f"{path}\0{digest}\n" for path, digest in sorted(manifest.items()))
    return hashlib.sha256(raw.encode()).hexdigest()


def validate_document_manifest(manifest) -> None:
    assert type(manifest) is dict and set(manifest) == {"version", "source_commit", "source_files", "canonical_files"}
    assert type(manifest["version"]) is int and manifest["version"] == 1
    assert type(manifest["source_commit"]) is str and re.fullmatch(r"[0-9a-f]{40}", manifest["source_commit"])
    for field in ("source_files", "canonical_files"):
        files = manifest[field]
        assert type(files) is dict and files
        assert all(
            type(path) is str and path.startswith(".SNL_Doc/")
            and type(digest) is str and HEX64.fullmatch(digest)
            for path, digest in files.items()
        )
    assert payload_hash(manifest) == EXPECTED_DOCUMENT_MANIFEST_DIGEST, "document manifest authority drift"


def expected_directories(files: dict[str, str]) -> set[str]:
    directories: set[str] = set()
    for name in files:
        for parent in Path(name).parents:
            text = str(parent)
            if text.startswith(".SNL_Doc/"):
                directories.add(text)
    return directories


def scan_document_tree(doc: Path, *, allow_writer_lock: bool = False) -> tuple[dict[str, str], set[str]]:
    files: dict[str, str] = {}
    directories: set[str] = set()
    pending = [doc]
    while pending:
        directory = pending.pop()
        with os.scandir(directory) as entries:
            for entry in entries:
                path = Path(entry.path)
                relative = str(Path(".SNL_Doc") / path.relative_to(doc))
                mode = entry.stat(follow_symlinks=False).st_mode
                if stat.S_ISLNK(mode):
                    raise AssertionError(f"symlink is not allowed in canonical document: {relative}")
                if stat.S_ISDIR(mode):
                    directories.add(relative)
                    pending.append(path)
                elif stat.S_ISREG(mode):
                    if relative == ".SNL_Doc/.data-write.lock" and allow_writer_lock:
                        continue
                    files[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
                else:
                    raise AssertionError(f"special inode is not allowed in canonical document: {relative}")
    return files, directories


def assert_document_tree(doc: Path, expected_files: dict[str, str], *, allow_writer_lock: bool = False) -> None:
    observed_files, observed_directories = scan_document_tree(doc, allow_writer_lock=allow_writer_lock)
    assert observed_files == expected_files, "complete canonical .SNL_Doc file manifest drift"
    assert observed_directories == expected_directories(expected_files), "complete canonical .SNL_Doc directory manifest drift"


def validate_repair_authority(authority) -> None:
    expected_keys = {
        "version", "entry_schema_version", "macro_schema_version", "legacy_entry_count",
        "style_renames", "macro_kind_renames", "library_metadata", "exact_parent",
        "duplicate_children_per_parent_occurrence", "repaired_macro_hashes",
        "macro_payload_updates", "entry_payload_updates", "predecessor_manifests",
        "deduplicate_relationships",
    }
    assert type(authority) is dict and set(authority) == expected_keys
    for key in ("version", "entry_schema_version", "macro_schema_version", "legacy_entry_count"):
        assert type(authority[key]) is int, key
    assert authority["version"] == authority["entry_schema_version"] == authority["macro_schema_version"] == 1
    assert authority["legacy_entry_count"] >= 0
    assert authority["deduplicate_relationships"] is True
    assert type(authority["style_renames"]) is dict and authority["style_renames"]
    assert all(type(k) is str and type(v) is str and k != v for k, v in authority["style_renames"].items())
    assert type(authority["macro_kind_renames"]) is dict and authority["macro_kind_renames"]
    for name, spec in authority["macro_kind_renames"].items():
        assert type(name) is str and set(spec) == {"from", "to"}
        assert all(type(spec[k]) is str for k in spec) and spec["from"] != spec["to"]
    assert authority["library_metadata"] == {"Syntax": {"title": "Syntax"}}
    assert set(authority["exact_parent"]) == {"entry_id", "parent_entry_id"}
    assert all(type(value) is str for value in authority["exact_parent"].values())
    duplicate = authority["duplicate_children_per_parent_occurrence"]
    assert set(duplicate) == {"parent_entry_id", "entry_ids"}
    assert type(duplicate["parent_entry_id"]) is str and type(duplicate["entry_ids"]) is list and duplicate["entry_ids"]
    assert len(duplicate["entry_ids"]) == len(set(duplicate["entry_ids"])) and all(type(x) is str for x in duplicate["entry_ids"])
    assert type(authority["repaired_macro_hashes"]) is dict
    assert all(type(name) is str and type(digest) is str and HEX64.fullmatch(digest) for name, digest in authority["repaired_macro_hashes"].items())
    for field, identity_key in (("macro_payload_updates", "name"), ("entry_payload_updates", "id")):
        assert type(authority[field]) is list
        identities = []
        for spec in authority[field]:
            assert set(spec) == {identity_key, "package", "accepted_predecessor_hashes", "canonical"}
            assert type(spec[identity_key]) is str and type(spec["package"]) is str and type(spec["canonical"]) is dict
            assert type(spec["accepted_predecessor_hashes"]) is list and all(type(x) is str and HEX64.fullmatch(x) for x in spec["accepted_predecessor_hashes"])
            identities.append(spec[identity_key])
        assert len(identities) == len(set(identities))
    manifests = authority["predecessor_manifests"]
    assert type(manifests) is dict and set(manifests) == {"fa2bb9d84013a62a12922ea5979b4bc9f98ce17a", "source_pipeline_after_stage2"}
    for name, manifest in manifests.items():
        assert type(name) is str and type(manifest) is dict and manifest
        assert all(type(path) is str and path.startswith(".SNL_Doc/") and type(digest) is str and HEX64.fullmatch(digest) for path, digest in manifest.items())
    macro_updates = {spec["name"]: spec for spec in authority["macro_payload_updates"]}
    assert set(macro_updates) <= set(authority["repaired_macro_hashes"])
    assert all(authority["repaired_macro_hashes"][name] == payload_hash(spec["canonical"]) for name, spec in macro_updates.items())
    assert payload_hash(authority) == EXPECTED_REPAIR_AUTHORITY_DIGEST, "independent repair authority drift"


def verify(doc: Path = DOC, *, allow_writer_lock: bool = False) -> dict[str, int | str]:
    repair_authority = load(ROOT / "scripts" / "toolkit-topology-repair.json")
    validate_repair_authority(repair_authority)
    manifest_authority = load(ROOT / "scripts" / "fulcrum-doc-manifest.json")
    validate_document_manifest(manifest_authority)
    canonical_manifest = manifest_authority["canonical_files"]

    config = load(doc / "config.json")
    storage = config["entity_storage"]
    assert storage["version"] == 1
    macro_kind_ids = [item["id"] for item in config["macro_kinds"]]
    assert len(macro_kind_ids) == len(set(macro_kind_ids)), "duplicate configured Macro kind"
    assert "partial" not in macro_kind_ids and "sub" in macro_kind_ids, "legacy partial Macro kind remains configured"

    receipt = storage["receipt"]

    legacy_entries = load(doc / "entries.json")
    assert isinstance(legacy_entries, list)
    compact = json.dumps(legacy_entries, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    assert receipt["legacy_backup_present"] is True
    assert receipt["legacy_entries_present"] is True
    assert receipt["entry_count"] == len(legacy_entries), "legacy Entry receipt count drift"
    assert receipt["entries_digest"] == hashlib.sha256(compact).hexdigest(), "legacy Entry receipt digest drift"

    entry_files = sorted((doc / "entries").glob("*.json"))
    macro_files = sorted((doc / "macros").glob("*.json"))
    assert entry_files and macro_files
    for path in entry_files:
        envelope = load(path)
        assert envelope.get("format") == "snl-entry", path
        assert envelope.get("version") == 1, path
        assert envelope.get("schema_version") == repair_authority["entry_schema_version"], f"missing current Entry schema_version: {path.name}"
    macros_by_name = {}
    for path in macro_files:
        envelope = load(path)
        assert envelope.get("format") == "snl-macro", path
        assert envelope.get("version") == 1, path
        assert envelope.get("schema_version") == repair_authority["macro_schema_version"], f"missing current Macro schema_version: {path.name}"
        macro = envelope["macro"]
        macros_by_name[macro["name"]] = macro
        assert macro.get("kind") != "partial", f"retired Macro kind 'partial': {macro.get('name')}"
        styles = macro.get("styles")
        assert isinstance(styles, list) and styles
        style_names = [style.get("style_name") for style in styles]
        assert all(isinstance(name, str) and STYLE_NAME_RE.fullmatch(name) for name in style_names), f"invalid Macro style identity: {macro.get('name')}"
        assert len(style_names) == len(set(style_names)), f"duplicate Macro style identity: {macro.get('name')}"

    for name, expected in repair_authority["repaired_macro_hashes"].items():
        assert name in macros_by_name, f"missing repaired Macro: {name}"
        observed = hashlib.sha256(json.dumps(macros_by_name[name], ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        assert observed == expected, f"repaired Macro authority drift: {name}"
    all_style_names = {style["style_name"] for macro in macros_by_name.values() for style in macro["styles"]}
    for old_name, new_name in repair_authority["style_renames"].items():
        assert old_name not in all_style_names and new_name in all_style_names, f"style migration authority is not load-bearing: {old_name}"
    for macro_name, kind_spec in repair_authority["macro_kind_renames"].items():
        assert macros_by_name[macro_name]["kind"] == kind_spec["to"] and kind_spec["from"] not in macro_kind_ids
    for spec in repair_authority["macro_payload_updates"]:
        assert macros_by_name[spec["name"]] == spec["canonical"], f"declared canonical Macro payload drift: {spec['name']}"

    entries_by_id = {load(path)["entry"]["id"]: load(path)["entry"] for path in entry_files}
    for spec in repair_authority["entry_payload_updates"]:
        assert entries_by_id[spec["id"]] == spec["canonical"], f"declared canonical Entry payload drift: {spec['id']}"

    library_count = 0
    graph_count = 0
    for library in sorted(path for path in (doc / "libraries").iterdir() if path.is_dir()):
        meta_path = library / "meta.json"
        assert meta_path.is_file(), f"missing Library metadata: {library.name}/meta.json"
        meta = load(meta_path)
        assert isinstance(meta, dict) and isinstance(meta.get("title"), str) and meta["title"], meta_path
        if library.name in repair_authority["library_metadata"]:
            assert meta == repair_authority["library_metadata"][library.name], f"Library metadata authority drift: {library.name}"
        graph_path = library / "graph.json"
        assert graph_path.is_file(), f"missing Library graph: {library.name}/graph.json"
        graph = load(graph_path)
        node_ids = {node["id"] for node in graph["nodes"]}
        assert len(node_ids) == len(graph["nodes"]), f"duplicate graph node ID: {library.name}"
        incoming: dict[str, int] = {}
        for relation in graph["relationships"]:
            assert relation["from"] in node_ids and relation["to"] in node_ids, f"dangling graph edge: {library.name}"
            if relation.get("label") == "branch":
                incoming[relation["to"]] = incoming.get(relation["to"], 0) + 1
        assert all(count <= 1 for count in incoming.values()), f"multi-parent graph node: {library.name}"
        by_node_id = {node["id"]: node for node in graph["nodes"]}
        exact_parent = repair_authority["exact_parent"]
        target_nodes = [node for node in graph["nodes"] if node.get("props", {}).get("entryId") == exact_parent["entry_id"]]
        if library.name == "Type_Theory":
            assert target_nodes, "exact-parent authority does not identify a target occurrence"
        for target in target_nodes:
            parents = [relation["from"] for relation in graph["relationships"] if relation.get("label") == "branch" and relation.get("to") == target["id"]]
            assert len(parents) == 1
            assert by_node_id[parents[0]].get("props", {}).get("entryId") == exact_parent["parent_entry_id"]
        duplicate_authority = repair_authority["duplicate_children_per_parent_occurrence"]
        parent_nodes = [node for node in graph["nodes"] if node.get("props", {}).get("entryId") == duplicate_authority["parent_entry_id"]]
        if library.name == "Functional_Programming":
            assert len(parent_nodes) > 1, "duplicate-occurrence authority does not identify repeated parents"
        if len(parent_nodes) > 1:
            for parent in parent_nodes:
                child_entry_ids = [
                    by_node_id[relation["to"]].get("props", {}).get("entryId")
                    for relation in graph["relationships"]
                    if relation.get("label") == "branch" and relation.get("from") == parent["id"]
                ]
                for child_entry_id in duplicate_authority["entry_ids"]:
                    assert child_entry_ids.count(child_entry_id) == 1, f"missing duplicate child occurrence: {library.name}:{parent['id']}:{child_entry_id}"
        library_count += 1
        graph_count += len(graph["nodes"])

    assert_document_tree(doc, canonical_manifest, allow_writer_lock=allow_writer_lock)
    assert manifest_digest(canonical_manifest) == EXPECTED_CANONICAL_TREE_DIGEST, "independent canonical tree digest drift"
    for name, expected in CRITICAL_MACRO_HASHES.items():
        assert payload_hash(macros_by_name[name]) == expected, f"critical Macro payload drift: {name}"
    for entry_id, expected in CRITICAL_ENTRY_HASHES.items():
        assert payload_hash(entries_by_id[entry_id]) == expected, f"critical Entry payload drift: {entry_id}"

    return {
        "status": "PASS",
        "entries": len(entry_files),
        "macros": len(macro_files),
        "legacy_entries": len(legacy_entries),
        "libraries": library_count,
        "graph_nodes": graph_count,
    }


if __name__ == "__main__":
    print(json.dumps(verify(), ensure_ascii=False))
