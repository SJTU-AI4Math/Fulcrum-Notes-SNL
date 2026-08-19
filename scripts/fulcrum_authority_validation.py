from __future__ import annotations


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def _known(value: object, allowed: set[str], label: str) -> dict:
    _require(isinstance(value, dict), f"{label} must be an object")
    unknown = set(value) - allowed
    _require(not unknown, f"unknown {label} fields: {sorted(unknown)}")
    return value


def _required(value: object, required: set[str], allowed: set[str], label: str) -> dict:
    record = _known(value, allowed, label)
    missing = required - set(record)
    _require(not missing, f"missing {label} fields: {sorted(missing)}")
    return record


def _string_list(value: object, label: str) -> None:
    _require(isinstance(value, list) and all(isinstance(item, str) for item in value), f"{label} must be a string list")


def _locale_projection(value: object, label: str) -> None:
    projection = _known(value, {"en", "zh-CN"}, label)
    _require(set(projection) == {"en", "zh-CN"}, f"{label} must contain exactly en and zh-CN")
    _require(all(isinstance(projection[locale], str) for locale in ("en", "zh-CN")), f"{label} projections must be strings")


def _template(template: object, label: str) -> None:
    if isinstance(template, dict) and template.get("type") == "i18n":
        template = _required(template, {"type", "default_language", "values"}, {"type", "default_language", "values"}, label)
    else:
        required = {"mode", "body", "typst", "latex", "markdown", "text"}
        template = _required(template, required, required | {"separator"}, label)
    if template.get("type") == "i18n":
        _require(template["type"] == "i18n" and template["default_language"] in {"en", "zh-CN"}, f"{label} has invalid I18N metadata")
        values = _required(template["values"], {"en", "zh-CN"}, {"en", "zh-CN"}, f"{label}.values")
        _require(set(values) == {"en", "zh-CN"}, f"{label}.values must contain exactly en and zh-CN")
        for locale, projection in values.items():
            _template(projection, f"{label}.values.{locale}")
        return
    for backend in ("typst", "latex"):
        backend_spec = _required(template[backend], {"built_in", "synthesis"}, {"built_in", "synthesis"}, f"{label}.{backend}")
        _required(backend_spec["synthesis"], {"mode", "macro"}, {"mode", "macro"}, f"{label}.{backend}.synthesis")


def _template_envelope(value: object, label: str) -> None:
    allowed = {"mode", "typst", "latex", "markdown", "text", "separator"}
    value = _required(value, {"mode"}, allowed, label)
    _require(isinstance(value["mode"], str), f"{label}.mode must be a string")
    for backend_name in ("typst", "latex"):
        if backend_name in value:
            backend = _required(value[backend_name], {"built_in", "synthesis"}, {"built_in", "synthesis"}, f"{label}.{backend_name}")
            _require(isinstance(backend["built_in"], str), f"{label}.{backend_name}.built_in must be a string")
            synthesis = _required(backend["synthesis"], {"mode", "macro"}, {"mode", "macro"}, f"{label}.{backend_name}.synthesis")
            _require(all(isinstance(synthesis[field], str) for field in ("mode", "macro")), f"{label}.{backend_name}.synthesis fields must be strings")
    for field in ("markdown", "text", "separator"):
        if field in value:
            _require(isinstance(value[field], str), f"{label}.{field} must be a string")


def _macro(macro: object, label: str) -> None:
    macro_fields = {"description", "source", "kind", "dynamic_arity", "styles", "tags", "name"}
    macro = _required(macro, macro_fields, macro_fields, label)
    source = _required(macro["source"], {"entries", "urls"}, {"entries", "urls"}, f"{label}.source")
    _string_list(source["entries"], f"{label}.source.entries")
    _string_list(source["urls"], f"{label}.source.urls")
    _require(isinstance(macro["styles"], list), f"{label}.styles must be a list")
    for index, style in enumerate(macro["styles"]):
        style = _required(style, {"style_name", "tags", "template"}, {"style_name", "tags", "template"}, f"{label}.styles[{index}]")
        _template(style["template"], f"{label}.styles[{index}].template")


_PLAN_LIST_FIELDS = {
    "requested_entries": {"accepted_content", "accepted_packages", "after_entry_id", "content", "existing", "graph_level", "id", "kind", "package", "parent_entry_id", "parent_node_ids", "title"},
    "entry_updates": {"accepted_content_snl", "content_snl", "id"},
    "inductive_types": {"accepted_packages", "constructors", "existing", "ordered_children", "package", "parent_entry_id", "recursor"},
    "graph_references": {"after_entry_id", "entry_id", "graph_level", "parent_entry_id"},
    "ordered_graph_children": {"entry_ids", "parent_entry_id"},
    "metadata_updates": {"accepted_kind", "id", "kind"},
    "concept_ownership": {"concept", "entry_id", "primary_library", "secondary_entries"},
    "macro_source_updates": {"accepted_entries", "entries", "name"},
    "macro_renames": {"new_name", "old_name", "package"},
    "graph_counter_repairs": {"entry_id", "level"},
    "requested_macros": {"accepted_bodies", "accepted_kinds", "accepted_source_entries", "body", "kind", "name", "package", "source_entry_id", "style_name"},
    "requested_structural_macros": {"accepted_predecessors", "canonical", "name", "package"},
    "entry_renames": {"new_id", "old_id", "package"},
    "macro_merges": {"accepted_source_macro", "accepted_target_macro", "canonical_style_names", "package", "source_name", "source_style_names", "target_name", "target_text_style_from", "target_text_style_name"},
    "snl_macro_rewrites": {"new_name", "old_name"},
    "macro_style_updates": {"accepted_style_names", "canonical_style_names", "description", "dynamic_arity", "kind", "name", "package", "source_entry_id", "symbolic_body", "symbolic_style_name", "text_style_from", "text_style_name"},
    "macro_snapshot_updates": {"accepted_predecessors", "accepted_predecessor_hashes", "canonical", "name"},
    "entry_snl_updates": {"accepted_predecessors", "canonical", "id"},
    "retired_macros": {"accepted_snapshots", "name", "package"},
    "entry_markdown_removals": {"accepted_markdown", "id"},
    "graph_detachments": {"entry_ids", "library"},
}
_PLAN_SCALAR_LISTS = {"dependency_scope_entries", "invariant_macro_styles", "managed_macro_packages", "retired_macro_packages"}

_PLAN_REQUIRED_FIELDS = {
    "requested_entries": {"id", "package", "kind", "parent_entry_id", "graph_level", "title"},
    "entry_updates": {"id", "accepted_content_snl", "content_snl"},
    "inductive_types": {"parent_entry_id", "package", "constructors", "recursor"},
    "graph_references": {"entry_id", "parent_entry_id", "graph_level", "after_entry_id"},
    "ordered_graph_children": {"parent_entry_id", "entry_ids"},
    "metadata_updates": {"id", "accepted_kind", "kind"},
    "concept_ownership": {"concept", "entry_id", "primary_library"},
    "macro_source_updates": {"name", "accepted_entries", "entries"},
    "macro_renames": {"old_name", "new_name", "package"},
    "graph_counter_repairs": {"entry_id", "level"},
    "requested_macros": {"name", "package", "kind", "style_name", "source_entry_id", "body"},
    "requested_structural_macros": {"name", "package", "canonical", "accepted_predecessors"},
    "entry_renames": {"old_id", "new_id", "package"},
    "macro_merges": {"source_name", "target_name", "package", "accepted_source_macro", "accepted_target_macro", "target_text_style_from", "target_text_style_name", "source_style_names", "canonical_style_names"},
    "snl_macro_rewrites": {"old_name", "new_name"},
    "macro_style_updates": {"name", "package", "source_entry_id", "accepted_style_names", "canonical_style_names", "symbolic_style_name", "symbolic_body", "text_style_from", "text_style_name", "kind", "dynamic_arity", "description"},
    "macro_snapshot_updates": {"name", "canonical", "accepted_predecessors"},
    "entry_snl_updates": {"id", "canonical", "accepted_predecessors"},
    "retired_macros": {"name", "package", "accepted_snapshots"},
    "entry_markdown_removals": {"id", "accepted_markdown"},
    "graph_detachments": {"library", "entry_ids"},
}


def validate_authorities(i18n: object, plan: object, entry_packages: object, expected_source_head: str) -> None:
    i18n = _required(i18n, {"source_head", "entries", "styles"}, {"source_head", "entries", "styles"}, "I18N authority")
    _require(i18n["source_head"] == expected_source_head, "I18N source lease changed")
    for entry_id, spec in i18n["entries"].items():
        spec = _required(spec, {"title"}, {"title", "markdown", "accepted_title_en", "accepted_title_predecessors", "accepted_markdown"}, f"I18N Entry {entry_id}")
        for field in ("title", "markdown"):
            if field in spec:
                _locale_projection(spec[field], f"I18N Entry {entry_id}.{field}")
        if "accepted_title_en" in spec:
            _string_list(spec["accepted_title_en"], f"I18N Entry {entry_id}.accepted_title_en")
        if "accepted_title_predecessors" in spec:
            _require(isinstance(spec["accepted_title_predecessors"], list), f"I18N Entry {entry_id}.accepted_title_predecessors must be a list")
            for predecessor_index, predecessor in enumerate(spec["accepted_title_predecessors"]):
                predecessor = _required(predecessor, {"type", "default_language", "values"}, {"type", "default_language", "values"}, f"I18N Entry {entry_id}.accepted_title_predecessors[{predecessor_index}]")
                _require(predecessor["type"] == "i18n" and predecessor["default_language"] in {"en", "zh-CN"}, f"I18N Entry {entry_id}.accepted_title_predecessors[{predecessor_index}] has invalid metadata")
                values = _known(predecessor["values"], {"en", "zh-CN"}, f"I18N Entry {entry_id}.accepted_title_predecessors[{predecessor_index}].values")
                _require(values and all(isinstance(value, str) for value in values.values()), f"I18N Entry {entry_id}.accepted_title_predecessors[{predecessor_index}] values must be nonempty strings")
        if "accepted_markdown" in spec:
            _require(isinstance(spec["accepted_markdown"], list), f"I18N Entry {entry_id}.accepted_markdown must be a list")
            for predecessor_index, predecessor in enumerate(spec["accepted_markdown"]):
                if predecessor is None or isinstance(predecessor, str):
                    continue
                predecessor = _required(predecessor, {"type", "default_language", "values"}, {"type", "default_language", "values"}, f"I18N Entry {entry_id}.accepted_markdown[{predecessor_index}]")
                _require(predecessor["type"] == "i18n" and predecessor["default_language"] in {"en", "zh-CN"}, f"I18N Entry {entry_id}.accepted_markdown[{predecessor_index}] has invalid metadata")
                _locale_projection(predecessor["values"], f"I18N Entry {entry_id}.accepted_markdown[{predecessor_index}].values")
    for style_id, spec in i18n["styles"].items():
        spec = _required(spec, {"en", "zh-CN", "template_envelope"}, {"en", "zh-CN", "template_envelope", "accepted_en", "accepted_body"}, f"I18N style {style_id}")
        _require(isinstance(spec["en"], str) and isinstance(spec["zh-CN"], str), f"I18N style {style_id} projections must be strings")
        _template_envelope(spec["template_envelope"], f"I18N style {style_id}.template_envelope")
        for field in ("accepted_en", "accepted_body"):
            if field in spec:
                _string_list(spec[field], f"I18N style {style_id}.{field}")

    plan_fields = set(_PLAN_LIST_FIELDS) | _PLAN_SCALAR_LISTS
    plan = _required(plan, plan_fields, plan_fields, "inductive authority")
    for collection, allowed in _PLAN_LIST_FIELDS.items():
        _require(isinstance(plan[collection], list), f"{collection} must be a list")
        for index, spec in enumerate(plan[collection]):
            _required(spec, _PLAN_REQUIRED_FIELDS[collection], allowed, f"{collection}[{index}]")
    for field in _PLAN_SCALAR_LISTS:
        _string_list(plan[field], field)

    for index, spec in enumerate(plan["graph_detachments"]):
        _require(isinstance(spec["library"], str) and spec["library"], f"graph_detachments[{index}].library must be a string")
        _string_list(spec["entry_ids"], f"graph_detachments[{index}].entry_ids")

    for index, spec in enumerate(plan["entry_snl_updates"]):
        _require(spec["canonical"] is None or isinstance(spec["canonical"], str), f"entry_snl_updates[{index}].canonical must be a string or null")
        _string_list(spec["accepted_predecessors"], f"entry_snl_updates[{index}].accepted_predecessors")

    for index, spec in enumerate(plan["retired_macros"]):
        _require(isinstance(spec["name"], str) and spec["name"], f"retired_macros[{index}].name must be a string")
        _require(isinstance(spec["package"], str) and spec["package"], f"retired_macros[{index}].package must be a string")
        _require(isinstance(spec["accepted_snapshots"], list) and spec["accepted_snapshots"], f"retired_macros[{index}].accepted_snapshots must be a nonempty list")
        for snapshot_index, snapshot in enumerate(spec["accepted_snapshots"]):
            _macro(snapshot, f"retired_macros[{index}].accepted_snapshots[{snapshot_index}]")
            _require(snapshot["name"] == spec["name"], f"retired_macros[{index}] snapshot name mismatch")

    for index, spec in enumerate(plan["entry_markdown_removals"]):
        _require(isinstance(spec["accepted_markdown"], list), f"entry_markdown_removals[{index}].accepted_markdown must be a list")
        for predecessor_index, predecessor in enumerate(spec["accepted_markdown"]):
            if predecessor is None or isinstance(predecessor, str):
                continue
            predecessor = _required(predecessor, {"type", "default_language", "values"}, {"type", "default_language", "values"}, f"entry_markdown_removals[{index}].accepted_markdown[{predecessor_index}]")
            _require(predecessor["type"] == "i18n" and predecessor["default_language"] in {"en", "zh-CN"}, f"entry_markdown_removals[{index}].accepted_markdown[{predecessor_index}] has invalid metadata")
            _locale_projection(predecessor["values"], f"entry_markdown_removals[{index}].accepted_markdown[{predecessor_index}].values")

    for index, spec in enumerate(plan["requested_entries"]):
        _locale_projection(spec["title"], f"requested_entries[{index}].title")
        content = _known(spec.get("content", {}), {"snl", "markdown"}, f"requested_entries[{index}].content")
        if "markdown" in content:
            _locale_projection(content["markdown"], f"requested_entries[{index}].content.markdown")
        if "accepted_content" in spec:
            _require(isinstance(spec["accepted_content"], list), f"requested_entries[{index}].accepted_content must be a list")
            for predecessor_index, predecessor in enumerate(spec["accepted_content"]):
                predecessor = _known(predecessor, {"snl", "markdown"}, f"requested_entries[{index}].accepted_content[{predecessor_index}]")
                if "snl" in predecessor:
                    _require(isinstance(predecessor["snl"], str), f"requested_entries[{index}].accepted_content[{predecessor_index}].snl must be a string")
                if "markdown" in predecessor:
                    _locale_projection(predecessor["markdown"], f"requested_entries[{index}].accepted_content[{predecessor_index}].markdown")
    for index, inductive in enumerate(plan["inductive_types"]):
        for child_kind, children in (("constructors", inductive["constructors"]), ("recursor", [inductive["recursor"]])):
            for child_index, child in enumerate(children):
                label = f"inductive_types[{index}].{child_kind}[{child_index}]"
                child = _known(child, {"id", "title", "kind", "accepted_kind", "content", "reuse"}, label)
                _locale_projection(child["title"], f"{label}.title")
                content = _known(child.get("content", {}), {"snl", "markdown"}, f"{label}.content")
                if "markdown" in content:
                    _locale_projection(content["markdown"], f"{label}.content.markdown")
    for index, ownership in enumerate(plan["concept_ownership"]):
        secondary_entries = ownership.get("secondary_entries", [])
        _require(isinstance(secondary_entries, list), f"concept_ownership[{index}].secondary_entries must be a list")
        for secondary_index, secondary in enumerate(secondary_entries):
            secondary = _required(secondary, {"library", "entry_id", "role"}, {"library", "entry_id", "role"}, f"concept_ownership[{index}].secondary_entries[{secondary_index}]")
            _require(all(isinstance(secondary[key], str) for key in ("library", "entry_id", "role")), f"concept_ownership[{index}].secondary_entries[{secondary_index}] fields must be strings")
    for index, spec in enumerate(plan["requested_macros"]):
        _locale_projection(spec["body"], f"requested_macros[{index}].body")
        if "accepted_bodies" in spec:
            accepted = _known(spec["accepted_bodies"], {"en", "zh-CN"}, f"requested_macros[{index}].accepted_bodies")
            for locale in ("en", "zh-CN"):
                _string_list(accepted[locale], f"requested_macros[{index}].accepted_bodies.{locale}")
    for index, spec in enumerate(plan["requested_structural_macros"]):
        _require(isinstance(spec["name"], str) and spec["name"], f"requested_structural_macros[{index}].name must be a string")
        _require(isinstance(spec["package"], str) and spec["package"], f"requested_structural_macros[{index}].package must be a string")
        _macro(spec["canonical"], f"requested_structural_macros[{index}].canonical")
        _require(spec["canonical"]["name"] == spec["name"], f"requested_structural_macros[{index}] canonical name mismatch")
        for predecessor_index, predecessor in enumerate(spec["accepted_predecessors"]):
            _macro(predecessor, f"requested_structural_macros[{index}].accepted_predecessors[{predecessor_index}]")
            _require(predecessor["name"] == spec["name"], f"requested_structural_macros[{index}] predecessor name mismatch")
    for index, spec in enumerate(plan["macro_snapshot_updates"]):
        _macro(spec["canonical"], f"macro_snapshot_updates[{index}].canonical")
        for predecessor_index, predecessor in enumerate(spec.get("accepted_predecessors", [])):
            _macro(predecessor, f"macro_snapshot_updates[{index}].accepted_predecessors[{predecessor_index}]")
        for digest in spec.get("accepted_predecessor_hashes", []):
            _require(isinstance(digest, str) and len(digest) == 64 and all(char in "0123456789abcdef" for char in digest), f"macro_snapshot_updates[{index}] has invalid predecessor hash")
    for index, spec in enumerate(plan["macro_merges"]):
        _macro(spec["accepted_source_macro"], f"macro_merges[{index}].accepted_source_macro")
        _macro(spec["accepted_target_macro"], f"macro_merges[{index}].accepted_target_macro")

    entry_package_fields = {"version", "source_head", "packages", "assignments", "manifests"}
    entry_packages = _required(entry_packages, entry_package_fields, entry_package_fields, "Entry Package authority")
    _require(entry_packages["source_head"] == expected_source_head, "Entry Package source lease changed")
    _require(entry_packages["version"] == 1, "unsupported Entry Package authority version")
    for package_id, spec in entry_packages["packages"].items():
        _required(spec, {"name", "description"}, {"name", "description"}, f"Entry Package metadata {package_id}")
    for package_id, spec in entry_packages["manifests"].items():
        spec = _required(spec, {"accepted_predecessor", "canonical"}, {"accepted_predecessor", "canonical"}, f"Entry Package manifest authority {package_id}")
        for state, manifest in (("canonical", spec["canonical"]), ("accepted_predecessor", spec.get("accepted_predecessor"))):
            if manifest is not None:
                manifest_fields = {"format", "version", "schema_version", "id", "name", "description", "entry_ids"}
                _required(manifest, manifest_fields, manifest_fields, f"Entry Package manifest {package_id}.{state}")
