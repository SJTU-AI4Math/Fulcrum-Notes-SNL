#!/usr/bin/env python3
"""Apply the authority-backed Syntax namespace and judgement-layer migration.

The migration is transactional: all JSON is parsed strictly, transformed in
memory, semantically validated, and only then written. It is idempotent on the
canonical tree and rejects split old/new identities.
"""
from __future__ import annotations

if not __debug__:
    raise RuntimeError("Fulcrum Syntax authority tooling must run without Python optimization; -O disables required assertions")

import hashlib
import json
import math
import re
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / ".SNL_Doc"

ENTRY_RENAMES = {
    "Type.subsec.patternMatching": "Syntax.subsec.patternMatching",
    "Type.rl.Expr-LC": "Syntax.def.expression-UTLC",
    "Type.rl.Expr-LC.ctor.lambda-abstraction": "Syntax.def.expression-UTLC.ctor.lambdaAbstraction",
    "Type.rl.Expr-LC.ctor.application": "Syntax.def.expression-UTLC.ctor.application",
    "Type.rl.Expr-LC.ctor.bound-variable": "Syntax.def.expression-UTLC.ctor.boundVariable",
    "Type.rl.Expr-LC.recursor": "Syntax.def.expression-UTLC.recursor",
    "Type.rmk.Expr-LC.lambda": "Syntax.rmk.lambdaNotation-UTLC",
    "Type.rmk.Expr-LC.apply": "Syntax.rmk.applicationNotation-UTLC",
    "Type.rmk.deBruijnIndex": "Syntax.rmk.deBruijnIndex",
    "Type.rmk.closedExpression": "Syntax.rmk.closedExpression-UTLC",
    "Type.def.named-lambda": "Syntax.def.namedBinderPresentation-UTLC",
    "Type.rmk.named-lambda": "Syntax.rmk.namedBinderPresentation-UTLC",
    "Type.def.LegalExpr-LC": "Syntax.def.legalExpression-UTLC",
    "Type.def.shift-LC": "Syntax.def.shift-UTLC",
    "Type.def.Substitution-LC": "Syntax.def.substitution-UTLC",
    "Type.def.freeVariable": "Syntax.def.openExpression-UTLC",
    "Type.def.freeVariable.ctor.closedExpression": "Syntax.def.openExpression-UTLC.ctor.closedExpression",
    "Type.def.freeVariable.ctor.freeVariable": "Syntax.def.openExpression-UTLC.ctor.freeVariable",
    "Type.def.freeVariable.ctor.lambdaAbstraction": "Syntax.def.openExpression-UTLC.ctor.lambdaAbstraction",
    "Type.def.freeVariable.ctor.application": "Syntax.def.openExpression-UTLC.ctor.application",
    "Type.def.freeVariable.recursor": "Syntax.def.openExpression-UTLC.recursor",
    "Type.rmk.freeVariableOpenExpression": "Syntax.rmk.freeVariableOpenExpression-UTLC",
    "Type.rl.Expr-STLC": "Syntax.def.expression-STLC",
    "Type.rl.lambda-typed": "Syntax.def.expression-STLC.ctor.lambdaAbstraction",
    "Type.rl.Expr-STLC.ctor.application": "Syntax.def.expression-STLC.ctor.application",
    "Type.rl.Expr-STLC.ctor.bound-variable": "Syntax.def.expression-STLC.ctor.boundVariable",
    "Type.rl.Expr-STLC.ctor.function-type": "Syntax.def.expression-STLC.ctor.functionType",
    "Type.rl.Expr-STLC.recursor": "Syntax.rmk.expressionSTLCNoRecursor",
    "Type.def.type-expression-stlc": "Syntax.def.typeExpression-STLC",
}

RETIRED_CANONICAL_ENTRIES = {"Syntax.def.openExpression-UTLC.recursor"}


MACRO_RENAMES = {
    # The old two-place colon form is metadata, not an object-language judgement.
    "Type.judge": "Type.annotation",
    # The old three-place macro already had the required rendering.
    "Type.ctx-judge": "Type.judge",
    "Type.Expr": "Syntax.Expr",
    "Type.TypeExpr": "Syntax.TypeExpr",
    "Type.Term": "Syntax.Term",
    "Lambda.Expr": "Syntax.Expr-UTLC",
    "Lambda.OpenExpr": "Syntax.OpenExpr-UTLC",
    "Lambda.LegalExpr": "Syntax.LegalExpr-UTLC",
    "Type.Expr-UTLC.lambda": "Syntax.Expr-UTLC.lambda",
    "Type.Expr-UTLC.apply": "Syntax.Expr-UTLC.apply",
    "Type.Expr-UTLC.bvar": "Syntax.Expr-UTLC.bvar",
    "Type.Expr-UTLC.fvar": "Syntax.Expr-UTLC.fvar",
    "Type.Expr-UTLC.closed": "Syntax.Expr-UTLC.closed",
    "Lambda.apply": "Syntax.apply-UTLC",
    "Lambda.pattern.lambda": "Syntax.pattern.UTLC.lambda",
    "Lambda.pattern.app": "Syntax.pattern.UTLC.application",
    "Lambda.pattern.bvar": "Syntax.pattern.UTLC.boundVariable",
    "Lambda.shift": "Syntax.shift-UTLC",
    "Lambda.substitution": "Syntax.substitution-UTLC",
    "Type.pattern.arguments": "Syntax.pattern.arguments",
    "Type.pattern.branch": "Syntax.pattern.branch",
    "Type.pattern.branches": "Syntax.pattern.branches",
    "Type.pattern.constructor": "Syntax.pattern.constructor",
    "Type.pattern.match": "Syntax.pattern.match",
    "Type.piecewise": "Syntax.piecewise",
    "Type.piecewise.branch": "Syntax.piecewise.branch",
}

# One-off localized prose sourced by migrated Syntax Entries is Syntax-owned too.
ONE_OFF_PREFIX_RENAMES = {
    "FulcrumNotes.OneOffI18N.TypeTheory.ApplicationNotation.": "Syntax.OneOffI18N.ApplicationNotation.",
    "FulcrumNotes.OneOffI18N.TypeTheory.LegalExpression.": "Syntax.OneOffI18N.LegalExpression.",
    "FulcrumNotes.OneOffI18N.TypeTheory.DeBruijnIndex.": "Syntax.OneOffI18N.DeBruijnIndex.",
    "FulcrumNotes.OneOffI18N.TypeTheory.LambdaNotation.": "Syntax.OneOffI18N.LambdaNotation.",
    "FulcrumNotes.OneOffI18N.TypeTheory.NamedBinder.": "Syntax.OneOffI18N.NamedBinder.",
    "FulcrumNotes.OneOffI18N.TypeTheory.ClosedExpression.": "Syntax.OneOffI18N.ClosedExpression.",
    "FulcrumNotes.OneOffI18N.TypeTheory.FreeVariable.": "Syntax.OneOffI18N.FreeVariable.",
}


def reject_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON constant: {value}")


def strict_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in pairs:
        if key in out:
            raise ValueError(f"duplicate JSON key: {key}")
        out[key] = value
    return out


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=strict_pairs, parse_constant=reject_constant)
    assert isinstance(value, dict), path
    return value


def finite(value: Any) -> bool:
    if isinstance(value, float):
        return math.isfinite(value)
    if isinstance(value, dict):
        return all(finite(v) for v in value.values())
    if isinstance(value, list):
        return all(finite(v) for v in value)
    return True


def identity_hash(kind: str, *segments: str) -> str:
    raw = "snl-doc/v1\0" + kind + "\0" + "\0".join(segments)
    return hashlib.sha256(raw.encode()).hexdigest()[:20]


def dump(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def localized(en: str, zh: str) -> dict[str, Any]:
    return {"type": "i18n", "default_language": "en", "values": {"en": en, "zh-CN": zh}}


def template(body: str, mode: str = "formula_inline") -> dict[str, Any]:
    return {
        "mode": mode,
        "body": body,
        "typst": {"built_in": "", "synthesis": {"mode": "formula", "macro": ""}},
        "latex": {"built_in": "", "synthesis": {"mode": "formula", "macro": ""}},
        "markdown": "",
        "text": "",
    }


def macro(name: str, kind: str, body: str, source: str, *, mode: str = "formula_inline", description: str = "") -> dict[str, Any]:
    return {
        "description": description,
        "source": {"entries": [source], "urls": []},
        "kind": kind,
        "dynamic_arity": False,
        "styles": [{"style_name": "default", "tags": [], "template": template(body, mode)}],
        "tags": [],
        "name": name,
    }


def i18n_macro(name: str, body_en: str, body_zh: str, source: str) -> dict[str, Any]:
    return {
        "description": "Non-exhaustive syntax-signature fragment",
        "source": {"entries": [source], "urls": []},
        "kind": "rule",
        "dynamic_arity": False,
        "styles": [{
            "style_name": "default", "tags": [],
            "template": {"type": "i18n", "default_language": "en", "values": {
                "en": template(body_en, "text"), "zh-CN": template(body_zh, "text")
            }}
        }],
        "tags": [], "name": name,
    }


def rewrite_identifier(source: str, old: str, new: str) -> str:
    """Rewrite a Macro token while leaving opaque percent/dollar bodies untouched."""
    pattern = re.compile(rf"(?<![A-Za-z0-9_.-]){re.escape(old)}(?![A-Za-z0-9_.-])")
    out: list[str] = []
    cursor = plain_start = 0
    while cursor < len(source):
        delim = "$$" if source.startswith("$$", cursor) else source[cursor] if source[cursor] in {"%", "$"} else None
        if delim is None:
            cursor += 1
            continue
        out.append(pattern.sub(new, source[plain_start:cursor]))
        end = source.find(delim, cursor + len(delim))
        if end < 0:
            out.append(source[cursor:])
            return "".join(out)
        end += len(delim)
        out.append(source[cursor:end])
        cursor = plain_start = end
    out.append(pattern.sub(new, source[plain_start:]))
    return "".join(out)


JUDGEMENT_ROLE_MACROS = {
    "syntax": "Syntax.hasCategory",
    "syntax_constructor": "Syntax.constructor",
    "annotation": "Type.annotation",
    "declaration": "Type.declaration",
    # Preserve object judgements through the later Type.judge -> Type.annotation rename chain.
    "object": "Type.ctx-judge",
}


def macro_call_positions(source: str, name: str) -> list[int]:
    """Return Macro call-token offsets outside opaque SNL literals."""
    pattern = re.compile(rf"(?<![A-Za-z0-9_.-]){re.escape(name)}(?=\s*(?:\[[^\]]*\])?\s*\()")
    positions: list[int] = []
    cursor = plain_start = 0
    while cursor < len(source):
        delim = "$$" if source.startswith("$$", cursor) else source[cursor] if source[cursor] in {"%", "$"} else None
        if delim is None:
            cursor += 1
            continue
        positions.extend(plain_start + match.start() for match in pattern.finditer(source[plain_start:cursor]))
        end = source.find(delim, cursor + len(delim))
        if end < 0:
            return positions
        cursor = plain_start = end + len(delim)
    positions.extend(plain_start + match.start() for match in pattern.finditer(source[plain_start:]))
    return positions


def judgement_call_positions(source: str) -> list[int]:
    return macro_call_positions(source, "Type.judge")


def rewrite_judgement_roles(source: str, roles: list[str]) -> str:
    positions = judgement_call_positions(source)
    assert len(positions) == len(roles), (len(positions), len(roles))
    out = source
    for position, role in reversed(list(zip(positions, roles))):
        replacement = JUDGEMENT_ROLE_MACROS[role]
        out = out[:position] + replacement + out[position + len("Type.judge"):]
    return out


def deep_exact_replace(value: Any, mapping: dict[str, str]) -> Any:
    if isinstance(value, str):
        return mapping.get(value, value)
    if isinstance(value, list):
        return [deep_exact_replace(x, mapping) for x in value]
    if isinstance(value, dict):
        return {k: deep_exact_replace(v, mapping) for k, v in value.items()}
    return value


def collect(directory: str, payload_key: str, identity_key: str):
    records: dict[str, dict[str, Any]] = {}
    envs: dict[str, dict[str, Any]] = {}
    paths: dict[str, Path] = {}
    for path in sorted((DOC / directory).glob("*.json")):
        env = load(path)
        assert set(env) in ({"format", "version", "package", payload_key}, {"format", "version", "schema_version", "package", payload_key}), path
        assert type(env["version"]) is int and env["version"] == 1
        if "schema_version" in env:
            assert type(env["schema_version"]) is int and env["schema_version"] == 1
        record = env[payload_key]
        ident = record[identity_key]
        assert ident not in records, ident
        assert env["package"] == record.get("package", env["package"])
        records[ident], envs[ident], paths[ident] = record, env, path
    return records, envs, paths


def canonical_entry(entry_id: str, kind: str, title_en: str, title_zh: str, *, snl: str = "", md_en: str = "", md_zh: str = "") -> dict[str, Any]:
    content: dict[str, Any] = {}
    if snl:
        content["snl"] = snl
    if md_en or md_zh:
        content["markdown"] = localized(md_en, md_zh)
    return {
        "id": entry_id, "package": "TypeTheory", "kind": kind,
        "title": localized(title_en, title_zh), "content": content,
        "contribution_info": None, "pointer": None,
    }


def doc_file_manifest() -> dict[str, str]:
    return {
        path.relative_to(ROOT).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(DOC.rglob("*")) if path.is_file()
    }


def git_head() -> str | None:
    result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, capture_output=True)
    return result.stdout.strip() if result.returncode == 0 else None


def main() -> None:
    entries, entry_envs, entry_paths = collect("entries", "entry", "id")
    macros, macro_envs, macro_paths = collect("macros", "macro", "name")
    all_original_entity_paths = set(entry_paths.values()) | set(macro_paths.values())
    packages = {load(p)["id"]: load(p) for p in sorted((DOC / "packages").glob("*.json"))}
    graphs = {p: load(p) for p in sorted((DOC / "libraries").glob("*/graph.json"))}
    rel_path = DOC / "relationships.json"
    relationships = load(rel_path)
    config_path = DOC / "config.json"
    config = load(config_path)

    authority = load(ROOT / "scripts" / "fulcrum-syntax-migration.json")
    assert set(authority) == {"version", "source_head", "entry_renames", "macro_renames", "accepted_predecessor_hashes", "canonical_hashes"}
    assert type(authority["version"]) is int and authority["version"] == 1
    assert authority["source_head"] == "bc09e62e7217ae4b65357eb46e8ad8487bb4ae24"
    assert authority["entry_renames"] == ENTRY_RENAMES
    macro_renames = authority["macro_renames"]
    assert all(macro_renames.get(name) == target for name, target in MACRO_RENAMES.items())
    for old_name, new_name in macro_renames.items():
        if old_name not in MACRO_RENAMES:
            assert any(old_name.startswith(a) and new_name == b + old_name[len(a):] for a, b in ONE_OFF_PREFIX_RENAMES.items())
    assert len(set(ENTRY_RENAMES.values())) == len(ENTRY_RENAMES)
    assert len(set(macro_renames.values())) == len(macro_renames)

    def payload_hash(value: Any) -> str:
        raw = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(raw.encode()).hexdigest()

    predecessor_mode = any(old in entries for old in ENTRY_RENAMES)
    manifest = load(ROOT / "scripts" / "fulcrum-doc-manifest.json")
    assert set(manifest) == {"version", "source_commit", "source_files", "canonical_files"}
    assert type(manifest["version"]) is int and manifest["version"] == 1
    assert manifest["source_commit"] == authority["source_head"]
    observed_doc_files = doc_file_manifest()
    if predecessor_mode:
        observed_head = git_head()
        if observed_head is not None:
            assert observed_head == authority["source_head"], "Git predecessor does not match the immutable source lease"
        assert observed_doc_files == manifest["source_files"], "complete predecessor .SNL_Doc manifest drift"
    else:
        assert manifest["canonical_files"], "canonical .SNL_Doc manifest is missing"
        assert observed_doc_files == manifest["canonical_files"], "complete canonical .SNL_Doc manifest drift"
    lease_group = authority["accepted_predecessor_hashes"] if predecessor_mode else authority["canonical_hashes"]
    for entry_id, expected in lease_group["entries"].items():
        assert entry_id in entries, f"missing leased Entry: {entry_id}"
        assert payload_hash(entries[entry_id]) == expected, f"leased Entry drift: {entry_id}"
    for macro_name, expected in lease_group["macros"].items():
        assert macro_name in macros, f"missing leased Macro: {macro_name}"
        assert payload_hash(macros[macro_name]) == expected, f"leased Macro drift: {macro_name}"

    role_authority = load(ROOT / "scripts" / "type-judgement-role-plan.json")
    assert set(role_authority) == {"version", "source_commit", "total_predecessor_calls", "role_counts", "entries"}
    assert type(role_authority["version"]) is int and role_authority["version"] == 1
    assert role_authority["source_commit"] == authority["source_head"]
    assert type(role_authority["total_predecessor_calls"]) is int and role_authority["total_predecessor_calls"] == 455
    assert set(role_authority["role_counts"]) == set(JUDGEMENT_ROLE_MACROS)
    assert sum(role_authority["role_counts"].values()) == 455
    if predecessor_mode:
        source_judgement_entries = {
            entry_id for entry_id, entry in entries.items()
            if judgement_call_positions((entry.get("content") or {}).get("snl") or "")
        }
        assert set(role_authority["entries"]) == source_judgement_entries, "judgement-role authority is not repository-complete"
        assert sum(len(judgement_call_positions((entry.get("content") or {}).get("snl") or "")) for entry in entries.values()) == role_authority["total_predecessor_calls"]
        observed_roles: dict[str, int] = {role: 0 for role in JUDGEMENT_ROLE_MACROS}
        observed_calls = 0
        for entry_id, lease in role_authority["entries"].items():
            assert set(lease) == {"source_snl_sha256", "source_package", "calls"}
            assert entry_id in entries and entries[entry_id]["package"] == lease["source_package"], entry_id
            snl = (entries[entry_id].get("content") or {}).get("snl")
            assert isinstance(snl, str)
            assert hashlib.sha256(snl.encode()).hexdigest() == lease["source_snl_sha256"], f"judgement source drift: {entry_id}"
            calls = lease["calls"]
            assert all(set(call) == {"path", "role"} for call in calls)
            assert [call["path"] for call in calls] == [f"preorder/{index}" for index in range(len(calls))]
            roles = [call["role"] for call in calls]
            assert all(role in JUDGEMENT_ROLE_MACROS for role in roles)
            assert len(judgement_call_positions(snl)) == len(roles)
            for role in roles:
                observed_roles[role] += 1
            observed_calls += len(roles)
            entries[entry_id]["content"]["snl"] = rewrite_judgement_roles(snl, roles)
        assert observed_calls == role_authority["total_predecessor_calls"]
        assert observed_roles == role_authority["role_counts"]

    # Rename Entry identities and all structured references.
    for old, new in ENTRY_RENAMES.items():
        assert not (old in entries and new in entries), f"split Entry identity: {old} / {new}"
        if old not in entries and new not in entries:
            assert new in RETIRED_CANONICAL_ENTRIES, f"missing Entry identity: {old}"
            continue
        if old in entries:
            record, env, path = entries.pop(old), entry_envs.pop(old), entry_paths.pop(old)
            record["id"] = new
            entries[new], entry_envs[new], entry_paths[new] = record, env, path
        for record in macros.values():
            source = record.get("source") or {}
            if isinstance(source.get("entries"), list):
                source["entries"] = [new if x == old else x for x in source["entries"]]
        for graph in graphs.values():
            for node in graph.get("nodes", []):
                if (node.get("props") or {}).get("entryId") == old:
                    node["props"]["entryId"] = new
        for row in relationships.get("relationships", []):
            if row.get("from") == old:
                row["from"] = new
            if row.get("to") == old:
                row["to"] = new
        for package in packages.values():
            package["entry_ids"] = [new if x == old else x for x in package.get("entry_ids", [])]

    # Rename Macro identities, then rewrite every structured SNL use. The
    # Type.judge -> Type.annotation -> (old Type.ctx-judge -> Type.judge)
    # chain intentionally leaves both target names in the canonical tree.
    rename_steps = list(macro_renames.items())
    judgement_already_split = "Type.ctx-judge" not in macros
    if judgement_already_split:
        assert "Type.annotation" in macros and "Type.judge" in macros, "incomplete canonical judgement split"
        rename_steps = [step for step in rename_steps if step[0] not in {"Type.judge", "Type.ctx-judge"}]
    for old, new in rename_steps:
        assert not (old in macros and new in macros), f"split Macro identity: {old} / {new}"
        assert old in macros or new in macros, f"missing Macro identity: {old}"
        if old in macros:
            record, env, path = macros.pop(old), macro_envs.pop(old), macro_paths.pop(old)
            record["name"] = new
            macros[new], macro_envs[new], macro_paths[new] = record, env, path
    for entry in entries.values():
        content = entry.get("content") or {}
        if isinstance(content.get("snl"), str):
            snl = content["snl"]
            rewrite_steps = macro_renames.items()
            if judgement_already_split:
                rewrite_steps = [step for step in rewrite_steps if step[0] not in {"Type.judge", "Type.ctx-judge"}]
            for old, new in rewrite_steps:
                snl = rewrite_identifier(snl, old, new)
            content["snl"] = snl

    # Canonical vocabulary Entries.
    additions = {
        "Syntax.sec.syntax": canonical_entry(
            "Syntax.sec.syntax", "section", "Syntax", "语法",
            md_en="Syntactic carriers and constructor signatures live at the metalanguage level. They are distinct from object-language typing judgements.",
            md_zh="语法载体与构造子签名属于元语言层，必须与对象语言的类型判断分开。"),
        "Syntax.def.signatureFragment": canonical_entry(
            "Syntax.def.signatureFragment", "definition", "Syntax-Signature Fragment", "语法签名片段",
            snl="def-hyp-opq(Syntax.hasCategory(@Expr,Syntax.SyntacticCategory),Syntax.signatureFragment(Expr,ctors(Syntax.constructor(@c,Type.to(Expr,Expr)))))",
            md_en="Assume the target syntactic category has already been defined. A fragment records only the constructors introduced here; it is non-exhaustive and does not determine a recursor.",
            md_zh="假设目标语法范畴已经定义。签名片段只记录此处新介绍的构造子；它并不穷尽构造子，也不能据此生成递归子。"),
        "Syntax.rmk.signatureFragment": canonical_entry(
            "Syntax.rmk.signatureFragment", "remark", "Fragments Are Not Datatype Definitions", "签名片段不是数据类型定义",
            md_en="Only the UTLC expression Entry in this library gives a complete inductive definition. Entries for other calculi are incremental presentations over assumed carriers.",
            md_zh="本 Library 中只有 UTLC 表达式条目给出完整归纳定义；其他演算的条目都是在假定载体上的增量描述。"),
        "Type.def.annotation": canonical_entry(
            "Type.def.annotation", "definition", "Metalinguistic Type Annotation", "元语言类型标注",
            snl="def-hyp-opq(Type.annotation(@x,@A),Type.annotation(x,A))",
            md_en="The colon annotation classifies an ordinary metalinguistic parameter. It is not an object-language typing derivation or a constructor declaration.",
            md_zh="冒号标注用于分类普通元语言参数，不是对象语言中的类型推导或构造子声明。"),
        "Type.def.declaration": canonical_entry(
            "Type.def.declaration", "definition", "Signature Declaration", "签名声明",
            snl="def-hyp-opq(Type.annotation(@c,@T),Type.declaration(c,T))",
            md_en="A declaration records the signature of an object constant, inductive constructor, or relation constructor. It is not a typing derivation.",
            md_zh="签名声明记录对象常量、归纳构造子或关系构造子的签名，不是类型推导。"),
    }
    for eid, record in additions.items():
        if eid in entries:
            # Existing canonical identity must already agree exactly.
            assert entries[eid] == record, f"drift in canonical Entry {eid}"
        else:
            entries[eid] = record
            entry_envs[eid] = {"format": "snl-entry", "version": 1, "schema_version": 1, "package": "TypeTheory", "entry": record}
            entry_paths[eid] = DOC / "entries" / "__new__.json"

    # Canonical syntax/judgement Macros.
    new_macros = {
        "Syntax.SyntacticCategory": macro("Syntax.SyntacticCategory", "const", "\\mathsf{SyntacticCategory}", "Syntax.def.signatureFragment"),
        "Syntax.hasCategory": macro("Syntax.hasCategory", "rule", "#0 \\in #1", "Syntax.def.signatureFragment"),
        "Syntax.constructor": macro("Syntax.constructor", "rule", "#0 : #1", "Syntax.def.signatureFragment"),
        "Syntax.signatureFragment": i18n_macro(
            "Syntax.signatureFragment",
            "Assuming #0 is already defined, record the following newly introduced constructors (non-exhaustive):\\n#1",
            "假设 #0 已经定义，记录以下新介绍的构造子（非穷尽）：\\n#1",
            "Syntax.def.signatureFragment"),
        "Type.declaration": macro("Type.declaration", "rule", "#0 : #1", "Type.def.declaration"),
        "Type.contextExtend": macro("Type.contextExtend", "rule", "#0, #1 : #2", "Type.def.ctx"),
        "Type.emptyContext": macro("Type.emptyContext", "const", "\\cdot", "Type.def.ctx"),
    }
    for name, record in new_macros.items():
        if name in macros:
            assert macros[name] == record, f"drift in canonical Macro {name}"
        else:
            macros[name] = record
            macro_envs[name] = {"format": "snl-macro", "version": 1, "schema_version": 1, "package": "TypeTheory", "macro": record}
            macro_paths[name] = DOC / "macros" / "__new__.json"

    # The two old macros are now separated by semantic layer.
    macros["Type.annotation"]["source"] = {"entries": ["Type.def.annotation"], "urls": []}
    macros["Type.judge"]["source"] = {"entries": ["Type.rl.judge"], "urls": []}
    expected_judge = "#0 \\vdash #1 : #2"
    assert any((s.get("template") or {}).get("body") == expected_judge for s in macros["Type.judge"]["styles"]), "object judgement rendering drift"

    # Only UTLC Expr is exhaustive. Open and STLC syntax are explicit fragments.
    entries["Syntax.def.expression-UTLC"]["content"]["snl"] = (
        "def-inductive(Syntax.Expr-UTLC,ctors("
        "Syntax.constructor(Syntax.Expr-UTLC.lambda[text],Type.to(Syntax.Expr-UTLC,Syntax.Expr-UTLC)),"
        "Syntax.constructor(Syntax.Expr-UTLC.apply[text],Type.to(Syntax.Expr-UTLC,Type.to(Syntax.Expr-UTLC,Syntax.Expr-UTLC))),"
        "Syntax.constructor(Syntax.Expr-UTLC.bvar[text],Type.to(Nat,Syntax.Expr-UTLC))))")
    entries["Syntax.def.openExpression-UTLC"]["content"]["snl"] = (
        "Syntax.signatureFragment(Syntax.OpenExpr-UTLC,ctors("
        "Syntax.constructor(Syntax.Expr-UTLC.closed[text],Type.to(Syntax.Expr-UTLC,Syntax.OpenExpr-UTLC)),"
        "Syntax.constructor(Syntax.Expr-UTLC.fvar[text],Type.to(`string`,Syntax.OpenExpr-UTLC)),"
        "Syntax.constructor(Syntax.Expr-UTLC.lambda[text],Type.to(Syntax.OpenExpr-UTLC,Syntax.OpenExpr-UTLC)),"
        "Syntax.constructor(Syntax.Expr-UTLC.apply[text],Type.to(Syntax.OpenExpr-UTLC,Type.to(Syntax.OpenExpr-UTLC,Syntax.OpenExpr-UTLC)))))")
    entries["Syntax.def.expression-STLC"]["content"]["snl"] = (
        "Syntax.signatureFragment(Syntax.Expr,ctors("
        "Syntax.constructor(%typed lambda%,Type.to(Syntax.TypeExpr,Type.to(Syntax.Expr,Syntax.Expr))),"
        "Syntax.constructor(%bound variable%,Type.to(Nat,Syntax.Expr)),"
        "Syntax.constructor(%application%,Type.to(Syntax.Expr,Type.to(Syntax.Expr,Syntax.Expr)))))")
    entries["Syntax.def.expression-STLC"]["content"]["markdown"] = localized(
        "Assume the STLC expression carrier is already available. This Entry records only the term constructors used here and is not an exhaustive datatype declaration.",
        "假设 STLC 表达式载体已经给定。本条目只记录此处使用的项构造子，不是穷尽的数据类型声明。")
    entries["Syntax.def.typeExpression-STLC"]["content"] = {
        "snl": "Syntax.signatureFragment(Syntax.TypeExpr,ctors(Syntax.constructor(%function type%,Type.to(Syntax.TypeExpr,Type.to(Syntax.TypeExpr,Syntax.TypeExpr)))))",
        "markdown": localized(
            "Assume the STLC type-expression carrier is already available; only the function-type constructor is introduced here.",
            "假设 STLC 类型表达式载体已经给定；此处只介绍函数类型构造子。")}
    no_rec = entries["Syntax.rmk.expressionSTLCNoRecursor"]
    no_rec["kind"] = "remark"
    no_rec["title"] = localized("No Recursor from a Signature Fragment", "签名片段不生成递归子")
    no_rec["content"] = {"markdown": localized(
        "Because the STLC Entry is non-exhaustive, it does not define a recursor. A recursor requires a separately supplied complete syntax definition.",
        "由于 STLC 条目并不穷尽构造子，它不会定义递归子；递归子必须来自另行给出的完整语法定义。")}

    # The exact role authority has already separated annotations, declarations,
    # syntax-category assumptions, and syntax constructors by predecessor call path.

    # Reconcile dependency metadata for predecessor Type.judge calls whose exact
    # per-occurrence role migration changed the referenced Macro and Entry.
    role_dependencies = {
        "annotation": ("Type.annotation", "Type.def.annotation"),
        "declaration": ("Type.declaration", "Type.def.declaration"),
        "syntax": ("Syntax.hasCategory", "Syntax.def.signatureFragment"),
        "syntax_constructor": ("Syntax.constructor", "Syntax.def.signatureFragment"),
        "object": ("Type.judge", "Type.rl.judge"),
    }
    relation_rows = relationships["relationships"]
    allocated_relation_ids = {row["id"] for row in relation_rows}
    for source_entry_id, spec in role_authority["entries"].items():
        entry_id = ENTRY_RENAMES.get(source_entry_id, source_entry_id)
        migrated_rows = [row for row in relation_rows if row["from"] == entry_id and row["to"] == "Type.rl.judge" and "Type.judge" in row["metadata"].get("macros", [])]
        if not migrated_rows:
            continue
        roles = {call["role"] for call in spec["calls"]}
        for row in migrated_rows:
            witnesses = [name for name in row["metadata"]["macros"] if name != "Type.judge"]
            if "object" in roles:
                witnesses.append("Type.judge")
            row["metadata"]["macros"] = sorted(set(witnesses))
        relation_rows[:] = [row for row in relation_rows if row not in migrated_rows or row["metadata"]["macros"]]
        for role in sorted(roles - {"object"}):
            macro_name, target_entry = role_dependencies[role]
            existing = next((row for row in relation_rows if row["from"] == entry_id and row["to"] == target_entry), None)
            if existing is not None:
                existing["metadata"]["macros"] = sorted(set(existing["metadata"].get("macros", [])) | {macro_name})
                continue
            base = f"dep.{entry_id}.{target_entry}"
            relation_id = base
            suffix = 1
            while relation_id in allocated_relation_ids:
                relation_id = f"{base}.{suffix}"
                suffix += 1
            allocated_relation_ids.add(relation_id)
            relation_rows.append({
                "id": relation_id,
                "from": entry_id,
                "to": target_entry,
                "label": "depends",
                "metadata": {"generator": "macro-source-scan", "macros": [macro_name], "isAtomic": True},
            })

    # Object-language judgement is always the three-place Γ ⊢ t : T relation.
    entries["Type.rl.judge"]["content"]["snl"] = "def-hyp-opq(Type.ctx(@Γ),Type.judge(Γ,@t,@T))"
    object_updates = {
        "Type.rl.fun": "def-hyp-opq(list-partial(Type.judge(@Γ,@A,Type[univ](@u)),Type.judge(Γ,@B,Type[univ](@v))),Type.judge(Γ,Type.to(A,B),Type[univ](\\max(u,v))))",
        "Type.rl.pi": "def-hyp-opq(list-partial(Type.judge(@Γ,@T,Type[univ](@u)),Type.judge(Type.contextExtend(Γ,@x,T),@B,Type[univ](@v))),Type.judge(Γ,Type.Pi(@x,T,B),Type[univ](\\max(u,v))))",
        "Type.ppt.PropImpredicativePi": "thm-hyp(list-partial(Type.judge(@Γ,@A,Type[univ](@u)),Type.judge(Type.contextExtend(Γ,@x,A),@P,Proposition)),Type.judge(Γ,Type.Pi(@x,A,P),Proposition))",
        "Type.ppt.pi-judge": "thm-hyp(list-partial(Type.judge(@Γ,@T,Type[univ](@u)),Type.judge(Type.contextExtend(Γ,@x,T),@e,Type[univ](@v))),Type.judge(Γ,Type.Pi(@x,T,e),Type[univ](\\max(u,v))))",
        "Type.rmk.PropUniverseBehavior": "list-partial[none](%Lean%,Type.judge(Type.emptyContext,Proposition,Type[univ](0)),Type.judge(Type.emptyContext,Type[univ](@u),Type[univ](Nat.succ(u))))",
    }
    for eid, snl in object_updates.items():
        assert eid in entries, eid
        entries[eid].setdefault("content", {})["snl"] = snl
    entries["Type.ppt.pi-judge"]["title"] = localized(
        "Universe Level of $\\Pi$-Types", "$\\Pi$ 类型的宇宙层级")

    # A signature fragment is non-exhaustive and cannot publish a generated recursor.
    retired_fragment_recursors = RETIRED_CANONICAL_ENTRIES
    for retired in retired_fragment_recursors:
        if retired in entries:
            entries.pop(retired)
            entry_envs.pop(retired)
            entry_paths.pop(retired)
    for graph in graphs.values():
        removed_nodes = {node["id"] for node in graph.get("nodes", []) if node["props"]["entryId"] in retired_fragment_recursors}
        graph["nodes"] = [node for node in graph.get("nodes", []) if node["id"] not in removed_nodes]
        graph["relationships"] = [edge for edge in graph.get("relationships", []) if edge["from"] not in removed_nodes and edge["to"] not in removed_nodes]
    relationships["relationships"] = [relation for relation in relationships["relationships"] if relation["from"] not in retired_fragment_recursors and relation["to"] not in retired_fragment_recursors]
    for macro_record in macros.values():
        source = macro_record.get("source") or {}
        if "entries" in source:
            source["entries"] = [entry_id for entry_id in source["entries"] if entry_id not in retired_fragment_recursors]

    # Build a standalone summary Library. Reusing Entries across graphs is intentional.
    library_sections = [
        ("Syntax.sec.syntax", ["Syntax.def.signatureFragment", "Syntax.rmk.signatureFragment"]),
        ("Syntax.def.expression-UTLC", [
            "Syntax.def.expression-UTLC.ctor.lambdaAbstraction", "Syntax.def.expression-UTLC.ctor.application",
            "Syntax.def.expression-UTLC.ctor.boundVariable", "Syntax.def.expression-UTLC.recursor",
            "Syntax.rmk.lambdaNotation-UTLC", "Syntax.rmk.applicationNotation-UTLC", "Syntax.rmk.deBruijnIndex",
            "Syntax.rmk.closedExpression-UTLC", "Syntax.def.legalExpression-UTLC", "Syntax.def.shift-UTLC",
            "Syntax.def.substitution-UTLC"]),
        ("Syntax.def.openExpression-UTLC", [
            "Syntax.def.openExpression-UTLC.ctor.closedExpression", "Syntax.def.openExpression-UTLC.ctor.freeVariable",
            "Syntax.def.openExpression-UTLC.ctor.lambdaAbstraction", "Syntax.def.openExpression-UTLC.ctor.application",
            "Syntax.rmk.freeVariableOpenExpression-UTLC"]),
        ("Syntax.def.expression-STLC", [
            "Syntax.def.expression-STLC.ctor.lambdaAbstraction", "Syntax.def.expression-STLC.ctor.application",
            "Syntax.def.expression-STLC.ctor.boundVariable", "Syntax.def.typeExpression-STLC",
            "Syntax.def.expression-STLC.ctor.functionType", "Syntax.rmk.expressionSTLCNoRecursor"]),
        ("Syntax.subsec.patternMatching", []),
    ]
    ordered_ids: list[str] = []
    for parent, children in library_sections:
        if parent not in ordered_ids:
            ordered_ids.append(parent)
        for child in children:
            if child not in ordered_ids:
                ordered_ids.append(child)
    assert set(ordered_ids) <= set(entries), sorted(set(ordered_ids) - set(entries))
    syntax_counter_path = DOC / "libraries" / "Syntax" / "counters.json"
    syntax_counters = load(DOC / "libraries" / "Type_Theory" / "counters.json")

    def counter_id_named(children: list[dict[str, Any]], name: str) -> str | None:
        for counter in children:
            if counter.get("name") == name:
                return counter["id"]
            nested = counter_id_named(counter.get("children", []), name)
            if nested is not None:
                return nested
        return None

    subentry_counter_id = counter_id_named(syntax_counters["counters"], "Subentry")
    assert subentry_counter_id is not None
    subentry_nodes = {
        "Syntax.rmk.closedExpression-UTLC",
        "Syntax.rmk.freeVariableOpenExpression-UTLC",
    }
    nodes = []
    for i, eid in enumerate(ordered_ids):
        props: dict[str, Any] = {"entryId": eid}
        if eid in subentry_nodes:
            props["counterId"] = subentry_counter_id
        nodes.append({"id": f"syntax_n_{i+1}", "label": "Entry", "props": props})
    node_id = {n["props"]["entryId"]: n["id"] for n in nodes}
    branches: list[tuple[str, str]] = []
    # The root summarizes each major syntax family.
    for major in ["Syntax.def.expression-UTLC", "Syntax.def.openExpression-UTLC", "Syntax.def.expression-STLC", "Syntax.subsec.patternMatching"]:
        branches.append(("Syntax.sec.syntax", major))
    for parent, children in library_sections:
        branch_children = list(children)
        if parent == "Syntax.def.expression-UTLC":
            # The inductive authority places the closed-expression subentry
            # immediately before the generated recursor. Construct that exact
            # canonical sibling order here without changing stable node IDs.
            branch_children.remove("Syntax.rmk.closedExpression-UTLC")
            branch_children.insert(branch_children.index("Syntax.def.expression-UTLC.recursor"), "Syntax.rmk.closedExpression-UTLC")
        branches.extend((parent, child) for child in branch_children)
    graph = {
        "nodes": nodes,
        "relationships": [
            {"from": node_id[a], "to": node_id[b], "label": "branch"}
            for a, b in branches
        ],
    }
    syntax_graph_path = DOC / "libraries" / "Syntax" / "graph.json"
    graphs[syntax_graph_path] = graph

    # Recompute TypeTheory manifest after additions/renames.
    by_package: dict[str, set[str]] = {}
    for eid, entry in entries.items():
        by_package.setdefault(entry["package"], set()).add(eid)
    for package_id, package in packages.items():
        values = list(by_package.get(package_id, set()))
        result = subprocess.run(
            ["node", "-e", "let s='';process.stdin.on('data',x=>s+=x).on('end',()=>process.stdout.write(JSON.stringify(JSON.parse(s).sort((a,b)=>a.localeCompare(b)))))"],
            input=json.dumps(values), text=True, capture_output=True, check=True)
        package["entry_ids"] = json.loads(result.stdout)

    # Validate identity closure and the semantic hard gates before any write.
    assert not (set(ENTRY_RENAMES) & set(entries)), "old Syntax Entry IDs remain"
    retired_old_macro_names = set(macro_renames) - set(macro_renames.values())
    assert not (retired_old_macro_names & set(macros)), "old Syntax Macro names remain"
    assert set(entries) == {e["id"] for e in entries.values()}
    assert set(macros) == {m["name"] for m in macros.values()}
    for entry in entries.values():
        snl = (entry.get("content") or {}).get("snl", "")
        assert "Type.ctx-judge(" not in snl
    object_snl = [entries[eid]["content"]["snl"] for eid in object_updates] + [entries["Type.rl.judge"]["content"]["snl"]]
    assert all("Type.judge(" in snl for snl in object_snl)
    assert all("Type.annotation(" not in snl for snl in object_snl)
    role_sequence_replaced_entries = {
        "Syntax.def.expression-UTLC", "Syntax.def.openExpression-UTLC", "Syntax.def.expression-STLC", "Syntax.def.typeExpression-STLC",
        *object_updates.keys(), "Type.rl.judge",
    }
    canonical_role_macros = {
        "syntax": "Syntax.hasCategory", "syntax_constructor": "Syntax.constructor",
        "annotation": "Type.annotation", "declaration": "Type.declaration", "object": "Type.judge",
    }
    for source_entry_id, lease in role_authority["entries"].items():
        canonical_entry_id = ENTRY_RENAMES.get(source_entry_id, source_entry_id)
        if canonical_entry_id in role_sequence_replaced_entries:
            assert canonical_entry_id in authority["canonical_hashes"]["entries"]
            continue
        snl = (entries[canonical_entry_id].get("content") or {}).get("snl") or ""
        observed = []
        for role, macro_name in canonical_role_macros.items():
            observed.extend((position, role) for position in macro_call_positions(snl, macro_name))
        observed_roles = [role for _, role in sorted(observed)]
        expected_roles = [call["role"] for call in lease["calls"]]
        assert observed_roles == expected_roles, f"canonical judgement-role drift: {canonical_entry_id}: {observed_roles} != {expected_roles}"

    semantic_counts = {name: 0 for name in ["Type.judge", "Type.annotation", "Type.declaration", "Syntax.hasCategory", "Syntax.constructor"]}
    judgement_entries: set[str] = set()
    for entry_id, entry in entries.items():
        snl = (entry.get("content") or {}).get("snl") or ""
        for name in semantic_counts:
            count = len(macro_call_positions(snl, name))
            semantic_counts[name] += count
            if name == "Type.judge" and count:
                judgement_entries.add(entry_id)
        if macro_call_positions(snl, "Type.judge"):
            assert "ctors(" not in snl and "Syntax.signatureFragment(" not in snl, entry_id
    accepted_semantic_counts = [
        {"Type.judge": 15, "Type.annotation": 379, "Type.declaration": 32, "Syntax.hasCategory": 22, "Syntax.constructor": 12},
        {"Type.judge": 20, "Type.annotation": 379, "Type.declaration": 32, "Syntax.hasCategory": 23, "Syntax.constructor": 12},
    ]
    assert semantic_counts in accepted_semantic_counts, semantic_counts
    expected_object_entries = {
        ENTRY_RENAMES.get(source_entry_id, source_entry_id)
        for source_entry_id, lease in role_authority["entries"].items()
        if any(call["role"] == "object" for call in lease["calls"])
    } | {"Type.rl.judge"}
    adopted_object_entries = {"Type.axm.ProofIrrelevance", "Type.thm.GirardParadox", "Logic.axm.em"}
    expected_object_entries |= adopted_object_entries & set(entries)
    assert judgement_entries == expected_object_entries, sorted(judgement_entries ^ expected_object_entries)
    assert not macro_call_positions(entries["Syntax.def.expression-UTLC.ctor.boundVariable"]["content"]["snl"], "Syntax.hasCategory")
    assert not macro_call_positions(entries["Syntax.def.openExpression-UTLC.ctor.freeVariable"]["content"]["snl"], "Syntax.hasCategory")
    empty_context_bodies = [(style.get("template") or {}).get("body") for style in macros["Type.emptyContext"]["styles"]]
    assert "\\cdot" in empty_context_bodies and "\\varnothing" not in empty_context_bodies
    assert entries["Syntax.def.expression-UTLC"]["content"]["snl"].startswith("def-inductive(")
    for eid in ["Syntax.def.openExpression-UTLC", "Syntax.def.expression-STLC", "Syntax.def.typeExpression-STLC"]:
        assert "Syntax.signatureFragment(" in entries[eid]["content"]["snl"]
        assert "def-inductive(" not in entries[eid]["content"]["snl"]
    all_graph_refs = {n["props"]["entryId"] for graph in graphs.values() for n in graph.get("nodes", [])}
    assert all_graph_refs <= set(entries), sorted(all_graph_refs - set(entries))
    assert all(finite(x) for x in [entries, macros, packages, graphs, relationships, config])
    for entry_id, expected in authority["canonical_hashes"]["entries"].items():
        assert payload_hash(entries[entry_id]) == expected, f"canonical Entry drift after migration: {entry_id}"
    for macro_name, expected in authority["canonical_hashes"]["macros"].items():
        assert payload_hash(macros[macro_name]) == expected, f"canonical Macro drift after migration: {macro_name}"

    # Final in-memory envelopes and canonical paths.
    target_files: dict[Path, str] = {}
    old_entity_paths = all_original_entity_paths
    for eid, entry in entries.items():
        package_id = entry["package"]
        env = entry_envs[eid]
        env["package"] = package_id
        env["entry"] = entry
        path = DOC / "entries" / f"{package_id}-{identity_hash('entry', package_id, eid)}.json"
        target_files[path] = dump(env)
    for name, record in macros.items():
        env = macro_envs[name]
        package_id = env["package"]
        env["macro"] = record
        path = DOC / "macros" / f"{package_id}-{identity_hash('macro', package_id, name)}.json"
        target_files[path] = dump(env)
    for package_id, package in packages.items():
        path = DOC / "packages" / f"{package_id}-{identity_hash('package', package_id)}.json"
        target_files[path] = dump(package)
    for path, value in graphs.items():
        target_files[path] = dump(value)
    target_files[syntax_counter_path] = dump(syntax_counters)
    target_files[rel_path] = dump(relationships)
    target_files[config_path] = dump(config)
    assert len(target_files) == len(set(target_files))

    # Filesystem mutation starts here.
    for path in sorted(old_entity_paths):
        if path not in target_files:
            path.unlink(missing_ok=True)
    for path, text in sorted(target_files.items(), key=lambda kv: str(kv[0])):
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists() or path.read_text(encoding="utf-8") != text:
            path.write_text(text, encoding="utf-8")

    print(json.dumps({
        "status": "PASS", "entries": len(entries), "macros": len(macros),
        "syntax_library_entries": len(nodes), "object_judgement": "Γ ⊢ t : T",
        "complete_expr_definitions": ["Syntax.def.expression-UTLC"],
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
