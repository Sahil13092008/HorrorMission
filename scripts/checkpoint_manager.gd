extends CanvasLayer

# ==============================================================
# CHECKPOINT_MANAGER.GD
# Global Autoload Singleton for Instant Checkpoints & Scene Skips
# Allows the player to jump to any part of the story instantly,
# skip scenes, or recover if ever stuck.
# ==============================================================

var checkpoint_ui: Control
var menu_panel: PanelContainer
var toggle_btn: Button
var is_menu_open: bool = false
var prev_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

# List of story checkpoints
const CHECKPOINTS = [
	{
		"id": "classroom",
		"title": "🏫 1. Classroom (क्लासरूम — कृपाल गायब)",
		"scene": "res://scenes/classroom.tscn",
		"desc": "School classroom, realization Kripal is missing, cycle rush."
	},
	{
		"id": "cycle_ride",
		"title": "🚲 2. Cycle Ride (साइकिल राइड — सड़क का सफर)",
		"scene": "res://scenes/cycle_ride.tscn",
		"desc": "Bicycle ride with friends towards Kripal's house."
	},
	{
		"id": "kripal_house",
		"title": "🏠 3. Kripal's House (कृपाल का घर — मम्मी से बातचीत)",
		"scene": "res://scenes/street_to_kripal.tscn",
		"desc": "Street outside Kripal's house, talking to Kripal's worried mother."
	},
	{
		"id": "police_station",
		"title": "🚔 4. Police Station (पुलिस स्टेशन — FIR दर्ज)",
		"scene": "res://scenes/police_station.tscn",
		"desc": "Pansemal Police Station, Inspector Sharma, official missing report."
	},
	{
		"id": "phone_call",
		"title": "📞 5. 2 Days Later (२ दिन बाद — 3-Way Phone Call)",
		"scene": "res://scenes/phone_call_convo.tscn",
		"desc": "3 friends in their bedrooms on group phone call, Bhangarh decision."
	},
	{
		"id": "bhangarh_ruins",
		"title": "🏰 6. Bhangarh Ruins (भानगढ़ खंडहर — Chapter 2)",
		"scene": "res://scenes/bhangarh_ruins.tscn",
		"desc": "Expedition starts at Bhangarh Fort ruins at midnight."
	}
]

func _ready() -> void:
	layer = 120 # Above all other HUDs
	process_mode = Node.PROCESS_MODE_ALWAYS # Runs even when paused
	
	build_ui()

func build_ui() -> void:
	checkpoint_ui = Control.new()
	checkpoint_ui.name = "CheckpointRoot"
	checkpoint_ui.anchors_preset = Control.PRESET_FULL_RECT
	checkpoint_ui.anchor_right = 1.0
	checkpoint_ui.anchor_bottom = 1.0
	checkpoint_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(checkpoint_ui)
	
	# Top-Right Floating Fast-Travel Button
	toggle_btn = Button.new()
	toggle_btn.text = "⚡ CHECKPOINTS [TAB]"
	toggle_btn.tooltip_text = "Press [TAB] or click to jump to any chapter/checkpoint"
	toggle_btn.anchors_preset = Control.PRESET_TOP_RIGHT
	toggle_btn.anchor_left = 1.0
	toggle_btn.anchor_right = 1.0
	toggle_btn.offset_left = -210
	toggle_btn.offset_top = 12
	toggle_btn.offset_right = -12
	toggle_btn.offset_bottom = 44
	toggle_btn.focus_mode = Control.FOCUS_NONE
	
	# Style for Toggle Button
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.14, 0.22, 0.88)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.3, 0.8, 1.0, 0.8)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_bottom_left = 8
	toggle_btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.35, 0.55, 0.95)
	btn_hover.border_color = Color(0.5, 1.0, 0.5, 1.0)
	toggle_btn.add_theme_stylebox_override("hover", btn_hover)
	
	toggle_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	toggle_btn.add_theme_font_size_override("font_size", 13)
	toggle_btn.pressed.connect(toggle_menu)
	checkpoint_ui.add_child(toggle_btn)
	
	# Modal Checkpoint Dialog
	menu_panel = PanelContainer.new()
	menu_panel.anchors_preset = Control.PRESET_CENTER
	menu_panel.anchor_left = 0.5
	menu_panel.anchor_top = 0.5
	menu_panel.anchor_right = 0.5
	menu_panel.anchor_bottom = 0.5
	menu_panel.offset_left = -280
	menu_panel.offset_top = -240
	menu_panel.offset_right = 280
	menu_panel.offset_bottom = 240
	menu_panel.visible = false
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1.0, 0.75, 0.2, 0.9)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.shadow_size = 20
	panel_style.shadow_color = Color(0, 0, 0, 0.8)
	menu_panel.add_theme_stylebox_override("panel", panel_style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	menu_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "📍 STORY CHECKPOINTS (स्टोरी चेकपॉइंट्स)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	var hint = Label.new()
	hint.text = "किसी भी सीन या अपडेट को सीधे टेस्ट करने के लिए चुनें:"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hint)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Buttons for each checkpoint
	for cp in CHECKPOINTS:
		var cp_btn = Button.new()
		cp_btn.text = cp["title"]
		cp_btn.tooltip_text = cp["desc"]
		cp_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		cp_btn.custom_minimum_size = Vector2(0, 36)
		cp_btn.focus_mode = Control.FOCUS_NONE
		
		var bstyle = StyleBoxFlat.new()
		bstyle.bg_color = Color(0.12, 0.16, 0.24, 0.9)
		bstyle.border_width_left = 1
		bstyle.border_width_top = 1
		bstyle.border_width_right = 1
		bstyle.border_width_bottom = 1
		bstyle.border_color = Color(0.3, 0.5, 0.7, 0.6)
		bstyle.corner_radius_top_left = 6
		bstyle.corner_radius_top_right = 6
		bstyle.corner_radius_bottom_right = 6
		bstyle.corner_radius_bottom_left = 6
		cp_btn.add_theme_stylebox_override("normal", bstyle)
		
		var bhover = bstyle.duplicate()
		bhover.bg_color = Color(0.2, 0.45, 0.7, 1.0)
		bhover.border_color = Color(0.4, 0.9, 1.0, 1.0)
		cp_btn.add_theme_stylebox_override("hover", bhover)
		
		var scene_path = cp["scene"]
		cp_btn.pressed.connect(func(): jump_to_scene(scene_path))
		vbox.add_child(cp_btn)
		
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var close_btn = Button.new()
	close_btn.text = "✖ CLOSE / RESUME (वापस गेम में जाएं)"
	close_btn.custom_minimum_size = Vector2(0, 34)
	close_btn.focus_mode = Control.FOCUS_NONE
	
	var cstyle = StyleBoxFlat.new()
	cstyle.bg_color = Color(0.4, 0.12, 0.12, 0.9)
	cstyle.corner_radius_top_left = 6
	cstyle.corner_radius_top_right = 6
	cstyle.corner_radius_bottom_right = 6
	cstyle.corner_radius_bottom_left = 6
	close_btn.add_theme_stylebox_override("normal", cstyle)
	close_btn.pressed.connect(close_menu)
	vbox.add_child(close_btn)
	
	checkpoint_ui.add_child(menu_panel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_F1:
			toggle_menu()
		elif event.keycode == KEY_ESCAPE and is_menu_open:
			close_menu()

func toggle_menu() -> void:
	if is_menu_open:
		close_menu()
	else:
		open_menu()

func open_menu() -> void:
	is_menu_open = true
	prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_panel.visible = true
	menu_panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(menu_panel, "modulate:a", 1.0, 0.2)

func close_menu() -> void:
	is_menu_open = false
	menu_panel.visible = false
	if prev_mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func jump_to_scene(scene_path: String) -> void:
	close_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Verify target exists
	if not ResourceLoader.exists(scene_path):
		print("ERROR: Scene does not exist: ", scene_path)
		return
		
	print("Fast-traveling to checkpoint scene: ", scene_path)
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		print("change_scene_to_file failed with error %d, trying packed scene..." % err)
		var ps = ResourceLoader.load(scene_path) as PackedScene
		if ps:
			get_tree().change_scene_to_packed(ps)
