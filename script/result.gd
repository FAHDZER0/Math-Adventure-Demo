extends Control

signal play_again_pressed
signal back_pressed

@export var operation_name: String = ""
@export var correct_answer: int = 0
@export var score: int = 0
@export var badge_earned: bool = false

@onready var operation_label: Label = $ResultPanel/ResultContainer/OperationLabel
@onready var answer_label: Label = $ResultPanel/ResultContainer/AnswerLabel
@onready var score_label: Label = $ResultPanel/ResultContainer/ScoreLabel
@onready var badge_label: Label = $ResultPanel/ResultContainer/BadgeLabel
@onready var play_again_button: Button = $ResultPanel/ResultContainer/Buttons/PlayAgainButton
@onready var back_button: Button = $ResultPanel/ResultContainer/Buttons/BackButton

func _ready() -> void:
	play_again_button.pressed.connect(func() -> void: play_again_pressed.emit())
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	_update_labels()

func setup(operation: String, answer: int, new_score: int, new_badge_earned: bool) -> void:
	operation_name = operation
	correct_answer = answer
	score = new_score
	badge_earned = new_badge_earned
	if is_inside_tree():
		_update_labels()

func _update_labels() -> void:
	operation_label.text = "Operation: %s" % operation_name
	answer_label.text = "Answer: %d" % correct_answer
	score_label.text = "Score: %d" % score
	badge_label.text = "Badge: Earned!" if badge_earned else "Badge: Keep trying"
