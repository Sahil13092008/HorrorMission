extends Node3D

# ==============================================================================
# CINEMATIC OPENING PROLOGUE — HORROR MISSION
# ==============================================================================
# Full Multi-Scene Cinematic Experience:
# Act 1: Walking down the Pansemal street under the eerie Blood Sky (लाल आसमान),
#        4 friends chatting and separating at the 3-Way crossroads.
# Act 2: Dense 3D Forest map, misty path, terrifying pulsing light anomaly,
#        Kripal's panic sprint to his house.
# Act 3: Full House interior (Living Room with Papa watching TV, Kitchen with
#        Mummy cooking chai, Upstairs bedroom with Protagonist waking up).
# Act 4: Living neighborhood street with houses, trees in the breeze, school van
#        arrival with horn, and full 3D running animation of Protagonist to the van.
# Act 5: Detailed school van interior with driver & kids, window gazing cutscene
#        with parallax scrolling morning street and dedicated Song/BGM slot.
# ==============================================================================

var current_beat: int = -1
var is_beat_active: bool = false
var beat_timer: float = 0.0
var auto_advance_time: float = 5.0
var anim_time: float = 0.0
var skipped: bool = false

# UI Elements
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

# Camera & World
var cam: Camera3D
var cam_pivot: Node3D
var world_env: WorldEnvironment
var blood_sky_env: Environment
var morning_sky_env: Environment
var sun_light: DirectionalLight3D
var blood_sky_light: DirectionalLight3D

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
var audio_bgm_song: AudioStreamPlayer

# Sets
var set_blood_road: Node3D
var set_dense_forest: Node3D
var set_kripal_house: Node3D
var set_full_house: Node3D
var set_neighborhood_street: Node3D
var set_van_interior: Node3D

# Characters & Interactive Objects
var char_group_walk: Node3D
var char_sahil_walk: Node3D
var char_aashu_walk: Node3D
var char_kripal_walk: Node3D
var char_player_walk: Node3D

var char_kripal_forest: Node3D
var forest_anomaly_core: MeshInstance3D
var forest_anomaly_light: OmniLight3D
var forest_trees: Array = []

var char_papa: Node3D
var char_mummy: Node3D
var char_player_bed: Node3D
var tv_screen_mesh: CSGBox3D
var tea_steam_mesh: MeshInstance3D

var char_player_sprint: Node3D
var front_door_mesh: CSGBox3D
var school_van_exterior: Node3D
var street_trees: Array = []

var char_player_window: Node3D
var van_scenery_scroll: Node3D

func _ready() -> void:
	_build_ui()
	_setup_lighting_and_environments()
	_setup_audio()
	_build_all_3d_sets()
	_start_prologue()

# --- UI CREATION ---
func _build_ui() -> void:
	ui_root = CanvasLayer.new()
	ui_root.layer = 10
	add_child(ui_root)
	
	tap_advance_panel = Control.new()
	tap_advance_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap_advance_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_root.add_child(tap_advance_panel)
	tap_advance_panel.gui_input.connect(_on_screen_tapped)
	
	letterbox_top = ColorRect.new()
	letterbox_top.color = Color(0, 0, 0, 1)
	letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	letterbox_top.custom_minimum_size = Vector2(0, 72)
	letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(letterbox_top)
	
	letterbox_bottom = ColorRect.new()
	letterbox_bottom.color = Color(0.02, 0.02, 0.03, 0.96)
	letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	letterbox_bottom.offset_top = -140
	letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(letterbox_bottom)
	
	var sub_margin = MarginContainer.new()
	sub_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_margin.add_theme_constant_override("margin_left", 35)
	sub_margin.add_theme_constant_override("margin_right", 35)
	sub_margin.add_theme_constant_override("margin_top", 10)
	sub_margin.add_theme_constant_override("margin_bottom", 10)
	sub_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letterbox_bottom.add_child(sub_margin)
	
	var sub_vbox = VBoxContainer.new()
	sub_vbox.add_theme_constant_override("separation", 3)
	sub_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_margin.add_child(sub_vbox)
	
	speaker_tag = Label.new()
	speaker_tag.text = "PROLOGUE"
	speaker_tag.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	speaker_tag.add_theme_font_size_override("font_size", 16)
	sub_vbox.add_child(speaker_tag)
	
	subtitle_text = Label.new()
	subtitle_text.text = "शुरुआत हो रही है..."
	subtitle_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	subtitle_text.add_theme_font_size_override("font_size", 17)
	sub_vbox.add_child(subtitle_text)
	
	subtitle_sub = Label.new()
	subtitle_sub.text = ""
	subtitle_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_sub.add_theme_color_override("font_color", Color(0.78, 0.8, 0.88))
	subtitle_sub.add_theme_font_size_override("font_size", 13)
	sub_vbox.add_child(subtitle_sub)
	
	# Centered Title Card
	title_card_box = CenterContainer.new()
	title_card_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card_box.modulate = Color(1, 1, 1, 0)
	ui_root.add_child(title_card_box)
	
	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 8)
	title_card_box.add_child(title_vbox)
	
	title_card_title = Label.new()
	title_card_title.text = "लाल आसमान के साये में"
	title_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_card_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title_card_title.add_theme_font_size_override("font_size", 28)
	title_vbox.add_child(title_card_title)
	
	title_card_sub = Label.new()
	title_card_sub.text = "THE BLOOD SKY ROAD — PANSEMAL"
	title_card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_card_sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	title_card_sub.add_theme_font_size_override("font_size", 16)
	title_vbox.add_child(title_card_sub)
	
	# Skip Button
	skip_btn = Button.new()
	skip_btn.text = "SKIP ⏭️"
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -115
	skip_btn.offset_top = 14
	skip_btn.offset_right = -20
	skip_btn.offset_bottom = 54
	skip_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	skip_btn.add_theme_font_size_override("font_size", 14)
	skip_btn.pressed.connect(_on_skip_pressed)
	ui_root.add_child(skip_btn)
	
	# Continue Button
	continue_btn = Button.new()
	continue_btn.text = "▶ START CHAPTER 1 / क्लासरूम शुरू करें"
	continue_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	continue_btn.offset_left = -310
	continue_btn.offset_top = -125
	continue_btn.offset_right = -25
	continue_btn.offset_bottom = -75
	continue_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.45))
	continue_btn.add_theme_font_size_override("font_size", 16)
	continue_btn.visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	ui_root.add_child(continue_btn)
	
	# Fade Overlay
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade_overlay)

# --- LIGHTING & ENVIRONMENTS ---
func _setup_lighting_and_environments() -> void:
	# Blood Sky Environment for Act 1 & 2
	blood_sky_env = Environment.new()
	blood_sky_env.background_mode = Environment.BG_COLOR
	blood_sky_env.background_color = Color(0.28, 0.04, 0.04)
	blood_sky_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	blood_sky_env.ambient_light_color = Color(0.48, 0.14, 0.12)
	blood_sky_env.ambient_light_energy = 0.8
	blood_sky_env.fog_enabled = true
	blood_sky_env.fog_light_color = Color(0.35, 0.08, 0.08)
	blood_sky_env.fog_density = 0.018
	
	# Morning Sky Environment for Act 3, 4, 5
	morning_sky_env = Environment.new()
	morning_sky_env.background_mode = Environment.BG_COLOR
	morning_sky_env.background_color = Color(0.68, 0.84, 0.98)
	morning_sky_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	morning_sky_env.ambient_light_color = Color(0.92, 0.9, 0.85)
	morning_sky_env.ambient_light_energy = 1.1
	morning_sky_env.fog_enabled = true
	morning_sky_env.fog_light_color = Color(0.85, 0.9, 0.95)
	morning_sky_env.fog_density = 0.005
	
	world_env = WorldEnvironment.new()
	world_env.environment = blood_sky_env
	add_child(world_env)
	
	# Blood Sky Directional Light
	blood_sky_light = DirectionalLight3D.new()
	blood_sky_light.light_color = Color(0.95, 0.35, 0.25)
	blood_sky_light.light_energy = 1.2
	blood_sky_light.rotation_degrees = Vector3(-35, 45, 0)
	blood_sky_light.shadow_enabled = true
	add_child(blood_sky_light)
	
	# Morning Golden Sunlight (Initially hidden)
	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.94, 0.8)
	sun_light.light_energy = 1.4
	sun_light.rotation_degrees = Vector3(-38, -40, 0)
	sun_light.shadow_enabled = true
	sun_light.visible = false
	add_child(sun_light)
	
	# Camera Setup
	cam_pivot = Node3D.new()
	cam_pivot.name = "CameraPivot"
	add_child(cam_pivot)
	
	cam = Camera3D.new()
	cam.name = "CinematicCamera"
	cam.current = true
	cam.fov = 65.0
	cam_pivot.add_child(cam)

# --- AUDIO SETUP ---
func _setup_audio() -> void:
	var audio_root = Node.new()
	audio_root.name = "AudioRoot"
	add_child(audio_root)
	
	audio_ambience_night = AudioStreamPlayer.new()
	audio_ambience_night.stream = _load_audio("res://audio/ambience.wav")
	audio_ambience_night.volume_db = -4.0
	audio_root.add_child(audio_ambience_night)
	
	audio_ambience_morning = AudioStreamPlayer.new()
	audio_ambience_morning.stream = _load_audio("res://audio/morning_birds.wav")
	audio_ambience_morning.volume_db = -2.0
	audio_root.add_child(audio_ambience_morning)
	
	audio_whisper = AudioStreamPlayer.new()
	audio_whisper.stream = _load_audio("res://audio/demon_whisper.wav")
	audio_whisper.volume_db = -1.0
	audio_root.add_child(audio_whisper)
	
	audio_heartbeat = AudioStreamPlayer.new()
	audio_heartbeat.stream = _load_audio("res://audio/heartbeat.wav")
	audio_heartbeat.volume_db = 2.0
	audio_root.add_child(audio_heartbeat)
	
	audio_jumpscare = AudioStreamPlayer.new()
	audio_jumpscare.stream = _load_audio("res://audio/jumpscare.wav")
	audio_jumpscare.volume_db = 3.0
	audio_root.add_child(audio_jumpscare)
	
	audio_door_open = AudioStreamPlayer.new()
	audio_door_open.stream = _load_audio("res://audio/home_door_open.wav")
	audio_root.add_child(audio_door_open)
	
	audio_door_close = AudioStreamPlayer.new()
	audio_door_close.stream = _load_audio("res://audio/car_door_close.wav")
	audio_root.add_child(audio_door_close)
	
	audio_van_horn = AudioStreamPlayer.new()
	audio_van_horn.stream = _load_audio("res://audio/van_horn.wav")
	audio_van_horn.volume_db = 4.0
	audio_root.add_child(audio_van_horn)
	
	audio_van_engine = AudioStreamPlayer.new()
	audio_van_engine.stream = _load_audio("res://audio/car_engine_loop.wav")
	audio_van_engine.volume_db = -6.0
	audio_root.add_child(audio_van_engine)
	
	# Dedicated Song / BGM slot
	audio_bgm_song = AudioStreamPlayer.new()
	audio_bgm_song.volume_db = -4.0
	# Auto load prologue_bgm or prologue_song if user places it, or fallback to bhangarh_ambience
	var song_stream = _load_audio("res://audio/prologue_song.mp3")
	if not song_stream:
		song_stream = _load_audio("res://audio/prologue_bgm.mp3")
	if not song_stream:
		song_stream = _load_audio("res://audio/bhangarh_ambience.wav")
	audio_bgm_song.stream = song_stream
	audio_root.add_child(audio_bgm_song)

func _load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null

func _create_mat(col: Color, roughness: float = 0.8, metallic: float = 0.0, emission: Color = Color.BLACK, emission_eng: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = roughness
	m.metallic = metallic
	if emission_eng > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_eng
	return m

# --- 3D SETS BUILDER ---
func _build_all_3d_sets() -> void:
	_build_act1_blood_sky_road()
	_build_act2_dense_forest()
	_build_act3_full_house()
	_build_act4_neighborhood_van()
	_build_act5_van_interior()

# ------------------------------------------------------------------------------
# ACT 1: BLOOD SKY ROAD (Four friends walking down the road together)
# ------------------------------------------------------------------------------
func _build_act1_blood_sky_road() -> void:
	set_blood_road = Node3D.new()
	set_blood_road.name = "Set_BloodRoad"
	set_blood_road.position = Vector3(0, 0, 0)
	add_child(set_blood_road)
	
	var mat_road = _create_mat(Color(0.12, 0.12, 0.14), 0.9)
	var mat_sidewalk = _create_mat(Color(0.25, 0.22, 0.2), 0.85)
	var mat_wall = _create_mat(Color(0.5, 0.4, 0.35), 0.9)
	var mat_pole = _create_mat(Color(0.2, 0.2, 0.22), 0.5, 0.7)
	var mat_glow = _create_mat(Color(1.0, 0.85, 0.4), 0.2, 0.0, Color(1.0, 0.8, 0.3), 3.0)
	
	# Main Road (60 meters long)
	var road = CSGBox3D.new()
	road.size = Vector3(7.0, 0.1, 70.0)
	road.position = Vector3(0, -0.05, 5.0)
	road.material = mat_road
	set_blood_road.add_child(road)
	
	# White lane dashes
	for z in range(-25, 35, 6):
		var dash = CSGBox3D.new()
		dash.size = Vector3(0.2, 0.11, 2.8)
		dash.position = Vector3(0, 0.01, z)
		dash.material = _create_mat(Color(0.9, 0.85, 0.3))
		set_blood_road.add_child(dash)
	
	# Sidewalks
	var sw_l = CSGBox3D.new()
	sw_l.size = Vector3(2.5, 0.25, 70.0)
	sw_l.position = Vector3(-4.75, 0.02, 5.0)
	sw_l.material = mat_sidewalk
	set_blood_road.add_child(sw_l)
	
	var sw_r = CSGBox3D.new()
	sw_r.size = Vector3(2.5, 0.25, 70.0)
	sw_r.position = Vector3(4.75, 0.02, 5.0)
	sw_r.material = mat_sidewalk
	set_blood_road.add_child(sw_r)
	
	# Roadside Town Houses and Compound Walls
	for z in [-18, -4, 10, 24]:
		# Left house
		var h_l = CSGBox3D.new()
		h_l.size = Vector3(8.0, 5.5, 9.0)
		h_l.position = Vector3(-10.5, 2.75, z)
		h_l.material = _create_mat(Color(0.48 + randf() * 0.1, 0.38 + randf() * 0.1, 0.3))
		set_blood_road.add_child(h_l)
		
		# Right house
		var h_r = CSGBox3D.new()
		h_r.size = Vector3(8.0, 5.5, 9.0)
		h_r.position = Vector3(10.5, 2.75, z)
		h_r.material = _create_mat(Color(0.42 + randf() * 0.1, 0.44 + randf() * 0.1, 0.38))
		set_blood_road.add_child(h_r)
	
	# Streetlights casting pools of warm light
	for z in [-15, 0, 15, 30]:
		var pole = CSGCylinder3D.new()
		pole.radius = 0.07
		pole.height = 5.0
		pole.position = Vector3(-4.0, 2.5, z)
		pole.material = mat_pole
		set_blood_road.add_child(pole)
		
		var lamp = CSGSphere3D.new()
		lamp.radius = 0.3
		lamp.position = Vector3(-3.8, 4.9, z)
		lamp.material = mat_glow
		set_blood_road.add_child(lamp)
		
		var light = OmniLight3D.new()
		light.position = Vector3(-3.8, 4.7, z)
		light.omni_range = 11.0
		light.light_energy = 1.8
		light.light_color = Color(1.0, 0.85, 0.5)
		light.shadow_enabled = true
		set_blood_road.add_child(light)
	
	# 3-Way Crossroads Signboard at z = -22
	var sign_pole = CSGCylinder3D.new()
	sign_pole.radius = 0.08
	sign_pole.height = 3.2
	sign_pole.position = Vector3(2.5, 1.6, -22.0)
	sign_pole.material = mat_pole
	set_blood_road.add_child(sign_pole)
	
	var sign_board = Label3D.new()
	sign_board.text = "⬅ MARKET / SAHIL  |  FOREST / KRIPAL ⬆  |  TOWN / HOME ➡"
	sign_board.font_size = 22
	sign_board.modulate = Color(1.0, 0.9, 0.4)
	sign_board.position = Vector3(2.5, 3.2, -22.0)
	sign_board.rotation_degrees = Vector3(0, 0, 0)
	set_blood_road.add_child(sign_board)
	
	# Group of 4 Friends walking together down the street
	char_group_walk = Node3D.new()
	char_group_walk.name = "FriendsWalkingGroup"
	char_group_walk.position = Vector3(0, 0, 22.0)
	set_blood_road.add_child(char_group_walk)
	
	char_sahil_walk = _build_rigged_human("Sahil", Color(0.2, 0.6, 0.3), Color(0.18, 0.18, 0.22), true) # cricket bat
	char_sahil_walk.position = Vector3(-1.3, 0, 0)
	char_group_walk.add_child(char_sahil_walk)
	
	char_aashu_walk = _build_rigged_human("Aashutosh", Color(0.68, 0.42, 0.2), Color(0.22, 0.22, 0.25))
	char_aashu_walk.position = Vector3(-0.4, 0, 0.3)
	char_group_walk.add_child(char_aashu_walk)
	
	char_kripal_walk = _build_rigged_human("Kripal", Color(0.82, 0.25, 0.2), Color(0.18, 0.2, 0.3), false, true) # glasses
	char_kripal_walk.position = Vector3(0.5, 0, -0.2)
	char_group_walk.add_child(char_kripal_walk)
	
	char_player_walk = _build_rigged_human("Protagonist", Color(0.25, 0.45, 0.8), Color(0.15, 0.15, 0.18))
	char_player_walk.position = Vector3(1.3, 0, 0.2)
	char_group_walk.add_child(char_player_walk)

# ------------------------------------------------------------------------------
# ACT 2: DENSE FOREST MAP & PULSING ANOMALY (पूरा घना जंगल का मैप)
# ------------------------------------------------------------------------------
func _build_act2_dense_forest() -> void:
	set_dense_forest = Node3D.new()
	set_dense_forest.name = "Set_DenseForest"
	set_dense_forest.position = Vector3(200, 0, 0)
	add_child(set_dense_forest)
	
	# Massive forest floor (60m x 70m)
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(60.0, 0.2, 70.0)
	floor_mesh.position = Vector3(0, -0.1, 0)
	floor_mesh.material = _create_mat(Color(0.06, 0.05, 0.04), 0.95)
	set_dense_forest.add_child(floor_mesh)
	
	# Winding dirt trail
	var trail = CSGBox3D.new()
	trail.size = Vector3(4.5, 0.05, 70.0)
	trail.position = Vector3(0, 0.02, 0)
	trail.material = _create_mat(Color(0.12, 0.09, 0.06), 0.95)
	set_dense_forest.add_child(trail)
	
	# Dense clusters of trees (Over 35 tall detailed trees)
	var tree_coords = []
	for z in range(-30, 32, 4):
		# Near trail edges
		tree_coords.append(Vector3(-4.5 - randf() * 2.0, 0, z + randf_range(-1.0, 1.0)))
		tree_coords.append(Vector3(4.5 + randf() * 2.0, 0, z + randf_range(-1.0, 1.0)))
		# Deep in the woods
		tree_coords.append(Vector3(-10.0 - randf() * 8.0, 0, z + randf_range(-2.0, 2.0)))
		tree_coords.append(Vector3(10.0 + randf() * 8.0, 0, z + randf_range(-2.0, 2.0)))
		tree_coords.append(Vector3(-18.0 - randf() * 5.0, 0, z + randf_range(-2.0, 2.0)))
		tree_coords.append(Vector3(18.0 + randf() * 5.0, 0, z + randf_range(-2.0, 2.0)))
	
	for tc in tree_coords:
		var tree = _create_detailed_forest_tree()
		tree.position = tc
		set_dense_forest.add_child(tree)
		forest_trees.append(tree)
	
	# Fallen mossy logs & rocky boulders
	for i in range(10):
		var log_mesh = CSGCylinder3D.new()
		log_mesh.radius = 0.3
		log_mesh.height = 4.0
		log_mesh.rotation_degrees = Vector3(0, randf_range(-60, 60), 90)
		log_mesh.position = Vector3(-6.0 if i % 2 == 0 else 6.0, 0.3, -25.0 + i * 5.5)
		log_mesh.material = _create_mat(Color(0.18, 0.14, 0.08), 0.9)
		set_dense_forest.add_child(log_mesh)
	
	# Eerie Pulsing Light Anomaly deep inside the trees on the right (at z = -8)
	var anomaly_pivot = Node3D.new()
	anomaly_pivot.position = Vector3(7.5, 2.4, -8.0)
	set_dense_forest.add_child(anomaly_pivot)
	
	forest_anomaly_core = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.6
	s_mesh.height = 1.2
	forest_anomaly_core.mesh = s_mesh
	forest_anomaly_core.material_override = _create_mat(Color(0.2, 0.8, 1.0), 0.1, 0.0, Color(0.3, 0.9, 1.0), 6.0)
	anomaly_pivot.add_child(forest_anomaly_core)
	
	# Outer glowing ring around anomaly
	var ring = CSGTorus3D.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.0
	ring.material = _create_mat(Color(0.7, 0.2, 1.0), 0.1, 0.0, Color(0.8, 0.3, 1.0), 4.5)
	anomaly_pivot.add_child(ring)
	
	forest_anomaly_light = OmniLight3D.new()
	forest_anomaly_light.light_color = Color(0.2, 0.75, 1.0)
	forest_anomaly_light.light_energy = 4.0
	forest_anomaly_light.omni_range = 24.0
	forest_anomaly_light.shadow_enabled = true
	anomaly_pivot.add_child(forest_anomaly_light)
	
	# Kripal inside the forest
	char_kripal_forest = _build_rigged_human("KripalForest", Color(0.82, 0.25, 0.2), Color(0.18, 0.2, 0.3), false, true)
	char_kripal_forest.position = Vector3(0, 0, 10.0)
	char_kripal_forest.rotation_degrees = Vector3(0, 180, 0)
	set_dense_forest.add_child(char_kripal_forest)

# ------------------------------------------------------------------------------
# ACT 3: FULL HOUSE INTERIOR (Living Room, Kitchen with Mummy, Upstairs Bedroom)
# ------------------------------------------------------------------------------
func _build_act3_full_house() -> void:
	set_full_house = Node3D.new()
	set_full_house.name = "Set_FullHouse"
	set_full_house.position = Vector3(400, 0, 0)
	add_child(set_full_house)
	
	var mat_wall_hall = _create_mat(Color(0.92, 0.88, 0.82), 0.9)
	var mat_tile_floor = _create_mat(Color(0.82, 0.8, 0.76), 0.6)
	var mat_kitchen_slab = _create_mat(Color(0.18, 0.18, 0.2), 0.3)
	var mat_wood = _create_mat(Color(0.42, 0.25, 0.14), 0.7)
	var mat_sofa = _create_mat(Color(0.3, 0.2, 0.4), 0.85) # Purple/Maroon Indian sofa
	
	# Ground floor slab (16m wide x 12m deep)
	var floor_g = CSGBox3D.new()
	floor_g.size = Vector3(16.0, 0.2, 12.0)
	floor_g.position = Vector3(0, -0.1, 0)
	floor_g.material = mat_tile_floor
	set_full_house.add_child(floor_g)
	
	# Outer perimeter walls
	var wall_back = CSGBox3D.new()
	wall_back.size = Vector3(16.0, 6.5, 0.3)
	wall_back.position = Vector3(0, 3.25, -6.0)
	wall_back.material = mat_wall_hall
	set_full_house.add_child(wall_back)
	
	var wall_left = CSGBox3D.new()
	wall_left.size = Vector3(0.3, 6.5, 12.0)
	wall_left.position = Vector3(-8.0, 3.25, 0)
	wall_left.material = mat_wall_hall
	set_full_house.add_child(wall_left)
	
	# --- ZONE 1: LIVING ROOM / HALL (Left half of ground floor) ---
	# Sofa Set
	var sofa_main = CSGBox3D.new()
	sofa_main.size = Vector3(3.2, 0.85, 1.1)
	sofa_main.position = Vector3(-4.5, 0.42, 1.5)
	sofa_main.material = mat_sofa
	set_full_house.add_child(sofa_main)
	
	var sofa_back = CSGBox3D.new()
	sofa_back.size = Vector3(3.2, 0.8, 0.3)
	sofa_back.position = Vector3(-4.5, 1.0, 1.9)
	sofa_back.material = mat_sofa
	set_full_house.add_child(sofa_back)
	
	# Coffee Table
	var table = CSGBox3D.new()
	table.size = Vector3(1.8, 0.45, 0.9)
	table.position = Vector3(-4.5, 0.22, 0.0)
	table.material = mat_wood
	set_full_house.add_child(table)
	
	# Newspaper & Cups on coffee table
	var newspaper = CSGBox3D.new()
	newspaper.size = Vector3(0.5, 0.02, 0.4)
	newspaper.position = Vector3(-4.8, 0.46, 0.0)
	newspaper.material = _create_mat(Color(0.9, 0.9, 0.88))
	set_full_house.add_child(newspaper)
	
	# TV Unit against wall
	var tv_cabinet = CSGBox3D.new()
	tv_cabinet.size = Vector3(2.6, 0.7, 0.5)
	tv_cabinet.position = Vector3(-4.5, 0.35, -4.5)
	tv_cabinet.material = mat_wood
	set_full_house.add_child(tv_cabinet)
	
	tv_screen_mesh = CSGBox3D.new()
	tv_screen_mesh.size = Vector3(2.0, 1.2, 0.08)
	tv_screen_mesh.position = Vector3(-4.5, 1.5, -4.5)
	tv_screen_mesh.material = _create_mat(Color(0.2, 0.6, 0.9), 0.2, 0.0, Color(0.3, 0.7, 1.0), 2.5) # Glowing TV
	set_full_house.add_child(tv_screen_mesh)
	
	# Papa NPC sitting on sofa watching TV
	char_papa = _build_rigged_human("Papa", Color(0.85, 0.82, 0.75), Color(0.9, 0.9, 0.9), false, false, false, true) # Sitting pose
	char_papa.position = Vector3(-4.5, 0.35, 1.5)
	char_papa.rotation_degrees = Vector3(0, 180, 0)
	set_full_house.add_child(char_papa)
	
	# --- ZONE 2: KITCHEN (Right half of ground floor) ---
	var kitchen_counter = CSGBox3D.new()
	kitchen_counter.size = Vector3(4.0, 0.9, 1.2)
	kitchen_counter.position = Vector3(4.5, 0.45, -4.5)
	kitchen_counter.material = mat_kitchen_slab
	set_full_house.add_child(kitchen_counter)
	
	# Gas stove & Chai pot
	var stove = CSGBox3D.new()
	stove.size = Vector3(1.2, 0.1, 0.6)
	stove.position = Vector3(4.5, 0.95, -4.5)
	stove.material = _create_mat(Color(0.2, 0.2, 0.22), 0.3, 0.8)
	set_full_house.add_child(stove)
	
	var chai_pot = CSGCylinder3D.new()
	chai_pot.radius = 0.2
	chai_pot.height = 0.25
	chai_pot.position = Vector3(4.5, 1.15, -4.5)
	chai_pot.material = _create_mat(Color(0.7, 0.7, 0.72), 0.2, 0.9)
	set_full_house.add_child(chai_pot)
	
	# Steam puff over chai
	tea_steam_mesh = MeshInstance3D.new()
	var steam_s = SphereMesh.new()
	steam_s.radius = 0.12
	steam_s.height = 0.25
	tea_steam_mesh.mesh = steam_s
	tea_steam_mesh.material_override = _create_mat(Color(1, 1, 1, 0.3), 0.9, 0.0, Color.WHITE, 0.5)
	tea_steam_mesh.position = Vector3(4.5, 1.4, -4.5)
	set_full_house.add_child(tea_steam_mesh)
	
	# Mummy NPC standing at stove
	char_mummy = _build_rigged_human("Mummy", Color(0.85, 0.2, 0.35), Color(0.85, 0.2, 0.35), false, false, true) # Saree attire
	char_mummy.position = Vector3(4.5, 0, -3.2)
	char_mummy.rotation_degrees = Vector3(0, 0, 0)
	set_full_house.add_child(char_mummy)
	
	# --- ZONE 3: STAIRCASE & UPSTAIRS BEDROOM ---
	# Stair steps
	for i in range(8):
		var step = CSGBox3D.new()
		step.size = Vector3(1.8, 0.35, 0.45)
		step.position = Vector3(0.5, 0.18 + (i * 0.35), -1.5 + (i * 0.45))
		step.material = mat_wood
		set_full_house.add_child(step)
	
	# Upstairs floor slab
	var floor_up = CSGBox3D.new()
	floor_up.size = Vector3(9.0, 0.2, 7.0)
	floor_up.position = Vector3(-2.5, 2.9, 2.5)
	floor_up.material = mat_wood
	set_full_house.add_child(floor_up)
	
	# Protagonist's Bed upstairs
	var bed_frame = CSGBox3D.new()
	bed_frame.size = Vector3(2.2, 0.4, 3.2)
	bed_frame.position = Vector3(-4.8, 3.2, 3.2)
	bed_frame.material = mat_wood
	set_full_house.add_child(bed_frame)
	
	var mattress = CSGBox3D.new()
	mattress.size = Vector3(2.0, 0.35, 3.0)
	mattress.position = Vector3(-4.8, 3.5, 3.2)
	mattress.material = _create_mat(Color(0.2, 0.45, 0.8)) # Blue bedsheet
	set_full_house.add_child(mattress)
	
	var pillow = CSGBox3D.new()
	pillow.size = Vector3(1.3, 0.18, 0.6)
	pillow.position = Vector3(-4.8, 3.75, 4.2)
	pillow.material = _create_mat(Color(0.95, 0.95, 0.95))
	set_full_house.add_child(pillow)
	
	# Window with morning sun in bedroom
	var bedroom_window = CSGBox3D.new()
	bedroom_window.size = Vector3(2.4, 1.8, 0.2)
	bedroom_window.position = Vector3(-4.8, 4.5, 5.9)
	bedroom_window.material = _create_mat(Color(0.85, 0.95, 1.0, 0.5), 0.1, 0.0, Color(1.0, 0.96, 0.75), 3.0)
	set_full_house.add_child(bedroom_window)
	
	# Protagonist sleeping / waking up on bed
	char_player_bed = _build_rigged_human("ProtagonistBed", Color(0.9, 0.9, 0.9), Color(0.2, 0.35, 0.6))
	char_player_bed.position = Vector3(-4.8, 3.7, 3.2)
	char_player_bed.rotation_degrees = Vector3(-70, 0, 0) # Lying down, sits up
	set_full_house.add_child(char_player_bed)

# ------------------------------------------------------------------------------
# ACT 4: NEIGHBORHOOD MAP & SCHOOL VAN ARRIVAL (पूरा मैप, वैन, दौड़ते हुए जाना)
# ------------------------------------------------------------------------------
func _build_act4_neighborhood_van() -> void:
	set_neighborhood_street = Node3D.new()
	set_neighborhood_street.name = "Set_NeighborhoodStreet"
	set_neighborhood_street.position = Vector3(600, 0, 0)
	add_child(set_neighborhood_street)
	
	# Long residential street (70m x 25m)
	var ground = CSGBox3D.new()
	ground.size = Vector3(30.0, 0.2, 80.0)
	ground.position = Vector3(0, -0.1, 0)
	ground.material = _create_mat(Color(0.2, 0.2, 0.22), 0.9)
	set_neighborhood_street.add_child(ground)
	
	# Protagonist's house front exterior (Right side)
	var house_facade = CSGBox3D.new()
	house_facade.size = Vector3(10.0, 6.0, 8.0)
	house_facade.position = Vector3(10.0, 3.0, 0)
	house_facade.material = _create_mat(Color(0.88, 0.84, 0.78))
	set_neighborhood_street.add_child(house_facade)
	
	# Front Porch & Door
	front_door_mesh = CSGBox3D.new()
	front_door_mesh.size = Vector3(0.1, 2.5, 1.5)
	front_door_mesh.position = Vector3(4.9, 1.25, 0)
	front_door_mesh.material = _create_mat(Color(0.4, 0.25, 0.12))
	set_neighborhood_street.add_child(front_door_mesh)
	
	# Compound wall with open gate
	var c_wall = CSGBox3D.new()
	c_wall.size = Vector3(0.25, 1.5, 18.0)
	c_wall.position = Vector3(3.0, 0.75, 0)
	c_wall.material = _create_mat(Color(0.65, 0.65, 0.65))
	set_neighborhood_street.add_child(c_wall)
	
	# Gate opening
	var gate_cut = CSGBox3D.new()
	gate_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	gate_cut.size = Vector3(0.5, 1.8, 3.0)
	gate_cut.position = Vector3(3.0, 0.9, 0)
	c_wall.add_child(gate_cut)
	
	# Other houses across the street
	for z in [-20, -5, 12, 28]:
		var opp_house = CSGBox3D.new()
		opp_house.size = Vector3(9.0, 5.0, 10.0)
		opp_house.position = Vector3(-11.0, 2.5, z)
		opp_house.material = _create_mat(Color(0.75 + randf()*0.1, 0.65 + randf()*0.1, 0.55))
		set_neighborhood_street.add_child(opp_house)
	
	# Swaying Neem / Gulmohar trees along street
	for z in [-26, -14, 2, 16, 28]:
		var tree = _create_detailed_forest_tree(true) # morning tree
		tree.position = Vector3(-4.0, 0, z)
		set_neighborhood_street.add_child(tree)
		street_trees.append(tree)
	
	# Overhead electric wires & concrete poles
	for z in [-20, 0, 20]:
		var pole = CSGCylinder3D.new()
		pole.radius = 0.1
		pole.height = 6.5
		pole.position = Vector3(-3.5, 3.25, z)
		pole.material = _create_mat(Color(0.35, 0.35, 0.38), 0.6)
		set_neighborhood_street.add_child(pole)
	
	# School Van Exterior parked by front gate
	school_van_exterior = _build_detailed_school_van()
	school_van_exterior.position = Vector3(-0.5, 0, -2.5)
	set_neighborhood_street.add_child(school_van_exterior)
	
	# Protagonist running figure
	char_player_sprint = _build_rigged_human("ProtagonistSprint", Color(0.95, 0.95, 0.95), Color(0.18, 0.28, 0.55), false, false, false, false, true) # Uniform + Backpack
	char_player_sprint.position = Vector3(4.5, 0, 0)
	char_player_sprint.rotation_degrees = Vector3(0, -90, 0)
	char_player_sprint.visible = false
	set_neighborhood_street.add_child(char_player_sprint)

# ------------------------------------------------------------------------------
# ACT 5: SCHOOL VAN INTERIOR & WINDOW GAZING (वैन का इंटीरियर & खिड़की से देखना)
# ------------------------------------------------------------------------------
func _build_act5_van_interior() -> void:
	set_van_interior = Node3D.new()
	set_van_interior.name = "Set_VanInterior"
	set_van_interior.position = Vector3(800, 0, 0)
	add_child(set_van_interior)
	
	var mat_van_frame = _create_mat(Color(0.2, 0.2, 0.22), 0.7)
	var mat_seat = _create_mat(Color(0.48, 0.22, 0.15), 0.7) # Indian van brown leatherette
	var mat_glass = _create_mat(Color(0.7, 0.85, 0.95, 0.4), 0.1, 0.0)
	
	# Van cabin enclosure
	var cabin = CSGBox3D.new()
	cabin.size = Vector3(2.8, 2.2, 4.8)
	cabin.position = Vector3(0, 1.1, 0)
	cabin.material = mat_van_frame
	set_van_interior.add_child(cabin)
	
	# Cut out interior space
	var c_hollow = CSGBox3D.new()
	c_hollow.operation = CSGShape3D.OPERATION_SUBTRACTION
	c_hollow.size = Vector3(2.5, 1.9, 4.5)
	c_hollow.position = Vector3(0, 1.05, 0)
	cabin.add_child(c_hollow)
	
	# Left passenger window cutout (Where Protagonist looks out)
	var c_window = CSGBox3D.new()
	c_window.operation = CSGShape3D.OPERATION_SUBTRACTION
	c_window.size = Vector3(0.5, 1.1, 2.4)
	c_window.position = Vector3(-1.3, 1.25, 0.2)
	cabin.add_child(c_window)
	
	# Glass pane
	var glass_pane = CSGBox3D.new()
	glass_pane.size = Vector3(0.04, 1.08, 2.38)
	glass_pane.position = Vector3(-1.26, 1.25, 0.2)
	glass_pane.material = mat_glass
	set_van_interior.add_child(glass_pane)
	
	# Driver seat and Steering Wheel in front
	var driver_seat = CSGBox3D.new()
	driver_seat.size = Vector3(0.9, 0.5, 0.7)
	driver_seat.position = Vector3(-0.5, 0.45, -1.5)
	driver_seat.material = mat_seat
	set_van_interior.add_child(driver_seat)
	
	var wheel = CSGTorus3D.new()
	wheel.inner_radius = 0.15
	wheel.outer_radius = 0.22
	wheel.rotation_degrees = Vector3(45, 0, 0)
	wheel.position = Vector3(-0.5, 0.95, -1.9)
	wheel.material = _create_mat(Color(0.1, 0.1, 0.1))
	set_van_interior.add_child(wheel)
	
	# Driver NPC in uniform
	var driver_npc = _build_rigged_human("VanDriverNPC", Color(0.7, 0.6, 0.35), Color(0.2, 0.2, 0.25), false, false, false, true)
	driver_npc.position = Vector3(-0.5, 0.45, -1.4)
	driver_npc.rotation_degrees = Vector3(0, 180, 0)
	set_van_interior.add_child(driver_npc)
	
	# Passenger seat row (Protagonist sitting by window)
	var p_seat = CSGBox3D.new()
	p_seat.size = Vector3(1.1, 0.45, 0.8)
	p_seat.position = Vector3(-0.6, 0.45, 0.3)
	p_seat.material = mat_seat
	set_van_interior.add_child(p_seat)
	
	var p_seatback = CSGBox3D.new()
	p_seatback.size = Vector3(1.1, 0.8, 0.18)
	p_seatback.position = Vector3(-0.6, 0.95, -0.05)
	p_seatback.material = mat_seat
	set_van_interior.add_child(p_seatback)
	
	# Protagonist sitting by window, resting head, looking outside
	char_player_window = _build_rigged_human("ProtagonistWindow", Color(0.95, 0.95, 0.95), Color(0.18, 0.28, 0.55), false, false, false, true, true)
	char_player_window.position = Vector3(-0.7, 0.45, 0.35)
	char_player_window.rotation_degrees = Vector3(0, 90, 0) # Facing out the window
	set_van_interior.add_child(char_player_window)
	
	# Other school student sitting in back
	var kid_npc = _build_rigged_human("KidPassenger", Color(0.95, 0.95, 0.95), Color(0.18, 0.28, 0.55), false, false, false, true, true)
	kid_npc.position = Vector3(0.5, 0.45, 1.4)
	kid_npc.rotation_degrees = Vector3(0, 180, 0)
	set_van_interior.add_child(kid_npc)
	
	# Moving Scenery outside window (Road, trees, shops scrolling for real motion effect)
	van_scenery_scroll = Node3D.new()
	van_scenery_scroll.name = "VanSceneryScroll"
	van_scenery_scroll.position = Vector3(-8.0, 0, 0)
	set_van_interior.add_child(van_scenery_scroll)
	
	# Road outside window
	var out_road = CSGBox3D.new()
	out_road.size = Vector3(8.0, 0.1, 60.0)
	out_road.position = Vector3(2.0, -0.1, 0)
	out_road.material = _create_mat(Color(0.2, 0.2, 0.22))
	van_scenery_scroll.add_child(out_road)
	
	for i in range(12):
		var t = _create_detailed_forest_tree(true)
		t.position = Vector3(0, 0, -25.0 + (i * 5.0))
		van_scenery_scroll.add_child(t)
		
		# Roadside shops / small houses passing by
		var shop = CSGBox3D.new()
		shop.size = Vector3(4.0, 3.5, 4.5)
		shop.position = Vector3(-4.0, 1.75, -23.0 + (i * 6.5))
		shop.material = _create_mat(Color(0.85, 0.75 + randf()*0.1, 0.6))
		van_scenery_scroll.add_child(shop)

# --- RIGGED HUMAN CHARACTER BUILDER ---
func _build_rigged_human(c_name: String, shirt_col: Color, pant_col: Color, has_bat: bool = false, has_glasses: bool = false, is_female: bool = false, is_sitting: bool = false, has_backpack: bool = false) -> Node3D:
	var root = Node3D.new()
	root.name = c_name
	
	var mat_skin = _create_mat(Color(0.84, 0.66, 0.5))
	var mat_hair = _create_mat(Color(0.1, 0.08, 0.06))
	var mat_shirt = _create_mat(shirt_col)
	var mat_pant = _create_mat(pant_col)
	var mat_shoe = _create_mat(Color(0.12, 0.12, 0.14))
	
	var body = Node3D.new()
	body.name = "Body"
	root.add_child(body)
	
	# Head & Hair
	var head = CSGBox3D.new()
	head.size = Vector3(0.34, 0.38, 0.34)
	head.position = Vector3(0, 1.65, 0)
	head.material = mat_skin
	body.add_child(head)
	
	var hair = CSGBox3D.new()
	hair.size = Vector3(0.38, 0.16, 0.38)
	hair.position = Vector3(0, 1.84, 0)
	hair.material = mat_hair
	body.add_child(hair)
	
	if has_glasses:
		var glasses = CSGBox3D.new()
		glasses.size = Vector3(0.32, 0.08, 0.04)
		glasses.position = Vector3(0, 1.68, 0.18)
		glasses.material = _create_mat(Color(0.08, 0.08, 0.08), 0.2, 0.8)
		body.add_child(glasses)
	
	# Torso
	var torso = CSGBox3D.new()
	torso.size = Vector3(0.55, 0.65, 0.34)
	torso.position = Vector3(0, 1.15, 0)
	torso.material = mat_shirt
	body.add_child(torso)
	
	if has_backpack:
		var bag = CSGBox3D.new()
		bag.size = Vector3(0.42, 0.5, 0.24)
		bag.position = Vector3(0, 1.15, -0.25)
		bag.material = _create_mat(Color(0.15, 0.35, 0.75)) # Blue school backpack
		body.add_child(bag)
	
	# Limbs with dedicated pivots for walking/running rotation
	var arm_l_pivot = Node3D.new()
	arm_l_pivot.name = "ArmL_Pivot"
	arm_l_pivot.position = Vector3(-0.35, 1.4, 0)
	body.add_child(arm_l_pivot)
	var arm_l = CSGBox3D.new()
	arm_l.size = Vector3(0.14, 0.6, 0.14)
	arm_l.position = Vector3(0, -0.3, 0)
	arm_l.material = mat_shirt
	arm_l_pivot.add_child(arm_l)
	
	var arm_r_pivot = Node3D.new()
	arm_r_pivot.name = "ArmR_Pivot"
	arm_r_pivot.position = Vector3(0.35, 1.4, 0)
	body.add_child(arm_r_pivot)
	var arm_r = CSGBox3D.new()
	arm_r.size = Vector3(0.14, 0.6, 0.14)
	arm_r.position = Vector3(0, -0.3, 0)
	arm_r.material = mat_shirt
	arm_r_pivot.add_child(arm_r)
	
	if has_bat:
		var bat = CSGBox3D.new()
		bat.size = Vector3(0.12, 0.75, 0.06)
		bat.position = Vector3(0, -0.5, 0.15)
		bat.material = _create_mat(Color(0.72, 0.58, 0.35))
		arm_r_pivot.add_child(bat)
	
	var leg_l_pivot = Node3D.new()
	leg_l_pivot.name = "LegL_Pivot"
	leg_l_pivot.position = Vector3(-0.16, 0.85, 0)
	body.add_child(leg_l_pivot)
	var leg_l = CSGBox3D.new()
	leg_l.size = Vector3(0.18, 0.75, 0.22)
	leg_l.position = Vector3(0, -0.38, 0)
	leg_l.material = mat_pant
	leg_l_pivot.add_child(leg_l)
	var shoe_l = CSGBox3D.new()
	shoe_l.size = Vector3(0.2, 0.12, 0.3)
	shoe_l.position = Vector3(0, -0.74, 0.05)
	shoe_l.material = mat_shoe
	leg_l_pivot.add_child(shoe_l)
	
	var leg_r_pivot = Node3D.new()
	leg_r_pivot.name = "LegR_Pivot"
	leg_r_pivot.position = Vector3(0.16, 0.85, 0)
	body.add_child(leg_r_pivot)
	var leg_r = CSGBox3D.new()
	leg_r.size = Vector3(0.18, 0.75, 0.22)
	leg_r.position = Vector3(0, -0.38, 0)
	leg_r.material = mat_pant
	leg_r_pivot.add_child(leg_r)
	var shoe_r = CSGBox3D.new()
	shoe_r.size = Vector3(0.2, 0.12, 0.3)
	shoe_r.position = Vector3(0, -0.74, 0.05)
	shoe_r.material = mat_shoe
	leg_r_pivot.add_child(shoe_r)
	
	if is_sitting:
		leg_l_pivot.rotation_degrees = Vector3(-90, 0, 0)
		leg_r_pivot.rotation_degrees = Vector3(-90, 0, 0)
		leg_l.position = Vector3(0, -0.3, 0.3)
		leg_r.position = Vector3(0, -0.3, 0.3)
		body.position.y = -0.35
	
	return root

func _create_detailed_forest_tree(is_morning: bool = false) -> Node3D:
	var tree = Node3D.new()
	var mat_trunk = _create_mat(Color(0.24, 0.15, 0.09) if not is_morning else Color(0.3, 0.2, 0.12))
	var mat_leaf = _create_mat(Color(0.1, 0.22, 0.12) if not is_morning else Color(0.15, 0.42, 0.18))
	
	var trunk = CSGCylinder3D.new()
	trunk.radius = 0.25
	trunk.height = 4.2
	trunk.position = Vector3(0, 2.1, 0)
	trunk.material = mat_trunk
	tree.add_child(trunk)
	
	var crown1 = CSGSphere3D.new()
	crown1.radius = 1.8
	crown1.position = Vector3(0, 4.4, 0)
	crown1.material = mat_leaf
	tree.add_child(crown1)
	
	var crown2 = CSGSphere3D.new()
	crown2.radius = 1.3
	crown2.position = Vector3(0.5, 5.4, 0.3)
	crown2.material = mat_leaf
	tree.add_child(crown2)
	
	return tree

func _build_detailed_school_van() -> Node3D:
	var van = Node3D.new()
	var mat_yellow = _create_mat(Color(0.98, 0.78, 0.04), 0.3)
	var mat_black = _create_mat(Color(0.12, 0.12, 0.14), 0.7)
	var mat_glass = _create_mat(Color(0.15, 0.25, 0.35, 0.5), 0.1, 0.0)
	var mat_light = _create_mat(Color(1, 1, 0.8), 0.1, 0.0, Color(1, 1, 0.7), 3.0)
	
	var body = CSGBox3D.new()
	body.size = Vector3(2.3, 1.9, 4.6)
	body.position = Vector3(0, 1.25, 0)
	body.material = mat_yellow
	van.add_child(body)
	
	var stripe = CSGBox3D.new()
	stripe.size = Vector3(2.35, 0.28, 4.62)
	stripe.position = Vector3(0, 1.05, 0)
	stripe.material = mat_black
	van.add_child(stripe)
	
	var bus_text = Label3D.new()
	bus_text.text = "★ SCHOOL BUS ★"
	bus_text.font_size = 28
	bus_text.modulate = Color(0.05, 0.05, 0.05)
	bus_text.position = Vector3(1.19, 1.5, 0)
	bus_text.rotation_degrees = Vector3(0, 90, 0)
	van.add_child(bus_text)
	
	var windshield = CSGBox3D.new()
	windshield.size = Vector3(2.0, 0.85, 0.1)
	windshield.position = Vector3(0, 1.55, -2.26)
	windshield.material = mat_glass
	van.add_child(windshield)
	
	var hl_l = CSGSphere3D.new()
	hl_l.radius = 0.2
	hl_l.position = Vector3(-0.75, 0.85, -2.3)
	hl_l.material = mat_light
	van.add_child(hl_l)
	
	var hl_r = CSGSphere3D.new()
	hl_r.radius = 0.2
	hl_r.position = Vector3(0.75, 0.85, -2.3)
	hl_r.material = mat_light
	van.add_child(hl_r)
	
	for wp in [Vector3(-1.15, 0.45, -1.4), Vector3(1.15, 0.45, -1.4), Vector3(-1.15, 0.45, 1.4), Vector3(1.15, 0.45, 1.4)]:
		var w = CSGCylinder3D.new()
		w.radius = 0.45
		w.height = 0.32
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = wp
		w.material = mat_black
		van.add_child(w)
	
	return van

# --- CUTSCENE FLOW & PROCEDURAL ANIMATIONS ---
func _start_prologue() -> void:
	if audio_ambience_night:
		audio_ambience_night.play()
	if audio_bgm_song:
		audio_bgm_song.play()
	
	# Start camera looking at friends walking down the Blood Sky road
	cam_pivot.position = Vector3(0, 1.8, 16.0)
	cam.rotation_degrees = Vector3(-8, 0, 0)
	
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	tw.tween_callback(func(): _advance_beat())

func _process(delta: float) -> void:
	anim_time += delta
	
	# 1. Animate walking friends in Act 1
	if current_beat in [0, 1, 2, 3] and char_group_walk:
		_animate_char_walk(char_sahil_walk, anim_time, 5.0)
		_animate_char_walk(char_aashu_walk, anim_time + 0.3, 5.0)
		_animate_char_walk(char_kripal_walk, anim_time + 0.6, 5.0)
		_animate_char_walk(char_player_walk, anim_time + 0.9, 5.0)
		
		# Move group forward down the road
		char_group_walk.position.z -= delta * 1.8
		cam_pivot.position.z -= delta * 1.8
	
	# 2. Swaying trees in the morning / night wind (hawa ke jhoke)
	var wind_sway = sin(anim_time * 2.2) * 0.04
	for tr in street_trees:
		tr.rotation.z = wind_sway
	for ft in forest_trees:
		ft.rotation.z = wind_sway * 0.7
	
	# 3. Animate forest anomaly pulsating light & flares
	if current_beat in [5, 6, 7] and forest_anomaly_light:
		var p = (sin(anim_time * 7.0) + 1.0) * 0.5
		forest_anomaly_light.light_energy = 3.0 + (p * 5.5)
		if forest_anomaly_core:
			forest_anomaly_core.scale = Vector3.ONE * (0.85 + p * 0.45)
	
	# 4. TV Screen light flickering in living room
	if current_beat in [9, 10, 11] and tv_screen_mesh:
		var tv_mat = tv_screen_mesh.material as StandardMaterial3D
		if tv_mat:
			var flick = sin(anim_time * 14.0) * 0.2 + 0.8
			tv_mat.emission_energy_multiplier = 2.0 * flick
	
	# 5. Chai steam rising in kitchen
	if tea_steam_mesh:
		tea_steam_mesh.position.y = 1.35 + (fmod(anim_time * 0.6, 0.4))
		tea_steam_mesh.scale = Vector3.ONE * (0.8 + fmod(anim_time * 0.8, 0.5))
	
	# 6. Sprinting Protagonist in Act 4
	if current_beat == 14 and char_player_sprint and char_player_sprint.visible:
		_animate_char_walk(char_player_sprint, anim_time, 12.0, true) # Fast sprint
		char_player_sprint.position.x -= delta * 4.2
		cam_pivot.position.x -= delta * 3.8
	
	# 7. Van scenery scrolling outside the window in Act 5 (Looking out window)
	if current_beat in [16, 17, 18] and van_scenery_scroll:
		van_scenery_scroll.position.z += delta * 14.0
		if van_scenery_scroll.position.z > 22.0:
			van_scenery_scroll.position.z = -8.0
	
	# Auto advance timer
	if is_beat_active:
		beat_timer += delta
		if beat_timer >= auto_advance_time:
			_advance_beat()

func _animate_char_walk(c: Node3D, t: float, spd: float, is_sprint: bool = false) -> void:
	if not c: return
	var angle = sin(t * spd) * (0.65 if is_sprint else 0.35)
	var l_leg = c.get_node_or_null("Body/LegL_Pivot")
	var r_leg = c.get_node_or_null("Body/LegR_Pivot")
	var l_arm = c.get_node_or_null("Body/ArmL_Pivot")
	var r_arm = c.get_node_or_null("Body/ArmR_Pivot")
	if l_leg: l_leg.rotation.x = angle
	if r_leg: r_leg.rotation.x = -angle
	if l_arm: l_arm.rotation.x = -angle * 0.85
	if r_arm: r_arm.rotation.x = angle * 0.85

func _on_screen_tapped(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_beat()
	elif event is InputEventScreenTouch and event.pressed:
		_advance_beat()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E]):
		_advance_beat()

func _on_skip_pressed() -> void:
	if skipped: return
	skipped = true
	_transition_to_classroom()

func _on_continue_pressed() -> void:
	_transition_to_classroom()

func _transition_to_classroom() -> void:
	is_beat_active = false
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.8)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/classroom.tscn")
	)

func _advance_beat() -> void:
	if skipped: return
	current_beat += 1
	beat_timer = 0.0
	is_beat_active = true
	
	match current_beat:
		# --- ACT 1: WALKING DOWN ROAD UNDER BLOOD SKY (लाल आसमान) ---
		0:
			auto_advance_time = 5.2
			_show_title_card("रात 8:30 PM — लाल आसमान के नीचे", "THE BLOOD SKY ROAD — PANSEMAL")
			_set_dialogue("SAHIL (WALKING ON ROAD)", Color(0.35, 0.85, 0.4),
				"भाई सच में, आज गार्डन में क्रिकेट मैच खेलने में मज़ा आ गया! लेकिन अचानक ये आसमान कितना अजीब लाल हो गया है...",
				"Bhai sach me, aaj garden me cricket match me maza aa gaya! Lekin achanak ye aasman kitna ajeeb laal ho gaya hai...")
			_tween_cam(Vector3(0, 1.8, 16.0), Vector3(-6, -10, 0), 4.8)
			
		1:
			auto_advance_time = 5.2
			_hide_title_card()
			_set_dialogue("AASHUTOSH", Color(0.95, 0.65, 0.3),
				"हाँ यार, मौसम अचानक बहुत अजीब लग रहा है जैसे कोई तूफ़ान आने वाला हो... और 8:30 भी बज गए, कल सुबह स्कूल है।",
				"Haan yaar, mausam achanak bohot ajeeb lag raha hai jaise koi toofan aane wala ho... Aur 8:30 bhi baj gaye, kal subah school hai.")
			_tween_cam(Vector3(-0.6, 1.7, 14.5), Vector3(-5, -25, 0), 4.8)
			
		2:
			auto_advance_time = 5.5
			_set_dialogue("PROTAGONIST (YOU)", Color(0.4, 0.75, 1.0),
				"कृपाल, तू अकेले जंगल वाले रास्ते से जाता है ना? वहाँ तो दिन में भी अँधेरा रहता है, तू मेन रोड से घूम के चला जा ना?",
				"Kripal, tu akele jungle wale raste se jata hai na? Wahan to din me bhi andhera rehta hai, tu highway se ghoom ke chala ja na?")
			_tween_cam(Vector3(0.6, 1.7, 13.0), Vector3(-6, 20, 0), 5.0)
			
		3:
			auto_advance_time = 5.5
			_set_dialogue("KRIPAL", Color(1.0, 0.35, 0.35),
				"अरे भाई तुम सब इतना डरते क्यों हो? मैं तो बचपन से इसी शॉर्टकट से निकलता हूँ। कुछ नहीं होता! कल सुबह वैन में मिलते हैं!",
				"Arrey bhai tum sab itna darte kyu ho? Main to bachpan se isi shortcut se nikalta hoon. Kuchh nahi hota! Kal subah van me milte hain!")
			_tween_cam(Vector3(0.4, 1.65, 10.5), Vector3(-4, -40, 0), 5.0)
			
		4:
			# Parting ways at the crossroads signpost
			auto_advance_time = 4.5
			_set_dialogue("CROSSROADS (तीराहा)", Color(0.85, 0.85, 0.9),
				"चारों दोस्त तीराहे पर अलग हो गए... साहिल-आशुतोष बाएँ मुड़े, और कृपाल घने अंधेरे जंगल की तरफ चल पड़ा...",
				"The four friends parted ways at the crossroads... Kripal took the dark path into the dense forest...")
			
			var tw = create_tween().set_parallel(true)
			tw.tween_property(char_sahil_walk, "position:x", -8.0, 4.0)
			tw.tween_property(char_aashu_walk, "position:x", -7.0, 4.0)
			tw.tween_property(char_player_walk, "position:x", 8.0, 4.0)
			tw.tween_property(char_kripal_walk, "position:z", -12.0, 4.0)
			_tween_cam(Vector3(0, 3.2, 8.0), Vector3(-20, 0, 0), 4.0)
			
		# --- ACT 2: DENSE FOREST & GLOWING ANOMALY (पूरा घना जंगल का मैप) ---
		5:
			auto_advance_time = 5.2
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(200, 1.8, 12.0)
				cam.rotation_degrees = Vector3(-8, 0, 0)
			)
			_set_dialogue("DENSE FOREST — 8:45 PM", Color(0.6, 0.85, 1.0),
				"रात का गहरा सन्नाटा... पेड़ों के बीच ठंडी हवा की सरसराहट... कृपाल अकेला जंगल के रास्ते पर चल रहा था...",
				"The deep silence of the forest... cold wind rustling ancient trees... Kripal walks alone along the dark dirt trail...")
			
		6:
			auto_advance_time = 5.8
			if audio_whisper: audio_whisper.play()
			_set_dialogue("KRIPAL", Color(1.0, 0.4, 0.4),
				"ये... ये जंगल के इतने अंदर ऐसी अजीब नीली रौशनी कहाँ से आ रही है...? यहाँ तो कोई खंभा भी नहीं है...",
				"Ye... ye jungle ke itne andar aisi ajeeb neeli roshni kahan se aa rahi hai...? Yahan to koi khamba bhi nahi hai...")
			_tween_cam(Vector3(203.5, 1.9, 0.0), Vector3(-6, 45, 0), 5.2)
			
		7:
			auto_advance_time = 4.8
			if audio_jumpscare: audio_jumpscare.play()
			if audio_heartbeat: audio_heartbeat.play()
			_set_dialogue("KRIPAL", Color(1.0, 0.2, 0.2),
				"न-नहीं... ये क्या चीज़ है?!! ये तो मेरी तरफ बढ़ रही है!! मुझे भागना होगा!!",
				"N-Nahi... Ye kya cheez hai?!! Ye to meri taraf badh rahi hai!! Mujhe bhagna hoga!!")
			
			# Camera shake
			var tw_shk = create_tween()
			for i in range(8):
				tw_shk.tween_property(cam, "position", Vector3(randf_range(-0.18, 0.18), randf_range(-0.18, 0.18), 0), 0.05)
			tw_shk.tween_property(cam, "position", Vector3.ZERO, 0.1)
			
		8:
			auto_advance_time = 4.5
			_set_dialogue("KRIPAL'S PANIC SPRINT", Color(0.9, 0.8, 0.3),
				"कृपाल बदहवास हालत में सरपट भागते हुए जंगल से बाहर निकला और अपने घर का दरवाजा धड़ाम से बंद कर लिया!",
				"In sheer terror, Kripal sprinted out of the woods, reached his house porch and slammed the door shut!")
			
			var tw_run = create_tween()
			tw_run.tween_property(char_kripal_forest, "position:z", -15.0, 3.2)
			tw_run.tween_callback(func():
				if audio_door_open: audio_door_open.play()
				char_kripal_forest.visible = false
			)
			
		# --- ACT 3: FULL HOUSE (Papa watching TV in Hall, Mummy cooking in Kitchen, Bedroom) ---
		9:
			auto_advance_time = 5.2
			if audio_ambience_night and audio_ambience_night.playing: audio_ambience_night.stop()
			if audio_heartbeat and audio_heartbeat.playing: audio_heartbeat.stop()
			if audio_ambience_morning: audio_ambience_morning.play()
			
			# Shift environment from Blood Sky to bright morning
			world_env.environment = morning_sky_env
			blood_sky_light.visible = false
			sun_light.visible = true
			
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(395.5, 1.6, 2.8) # Living room view looking at Papa & TV
				cam.rotation_degrees = Vector3(-8, -25, 0)
			)
			
			_show_title_card("अगली सुबह — 7:15 AM", "PROTAGONIST'S HOUSE — LIVING ROOM & KITCHEN")
			_set_dialogue("PAPA (LIVING ROOM MEIN TV DEKHTE HUE)", Color(1.0, 0.85, 0.35),
				"अरे बेटा! 7:15 हो गए... उठ जाओ जल्दी! आज फिर स्कूल वैन के लिए दौड़ना पड़ेगा!",
				"Arrey beta! 7:15 ho gaye... Uth jao jaldi! Aaj phir school van ke liye daudna padega!")
			
		10:
			auto_advance_time = 5.2
			_hide_title_card()
			# Pan camera to Kitchen looking at Mummy cooking chai
			_tween_cam(Vector3(404.5, 1.5, -1.8), Vector3(-6, -110, 0), 4.8)
			_set_dialogue("MUMMY (KITCHEN SE CHAI BANATE HUE)", Color(1.0, 0.45, 0.55),
				"चाय बन गई है! पहले मुँह-हाथ धो लो और स्कूल यूनिफॉर्म पहनो! वैन किसी भी वक्त आती होगी!",
				"Chai ban gayi hai! Pehle muh-haath dho lo aur school uniform pehno! Van kisi bhi waqt aati hogi!")
			
		11:
			auto_advance_time = 5.0
			# Float camera upstairs into Protagonist's sunny bedroom
			_tween_cam(Vector3(395.2, 4.4, 2.2), Vector3(-14, 35, 0), 4.5)
			
			# Protagonist sits up on bed
			var tw_bed = create_tween()
			tw_bed.tween_property(char_player_bed, "rotation_degrees:x", 0.0, 1.8)
			
			_set_dialogue("PROTAGONIST (BEDROOM MEIN UTH TE HUE)", Color(0.4, 0.75, 1.0),
				"हाँ पापा, हाँ मम्मी! बस 5 मिनट... उठ रहा हूँ! चाय ला रहा हूँ नीचे...",
				"Haan Papa, haan Mummy! Bas 5 minute... uth raha hoon! Chai la raha hoon neeche...")
			
		# --- ACT 4: NEIGHBORHOOD MAP, VAN ARRIVAL & RUNNING ANIMATION ---
		12:
			auto_advance_time = 5.5
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(600, 2.2, 8.0) # Street view outside house
				cam.rotation_degrees = Vector3(-10, 0, 0)
			)
			if audio_van_horn: audio_van_horn.play()
			
			_set_dialogue("SCHOOL VAN DRIVER UNCLE (BEEP BEEP!)", Color(1.0, 0.88, 0.2),
				"भाभी जी! जल्दी भेजो ना बच्चे को! 7:35 हो गए हैं, आगे कृपाल और बाकी बच्चों को भी लेना है... लेट हो रहा है!",
				"Bhabhi ji! Jaldi bhejo na bachhe ko! 7:35 ho gaye hain, aage Kripal aur baki bachhon ko bhi lena hai... late ho raha hai!")
			
		13:
			auto_advance_time = 4.8
			_set_dialogue("PROTAGONIST", Color(0.4, 0.75, 1.0),
				"अरे बाप रे! वैन तो आ भी गई! जुराबें कहाँ गईं... जल्दी बैग पकड़ो!",
				"Arey baap re! Van to aa bhi gayi! Jurabein kahan gayin... jaldi bag pakdo!")
			
			# Front door swings open
			var tw_door = create_tween()
			tw_door.tween_property(front_door_mesh, "rotation_degrees:y", 85.0, 1.2)
			
		14:
			# Live 3D Sprinting sequence across the front yard to the van
			auto_advance_time = 5.2
			char_player_sprint.visible = true
			_tween_cam(Vector3(603.5, 1.8, 3.5), Vector3(-6, -45, 0), 4.5)
			_set_dialogue("PROTAGONIST RUNNING TO VAN", Color(0.35, 0.85, 0.95),
				"\"गुड मॉर्निंग भैया! सॉरी आज थोड़ा लेट हो गया...\"\n— ड्राइवर: \"रोज़ का यही है तुम्हारा... चलो बैठो जल्दी, दरवाजा लगाओ!\"",
				"\"Good morning bhaiya! Sorry aaj thoda late ho gaya...\"\n— Driver: \"Roz ka yahi naatak hai tumhara... chalo baitho jaldi, darwaja lagao!\"")
			
		# --- ACT 5: VAN INTERIOR & WINDOW GAZING SCENE (SONG / BGM SLOT) ---
		15:
			auto_advance_time = 5.5
			if audio_door_close: audio_door_close.play()
			if audio_van_engine: audio_van_engine.play()
			
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(800.8, 1.3, -0.6) # Inside van looking at driver & road ahead
				cam.rotation_degrees = Vector3(0, 180, 0)
			)
			_set_dialogue("INSIDE SCHOOL VAN (वैन चल पड़ी)", Color(1.0, 0.85, 0.3),
				"वैन का दरवाजा बंद हुआ... इंजन की आवाज़ के साथ वैन सुबह की धूप में सड़कों पर आगे बढ़ी...",
				"The van door slid shut... with the hum of the engine, the school van drove forward down the sunny streets...")
			
		16:
			# The Iconic Window Gazing Shot (Dedicated Song / BGM Scene)
			auto_advance_time = 6.5
			_tween_cam(Vector3(799.3, 1.25, 0.35), Vector3(0, -90, 0), 4.5) # Looking right past Protagonist out the moving window
			
			_set_dialogue("PROTAGONIST (LOOKING OUT THE WINDOW)", Color(0.4, 0.8, 1.0),
				"खिड़की से बाहर सुबह की ठंडी हवा, पेड़ और घर पीछे छूट रहे हैं... और वैन कृपाल के घर की तरफ मुड़ रही है...",
				"Looking out the window as morning breeze, trees and houses rush past... the van turns towards Kripal's street...")
			
		17:
			auto_advance_time = 6.0
			_set_dialogue("PROTAGONIST (मन में सोचते हुए)", Color(0.4, 0.75, 1.0),
				"पर अजीब बात है... कल रात से कृपाल का फोन स्विच ऑफ क्यों आ रहा है...? क्या रात को सच में कुछ हुआ था...?",
				"Par ajeeb baat hai... kal raat se Kripal ka phone switch off kyu aa raha hai...? Kya raat ko sach me kuchh hua tha...?")
			
		18:
			auto_advance_time = 5.2
			_set_dialogue("VAN DRIVER", Color(1.0, 0.85, 0.2),
				"देखते हैं आज कृपाल तैयार मिलता है या वो भी सोता ही मिलेगा...",
				"Dekhte hain aaj Kripal taiyaar milta hai ya wo bhi sota hi milega...")
			
		19:
			# Final Suspense Chapter Card
			auto_advance_time = 999.0
			continue_btn.visible = true
			_set_dialogue("PROLOGUE COMPLETE (प्रस्तावना समाप्त)", Color(1.0, 0.9, 0.4),
				"वैन कृपाल के घर के सामने पहुँचती है... पर घर का खुला दरवाज़ा और सन्नाटा देखकर सबके होश उड़ जाते हैं...",
				"The van arrives outside Kripal's house... but the open door and eerie silence shocks everyone...")
			_show_title_card("CHAPTER 1: THE DISAPPEARANCE", "गायब कृपाल — कहानी शुरू होती है...")

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

func _tween_cam(target_pos: Vector3, target_rot: Vector3, duration: float) -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(cam_pivot, "position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "rotation_degrees", target_rot, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _fade_to_black_and_call(callback: Callable) -> void:
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.45)
	tw.tween_callback(callback)
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.6)
