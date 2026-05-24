extends Area2D

@export var target_wall: Vector2i = Vector2i.ZERO
@export var instability_delta := 15

var activated := false

@onready var _label: Label = get_node_or_null("ButtonLabel")
@onready var _plate: ColorRect = get_node_or_null("Plate")

func _ready() -> void:
	add_to_group("interactable")
	_update_visual()

func interact(player: Node = null) -> void:
	if activated:
		return
	activated = true
	if is_in_group("interactable"):
		remove_from_group("interactable")
	if player and player.has_method("on_greed_button_pressed"):
		player.on_greed_button_pressed(self)
	_update_visual()

func _update_visual() -> void:
	if _label:
		_label.text = "!" if not activated else "x"
	if _plate:
		_plate.color = Color(0.72, 0.14, 0.12, 0.92) if not activated else Color(0.2, 0.16, 0.18, 0.78)
