#!/usr/bin/env python3
from __future__ import annotations

if not __debug__:
    raise RuntimeError("Fulcrum authority tooling must run without Python optimization; -O disables required assertions")

import copy
import hashlib
import json
import os
import re
import subprocess
import sys
import uuid
from pathlib import Path

from fulcrum_authority_validation import validate_authorities

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / ".SNL_Doc"
I18N_PATH = ROOT / "scripts/fulcrum-i18n-en-zh.json"
PLAN_PATH = ROOT / "scripts/fulcrum-inductive-subentries.json"
ENTRY_PACKAGE_PLAN_PATH = ROOT / "scripts/fulcrum-entry-packages.json"
EXPECTED_SOURCE_HEAD = "d3a3785e1d1ec1114e48eb2180f9a8ddd7a548f0"
PREFLIGHT_ONLY = os.environ.get("FULCRUM_APPLY_PREFLIGHT_ONLY") == "1"
_VIRTUAL_JSON: dict[Path, object] = {}
_VIRTUAL_DELETED: set[Path] = set()


def _strict_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def _reject_json_constant(value: str):
    raise ValueError(f"non-finite JSON constant: {value}")


def strict_json_loads(text: str):
    return json.loads(text, object_pairs_hook=_strict_object, parse_constant=_reject_json_constant)


def read_json(path: Path):
    path = path.resolve()
    assert path not in _VIRTUAL_DELETED, f"read after staged removal: {path}"
    if path in _VIRTUAL_JSON:
        return copy.deepcopy(_VIRTUAL_JSON[path])
    return strict_json_loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value) -> None:
    path = path.resolve()
    if PREFLIGHT_ONLY:
        _VIRTUAL_DELETED.discard(path)
        _VIRTUAL_JSON[path] = copy.deepcopy(value)
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def path_exists(path: Path) -> bool:
    path = path.resolve()
    if path in _VIRTUAL_DELETED:
        return False
    return path in _VIRTUAL_JSON or path.exists()


def rename_json_path(old_path: Path, new_path: Path) -> None:
    old_path, new_path = old_path.resolve(), new_path.resolve()
    if PREFLIGHT_ONLY:
        assert path_exists(old_path) and not path_exists(new_path)
        _VIRTUAL_JSON[new_path] = read_json(old_path)
        _VIRTUAL_JSON.pop(old_path, None)
        _VIRTUAL_DELETED.add(old_path)
        return
    old_path.rename(new_path)


def unlink_path(path: Path, *, missing_ok: bool = False) -> None:
    path = path.resolve()
    if PREFLIGHT_ONLY:
        if not missing_ok:
            assert path_exists(path), f"missing staged removal: {path}"
        _VIRTUAL_JSON.pop(path, None)
        _VIRTUAL_DELETED.add(path)
        return
    path.unlink(missing_ok=missing_ok)


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


def validate_macro_envelope(envelope: dict, path: Path, *, require_schema_version: bool = False) -> None:
    legacy_keys = {"format", "version", "package", "macro"}
    current_keys = legacy_keys | {"schema_version"}
    allowed_keys = (current_keys,) if require_schema_version else (legacy_keys, current_keys)
    assert any(set(envelope) == keys for keys in allowed_keys), f"invalid Macro envelope fields: {path}"
    assert envelope["format"] == "snl-macro", f"invalid Macro envelope format: {path}"
    assert type(envelope["version"]) is int and envelope["version"] == 1, f"invalid Macro envelope version: {path}"
    if "schema_version" in envelope:
        assert type(envelope["schema_version"]) is int and envelope["schema_version"] == 1, f"invalid Macro envelope schema version: {path}"
    assert isinstance(envelope["package"], str) and envelope["package"], f"invalid Macro envelope package: {path}"
    assert isinstance(envelope["macro"], dict), f"invalid Macro envelope payload: {path}"


def validate_entry_envelope(envelope: dict, path: Path) -> None:
    legacy_fields = {"format", "version", "package", "entry"}
    current_fields = legacy_fields | {"schema_version"}
    assert isinstance(envelope, dict) and set(envelope) in (legacy_fields, current_fields), f"invalid Entry envelope fields: {path}"
    assert envelope["format"] == "snl-entry", f"invalid Entry envelope format: {path}"
    assert type(envelope["version"]) is int and envelope["version"] == 1, f"invalid Entry envelope version: {path}"
    if "schema_version" in envelope:
        assert type(envelope["schema_version"]) is int and envelope["schema_version"] == 1, f"invalid Entry envelope schema version: {path}"
    assert isinstance(envelope["package"], str) and envelope["package"], f"invalid Entry envelope package: {path}"
    assert isinstance(envelope["entry"], dict), f"invalid Entry envelope payload: {path}"
    assert envelope["entry"].get("package") == envelope["package"], f"Entry envelope/payload package mismatch: {path}"


def validate_package_manifest(manifest: dict, path: Path, expected_id: str | None = None) -> None:
    fields = {"format", "version", "schema_version", "id", "name", "description", "entry_ids"}
    assert isinstance(manifest, dict) and set(manifest) == fields, f"invalid Package manifest fields: {path}"
    assert manifest["format"] == "snl-package", f"invalid Package manifest format: {path}"
    assert type(manifest["version"]) is int and manifest["version"] == 1, f"invalid Package manifest version: {path}"
    assert type(manifest["schema_version"]) is int and manifest["schema_version"] == 2, f"invalid Package manifest schema version: {path}"
    assert isinstance(manifest["id"], str) and manifest["id"], f"invalid Package manifest ID: {path}"
    if expected_id is not None:
        assert manifest["id"] == expected_id, f"Package manifest ID mismatch: {path}"
    assert isinstance(manifest["name"], str) and manifest["name"], f"invalid Package manifest name: {path}"
    assert isinstance(manifest["description"], str), f"invalid Package manifest description: {path}"
    assert isinstance(manifest["entry_ids"], list) and all(isinstance(item, str) and item for item in manifest["entry_ids"]), f"invalid Package manifest Entry IDs: {path}"
    assert len(manifest["entry_ids"]) == len(set(manifest["entry_ids"])), f"duplicate Package manifest Entry IDs: {path}"


def load_records(directory: str, identity_key: str):
    records = {}
    paths = {}
    envelopes = {}
    for path in sorted((DOC / directory).glob("*.json")):
        envelope = read_json(path)
        record_key = "entry" if directory == "entries" else "macro"
        if record_key == "macro":
            validate_macro_envelope(envelope, path)
        else:
            validate_entry_envelope(envelope, path)
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


def template_envelope(template: dict):
    return json.loads(json.dumps({key: value for key, value in template.items() if key != "body"}, ensure_ascii=False))


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


if not PREFLIGHT_ONLY:
    preflight_env = dict(os.environ)
    preflight_env["FULCRUM_APPLY_PREFLIGHT_ONLY"] = "1"
    preflight = subprocess.run(
        [sys.executable, str(Path(__file__).resolve())],
        cwd=ROOT,
        env=preflight_env,
        text=True,
        capture_output=True,
    )
    if preflight.returncode != 0:
        raise RuntimeError(f"preflight failed before filesystem mutation:\n{preflight.stderr or preflight.stdout}")


i18n = read_json(I18N_PATH)
plan = read_json(PLAN_PATH)
entry_package_plan = read_json(ENTRY_PACKAGE_PLAN_PATH)


validate_authorities(i18n, plan, entry_package_plan, EXPECTED_SOURCE_HEAD)
entries, entry_paths, entry_envelopes = load_records("entries", "id")
macros, macro_paths, macro_envelopes = load_records("macros", "name")

# Preflight complete Package manifests before the first filesystem mutation.
# Each manifest must be one of two fully pinned states: the exact predecessor
# or the exact canonical partition. Unknown metadata or membership drift is
# rejected rather than silently repaired.
manifest_specs = entry_package_plan["manifests"]
existing_package_manifests: dict[str, tuple[Path, dict]] = {}
for path in sorted((DOC / "packages").glob("*.json")):
    manifest = read_json(path)
    validate_package_manifest(manifest, path)
    package_id = manifest["id"]
    assert package_id in manifest_specs, f"unplanned Entry Package: {package_id}"
    assert package_id not in existing_package_manifests
    assert path == DOC / "packages" / f"{package_id}-{identity_hash('package', package_id)}.json"
    accepted = [manifest_specs[package_id]["canonical"]]
    predecessor = manifest_specs[package_id].get("accepted_predecessor")
    if predecessor is not None:
        accepted.append(predecessor)
    assert manifest in accepted, f"Entry Package manifest snapshot drift: {package_id}"
    existing_package_manifests[package_id] = (path, manifest)
for package_id, spec in manifest_specs.items():
    if package_id not in existing_package_manifests:
        assert spec.get("accepted_predecessor") is None, f"missing Entry Package manifest: {package_id}"

# Build only the pinned canonical Package records in memory; publication occurs
# after every migration precondition has passed.
package_manifests: dict[str, tuple[Path, dict]] = {}
for package_id, spec in manifest_specs.items():
    canonical = json.loads(json.dumps(spec["canonical"], ensure_ascii=False))
    validate_package_manifest(canonical, ENTRY_PACKAGE_PLAN_PATH, package_id)
    path = DOC / "packages" / f"{package_id}-{identity_hash('package', package_id)}.json"
    package_manifests[package_id] = (path, canonical)

# Create or normalize full structural Macro snapshots under exact leases.
# This is distinct from requested_macros, which is intentionally limited to
# zero-arity localized lexical helpers.
for spec in plan.get("requested_structural_macros", []):
    name = spec["name"]
    package_id = spec["package"]
    canonical = json.loads(json.dumps(spec["canonical"], ensure_ascii=False))
    assert canonical["name"] == name
    canonical_path = DOC / "macros" / f"{package_id}-{identity_hash('macro', package_id, name)}.json"
    if name in macros:
        assert macro_paths[name] == canonical_path, f"noncanonical structural Macro path: {name}"
        assert macro_envelopes[name]["package"] == package_id, f"structural Macro Package drift: {name}"
        validate_macro_envelope(macro_envelopes[name], macro_paths[name], require_schema_version=True)
        assert macros[name] in [canonical, *spec.get("accepted_predecessors", [])], f"structural Macro snapshot drift: {name}"
        macros[name] = canonical
        macro_envelopes[name]["macro"] = canonical
    else:
        assert not path_exists(canonical_path), f"structural Macro path collision: {canonical_path.name}"
        envelope = {"format": "snl-macro", "version": 1, "schema_version": 1, "package": package_id, "macro": canonical}
        macros[name] = canonical
        macro_paths[name] = canonical_path
        macro_envelopes[name] = envelope

# Preflight and normalize exact user-authored Macro snapshots before any
# filesystem mutation. This preserves intentional language-invariant styles
# while making the few structural repairs explicit and replayable.
for spec in plan.get("macro_snapshot_updates", []):
    name = spec["name"]
    assert name in macros, f"Macro snapshot update references unknown Macro: {name}"
    accepted = [spec["canonical"], *spec.get("accepted_predecessors", [])]
    current_hash = hashlib.sha256(json.dumps(macros[name], ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    assert macros[name] in accepted or current_hash in spec.get("accepted_predecessor_hashes", []), f"Macro snapshot drift: {name}"
    canonical = json.loads(json.dumps(spec["canonical"], ensure_ascii=False))
    macros[name] = canonical
    macro_envelopes[name]["macro"] = canonical

# Rewrite only explicitly leased SNL bodies. Raw text templates are migrated to
# long, package-scoped one-off I18N Macros rather than split into finer SNL.
for spec in plan.get("entry_snl_updates", []):
    entry_id = spec["id"]
    if entry_id not in entries:
        predecessor_ids = [rename["old_id"] for rename in plan.get("entry_renames", []) if rename["new_id"] == entry_id and rename["old_id"] in entries]
        assert len(predecessor_ids) == 1, f"SNL update references unknown Entry: {entry_id}"
        entry_id = predecessor_ids[0]
    assert entry_id in entries, f"SNL update references unknown Entry: {entry_id}"
    current = (entries[entry_id].get("content") or {}).get("snl")
    assert current in [spec["canonical"], *spec.get("accepted_predecessors", [])], f"Entry SNL snapshot drift: {entry_id}"
    if spec["canonical"] is None:
        entries[entry_id]["content"].pop("snl", None)
    else:
        entries[entry_id]["content"]["snl"] = spec["canonical"]

# Remove obsolete draft Markdown only from explicitly leased structured Entries.
for removal in plan.get("entry_markdown_removals", []):
    entry_id = removal["id"]
    assert entry_id in entries, f"Markdown removal references unknown Entry: {entry_id}"
    content = entries[entry_id].get("content") or {}
    retired_snl_ids = {spec["id"] for spec in plan.get("entry_snl_updates", []) if spec["canonical"] is None}
    assert (isinstance(content.get("snl"), str) and content["snl"]) or entry_id in retired_snl_ids, f"Markdown removal requires canonical or explicitly retired SNL: {entry_id}"
    assert content.get("markdown") in removal["accepted_markdown"], f"unrecognized Markdown predecessor: {entry_id}"
    content.pop("markdown", None)

# Macro ownership and Entry membership are independent. The Extension currently
# requires every active Macro Package to have a shared package-registry manifest;
# an empty entry_ids list records that this Macro Package owns no Entries.
config_path = DOC / "config.json"
config = read_json(config_path)
active_macro_packages = config.get("active_macro_packages", [])
assert isinstance(active_macro_packages, list) and len(active_macro_packages) == len(set(active_macro_packages))
retired_macro_packages = set(plan.get("retired_macro_packages", []))
active_macro_packages = [package_id for package_id in active_macro_packages if package_id not in retired_macro_packages]
for package_id in plan.get("managed_macro_packages", []):
    if package_id not in active_macro_packages:
        active_macro_packages.append(package_id)
config["active_macro_packages"] = active_macro_packages

# Apply explicit Entry identity migrations before graph, Package, provenance,
# and dependency reconciliation. This is deliberately not a raw text replace.
for rename in plan.get("entry_renames", []):
    old_id = rename["old_id"]
    new_id = rename["new_id"]
    package_id = rename["package"]
    if old_id in entries:
        assert new_id not in entries, f"both old and new Entry identities exist: {old_id}, {new_id}"
        record = entries.pop(old_id)
        path = entry_paths.pop(old_id)
        envelope = entry_envelopes.pop(old_id)
        assert envelope["package"] == package_id and record["package"] == package_id
        record["id"] = new_id
        entries[new_id] = record
        entry_paths[new_id] = path
        entry_envelopes[new_id] = envelope
    else:
        assert new_id in entries, f"missing Entry identity migration source: {old_id}"
    path = entry_paths[new_id]
    canonical_path = DOC / "entries" / f"{package_id}-{identity_hash('entry', package_id, new_id)}.json"
    if path != canonical_path:
        assert not path_exists(canonical_path), f"Entry identity migration path collision: {canonical_path.name}"
        rename_json_path(path, canonical_path)
        entry_paths[new_id] = canonical_path
    for macro in macros.values():
        source = macro.get("source") or {}
        source_entries = source.get("entries")
        if isinstance(source_entries, list):
            source["entries"] = [new_id if entry_id == old_id else entry_id for entry_id in source_entries]
    for graph_path in sorted((DOC / "libraries").glob("*/graph.json")):
        graph = read_json(graph_path)
        graph_changed = False
        for node in graph.get("nodes", []):
            props = node.get("props") or {}
            if props.get("entryId") == old_id:
                props["entryId"] = new_id
                graph_changed = True
        if graph_changed:
            write_json(graph_path, graph)
    relationship_path = DOC / "relationships.json"
    relationship_data = read_json(relationship_path)
    relationships_changed = False
    for relationship in relationship_data.get("relationships", []):
        row_changed = False
        if relationship.get("from") == old_id:
            relationship["from"] = new_id
            row_changed = True
        if relationship.get("to") == old_id:
            relationship["to"] = new_id
            row_changed = True
        if row_changed and (relationship.get("metadata") or {}).get("generator") == "macro-source-scan":
            relationship["id"] = f"dep.{relationship['from']}.{relationship['to']}"
        relationships_changed = relationships_changed or row_changed
    if relationships_changed:
        write_json(relationship_path, relationship_data)

# Apply explicit Macro identity migrations before localization and provenance updates.
for rename in plan.get("macro_renames", []):
    old_name = rename["old_name"]
    new_name = rename["new_name"]
    package_id = rename["package"]
    if old_name in macros:
        assert new_name not in macros, f"both old and new Macro identities exist: {old_name}, {new_name}"
        record = macros.pop(old_name)
        path = macro_paths.pop(old_name)
        envelope = macro_envelopes.pop(old_name)
        record["name"] = new_name
        macros[new_name] = record
        macro_paths[new_name] = path
        macro_envelopes[new_name] = envelope
    else:
        assert new_name in macros, f"missing Macro identity migration source: {old_name}"
    path = macro_paths[new_name]
    canonical_path = DOC / "macros" / f"{package_id}-{identity_hash('macro', package_id, new_name)}.json"
    if path != canonical_path:
        assert not path_exists(canonical_path), f"Macro identity migration path collision: {canonical_path.name}"
        rename_json_path(path, canonical_path)
        macro_paths[new_name] = canonical_path

# Merge legacy presentation Macros into canonical constructor Macros. The
# complete accepted predecessor records are pinned in the plan: style names
# alone are not enough because that would promote corrupted templates.
retired_macro_paths: list[Path] = []
for merge in plan.get("macro_merges", []):
    source_name = merge["source_name"]
    target_name = merge["target_name"]
    package_id = merge["package"]
    source_snapshot = merge["accepted_source_macro"]
    target_snapshot = merge["accepted_target_macro"]
    assert source_snapshot["name"] == source_name and target_snapshot["name"] == target_name
    canonical_macro = json.loads(json.dumps(target_snapshot, ensure_ascii=False))
    text_style = canonical_macro["styles"][0]
    assert text_style["style_name"] == merge["target_text_style_from"]
    text_style["style_name"] = merge["target_text_style_name"]
    canonical_macro["description"] = source_snapshot["description"]
    canonical_macro["kind"] = source_snapshot["kind"]
    canonical_macro["dynamic_arity"] = source_snapshot["dynamic_arity"]
    canonical_macro["styles"] = [*json.loads(json.dumps(source_snapshot["styles"], ensure_ascii=False)), text_style]
    assert [style["style_name"] for style in canonical_macro["styles"]] == merge["canonical_style_names"]

    assert target_name in macros, f"missing Macro merge target: {target_name}"
    target = macros[target_name]
    target_path = macro_paths[target_name]
    assert macro_envelopes[target_name]["package"] == package_id
    if source_name in macros:
        source = macros[source_name]
        source_path = macro_paths[source_name]
        assert macro_envelopes[source_name]["package"] == package_id
        assert source == source_snapshot, f"source Macro snapshot drift: {source_name}"
        assert target in (target_snapshot, canonical_macro), f"target Macro snapshot drift: {target_name}"
        target.clear()
        target.update(json.loads(json.dumps(canonical_macro, ensure_ascii=False)))
        retired_macro_paths.append(source_path)
        del macros[source_name], macro_paths[source_name], macro_envelopes[source_name]
    else:
        assert target == canonical_macro, f"canonical Macro merge drift: {target_name}"
    canonical_path = DOC / "macros" / f"{package_id}-{identity_hash('macro', package_id, target_name)}.json"
    assert target_path == canonical_path, f"noncanonical Macro merge target path: {target_name}"


def formula_template(body: str) -> dict:
    return {
        "mode": "formula_inline", "body": body,
        "typst": {"built_in": "", "synthesis": {"mode": "formula", "macro": ""}},
        "latex": {"built_in": "", "synthesis": {"mode": "formula", "macro": ""}},
        "markdown": "", "text": "",
    }


# Add a fixed-arity symbolic constructor style without consuming a separate
# variadic surface-notation Macro. Dynamic arity is a Macro-level contract, so
# a lexical text style cannot safely share the old `#*` Macro.
for update in plan.get("macro_style_updates", []):
    name = update["name"]
    macro = macros[name]
    assert macro_paths[name] == DOC / "macros" / f"{update['package']}-{identity_hash('macro', update['package'], name)}.json"
    current_names = [style["style_name"] for style in macro["styles"]]
    if current_names == update["accepted_style_names"]:
        assert macro["kind"] == "const" and macro["dynamic_arity"] is False and macro["description"] == "" and macro["tags"] == []
        text_style = macro["styles"][0]
        text_style["style_name"] = update["text_style_name"]
        macro["styles"] = [
            {"style_name": update["symbolic_style_name"], "tags": [], "template": formula_template(update["symbolic_body"])},
            text_style,
        ]
        macro["kind"] = update["kind"]
        macro["dynamic_arity"] = update["dynamic_arity"]
        macro["description"] = update["description"]
    else:
        assert current_names == update["canonical_style_names"], f"canonical Macro style update drift: {name}"
    assert macro["kind"] == update["kind"] and macro["dynamic_arity"] is update["dynamic_arity"] and macro["description"] == update["description"]
    assert macro["styles"][0] == {"style_name": update["symbolic_style_name"], "tags": [], "template": formula_template(update["symbolic_body"])}


def rewrite_snl_identifier(source: str, old_name: str, new_name: str) -> str:
    """Rewrite one Macro token, leaving opaque `%...%`/`$...$` bodies untouched."""
    pattern = re.compile(rf"(?<![A-Za-z0-9_.-]){re.escape(old_name)}(?![A-Za-z0-9_.-])")
    out = []
    cursor = 0
    plain_start = 0
    while cursor < len(source):
        delimiter = "$$" if source.startswith("$$", cursor) else source[cursor] if source[cursor] in {"%", "$"} else None
        if delimiter is None:
            cursor += 1
            continue
        out.append(pattern.sub(new_name, source[plain_start:cursor]))
        end = source.find(delimiter, cursor + len(delimiter))
        if end < 0:
            out.append(source[cursor:])
            return "".join(out)
        end += len(delimiter)
        out.append(source[cursor:end])
        cursor = end
        plain_start = end
    out.append(pattern.sub(new_name, source[plain_start:]))
    return "".join(out)


for rewrite in plan.get("snl_macro_rewrites", []):
    for entry in entries.values():
        content = entry.get("content") or {}
        snl = content.get("snl")
        if isinstance(snl, str):
            content["snl"] = rewrite_snl_identifier(snl, rewrite["old_name"], rewrite["new_name"])

# Retire explicitly leased orphan Macros only when their complete snapshot matches.
for retirement in plan.get("retired_macros", []):
    name = retirement["name"]
    package_id = retirement["package"]
    canonical_path = DOC / "macros" / f"{package_id}-{identity_hash('macro', package_id, name)}.json"
    if name in macros:
        assert macro_paths[name] == canonical_path, f"noncanonical retired Macro path: {name}"
        assert macro_envelopes[name]["package"] == package_id, f"retired Macro Package drift: {name}"
        assert macros[name] in retirement["accepted_snapshots"], f"retired Macro snapshot drift: {name}"
        retired_macro_paths.append(canonical_path)
        del macros[name], macro_paths[name], macro_envelopes[name]
    else:
        assert not path_exists(canonical_path), f"retired Macro path remains without loaded identity: {name}"


# Create or normalize explicitly requested zero-arity localized lexical Macros.
def lexical_template(body: str) -> dict:
    return {
        "mode": "text", "body": body,
        "typst": {"built_in": "", "synthesis": {"mode": "formula", "macro": ""}},
        "latex": {"built_in": "", "synthesis": {"mode": "formula", "macro": ""}},
        "markdown": "", "text": "",
    }


for spec in plan.get("requested_macros", []):
    name = spec["name"]
    package_id = spec["package"]
    canonical_path = DOC / "macros" / f"{package_id}-{identity_hash('macro', package_id, name)}.json"
    expected_macro = {
        "description": "",
        "source": {"entries": [spec["source_entry_id"]], "urls": []},
        "kind": spec["kind"],
        "dynamic_arity": False,
        "styles": [{
            "style_name": spec["style_name"], "tags": [],
            "template": localized({
                "en": lexical_template(spec["body"]["en"]),
                "zh-CN": lexical_template(spec["body"]["zh-CN"]),
            }),
        }],
        "tags": [],
        "name": name,
    }
    if name in macros:
        assert macro_paths[name] == canonical_path, f"noncanonical requested Macro path: {name}"
        existing_macro = macros[name]
        existing_source = existing_macro.get("source")
        assert isinstance(existing_source, dict) and set(existing_source) == {"entries", "urls"}, f"requested Macro source shape drift: {name}"
        assert existing_source["urls"] == [], f"requested Macro source URL drift: {name}"
        assert existing_source["entries"] in spec.get("accepted_source_entries", [[spec["source_entry_id"]]]), f"unaccepted requested Macro provenance: {name}"
        existing_source["entries"] = [spec["source_entry_id"]]
        assert existing_macro.get("kind") in [spec["kind"], *spec.get("accepted_kinds", [])], f"unaccepted requested Macro kind: {name}"
        existing_macro["kind"] = spec["kind"]
        if "accepted_bodies" in spec:
            assert len(existing_macro.get("styles", [])) == 1 and existing_macro["styles"][0].get("style_name") == spec["style_name"], f"requested Macro style drift: {name}"
            template = existing_macro["styles"][0].get("template")
            assert isinstance(template, dict) and template.get("type") == "i18n" and template.get("default_language") == "en" and set(template.get("values", {})) == {"en", "zh-CN"}, f"requested Macro locale shape drift: {name}"
            for locale in ("en", "zh-CN"):
                assert template["values"][locale].get("body") in spec["accepted_bodies"][locale], f"unaccepted requested Macro body: {name}/{locale}"
                template["values"][locale]["body"] = spec["body"][locale]
        assert existing_macro == expected_macro, f"requested Macro drift: {name}"
    else:
        assert not path_exists(canonical_path), f"requested Macro path collision: {canonical_path.name}"
        envelope = {"format": "snl-macro", "version": 1, "schema_version": 1, "package": package_id, "macro": expected_macro}
        macros[name] = expected_macro
        macro_paths[name] = canonical_path
        macro_envelopes[name] = envelope
        write_json(canonical_path, envelope)

# Localize every existing Entry title and Markdown body covered by the exact mapping.
for entry_id, projection in i18n["entries"].items():
    assert entry_id in entries, f"I18n map references unknown Entry {entry_id}"
    entry = entries[entry_id]
    title = projection.get("title")
    if title is not None:
        expected = localized(title)
        if entry.get("title") != expected:
            current_title = entry.get("title")
            if current_title in projection.get("accepted_title_predecessors", []):
                pass
            elif isinstance(current_title, dict) and current_title.get("type") == "i18n":
                assert current_title.get("default_language") in {"en", "zh-CN"} and set(current_title.get("values", {})) == {"en", "zh-CN"}, f"stale localized title {entry_id}"
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
            accepted_markdown = projection.get("accepted_markdown", [markdown["en"]])
            assert current in accepted_markdown, f"stale English Markdown mapping for {entry_id}"
            entry["content"]["markdown"] = expected

# Localize lexical text-mode Macro styles without changing Macro identities or structural projections.
for key, projection in i18n["styles"].items():
    macro_name, style_name = key.split("::", 1)
    assert macro_name in macros, f"I18n map references unknown Macro {macro_name}"
    styles = [style for style in macros[macro_name]["styles"] if style["style_name"] == style_name]
    assert len(styles) == 1, f"style identity is not unique: {key}"
    style = styles[0]
    template = style["template"]
    canonical_envelope = projection["template_envelope"]
    if template.get("type") == "i18n":
        assert template.get("default_language") in {"en", "zh-CN"} and set(template.get("values", {})) == {"en", "zh-CN"}, f"stale localized Macro template: {key}"
        accepted_en = projection.get("accepted_en", [projection["en"]])
        assert template["values"]["en"].get("body") in accepted_en, f"stale English Macro body: {key}"
        for locale in ("en", "zh-CN"):
            assert template_envelope(template["values"][locale]) == canonical_envelope, f"stale localized Macro template envelope: {key}/{locale}"
            template["values"][locale]["body"] = projection[locale]
        template["default_language"] = "en"
        continue
    assert template.get("mode") == "text", f"cannot localize structural Macro template: {key}"
    accepted_body = set(projection.get("accepted_body", [])) | {projection["en"], projection["zh-CN"]}
    assert template.get("body") in accepted_body, f"stale Macro body mapping for {key}"
    assert template_envelope(template) == canonical_envelope, f"stale Macro template envelope: {key}"
    style["template"] = {
        "type": "i18n",
        "default_language": "en",
        "values": {
            "en": template_with_body(template, projection["en"]),
            "zh-CN": template_with_body(template, projection["zh-CN"])
        }
    }

# Add requested Entries and all constructor/recursor definition subentries.
new_specs = []
for spec in plan["requested_entries"]:
    new_specs.append(spec)
for inductive in plan["inductive_types"]:
    for child in [*inductive["constructors"], inductive["recursor"]]:
        spec = {
            "id": child["id"],
            "package": inductive["package"],
            "accepted_packages": inductive.get("accepted_packages", [inductive["package"]]),
            "kind": child.get("kind", "definition"),
            "accepted_kind": child.get("accepted_kind", [child.get("kind", "definition")]),
            "title": child["title"],
            "content": child.get("content", {}),
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
        assert entry["package"] in spec.get("accepted_packages", [spec["package"]])
        assert entry.get("content") in ({}, None), f"reused subentry already has content: {entry_id}"
        entry["kind"] = "definition"
        entry["title"] = localized(spec["title"])
        entry["content"] = {}
        continue
    if entry_id in entries:
        entry = entries[entry_id]
        accepted_content = []
        for predecessor in spec.get("accepted_content", []):
            normalized_predecessor = {}
            if "snl" in predecessor:
                normalized_predecessor["snl"] = predecessor["snl"]
            if "markdown" in predecessor:
                normalized_predecessor["markdown"] = localized(predecessor["markdown"])
            accepted_content.append(normalized_predecessor)
        assert entry["package"] in spec.get("accepted_packages", [spec["package"]])
        assert entry["kind"] in spec.get("accepted_kind", [spec["kind"]]), f"stale Entry kind: {entry_id}"
        assert entry.get("content") in [expected_content, *accepted_content], f"unaccepted requested Entry content drift: {entry_id}"
        entry["kind"] = spec["kind"]
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

# Assign every Entry to exactly one semantic Package. The complete explicit
# partition is authoritative; prefix rules were used only to author the plan.
planned_entry_packages: dict[str, str] = {}
for package_id, entry_ids in entry_package_plan["assignments"].items():
    assert len(entry_ids) == len(set(entry_ids)), f"duplicate Entry within Package plan: {package_id}"
    for entry_id in entry_ids:
        assert entry_id not in planned_entry_packages, f"Entry assigned to multiple Packages: {entry_id}"
        planned_entry_packages[entry_id] = package_id
assert set(planned_entry_packages) == set(entries), "Entry Package plan must partition the complete Entry set"
retired_entry_package_paths: list[Path] = []
for entry_id, target_package in planned_entry_packages.items():
    entry = entries[entry_id]
    envelope = entry_envelopes[entry_id]
    current_package = entry["package"]
    assert envelope["package"] == current_package
    assert current_package in ("_unpackaged", target_package), f"unexpected existing Entry Package: {entry_id}"
    canonical_path = DOC / "entries" / f"{target_package}-{identity_hash('entry', target_package, entry_id)}.json"
    if current_package != target_package:
        retired_entry_package_paths.append(entry_paths[entry_id])
        entry["package"] = target_package
        envelope["package"] = target_package
        entry_paths[entry_id] = canonical_path
    else:
        assert entry_paths[entry_id] == canonical_path, f"noncanonical Entry path: {entry_id}"

# Keep Macro provenance aligned with the Entries that now define each notation.
for update in plan.get("macro_source_updates", []):
    name = update["name"]
    assert name in macros, f"Macro source update references unknown Macro {name}"
    source = macros[name].setdefault("source", {"entries": [], "urls": []})
    assert source.get("entries", []) in update["accepted_entries"], f"stale Macro source for {name}"
    source["entries"] = update["entries"]

# Validate and prepare every Package manifest before any Entry move is
# persisted. A stale manifest must fail closed without leaving duplicate or
# half-moved canonical files behind.
by_package: dict[str, list[str]] = {}
for entry_id, entry in entries.items():
    by_package.setdefault(entry["package"], []).append(entry_id)
for package_id, (_, manifest) in sorted(package_manifests.items()):
    expected_ids = js_locale_sorted(set(by_package.get(package_id, [])))
    assert manifest["entry_ids"] == expected_ids, f"canonical Entry Package plan mismatch: {package_id}"
assert set(entry_package_plan["assignments"]) <= set(package_manifests)

# Persist Entry, Macro, and Package envelopes only after all migration
# preconditions have passed, then retire predecessor Entry paths.
for entry_id, envelope in entry_envelopes.items():
    write_json(entry_paths[entry_id], envelope)
for old_path in retired_entry_package_paths:
    if path_exists(old_path):
        unlink_path(old_path)
for macro_name, envelope in macro_envelopes.items():
    write_json(macro_paths[macro_name], envelope)
for _, (path, manifest) in sorted(package_manifests.items()):
    write_json(path, manifest)
write_json(config_path, config)

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
    detached_entry_ids = {
        entry_id
        for spec in plan.get("graph_detachments", [])
        if spec["library"] == graph_path.parent.name
        for entry_id in spec["entry_ids"]
    }
    if detached_entry_ids:
        detached_node_ids = {node["id"] for node in nodes if node.get("props", {}).get("entryId") in detached_entry_ids}
        assert not detached_node_ids, f"detached graph entries unexpectedly present in {graph_path}: {sorted(detached_node_ids)}"
    for parent_entry_id, child_entry_id, level, allowed_parent_node_ids, after_entry_id in relations:
        if child_entry_id in detached_entry_ids:
            continue
        if after_entry_id in detached_entry_ids:
            after_entry_id = None
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
    # Repair counters on explicitly adopted pre-existing graph nodes.
    for repair in plan.get("graph_counter_repairs", []):
        repair_nodes = [node for node in nodes if node.get("props", {}).get("entryId") == repair["entry_id"]]
        if not repair_nodes:
            continue
        expected_counter_id = ensure_counter(graph_path.parent / "counters.json", repair["level"])
        for repair_node in repair_nodes:
            props = repair_node.setdefault("props", {})
            if props.get("counterId") != expected_counter_id:
                props["counterId"] = expected_counter_id
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

    if changed:
        write_json(graph_path, graph)

# Reconcile the explicitly managed dependency slice from Entry SNL and Macro provenance.
def extract_snl_macro_names(snl: str) -> list[str]:
    names: set[str] = set()
    i = 0
    n = len(snl)
    is_start = lambda c: c.isascii() and (c.isalpha() or c in "_.")
    is_cont = lambda c: c.isascii() and (c.isalnum() or c in "_.-")
    while i < n:
        c = snl[i]
        if c.isspace() or c in "(),[]":
            i += 1
            continue
        if c == "%":
            i += 1
            while i < n and snl[i] != "%":
                i += 1
            i += 1
            continue
        if c == "$":
            delimiter = "$$" if i + 1 < n and snl[i + 1] == "$" else "$"
            i += len(delimiter)
            while i < n and not snl.startswith(delimiter, i):
                i += 1
            i += len(delimiter)
            continue
        if c == "@":
            i += 1
            if i < n and snl[i] in "%$":
                continue
            while i < n and is_cont(snl[i]):
                i += 1
            continue
        if is_start(c):
            j = i + 1
            while j < n and is_cont(snl[j]):
                j += 1
            names.add(snl[i:j])
            i = j
            if i < n and snl[i] == "[":
                while i < n and snl[i] != "]":
                    i += 1
                if i < n:
                    i += 1
            if i < n and snl[i] == "@":
                i += 1
                while i < n and is_cont(snl[i]):
                    i += 1
            continue
        i += 1
    return sorted(names)


def reconcile_dependency_slice() -> None:
    scope = set(plan.get("dependency_scope_entries", []))
    if not scope:
        return
    assert scope <= set(entries), f"dependency scope references unknown Entries: {sorted(scope - set(entries))}"
    path = DOC / "relationships.json"
    data = read_json(path)
    relationships = data.get("relationships", [])
    auto = lambda rel: rel.get("label") == "depends" and isinstance(rel.get("metadata"), dict) and rel["metadata"].get("generator") == "macro-source-scan"
    preserved = [rel for rel in relationships if not (auto(rel) and rel.get("from") in scope)]
    previous = {(rel["from"], rel["to"]): rel for rel in relationships if auto(rel) and rel.get("from") in scope}
    allocated = {rel["id"] for rel in preserved}
    generated: list[dict] = []
    for entry_id in sorted(scope):
        witnesses: dict[str, set[str]] = {}
        for name in extract_snl_macro_names((entries[entry_id].get("content") or {}).get("snl", "")):
            macro = macros.get(name)
            if macro is None:
                continue
            for target in (macro.get("source") or {}).get("entries", []):
                if target and target != entry_id and target in entries:
                    witnesses.setdefault(target, set()).add(name)
        for target in sorted(witnesses):
            old = previous.get((entry_id, target))
            if old is not None and old["id"] not in allocated:
                relation_id = old["id"]
            else:
                base = f"dep.{entry_id}.{target}"
                relation_id = base
                suffix = 1
                while relation_id in allocated:
                    relation_id = f"{base}.{suffix}"
                    suffix += 1
            allocated.add(relation_id)
            generated.append({
                "id": relation_id,
                "from": entry_id,
                "to": target,
                "label": "depends",
                "metadata": {
                    "generator": "macro-source-scan",
                    "macros": sorted(witnesses[target]),
                    "isAtomic": True,
                },
            })
    merged = [*preserved, *generated]
    for current in generated:
        seen = {current["from"]}
        queue = [current["from"]]
        reachable = False
        while queue and not reachable:
            source = queue.pop(0)
            for rel in merged:
                if rel is current or rel.get("label") != "depends" or rel.get("from") != source:
                    continue
                target = rel.get("to")
                if target == current["to"]:
                    reachable = True
                    break
                if target not in seen:
                    seen.add(target)
                    queue.append(target)
        current["metadata"]["isAtomic"] = not reachable
    merged.sort(key=lambda rel: rel["id"])
    write_json(path, {"version": 1, "relationships": merged})


reconcile_dependency_slice()
for retired_macro_path in retired_macro_paths:
    unlink_path(retired_macro_path, missing_ok=True)

print(json.dumps({
    "entries": len(entries),
    "macros": len(macros),
    "localized_entries": len(i18n["entries"]),
    "localized_macro_styles": len(i18n["styles"]),
    "requested_entries": len(plan["requested_entries"]),
    "inductive_types": len(plan["inductive_types"])
}, ensure_ascii=False))
