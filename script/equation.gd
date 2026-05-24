extends Control

const RESULT_SCENE := preload("res://scene/result.tscn")
const BASE_BG_COLOR := Color(0x83d197ff)
const FLASH_BG_COLOR := Color(1.0, 0.7, 0.7, 1.0)
const WRONG_FLASH_DURATION := 0.45
const WRONG_FLASH_INTENSITY := 0.45

@export var operation_name: String = ""
@export var time_per_question: int = 20
@export var max_attempts: int = 3
@export var min_value: int = 1
@export var max_value: int = 10
@export var warning_time: int = 6
@export var critical_time: int = 3
@export var badge_streak_required: int = 5

@onready var title_label: Label = $Content/TitleLabel
@onready var back_button: Button = $Content/BackButton
@onready var question_label: Label = $Content/QuestionLabel
@onready var feedback_label: Label = $Content/FeedbackLabel
@onready var timer_label: Label = $Content/TimerLabel
@onready var attempts_label: Label = $Content/AttemptsLabel
@onready var answers_container: GridContainer = $Content/AnswersContainer
@onready var tick_timer: Timer = $TickTimer
@onready var flash_background: ColorRect = $FlashBackground

var rng := RandomNumberGenerator.new()
var remaining_time: int = 0
var attempts_left: int = 0
var correct_answer: int = 0
var round_active: bool = false
var flash_phase: float = 0.0
var result_screen: Control
var round_score: int = 0
var correct_streak: int = 0
var badge_earned: bool = false
var wrong_flash_time_left: float = 0.0

func _ready() -> void:
	if operation_name != "":
		title_label.text = operation_name
	back_button.pressed.connect(_on_back_pressed)
	for answer_node in answers_container.get_children():
		var answer_button := answer_node as Button
		if answer_button:
			answer_button.pressed.connect(func() -> void: _on_answer_pressed(answer_button))
	tick_timer.timeout.connect(_on_tick)
	rng.randomize()
	timer_label.visible = false
	flash_background.color = BASE_BG_COLOR
	_start_new_question(true)

func _process(delta: float) -> void:
	_update_flash(delta)

func _start_new_question(reset_round: bool = false) -> void:
	if reset_round:
		round_score = 0
		correct_streak = 0
		badge_earned = false
	attempts_left = max_attempts
	remaining_time = time_per_question
	round_active = true
	feedback_label.text = ""
	_flash_reset()
	wrong_flash_time_left = 0.0
	_remove_result_screen()
	_set_gameplay_visible(true)
	_update_attempts_label()
	_update_timer_label()
	_generate_question()
	_set_answer_buttons_enabled(true)
	tick_timer.start()

func _generate_question() -> void:
	var a := 0
	var b := 0
	var symbol := "+"

	match operation_name:
		"Subtraction":
			a = rng.randi_range(min_value, max_value)
			b = rng.randi_range(min_value, max_value)
			if b > a:
				var temp := a
				a = b
				b = temp
			symbol = "-"
			correct_answer = a - b
		"Multiplication":
			a = rng.randi_range(min_value, max_value)
			b = rng.randi_range(min_value, max_value)
			symbol = "*"
			correct_answer = a * b
		"Division":
			b = rng.randi_range(min_value, max_value)
			correct_answer = rng.randi_range(min_value, max_value)
			a = b * correct_answer
			symbol = "/"
			correct_answer = a / b
		_:
			a = rng.randi_range(min_value, max_value)
			b = rng.randi_range(min_value, max_value)
			symbol = "+"
			correct_answer = a + b

	question_label.text = "%d %s %d = ?" % [a, symbol, b]
	_assign_answers()

func _assign_answers() -> void:
	var answers: Array[int] = [correct_answer]
	var max_wrong := max_value * max_value
	while answers.size() < 4:
		var wrong := rng.randi_range(0, max_wrong)
		if wrong == correct_answer:
			continue
		if answers.has(wrong):
			continue
		answers.append(wrong)
	answers.shuffle()

	var buttons: Array[Node] = answers_container.get_children()
	for i in range(min(buttons.size(), answers.size())):
		var button := buttons[i] as Button
		if button:
			button.text = str(answers[i])

func _on_answer_pressed(button: Button) -> void:
	if not round_active:
		return

	var chosen := int(button.text)
	if chosen == correct_answer:
		feedback_label.text = "Correct!"
		round_score += 1
		correct_streak += 1
		if correct_streak >= badge_streak_required:
			badge_earned = true
		await get_tree().create_timer(0.8).timeout
		_start_new_question()
		return

	attempts_left -= 1
	correct_streak = 0
	_trigger_wrong_flash()
	if attempts_left <= 0:
		_end_round()
		return

	feedback_label.text = "Try again."
	remaining_time = time_per_question
	_update_attempts_label()
	_update_timer_label()

func _on_tick() -> void:
	if not round_active:
		return
	remaining_time -= 1
	if remaining_time <= 0:
		attempts_left -= 1
		correct_streak = 0
		_trigger_wrong_flash()
		if attempts_left <= 0:
			_end_round()
			return
		feedback_label.text = "Time is up! Try again."
		remaining_time = time_per_question
		_update_attempts_label()
		_update_timer_label()
		return
	_update_timer_label()

func _end_round() -> void:
	round_active = false
	tick_timer.stop()
	_set_answer_buttons_enabled(false)
	feedback_label.text = ""
	_flash_reset()
	_show_result_screen()
	_set_gameplay_visible(false)
	_update_attempts_label()

func _set_answer_buttons_enabled(is_enabled: bool) -> void:
	for answer_node in answers_container.get_children():
		var answer_button := answer_node as Button
		if answer_button:
			answer_button.disabled = not is_enabled

func _update_attempts_label() -> void:
	attempts_label.text = "Attempts: %d" % attempts_left

func _update_timer_label() -> void:
	timer_label.text = "Time: %d" % remaining_time

func _show_result_screen() -> void:
	_remove_result_screen()
	result_screen = RESULT_SCENE.instantiate()
	add_child(result_screen)
	result_screen.setup(operation_name, correct_answer, round_score, badge_earned)
	result_screen.play_again_pressed.connect(_on_play_again_pressed)
	result_screen.back_pressed.connect(_on_back_pressed)

func _remove_result_screen() -> void:
	if result_screen and is_instance_valid(result_screen):
		result_screen.queue_free()
	result_screen = null

func _on_play_again_pressed() -> void:
	_start_new_question(true)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main.tscn")

func _update_flash(delta: float) -> void:
	if not round_active:
		_set_flash_intensity(0.0)
		return

	var level := 0.0
	var speed := 0.0
	if remaining_time <= critical_time:
		level = 0.32
		speed = 1.6
	elif remaining_time <= warning_time:
		level = 0.18
		speed = 0.8

	var wrong_intensity := 0.0
	if wrong_flash_time_left > 0.0:
		wrong_flash_time_left = max(0.0, wrong_flash_time_left - delta)
		wrong_intensity = WRONG_FLASH_INTENSITY * (wrong_flash_time_left / WRONG_FLASH_DURATION)

	if level <= 0.0 and wrong_intensity <= 0.0:
		flash_phase = 0.0
		_set_flash_intensity(0.0)
		return

	var time_intensity := 0.0
	if level > 0.0:
		flash_phase += delta * speed * TAU
		var pulse := (sin(flash_phase) + 1.0) * 0.5
		time_intensity = level * pulse
	_set_flash_intensity(max(time_intensity, wrong_intensity))

func _set_flash_intensity(intensity: float) -> void:
	var clamped: float = clampf(intensity, 0.0, 0.6)
	flash_background.color = BASE_BG_COLOR.lerp(FLASH_BG_COLOR, clamped)

func _flash_reset() -> void:
	flash_phase = 0.0
	_set_flash_intensity(0.0)

func _trigger_wrong_flash() -> void:
	wrong_flash_time_left = WRONG_FLASH_DURATION

func _set_gameplay_visible(is_visible: bool) -> void:
	title_label.visible = is_visible
	back_button.visible = is_visible
	question_label.visible = is_visible
	feedback_label.visible = is_visible
	attempts_label.visible = is_visible
	answers_container.visible = is_visible
	flash_background.visible = is_visible
