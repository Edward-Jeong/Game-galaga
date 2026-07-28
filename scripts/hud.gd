extends CanvasLayer
class_name GameHUD

signal start_pressed
signal pause_pressed
signal mute_pressed

var _score_label: Label
var _best_label: Label
var _wave_label: Label
var _lives_label: Label
var _boss_panel: PanelContainer
var _boss_bar: ProgressBar
var _overlay: ColorRect
var _title_label: Label
var _message_label: Label
var _start_button: Button
var _pause_button: Button
var _mute_button: Button
var _banner: Label


func _ready() -> void:
	_build_interface()
	update_score(0)
	update_best(0)
	update_wave(1)
	update_lives(3)
	update_muted(false)
	set_boss_health(0, 1)
	set_state(GameSession.State.READY)


func _build_interface() -> void:
	var root := Control.new()
	root.name = "Interface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var hud_panel := PanelContainer.new()
	hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_panel.offset_left = 14.0
	hud_panel.offset_top = 14.0
	hud_panel.offset_right = -14.0
	hud_panel.offset_bottom = 82.0
	hud_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.10, 0.82), Color(0.25, 0.78, 1.0, 0.32), 10))
	root.add_child(hud_panel)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	hud_panel.add_child(stats)
	_score_label = _add_stat(stats, "SCORE")
	_best_label = _add_stat(stats, "BEST")
	_wave_label = _add_stat(stats, "WAVE")
	_lives_label = _add_stat(stats, "LIVES")

	_boss_panel = PanelContainer.new()
	_boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_panel.offset_left = 70.0
	_boss_panel.offset_top = 94.0
	_boss_panel.offset_right = -70.0
	_boss_panel.offset_bottom = 129.0
	_boss_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.02, 0.09, 0.88), Color(0.9, 0.25, 0.62, 0.55), 8))
	root.add_child(_boss_panel)
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size.y = 15.0
	_boss_bar.add_theme_stylebox_override("background", _panel_style(Color("#130b22"), Color.TRANSPARENT, 5))
	_boss_bar.add_theme_stylebox_override("fill", _panel_style(Color("#ff4f85"), Color.TRANSPARENT, 5))
	_boss_panel.add_child(_boss_bar)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -210.0
	_banner.offset_top = 148.0
	_banner.offset_right = 210.0
	_banner.offset_bottom = 205.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 27)
	_banner.add_theme_color_override("font_color", Color("#ffd45a"))
	_banner.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_banner.add_theme_constant_override("shadow_offset_x", 2)
	_banner.add_theme_constant_override("shadow_offset_y", 3)
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_banner)

	_pause_button = Button.new()
	_pause_button.text = "Ⅱ"
	_pause_button.tooltip_text = "Pause"
	_pause_button.custom_minimum_size = Vector2(58.0, 58.0)
	_pause_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_pause_button.offset_left = -76.0
	_pause_button.offset_top = -78.0
	_pause_button.offset_right = -18.0
	_pause_button.offset_bottom = -20.0
	_style_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	root.add_child(_pause_button)

	_mute_button = Button.new()
	_mute_button.tooltip_text = "Sound"
	_mute_button.custom_minimum_size = Vector2(58.0, 58.0)
	_mute_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_mute_button.offset_left = 18.0
	_mute_button.offset_top = -78.0
	_mute_button.offset_right = 76.0
	_mute_button.offset_bottom = -20.0
	_style_button(_mute_button)
	_mute_button.pressed.connect(func() -> void: mute_pressed.emit())
	root.add_child(_mute_button)

	_overlay = ColorRect.new()
	_overlay.color = Color(0.008, 0.014, 0.045, 0.88)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24.0
	center.offset_right = -24.0
	_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(450.0, 420.0)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.04, 0.10, 0.97), Color(0.27, 0.84, 1.0, 0.55), 18))
	center.add_child(card)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	card.add_child(content)

	_title_label = Label.new()
	_title_label.text = "STARLINE\nDEFENDER"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 46)
	_title_label.add_theme_color_override("font_color", Color("#ffd45a"))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.05, 0.0, 0.9))
	_title_label.add_theme_constant_override("shadow_offset_x", 3)
	_title_label.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(_title_label)

	_message_label = Label.new()
	_message_label.text = "Drag to move · Auto fire\nClear three waves and defeat the flagship"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size.x = 380.0
	_message_label.add_theme_font_size_override("font_size", 18)
	_message_label.add_theme_color_override("font_color", Color("#dff7ff"))
	content.add_child(_message_label)

	_start_button = Button.new()
	_start_button.text = "START MISSION"
	_start_button.custom_minimum_size = Vector2(250.0, 62.0)
	_start_button.add_theme_font_size_override("font_size", 20)
	_style_button(_start_button, true)
	_start_button.pressed.connect(func() -> void: start_pressed.emit())
	content.add_child(_start_button)


func _add_stat(parent: HBoxContainer, title: String) -> Label:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color("#89a8c5"))
	box.add_child(title_label)
	var value_label := Label.new()
	value_label.text = "0"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color("#f5fbff"))
	box.add_child(value_label)
	parent.add_child(box)
	return value_label


func _style_button(button: Button, primary: bool = false) -> void:
	var fill := Color(0.08, 0.32, 0.47, 0.95) if primary else Color(0.025, 0.07, 0.15, 0.92)
	var border := Color(0.27, 0.84, 1.0, 0.85) if primary else Color(0.27, 0.84, 1.0, 0.42)
	button.add_theme_stylebox_override("normal", _panel_style(fill, border, 10))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.12), Color("#72e4ff"), 10))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.12), Color("#ffd45a"), 10))
	button.add_theme_stylebox_override("focus", _panel_style(fill, Color("#ffd45a"), 10))
	button.add_theme_color_override("font_color", Color("#f5fbff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func update_score(value: int) -> void:
	_score_label.text = "%06d" % value


func update_best(value: int) -> void:
	_best_label.text = "%06d" % value


func update_wave(value: int) -> void:
	_wave_label.text = "%d/3" % value


func update_lives(value: int) -> void:
	_lives_label.text = "◆".repeat(maxi(0, value))


func update_muted(value: bool) -> void:
	_mute_button.text = "×♪" if value else "♪"
	_mute_button.tooltip_text = "Enable sound" if value else "Mute sound"


func set_boss_health(current: int, maximum: int) -> void:
	_boss_panel.visible = current > 0
	_boss_bar.max_value = maxi(1, maximum)
	_boss_bar.value = maxi(0, current)


func set_state(value: GameSession.State) -> void:
	_overlay.visible = value != GameSession.State.PLAYING
	_pause_button.visible = value == GameSession.State.PLAYING
	match value:
		GameSession.State.READY:
			_title_label.text = "STARLINE\nDEFENDER"
			_message_label.text = "Drag to move · Auto fire\nClear three waves and defeat the flagship"
			_start_button.text = "START MISSION"
		GameSession.State.PAUSED:
			_title_label.text = "MISSION\nPAUSED"
			_message_label.text = "Your flight is safely suspended."
			_start_button.text = "RESUME"
		GameSession.State.GAME_OVER:
			_title_label.text = "MISSION\nFAILED"
			_message_label.text = "The defense line has fallen.\nRegroup and try again."
			_start_button.text = "RETRY"
		GameSession.State.VICTORY:
			_title_label.text = "SECTOR\nSECURED"
			_message_label.text = "The enemy flagship is gone.\nThe starline is safe—for now."
			_start_button.text = "PLAY AGAIN"


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 1.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.9)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.55)
