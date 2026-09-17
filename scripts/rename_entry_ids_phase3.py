#!/usr/bin/env python3
"""Phase 3: rename entry IDs (concept + prop/example) via snl entry rename."""
import json
import subprocess
import sys

CLI = "/home/sky/workspace/cat/SNL-Agent-Toolkit/dist/cli/snl.mjs"
ROOT = "/home/sky/workspace/gray/Fulcrum-Notes-SNL"

RENAMES = [
    ("Algebra.def.semigroup", "Semigroup"),
    ("Algebra.def.monoid", "Monoid"),
    ("Algebra.def.monoid.commutative", "CommMonoid"),
    ("Algebra.def.group", "Group"),
    ("Algebra.def.abelian", "CommGroup"),
    ("Algebra.def.groupHom", "MonoidHom"),
    ("Algebra.def.groupMono", "GroupMono"),
    ("Algebra.def.groupEpi", "GroupEpi"),
    ("Algebra.def.groupIso", "MulEquiv"),
    ("Algebra.def.kernel", "MonoidHom.ker"),
    ("Algebra.def.image", "MonoidHom.range"),
    ("Algebra.def.ring", "NonUnitalRing"),
    ("Algebra.def.ring.unital", "UnitalRing"),
    ("Algebra.def.ring.commutative", "CommRing"),
    ("Algebra.def.integral", "IsDomain"),
    ("Algebra.def.ring.divisible", "DivisionRing"),
    ("Algebra.def.field", "Field"),
    ("Algebra.def.subgroup", "Subgroup"),
    ("Algebra.def.groupAction", "MulAction"),
    ("Algebra.def.orbit", "MulAction.orbit"),
    ("Algebra.def.stabilizer", "MulAction.stabilizer"),
    ("Algebra.def.symmetricGroup", "Symmetric"),
    ("Algebra.def.permutation", "Perm"),
    ("Algebra.def.cycle", "Cycle"),
    ("Algebra.def.transposition", "Trans"),
    ("Algebra.def.identity", "One"),
    ("Algebra.prop.identityUnique", "Monoid.prop.identityUnique"),
    ("Algebra.prop.inverseUnique", "Group.prop.inverseUnique"),
    ("Algebra.prop.int.abelian", "CommGroup.prop.int"),
    ("Algebra.prop.nat.monoid", "Monoid.prop.nat"),
    ("Algebra.example.nat.add", "Monoid.example.nat.add"),
    ("Algebra.remark.ring.mulPrioritized", "NonUnitalRing.remark.mulPrioritized"),
    ("Algebra.thm.grothendieckGroup", "CommMonoid.thm.grothendieckGroup"),
]


def run(args):
    proc = subprocess.run(
        ["node", CLI, "--root", ROOT] + args,
        capture_output=True, text=True,
    )
    try:
        payload = json.loads(proc.stdout)
    except Exception:
        return None, proc
    return payload, proc


def main():
    results = []
    for idx, (old, new) in enumerate(RENAMES, 1):
        entry = {"n": idx, "old": old, "new": new}
        got, proc = run(["entry", "get", old])
        if got is None:
            entry.update(status="error", stage="get", detail=proc.stdout[-500:] + proc.stderr[-500:])
            results.append(entry)
            print(f"[{idx:02d}] GET-FAIL {old}: {entry['detail'][:200]}", flush=True)
            continue
        if not got.get("ok"):
            code = got.get("error", {}).get("code")
            if code == "entity.not-found":
                entry.update(status="skipped", reason="entity.not-found (already renamed or missing)")
                results.append(entry)
                print(f"[{idx:02d}] SKIP     {old} -> {new} (not found)", flush=True)
            else:
                entry.update(status="error", stage="get", detail=got.get("error"))
                results.append(entry)
                print(f"[{idx:02d}] GET-ERR  {old}: {got.get('error')}", flush=True)
            continue
        rev = got["data"]["entity"]["revision"]

        payload, proc = run(["entry", "rename", old, "--to", new, "--if-match", rev])
        if payload is None:
            entry.update(status="error", stage="rename", detail=proc.stdout[-500:] + proc.stderr[-500:])
            results.append(entry)
            print(f"[{idx:02d}] RENAME-FAIL {old} -> {new}: parse error", flush=True)
            continue
        if payload.get("ok"):
            entry.update(status="renamed")
            results.append(entry)
            print(f"[{idx:02d}] OK       {old} -> {new}", flush=True)
        else:
            err = payload.get("error", {})
            if err.get("code") == "entity.not-found":
                entry.update(status="skipped", reason=str(err))
            else:
                entry.update(status="failed", reason=err)
                print(f"[{idx:02d}] FAIL     {old} -> {new}: {err}", flush=True)
            results.append(entry)

    summary = {
        "total": len(RENAMES),
        "renamed": sum(1 for r in results if r["status"] == "renamed"),
        "skipped": sum(1 for r in results if r["status"] == "skipped"),
        "failed": sum(1 for r in results if r["status"] in ("failed", "error")),
    }
    report = {"summary": summary, "results": results}
    with open(f"{ROOT}/scripts/rename_entry_ids_phase3_report.json", "w") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(json.dumps(summary), flush=True)
    return 0 if summary["failed"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
