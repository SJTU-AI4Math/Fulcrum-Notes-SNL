#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / ".SNL_Doc"
I18N_PATH = ROOT / "scripts/fulcrum-i18n-en-zh.json"
PLAN_PATH = ROOT / "scripts/fulcrum-inductive-subentries.json"


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def identity_hash(kind: str, *segments: str) -> str:
    raw = "snl-doc/v1\0" + kind + "\0" + "\0".join(segments)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:20]


def localized(values: dict[str, str], default_language: str = "en"):
    assert set(values) == {"en", "zh-CN"}
    return {"type": "i18n", "default_language": default_language, "values": values}


def js_locale_sorted(values: set[str]) -> list[str]:
    result = subprocess.run(
        ["node", "-e", "let s='';process.stdin.on('data',x=>s+=x).on('end',()=>process.stdout.write(JSON.stringify(JSON.parse(s).sort((a,b)=>a.localeCompare(b)))))"],
        input=json.dumps(list(values)), text=True, capture_output=True, check=True
    )
    return json.loads(result.stdout)


def load_records(directory: str, identity_key: str):
    records = {}
    paths = {}
    envelopes = {}
    for path in sorted((DOC / directory).glob("*.json")):
        envelope = read_json(path)
        record_key = "entry" if directory == "entries" else "macro"
        record = envelope[record_key]
        identity = record[identity_key]
        assert identity not in records
        records[identity] = record
        paths[identity] = path
        envelopes[identity] = envelope
    return records, paths, envelopes


def template_with_body(template: dict, body: str):
    result = json.loads(json.dumps(template, ensure_ascii=False))
    result["body"] = body
    return result


def counter_nodes(counters: list[dict]):
    for counter in counters:
        yield counter
        yield from counter_nodes(counter.get("children", []))


def ensure_counter(counter_path: Path, level: str) -> str:
    data = read_json(counter_path)
    counters = data.get("counters", [])
    existing = next((c for c in counter_nodes(counters) if str(c.get("name", "")).casefold() == level.casefold()), None)
    if existing is not None:
        return existing["id"]
    assert level == "subentry", f"missing required {level} counter in {counter_path}"
    parent = next((c for c in counter_nodes(counters) if str(c.get("name", "")).casefold() == "entry"), None)
    assert parent is not None, f"cannot create subentry counter without Entry counter in {counter_path}"
    counter_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"snl-doc:{counter_path.parent.name}:subentry"))
    parent.setdefault("children", []).append({
        "id": counter_id,
        "name": "Subentry",
        "numbering": ".1",
        "children": []
    })
    write_json(counter_path, data)
    return counter_id


def node_id_for(entry_id: str) -> str:
    return "n_sub_" + hashlib.sha256(("snl-subentry\0" + entry_id).encode("utf-8")).hexdigest()[:12]


i18n = read_json(I18N_PATH)
plan = read_json(PLAN_PATH)
entries, entry_paths, entry_envelopes = load_records("entries", "id")
macros, macro_paths, macro_envelopes = load_records("macros", "name")
# Localize every existing Entry title and Markdown body covered by the exact mapping.
for entry_id, projection in i18n["entries"].items():
    assert entry_id in entries, f"I18n map references unknown Entry {entry_id}"
    entry = entries[entry_id]
    title = projection.get("title")
    if title is not None:
        expected = localized(title)
        if entry.get("title") != expected:
            current_title = entry.get("title")
            if isinstance(current_title, dict) and current_title.get("type") == "i18n":
                assert current_title.get("default_language") == "en" and set(current_title.get("values", {})) == {"en", "zh-CN"}, f"stale localized title {entry_id}"
                accepted_title_en = set(projection.get("accepted_title_en", [])) | {title["en"]}
                assert current_title["values"]["en"] in accepted_title_en, f"stale English title mapping for {entry_id}"
            else:
                accepted_title_en = set(projection.get("accepted_title_en", [])) | {title["en"]}
                assert current_title in accepted_title_en, f"stale English title mapping for {entry_id}"
            entry["title"] = expected
    markdown = projection.get("markdown")
    if markdown is not None:
        current = (entry.get("content") or {}).get("markdown")
        expected = localized(markdown)
        if current != expected:
            assert current == markdown["en"], f"stale English Markdown mapping for {entry_id}"
            entry["content"]["markdown"] = expected

# Localize lexical text-mode Macro styles without changing Macro identities or structural projections.
for key, projection in i18n["styles"].items():
    macro_name, style_name = key.split("::", 1)
    assert macro_name in macros, f"I18n map references unknown Macro {macro_name}"
    styles = [style for style in macros[macro_name]["styles"] if style["style_name"] == style_name]
    assert len(styles) == 1, f"style identity is not unique: {key}"
    style = styles[0]
    template = style["template"]
    expected = {
        "type": "i18n",
        "default_language": "en",
        "values": {
            "en": template_with_body(template, projection["en"]),
            "zh-CN": template_with_body(template, projection["zh-CN"])
        }
    }
    if template.get("type") == "i18n":
        assert template.get("default_language") == "en" and set(template.get("values", {})) == {"en", "zh-CN"}, f"stale localized Macro template: {key}"
        assert template["values"]["en"].get("body") == projection["en"], f"stale English Macro body: {key}"
        template["values"]["zh-CN"] = template_with_body(template["values"]["zh-CN"], projection["zh-CN"])
        continue
    assert template.get("mode") == "text", f"cannot localize structural Macro template: {key}"
    assert template.get("body") in {projection["en"], projection["zh-CN"]}, f"stale Macro body mapping for {key}"
    style["template"] = expected

# Add requested Entries and all constructor/recursor definition subentries.
new_specs = []
for spec in plan["requested_entries"]:
    new_specs.append(spec)
for inductive in plan["inductive_types"]:
    for child in [*inductive["constructors"], inductive["recursor"]]:
        spec = {
            "id": child["id"],
            "package": inductive["package"],
            "kind": "definition",
            "title": child["title"],
            "parent_entry_id": inductive["parent_entry_id"],
            "graph_level": "subentry",
            "reuse": bool(child.get("reuse"))
        }
        new_specs.append(spec)

for spec in new_specs:
    entry_id = spec["id"]
    content_spec = spec.get("content", {})
    expected_content = {}
    if "snl" in content_spec:
        expected_content["snl"] = content_spec["snl"]
    if "markdown" in content_spec:
        expected_content["markdown"] = localized(content_spec["markdown"])
    if spec.get("reuse"):
        assert entry_id in entries, f"reused subentry is missing: {entry_id}"
        entry = entries[entry_id]
        assert entry["package"] == spec["package"]
        assert entry.get("content") in ({}, None), f"reused subentry already has content: {entry_id}"
        entry["kind"] = "definition"
        entry["title"] = localized(spec["title"])
        entry["content"] = {}
        continue
    if entry_id in entries:
        entry = entries[entry_id]
        assert entry["package"] == spec["package"] and entry["kind"] == spec["kind"]
        entry["title"] = localized(spec["title"])
        entry["content"] = expected_content
        continue
    package_id = spec["package"]
    entry = {
        "id": entry_id,
        "package": package_id,
        "kind": spec["kind"],
        "title": localized(spec["title"]),
        "content": expected_content,
        "contribution_info": None,
        "pointer": None
    }
    envelope = {"format": "snl-entry", "version": 1, "package": package_id, "entry": entry}
    path = DOC / "entries" / f"{package_id}-{identity_hash('entry', package_id, entry_id)}.json"
    entries[entry_id] = entry
    entry_paths[entry_id] = path
    entry_envelopes[entry_id] = envelope

# Apply exact, explicitly planned semantic updates to existing Entries.
for update in plan.get("entry_updates", []):
    entry_id = update["id"]
    assert entry_id in entries, f"Entry update references unknown Entry {entry_id}"
    entry = entries[entry_id]
    current_snl = entry.get("content", {}).get("snl")
    assert current_snl in update["accepted_content_snl"], f"stale Entry update for {entry_id}"
    entry["content"]["snl"] = update["content_snl"]

# Apply exact metadata corrections generalized from the user's axiom→definition edits.
for update in plan.get("metadata_updates", []):
    entry_id = update["id"]
    assert entry_id in entries, f"Metadata update references unknown Entry {entry_id}"
    entry = entries[entry_id]
    assert entry.get("kind") in update["accepted_kind"], f"stale Entry kind for {entry_id}"
    entry["kind"] = update["kind"]

# Keep Macro provenance aligned with the Entries that now define each notation.
for update in plan.get("macro_source_updates", []):
    name = update["name"]
    assert name in macros, f"Macro source update references unknown Macro {name}"
    source = macros[name].setdefault("source", {"entries": [], "urls": []})
    assert source.get("entries", []) in update["accepted_entries"], f"stale Macro source for {name}"
    source["entries"] = update["entries"]

# Persist Entry and Macro envelopes.
for entry_id, envelope in entry_envelopes.items():
    write_json(entry_paths[entry_id], envelope)
for macro_name, envelope in macro_envelopes.items():
    write_json(macro_paths[macro_name], envelope)

# Keep package manifests exact, sorted, and authoritative.
by_package: dict[str, list[str]] = {}
for entry_id, entry in entries.items():
    by_package.setdefault(entry["package"], []).append(entry_id)
for path in sorted((DOC / "packages").glob("*.json")):
    manifest = read_json(path)
    package_id = manifest["id"]
    expected_ids = set(by_package.get(package_id, []))
    current_ids = manifest.get("entry_ids", [])
    assert set(current_ids) <= expected_ids, f"Package manifest references an unknown Entry: {package_id}"
    sorted_ids = js_locale_sorted(expected_ids)
    if current_ids != sorted_ids:
        manifest["entry_ids"] = sorted_ids
        write_json(path, manifest)

# Attach requested Entries and inductive subentries to every Library occurrence of their parent.
managed_new_entry_ids = {spec["id"] for spec in plan["requested_entries"] if not spec.get("existing")}
generated_child_ids = {
    child["id"]
    for inductive in plan["inductive_types"]
    for child in [*inductive["constructors"], inductive["recursor"]]
}
immediate_requested = [spec for spec in plan["requested_entries"] if spec.get("after_entry_id") not in generated_child_ids]
deferred_requested = [spec for spec in plan["requested_entries"] if spec.get("after_entry_id") in generated_child_ids]
relations = [
    (spec["parent_entry_id"], spec["id"], spec["graph_level"], spec.get("parent_node_ids"), spec.get("after_entry_id"))
    for spec in immediate_requested
]
relations.extend(
    (spec["parent_entry_id"], spec["entry_id"], spec["graph_level"], spec.get("parent_node_ids"), spec.get("after_entry_id"))
    for spec in plan.get("graph_references", [])
)
for inductive in plan["inductive_types"]:
    children = [*inductive["constructors"], inductive["recursor"]]
    relations.extend(
        (
            inductive["parent_entry_id"], child["id"], "subentry", None,
            children[index - 1]["id"] if inductive.get("ordered_children") and index else None
        )
        for index, child in enumerate(children)
    )
    if not inductive.get("existing"):
        managed_new_entry_ids.update(child["id"] for child in children if not child.get("reuse"))
relations.extend(
    (spec["parent_entry_id"], spec["id"], spec["graph_level"], spec.get("parent_node_ids"), spec.get("after_entry_id"))
    for spec in deferred_requested
)

for graph_path in sorted((DOC / "libraries").glob("*/graph.json")):
    graph = read_json(graph_path)
    nodes = graph.setdefault("nodes", [])
    relationships = graph.setdefault("relationships", [])
    changed = False
    for parent_entry_id, child_entry_id, level, allowed_parent_node_ids, after_entry_id in relations:
        all_parent_nodes = [node for node in nodes if node.get("props", {}).get("entryId") == parent_entry_id]
        if not all_parent_nodes:
            continue
        child_nodes = [node for node in nodes if node.get("props", {}).get("entryId") == child_entry_id]
        if allowed_parent_node_ids is not None and child_nodes:
            allowed = set(allowed_parent_node_ids)
            child_node_ids = {node["id"] for node in child_nodes}
            filtered = [rel for rel in relationships if not (
                rel.get("from") in {node["id"] for node in all_parent_nodes if node["id"] not in allowed}
                and rel.get("to") in child_node_ids
                and rel.get("label") == "branch"
            )]
            if len(filtered) != len(relationships):
                relationships[:] = filtered
                changed = True
        parent_nodes = all_parent_nodes if allowed_parent_node_ids is None else [node for node in all_parent_nodes if node["id"] in set(allowed_parent_node_ids)]
        assert parent_nodes, f"selected parent node missing for {parent_entry_id} -> {child_entry_id} in {graph_path}"
        if not child_nodes:
            counter_id = ensure_counter(graph_path.parent / "counters.json", level)
            child_node = {
                "id": node_id_for(child_entry_id),
                "label": "Entry",
                "props": {"entryId": child_entry_id, "counterId": counter_id}
            }
            assert all(node["id"] != child_node["id"] for node in nodes)
            nodes.append(child_node)
            child_nodes = [child_node]
            changed = True
        expected_counter_id = ensure_counter(graph_path.parent / "counters.json", level)
        for child_node in child_nodes:
            props = child_node.setdefault("props", {})
            if props.get("counterId") != expected_counter_id:
                props["counterId"] = expected_counter_id
                changed = True
        child_node_id = child_nodes[0]["id"]
        for parent_node in parent_nodes:
            relation = {"from": parent_node["id"], "to": child_node_id, "label": "branch"}
            if after_entry_id is not None:
                before = relationships[:]
                if relation in relationships:
                    relationships.remove(relation)
                after_node_ids = {node["id"] for node in nodes if node.get("props", {}).get("entryId") == after_entry_id}
                after_indices = [i for i, rel in enumerate(relationships) if rel.get("from") == parent_node["id"] and rel.get("to") in after_node_ids and rel.get("label") == "branch"]
                assert len(after_indices) == 1, f"placement anchor missing or ambiguous: {after_entry_id} under {parent_entry_id}"
                relationships.insert(after_indices[0] + 1, relation)
                if relationships != before:
                    changed = True
            elif relation not in relationships:
                relationships.append(relation)
                changed = True
    # Normalize only explicitly ordered parent sibling lists; preserve unrelated relationship order.
    by_node_id = {node["id"]: node for node in nodes}
    for order_spec in plan.get("ordered_graph_children", []):
        parent_nodes = [node for node in nodes if node.get("props", {}).get("entryId") == order_spec["parent_entry_id"]]
        for parent_node in parent_nodes:
            branch_indices = [i for i, rel in enumerate(relationships) if rel.get("from") == parent_node["id"] and rel.get("label") == "branch"]
            if not branch_indices:
                continue
            branch_rels = [relationships[i] for i in branch_indices]
            by_entry = {}
            for rel in branch_rels:
                child_entry_id = by_node_id[rel["to"]].get("props", {}).get("entryId")
                by_entry.setdefault(child_entry_id, []).append(rel)
            expected_order = order_spec["entry_ids"]
            assert all(len(by_entry.get(entry_id, [])) == 1 for entry_id in expected_order), f"ordered child missing or duplicated under {order_spec['parent_entry_id']}"
            ordered = [by_entry[entry_id][0] for entry_id in expected_order]
            ordered_ids = set(expected_order)
            trailing = [rel for rel in branch_rels if by_node_id[rel["to"]].get("props", {}).get("entryId") not in ordered_ids]
            replacement = [*ordered, *trailing]
            before = relationships[:]
            first = branch_indices[0]
            relationships[:] = [rel for i, rel in enumerate(relationships) if i not in set(branch_indices)]
            relationships[first:first] = replacement
            if relationships != before:
                changed = True

    base_nodes = [node for node in nodes if node.get("props", {}).get("entryId") not in managed_new_entry_ids]
    managed_nodes = sorted(
        (node for node in nodes if node.get("props", {}).get("entryId") in managed_new_entry_ids),
        key=lambda node: node["props"]["entryId"]
    )
    normalized_nodes = [*base_nodes, *managed_nodes]
    if nodes != normalized_nodes:
        nodes[:] = normalized_nodes
        changed = True
    if changed:
        write_json(graph_path, graph)

print(json.dumps({
    "entries": len(entries),
    "macros": len(macros),
    "localized_entries": len(i18n["entries"]),
    "localized_macro_styles": len(i18n["styles"]),
    "requested_entries": len(plan["requested_entries"]),
    "inductive_types": len(plan["inductive_types"])
}, ensure_ascii=False))
