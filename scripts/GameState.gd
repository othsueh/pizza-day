extends Node
##
## M4 gameplay stats state.
##
## Kept as a scene-local node so the maze owns this run's volatile stats.

signal stats_changed(vision_label: String, achievement: int, instability: int, stage: int, critical_state: bool)

const MIN_VISION_LEVEL := 1  ## 3x3
const MAX_VISION_LEVEL := 4  ## 9x9

const ENDING_BAD := 0
const ENDING_NORMAL := 1
const ENDING_TRUE := 2

var vision_level: int = 1
var opened_chests: int = 0
var picked_vision_cores: int = 0
var solved_puzzles: int = 0
var defeated_enemies: int = 0
var explored_tiles: int = 0
var total_walkable_tiles: int = 0
var greed_buttons_pressed: int = 0
var bonus_instability: int = 0
var instability: int = 0
var instability_stage: int = 0
var critical_state: bool = false

var max_vision_level_reached: int = 1
var critical_state_ever_triggered: bool = false
var total_wall_hints_in_run: int = 0

var _explored_cells: Dictionary = {}
var _wall_hint_texts: Dictionary = {}
var _wall_hints_read: Dictionary = {}

func reset_from_core(stats: Dictionary, stage: int, is_critical: bool = false) -> void:
	vision_level = int(clamp(int(stats.get("vision", vision_level)), MIN_VISION_LEVEL, MAX_VISION_LEVEL))
	opened_chests = int(stats.get("chests", opened_chests))
	picked_vision_cores = 0
	solved_puzzles = int(stats.get("puzzles", solved_puzzles))
	defeated_enemies = int(stats.get("enemies", defeated_enemies))
	explored_tiles = int(stats.get("explored", explored_tiles))
	total_walkable_tiles = int(stats.get("total_walkable", total_walkable_tiles))
	greed_buttons_pressed = int(stats.get("greed_buttons", 0))
	bonus_instability = int(stats.get("bonus", 0))
	instability = int(stats.get("instability", instability))
	instability_stage = stage
	critical_state = is_critical
	max_vision_level_reached = vision_level
	critical_state_ever_triggered = is_critical
	total_wall_hints_in_run = 0
	_explored_cells.clear()
	_wall_hint_texts.clear()
	_wall_hints_read.clear()
	_emit_stats_changed()

func apply_core_result(stats: Dictionary, stage: int, is_critical: bool = false) -> void:
	vision_level = int(clamp(int(stats.get("vision", vision_level)), MIN_VISION_LEVEL, MAX_VISION_LEVEL))
	opened_chests = int(stats.get("chests", opened_chests))
	solved_puzzles = int(stats.get("puzzles", solved_puzzles))
	defeated_enemies = int(stats.get("enemies", defeated_enemies))
	explored_tiles = int(stats.get("explored", explored_tiles))
	greed_buttons_pressed = int(stats.get("greed_buttons", greed_buttons_pressed))
	bonus_instability = int(stats.get("bonus", bonus_instability))
	instability = int(stats.get("instability", instability))
	instability_stage = stage
	critical_state = is_critical
	max_vision_level_reached = max(max_vision_level_reached, vision_level)
	if is_critical:
		critical_state_ever_triggered = true
	_emit_stats_changed()

func mark_explored(cell: Vector2i) -> bool:
	if _explored_cells.has(cell):
		return false
	_explored_cells[cell] = true
	explored_tiles = _explored_cells.size()
	return true

func apply_chest_open() -> void:
	opened_chests += 1

func apply_vision_core_pickup() -> void:
	picked_vision_cores += 1
	vision_level = min(vision_level + 2, MAX_VISION_LEVEL)
	max_vision_level_reached = max(max_vision_level_reached, vision_level)

func register_wall_hint(hint_text: String) -> void:
	if hint_text.is_empty():
		return
	_wall_hint_texts[hint_text] = true
	total_wall_hints_in_run = _wall_hint_texts.size()

func mark_wall_hint_read(hint_text: String) -> void:
	if hint_text.is_empty():
		return
	_wall_hints_read[hint_text] = true

func get_wall_hints_read_count() -> int:
	return _wall_hints_read.size()

func apply_enemy_seen() -> void:
	defeated_enemies += 1

func apply_greed_button(delta: int) -> void:
	greed_buttons_pressed += 1
	bonus_instability += delta

func set_total_walkable_tiles(total: int) -> void:
	total_walkable_tiles = max(total, 0)
	_emit_stats_changed()

func get_vision_core_count() -> int:
	return picked_vision_cores

func get_achievement() -> int:
	return opened_chests + solved_puzzles + defeated_enemies + greed_buttons_pressed

func get_vision_radius() -> int:
	return vision_level

func get_vision_label() -> String:
	var diameter := vision_level * 2 + 1
	return "%dx%d" % [diameter, diameter]

func get_exploration_percent() -> float:
	if total_walkable_tiles <= 0:
		return 0.0
	return float(explored_tiles) / float(total_walkable_tiles) * 100.0

func to_core_stats() -> Dictionary:
	return {
		"vision": vision_level,
		"chests": opened_chests,
		"puzzles": solved_puzzles,
		"enemies": defeated_enemies,
		"explored": explored_tiles,
		"bonus": bonus_instability,
	}

func get_debug_snapshot() -> Dictionary:
	return {
		"vision_level": vision_level,
		"opened_chests": opened_chests,
		"vision_cores": picked_vision_cores,
		"puzzles_solved": solved_puzzles,
		"enemies_seen": defeated_enemies,
		"explored_tiles": explored_tiles,
		"total_walkable_tiles": total_walkable_tiles,
		"exploration_percent": get_exploration_percent(),
		"greed_buttons": greed_buttons_pressed,
		"bonus_instability": bonus_instability,
		"instability": instability,
		"critical_state": critical_state,
	}

func evaluate_achievements(ending_type: int, exit_type: String) -> Array:
	var badges: Array = []
	var exploration_pct := get_exploration_percent()
	var hints_read := get_wall_hints_read_count()

	match ending_type:
		ENDING_TRUE:
			if opened_chests == 0 and picked_vision_cores == 0:
				badges.append({
					"title": "空手而歸",
					"body": "你經過了所有發亮的東西，沒有伸手。",
				})
			if max_vision_level_reached == MIN_VISION_LEVEL:
				badges.append({
					"title": "不眨眼",
					"body": "三格的視野，足以走到底。",
				})
			if greed_buttons_pressed == 0:
				badges.append({
					"title": "拒絕之人",
					"body": "紅色的按鈕，沒有等到第二聲心跳。",
				})
			if instability <= 20:
				badges.append({
					"title": "邊界的守者",
					"body": "不穩定度不到二十，迷宮幾乎沒注意到你來過。",
				})
			if total_wall_hints_in_run > 0 and hints_read >= total_wall_hints_in_run:
				badges.append({
					"title": "牆的傾聽者",
					"body": "你讀完了牆上所有字。它們是寫給願意停下的人。",
				})
			if critical_state_ever_triggered:
				badges.append({
					"title": "無視警告",
					"body": "它叫過你停下。你聽到了，繼續走，然後走出去了。",
				})
			if exploration_pct < 30.0:
				badges.append({
					"title": "第一個轉身",
					"body": "你只看了三成，就知道夠了。",
				})
		ENDING_NORMAL:
			badges.append({
				"title": "你走出去了",
				"body": "一個誠實的離開。",
			})
			if instability >= 50 and instability <= 69:
				badges.append({
					"title": "半個自己",
					"body": "你帶走了一些自己，也留了一些下來。",
				})
			if exit_type == "false" and instability < 30:
				badges.append({
					"title": "錯過真相",
					"body": "你明明可以走另一扇門的。",
				})
		ENDING_BAD:
			badges.append({
				"title": "被記住的人",
				"body": "不穩定度滿了。出口開始把你忘記。",
			})
			if greed_buttons_pressed >= 2:
				badges.append({
					"title": "餵飽迷宮",
					"body": "你親手把牆變短。它把這件事記下來了。",
				})
			if opened_chests >= 3 and picked_vision_cores >= 1:
				badges.append({
					"title": "完美的失敗",
					"body": "你做對了所有「該做」的事，然後迷宮收下了你。",
				})
			if greed_buttons_pressed == 0:
				badges.append({
					"title": "被迷宮選中",
					"body": "你沒按任何按鈕，光是好奇就足夠了。",
				})

	return badges

func build_ending_recap() -> String:
	var explored_text := "%d / %d tiles (%.0f%%)" % [
		explored_tiles,
		total_walkable_tiles,
		get_exploration_percent(),
	]
	return (
		"本局回顧\n"
		+ "打開的寶箱：%d\n" % opened_chests
		+ "拿走的視野核心：%d\n" % picked_vision_cores
		+ "按下的貪婪按鈕：%d\n" % greed_buttons_pressed
		+ "探索範圍：%s\n" % explored_text
		+ "最終不穩定度：%d" % instability
	)

func _emit_stats_changed() -> void:
	stats_changed.emit(get_vision_label(), get_achievement(), instability, instability_stage, critical_state)
