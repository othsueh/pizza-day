extends Node2D
##
## M1 — drives the C ↔ Godot pipeline.
## Runs the maze_core executable, reads maze_state.json, and renders it
## onto the child TileMapLayer.
##
## Source IDs in maze_tileset.tres:
##   0 = floor
##   1 = wall
## Tile values from maze_core JSON:
##   0 = floor
##   1 = wall
## The mapping is intentionally identity so v can be passed straight in.

const ATLAS_COORDS := Vector2i(0, 0)

@onready var tile_layer: TileMapLayer = $TileMapLayer

func _ready() -> void:
	var maze := _run_maze_core()
	if maze.is_empty():
		return
	_render_maze(maze)

func _run_maze_core() -> Dictionary:
	var project_dir := ProjectSettings.globalize_path("res://")
	var exe_name := "maze_core.exe" if OS.has_feature("windows") else "maze_core"
	var exe_path := project_dir.path_join(exe_name)
	var out_path := ProjectSettings.globalize_path("user://maze_state.json")

	if not FileAccess.file_exists(exe_path):
		push_error("maze_core executable not found at %s — run `make` in c_src/" % exe_path)
		return {}

	var output: Array = []
	var args := PackedStringArray([out_path, str(int(Time.get_unix_time_from_system()))])
	var exit_code := OS.execute(exe_path, args, output, true)
	if exit_code != 0:
		push_error("maze_core exited with code %d. stdout/stderr:\n%s" % [exit_code, "\n".join(output)])
		return {}

	var f := FileAccess.open(out_path, FileAccess.READ)
	if f == null:
		push_error("cannot read %s" % out_path)
		return {}
	var json_text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("invalid JSON from maze_core")
		return {}
	return parsed

func _render_maze(maze: Dictionary) -> void:
	var w := int(maze.get("width", 0))
	var h := int(maze.get("height", 0))
	var tiles: Array = maze.get("tiles", [])
	tile_layer.clear()
	for y in h:
		var row: Array = tiles[y]
		for x in w:
			var source_id := int(row[x])
			tile_layer.set_cell(Vector2i(x, y), source_id, ATLAS_COORDS)
	print("maze_core: rendered %dx%d, seed=%s" % [w, h, maze.get("seed", "?")])
