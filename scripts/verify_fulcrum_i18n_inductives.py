#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / ".SNL_Doc"
PLAN = json.loads((ROOT / "scripts/fulcrum-inductive-subentries.json").read_text(encoding="utf-8"))
I18N = json.loads((ROOT / "scripts/fulcrum-i18n-en-zh.json").read_text(encoding="utf-8"))
EXPECTED_ENTRIES = 452  # user baseline 440 + 6 new ordinary Entries + 6 W/enum children
EXPECTED_MACROS = 393
EXPECTED_DARK_ENTRY_STROKES = {
    "section": "#CBD5E1", "subsection": "#94A3B8", "definition": "#4ADE80",
    "axiom": "#FACC15", "theorem": "#60A5FA", "lemma": "#93C5FD",
    "corollary": "#7DD3FC", "property": "#E879F9", "remark": "#FB923C",
    "example": "#C084FC", "counterexample": "#FB7185", "construction": "#A3A3A3",
    "proof": "#D1D5DB", "problem": "#38BDF8", "context": "#A78BFA", "ctor": "#A3E635",
}
EXPECTED_DARK_MACRO_STROKES = {
    "rule": "#4ADE80", "const": "#60A5FA", "bvar": "#C084FC",
    "binder": "#FB923C", "fvar": "#FB7185",
}


def load_entities(directory: str, key: str):
    records = {}
    paths = {}
    for path in sorted((DOC / directory).glob("*.json")):
        envelope = json.loads(path.read_text(encoding="utf-8"))
        record = envelope[key]
        identity = record["id"] if key == "entry" else record["name"]
        assert identity not in records, f"duplicate {key} identity: {identity}"
        records[identity] = record
        paths[identity] = path
    return records, paths


def identity_hash(kind: str, *segments: str) -> str:
    raw = "snl-doc/v1\0" + kind + "\0" + "\0".join(segments)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:20]


def i18n_values(value, label: str):
    assert isinstance(value, dict) and value.get("type") == "i18n", f"{label} is not I18n"
    assert value.get("default_language") in {"en", "zh-CN"}, f"{label} has invalid default language"
    values = value.get("values")
    assert isinstance(values, dict), f"{label} has invalid values"
    assert set(values) == {"en", "zh-CN"}, f"{label} must have exactly en and zh-CN"
    assert all(isinstance(values[k], str) and values[k].strip() for k in ("en", "zh-CN")), f"{label} has empty projection"
    return values


def placeholder_signature(text: str):
    return tuple(sorted(set(re.findall(r"(?<!\\)#(?:\*|\d+)", text))))


def js_locale_sorted(values: list[str]) -> list[str]:
    result = subprocess.run(
        ["node", "-e", "let s='';process.stdin.on('data',x=>s+=x).on('end',()=>process.stdout.write(JSON.stringify(JSON.parse(s).sort((a,b)=>a.localeCompare(b)))))"],
        input=json.dumps(values), text=True, capture_output=True, check=True
    )
    return json.loads(result.stdout)


def is_lexical(text: str) -> bool:
    return bool(re.search(r"[A-Za-z\u4e00-\u9fff]", text))


config = json.loads((DOC / "config.json").read_text(encoding="utf-8"))
entry_kinds = {kind["id"]: kind for kind in config["entry_kinds"]}
assert set(entry_kinds) == set(EXPECTED_DARK_ENTRY_STROKES), "Fulcrum Entry Kind catalog changed"
for kind_id, stroke in EXPECTED_DARK_ENTRY_STROKES.items():
    assert entry_kinds[kind_id]["coloring"]["dark"] == {"stroke": stroke, "background": "#313131"}, f"dark Entry palette drift: {kind_id}"
macro_kinds = {kind["id"]: kind for kind in config["macro_kinds"]}
assert set(macro_kinds) == set(EXPECTED_DARK_MACRO_STROKES) | {"partial"}, "Fulcrum Macro Kind catalog or transparent exception changed"
for kind_id, stroke in EXPECTED_DARK_MACRO_STROKES.items():
    assert macro_kinds[kind_id]["coloring"]["dark"] == {"stroke": stroke, "background": "#313131"}, f"dark Macro palette drift: {kind_id}"
assert macro_kinds["partial"]["coloring"]["dark"] == {"stroke": "inherit", "background": "transparent"}

entries, entry_paths = load_entities("entries", "entry")
macros, macro_paths = load_entities("macros", "macro")
assert len(macros) == EXPECTED_MACROS, f"Macro count changed: {len(macros)}"
assert len(entries) == EXPECTED_ENTRIES, f"unexpected Entry count: {len(entries)}"
assert I18N.get("source_head") == "14e7c49b7c4895c7b2c6ae32dd96eba3fdc58681", "I18n map source lease changed"
assert len(I18N.get("entries", {})) == 378, "I18n Entry mapping coverage changed"
assert len(I18N.get("styles", {})) == 83, "I18n Macro-style mapping coverage changed"

for entry_id, projection in I18N["entries"].items():
    assert entry_id in entries, f"I18n map references missing Entry {entry_id}"
    if "title" in projection:
        assert i18n_values(entries[entry_id]["title"], f"mapped Entry {entry_id} title") == projection["title"]
    if "markdown" in projection:
        assert i18n_values(entries[entry_id]["content"]["markdown"], f"mapped Entry {entry_id} markdown") == projection["markdown"]

# Every Entry surface that supports localization must expose complete English and Chinese projections.
for entry_id, entry in entries.items():
    i18n_values(entry.get("title"), f"Entry {entry_id} title")
    content = entry.get("content") or {}
    if "markdown" in content:
        i18n_values(content["markdown"], f"Entry {entry_id} markdown")

# Every lexical text-mode Macro projection must be localized; structural modes stay invariant.
for macro_name, macro in macros.items():
    for style in macro.get("styles", []):
        label = f"Macro {macro_name}[{style.get('style_name')}]"
        template = style.get("template")
        if isinstance(template, dict) and template.get("type") == "i18n":
            values = template.get("values")
            assert isinstance(values, dict) and set(values) == {"en", "zh-CN"}, f"{label} incomplete I18n"
            assert template.get("default_language") in values, f"{label} invalid default language"
            en = values["en"]
            zh = values["zh-CN"]
            assert en.get("mode") == zh.get("mode") == "text", f"{label} localizes a structural mode"
            assert placeholder_signature(en.get("body", "")) == placeholder_signature(zh.get("body", "")), f"{label} placeholder mismatch"
        else:
            assert isinstance(template, dict), f"{label} invalid template"
            body = template.get("body", "")
            if template.get("mode") == "text" and isinstance(body, str) and is_lexical(body):
                raise AssertionError(f"{label} lexical text is not localized")

for key, projection in I18N["styles"].items():
    macro_name, style_name = key.split("::", 1)
    assert macro_name in macros, f"I18n map references missing Macro {macro_name}"
    styles = [style for style in macros[macro_name]["styles"] if style["style_name"] == style_name]
    assert len(styles) == 1, f"mapped Macro style is not unique: {key}"
    values = styles[0]["template"]["values"]
    assert values["en"]["body"] == projection["en"] and values["zh-CN"]["body"] == projection["zh-CN"], f"mapped Macro body mismatch: {key}"

# Requested Entries have exactly the planned content and graph placement.
all_expected_new = []
for spec in PLAN["requested_entries"]:
    all_expected_new.append(spec)
    entry = entries.get(spec["id"])
    assert entry is not None, f"missing requested Entry {spec['id']}"
    assert entry["package"] == spec["package"] and entry["kind"] == spec["kind"]
    content_spec = spec.get("content", {})
    expected_content = {}
    if "snl" in content_spec:
        expected_content["snl"] = content_spec["snl"]
    if "markdown" in content_spec:
        expected_content["markdown"] = {"type": "i18n", "default_language": "en", "values": content_spec["markdown"]}
    assert entry.get("content") == expected_content, f"wrong requested Entry content: {spec['id']}"
    assert i18n_values(entry["title"], f"requested Entry {spec['id']} title") == spec["title"]

for update in PLAN.get("entry_updates", []):
    entry = entries.get(update["id"])
    assert entry is not None, f"missing updated Entry {update['id']}"
    assert entry.get("content", {}).get("snl") == update["content_snl"], f"Entry update did not land: {update['id']}"
for update in PLAN.get("metadata_updates", []):
    entry = entries.get(update["id"])
    assert entry is not None, f"missing metadata-updated Entry {update['id']}"
    assert entry.get("kind") == update["kind"], f"Entry metadata update did not land: {update['id']}"

for update in PLAN.get("macro_source_updates", []):
    macro = macros.get(update["name"])
    assert macro is not None, f"missing source-updated Macro {update['name']}"
    assert macro.get("source", {}).get("entries") == update["entries"], f"Macro source update did not land: {update['name']}"

# Every audited inductive type has constructor and recursor definition subentries, all still empty.
child_specs = []
for inductive in PLAN["inductive_types"]:
    parent_id = inductive["parent_entry_id"]
    assert parent_id in entries, f"missing inductive parent {parent_id}"
    assert entries[parent_id]["package"] == inductive["package"], f"parent package mismatch: {parent_id}"
    children = [*inductive["constructors"], inductive["recursor"]]
    child_specs.extend((parent_id, inductive["package"], child) for child in children)
    for child in children:
        entry = entries.get(child["id"])
        assert entry is not None, f"missing inductive subentry {child['id']}"
        assert entry["package"] == inductive["package"], f"subentry package mismatch: {child['id']}"
        assert entry["kind"] == "definition", f"subentry is not a definition: {child['id']}"
        assert entry.get("content") == {}, f"subentry content must be empty: {child['id']}"
        assert i18n_values(entry["title"], f"subentry {child['id']} title") == child["title"]

# Entity paths and package manifests are canonical and complete.
manifest_members = {}
for path in sorted((DOC / "packages").glob("*.json")):
    manifest = json.loads(path.read_text(encoding="utf-8"))
    package_id = manifest["id"]
    expected_name = f"{package_id}-{identity_hash('package', package_id)}.json"
    assert path.name == expected_name, f"noncanonical Package path: {path.name}"
    ids = manifest.get("entry_ids", [])
    assert ids == js_locale_sorted(ids), f"unsorted package membership: {package_id}"
    assert len(ids) == len(set(ids)), f"duplicate package membership: {package_id}"
    manifest_members[package_id] = set(ids)
for entry_id, entry in entries.items():
    package_id = entry["package"]
    assert entry_paths[entry_id].name == f"{package_id}-{identity_hash('entry', package_id, entry_id)}.json", f"noncanonical Entry path: {entry_id}"
    assert entry_id in manifest_members.get(package_id, set()), f"Entry missing from package manifest: {entry_id}"
for package_id, ids in manifest_members.items():
    actual = {entry_id for entry_id, entry in entries.items() if entry["package"] == package_id}
    assert ids == actual, f"package membership mismatch: {package_id}"
for macro_name, macro in macros.items():
    package_id = json.loads(macro_paths[macro_name].read_text(encoding="utf-8"))["package"]
    assert macro_paths[macro_name].name == f"{package_id}-{identity_hash('macro', package_id, macro_name)}.json", f"noncanonical Macro path: {macro_name}"

# Every parent occurrence in a Library graph has a branch to each requested child/subentry occurrence.
expected_relations = [(spec["parent_entry_id"], spec["id"], spec.get("parent_node_ids"), spec.get("after_entry_id")) for spec in PLAN["requested_entries"]]
expected_relations.extend((spec["parent_entry_id"], spec["entry_id"], spec.get("parent_node_ids"), spec.get("after_entry_id")) for spec in PLAN.get("graph_references", []))
for inductive in PLAN["inductive_types"]:
    children = [*inductive["constructors"], inductive["recursor"]]
    expected_relations.extend(
        (
            inductive["parent_entry_id"], child["id"], None,
            children[index - 1]["id"] if inductive.get("ordered_children") and index else None
        )
        for index, child in enumerate(children)
    )
for parent_id, child_id, allowed_parent_node_ids, after_entry_id in expected_relations:
    parent_occurrences = 0
    attached_occurrences = 0
    for graph_path in sorted((DOC / "libraries").glob("*/graph.json")):
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
        nodes = graph.get("nodes", [])
        by_id = {node["id"]: node for node in nodes}
        assert len(by_id) == len(nodes), f"duplicate graph node id in {graph_path}"
        all_parent_nodes = [node["id"] for node in nodes if node.get("props", {}).get("entryId") == parent_id]
        parent_nodes = all_parent_nodes if allowed_parent_node_ids is None else [node_id for node_id in all_parent_nodes if node_id in set(allowed_parent_node_ids)]
        child_nodes = {node["id"] for node in nodes if node.get("props", {}).get("entryId") == child_id}
        parent_occurrences += len(parent_nodes)
        relations = graph.get("relationships", [])
        if allowed_parent_node_ids is not None:
            disallowed = set(all_parent_nodes) - set(parent_nodes)
            assert not any(rel.get("from") in disallowed and rel.get("to") in child_nodes and rel.get("label") == "branch" for rel in relations), f"requested Entry attached to a wrong parent occurrence: {parent_id} -> {child_id}"
        for parent_node in parent_nodes:
            if any(rel.get("from") == parent_node and rel.get("to") in child_nodes and rel.get("label") == "branch" for rel in relations):
                attached_occurrences += 1
            if after_entry_id is not None:
                sibling_nodes = [rel.get("to") for rel in relations if rel.get("from") == parent_node and rel.get("label") == "branch"]
                sibling_entries = [by_id[node_id].get("props", {}).get("entryId") for node_id in sibling_nodes]
                assert sibling_entries.count(after_entry_id) == 1 and sibling_entries.count(child_id) == 1, f"placement entries missing or ambiguous: {after_entry_id} -> {child_id}"
                assert sibling_entries.index(child_id) == sibling_entries.index(after_entry_id) + 1, f"wrong sibling order: {child_id} must immediately follow {after_entry_id}"
    assert parent_occurrences > 0, f"parent absent from all Library graphs: {parent_id}"
    assert attached_occurrences == parent_occurrences, f"subentry not attached to every parent occurrence: {parent_id} -> {child_id}"

# All graph identities, counter references, relationships, and reachability are valid.
for graph_path in sorted((DOC / "libraries").glob("*/graph.json")):
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    nodes = graph.get("nodes", [])
    node_ids = [node["id"] for node in nodes]
    assert len(node_ids) == len(set(node_ids)), f"duplicate graph node id in {graph_path}"
    node_id_set = set(node_ids)
    for node in nodes:
        entry_id = node.get("props", {}).get("entryId")
        assert entry_id in entries, f"unknown graph Entry {entry_id} in {graph_path}"
    counters_path = graph_path.parent / "counters.json"
    counters = json.loads(counters_path.read_text(encoding="utf-8")).get("counters", []) if counters_path.exists() else []
    counter_ids = set()
    counter_stack = counters[:]
    while counter_stack:
        counter = counter_stack.pop()
        counter_ids.add(counter["id"])
        counter_stack.extend(counter.get("children", []))
    assert all(node.get("props", {}).get("counterId") is None or node.get("props", {}).get("counterId") in counter_ids for node in nodes), f"missing graph counter in {graph_path}"
    relationships = graph.get("relationships", [])
    relation_keys = [(rel.get("from"), rel.get("to"), rel.get("label")) for rel in relationships]
    assert len(relation_keys) == len(set(relation_keys)), f"duplicate graph relationship in {graph_path}"
    assert all(rel.get("from") in node_id_set and rel.get("to") in node_id_set for rel in relationships), f"dangling graph relationship in {graph_path}"
    outgoing = {node_id: [] for node_id in node_ids}
    indegree = {node_id: 0 for node_id in node_ids}
    for rel in relationships:
        outgoing[rel["from"]].append(rel["to"])
        indegree[rel["to"]] += 1
    roots = [node_id for node_id, degree in indegree.items() if degree == 0]
    seen = set()
    stack = roots[:]
    while stack:
        node_id = stack.pop()
        if node_id in seen:
            continue
        seen.add(node_id)
        stack.extend(outgoing[node_id])
    assert seen == node_id_set, f"cycle or unreachable graph node in {graph_path}: {sorted(node_id_set - seen)}"

# Every teaching concept has one declared primary Library; secondary occurrences are explicit applications/variants.
for ownership in PLAN.get("concept_ownership", []):
    entry_id = ownership["entry_id"]
    assert entry_id in entries, f"ownership references missing Entry: {entry_id}"
    graph_path = DOC / "libraries" / ownership["primary_library"] / "graph.json"
    assert graph_path.exists(), f"ownership references missing Library: {ownership['primary_library']}"
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    assert any(node.get("props", {}).get("entryId") == entry_id for node in graph.get("nodes", [])), f"primary Library does not contain {entry_id}"
    for secondary in ownership.get("secondary_entries", []):
        secondary_id = secondary["entry_id"]
        assert secondary_id in entries, f"secondary ownership references missing Entry: {secondary_id}"
        secondary_graph = DOC / "libraries" / secondary["library"] / "graph.json"
        assert secondary_graph.exists(), f"secondary ownership references missing Library: {secondary['library']}"
        data = json.loads(secondary_graph.read_text(encoding="utf-8"))
        assert any(node.get("props", {}).get("entryId") == secondary_id for node in data.get("nodes", [])), f"secondary Library does not contain {secondary_id}"

# Explicitly planned Library sibling orders encode the concept-ownership presentation.
for order_spec in PLAN.get("ordered_graph_children", []):
    found = 0
    for graph_path in sorted((DOC / "libraries").glob("*/graph.json")):
        graph = json.loads(graph_path.read_text(encoding="utf-8"))
        nodes = graph.get("nodes", [])
        by_id = {node["id"]: node for node in nodes}
        for parent in [node for node in nodes if node.get("props", {}).get("entryId") == order_spec["parent_entry_id"]]:
            found += 1
            actual = [
                by_id[rel["to"]].get("props", {}).get("entryId")
                for rel in graph.get("relationships", [])
                if rel.get("from") == parent["id"] and rel.get("label") == "branch"
            ]
            expected = order_spec["entry_ids"]
            assert actual[:len(expected)] == expected, f"wrong sibling order under {order_spec['parent_entry_id']}: {actual}"
    assert found > 0, f"ordered parent not found: {order_spec['parent_entry_id']}"

print(json.dumps({
    "entries": len(entries),
    "macros": len(macros),
    "requested_entries": len(PLAN["requested_entries"]),
    "new_requested_entries": sum(not spec.get("existing") for spec in PLAN["requested_entries"]),
    "inductive_types": len(PLAN["inductive_types"]),
    "constructors": sum(len(x["constructors"]) for x in PLAN["inductive_types"]),
    "recursors": len(PLAN["inductive_types"]),
    "planned_inductive_subentries": sum(len(x["constructors"]) + 1 for x in PLAN["inductive_types"])
}, ensure_ascii=False))
