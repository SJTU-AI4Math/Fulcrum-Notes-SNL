#!/usr/bin/env python3
"""Serial Lean checks; native sorry warnings are allowed, as in ordinary Lean."""
from pathlib import Path
import os
import re
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parent
TOOLCHAIN = (ROOT / "lean-toolchain").read_text(encoding="utf-8").strip()
BUILD = ROOT / ".lake" / "convincer-flat"
BUILD.mkdir(parents=True, exist_ok=True)
ENV = dict(os.environ, LEAN_PATH=str(BUILD))


def lean(path, output=None):
    command = ["lean", "+" + TOOLCHAIN]
    if output:
        output.parent.mkdir(parents=True, exist_ok=True)
        command += ["-o", str(output)]
    return subprocess.run(command + [str(path)], cwd=SOURCE, env=ENV, text=True,
                          encoding="utf-8", errors="replace", capture_output=True, timeout=90)


def positive(path, output=None):
    result = lean(path, output)
    print(result.stdout, end="")
    print(result.stderr, end="")
    if result.returncode != 0:
        raise SystemExit(f"FAIL: {path} (exit {result.returncode})")
    print(f"PASS: {path}")
    return result.stdout + result.stderr


NEGATIVE = {
    "no-extraction-without-sorry": ("""
def asserted : Convincing False := .evidence (Evidence.of "asserted")
example : False := by exact asserted
""", "Type mismatch"),
    "invalid-rigid-step": ("""
convince bad : False := by
  evidence h : True := "true"
  exact h
""", "Type mismatch"),
    "unsolved-goal": ("""
convince bad : True ∧ False := by
  constructor
  · trivial
""", "unsolved goals"),
    "unknown-payload": ("""
example : False := by
  evidence noSuchPayload
""", "Unknown identifier"),
    "binder-dependent-effect": ("""
convince bad : ∀ n : Nat, n = 0 := by
  intro n
  evidence h : n = 0 := "local"
  exact h
""", "independent of tactic-local binders"),
    "proof-dependent-source": ("""
def conditional (h : False) : Convincing True := .proof (False.elim h)
convince bad : True := by
  evidence h : False := "false"
  have t ← conditional h
  exact t
""", "independent of tactic-local binders"),
    "wrong-source-type": ("""
convince bad : True := by
  have h ← True.intro
  exact h
""", "Expected a `Convincing p`"),
    "data-not-proposition": ("""
convince bad : Nat := by exact 3
""", "expected to have type"),
    "symbolic-report": ("""
variable (c : Convincing True)
#evidence c
""", "require a closed argument"),
    "open-proof-report": ("""
variable (h : False)
#evidence (show Convincing False from .proof h)
""", "require a closed argument"),
    "open-evidence-report": ("""
variable (s : Evidence)
#evidence (show Convincing False from .evidence s)
""", "require a closed argument"),
    "opaque-report": ("""
opaque hidden : Convincing True := .evidence (Evidence.of "hidden")
#evidence hidden
""", "cannot inspect this argument"),
}


def main():
    positive(SOURCE / "Convincer.lean", BUILD / "Convincer.olean")
    tests = positive(SOURCE / "Tests.lean", BUILD / "Tests.olean")
    for fragment in [
        "False ← \"Obvious\"", "True ← [1, 2, 3]",
        "'Convincer.Tests.combined' does not depend on any axioms",
        "'Convincer.Convincing.sound' does not depend on any axioms",
        "'Convincer.Compatibility.captured' does not depend on any axioms",
        "'Convincer.Compatibility.clearedContext' does not depend on any axioms",
        "'Convincer.Compatibility.ordinary' depends on axioms: [sorryAx]",
        "'Convincer.Compatibility.ordinaryCitation' depends on axioms: [sorryAx]",
        "'Convincer.Compatibility.ordinaryData' depends on axioms: [sorryAx]",
        "'Convincer.Compatibility.unfinished' depends on axioms: [sorryAx]",
        "'Convincer.Compatibility.indirect' depends on axioms: [sorryAx]",
        "declaration uses `sorry`",
    ]:
        if fragment not in tests:
            raise SystemExit(f"Missing receipt: {fragment}")
    failures = []
    with tempfile.TemporaryDirectory(prefix="check-", dir=BUILD) as folder:
        blocks = re.findall(r"```lean\n(.*?)```", (SOURCE / "README.md").read_text(encoding="utf-8"), re.S)
        runnable = [b for b in blocks if b.startswith("import ") or b.startswith("convince ")]
        docs = Path(folder) / "Documentation.lean"
        docs.write_text("\n".join(runnable), encoding="utf-8")
        positive(docs)
        for name, (body, expected) in NEGATIVE.items():
            path = Path(folder) / (name + ".lean")
            path.write_text("import Convincer\n" + body, encoding="utf-8")
            result = lean(path)
            text = result.stdout + result.stderr
            if result.returncode == 0 or expected not in text:
                failures.append(name)
                print(f"FAIL: negative/{name} (exit {result.returncode})\n{text}")
            else:
                print(f"PASS: negative/{name}")
    if failures:
        raise SystemExit("Failed negative gates: " + ", ".join(failures))
    print(f"Convincer: arbitrary payloads + evidence-only trees + shared tactics + native sorry + {len(NEGATIVE)} negative gates PASS")


if __name__ == "__main__":
    main()
