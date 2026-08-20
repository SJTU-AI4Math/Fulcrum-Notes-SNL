#!/usr/bin/env python3
from __future__ import annotations

if not __debug__:
    raise RuntimeError("Syntax authority tests require assertions")

import hashlib
import json
import shutil
import subprocess
import tempfile
import tarfile
import io
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def tree_digest(root: Path) -> str:
    h = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        if path.is_file():
            h.update(str(path.relative_to(root)).encode() + b"\0" + path.read_bytes())
    return h.hexdigest()


def sandbox() -> Path:
    path = Path(tempfile.mkdtemp(prefix="fulcrum-syntax-authority-"))
    shutil.copytree(ROOT / ".SNL_Doc", path / ".SNL_Doc")
    shutil.copytree(ROOT / "scripts", path / "scripts")
    return path


def predecessor_sandbox() -> Path:
    path = Path(tempfile.mkdtemp(prefix="fulcrum-syntax-predecessor-"))
    source_commit = json.loads((ROOT / "scripts/fulcrum-doc-manifest.json").read_text())["source_commit"]
    archive = subprocess.run(["git", "archive", "--format=tar", source_commit], cwd=ROOT, capture_output=True, check=True).stdout
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:") as tar:
        tar.extractall(path, filter="data")
    shutil.copytree(ROOT / "scripts", path / "scripts", dirs_exist_ok=True)
    return path


def run(path: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(list(args), cwd=path, text=True, capture_output=True, timeout=300)


def expect_preflight_rejection(mutator, label: str) -> None:
    path = sandbox()
    try:
        mutator(path)
        before = tree_digest(path / ".SNL_Doc")
        result = run(path, "python3", "scripts/apply_syntax_namespace.py")
        assert result.returncode != 0, f"{label} was accepted"
        assert tree_digest(path / ".SNL_Doc") == before, f"{label} mutated the filesystem before rejection"
    finally:
        shutil.rmtree(path)


def main() -> None:
    # A pristine leased predecessor must reproduce the exact checked-in canonical document tree.
    path = predecessor_sandbox()
    try:
        for command in (
            ("python3", "scripts/apply_syntax_namespace.py"),
            ("python3", "scripts/apply_fulcrum_i18n_inductives.py"),
            ("python3", "scripts/verify_fulcrum_i18n_inductives.py"),
        ):
            result = run(path, *command)
            assert result.returncode == 0, result.stdout + result.stderr
        assert tree_digest(path / ".SNL_Doc") == tree_digest(ROOT / ".SNL_Doc"), "pristine predecessor replay differs from canonical tree"
    finally:
        shutil.rmtree(path)

    # Valid canonical replay is byte-idempotent across the complete two-stage pipeline.
    path = sandbox()
    try:
        baseline = tree_digest(path / ".SNL_Doc")
        for _ in range(2):
            for command in (
                ("python3", "scripts/apply_syntax_namespace.py"),
                ("python3", "scripts/apply_fulcrum_i18n_inductives.py"),
                ("python3", "scripts/verify_fulcrum_i18n_inductives.py"),
            ):
                result = run(path, *command)
                assert result.returncode == 0, result.stdout + result.stderr
                assert tree_digest(path / ".SNL_Doc") == baseline, f"{command[1]} is not independently byte-idempotent"
            assert tree_digest(path / ".SNL_Doc") == baseline
    finally:
        shutil.rmtree(path)

    def duplicate_key(path: Path) -> None:
        p = path / "scripts" / "fulcrum-syntax-migration.json"
        text = p.read_text()
        p.write_text(text.replace('"version": 1,', '"version": 1,\n  "version": 1,', 1))

    def boolean_version(path: Path) -> None:
        p = path / "scripts" / "fulcrum-syntax-migration.json"
        value = json.loads(p.read_text())
        value["version"] = True
        p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")

    def unknown_authority_field(path: Path) -> None:
        p = path / "scripts" / "fulcrum-syntax-migration.json"
        value = json.loads(p.read_text())
        value["unexpected"] = 1
        p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")

    def canonical_graph_unknown_field(path: Path) -> None:
        p = path / ".SNL_Doc" / "libraries" / "basic-algebra" / "graph.json"
        value = json.loads(p.read_text())
        value["unexpected"] = "must fail closed"
        p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")

    def canonical_relationship_unknown_field(path: Path) -> None:
        p = path / ".SNL_Doc" / "relationships.json"
        value = json.loads(p.read_text())
        value["unexpected"] = "must fail closed"
        p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")

    def canonical_provenance_unknown_field(path: Path) -> None:
        for p in (path / ".SNL_Doc" / "macros").glob("*.json"):
            value = json.loads(p.read_text())
            if value["macro"]["name"] == "Algebra.Stab":
                value["macro"]["source"]["unexpected"] = "must fail closed"
                p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
                return
        raise AssertionError("canonical provenance probe Macro not found")

    def canonical_entry_drift(path: Path) -> None:
        for p in (path / ".SNL_Doc" / "entries").glob("*.json"):
            value = json.loads(p.read_text())
            if value["entry"]["id"] == "Syntax.def.expression-UTLC":
                value["entry"]["title"]["values"]["en"] = "CORRUPTED"
                p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
                return
        raise AssertionError("canonical probe Entry not found")

    # The second mutating applicator must independently reject every auxiliary
    # closed-schema mutation, without relying on the first applicator.
    for mutator, label in (
        (canonical_graph_unknown_field, "second-stage graph unknown field"),
        (canonical_relationship_unknown_field, "second-stage relationship unknown field"),
        (canonical_provenance_unknown_field, "second-stage provenance unknown field"),
    ):
        path = sandbox()
        try:
            mutator(path)
            before = tree_digest(path / ".SNL_Doc")
            result = run(path, "python3", "scripts/apply_fulcrum_i18n_inductives.py")
            assert result.returncode != 0, f"{label} was accepted"
            assert tree_digest(path / ".SNL_Doc") == before, f"{label} mutated the filesystem before rejection"
        finally:
            shutil.rmtree(path)

    path = predecessor_sandbox()
    try:
        graph = path / ".SNL_Doc" / "libraries" / "basic-algebra" / "graph.json"
        value = json.loads(graph.read_text())
        value["unexpected"] = "source drift"
        graph.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
        before = tree_digest(path / ".SNL_Doc")
        result = run(path, "python3", "scripts/apply_syntax_namespace.py")
        assert result.returncode != 0, "source graph drift was accepted"
        assert tree_digest(path / ".SNL_Doc") == before, "source graph drift rejection was not transactional"
    finally:
        shutil.rmtree(path)

    for mutator, label in (
        (duplicate_key, "duplicate JSON key"),
        (boolean_version, "boolean schema version"),
        (unknown_authority_field, "unknown authority field"),
        (canonical_entry_drift, "canonical Entry drift"),
        (canonical_graph_unknown_field, "canonical graph unknown field"),
    ):
        expect_preflight_rejection(mutator, label)

    optimized = run(ROOT, "python3", "-O", "scripts/apply_syntax_namespace.py")
    assert optimized.returncode != 0 and "must run without Python optimization" in (optimized.stdout + optimized.stderr)

    print(json.dumps({"status": "PASS", "idempotent_rounds": 2, "mutation_probes": 9, "pristine_replay": True, "python_O_rejected": True}))


if __name__ == "__main__":
    main()
