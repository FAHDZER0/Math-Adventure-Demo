extends Control

const EQUATION_SCENE := preload("res://scene/equation.tscn")

@onready var addition_button: Button = $Content/GridContainer/Addition
@onready var subtraction_button: Button = $Content/GridContainer/Subtraction
@onready var multiplication_button: Button = $Content/GridContainer/Multiplication
@onready var division_button: Button = $Content/GridContainer/Division
@onready var back_button: Button = $Button

func _ready() -> void:
	addition_button.pressed.connect(func() -> void: _open_equation("Addition"))
	subtraction_button.pressed.connect(func() -> void: _open_equation("Subtraction"))
	multiplication_button.pressed.connect(func() -> void: _open_equation("Multiplication"))
	division_button.pressed.connect(func() -> void: _open_equation("Division"))
	back_button.pressed.connect(_on_back_pressed)

func _open_equation(operation_name: String) -> void:
	var equation_screen := EQUATION_SCENE.instantiate()
	equation_screen.operation_name = operation_name
	get_tree().root.add_child(equation_screen)
	get_tree().current_scene = equation_screen
	queue_free()

func _on_back_pressed() -> void:
	get_tree().quit()
