#!/usr/bin/env python3
from __future__ import annotations

if not __debug__:
    raise RuntimeError("Toolkit topology tests require assertions")

import hashlib
import io
import json
import os
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARENT = "fa2bb9d84013a62a12922ea5979b4bc9f98ce17a"
SCRIPT_FILES = (
    "apply_toolkit_topology_repair.py",
    "verify_toolkit_topology.py",
    "toolkit-topology-repair.json",
    "fulcrum-doc-manifest.json",
)


def write(path: Path, value) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def document_manifest(root: Path) -> dict[str, str]:
    doc = root / ".SNL_Doc"
    return {
        str(Path(".SNL_Doc") / path.relative_to(doc)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(doc.rglob("*"))
        if path.is_file() and path.name != ".data-write.lock"
    }


def install_scripts(path: Path) -> None:
    scripts = path / "scripts"
    scripts.mkdir(exist_ok=True)
    for name in SCRIPT_FILES:
        shutil.copy2(ROOT / "scripts" / name, scripts / name)


def sandbox() -> Path:
    path = Path(tempfile.mkdtemp(prefix="fulcrum-toolkit-topology-"))
    shutil.copytree(ROOT / ".SNL_Doc", path / ".SNL_Doc")
    install_scripts(path)
    return path


def parent_sandbox() -> Path:
    path = Path(tempfile.mkdtemp(prefix="fulcrum-toolkit-parent-"))
    archive = subprocess.run(
        ["git", "archive", "--format=tar", PARENT], cwd=ROOT, capture_output=True, check=True
    ).stdout
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:") as bundle:
        bundle.extractall(path, filter="data")
    install_scripts(path)
    return path


def run_verifier(path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", "scripts/verify_toolkit_topology.py"],
        cwd=path, text=True, capture_output=True, timeout=120,
    )


def run_applicator(path: Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", "scripts/apply_toolkit_topology_repair.py"],
        cwd=path, text=True, capture_output=True, timeout=120,
        env={**os.environ, **(env or {})},
    )


def assert_clean_failure(path: Path, before: dict[str, str], result: subprocess.CompletedProcess[str], label: str) -> None:
    assert result.returncode != 0, f"{label} was accepted"
    assert document_manifest(path) == before, f"{label} changed canonical data before rejection"
    assert not (path / ".SNL_Doc" / ".data-write.lock").exists(), f"{label} leaked writer lock"
    for retained in path.glob(".SNL_Doc-toolkit-repair-*"):
        assert retained.is_dir(), f"{label} left a non-directory recovery artifact"


def expect_rejection(mutator, label: str) -> None:
    path = sandbox()
    try:
        mutator(path)
        before = document_manifest(path)
        verifier = run_verifier(path)
        assert verifier.returncode != 0, f"verifier accepted {label}"
        applicator = run_applicator(path)
        assert_clean_failure(path, before, applicator, f"applicator accepted {label}")
    finally:
        shutil.rmtree(path)


def semantic_hash(value) -> str:
    raw = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode()).hexdigest()


def main() -> None:
    baseline = run_verifier(ROOT)
    assert baseline.returncode == 0, baseline.stdout + baseline.stderr

    def stale_receipt_count(root: Path) -> None:
        path = root / ".SNL_Doc/config.json"
        value = json.loads(path.read_text())
        value["entity_storage"]["receipt"]["entry_count"] -= 1
        write(path, value)

    def retired_config_kind(root: Path) -> None:
        path = root / ".SNL_Doc/config.json"
        value = json.loads(path.read_text())
        kind = next(item for item in value["macro_kinds"] if item["id"] == "sub")
        kind["id"] = "partial"
        write(path, value)

    def missing_entry_schema(root: Path) -> None:
        path = next((root / ".SNL_Doc/entries").glob("*.json"))
        value = json.loads(path.read_text())
        del value["schema_version"]
        write(path, value)

    def missing_macro_schema(root: Path) -> None:
        path = next((root / ".SNL_Doc/macros").glob("*.json"))
        value = json.loads(path.read_text())
        del value["schema_version"]
        write(path, value)

    def missing_library_meta(root: Path) -> None:
        (root / ".SNL_Doc/libraries/Syntax/meta.json").unlink()

    def retired_partial_kind(root: Path) -> None:
        path = next((root / ".SNL_Doc/macros").glob("*.json"))
        value = json.loads(path.read_text())
        value["macro"]["kind"] = "partial"
        write(path, value)

    def invalid_style_identity(root: Path) -> None:
        path = next((root / ".SNL_Doc/macros").glob("*.json"))
        value = json.loads(path.read_text())
        value["macro"]["styles"][0]["style_name"] = "not-valid"
        write(path, value)

    def multi_parent_graph(root: Path) -> None:
        path = root / ".SNL_Doc/libraries/Syntax/graph.json"
        value = json.loads(path.read_text())
        nodes = value["nodes"]
        assert len(nodes) >= 3
        value["relationships"].append({"from": nodes[1]["id"], "to": nodes[2]["id"], "label": "branch"})
        value["relationships"].append({"from": nodes[0]["id"], "to": nodes[2]["id"], "label": "branch"})
        write(path, value)

    def arbitrary_entry_drift(root: Path) -> None:
        path = next((root / ".SNL_Doc/entries").glob("*.json"))
        value = json.loads(path.read_text())
        value["entry"]["title"] = "Unauthorized drift"
        write(path, value)

    def duplicate_authority_key(root: Path) -> None:
        path = root / "scripts/toolkit-topology-repair.json"
        raw = path.read_text()
        assert raw.startswith("{\n  \"version\": 1,")
        path.write_text(raw.replace("{\n  \"version\": 1,", "{\n  \"version\": 1,\n  \"version\": 1,", 1))

    def malformed_authority(root: Path) -> None:
        path = root / "scripts/toolkit-topology-repair.json"
        value = json.loads(path.read_text())
        value["version"] = True
        value["unexpected"] = "must fail closed"
        write(path, value)

    def metadata_authority_drift(root: Path) -> None:
        path = root / "scripts/toolkit-topology-repair.json"
        value = json.loads(path.read_text())
        value["library_metadata"]["Syntax"]["title"] = "Drift"
        write(path, value)

    def coherent_semantic_regression(root: Path) -> None:
        macro_path = None
        envelope = None
        for candidate in (root / ".SNL_Doc/macros").glob("*.json"):
            current = json.loads(candidate.read_text())
            if current["macro"]["name"] == "Topology.mapLimit":
                macro_path, envelope = candidate, current
                break
        assert macro_path is not None and envelope is not None
        style = envelope["macro"]["styles"][0]
        body = style["template"]["body"]
        style["template"]["body"] = body.replace("#0\\to #1", "#1\\to #0")
        assert style["template"]["body"] != body
        write(macro_path, envelope)
        plan_path = root / "scripts/toolkit-topology-repair.json"
        plan = json.loads(plan_path.read_text())
        update = next(item for item in plan["macro_payload_updates"] if item["name"] == "Topology.mapLimit")
        update["canonical"] = envelope["macro"]
        plan["repaired_macro_hashes"]["Topology.mapLimit"] = semantic_hash(envelope["macro"])
        write(plan_path, plan)
        manifest_path = root / "scripts/fulcrum-doc-manifest.json"
        manifest = json.loads(manifest_path.read_text())
        relative = str(macro_path.relative_to(root))
        manifest["canonical_files"][relative] = hashlib.sha256(macro_path.read_bytes()).hexdigest()
        write(manifest_path, manifest)

    def manifest_top_level_drift(root: Path) -> None:
        path = root / "scripts/fulcrum-doc-manifest.json"
        value = json.loads(path.read_text())
        value["unexpected"] = "must fail closed"
        write(path, value)

    def unused_style_authority(root: Path) -> None:
        path = root / "scripts/toolkit-topology-repair.json"
        value = json.loads(path.read_text())
        value["style_renames"]["unused-old"] = "unused_new"
        write(path, value)

    def dead_parent_authority(root: Path) -> None:
        path = root / "scripts/toolkit-topology-repair.json"
        value = json.loads(path.read_text())
        value["exact_parent"] = {"entry_id": "missing.entry", "parent_entry_id": "missing.parent"}
        write(path, value)

    def empty_repaired_hash_authority(root: Path) -> None:
        path = root / "scripts/toolkit-topology-repair.json"
        value = json.loads(path.read_text())
        value["repaired_macro_hashes"] = {}
        write(path, value)

    def nested_canonical_authority_drift(root: Path) -> None:
        path = root / "scripts/toolkit-topology-repair.json"
        value = json.loads(path.read_text())
        value["entry_payload_updates"][0]["canonical"]["unexpected_schema_field"] = True
        write(path, value)

    def extra_empty_directory(root: Path) -> None:
        (root / ".SNL_Doc/unexpected-empty").mkdir()

    def dangling_symlink(root: Path) -> None:
        (root / ".SNL_Doc/unexpected-link").symlink_to("missing-target")

    def unexpected_fifo(root: Path) -> None:
        os.mkfifo(root / ".SNL_Doc/unexpected-fifo")

    probes = (
        (stale_receipt_count, "stale receipt count"),
        (retired_config_kind, "retired configured partial Macro kind"),
        (missing_entry_schema, "missing Entry schema version"),
        (missing_macro_schema, "missing Macro schema version"),
        (missing_library_meta, "missing Library metadata"),
        (retired_partial_kind, "retired partial Macro kind"),
        (invalid_style_identity, "invalid style identity"),
        (multi_parent_graph, "multi-parent graph node"),
        (arbitrary_entry_drift, "unauthorized carried-through Entry drift"),
        (duplicate_authority_key, "duplicate repair authority key"),
        (malformed_authority, "malformed repair authority"),
        (metadata_authority_drift, "Library metadata authority drift"),
        (manifest_top_level_drift, "document manifest top-level drift"),
        (unused_style_authority, "unused style migration authority"),
        (dead_parent_authority, "dead exact-parent authority"),
        (empty_repaired_hash_authority, "empty repaired-Macro authority"),
        (nested_canonical_authority_drift, "nested canonical payload authority drift"),
        (coherent_semantic_regression, "coherent semantic authority regression"),
        (extra_empty_directory, "unexpected empty directory"),
        (dangling_symlink, "unexpected dangling symlink"),
        (unexpected_fifo, "unexpected FIFO"),
    )
    for mutator, label in probes:
        expect_rejection(mutator, label)

    # The owning migration must atomically reproduce the exact candidate from
    # its real Git parent, not merely from an older generator lease.
    initial_lock_failure = parent_sandbox()
    try:
        before = document_manifest(initial_lock_failure)
        fault = run_applicator(
            initial_lock_failure,
            {"SNL_TEST_SUBSTITUTE_INITIAL_LOCK_ON_WRITE_FAILURE": "1"},
        )
        assert fault.returncode != 0 and "retained lock state" in (fault.stdout + fault.stderr)
        visible = document_manifest(initial_lock_failure)
        visible.pop(".SNL_Doc/.owned-initial-lock")
        assert visible == before
        assert (initial_lock_failure / ".SNL_Doc/.owned-initial-lock").is_file()
        assert (initial_lock_failure / ".SNL_Doc/.data-write.lock").read_text() == "unrelated replacement\n"
    finally:
        shutil.rmtree(initial_lock_failure)

    parent = parent_sandbox()
    try:
        before = document_manifest(parent)
        fault = run_applicator(parent, {"SNL_TEST_FAIL_BEFORE_EXCHANGE": "1"})
        assert_clean_failure(parent, before, fault, "injected pre-publication failure")
        retained = list(parent.glob(".SNL_Doc-toolkit-repair-*"))
        assert len(retained) == 1, "pre-publication failure did not retain recovery evidence"
    finally:
        shutil.rmtree(parent)

    post_exchange = parent_sandbox()
    try:
        predecessor = document_manifest(post_exchange)
        fault = run_applicator(post_exchange, {"SNL_TEST_FAIL_AFTER_EXCHANGE": "1"})
        assert fault.returncode != 0
        assert document_manifest(post_exchange) == document_manifest(ROOT)
        assert (post_exchange / ".SNL_Doc/.data-write.lock").is_file()
        retained = list(post_exchange.glob(".SNL_Doc-toolkit-repair-*"))
        assert len(retained) == 1
        assert document_manifest(retained[0]) == predecessor
        assert (retained[0] / ".SNL_Doc/.data-write.lock").is_file()
    finally:
        shutil.rmtree(post_exchange)

    stage_substitution = parent_sandbox()
    try:
        failed = run_applicator(stage_substitution, {"SNL_TEST_REPLACE_STAGE_PATH_AFTER_EXCHANGE": "1"})
        assert failed.returncode != 0 and "retained predecessor root pathname changed" in (failed.stdout + failed.stderr)
        assert document_manifest(stage_substitution) == document_manifest(ROOT)
        assert (stage_substitution / ".SNL_Doc/.data-write.lock").is_file()
        replacements = list(stage_substitution.glob(".SNL_Doc-toolkit-repair-*"))
        assert any((path / "unrelated").read_text() == "must not be removed\n" for path in replacements if (path / "unrelated").is_file())
        assert any((path / ".SNL_Doc/.data-write.lock").is_file() for path in replacements)
    finally:
        shutil.rmtree(stage_substitution)

    lock_substitution = parent_sandbox()
    try:
        failed = run_applicator(lock_substitution, {"SNL_TEST_SUBSTITUTE_LOCK_BEFORE_COMMIT": "1"})
        assert failed.returncode != 0 and "writer-lock inode changed" in (failed.stdout + failed.stderr)
        visible = document_manifest(lock_substitution)
        visible.pop(".SNL_Doc/.attacker-moved-lock")
        assert visible == document_manifest(ROOT)
        assert (lock_substitution / ".SNL_Doc/.data-write.lock").is_file(), "emergency visible lock missing"
        assert (lock_substitution / ".SNL_Doc/.attacker-moved-lock").is_file(), "original moved lock was deleted"
        retained = list(lock_substitution.glob(".SNL_Doc-toolkit-repair-*"))
        assert len(retained) == 1
        vault_files = list((retained[0] / "lock-vault").iterdir())
        assert len(vault_files) == 1 and vault_files[0].read_text() == "unrelated replacement\n"
    finally:
        shutil.rmtree(lock_substitution)

    parent = parent_sandbox()
    try:
        predecessor = document_manifest(parent)
        repaired = run_applicator(parent)
        assert repaired.returncode == 0, repaired.stdout + repaired.stderr
        result = json.loads(repaired.stdout)
        retained_path = Path(result["retained_predecessor"])
        assert retained_path.is_dir()
        assert document_manifest(retained_path.parent) == predecessor
        assert document_manifest(parent) == document_manifest(ROOT), "exact parent replay differs from candidate"
        assert not (parent / ".SNL_Doc/.data-write.lock").exists()
        doc_mtime = (parent / ".SNL_Doc").stat().st_mtime_ns
        second = run_applicator(parent)
        assert second.returncode != 0 and "already canonical" in (second.stdout + second.stderr)
        assert document_manifest(parent) == document_manifest(ROOT)
        assert (parent / ".SNL_Doc").stat().st_mtime_ns == doc_mtime, "canonical refusal changed directory metadata"
    finally:
        shutil.rmtree(parent)

    broken_output = parent_sandbox()
    try:
        result = run_applicator(broken_output, {"SNL_TEST_BROKEN_OUTPUT": "1"})
        assert result.returncode == 0, result.stdout + result.stderr
        assert document_manifest(broken_output) == document_manifest(ROOT)
        assert not (broken_output / ".SNL_Doc/.data-write.lock").exists()
    finally:
        shutil.rmtree(broken_output)

    # A current Toolkit writer lock must block publication without touching data.
    locked = sandbox()
    try:
        before = document_manifest(locked)
        lock_path = locked / ".SNL_Doc/.data-write.lock"
        lock_path.write_text('{"version":1,"pid":1,"hostname":"test","token":"held","purpose":"test","createdAt":"test"}\n')
        result = run_applicator(locked)
        assert result.returncode != 0, "writer lock was ignored"
        assert document_manifest(locked) == before
        lock_path.unlink()
    finally:
        shutil.rmtree(locked)

    for script in ("verify_toolkit_topology.py", "apply_toolkit_topology_repair.py", "test_toolkit_topology.py"):
        optimized = subprocess.run(
            ["python3", "-O", f"scripts/{script}"], cwd=ROOT,
            text=True, capture_output=True, timeout=120,
        )
        assert optimized.returncode != 0 and "RuntimeError" in (optimized.stdout + optimized.stderr)

    print(json.dumps({
        "status": "PASS",
        "mutation_probes": len(probes),
        "exact_parent_replay": True,
        "atomic_prepublication_preserved": True,
        "postpublication_failure_preserved_locked": True,
        "descriptor_bound_commit": True,
        "initial_lock_failure_preserved": True,
        "outer_stage_path_drift_detected": True,
        "lock_path_drift_detected": True,
        "concurrency_scope": "cooperating lock-honoring writers",
        "canonical_refusal_read_only": True,
        "postcommit_output_nonfatal": True,
        "writer_lock_rejected": True,
        "python_O_rejected": True,
    }))


if __name__ == "__main__":
    main()
