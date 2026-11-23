extends CanvasLayer

# ==============================================================
# CHECKPOINT_MANAGER.GD
# Global Autoload Singleton — Ultra User-Friendly Checkpoints & Skip
# - Keyboard: [TAB], [C], [F1]
# - Always-visible HUD Bar at Top-Center/Top-Right
# - One-click "NEXT SCENE ⏩" quick jump
# - Full Chapter Select with progress indicator & descriptions
# - Forces MOUSE_MODE_VISIBLE so cursor is ALWAYS visible when open!
# ==============================================================

var is_menu_open: bool = false
var prev_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var force_show_controls: bool = false

var hud_container: HBoxContainer
var toggle_btn: Button
var quick_next_btn: Button
var controls_toggle_btn: Button
var modal_overlay: ColorRect
var modal_panel: PanelContainer
var cards_vbox: VBoxContainer

const CHAPTERS = [
	{
		"num": "1",
		"icon": "🏫",
		"id": "classroom",
		"title": "Classroom (क्लासरूम)",
		"sub": "कृपाल की बेंच खाली, रहस्यमयी नोट, और दोस्तों की चर्चा",
		"scene": "res://scenes/classroom.tscn"
	},
	{
		"num": "2",
		"icon": "🚲",
		"id": "cycle_ride",
		"title": "Cycle Ride (साइकिल राइड)",
		"sub": "साइकिल उठाकर तूफानी शाम में कृपाल के घर की तरफ भागना",
		"scene": "res://scenes/cycle_ride.tscn"
	},
	{
		"num": "3",
		"icon": "🏠",
		"id": "street_to_kripal",
		"title": "Kripal's House (कृपाल का घर)",
		"sub": "कृपाल के घर के बाहर रोती हुई आंटी से बातचीत व पुलिस प्लान",
		"scene": "res://scenes/street_to_kripal.tscn"
	},
	{
		"num": "4",
		"icon": "🚔",
		"id": "police_station",
		"title": "Police Station (पानसेमल पुलिस स्टेशन)",
		"sub": "थानेदार आर.के. शर्मा के सामने बैठना व आधिकारिक FIR दर्ज होना",
		"scene": "res://scenes/police_station.tscn"
	},
	{
		"num": "5",
		"icon": "📞",
		"id": "phone_call_convo",
		"title": "2 Days Later (२ दिन बाद — 3-Way Phone Call)",
		"sub": "तीनों दोस्त अपने-अपने कमरों से फ़ोन कॉन्फ्रेंस पर — भानगढ़ का फैसला",
		"scene": "res://scenes/phone_call_convo.tscn"
	},
	{
		"num": "6",
		"icon": "🏰",
		"id": "bhangarh_ruins",
		"title": "Bhangarh Ruins (भानगढ़ खंडहर — Chapter 2)",
		"sub": "मध्यरात्रि में भानगढ़ के खंडहरों में कृपाल की खोज का मिशन",
		"scene": "res://scenes/bhangarh_ruins.tscn"
	}
]

func _ready() -> void:
	layer = 125 # Topmost UI layer
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or DisplayServer.is_touchscreen_available()
	force_show_controls = is_mobile
	
	# Force landscape orientation and fullscreen on mobile devices
	if is_mobile:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Register standard gameplay actions
	for action in ["move_forward", "move_backward", "move_left", "move_right", "interact", "flashlight", "sprint"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	
	build_hud()
	build_modal()
	build_mobile_controls()
	_ensure_controls_visibility()

func _process(_delta: float) -> void:
	# Keep mouse cursor visible whenever menu is open
	if is_menu_open:
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_ensure_controls_visibility()

func _ensure_controls_visibility() -> void:
	if not mobile_controls_root:
		return
	if is_menu_open:
		mobile_controls_root.visible = false
		return
		
	var cur = get_tree().current_scene
	var cur_path = cur.scene_file_path if cur else ""
	
	# Hide D-Pad during phone call conference or pure cutscenes
	if cur_path == "res://scenes/phone_call_convo.tscn" or cur_path == "res://scenes/cycle_ride.tscn":
		mobile_controls_root.visible = false
	else:
		var is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or DisplayServer.is_touchscreen_available()
		mobile_controls_root.visible = is_mobile or force_show_controls

func _input(event: InputEvent) -> void:
	if is_menu_open:
		# Always ensure mouse cursor is visible while checkpoint modal is active
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_TAB or event.keycode == KEY_C or event.keycode == KEY_ESCAPE:
				close_menu()
				get_viewport().set_input_as_handled()
				return
	else:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_TAB or event.keycode == KEY_C or event.keycode == KEY_F1:
				open_menu()
				get_viewport().set_input_as_handled()
				return

func build_hud() -> void:
	var hud_root = Control.new()
	hud_root.name = "HUD_Root"
	hud_root.anchors_preset = Control.PRESET_FULL_RECT
	hud_root.anchor_right = 1.0
	hud_root.anchor_bottom = 1.0
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)
	
	# Top Right HUD Action Bar
	hud_container = HBoxContainer.new()
	hud_container.anchors_preset = Control.PRESET_TOP_RIGHT
	hud_container.anchor_left = 1.0
	hud_container.anchor_right = 1.0
	hud_container.offset_left = -530
	hud_container.offset_top = 10
	hud_container.offset_right = -10
	hud_container.offset_bottom = 54
	hud_container.add_theme_constant_override("separation", 10)
	hud_root.add_child(hud_container)
	
	# 0. Mobile Controls Show/Hide toggle button
	controls_toggle_btn = Button.new()
	controls_toggle_btn.text = "🕹️ TOUCH: ON"
	controls_toggle_btn.tooltip_text = "टच कंट्रोल्स चालू / बंद करें (Toggle On-Screen Touch Controls)"
	controls_toggle_btn.custom_minimum_size = Vector2(130, 42)
	controls_toggle_btn.focus_mode = Control.FOCUS_NONE
	controls_toggle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var c_btn_style = StyleBoxFlat.new()
	c_btn_style.bg_color = Color(0.18, 0.22, 0.38, 0.92)
	c_btn_style.border_width_left = 2
	c_btn_style.border_width_top = 2
	c_btn_style.border_width_right = 2
	c_btn_style.border_width_bottom = 2
	c_btn_style.border_color = Color(0.4, 0.7, 1.0, 0.9)
	c_btn_style.corner_radius_top_left = 10
	c_btn_style.corner_radius_top_right = 10
	c_btn_style.corner_radius_bottom_right = 10
	c_btn_style.corner_radius_bottom_left = 10
	controls_toggle_btn.add_theme_stylebox_override("normal", c_btn_style)
	controls_toggle_btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	controls_toggle_btn.add_theme_font_size_override("font_size", 12)
	controls_toggle_btn.pressed.connect(func():
		force_show_controls = not force_show_controls
		controls_toggle_btn.text = "🕹️ TOUCH: ON" if force_show_controls else "🕹️ TOUCH: OFF"
		_ensure_controls_visibility()
	)
	hud_container.add_child(controls_toggle_btn)
	
	# 1. Quick Next Scene button
	quick_next_btn = Button.new()
	quick_next_btn.text = "⏩ NEXT SCENE"
	quick_next_btn.tooltip_text = "सीधे अगले सीन पर स्किप करें (Fast Skip to Next Chapter)"
	quick_next_btn.custom_minimum_size = Vector2(130, 42)
	quick_next_btn.focus_mode = Control.FOCUS_NONE
	quick_next_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var q_style = StyleBoxFlat.new()
	q_style.bg_color = Color(0.12, 0.28, 0.22, 0.92)
	q_style.border_width_left = 2
	q_style.border_width_top = 2
	q_style.border_width_right = 2
	q_style.border_width_bottom = 2
	q_style.border_color = Color(0.3, 0.9, 0.5, 0.9)
	q_style.corner_radius_top_left = 10
	q_style.corner_radius_top_right = 10
	q_style.corner_radius_bottom_right = 10
	q_style.corner_radius_bottom_left = 10
	quick_next_btn.add_theme_stylebox_override("normal", q_style)
	
	var q_hover = q_style.duplicate()
	q_hover.bg_color = Color(0.18, 0.45, 0.32, 1.0)
	q_hover.border_color = Color(0.5, 1.0, 0.7, 1.0)
	quick_next_btn.add_theme_stylebox_override("hover", q_hover)
	quick_next_btn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
	quick_next_btn.add_theme_font_size_override("font_size", 13)
	quick_next_btn.pressed.connect(jump_to_next_scene)
	hud_container.add_child(quick_next_btn)
	
	# 2. Checkpoints Menu button
	toggle_btn = Button.new()
	toggle_btn.text = "⚡ CHECKPOINTS [TAB]"
	toggle_btn.tooltip_text = "सारे चैप्टर्स की लिस्ट खोलें (Open All Story Checkpoints)"
	toggle_btn.custom_minimum_size = Vector2(210, 42)
	toggle_btn.focus_mode = Control.FOCUS_NONE
	toggle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color(0.10, 0.14, 0.24, 0.92)
	t_style.border_width_left = 2
	t_style.border_width_top = 2
	t_style.border_width_right = 2
	t_style.border_width_bottom = 2
	t_style.border_color = Color(1.0, 0.82, 0.3, 0.9)
	t_style.corner_radius_top_left = 10
	t_style.corner_radius_top_right = 10
	t_style.corner_radius_bottom_right = 10
	t_style.corner_radius_bottom_left = 10
	toggle_btn.add_theme_stylebox_override("normal", t_style)
	
	var t_hover = t_style.duplicate()
	t_hover.bg_color = Color(0.22, 0.32, 0.52, 1.0)
	t_hover.border_color = Color(1.0, 0.95, 0.5, 1.0)
	toggle_btn.add_theme_stylebox_override("hover", t_hover)
	toggle_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	toggle_btn.add_theme_font_size_override("font_size", 12)
	toggle_btn.pressed.connect(toggle_menu)
	hud_container.add_child(toggle_btn)

func build_modal() -> void:
	modal_overlay = ColorRect.new()
	modal_overlay.name = "ModalOverlay"
	modal_overlay.anchors_preset = Control.PRESET_FULL_RECT
	modal_overlay.anchor_right = 1.0
	modal_overlay.anchor_bottom = 1.0
	modal_overlay.color = Color(0, 0, 0, 0.75)
	modal_overlay.visible = false
	modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_overlay.mouse_default_cursor_shape = Control.CURSOR_ARROW
	add_child(modal_overlay)
	
	# Modal Center Card
	modal_panel = PanelContainer.new()
	modal_panel.anchors_preset = Control.PRESET_CENTER
	modal_panel.anchor_left = 0.5
	modal_panel.anchor_top = 0.5
	modal_panel.anchor_right = 0.5
	modal_panel.anchor_bottom = 0.5
	modal_panel.offset_left = -340
	modal_panel.offset_top = -280
	modal_panel.offset_right = 340
	modal_panel.offset_bottom = 280
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.07, 0.09, 0.14, 0.98)
	p_style.border_width_left = 3
	p_style.border_width_top = 3
	p_style.border_width_right = 3
	p_style.border_width_bottom = 3
	p_style.border_color = Color(1.0, 0.8, 0.25, 0.95)
	p_style.corner_radius_top_left = 14
	p_style.corner_radius_top_right = 14
	p_style.corner_radius_bottom_right = 14
	p_style.corner_radius_bottom_left = 14
	p_style.shadow_size = 28
	p_style.shadow_color = Color(0, 0, 0, 0.9)
	modal_panel.add_theme_stylebox_override("panel", p_style)
	modal_overlay.add_child(modal_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	modal_panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)
	
	# Header
	var title = Label.new()
	title.text = "⚡ STORY CHECKPOINTS & FAST-TRAVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_font_size_override("font_size", 20)
	main_vbox.add_child(title)
	
	var sub_title = Label.new()
	sub_title.text = "किसी भी सीन को तुरंत टेस्ट करने या नए अपडेट देखने के लिए चुनें:"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	sub_title.add_theme_font_size_override("font_size", 13)
	main_vbox.add_child(sub_title)
	
	main_vbox.add_child(HSeparator.new())
	
	# Scrollable List of Checkpoint Cards
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)
	
	cards_vbox = VBoxContainer.new()
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(cards_vbox)
	
	populate_cards()
	
	main_vbox.add_child(HSeparator.new())
	
	# Bottom Controls: Restart Scene & Close
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(bottom_hbox)
	
	var reload_btn = Button.new()
	reload_btn.text = "🔄 RESTART CURRENT SCENE"
	reload_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reload_btn.custom_minimum_size = Vector2(0, 36)
	reload_btn.focus_mode = Control.FOCUS_NONE
	reload_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var r_style = StyleBoxFlat.new()
	r_style.bg_color = Color(0.18, 0.22, 0.32, 0.9)
	r_style.corner_radius_top_left = 6
	r_style.corner_radius_top_right = 6
	r_style.corner_radius_bottom_right = 6
	r_style.corner_radius_bottom_left = 6
	reload_btn.add_theme_stylebox_override("normal", r_style)
	reload_btn.pressed.connect(func():
		close_menu()
		get_tree().reload_current_scene()
	)
	bottom_hbox.add_child(reload_btn)
	
	var close_btn = Button.new()
	close_btn.text = "✖ RESUME GAME [ESC]"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.custom_minimum_size = Vector2(0, 36)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.45, 0.14, 0.14, 0.9)
	c_style.corner_radius_top_left = 6
	c_style.corner_radius_top_right = 6
	c_style.corner_radius_bottom_right = 6
	c_style.corner_radius_bottom_left = 6
	close_btn.add_theme_stylebox_override("normal", c_style)
	close_btn.pressed.connect(close_menu)
	bottom_hbox.add_child(close_btn)

func populate_cards() -> void:
	for child in cards_vbox.get_children():
		child.queue_free()
		
	var current_scene_path: String = ""
	var cur = get_tree().current_scene
	if cur:
		current_scene_path = cur.scene_file_path
		
	for ch in CHAPTERS:
		var is_current = (ch["scene"] == current_scene_path)
		
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.14, 0.18, 0.26, 0.95) if not is_current else Color(0.18, 0.32, 0.45, 0.98)
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.border_color = Color(0.3, 0.8, 1.0, 0.9) if is_current else Color(0.2, 0.35, 0.5, 0.5)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_right = 8
		card_style.corner_radius_bottom_left = 8
		card.add_theme_stylebox_override("panel", card_style)
		
		var card_margin = MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 12)
		card_margin.add_theme_constant_override("margin_top", 8)
		card_margin.add_theme_constant_override("margin_right", 12)
		card_margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(card_margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		card_margin.add_child(hbox)
		
		# Icon & Number
		var num_lbl = Label.new()
		num_lbl.text = "%s %s." % [ch["icon"], ch["num"]]
		num_lbl.add_theme_font_size_override("font_size", 20)
		num_lbl.custom_minimum_size = Vector2(48, 0)
		hbox.add_child(num_lbl)
		
		# Text Details
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(text_vbox)
		
		var title_lbl = Label.new()
		title_lbl.text = ch["title"] + (" [CURRENT SCENE]" if is_current else "")
		title_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6) if is_current else Color(1.0, 0.9, 0.5))
		title_lbl.add_theme_font_size_override("font_size", 14)
		text_vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = ch["sub"]
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.85))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		text_vbox.add_child(desc_lbl)
		
		# Jump Button
		var jump_btn = Button.new()
		jump_btn.text = "PLAY ➔" if not is_current else "RELOAD 🔄"
		jump_btn.custom_minimum_size = Vector2(100, 32)
		jump_btn.focus_mode = Control.FOCUS_NONE
		jump_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var j_style = StyleBoxFlat.new()
		j_style.bg_color = Color(0.18, 0.45, 0.3, 0.9) if is_current else Color(0.15, 0.35, 0.6, 0.9)
		j_style.corner_radius_top_left = 6
		j_style.corner_radius_top_right = 6
		j_style.corner_radius_bottom_right = 6
		j_style.corner_radius_bottom_left = 6
		jump_btn.add_theme_stylebox_override("normal", j_style)
		
		var scene_to_load = ch["scene"]
		jump_btn.pressed.connect(func(): jump_to_scene(scene_to_load))
		hbox.add_child(jump_btn)
		
		cards_vbox.add_child(card)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_C or event.keycode == KEY_F1:
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
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	
	if mobile_controls_root:
		mobile_controls_root.visible = false
	
	populate_cards()
	
	modal_overlay.visible = true
	modal_panel.modulate.a = 1.0

func close_menu() -> void:
	is_menu_open = false
	modal_overlay.visible = false
	get_tree().paused = false
	
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or DisplayServer.is_touchscreen_available()
	if mobile_controls_root:
		mobile_controls_root.visible = is_mobile
	
	# Only restore captured if not going into a UI cutscene
	var cur = get_tree().current_scene
	var current_path = cur.scene_file_path if cur else ""
	if current_path == "res://scenes/phone_call_convo.tscn":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif prev_mouse_mode == Input.MOUSE_MODE_CAPTURED and not is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func jump_to_scene(scene_path: String) -> void:
	get_tree().paused = false
	is_menu_open = false
	modal_overlay.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if not ResourceLoader.exists(scene_path):
		print("ERROR: Scene file not found: ", scene_path)
		return
		
	print("Checkpoint jump to: ", scene_path)
	_ensure_controls_visibility()
	
	# Try loading freshly bypassing cache
	var ps = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if ps:
		var packed_err = get_tree().change_scene_to_packed(ps)
		if packed_err == OK:
			_ensure_controls_visibility()
			return
			
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		print("change_scene_to_file returned error %d" % err)
	_ensure_controls_visibility()

func jump_to_next_scene() -> void:
	get_tree().paused = false
	var cur = get_tree().current_scene
	var current_path = cur.scene_file_path if cur else ""
	
	var next_index: int = 0
	for i in range(CHAPTERS.size()):
		if CHAPTERS[i]["scene"] == current_path:
			next_index = (i + 1) % CHAPTERS.size()
			break
			
	var target = CHAPTERS[next_index]["scene"]
	print("Quick skipping to next scene: ", target)
	jump_to_scene(target)

var mobile_controls_root: Control

func build_mobile_controls() -> void:
	mobile_controls_root = Control.new()
	mobile_controls_root.name = "MobileControls"
	mobile_controls_root.anchors_preset = Control.PRESET_FULL_RECT
	mobile_controls_root.anchor_right = 1.0
	mobile_controls_root.anchor_bottom = 1.0
	mobile_controls_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mobile_controls_root)

	# Helper to create styled multi-touch button
	var make_touch_btn = func(text: String, size: Vector2, pos: Vector2, color_bg: Color, color_border: Color, font_size: int, on_press: Callable, on_release: Callable) -> Button:
		var btn = Button.new()
		btn.text = text
		btn.custom_minimum_size = size
		btn.size = size
		btn.position = pos
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var style = StyleBoxFlat.new()
		style.bg_color = color_bg
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = color_border
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_right = 16
		style.corner_radius_bottom_left = 16
		style.shadow_size = 6
		style.shadow_color = Color(0, 0, 0, 0.6)
		btn.add_theme_stylebox_override("normal", style)
		
		var pressed_style = style.duplicate()
		pressed_style.bg_color = Color(min(1.0, color_bg.r * 1.8 + 0.1), min(1.0, color_bg.g * 1.8 + 0.1), min(1.0, color_bg.b * 1.8 + 0.1), 0.95)
		pressed_style.border_color = Color(1, 1, 1, 0.98)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
		btn.add_theme_font_size_override("font_size", font_size)

		var state = {"is_down": false, "touch_id": -1}
		var do_press = func():
			if not state["is_down"]:
				state["is_down"] = true
				btn.add_theme_stylebox_override("normal", pressed_style)
				on_press.call()
		var do_release = func():
			if state["is_down"]:
				state["is_down"] = false
				state["touch_id"] = -1
				btn.add_theme_stylebox_override("normal", style)
				on_release.call()

		btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch:
				if ev.pressed:
					state["touch_id"] = ev.index
					do_press.call()
				else:
					if ev.index == state["touch_id"] or state["touch_id"] == -1:
						do_release.call()
			elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					do_press.call()
				else:
					do_release.call()
		)
		btn.button_down.connect(do_press)
		btn.button_up.connect(do_release)
		btn.mouse_exited.connect(do_release)
		return btn

	# Helper to dispatch key event
	var send_key = func(keycode: Key, pressed: bool):
		var ev = InputEventKey.new()
		ev.keycode = keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)

	# --- Bottom-Left: Movement D-Pad (Medium 76x76 Buttons) ---
	var dpad = Control.new()
	dpad.name = "DPad"
	dpad.anchors_preset = Control.PRESET_BOTTOM_LEFT
	dpad.anchor_top = 1.0
	dpad.anchor_bottom = 1.0
	dpad.offset_left = 28
	dpad.offset_top = -285
	dpad.offset_right = 285
	dpad.offset_bottom = -28
	dpad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls_root.add_child(dpad)

	var bg_col = Color(0.10, 0.14, 0.22, 0.75)
	var border_col = Color(0.35, 0.75, 1.0, 0.85)

	# FWD Button
	var btn_up = make_touch_btn.call(
		"▲\nFWD", Vector2(76, 76), Vector2(85, 0), bg_col, border_col, 16,
		func():
			Input.action_press("move_forward")
			Input.action_press("ui_up")
			send_key.call(KEY_W, true)
			send_key.call(KEY_UP, true),
		func():
			Input.action_release("move_forward")
			Input.action_release("ui_up")
			send_key.call(KEY_W, false)
			send_key.call(KEY_UP, false)
	)
	dpad.add_child(btn_up)

	# BACK Button
	var btn_down = make_touch_btn.call(
		"▼\nBACK", Vector2(76, 76), Vector2(85, 170), bg_col, border_col, 16,
		func():
			Input.action_press("move_backward")
			Input.action_press("ui_down")
			send_key.call(KEY_S, true)
			send_key.call(KEY_DOWN, true),
		func():
			Input.action_release("move_backward")
			Input.action_release("ui_down")
			send_key.call(KEY_S, false)
			send_key.call(KEY_DOWN, false)
	)
	dpad.add_child(btn_down)

	# LEFT Button
	var btn_left = make_touch_btn.call(
		"◀\nLEFT", Vector2(76, 76), Vector2(0, 85), bg_col, border_col, 16,
		func():
			Input.action_press("move_left")
			Input.action_press("ui_left")
			send_key.call(KEY_A, true)
			send_key.call(KEY_LEFT, true),
		func():
			Input.action_release("move_left")
			Input.action_release("ui_left")
			send_key.call(KEY_A, false)
			send_key.call(KEY_LEFT, false)
	)
	dpad.add_child(btn_left)

	# RIGHT Button
	var btn_right = make_touch_btn.call(
		"▶\nRIGHT", Vector2(76, 76), Vector2(170, 85), bg_col, border_col, 16,
		func():
			Input.action_press("move_right")
			Input.action_press("ui_right")
			send_key.call(KEY_D, true)
			send_key.call(KEY_RIGHT, true),
		func():
			Input.action_release("move_right")
			Input.action_release("ui_right")
			send_key.call(KEY_D, false)
			send_key.call(KEY_RIGHT, false)
	)
	dpad.add_child(btn_right)

	# Center Badge
	var center_lbl = Label.new()
	center_lbl.text = "🕹️\nMOVE"
	center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_lbl.position = Vector2(85, 85)
	center_lbl.size = Vector2(76, 76)
	center_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_lbl.add_theme_font_size_override("font_size", 12)
	center_lbl.add_theme_color_override("font_color", Color(0.65, 0.8, 1.0, 0.7))
	dpad.add_child(center_lbl)

	# --- Bottom-Right: Action, Flashlight, Sprint & Camera View Buttons ---
	var actions = Control.new()
	actions.name = "Actions"
	actions.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	actions.anchor_left = 1.0
	actions.anchor_right = 1.0
	actions.anchor_top = 1.0
	actions.anchor_bottom = 1.0
	actions.offset_left = -340
	actions.offset_top = -270
	actions.offset_right = -20
	actions.offset_bottom = -20
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_controls_root.add_child(actions)

	# [E] Interact Action Button (Medium 110x92)
	var btn_action = make_touch_btn.call(
		"⚡ [E]\nACTION", Vector2(110, 92), Vector2(180, 130),
		Color(0.12, 0.45, 0.25, 0.85), Color(0.3, 1.0, 0.6, 0.95), 17,
		func():
			Input.action_press("interact")
			send_key.call(KEY_E, true)
			send_key.call(KEY_SPACE, true)
			send_key.call(KEY_ENTER, true)
			send_key.call(KEY_BACKSPACE, true),
		func():
			Input.action_release("interact")
			send_key.call(KEY_E, false)
			send_key.call(KEY_SPACE, false)
			send_key.call(KEY_ENTER, false)
			send_key.call(KEY_BACKSPACE, false)
	)
	actions.add_child(btn_action)

	# [F] Flashlight Button (Medium 92x80)
	var btn_light = make_touch_btn.call(
		"🔦 [F]\nLIGHT", Vector2(92, 80), Vector2(65, 142),
		Color(0.48, 0.36, 0.1, 0.85), Color(1.0, 0.85, 0.3, 0.95), 15,
		func():
			Input.action_press("flashlight")
			send_key.call(KEY_F, true),
		func():
			Input.action_release("flashlight")
			send_key.call(KEY_F, false)
	)
	actions.add_child(btn_light)

	# [RUN] Sprint Button (Medium 110x68)
	var btn_sprint = make_touch_btn.call(
		"🏃 SPRINT\n[RUN]", Vector2(110, 68), Vector2(180, 48),
		Color(0.14, 0.28, 0.52, 0.85), Color(0.4, 0.75, 1.0, 0.95), 15,
		func():
			Input.action_press("sprint")
			send_key.call(KEY_SHIFT, true),
		func():
			Input.action_release("sprint")
			send_key.call(KEY_SHIFT, false)
	)
	actions.add_child(btn_sprint)

	# [V] Camera View Toggle Button (Medium 92x64)
	var btn_cam = make_touch_btn.call(
		"👁️ [V]\nVIEW", Vector2(92, 64), Vector2(65, 64),
		Color(0.24, 0.16, 0.42, 0.85), Color(0.7, 0.5, 1.0, 0.95), 14,
		func():
			send_key.call(KEY_V, true),
		func():
			send_key.call(KEY_V, false)
	)
	actions.add_child(btn_cam)
