## Repo paths and JSON loading. No dependencies, so any script can preload it.
extends RefCounted


static func repo_root() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()


static func repo_path(rel: String) -> String:
	return repo_root().path_join(rel)


static func resolve(p: String) -> String:
	var q := p.replace("\\", "/")
	if q.is_absolute_path():
		return q
	return repo_path(q)


## Returns {"ok": bool, "data": Variant, "error": String}.
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "data": null, "error": "file not found: %s" % path}
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) != OK:
		return {"ok": false, "data": null, "error": "%s:%d: %s" % [path, j.get_error_line(), j.get_error_message()]}
	return {"ok": true, "data": j.data, "error": ""}


static func list_json(rel_dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(repo_path(rel_dir)):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	out.sort()
	return out


## Recursive merge: dictionaries merge key by key, everything else replaces.
static func deep_merge(a, b):
	if typeof(a) == TYPE_DICTIONARY and typeof(b) == TYPE_DICTIONARY:
		var out: Dictionary = a.duplicate(true)
		for k in b:
			out[k] = deep_merge(out.get(k), b[k]) if out.has(k) else _copy(b[k])
		return out
	return _copy(b)


static func _copy(v):
	if typeof(v) == TYPE_DICTIONARY or typeof(v) == TYPE_ARRAY:
		return v.duplicate(true)
	return v
