#!/usr/bin/env python3
"""Verify Phase 3 renamed entry IDs: entry get + entry latex for each new id."""
import json
import subprocess
import sys

CLI = "/home/sky/workspace/cat/SNL-Agent-Toolkit/dist/cli/snl.mjs"
ROOT = "/home/sky/workspace/gray/Fulcrum-Notes-SNL"

NEW_IDS = [
    "Semigroup", "Monoid", "CommMonoid", "Group", "CommGroup", "MonoidHom",
    "GroupMono", "GroupEpi", "MulEquiv", "MonoidHom.ker", "MonoidHom.range",
    "NonUnitalRing", "UnitalRing", "CommRing", "IsDomain", "DivisionRing",
    "Field", "Subgroup", "MulAction", "MulAction.orbit", "MulAction.stabilizer",
    "Symmetric", "Perm", "Cycle", "Trans", "One",
    "Monoid.prop.identityUnique", "Group.prop.inverseUnique", "CommGroup.prop.int",
    "Monoid.prop.nat", "Monoid.example.nat.add",
    "NonUnitalRing.remark.mulPrioritized", "CommMonoid.thm.grothendieckGroup",
]

OLD_IDS = [
    "Algebra.def.semigroup", "Algebra.def.monoid", "Algebra.def.monoid.commutative",
    "Algebra.def.group", "Algebra.def.abelian", "Algebra.def.groupHom",
    "Algebra.def.groupMono", "Algebra.def.groupEpi", "Algebra.def.groupIso",
    "Algebra.def.kernel", "Algebra.def.image", "Algebra.def.ring",
    "Algebra.def.ring.unital", "Algebra.def.ring.commutative", "Algebra.def.integral",
    "Algebra.def.ring.divisible", "Algebra.def.field", "Algebra.def.subgroup",
    "Algebra.def.groupAction", "Algebra.def.orbit", "Algebra.def.stabilizer",
    "Algebra.def.symmetricGroup", "Algebra.def.permutation", "Algebra.def.cycle",
    "Algebra.def.transposition", "Algebra.def.identity", "Algebra.prop.identityUnique",
    "Algebra.prop.inverseUnique", "Algebra.prop.int.abelian", "Algebra.prop.nat.monoid",
    "Algebra.example.nat.add", "Algebra.remark.ring.mulPrioritized",
    "Algebra.thm.grothendieckGroup",
]


def run(args):
    proc = subprocess.run(["node", CLI, "--root", ROOT] + args, capture_output=True, text=True)
    try:
        return json.loads(proc.stdout), proc
    except Exception:
        return None, proc


def extract_title(value):
    title = (value or {}).get("title")
    if isinstance(title, str):
        return title
    if isinstance(title, dict):
        return title.get("values", {}).get("en") or title.get("default")
    return None


def main():
    rows = []
    for new in NEW_IDS:
        got, proc = run(["entry", "get", new])
        ok_get = bool(got and got.get("ok"))
        title = extract_title(got["data"]["entity"]["value"]) if ok_get else None
        lat, proc2 = run(["entry", "latex", new])
        ok_latex = bool(lat and lat.get("ok"))
        latex_text = ""
        if ok_latex:
            d = lat.get("data", {})
            latex_text = d.get("latex") or d.get("text") or json.dumps(d, ensure_ascii=False)
        rows.append({
            "id": new,
            "get_ok": ok_get,
            "title": title,
            "latex_ok": ok_latex,
            "latex_len": len(latex_text) if isinstance(latex_text, str) else None,
            "latex_head": (latex_text[:80] if isinstance(latex_text, str) else None),
            "get_err": None if ok_get else (got or {}).get("error") or proc.stdout[-200:],
            "latex_err": None if ok_latex else (lat or {}).get("error") or proc2.stdout[-200:],
        })
        print(f"{'OK ' if ok_get and ok_latex else 'BAD'} {new:38s} get={ok_get} latex={ok_latex} title={title}", flush=True)

    print("\n-- old ids (expect not-found) --", flush=True)
    old_rows = []
    for old in OLD_IDS:
        got, proc = run(["entry", "get", old])
        found = bool(got and got.get("ok"))
        old_rows.append({"id": old, "still_present": found})
        print(f"{'!! STILL PRESENT' if found else 'gone'} {old}", flush=True)

    summary = {
        "new_total": len(NEW_IDS),
        "new_get_ok": sum(1 for r in rows if r["get_ok"]),
        "new_latex_ok": sum(1 for r in rows if r["latex_ok"]),
        "old_still_present": sum(1 for r in old_rows if r["still_present"]),
    }
    with open(f"{ROOT}/scripts/verify_rename_phase3_report.json", "w") as fh:
        json.dump({"summary": summary, "new_ids": rows, "old_ids": old_rows}, fh, ensure_ascii=False, indent=2)
    print("\n" + json.dumps(summary), flush=True)
    return 0 if summary["new_get_ok"] == len(NEW_IDS) and summary["new_latex_ok"] == len(NEW_IDS) else 1


if __name__ == "__main__":
    sys.exit(main())
