extends CanvasLayer
##
## Text-only ending page for M6 endings.
##
## The screen is built in script so the ending copy, fade, and restart hint stay
## together while the Maze scene owns when it appears.

const BACKDROP_COLOR := Color(0.047, 0.035, 0.059, 0.94)
const TITLE_COLOR := Color(0.94, 0.86, 0.88)
const BODY_COLOR := Color(0.84, 0.78, 0.82)
const HINT_COLOR := Color(0.62, 0.56, 0.62)
const BADGE_HEADER_COLOR := Color(0.78, 0.62, 0.68)
const BADGE_TITLE_COLOR := Color(0.96, 0.82, 0.62)
const BADGE_BODY_COLOR := Color(0.78, 0.74, 0.78)
const FADE_SECONDS := 0.8

@export var default_title := ""
@export_multiline var default_body := ""
@export var default_hint := "按 R 再走一次"

@onready var _root: Control = get_node_or_null("Root")
@onready var _title_label: Label = get_node_or_null("Root/Center/TextBox/EndingTitle")
@onready var _body_label: Label = get_node_or_null("Root/Center/TextBox/EndingBody")
@onready var _hint_label: Label = get_node_or_null("Root/Center/TextBox/RestartHint")

var _badges_box: VBoxContainer = null

func _ready() -> void:
	layer = 50
	visible = false
	if _root == null or _title_label == null or _body_label == null or _hint_label == null:
		_build_screen()

func show_ending(title: String, body: String, hint: String) -> void:
	if _title_label == null:
		_build_screen()

	_title_label.text = title
	_body_label.text = body
	_hint_label.text = hint
	_clear_badges()
	visible = true
	_root.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, FADE_SECONDS)

func show_ending_with_recap(title: String, body: String, hint: String, recap: String) -> void:
	var full_body := body
	if not recap.is_empty():
		full_body = "%s\n\n%s" % [body, recap]
	show_ending(title, full_body, hint)

func show_ending_with_recap_and_badges(title: String, body: String, hint: String, recap: String, badges: Array) -> void:
	show_ending_with_recap(title, body, hint, recap)
	_render_badges(badges)

func show_default_ending() -> void:
	show_ending(default_title, default_body, default_hint)

func show_default_ending_with_recap(recap: String) -> void:
	show_ending_with_recap(default_title, default_body, default_hint, recap)

func show_default_ending_with_recap_and_badges(recap: String, badges: Array) -> void:
	show_ending_with_recap_and_badges(default_title, default_body, default_hint, recap, badges)

func _build_screen() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = BACKDROP_COLOR
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	scroll.add_child(margin)

	var text_box := VBoxContainer.new()
	text_box.name = "TextBox"
	text_box.custom_minimum_size = Vector2(430.0, 0.0)
	text_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 12)
	margin.add_child(text_box)

	_title_label = Label.new()
	_title_label.name = "EndingTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	text_box.add_child(_title_label)

	_body_label = Label.new()
	_body_label.name = "EndingBody"
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 14)
	_body_label.add_theme_color_override("font_color", BODY_COLOR)
	text_box.add_child(_body_label)

	_badges_box = VBoxContainer.new()
	_badges_box.name = "Badges"
	_badges_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_badges_box.add_theme_constant_override("separation", 6)
	_badges_box.visible = false
	text_box.add_child(_badges_box)

	_hint_label = Label.new()
	_hint_label.name = "RestartHint"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", HINT_COLOR)
	text_box.add_child(_hint_label)

func _clear_badges() -> void:
	if _badges_box == null:
		return
	for child in _badges_box.get_children():
		child.queue_free()
	_badges_box.visible = false

func _render_badges(badges: Array) -> void:
	if _badges_box == null or badges.is_empty():
		return

	var header := Label.new()
	header.text = "—— 你獲得了 ——"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", BADGE_HEADER_COLOR)
	_badges_box.add_child(header)

	for badge in badges:
		if typeof(badge) != TYPE_DICTIONARY:
			continue
		var entry := VBoxContainer.new()
		entry.alignment = BoxContainer.ALIGNMENT_CENTER
		entry.add_theme_constant_override("separation", 1)

		var title := Label.new()
		title.text = String(badge.get("title", ""))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", BADGE_TITLE_COLOR)
		entry.add_child(title)

		var body := Label.new()
		body.text = String(badge.get("body", ""))
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 10)
		body.add_theme_color_override("font_color", BADGE_BODY_COLOR)
		entry.add_child(body)

		_badges_box.add_child(entry)

	_badges_box.visible = true
