#!/usr/bin/env python3
"""Build and test the public Convincer slice serially, without fetching Mathlib.

Requires Python 3.10+ and the repository's pinned Lean toolchain via elan.
Run from any directory: python3 Convincer/check.py
"""
from pathlib import Path
import os
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
TOOLCHAIN = (ROOT / "lean-toolchain").read_text(encoding="utf-8").strip()
BUILD = ROOT / ".lake" / "convincer"
BUILD.mkdir(parents=True, exist_ok=True)
ENV = dict(os.environ, LEAN_PATH=str(BUILD))


def lean(path, output=None):
    command = ["lean", "+" + TOOLCHAIN]
    if output:
        output.parent.mkdir(parents=True, exist_ok=True)
        command += ["-o", str(output)]
    command.append(str(path))
    return subprocess.run(command, cwd=ROOT, env=ENV, text=True,
                          encoding="utf-8", errors="replace", capture_output=True, timeout=90)


def positive(path, output=None):
    result = lean(path, output)
    print(result.stdout, end="")
    print(result.stderr, end="")
    if result.returncode != 0 or "declaration uses `sorry`" in (result.stdout + result.stderr):
        raise SystemExit(f"FAIL: {path} (exit {result.returncode})")
    print(f"PASS: {path}")
    return result.stdout


NEGATIVE = {
    "no-extraction": ("""
def asserted : Convincing False := .evidence ⟨"x", "asserted", ""⟩
example : False := by exact asserted
""", "Type mismatch"),
    "invalid-rigid-step": ("""
convince bad : False := by
  evidence h : True := ⟨"x", "true", ""⟩
  exact h
""", "Type mismatch"),
    "unsolved-goal": ("""
convince bad : True ∧ False := by
  constructor
  · trivial
""", "unsolved goals"),
    "effect-outside-scope": ("""
example : False := by
  evidence ⟨"x", "not a proof", ""⟩
""", "only available inside"),
    "binder-dependent-effect": ("""
convince bad : ∀ n : Nat, n = 0 := by
  intro n
  evidence h : n = 0 := ⟨"x", "local", ""⟩
  exact h
""", "independent of tactic-local binders"),
    "proof-dependent-source": ("""
def conditional (h : False) : Convincing True := .proof (False.elim h)
convince bad : True := by
  evidence h : False := ⟨"x", "false", ""⟩
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
opaque hidden : Convincing True := .evidence ⟨"hidden", "opaque source", ""⟩
#evidence hidden
""", "cannot inspect this argument"),
    "sorry-not-evidence": ("""
convince bad : False := by sorry
""", "sorryAx"),
    "direct-term-sorry": ("""
convince bad : False := Convincing.proof (by sorry)
""", "sorryAx"),
    "transitive-sorry": ("""
theorem incomplete : False := by sorry
convince bad : False := by exact incomplete
""", "sorryAx"),
}


def main():
    for name in ["Convincer/Core", "Convincer/Elab", "Convincer"]:
        positive(ROOT / (name + ".lean"), BUILD / (name + ".olean"))
    tests = positive(ROOT / "Convincer/Tests.lean", BUILD / "Convincer/Tests.olean")
    for fragment in ["evidence [first] : False", "evidence [second] : True",
                     "'Convincer.Tests.combined' does not depend on any axioms",
                     "'Convincer.Convincing.sound' does not depend on any axioms"]:
        assert fragment in tests, f"Missing positive receipt: {fragment}"
    positive(ROOT / "Convince/test.lean")
    failures = []
    with tempfile.TemporaryDirectory(prefix="negative-", dir=BUILD) as folder:
        # Compile runnable README examples, not just a separately maintained copy.
        blocks = re.findall(r"```lean\n(.*?)```", (ROOT / "Convincer/README.md").read_text(encoding="utf-8"), re.S)
        runnable = [block for block in blocks if block.startswith("import ") or block.startswith("convince ")]
        docs = Path(folder) / "Documentation.lean"
        docs.write_text("\n".join(runnable), encoding="utf-8")
        positive(docs)
        # Explicit custom axioms remain visible rather than silently becoming evidence.
        axiom_probe = Path(folder) / "AxiomReport.lean"
        axiom_probe.write_text("import Convincer\naxiom chosenTrust : True\n"
                               "convince trusted : True := Convincing.proof chosenTrust\n"
                               "#evidence trusted\n", encoding="utf-8")
        axiom_output = positive(axiom_probe)
        if "axioms: #[chosenTrust]" not in axiom_output:
            raise SystemExit("FAIL: custom axiom omitted from provenance report")
        # The checker itself must reject a real Lean exit-0 sorry warning,
        # including ordinary declarations outside the Convincer DSL.
        warning_probe = Path(folder) / "OrdinarySorry.lean"
        warning_probe.write_text("import Convincer\nexample : False := by sorry\n", encoding="utf-8")
        warning_result = lean(warning_probe)
        if warning_result.returncode != 0 or "declaration uses `sorry`" not in (warning_result.stdout + warning_result.stderr):
            raise SystemExit("FAIL: missing real exit-0 sorry warning for checker regression")
        try:
            positive(warning_probe)
        except SystemExit:
            print("PASS: checker rejects ordinary Lean exit-0 sorry warning")
        else:
            raise SystemExit("FAIL: checker accepted ordinary Lean sorry")
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
    print(f"Convincer: public import + examples + structural assertions + {len(NEGATIVE)} negative gates PASS")


if __name__ == "__main__":
    main()
