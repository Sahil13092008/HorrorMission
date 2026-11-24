extends Node3D

# --- CINEMATIC OPENING PROLOGUE SCRIPT ---
# Directed movie-style introduction:
# Act 1: Night crossroads after playing in garden, friends parting ways
# Act 2: Kripal takes the forest path, encounters eerie glowing light, sprints home in panic
# Act 3: Next morning, Protagonist's house, Mom calling from hall, rushing to school van
# Act 4: Inside school van looking out window heading to Kripal's house

var current_beat: int = -1
var is_beat_active: bool = false
var beat_timer: float = 0.0
var auto_advance_time: float = 5.0
var skipped: bool = false

# UI References
var ui_root: CanvasLayer
var letterbox_top: ColorRect
var letterbox_bottom: ColorRect
var speaker_tag: Label
var subtitle_text: Label
var subtitle_sub: Label
var title_card_box: CenterContainer
var title_card_title: Label
var title_card_sub: Label
var skip_btn: Button
var continue_btn: Button
var fade_overlay: ColorRect
var tap_advance_panel: Control

# 3D Node References
var cam: Camera3D
var cam_pivot: Node3D
var sun_light: DirectionalLight3D
var moon_light: DirectionalLight3D
var world_env: WorldEnvironment

# Sets
var set_crossroads: Node3D
var set_forest: Node3D
var set_kripal_house: Node3D
var set_protagonist_house: Node3D
var set_van_exterior: Node3D
var set_van_interior: Node3D

# Characters
var char_sahil: Node3D
var char_aashu: Node3D
var char_kripal: Node3D
var char_player_night: Node3D
var char_player_morning: Node3D
var char_van_driver: Node3D

# Props & Lights
var forest_anomaly_light: OmniLight3D
var forest_anomaly_mesh: MeshInstance3D
var van_exterior_node: Node3D
var protagonist_bed: Node3D
var protagonist_door: Node3D
var moving_scenery_node: Node3D

# Audio Streams
var audio_ambience_night: AudioStreamPlayer
var audio_ambience_morning: AudioStreamPlayer
var audio_whisper: AudioStreamPlayer
var audio_heartbeat: AudioStreamPlayer
var audio_jumpscare: AudioStreamPlayer
var audio_door_open: AudioStreamPlayer
var audio_door_close: AudioStreamPlayer
var audio_van_horn: AudioStreamPlayer
var audio_van_engine: AudioStreamPlayer
var audio_bgm: AudioStreamPlayer

func _ready() -> void:
	_build_ui()
	_setup_environment()
	_setup_audio()
	_build_3d_scenes()
	
	# Start prologue from Beat 0 with a smooth fade in
	_start_prologue()

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.15, 0.22)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.06, 0.1)
	env.fog_density = 0.015
	world_env.environment = env
	add_child(world_env)
	
	# Moon light for night acts
	moon_light = DirectionalLight3D.new()
	moon_light.name = "MoonLight"
	moon_light.light_color = Color(0.45, 0.55, 0.8)
	moon_light.light_energy = 0.4
	moon_light.rotation_degrees = Vector3(-45, 45, 0)
	moon_light.shadow_enabled = true
	add_child(moon_light)
	
	# Sun light for morning acts (starts invisible)
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.light_color = Color(1.0, 0.92, 0.75)
	sun_light.light_energy = 1.3
	sun_light.rotation_degrees = Vector3(-35, -50, 0)
	sun_light.shadow_enabled = true
	sun_light.visible = false
	add_child(sun_light)
	
	# Camera & Pivot
	cam_pivot = Node3D.new()
	cam_pivot.name = "CameraPivot"
	add_child(cam_pivot)
	
	cam = Camera3D.new()
	cam.name = "CinematicCamera"
	cam.current = true
	cam.fov = 65.0
	cam_pivot.add_child(cam)

func _setup_audio() -> void:
	var audio_root = Node.new()
	audio_root.name = "AudioRoot"
	add_child(audio_root)
	
	audio_ambience_night = AudioStreamPlayer.new()
	audio_ambience_night.stream = _load_audio("res://audio/ambience.wav")
	audio_ambience_night.volume_db = -6.0
	audio_root.add_child(audio_ambience_night)
	
	audio_ambience_morning = AudioStreamPlayer.new()
	audio_ambience_morning.stream = _load_audio("res://audio/morning_birds.wav")
	audio_ambience_morning.volume_db = -4.0
	audio_root.add_child(audio_ambience_morning)
	
	audio_whisper = AudioStreamPlayer.new()
	audio_whisper.stream = _load_audio("res://audio/demon_whisper.wav")
	audio_whisper.volume_db = -2.0
	audio_root.add_child(audio_whisper)
	
	audio_heartbeat = AudioStreamPlayer.new()
	audio_heartbeat.stream = _load_audio("res://audio/heartbeat.wav")
	audio_heartbeat.volume_db = 0.0
	audio_root.add_child(audio_heartbeat)
	
	audio_jumpscare = AudioStreamPlayer.new()
	audio_jumpscare.stream = _load_audio("res://audio/jumpscare.wav")
	audio_jumpscare.volume_db = 2.0
	audio_root.add_child(audio_jumpscare)
	
	audio_door_open = AudioStreamPlayer.new()
	audio_door_open.stream = _load_audio("res://audio/home_door_open.wav")
	audio_root.add_child(audio_door_open)
	
	audio_door_close = AudioStreamPlayer.new()
	audio_door_close.stream = _load_audio("res://audio/car_door_close.wav")
	audio_root.add_child(audio_door_close)
	
	audio_van_horn = AudioStreamPlayer.new()
	audio_van_horn.stream = _load_audio("res://audio/van_horn.wav")
	audio_van_horn.volume_db = 3.0
	audio_root.add_child(audio_van_horn)
	
	audio_van_engine = AudioStreamPlayer.new()
	audio_van_engine.stream = _load_audio("res://audio/car_engine_loop.wav")
	audio_van_engine.volume_db = -8.0
	audio_root.add_child(audio_van_engine)
	
	# BGM Player
	audio_bgm = AudioStreamPlayer.new()
	audio_bgm.volume_db = -6.0
	# Check if custom prologue BGM exists, or fallback to chapter_boom/ambience
	var custom_bgm = _load_audio("res://audio/prologue_bgm.mp3")
	if not custom_bgm:
		custom_bgm = _load_audio("res://audio/bhangarh_ambience.wav")
	audio_bgm.stream = custom_bgm
	audio_root.add_child(audio_bgm)

func _load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null

func _build_ui() -> void:
	ui_root = CanvasLayer.new()
	ui_root.layer = 10
	add_child(ui_root)
	
	# Transparent tap panel covering screen to tap-advance dialogue
	tap_advance_panel = Control.new()
	tap_advance_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap_advance_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_root.add_child(tap_advance_panel)
	tap_advance_panel.gui_input.connect(_on_screen_tapped)
	
	# Cinematic Letterbox Bars
	letterbox_top = ColorRect.new()
	letterbox_top.color = Color(0, 0, 0, 1)
	letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	letterbox_top.custom_minimum_size = Vector2(0, 75)
	letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(letterbox_top)
	
	letterbox_bottom = ColorRect.new()
	letterbox_bottom.color = Color(0, 0, 0, 0.95)
	letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	letterbox_bottom.offset_top = -140
	letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(letterbox_bottom)
	
	# Subtitle Margin Container inside bottom letterbox
	var sub_margin = MarginContainer.new()
	sub_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_margin.add_theme_constant_override("margin_left", 30)
	sub_margin.add_theme_constant_override("margin_right", 30)
	sub_margin.add_theme_constant_override("margin_top", 10)
	sub_margin.add_theme_constant_override("margin_bottom", 10)
	sub_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letterbox_bottom.add_child(sub_margin)
	
	var sub_vbox = VBoxContainer.new()
	sub_vbox.add_theme_constant_override("separation", 4)
	sub_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_margin.add_child(sub_vbox)
	
	speaker_tag = Label.new()
	speaker_tag.text = "PROLOGUE"
	speaker_tag.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	speaker_tag.add_theme_font_size_override("font_size", 16)
	sub_vbox.add_child(speaker_tag)
	
	subtitle_text = Label.new()
	subtitle_text.text = "Loading cutscene..."
	subtitle_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	subtitle_text.add_theme_font_size_override("font_size", 17)
	sub_vbox.add_child(subtitle_text)
	
	subtitle_sub = Label.new()
	subtitle_sub.text = ""
	subtitle_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	subtitle_sub.add_theme_font_size_override("font_size", 13)
	sub_vbox.add_child(subtitle_sub)
	
	# Title Card Box (Centered)
	title_card_box = CenterContainer.new()
	title_card_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card_box.modulate = Color(1, 1, 1, 0)
	ui_root.add_child(title_card_box)
	
	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 10)
	title_card_box.add_child(title_vbox)
	
	title_card_title = Label.new()
	title_card_title.text = "रात 8:30 PM — 3-राहा"
	title_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_card_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title_card_title.add_theme_font_size_override("font_size", 28)
	title_vbox.add_child(title_card_title)
	
	title_card_sub = Label.new()
	title_card_sub.text = "THE 3-WAY CROSSROADS"
	title_card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_card_sub.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	title_card_sub.add_theme_font_size_override("font_size", 16)
	title_vbox.add_child(title_card_sub)
	
	# Skip Button (Top Right)
	skip_btn = Button.new()
	skip_btn.text = "SKIP ⏭️"
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -110
	skip_btn.offset_top = 15
	skip_btn.offset_right = -20
	skip_btn.offset_bottom = 55
	skip_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	skip_btn.add_theme_font_size_override("font_size", 14)
	skip_btn.pressed.connect(_on_skip_pressed)
	ui_root.add_child(skip_btn)
	
	# Continue Button (Final card)
	continue_btn = Button.new()
	continue_btn.text = "▶ START CHAPTER 1 / आगे बढ़ें"
	continue_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_btn.offset_left = -280
	continue_btn.offset_top = -125
	continue_btn.offset_right = -25
	continue_btn.offset_bottom = -75
	continue_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	continue_btn.add_theme_font_size_override("font_size", 16)
	continue_btn.visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	ui_root.add_child(continue_btn)
	
	# Fade Overlay (Black Screen for scene transitions)
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade_overlay)

# --- 3D ENVIRONMENT CREATION ---
func _build_3d_scenes() -> void:
	_build_set_crossroads()
	_build_set_forest()
	_build_set_kripal_house()
	_build_set_protagonist_house()
	_build_set_van_scene()

func _create_material(color: Color, roughness: float = 0.8, metallic: float = 0.0, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

# --- ACT 1: CROSSROADS (तीराहा) ---
func _build_set_crossroads() -> void:
	set_crossroads = Node3D.new()
	set_crossroads.name = "Set_Crossroads"
	set_crossroads.position = Vector3(0, 0, 0)
	add_child(set_crossroads)
	
	var mat_road = _create_material(Color(0.12, 0.12, 0.14), 0.9)
	var mat_ground = _create_material(Color(0.06, 0.08, 0.05), 0.95)
	var mat_line = _create_material(Color(0.9, 0.8, 0.2), 0.5)
	var mat_pole = _create_material(Color(0.2, 0.2, 0.22), 0.5, 0.7)
	var mat_lamp_glow = _create_material(Color(1.0, 0.9, 0.6), 0.2, 0.0, Color(1.0, 0.85, 0.4), 3.0)
	
	# Grass Ground
	var ground = CSGBox3D.new()
	ground.size = Vector3(80, 0.2, 80)
	ground.position = Vector3(0, -0.1, 0)
	ground.material = mat_ground
	set_crossroads.add_child(ground)
	
	# 3-Way Roads meeting at junction
	# Road 1: North (Forest road)
	var road_n = CSGBox3D.new()
	road_n.size = Vector3(5.5, 0.05, 30)
	road_n.position = Vector3(0, 0.02, -15)
	road_n.material = mat_road
	set_crossroads.add_child(road_n)
	
	# Road 2: West (Sahil & Aashu road)
	var road_w = CSGBox3D.new()
	road_w.size = Vector3(30, 0.05, 5.5)
	road_w.position = Vector3(-15, 0.02, 0)
	road_w.material = mat_road
	set_crossroads.add_child(road_w)
	
	# Road 3: East (Protagonist road)
	var road_e = CSGBox3D.new()
	road_e.size = Vector3(30, 0.05, 5.5)
	road_e.position = Vector3(15, 0.02, 0)
	road_e.material = mat_road
	set_crossroads.add_child(road_e)
	
	# Center junction pad
	var junction = CSGBox3D.new()
	junction.size = Vector3(9, 0.05, 9)
	junction.position = Vector3(0, 0.02, 0)
	junction.material = mat_road
	set_crossroads.add_child(junction)
	
	# Streetlight at junction center
	var pole = CSGCylinder3D.new()
	pole.radius = 0.08
	pole.height = 5.0
	pole.position = Vector3(3.5, 2.5, 3.5)
	pole.material = mat_pole
	set_crossroads.add_child(pole)
	
	var lamp = CSGSphere3D.new()
	lamp.radius = 0.35
	lamp.position = Vector3(3.5, 5.0, 3.5)
	lamp.material = mat_lamp_glow
	set_crossroads.add_child(lamp)
	
	var street_light = OmniLight3D.new()
	street_light.position = Vector3(3.5, 4.8, 3.5)
	street_light.omni_range = 14.0
	street_light.light_energy = 2.2
	street_light.light_color = Color(1.0, 0.85, 0.5)
	street_light.shadow_enabled = true
	set_crossroads.add_child(street_light)
	
	# Garden gate in background (South)
	_build_fence_and_gate(set_crossroads, Vector3(0, 0, 7.0))
	
	# Scatter roadside trees
	_spawn_trees(set_crossroads, [
		Vector3(-5, 0, -8), Vector3(5, 0, -8),
		Vector3(-8, 0, -16), Vector3(8, 0, -16),
		Vector3(-10, 0, 5), Vector3(10, 0, 5)
	])
	
	# Create 4 friends figures
	char_sahil = _create_stylized_character("Sahil", Color(0.2, 0.6, 0.3), Color(0.15, 0.15, 0.2))
	char_sahil.position = Vector3(-1.2, 0.0, 0.8)
	char_sahil.rotation_degrees = Vector3(0, 45, 0)
	set_crossroads.add_child(char_sahil)
	
	char_aashu = _create_stylized_character("Aashutosh", Color(0.65, 0.4, 0.2), Color(0.2, 0.2, 0.25))
	char_aashu.position = Vector3(-0.6, 0.0, -0.6)
	char_aashu.rotation_degrees = Vector3(0, 110, 0)
	set_crossroads.add_child(char_aashu)
	
	char_kripal = _create_stylized_character("Kripal", Color(0.8, 0.25, 0.2), Color(0.18, 0.2, 0.3), true)
	char_kripal.position = Vector3(0.8, 0.0, -0.4)
	char_kripal.rotation_degrees = Vector3(0, -120, 0)
	set_crossroads.add_child(char_kripal)
	
	char_player_night = _create_stylized_character("Player", Color(0.2, 0.35, 0.7), Color(0.12, 0.12, 0.15))
	char_player_night.position = Vector3(0.5, 0.0, 1.2)
	char_player_night.rotation_degrees = Vector3(0, -30, 0)
	set_crossroads.add_child(char_player_night)

# --- ACT 2: FOREST PATH & ANOMALY ---
func _build_set_forest() -> void:
	set_forest = Node3D.new()
	set_forest.name = "Set_Forest"
	set_forest.position = Vector3(100, 0, 0) # Isolated offset
	add_child(set_forest)
	
	var mat_dirt = _create_material(Color(0.08, 0.07, 0.05), 0.95)
	
	# Forest dirt ground
	var forest_ground = CSGBox3D.new()
	forest_ground.size = Vector3(30, 0.2, 60)
	forest_ground.position = Vector3(0, -0.1, 0)
	forest_ground.material = mat_dirt
	set_forest.add_child(forest_ground)
	
	# Dense trees flanking the trail
	var tree_coords = []
	for z in range(-25, 25, 5):
		tree_coords.append(Vector3(-4.5 + randf_range(-1.0, 1.0), 0, z))
		tree_coords.append(Vector3(4.5 + randf_range(-1.0, 1.0), 0, z))
		tree_coords.append(Vector3(-8.0 + randf_range(-1.5, 1.5), 0, z))
		tree_coords.append(Vector3(8.0 + randf_range(-1.5, 1.5), 0, z))
	_spawn_trees(set_forest, tree_coords)
	
	# Glowing Mystic Anomaly (Floating pulsating orb between trees)
	var anomaly_pivot = Node3D.new()
	anomaly_pivot.position = Vector3(5.5, 2.2, -10.0)
	set_forest.add_child(anomaly_pivot)
	
	var mat_anomaly = _create_material(Color(0.3, 0.8, 1.0), 0.1, 0.0, Color(0.2, 0.7, 1.0), 5.0)
	forest_anomaly_mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.45
	sphere_mesh.height = 0.9
	forest_anomaly_mesh.mesh = sphere_mesh
	forest_anomaly_mesh.material_override = mat_anomaly
	anomaly_pivot.add_child(forest_anomaly_mesh)
	
	forest_anomaly_light = OmniLight3D.new()
	forest_anomaly_light.light_color = Color(0.3, 0.8, 1.0)
	forest_anomaly_light.light_energy = 3.5
	forest_anomaly_light.omni_range = 18.0
	forest_anomaly_light.shadow_enabled = true
	anomaly_pivot.add_child(forest_anomaly_light)

# --- ACT 2 PART B: KRIPAL'S HOUSE EXTERIOR (PANIC SPRINT) ---
func _build_set_kripal_house() -> void:
	set_kripal_house = Node3D.new()
	set_kripal_house.name = "Set_KripalHouse"
	set_kripal_house.position = Vector3(200, 0, 0)
	add_child(set_kripal_house)
	
	var mat_house_wall = _create_material(Color(0.85, 0.8, 0.72), 0.85)
	var mat_door = _create_material(Color(0.4, 0.22, 0.1), 0.7)
	var mat_roof = _create_material(Color(0.5, 0.2, 0.15), 0.8)
	
	# Ground
	var g = CSGBox3D.new()
	g.size = Vector3(40, 0.2, 40)
	g.position = Vector3(0, -0.1, 0)
	g.material = _create_material(Color(0.15, 0.15, 0.15))
	set_kripal_house.add_child(g)
	
	# House Structure
	var house = CSGBox3D.new()
	house.size = Vector3(12, 6.0, 10)
	house.position = Vector3(0, 3.0, -8.0)
	house.material = mat_house_wall
	set_kripal_house.add_child(house)
	
	# Front Porch
	var porch = CSGBox3D.new()
	porch.size = Vector3(5, 0.3, 3)
	porch.position = Vector3(0, 0.15, -2.5)
	porch.material = _create_material(Color(0.6, 0.6, 0.6))
	set_kripal_house.add_child(porch)
	
	# Front Door
	var door = CSGBox3D.new()
	door.size = Vector3(1.6, 2.6, 0.1)
	door.position = Vector3(0, 1.45, -3.0)
	door.material = mat_door
	set_kripal_house.add_child(door)
	
	# Porch Light
	var porch_light = OmniLight3D.new()
	porch_light.position = Vector3(0, 3.2, -2.6)
	porch_light.light_color = Color(1.0, 0.9, 0.6)
	porch_light.light_energy = 2.0
	porch_light.omni_range = 10.0
	set_kripal_house.add_child(porch_light)

# --- ACT 3: PROTAGONIST'S HOUSE (MORNING) ---
func _build_set_protagonist_house() -> void:
	set_protagonist_house = Node3D.new()
	set_protagonist_house.name = "Set_ProtagonistHouse"
	set_protagonist_house.position = Vector3(300, 0, 0)
	add_child(set_protagonist_house)
	
	var mat_wall = _create_material(Color(0.92, 0.9, 0.84), 0.9)
	var mat_floor_wood = _create_material(Color(0.48, 0.32, 0.18), 0.7)
	var mat_bedsheet = _create_material(Color(0.25, 0.45, 0.75), 0.9)
	var mat_pillow = _create_material(Color(0.95, 0.95, 0.95), 0.9)
	
	# Room floor
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(10, 0.2, 10)
	floor_mesh.position = Vector3(0, -0.1, 0)
	floor_mesh.material = mat_floor_wood
	set_protagonist_house.add_child(floor_mesh)
	
	# Walls
	var wall_back = CSGBox3D.new()
	wall_back.size = Vector3(10, 4.0, 0.3)
	wall_back.position = Vector3(0, 2.0, -5.0)
	wall_back.material = mat_wall
	set_protagonist_house.add_child(wall_back)
	
	var wall_left = CSGBox3D.new()
	wall_left.size = Vector3(0.3, 4.0, 10)
	wall_left.position = Vector3(-5.0, 2.0, 0)
	wall_left.material = mat_wall
	set_protagonist_house.add_child(wall_left)
	
	# Bedroom Window with bright morning sun streaming in
	var win_cut = CSGBox3D.new()
	win_cut.size = Vector3(2.4, 2.0, 0.5)
	win_cut.position = Vector3(0, 2.5, -5.0)
	win_cut.material = _create_material(Color(0.8, 0.95, 1.0, 0.4), 0.1, 0.0, Color(1.0, 0.95, 0.7), 2.0)
	set_protagonist_house.add_child(win_cut)
	
	# Protagonist Bed
	protagonist_bed = Node3D.new()
	protagonist_bed.position = Vector3(-2.5, 0.0, -2.5)
	set_protagonist_house.add_child(protagonist_bed)
	
	var bed_frame = CSGBox3D.new()
	bed_frame.size = Vector3(2.2, 0.5, 3.2)
	bed_frame.position = Vector3(0, 0.25, 0)
	bed_frame.material = _create_material(Color(0.3, 0.2, 0.1))
	protagonist_bed.add_child(bed_frame)
	
	var mattress = CSGBox3D.new()
	mattress.size = Vector3(2.0, 0.4, 3.0)
	mattress.position = Vector3(0, 0.6, 0)
	mattress.material = mat_bedsheet
	protagonist_bed.add_child(mattress)
	
	var pillow = CSGBox3D.new()
	pillow.size = Vector3(1.4, 0.2, 0.7)
	pillow.position = Vector3(0, 0.85, -1.0)
	pillow.material = mat_pillow
	protagonist_bed.add_child(pillow)
	
	# Study Desk with School Bag
	var desk = CSGBox3D.new()
	desk.size = Vector3(2.2, 1.1, 1.2)
	desk.position = Vector3(2.5, 0.55, -4.0)
	desk.material = _create_material(Color(0.35, 0.22, 0.12))
	set_protagonist_house.add_child(desk)
	
	var school_bag = CSGBox3D.new()
	school_bag.size = Vector3(0.5, 0.6, 0.3)
	school_bag.position = Vector3(2.5, 1.4, -4.0)
	school_bag.material = _create_material(Color(0.1, 0.4, 0.8)) # Blue bag
	set_protagonist_house.add_child(school_bag)
	
	# Wooden Stairs leading down to hall
	for i in range(5):
		var step = CSGBox3D.new()
		step.size = Vector3(2.0, 0.25, 0.5)
		step.position = Vector3(3.5, -0.15 - (i * 0.25), 1.0 + (i * 0.5))
		step.material = mat_floor_wood
		set_protagonist_house.add_child(step)
	
	# Front Door (at bottom of stairs / hallway)
	protagonist_door = CSGBox3D.new()
	protagonist_door.size = Vector3(1.6, 2.6, 0.1)
	protagonist_door.position = Vector3(3.5, -0.1, 4.8)
	protagonist_door.material = _create_material(Color(0.4, 0.2, 0.1))
	set_protagonist_house.add_child(protagonist_door)
	
	# Protagonist Character in Room
	char_player_morning = _create_stylized_character("PlayerMorning", Color(0.9, 0.9, 0.9), Color(0.15, 0.25, 0.5)) # School Uniform (White shirt, Blue trousers)
	char_player_morning.position = Vector3(-2.5, 0.5, -2.5)
	set_protagonist_house.add_child(char_player_morning)

# --- ACT 4: SCHOOL VAN & MORNING DRIVE ---
func _build_set_van_scene() -> void:
	# Exterior Van & Street outside house
	set_van_exterior = Node3D.new()
	set_van_exterior.name = "Set_VanExterior"
	set_van_exterior.position = Vector3(400, 0, 0)
	add_child(set_van_exterior)
	
	var mat_asphalt = _create_material(Color(0.2, 0.2, 0.22))
	var road = CSGBox3D.new()
	road.size = Vector3(16, 0.2, 40)
	road.position = Vector3(0, -0.1, 0)
	road.material = mat_asphalt
	set_van_exterior.add_child(road)
	
	# Yellow School Van
	van_exterior_node = _build_school_van()
	van_exterior_node.position = Vector3(2.5, 0.0, 0.0)
	set_van_exterior.add_child(van_exterior_node)
	
	# Van Interior (Cabin view looking out side window)
	set_van_interior = Node3D.new()
	set_van_interior.name = "Set_VanInterior"
	set_van_interior.position = Vector3(500, 0, 0)
	add_child(set_van_interior)
	
	var mat_van_int = _create_material(Color(0.2, 0.2, 0.22), 0.7)
	var mat_seat = _create_material(Color(0.5, 0.2, 0.15), 0.8) # Brown rexine seat
	
	# Cabin floor and roof
	var c_floor = CSGBox3D.new()
	c_floor.size = Vector3(3.0, 0.2, 4.0)
	c_floor.position = Vector3(0, -0.1, 0)
	c_floor.material = mat_van_int
	set_van_interior.add_child(c_floor)
	
	var c_seat = CSGBox3D.new()
	c_seat.size = Vector3(1.2, 0.5, 0.8)
	c_seat.position = Vector3(0.6, 0.3, 0)
	c_seat.material = mat_seat
	set_van_interior.add_child(c_seat)
	
	var c_seatback = CSGBox3D.new()
	c_seatback.size = Vector3(1.2, 0.9, 0.2)
	c_seatback.position = Vector3(0.6, 0.9, -0.35)
	c_seatback.material = mat_seat
	set_van_interior.add_child(c_seatback)
	
	# Window Frame on the left side
	var win_frame = CSGBox3D.new()
	win_frame.size = Vector3(0.1, 1.4, 2.2)
	win_frame.position = Vector3(-1.2, 1.1, 0)
	win_frame.material = mat_van_int
	set_van_interior.add_child(win_frame)
	
	# Moving Scenery outside window (Poles, trees, roadside houses that scroll)
	moving_scenery_node = Node3D.new()
	moving_scenery_node.position = Vector3(-6.0, 0, 0)
	set_van_interior.add_child(moving_scenery_node)
	
	for i in range(12):
		var tree = _create_simple_tree()
		tree.position = Vector3(0, 0, -30.0 + (i * 6.0))
		moving_scenery_node.add_child(tree)
		
		# Electric pole
		var p = CSGCylinder3D.new()
		p.radius = 0.08
		p.height = 6.0
		p.position = Vector3(1.0, 3.0, -28.0 + (i * 8.0))
		p.material = _create_material(Color(0.3, 0.3, 0.32), 0.5, 0.6)
		moving_scenery_node.add_child(p)

func _build_school_van() -> Node3D:
	var van = Node3D.new()
	var mat_yellow = _create_material(Color(0.98, 0.78, 0.05), 0.4) # Classic school bus yellow
	var mat_black = _create_material(Color(0.12, 0.12, 0.12), 0.7)
	var mat_glass = _create_material(Color(0.1, 0.2, 0.3, 0.6), 0.1, 0.0)
	var mat_headlight = _create_material(Color(1, 1, 0.8), 0.1, 0.0, Color(1, 1, 0.7), 2.5)
	
	# Body
	var body = CSGBox3D.new()
	body.size = Vector3(2.2, 1.8, 4.4)
	body.position = Vector3(0, 1.2, 0)
	body.material = mat_yellow
	van.add_child(body)
	
	# Black side stripe
	var stripe = CSGBox3D.new()
	stripe.size = Vector3(2.25, 0.25, 4.42)
	stripe.position = Vector3(0, 1.0, 0)
	stripe.material = mat_black
	van.add_child(stripe)
	
	# "SCHOOL BUS" Label
	var bus_label = Label3D.new()
	bus_label.text = "★ SCHOOL BUS ★"
	bus_label.font_size = 28
	bus_label.modulate = Color(0.05, 0.05, 0.05)
	bus_label.position = Vector3(1.15, 1.45, 0)
	bus_label.rotation_degrees = Vector3(0, 90, 0)
	van.add_child(bus_label)
	
	# Windshield & Windows
	var windshield = CSGBox3D.new()
	windshield.size = Vector3(1.9, 0.8, 0.1)
	windshield.position = Vector3(0, 1.5, -2.18)
	windshield.material = mat_glass
	van.add_child(windshield)
	
	# Headlights
	var hl_l = CSGSphere3D.new()
	hl_l.radius = 0.18
	hl_l.position = Vector3(-0.7, 0.8, -2.2)
	hl_l.material = mat_headlight
	van.add_child(hl_l)
	
	var hl_r = CSGSphere3D.new()
	hl_r.radius = 0.18
	hl_r.position = Vector3(0.7, 0.8, -2.2)
	hl_r.material = mat_headlight
	van.add_child(hl_r)
	
	# Wheels (4 wheels)
	var wheel_pos = [
		Vector3(-1.1, 0.45, -1.3), Vector3(1.1, 0.45, -1.3),
		Vector3(-1.1, 0.45, 1.3), Vector3(1.1, 0.45, 1.3)
	]
	for wp in wheel_pos:
		var w = CSGCylinder3D.new()
		w.radius = 0.45
		w.height = 0.3
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = wp
		w.material = mat_black
		van.add_child(w)
	
	return van

func _build_fence_and_gate(parent: Node3D, pos: Vector3) -> void:
	var fence = CSGBox3D.new()
	fence.size = Vector3(18, 1.8, 0.15)
	fence.position = pos
	fence.material = _create_material(Color(0.2, 0.25, 0.2))
	parent.add_child(fence)

func _spawn_trees(parent: Node3D, positions: Array) -> void:
	for p in positions:
		var t = _create_simple_tree()
		t.position = p
		parent.add_child(t)

func _create_simple_tree() -> Node3D:
	var tree = Node3D.new()
	var mat_trunk = _create_material(Color(0.25, 0.16, 0.1))
	var mat_leaves = _create_material(Color(0.12, 0.28, 0.14))
	
	var trunk = CSGCylinder3D.new()
	trunk.radius = 0.22
	trunk.height = 3.5
	trunk.position = Vector3(0, 1.75, 0)
	trunk.material = mat_trunk
	tree.add_child(trunk)
	
	var foliage = CSGSphere3D.new()
	foliage.radius = 1.6
	foliage.position = Vector3(0, 4.0, 0)
	foliage.material = mat_leaves
	tree.add_child(foliage)
	
	return tree

func _create_stylized_character(c_name: String, shirt_color: Color, pant_color: Color, has_glasses: bool = false) -> Node3D:
	var char_root = Node3D.new()
	char_root.name = c_name
	
	var mat_skin = _create_material(Color(0.85, 0.68, 0.52))
	var mat_hair = _create_material(Color(0.1, 0.08, 0.06))
	var mat_shirt = _create_material(shirt_color)
	var mat_pant = _create_material(pant_color)
	var mat_shoe = _create_material(Color(0.1, 0.1, 0.1))
	
	# Head
	var head = CSGBox3D.new()
	head.size = Vector3(0.35, 0.38, 0.35)
	head.position = Vector3(0, 1.65, 0)
	head.material = mat_skin
	char_root.add_child(head)
	
	# Hair
	var hair = CSGBox3D.new()
	hair.size = Vector3(0.38, 0.16, 0.38)
	hair.position = Vector3(0, 1.84, 0)
	hair.material = mat_hair
	char_root.add_child(hair)
	
	# Glasses for Kripal
	if has_glasses:
		var glasses = CSGBox3D.new()
		glasses.size = Vector3(0.32, 0.08, 0.04)
		glasses.position = Vector3(0, 1.68, 0.19)
		glasses.material = _create_material(Color(0.1, 0.1, 0.1), 0.2, 0.8)
		char_root.add_child(glasses)
	
	# Torso
	var torso = CSGBox3D.new()
	torso.size = Vector3(0.55, 0.65, 0.35)
	torso.position = Vector3(0, 1.15, 0)
	torso.material = mat_shirt
	char_root.add_child(torso)
	
	# Legs
	var leg_l = CSGBox3D.new()
	leg_l.size = Vector3(0.2, 0.75, 0.25)
	leg_l.position = Vector3(-0.15, 0.45, 0)
	leg_l.material = mat_pant
	char_root.add_child(leg_l)
	
	var leg_r = CSGBox3D.new()
	leg_r.size = Vector3(0.2, 0.75, 0.25)
	leg_r.position = Vector3(0.15, 0.45, 0)
	leg_r.material = mat_pant
	char_root.add_child(leg_r)
	
	# Shoes
	var shoe_l = CSGBox3D.new()
	shoe_l.size = Vector3(0.22, 0.12, 0.32)
	shoe_l.position = Vector3(-0.15, 0.06, 0.05)
	shoe_l.material = mat_shoe
	char_root.add_child(shoe_l)
	
	var shoe_r = CSGBox3D.new()
	shoe_r.size = Vector3(0.22, 0.12, 0.32)
	shoe_r.position = Vector3(0.15, 0.06, 0.05)
	shoe_r.material = mat_shoe
	char_root.add_child(shoe_r)
	
	return char_root

# --- CUTSCENE TIMELINE & BEAT MANAGEMENT ---
func _start_prologue() -> void:
	if audio_ambience_night:
		audio_ambience_night.play()
	if audio_bgm:
		audio_bgm.play()
	
	# Initial camera at Crossroads
	cam_pivot.position = Vector3(0, 2.0, 3.8)
	cam.rotation_degrees = Vector3(-12, 0, 0)
	
	# Fade in from black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	tween.tween_callback(func(): _advance_beat())

func _process(delta: float) -> void:
	if not is_beat_active:
		return
	
	beat_timer += delta
	
	# Automatic pulsating light for forest anomaly during Act 2
	if current_beat in [6, 7, 8] and forest_anomaly_light:
		var pulse = (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
		forest_anomaly_light.light_energy = 2.5 + pulse * 4.0
		if forest_anomaly_mesh:
			forest_anomaly_mesh.scale = Vector3.ONE * (0.8 + pulse * 0.4)
	
	# Van driving scenery scroll during Act 4
	if current_beat in [17, 18, 19] and moving_scenery_node:
		moving_scenery_node.position.z += delta * 12.0
		if moving_scenery_node.position.z > 20.0:
			moving_scenery_node.position.z = -10.0
	
	# Auto advance to next beat after time expires
	if beat_timer >= auto_advance_time:
		_advance_beat()

func _on_screen_tapped(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_beat()
	elif event is InputEventScreenTouch and event.pressed:
		_advance_beat()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E]):
		_advance_beat()

func _on_skip_pressed() -> void:
	if skipped:
		return
	skipped = true
	_transition_to_classroom()

func _on_continue_pressed() -> void:
	_transition_to_classroom()

func _transition_to_classroom() -> void:
	is_beat_active = false
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.8)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/classroom.tscn")
	)

func _advance_beat() -> void:
	if skipped:
		return
	
	current_beat += 1
	beat_timer = 0.0
	is_beat_active = true
	
	match current_beat:
		# --- ACT 1: CROSSROADS (तीराहा) ---
		0:
			auto_advance_time = 4.8
			_set_dialogue("SAHIL", Color(0.3, 0.85, 0.4),
				"भाई सच में, आज गार्डन में क्रिकेट खेलने में बहुत मज़ा आया! लेकिन देखो कितनी रात हो गई...",
				"Bhai sach me, aaj garden me cricket khelne me bohot maza aaya! Lekin dekho kitni raat ho gayi...")
			_tween_camera(Vector3(0, 1.8, 3.2), Vector3(-8, -10, 0), 4.5)
			
		1:
			auto_advance_time = 4.8
			_set_dialogue("AASHUTOSH", Color(0.9, 0.65, 0.3),
				"हाँ यार, 8:30 बज गए! कल सुबह स्कूल भी जाना है, वरना सर क्लास से बाहर निकाल देंगे।",
				"Haan yaar, 8:30 baj gaye! Kal subah school bhi jana hai, varna sir class se bahar nikal denge.")
			_tween_camera(Vector3(-0.6, 1.7, 2.5), Vector3(-6, -25, 0), 4.5)
			
		2:
			auto_advance_time = 5.2
			_set_dialogue("PROTAGONIST (YOU)", Color(0.4, 0.7, 1.0),
				"कृपाल, तू तो अकेले जंगल वाले रास्ते से जाता है ना? वहाँ बहुत अँधेरा होता है, संभल के जाना भाई।",
				"Kripal, tu to akele jungle wale raste se jata hai na? Wahan bohot andhera hota hai, sambhal ke jana bhai.")
			_tween_camera(Vector3(0.5, 1.7, 2.2), Vector3(-6, 20, 0), 5.0)
			
		3:
			auto_advance_time = 5.2
			_set_dialogue("KRIPAL", Color(1.0, 0.4, 0.4),
				"अरे यार तुम सब टेंशन मत लो! ये तो मेरा रोज़ का शॉर्ट-कट है। चलो, कल सुबह स्कूल वैन में मिलते हैं!",
				"Arrey yaar tum sab tension mat lo! Ye to mera roz ka short-cut hai. Chalo, kal subah school van me milte hain!")
			_tween_camera(Vector3(0.6, 1.65, 1.8), Vector3(-5, -45, 0), 4.8)
			
		4:
			# Friends split up
			auto_advance_time = 4.0
			_set_dialogue("CROSSROADS", Color(0.8, 0.8, 0.8),
				"चारों दोस्त अपने-अपने घरों की तरफ निकल पड़े... कृपाल जंगल वाले रास्ते पर आगे बढ़ा...",
				"All friends parted ways... Kripal headed forward into the dark forest path...")
			
			# Animate friends walking away
			var tw = create_tween().set_parallel(true)
			tw.tween_property(char_sahil, "position:x", -12.0, 3.8)
			tw.tween_property(char_aashu, "position:x", -10.0, 3.8)
			tw.tween_property(char_player_night, "position:x", 10.0, 3.8)
			tw.tween_property(char_kripal, "position:z", -14.0, 3.8)
			_tween_camera(Vector3(0, 3.5, 5.0), Vector3(-25, 0, 0), 3.8)
			
		# --- ACT 2: KRIPAL IN THE FOREST & MYSTERIOUS LIGHT ---
		5:
			# Transition to forest
			auto_advance_time = 4.5
			_fade_transition(func():
				cam_pivot.position = Vector3(100, 1.6, 8.0)
				cam.rotation_degrees = Vector3(-8, 0, 0)
				char_kripal.reparent(set_forest)
				char_kripal.position = Vector3(0, 0, 6.0)
				char_kripal.rotation_degrees = Vector3(0, 180, 0)
			)
			_set_dialogue("NIGHT FOREST — 8:45 PM", Color(0.6, 0.8, 1.0),
				"रात का गहरा सन्नाटा... और पेड़ों के बीच अजीब खामोशी...",
				"The deep silence of the night forest... and an eerie stillness among the trees...")
			
		6:
			# Anomaly appears
			auto_advance_time = 5.5
			if audio_whisper:
				audio_whisper.play()
			_set_dialogue("KRIPAL", Color(1.0, 0.4, 0.4),
				"ये... ये जंगल के बीच में ऐसी अजीब नीली रौशनी कैसी...? यहाँ तो कोई रहता भी नहीं...",
				"Ye... ye jungle ke beech me aisi ajeeb neeli roshni kaisi...? Yahan to koi rehta bhi nahi...")
			_tween_camera(Vector3(100.8, 1.65, 2.5), Vector3(-5, 45, 0), 4.5)
			
		7:
			# Anomaly flares up / Jump shock
			auto_advance_time = 4.2
			if audio_jumpscare:
				audio_jumpscare.play()
			if audio_heartbeat:
				audio_heartbeat.play()
			
			_set_dialogue("KRIPAL", Color(1.0, 0.2, 0.2),
				"न-नहीं... ये क्या चीज़ है?!! मुझे यहाँ से तुरंत भागना होगा!!",
				"N-Nahi... Ye kya cheez hai?!! Mujhe yahan se turant bhagna hoga!!")
			
			# Camera shake
			var tw_shake = create_tween()
			for i in range(6):
				tw_shake.tween_property(cam, "position", Vector3(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15), 0), 0.06)
			tw_shake.tween_property(cam, "position", Vector3.ZERO, 0.1)
			
		8:
			# Kripal sprints to his house door
			auto_advance_time = 4.5
			_fade_transition(func():
				cam_pivot.position = Vector3(200, 2.2, 6.0)
				cam.rotation_degrees = Vector3(-12, 0, 0)
				char_kripal.reparent(set_kripal_house)
				char_kripal.position = Vector3(0, 0, 8.0)
				char_kripal.rotation_degrees = Vector3(0, 180, 0)
			)
			_set_dialogue("KRIPAL'S HOUSE", Color(0.9, 0.8, 0.4),
				"कृपाल बदहवास हालत में भागते हुए अपने घर पहुँचा और दरवाजा जोर से बंद कर लिया!",
				"Kripal sprinted in sheer terror, reached his home and slammed the front door shut!")
			
			var tw_run = create_tween()
			tw_run.tween_property(char_kripal, "position:z", -2.8, 2.5)
			tw_run.tween_callback(func():
				if audio_door_open:
					audio_door_open.play()
				char_kripal.visible = false
			)
			
		# --- ACT 3: NEXT MORNING - PROTAGONIST'S HOUSE ---
		9:
			# Next morning title card
			auto_advance_time = 4.2
			if audio_ambience_night and audio_ambience_night.playing:
				audio_ambience_night.stop()
			if audio_heartbeat and audio_heartbeat.playing:
				audio_heartbeat.stop()
			if audio_ambience_morning:
				audio_ambience_morning.play()
			
			# Switch to morning lighting
			moon_light.visible = false
			sun_light.visible = true
			world_env.environment.background_color = Color(0.65, 0.82, 0.98)
			world_env.environment.ambient_light_color = Color(0.85, 0.88, 0.95)
			world_env.environment.ambient_light_energy = 1.0
			world_env.environment.fog_enabled = false
			
			cam_pivot.position = Vector3(300, 1.8, 0.5)
			cam.rotation_degrees = Vector3(-10, 0, 0)
			
			_show_title_card("अगली सुबह — 7:15 AM", "THE NEXT MORNING — PROTAGONIST'S HOUSE")
			
		10:
			auto_advance_time = 5.0
			_hide_title_card()
			_set_dialogue("MUMMY (HALL SE)", Color(1.0, 0.75, 0.4),
				"बेटा! उठ जाओ जल्दी! सवा सात हो गए... आज फिर स्कूल वैन छूट जाएगी तुम्हारी!",
				"Beta! Uth jao jaldi! 7:15 ho gaye... Aaj phir school van chhoot jayegi tumhari!")
			_tween_camera(Vector3(300, 1.5, -0.5), Vector3(-6, -15, 0), 4.5)
			
		11:
			auto_advance_time = 5.2
			_set_dialogue("PROTAGONIST (BEDROOM)", Color(0.35, 0.75, 1.0),
				"हाँ मम्मी... उठ रहा हूँ बस 5 मिनट! मम्मी प्लीज एक कप चाय बना दो ना!",
				"Haan mummy... uth raha hoon bas 5 minute! Mummy please ek cup chai bana do na!")
			_tween_camera(Vector3(297.8, 1.4, -1.8), Vector3(-12, 45, 0), 4.5)
			
		12:
			auto_advance_time = 4.8
			_set_dialogue("MUMMY", Color(1.0, 0.75, 0.4),
				"चाय बन रही है, पहले मुँह-हाथ धो लो और यूनिफॉर्म पहनो! वैन किसी भी वक्त पहुँचती होगी!",
				"Chai ban rahi hai, pehle muh-haath dho lo aur uniform pehno! Van kisi bhi waqt pahunchti hogi!")
			
		13:
			# Van arrives outside!
			auto_advance_time = 5.5
			_fade_transition(func():
				cam_pivot.position = Vector3(400, 2.0, 6.0)
				cam.rotation_degrees = Vector3(-10, 0, 0)
			)
			if audio_van_horn:
				audio_van_horn.play()
			
			_set_dialogue("VAN DRIVER UNCLE", Color(1.0, 0.85, 0.2),
				"भाभी जी! जल्दी भेजो ना बच्चे को! 7:35 हो गए हैं, आगे कृपाल और बाकी बच्चों को भी पिक करना है... लेट हो रहा है!",
				"Bhabhi ji! Jaldi bhejo na bachhe ko! 7:35 ho gaye hain, aage Kripal aur baki bachhon ko bhi pick karna hai... late ho raha hai!")
			
		14:
			# Protagonist rushing downstairs
			auto_advance_time = 4.8
			_set_dialogue("PROTAGONIST", Color(0.35, 0.75, 1.0),
				"अरे बाप रे! वैन तो आ भी गई! जुराबें कहाँ गईं मेरी... जल्दी बैग पकड़ो!",
				"Arey baap re! Van to aa bhi gayi! Jurabein kahan gayin meri... jaldi bag pakdo!")
			
		15:
			# Running out and boarding van
			auto_advance_time = 5.0
			_set_dialogue("PROTAGONIST & DRIVER", Color(0.4, 0.85, 0.95),
				"\"गुड मॉर्निंग भैया! सॉरी आज थोड़ा लेट हो गया...\"\n— \"रोज़ का यही है तुम्हारा... चलो बैठो जल्दी, दरवाजा बंद करो!\"",
				"\"Good morning bhaiya! Sorry aaj thoda late ho gaya...\"\n— \"Roz ka yahi hai tumhara... chalo baitho jaldi, darwaja band karo!\"")
			
			if audio_door_close:
				audio_door_close.play()
			_tween_camera(Vector3(402.5, 1.6, 2.5), Vector3(-5, -30, 0), 4.5)
			
		# --- ACT 4: INSIDE THE VAN & DRIVE TO KRIPAL'S HOUSE ---
		16:
			auto_advance_time = 5.5
			if audio_van_engine:
				audio_van_engine.play()
			
			_fade_transition(func():
				cam_pivot.position = Vector3(500, 1.2, 0.8)
				cam.rotation_degrees = Vector3(0, -90, 0) # Looking out passenger window
			)
			
			_set_dialogue("INSIDE SCHOOL VAN", Color(0.85, 0.85, 0.9),
				"वैन सुबह की धूप में सड़कों पर दौड़ रही है... खिड़की से सुबह की ठंडी हवा और पेड़ पीछे छूट रहे हैं...",
				"The school van cruises through the morning streets... looking out the window as cool morning breeze and trees rush past...")
			
		17:
			auto_advance_time = 5.8
			_set_dialogue("PROTAGONIST (मन में सोचते हुए)", Color(0.35, 0.75, 1.0),
				"वैन अब कृपाल के घर की तरफ मुड़ रही है... पर अजीब बात है, सुबह से उसका फोन स्विच ऑफ क्यों आ रहा है...?",
				"Van ab Kripal ke ghar ki taraf mud rahi hai... Par ajeeb baat hai, subah se uska phone switch off kyu aa raha hai...?")
			
		18:
			auto_advance_time = 5.2
			_set_dialogue("VAN DRIVER", Color(1.0, 0.85, 0.2),
				"देखते हैं आज कृपाल तैयार मिलता है या वो भी सोता ही मिलेगा...",
				"Dekhte hain aaj Kripal taiyaar milta hai ya wo bhi sota hi milega...")
			
		19:
			# Final Suspense Chapter Card
			auto_advance_time = 999.0 # Wait for user to click button
			continue_btn.visible = true
			_set_dialogue("PROLOGUE COMPLETE", Color(1.0, 0.9, 0.4),
				"वैन कृपाल के घर के सामने रुकती है... पर वहाँ का नजारा देखकर सबके होश उड़ जाते हैं...",
				"The van halts outside Kripal's house... but what awaits them inside will shock everyone...")
			_show_title_card("CHAPTER 1: THE DISAPPEARANCE", "गायब कृपाल — कहानी जारी है...")

func _set_dialogue(speaker: String, col: Color, text_hi: String, text_sub: String) -> void:
	speaker_tag.text = speaker
	speaker_tag.add_theme_color_override("font_color", col)
	subtitle_text.text = text_hi
	subtitle_sub.text = text_sub

func _show_title_card(title: String, sub: String) -> void:
	title_card_title.text = title
	title_card_sub.text = sub
	var tw = create_tween()
	tw.tween_property(title_card_box, "modulate:a", 1.0, 0.8)

func _hide_title_card() -> void:
	var tw = create_tween()
	tw.tween_property(title_card_box, "modulate:a", 0.0, 0.6)

func _tween_camera(target_pos: Vector3, target_rot: Vector3, duration: float) -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cam_pivot, "position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "rotation_degrees", target_rot, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _fade_transition(callback: Callable) -> void:
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.45)
	tw.tween_callback(callback)
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.6)
