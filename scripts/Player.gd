extends CharacterBody2D

@export var tile_layer_path: NodePath = NodePath("../TileMapLayer")
@export var start_cell := Vector2i(1, 1)
@export var move_speed := 160.0
@export var wall_source_id := 1

@onready var tile_layer: TileMapLayer = get_node_or_null(tile_layer_path)
@onready var camera: Camera2D = $Camera2D

var _target_pos := Vector2.ZERO
var _moving := false

func _ready() -> void:
	if camera:
		camera.make_current()
	if tile_layer == null:
		push_warning("TileMapLayer not found at %s" % tile_layer_path)
		return
	call_deferred("_snap_to_floor")

func _physics_process(delta: float) -> void:
	if tile_layer == null:
		return
	if _moving:
		var step := move_speed * delta
		global_position = global_position.move_toward(_target_pos, step)
		if global_position.distance_to(_target_pos) <= 0.01:
			global_position = _target_pos
			_moving = false
		return

	var dir := _read_input()
	if dir == Vector2i.ZERO:
		return

	var from_cell := _world_to_cell(global_position)
	var to_cell := from_cell + dir
	if _cell_is_blocked(to_cell):
		return

	_target_pos = _cell_to_world(to_cell)
	_moving = true

func _read_input() -> Vector2i:
	if Input.is_action_just_pressed("ui_up"):
		return Vector2i(0, -1)
	if Input.is_action_just_pressed("ui_down"):
		return Vector2i(0, 1)
	if Input.is_action_just_pressed("ui_left"):
		return Vector2i(-1, 0)
	if Input.is_action_just_pressed("ui_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _snap_to_floor() -> void:
	if tile_layer == null:
		return
	var cell := start_cell
	if _cell_is_blocked(cell):
		var used := tile_layer.get_used_cells()
		for c in used:
			if not _cell_is_blocked(c):
				cell = c
				break
	_set_to_cell(cell)

func _set_to_cell(cell: Vector2i) -> void:
	_target_pos = _cell_to_world(cell)
	global_position = _target_pos
	_moving = false

func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return tile_layer.local_to_map(tile_layer.to_local(world_pos))

func _cell_to_world(cell: Vector2i) -> Vector2:
	return tile_layer.to_global(tile_layer.map_to_local(cell))

func _cell_is_blocked(cell: Vector2i) -> bool:
	var source_id := tile_layer.get_cell_source_id(cell)
	return source_id == wall_source_id or source_id == -1
