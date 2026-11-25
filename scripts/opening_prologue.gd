extends Node3D

# ==============================================================================
# CINEMATIC OPENING PROLOGUE — HORROR MISSION (DELUXE CINEMATIC EDITION)
# ==============================================================================
# Perfectly Synced Audio & Cinematics:
# 1. Walk under Blood Sky with follow cam & limb walking animations.
# 2. Halt & Switch to FIRST-PERSON (FP) MODE looking directly at friends
#    with exact matching native Hindi voice lines!
# 3. Clean wide road parting sequence.
# 4. Dense forest with clearing: Kripal stops, looks directly at the brilliant
#    pulsing anomaly in front of him, anomaly surges with scare audio, Kripal
#    sprints in full panic.
# 5. Extended House Sequence:
#    - Bedroom: Sleeping in bed under quilt, ceiling fan spinning, morning light.
#    - Hall: Papa on sofa watching TV with remote, calling out (with voice!).
#    - Kitchen: Mummy stirring boiling chai at stove with steam, calling (with voice!).
#    - Bedroom: Waking up, stretching, answering (with voice!).
# 6. Neighborhood street: Van arrives, horn blares, driver calls (with voice!),
#    Protagonist in uniform sprints across yard to the van.
# 7. Authentic Indian school van interior: Rexine seats, driver, kids, sliding window
#    with 3 horizontal metal safety bars, scrolling morning scenery, and song slot.
# 8. NO mobile controls on screen — only the clean [SKIP ⏭️] button!
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
var fp_crosshair: Label

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
var audio_voice: AudioStreamPlayer
var audio_bgm_song: AudioStreamPlayer
var audio_title_voice: AudioStreamPlayer

# Sets
var set_blood_road: Node3D
var set_dense_forest: Node3D
var set_full_house: Node3D
var set_neighborhood_street: Node3D
var set_van_interior: Node3D

# Characters & Objects
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
var char_player_sleeping: Node3D
var ceiling_fan_blades: Node3D
var tv_screen_mesh: CSGBox3D
var tea_steam_mesh: MeshInstance3D

var char_player_sprint: Node3D
var front_door_mesh: CSGBox3D
var front_door_pivot: Node3D
var gate_pivot_l: Node3D
var gate_pivot_r: Node3D
var van_passenger_door: Node3D
var school_van_exterior: Node3D
var street_trees: Array = []

var char_player_window: Node3D
var van_scenery_scroll: Node3D
var van_fan_blades: Node3D
var jumpscare_flash_rect: TextureRect

var title_splash_root: Control
var title_splash_bg: ColorRect
var title_content: Control
var title_blood_splatter: TextureRect
var title_horror_label: Label
var title_credits_label: Label
var is_title_splash_active: bool = true

func _ready() -> void:
	# Enforce hiding mobile controls during prologue
	_hide_external_controls()
	
	_build_ui()
	_setup_lighting_and_environments()
	_setup_audio()
	_build_all_3d_sets()
	_start_prologue()

func _hide_external_controls() -> void:
	var cp = get_node_or_null("/root/CheckpointManager")
	if cp and "mobile_controls_root" in cp and cp.mobile_controls_root:
		cp.mobile_controls_root.visible = false

# --- UI CREATION (Only Letterbox, Subtitles & SKIP button) ---
func _build_ui() -> void:
	ui_root = CanvasLayer.new()
	ui_root.layer = 10
	add_child(ui_root)
	
	# Cinematic Horror Camera Vignette Overlay
	var vignette_rect = TextureRect.new()
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vig_tex = load("res://textures/vignette.png")
	if vig_tex:
		vignette_rect.texture = vig_tex
		vignette_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vignette_rect.stretch_mode = TextureRect.STRETCH_SCALE
		vignette_rect.modulate = Color(1.0, 1.0, 1.0, 0.65)
		ui_root.add_child(vignette_rect)
	
	# Letterbox Top
	letterbox_top = ColorRect.new()
	letterbox_top.color = Color(0, 0, 0, 1)
	letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	letterbox_top.custom_minimum_size = Vector2(0, 72)
	letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(letterbox_top)
	
	# Letterbox Bottom
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
	
	# First-Person Crosshair indicator (Subtle center dot during FP mode)
	fp_crosshair = Label.new()
	fp_crosshair.text = "•"
	fp_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fp_crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fp_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	fp_crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	fp_crosshair.add_theme_font_size_override("font_size", 22)
	fp_crosshair.visible = false
	ui_root.add_child(fp_crosshair)
	
	# Clean SKIP Button (Top Right)
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
	
	# Continue Button (Final card)
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
	
	# Jumpscare Horror Flash Overlay (Beat 8 Forest Anomaly)
	jumpscare_flash_rect = TextureRect.new()
	jumpscare_flash_rect.set_anchors_preset(Control.PRESET_CENTER)
	jumpscare_flash_rect.offset_left = -260
	jumpscare_flash_rect.offset_top = -260
	jumpscare_flash_rect.offset_right = 260
	jumpscare_flash_rect.offset_bottom = 260
	jumpscare_flash_rect.pivot_offset = Vector2(260, 260)
	jumpscare_flash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jumpscare_flash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	jumpscare_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jumpscare_flash_rect.visible = false
	ui_root.add_child(jumpscare_flash_rect)
	
	# Fade Overlay
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade_overlay)
	
	# Opening Blood Title Splash Screen (THE HORROR MISSION + Credits)
	title_splash_root = Control.new()
	title_splash_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_splash_root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_root.add_child(title_splash_root)
	
	title_splash_bg = ColorRect.new()
	title_splash_bg.color = Color(0, 0, 0, 1)
	title_splash_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_splash_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	title_splash_root.add_child(title_splash_bg)
	
	# CenterContainer guarantees exact center positioning on ALL resolutions and mobile screens!
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_splash_root.add_child(center_container)
	
	title_content = Control.new()
	title_content.custom_minimum_size = Vector2(920, 320)
	title_content.pivot_offset = Vector2(460, 160)
	title_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_container.add_child(title_content)
	
	# Blood Splatter Backdrop behind "THE HORROR MISSION"
	title_blood_splatter = TextureRect.new()
	var splatter_tex = _load_texture("res://textures/blood_title_splatter.png")
	if splatter_tex:
		title_blood_splatter.texture = splatter_tex
	title_blood_splatter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_blood_splatter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_blood_splatter.position = Vector2(10, 20)
	title_blood_splatter.size = Vector2(900, 250)
	title_blood_splatter.pivot_offset = Vector2(450, 125)
	title_blood_splatter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_blood_splatter.modulate.a = 0.0 # Starts hidden, fades in with blood
	title_content.add_child(title_blood_splatter)
	
	# Blood Red Title Label: "THE HORROR MISSION" (Letter-by-letter reveal)
	title_horror_label = Label.new()
	title_horror_label.text = "THE HORROR MISSION"
	title_horror_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_horror_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_horror_label.position = Vector2(10, 60)
	title_horror_label.size = Vector2(900, 75)
	title_horror_label.pivot_offset = Vector2(450, 37)
	title_horror_label.add_theme_font_size_override("font_size", 48)
	title_horror_label.add_theme_color_override("font_color", Color(0.92, 0.08, 0.08))
	title_horror_label.add_theme_color_override("font_shadow_color", Color(0.22, 0.0, 0.0, 0.95))
	title_horror_label.add_theme_constant_override("shadow_offset_x", 4)
	title_horror_label.add_theme_constant_override("shadow_offset_y", 4)
	title_horror_label.add_theme_color_override("font_outline_color", Color(0.38, 0.01, 0.01))
	title_horror_label.add_theme_constant_override("outline_size", 5)
	title_horror_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_horror_label.visible_characters = 0
	title_content.add_child(title_horror_label)
	
	# Clean White Credits Subtitle: "Created By Sahil and Written By Aashutosh" (Letter-by-letter reveal)
	title_credits_label = Label.new()
	title_credits_label.text = "Created By Sahil and Written By Aashutosh"
	title_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_credits_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_credits_label.position = Vector2(10, 160)
	title_credits_label.size = Vector2(900, 45)
	title_credits_label.pivot_offset = Vector2(450, 22)
	title_credits_label.add_theme_font_size_override("font_size", 20)
	title_credits_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 0.95))
	title_credits_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	title_credits_label.add_theme_constant_override("shadow_offset_x", 2)
	title_credits_label.add_theme_constant_override("shadow_offset_y", 2)
	title_credits_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_credits_label.visible_characters = 0
	title_content.add_child(title_credits_label)
	
	# Tap to Skip Hint
	var tap_hint = Label.new()
	tap_hint.text = "• TAP ANYWHERE TO CONTINUE •"
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tap_hint.position = Vector2(10, 235)
	tap_hint.size = Vector2(900, 30)
	tap_hint.add_theme_font_size_override("font_size", 12)
	tap_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 0.35))
	tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_content.add_child(tap_hint)

# --- LIGHTING & ENVIRONMENTS ---
func _setup_lighting_and_environments() -> void:
	blood_sky_env = Environment.new()
	blood_sky_env.background_mode = Environment.BG_COLOR
	blood_sky_env.background_color = Color(0.32, 0.05, 0.05)
	blood_sky_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	blood_sky_env.ambient_light_color = Color(0.52, 0.16, 0.14)
	blood_sky_env.ambient_light_energy = 0.85
	blood_sky_env.fog_enabled = true
	blood_sky_env.fog_light_color = Color(0.38, 0.08, 0.08)
	blood_sky_env.fog_density = 0.016
	
	# AAA ACES Filmic Tonemapping for Blood Sky
	blood_sky_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	blood_sky_env.tonemap_exposure = 1.05
	blood_sky_env.tonemap_white = 1.15
	
	# Glowing Supernatural Bloom for Anomaly & Streetlights
	blood_sky_env.glow_enabled = true
	blood_sky_env.glow_intensity = 0.65
	blood_sky_env.glow_strength = 0.90
	blood_sky_env.glow_bloom = 0.28
	blood_sky_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	blood_sky_env.glow_hdr_threshold = 1.0
	
	# Screen Space Ambient Occlusion for deep contact shadows in forest and corners
	blood_sky_env.ssao_enabled = true
	blood_sky_env.ssao_radius = 1.8
	blood_sky_env.ssao_intensity = 2.4
	blood_sky_env.ssao_power = 1.5
	blood_sky_env.ssao_detail = 0.5
	
	# Filmic Color Grading
	blood_sky_env.adjustment_enabled = true
	blood_sky_env.adjustment_brightness = 1.02
	blood_sky_env.adjustment_contrast = 1.18
	blood_sky_env.adjustment_saturation = 1.12
	
	morning_sky_env = Environment.new()
	morning_sky_env.background_mode = Environment.BG_COLOR
	morning_sky_env.background_color = Color(0.68, 0.84, 0.98)
	morning_sky_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	morning_sky_env.ambient_light_color = Color(0.92, 0.9, 0.85)
	morning_sky_env.ambient_light_energy = 1.15
	morning_sky_env.fog_enabled = true
	morning_sky_env.fog_light_color = Color(0.85, 0.9, 0.95)
	morning_sky_env.fog_density = 0.005
	
	# AAA ACES Filmic Tonemapping for Morning Sky
	morning_sky_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	morning_sky_env.tonemap_exposure = 1.08
	morning_sky_env.tonemap_white = 1.20
	morning_sky_env.glow_enabled = true
	morning_sky_env.glow_intensity = 0.40
	morning_sky_env.glow_bloom = 0.15
	morning_sky_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	morning_sky_env.ssao_enabled = true
	morning_sky_env.ssao_radius = 1.6
	morning_sky_env.ssao_intensity = 2.0
	morning_sky_env.adjustment_enabled = true
	morning_sky_env.adjustment_brightness = 1.04
	morning_sky_env.adjustment_contrast = 1.12
	morning_sky_env.adjustment_saturation = 1.08
	
	world_env = WorldEnvironment.new()
	world_env.environment = blood_sky_env
	add_child(world_env)
	
	blood_sky_light = DirectionalLight3D.new()
	blood_sky_light.light_color = Color(0.98, 0.38, 0.28)
	blood_sky_light.light_energy = 1.3
	blood_sky_light.rotation_degrees = Vector3(-35, 45, 0)
	blood_sky_light.shadow_enabled = true
	blood_sky_light.shadow_blur = 1.5
	add_child(blood_sky_light)
	
	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.95, 0.8)
	sun_light.light_energy = 1.4
	sun_light.rotation_degrees = Vector3(-38, -40, 0)
	sun_light.shadow_enabled = true
	sun_light.shadow_blur = 1.4
	sun_light.visible = false
	add_child(sun_light)
	
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
	var js_stream = _load_audio("res://audio/scary_jumpscare_impact.mp3")
	if not js_stream: js_stream = _load_audio("res://audio/jumpscare.wav")
	audio_jumpscare.stream = js_stream
	audio_jumpscare.volume_db = 5.0
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
	
	# Dedicated Voice Line Player
	audio_voice = AudioStreamPlayer.new()
	audio_voice.volume_db = 3.5
	audio_root.add_child(audio_voice)
	
	# Dedicated Song / BGM slot (Plays continuously from start until classroom is entered)
	audio_bgm_song = AudioStreamPlayer.new()
	audio_bgm_song.volume_db = -2.5
	var song_stream = _load_audio("res://audio/prologue_bgm.mp3")
	if not song_stream: song_stream = _load_audio("res://audio/prologue_song.mp3")
	if not song_stream: song_stream = _load_audio("res://audio/bhangarh_ambience.wav")
	audio_bgm_song.stream = song_stream
	audio_bgm_song.finished.connect(func():
		if is_instance_valid(audio_bgm_song) and is_inside_tree():
			audio_bgm_song.play()
	)
	audio_root.add_child(audio_bgm_song)
	
	# Dedicated Title Screen Voice Player
	audio_title_voice = AudioStreamPlayer.new()
	audio_title_voice.volume_db = 4.0
	audio_title_voice.stream = _load_audio("res://audio/title_voice.wav")
	audio_root.add_child(audio_title_voice)

func _play_voice(path: String) -> void:
	var st = _load_audio(path)
	if st and audio_voice:
		audio_voice.stream = st
		audio_voice.play()

func _load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			return ImageTexture.create_from_image(img)
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

# --- PROCEDURAL PBR TEXTURES (ASPHALT, SIDEWALK, SOIL, BARK) ---
func _create_asphalt_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.14)
	mat.roughness = 0.74
	var fn = FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fn.frequency = 0.14
	var nt = NoiseTexture2D.new()
	nt.width = 128
	nt.height = 128
	nt.noise = fn
	nt.as_normal_map = true
	nt.bump_strength = 3.2
	mat.normal_enabled = true
	mat.normal_texture = nt
	mat.uv1_scale = Vector3(8.0, 8.0, 8.0)
	return mat

func _create_sidewalk_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.26, 0.24, 0.22)
	mat.roughness = 0.82
	var fn = FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_PERLIN
	fn.frequency = 0.18
	var nt = NoiseTexture2D.new()
	nt.width = 128
	nt.height = 128
	nt.noise = fn
	nt.as_normal_map = true
	nt.bump_strength = 2.4
	mat.normal_enabled = true
	mat.normal_texture = nt
	mat.uv1_scale = Vector3(6.0, 6.0, 6.0)
	return mat

func _create_forest_soil_material(col: Color = Color(0.08, 0.07, 0.05), uv_scale: float = 8.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.92
	var fn = FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.16
	var nt = NoiseTexture2D.new()
	nt.width = 128
	nt.height = 128
	nt.noise = fn
	nt.as_normal_map = true
	nt.bump_strength = 3.5
	mat.normal_enabled = true
	mat.normal_texture = nt
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	return mat

func _create_tree_bark_material(col: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.88
	var fn = FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_PERLIN
	fn.frequency = 0.25
	var nt = NoiseTexture2D.new()
	nt.width = 128
	nt.height = 128
	nt.noise = fn
	nt.as_normal_map = true
	nt.bump_strength = 3.8
	mat.normal_enabled = true
	mat.normal_texture = nt
	mat.uv1_scale = Vector3(2.0, 6.0, 2.0)
	return mat

# --- 3D SETS BUILDER ---
func _build_all_3d_sets() -> void:
	_build_act1_blood_sky_road()
	_build_act2_dense_forest()
	_build_act3_full_house()
	_build_act4_neighborhood_van()
	_build_act5_van_interior()

# ------------------------------------------------------------------------------
# ACT 1: BLOOD SKY ROAD (Follow Camera Walk -> Halt & FP Mode -> Clean Road Parting)
# ------------------------------------------------------------------------------
func _build_act1_blood_sky_road() -> void:
	set_blood_road = Node3D.new()
	set_blood_road.name = "Set_BloodRoad"
	set_blood_road.position = Vector3(0, 0, 0)
	add_child(set_blood_road)
	
	var mat_road = _create_asphalt_material()
	var mat_sidewalk = _create_sidewalk_material()
	var mat_pole = _create_mat(Color(0.2, 0.2, 0.22), 0.5, 0.7)
	var mat_glow = _create_mat(Color(1.0, 0.85, 0.4), 0.2, 0.0, Color(1.0, 0.8, 0.3), 3.0)
	
	# Main Clear Asphalt Road (80 meters long)
	var road = CSGBox3D.new()
	road.size = Vector3(8.0, 0.1, 80.0)
	road.position = Vector3(0, -0.05, 0.0)
	road.material = mat_road
	set_blood_road.add_child(road)
	
	# Clean Yellow Lane Dashes
	for z in range(-35, 38, 6):
		var dash = CSGBox3D.new()
		dash.size = Vector3(0.22, 0.11, 2.8)
		dash.position = Vector3(0, 0.01, z)
		dash.material = _create_mat(Color(0.9, 0.82, 0.25))
		set_blood_road.add_child(dash)
	
	# Sidewalks
	var sw_l = CSGBox3D.new()
	sw_l.size = Vector3(3.0, 0.25, 80.0)
	sw_l.position = Vector3(-5.5, 0.02, 0.0)
	sw_l.material = mat_sidewalk
	set_blood_road.add_child(sw_l)
	
	var sw_r = CSGBox3D.new()
	sw_r.size = Vector3(3.0, 0.25, 80.0)
	sw_r.position = Vector3(5.5, 0.02, 0.0)
	sw_r.material = mat_sidewalk
	set_blood_road.add_child(sw_r)
	
	# Streetlights
	for z in [-25, -10, 5, 20, 35]:
		var pole = CSGCylinder3D.new()
		pole.radius = 0.07
		pole.height = 5.2
		pole.position = Vector3(-4.5, 2.6, z)
		pole.material = mat_pole
		set_blood_road.add_child(pole)
		
		var lamp = CSGSphere3D.new()
		lamp.radius = 0.32
		lamp.position = Vector3(-4.3, 5.1, z)
		lamp.material = mat_glow
		set_blood_road.add_child(lamp)
		
		var light = OmniLight3D.new()
		light.position = Vector3(-4.3, 4.9, z)
		light.omni_range = 13.0
		light.light_energy = 2.0
		light.light_color = Color(1.0, 0.85, 0.5)
		light.shadow_enabled = true
		set_blood_road.add_child(light)
	
	# 3-Way Branching Roads at crossroads (z = -25)
	var road_branch_l = CSGBox3D.new()
	road_branch_l.size = Vector3(30.0, 0.1, 7.0)
	road_branch_l.position = Vector3(-18.0, -0.05, -25.0)
	road_branch_l.material = mat_road
	set_blood_road.add_child(road_branch_l)
	
	var road_branch_r = CSGBox3D.new()
	road_branch_r.size = Vector3(30.0, 0.1, 7.0)
	road_branch_r.position = Vector3(18.0, -0.05, -25.0)
	road_branch_r.material = mat_road
	set_blood_road.add_child(road_branch_r)
	
	var forest_entrance = CSGBox3D.new()
	forest_entrance.size = Vector3(6.5, 0.1, 30.0)
	forest_entrance.position = Vector3(0, -0.05, -45.0)
	forest_entrance.material = _create_mat(Color(0.1, 0.08, 0.06))
	set_blood_road.add_child(forest_entrance)
	
	# Signpost at crossroads
	var sign_pole = CSGCylinder3D.new()
	sign_pole.radius = 0.08
	sign_pole.height = 3.5
	sign_pole.position = Vector3(3.5, 1.75, -25.0)
	sign_pole.material = mat_pole
	set_blood_road.add_child(sign_pole)
	
	var sign_board = Label3D.new()
	sign_board.text = "⬅ SAHIL & AASHU (TOWN)  |  KRIPAL'S SHORTCUT (FOREST) ⬆  |  YOUR HOME ➡"
	sign_board.font_size = 22
	sign_board.modulate = Color(1.0, 0.9, 0.35)
	sign_board.position = Vector3(3.5, 3.4, -25.0)
	set_blood_road.add_child(sign_board)
	
	# Walking Group
	char_group_walk = Node3D.new()
	char_group_walk.name = "FriendsWalkingGroup"
	char_group_walk.position = Vector3(0, 0, 24.0)
	set_blood_road.add_child(char_group_walk)
	
	char_sahil_walk = _build_rigged_human("Sahil", Color(0.2, 0.6, 0.3), Color(0.18, 0.18, 0.22), true) # Cricket bat
	char_sahil_walk.position = Vector3(-1.4, 0, -1.0)
	char_group_walk.add_child(char_sahil_walk)
	
	char_aashu_walk = _build_rigged_human("Aashutosh", Color(0.68, 0.42, 0.2), Color(0.22, 0.22, 0.25))
	char_aashu_walk.position = Vector3(-0.4, 0, -0.5)
	char_group_walk.add_child(char_aashu_walk)
	
	char_kripal_walk = _build_rigged_human("Kripal", Color(0.82, 0.25, 0.2), Color(0.18, 0.2, 0.3), false, true) # Glasses
	char_kripal_walk.position = Vector3(0.6, 0, -1.2)
	char_group_walk.add_child(char_kripal_walk)
	
	char_player_walk = _build_rigged_human("Protagonist", Color(0.25, 0.45, 0.8), Color(0.15, 0.15, 0.18))
	char_player_walk.position = Vector3(1.4, 0, 0.0)
	char_group_walk.add_child(char_player_walk)

# ------------------------------------------------------------------------------
# ACT 2: DENSE FOREST WITH DIRECT CLEAR LINE-OF-SIGHT TO ANOMALY
# ------------------------------------------------------------------------------
func _build_act2_dense_forest() -> void:
	set_dense_forest = Node3D.new()
	set_dense_forest.name = "Set_DenseForest"
	set_dense_forest.position = Vector3(200, 0, 0)
	add_child(set_dense_forest)
	
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(60.0, 0.2, 70.0)
	floor_mesh.position = Vector3(0, -0.1, 0)
	floor_mesh.material = _create_forest_soil_material(Color(0.06, 0.05, 0.04), 10.0)
	set_dense_forest.add_child(floor_mesh)
	
	# Dirt trail down the middle
	var trail = CSGBox3D.new()
	trail.size = Vector3(4.2, 0.05, 70.0)
	trail.position = Vector3(0, 0.02, 0)
	trail.material = _create_forest_soil_material(Color(0.12, 0.10, 0.07), 4.0)
	set_dense_forest.add_child(trail)
	
	# Eerie Forest Ground Fog Drifting Along Trail
	var forest_fog = CPUParticles3D.new()
	forest_fog.amount = 24
	forest_fog.lifetime = 6.0
	forest_fog.preprocess = 2.0
	forest_fog.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	forest_fog.emission_box_extents = Vector3(16.0, 0.5, 30.0)
	forest_fog.position = Vector3(0.0, 0.35, 0.0)
	forest_fog.direction = Vector3(0.2, 0.0, 0.8)
	forest_fog.spread = 45.0
	forest_fog.gravity = Vector3(0, 0, 0)
	forest_fog.initial_velocity_min = 0.2
	forest_fog.initial_velocity_max = 0.6
	
	var fog_mat = StandardMaterial3D.new()
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	fog_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fog_mat.albedo_color = Color(0.45, 0.08, 0.10, 0.14)
	
	var fog_mesh = QuadMesh.new()
	fog_mesh.size = Vector2(4.8, 4.8)
	fog_mesh.material = fog_mat
	forest_fog.mesh = fog_mesh
	set_dense_forest.add_child(forest_fog)
	
	# Trees placed strictly to the sides (leaving trail & clearing completely open!)
	var tree_coords = []
	for z in range(-30, 32, 5):
		tree_coords.append(Vector3(-5.5 - randf() * 3.0, 0, z))
		tree_coords.append(Vector3(5.5 + randf() * 3.0, 0, z))
		tree_coords.append(Vector3(-12.0 - randf() * 6.0, 0, z))
		tree_coords.append(Vector3(12.0 + randf() * 6.0, 0, z))
	
	for tc in tree_coords:
		var tree = _create_detailed_forest_tree()
		tree.position = tc
		set_dense_forest.add_child(tree)
		forest_trees.append(tree)
	
	# Clear opening ahead on trail at Z = -10 where the mysterious anomaly hovers!
	var anomaly_pivot = Node3D.new()
	anomaly_pivot.position = Vector3(0.0, 2.2, -10.0) # Directly centered in front of Kripal!
	set_dense_forest.add_child(anomaly_pivot)
	
	forest_anomaly_core = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.75
	s_mesh.height = 1.5
	forest_anomaly_core.mesh = s_mesh
	forest_anomaly_core.material_override = _create_mat(Color(0.1, 0.85, 1.0), 0.1, 0.0, Color(0.2, 0.9, 1.0), 6.5)
	anomaly_pivot.add_child(forest_anomaly_core)
	
	var ring = CSGTorus3D.new()
	ring.inner_radius = 1.0
	ring.outer_radius = 1.2
	ring.rotation_degrees = Vector3(25, 45, 0)
	ring.material = _create_mat(Color(0.8, 0.2, 1.0), 0.1, 0.0, Color(0.9, 0.3, 1.0), 5.0)
	anomaly_pivot.add_child(ring)
	
	# Supernatural floating energy embers around anomaly
	var anomaly_motes = CPUParticles3D.new()
	anomaly_motes.amount = 40
	anomaly_motes.lifetime = 3.2
	anomaly_motes.preprocess = 1.5
	anomaly_motes.randomness = 0.7
	anomaly_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	anomaly_motes.emission_sphere_radius = 2.4
	anomaly_motes.direction = Vector3(0, 1, 0)
	anomaly_motes.spread = 180.0
	anomaly_motes.gravity = Vector3(0, 0.15, 0)
	anomaly_motes.initial_velocity_min = 0.2
	anomaly_motes.initial_velocity_max = 0.7
	
	var mote_mat = StandardMaterial3D.new()
	mote_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.albedo_color = Color(0.35, 0.9, 1.0, 0.95)
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(0.3, 0.95, 1.0)
	mote_mat.emission_energy_multiplier = 4.5
	
	var mote_mesh = SphereMesh.new()
	mote_mesh.radius = 0.035
	mote_mesh.height = 0.07
	mote_mesh.material = mote_mat
	anomaly_motes.mesh = mote_mesh
	anomaly_pivot.add_child(anomaly_motes)
	
	forest_anomaly_light = OmniLight3D.new()
	forest_anomaly_light.light_color = Color(0.25, 0.8, 1.0)
	forest_anomaly_light.light_energy = 5.0
	forest_anomaly_light.omni_range = 30.0
	forest_anomaly_light.shadow_enabled = true
	anomaly_pivot.add_child(forest_anomaly_light)
	
	char_kripal_forest = _build_rigged_human("KripalForest", Color(0.82, 0.25, 0.2), Color(0.18, 0.2, 0.3), false, true)
	char_kripal_forest.position = Vector3(0, 0, 10.0)
	char_kripal_forest.rotation_degrees = Vector3(0, 180, 0) # Facing -Z (straight towards anomaly)
	set_dense_forest.add_child(char_kripal_forest)

# ------------------------------------------------------------------------------
# HELPER: INDOOR POTTED PLANT GENERATOR (Matching User Reference Image)
# ------------------------------------------------------------------------------
func _create_potted_plant(pot_rad: float = 0.22, pot_h: float = 0.55, plant_h: float = 0.85, is_table_plant: bool = false) -> Node3D:
	var plant_root = Node3D.new()
	var pot = CSGCylinder3D.new()
	pot.radius = pot_rad
	pot.height = pot_h
	pot.material = _create_mat(Color(0.96, 0.96, 0.96), 0.3)
	pot.position.y = pot_h * 0.5
	plant_root.add_child(pot)
	
	var leaves_mat = _create_mat(Color(0.12, 0.52, 0.18), 0.8)
	if is_table_plant:
		var foliage = CSGSphere3D.new()
		foliage.radius = pot_rad * 1.35
		foliage.position.y = pot_h + foliage.radius * 0.5
		foliage.material = leaves_mat
		plant_root.add_child(foliage)
	else:
		var stem = CSGCylinder3D.new()
		stem.radius = 0.03
		stem.height = plant_h * 0.5
		stem.position.y = pot_h + stem.height * 0.5
		stem.material = _create_mat(Color(0.28, 0.18, 0.1))
		plant_root.add_child(stem)
		
		for a in [0.0, 72.0, 144.0, 216.0, 288.0]:
			var leaf = CSGBox3D.new()
			leaf.size = Vector3(pot_rad * 1.5, 0.02, pot_rad * 0.9)
			leaf.position = Vector3(sin(deg_to_rad(a)) * pot_rad * 0.7, pot_h + plant_h * 0.55, cos(deg_to_rad(a)) * pot_rad * 0.7)
			leaf.rotation_degrees = Vector3(randf_range(-15, 15), a, randf_range(20, 45))
			leaf.material = leaves_mat
			plant_root.add_child(leaf)
	return plant_root

# ------------------------------------------------------------------------------
# ACT 3: FULL TWO-STORY MODERN VILLA INTERIOR (Matching User 6-Panel Reference)
# ------------------------------------------------------------------------------
func _build_act3_full_house() -> void:
	set_full_house = Node3D.new()
	set_full_house.name = "Set_FullHouse"
	set_full_house.position = Vector3(400, 0, 0)
	add_child(set_full_house)
	
	# Reference-faithful luxury materials
	var mat_white_wall = _create_mat(Color(0.96, 0.96, 0.97), 0.85)
	var mat_periwinkle = _create_mat(Color(0.52, 0.60, 0.76), 0.9) # Panel 2 accent wall
	var mat_charcoal_wall = _create_mat(Color(0.18, 0.20, 0.23), 0.55) # Panel 3 TV accent wall & cabinets
	var mat_marble_floor = _create_mat(Color(0.94, 0.95, 0.96), 0.18, 0.0) # Panel 3 polished marble
	var mat_wood_warm = _create_mat(Color(0.48, 0.32, 0.18), 0.65) # Coffee/dining tables & doors
	var mat_sofa_navy = _create_mat(Color(0.12, 0.15, 0.26), 0.85) # Panel 3 navy seating
	var mat_rug_blue = _create_mat(Color(0.10, 0.32, 0.78), 0.95) # Panel 2 royal blue area rug
	var mat_quilt_blue = _create_mat(Color(0.12, 0.38, 0.82), 0.8) # Panel 2 pixel quilt
	var mat_curtain_blue = _create_mat(Color(0.10, 0.25, 0.62), 0.85) # Panel 2 window curtains
	var mat_black_metal = _create_mat(Color(0.12, 0.12, 0.14), 0.3, 0.7) # Railing posts & window frames
	var mat_silver_metal = _create_mat(Color(0.75, 0.76, 0.80), 0.25, 0.85) # Chimney hood & fridge
	var mat_countertop = _create_mat(Color(0.96, 0.96, 0.96), 0.25, 0.0) # White quartz counter
	var mat_glass = _create_mat(Color(0.75, 0.90, 1.0, 0.32), 0.05, 0.1) # Transparent glass balustrades
	var mat_water_blue = _create_mat(Color(0.15, 0.55, 0.90, 0.75), 0.15, 0.05) # Water dispenser carboy
	var mat_screen = _create_mat(Color(0.2, 0.6, 0.9), 0.2, 0.0, Color(0.3, 0.7, 1.0), 2.5)
	var mat_cyan_led = _create_mat(Color(0.0, 0.80, 1.0), 0.2, 0.0, Color(0.0, 0.80, 1.0), 4.5) # Glowing cyan TV backlight strip!
	var mat_pc_blue = _create_mat(Color(0.15, 0.65, 1.0), 0.2, 0.0, Color(0.15, 0.65, 1.0), 3.0) # Ultrawide PC display
	var mat_ceiling_light = _create_mat(Color(1.0, 1.0, 0.95), 0.2, 0.0, Color(1.0, 1.0, 0.95), 2.5)
	
	# Ground floor polished marble slab
	var floor_g = CSGBox3D.new()
	floor_g.size = Vector3(18.0, 0.2, 14.0)
	floor_g.position = Vector3(0, -0.1, 0)
	floor_g.material = mat_marble_floor
	set_full_house.add_child(floor_g)
	
	# Exterior enclosed perimeter walls (7.2m height for two full floors!)
	var wall_back = CSGBox3D.new()
	wall_back.size = Vector3(18.0, 7.2, 0.3)
	wall_back.position = Vector3(0, 3.6, -7.0)
	wall_back.material = mat_white_wall
	set_full_house.add_child(wall_back)
	
	var wall_left = CSGBox3D.new()
	wall_left.size = Vector3(0.3, 7.2, 14.0)
	wall_left.position = Vector3(-9.0, 3.6, 0)
	wall_left.material = mat_white_wall
	set_full_house.add_child(wall_left)
	
	var wall_right = CSGBox3D.new()
	wall_right.size = Vector3(0.3, 7.2, 14.0)
	wall_right.position = Vector3(9.0, 3.6, 0)
	wall_right.material = mat_white_wall
	set_full_house.add_child(wall_right)
	
	var wall_front = CSGBox3D.new()
	wall_front.size = Vector3(18.0, 7.2, 0.3)
	wall_front.position = Vector3(0, 3.6, 7.0)
	wall_front.material = mat_white_wall
	set_full_house.add_child(wall_front)
	
	# Mezzanine upper floor structure (Leaves double-height living room atrium open below!)
	# 1. Arjun's Room floor (Upper floor left/front):
	var floor_bedroom = CSGBox3D.new()
	floor_bedroom.size = Vector3(8.8, 0.25, 6.8)
	floor_bedroom.position = Vector3(-4.5, 3.6, 3.5)
	floor_bedroom.material = mat_white_wall
	set_full_house.add_child(floor_bedroom)
	
	# 2. Upper hallway / mezzanine walkway overlooking living room:
	var floor_mezzanine = CSGBox3D.new()
	floor_mezzanine.size = Vector3(2.6, 0.25, 7.2)
	floor_mezzanine.position = Vector3(0.5, 3.6, -3.4)
	floor_mezzanine.material = mat_marble_floor
	set_full_house.add_child(floor_mezzanine)
	
	# 3. Master suite floor above kitchen (Upper floor right):
	var floor_master = CSGBox3D.new()
	floor_master.size = Vector3(7.4, 0.25, 14.0)
	floor_master.position = Vector3(5.3, 3.6, 0)
	floor_master.material = mat_white_wall
	set_full_house.add_child(floor_master)
	
	# Bedroom dividing wall between Arjun's room and living room mezzanine
	var wall_bedroom_sep = CSGBox3D.new()
	wall_bedroom_sep.size = Vector3(8.8, 3.5, 0.25)
	wall_bedroom_sep.position = Vector3(-4.5, 5.35, 0.1)
	wall_bedroom_sep.material = mat_periwinkle # Back accent wall for Arjun's bedroom!
	set_full_house.add_child(wall_bedroom_sep)
	
	# --------------------------------------------------------------------------
	# PANEL 3: HALL / LIVING ROOM (Ground Floor Left)
	# --------------------------------------------------------------------------
	# TV Accent Wall Panel (Dark Slate / Charcoal)
	var tv_accent_panel = CSGBox3D.new()
	tv_accent_panel.size = Vector3(4.2, 2.5, 0.08)
	tv_accent_panel.position = Vector3(-4.2, 1.75, -6.82)
	tv_accent_panel.material = mat_charcoal_wall
	set_full_house.add_child(tv_accent_panel)
	
	# Glowing Cyan LED Backlight Strip around TV Panel (Signature Feature!)
	var led_top = CSGBox3D.new()
	led_top.size = Vector3(4.35, 0.08, 0.06)
	led_top.position = Vector3(-4.2, 3.02, -6.8)
	led_top.material = mat_cyan_led
	set_full_house.add_child(led_top)
	
	var led_bot = CSGBox3D.new()
	led_bot.size = Vector3(4.35, 0.08, 0.06)
	led_bot.position = Vector3(-4.2, 0.48, -6.8)
	led_bot.material = mat_cyan_led
	set_full_house.add_child(led_bot)
	
	var led_l = CSGBox3D.new()
	led_l.size = Vector3(0.08, 2.6, 0.06)
	led_l.position = Vector3(-6.35, 1.75, -6.8)
	led_l.material = mat_cyan_led
	set_full_house.add_child(led_l)
	
	var led_r = CSGBox3D.new()
	led_r.size = Vector3(0.08, 2.6, 0.06)
	led_r.position = Vector3(-2.05, 1.75, -6.8)
	led_r.material = mat_cyan_led
	set_full_house.add_child(led_r)
	
	# Soft cyan halo bounce light
	var tv_led_light = OmniLight3D.new()
	tv_led_light.position = Vector3(-4.2, 1.75, -6.6)
	tv_led_light.light_color = Color(0.0, 0.8, 1.0)
	tv_led_light.light_energy = 2.2
	tv_led_light.omni_range = 4.5
	set_full_house.add_child(tv_led_light)
	
	# Large Flat Screen TV
	tv_screen_mesh = CSGBox3D.new()
	tv_screen_mesh.size = Vector3(2.5, 1.4, 0.05)
	tv_screen_mesh.position = Vector3(-4.2, 1.75, -6.74)
	tv_screen_mesh.material = mat_screen
	set_full_house.add_child(tv_screen_mesh)
	
	# Modern Round Wall Clock above TV
	var clock_ring = CSGCylinder3D.new()
	clock_ring.radius = 0.32
	clock_ring.height = 0.04
	clock_ring.rotation_degrees = Vector3(90, 0, 0)
	clock_ring.position = Vector3(-4.2, 3.32, -6.82)
	clock_ring.material = mat_black_metal
	set_full_house.add_child(clock_ring)
	
	var clock_face = CSGCylinder3D.new()
	clock_face.radius = 0.28
	clock_face.height = 0.05
	clock_face.rotation_degrees = Vector3(90, 0, 0)
	clock_face.position = Vector3(-4.2, 3.32, -6.81)
	clock_face.material = _create_mat(Color(0.96, 0.96, 0.96))
	set_full_house.add_child(clock_face)
	
	# Floating Display Shelves with Succulents
	for sh_x in [-6.6, -1.8]:
		var shelf = CSGBox3D.new()
		shelf.size = Vector3(0.9, 0.05, 0.25)
		shelf.position = Vector3(sh_x, 2.3, -6.75)
		shelf.material = mat_wood_warm
		set_full_house.add_child(shelf)
		var p1 = _create_potted_plant(0.08, 0.12, 0.15, true)
		p1.position = Vector3(sh_x - 0.2, 2.35, -6.72)
		set_full_house.add_child(p1)
		var p2 = _create_potted_plant(0.07, 0.1, 0.12, true)
		p2.position = Vector3(sh_x + 0.2, 2.35, -6.72)
		set_full_house.add_child(p2)
	
	# Tall Audio Tower Speakers flanking TV
	for spk_x in [-6.8, -1.6]:
		var spk = CSGBox3D.new()
		spk.size = Vector3(0.35, 1.5, 0.35)
		spk.position = Vector3(spk_x, 0.75, -6.5)
		spk.material = mat_black_metal
		set_full_house.add_child(spk)
	
	# Low Media Console Unit
	var media_console = CSGBox3D.new()
	media_console.size = Vector3(3.4, 0.52, 0.6)
	media_console.position = Vector3(-4.2, 0.26, -6.4)
	media_console.material = mat_charcoal_wall
	set_full_house.add_child(media_console)
	
	# Modern Navy 3-Seater Sofa
	var sofa_base = CSGBox3D.new()
	sofa_base.size = Vector3(3.0, 0.5, 1.1)
	sofa_base.position = Vector3(-4.2, 0.25, -2.5)
	sofa_base.material = mat_sofa_navy
	set_full_house.add_child(sofa_base)
	
	var sofa_back = CSGBox3D.new()
	sofa_back.size = Vector3(3.0, 0.65, 0.35)
	sofa_back.position = Vector3(-4.2, 0.85, -1.95)
	sofa_back.material = mat_sofa_navy
	set_full_house.add_child(sofa_back)
	
	var sofa_arm_l = CSGBox3D.new()
	sofa_arm_l.size = Vector3(0.3, 0.55, 1.3)
	sofa_arm_l.position = Vector3(-5.8, 0.55, -2.4)
	sofa_arm_l.material = mat_sofa_navy
	set_full_house.add_child(sofa_arm_l)
	
	var sofa_arm_r = CSGBox3D.new()
	sofa_arm_r.size = Vector3(0.3, 0.55, 1.3)
	sofa_arm_r.position = Vector3(-2.6, 0.55, -2.4)
	sofa_arm_r.material = mat_sofa_navy
	set_full_house.add_child(sofa_arm_r)
	
	# Navy Armchair
	var armchair = CSGBox3D.new()
	armchair.size = Vector3(1.1, 0.5, 1.0)
	armchair.position = Vector3(-6.8, 0.25, -3.4)
	armchair.material = mat_sofa_navy
	set_full_house.add_child(armchair)
	var armchair_back = CSGBox3D.new()
	armchair_back.size = Vector3(0.3, 0.65, 1.0)
	armchair_back.position = Vector3(-7.3, 0.75, -3.4)
	armchair_back.material = mat_sofa_navy
	set_full_house.add_child(armchair_back)
	
	# Low Wooden Coffee Table with Plant Centerpiece
	var coffee_table = CSGBox3D.new()
	coffee_table.size = Vector3(1.8, 0.42, 0.9)
	coffee_table.position = Vector3(-4.2, 0.21, -4.2)
	coffee_table.material = mat_wood_warm
	set_full_house.add_child(coffee_table)
	
	var ct_plant = _create_potted_plant(0.16, 0.16, 0.3, true)
	ct_plant.position = Vector3(-4.2, 0.42, -4.2)
	set_full_house.add_child(ct_plant)
	
	# Papa NPC seated on sofa watching TV
	char_papa = _build_rigged_human("Papa", Color(0.85, 0.82, 0.75), Color(0.2, 0.22, 0.28), false, false, false, true)
	char_papa.position = Vector3(-4.2, 0.38, -2.4)
	char_papa.rotation_degrees = Vector3(0, 180, 0)
	set_full_house.add_child(char_papa)
	
	# Indoor Floor Plants in Living Room
	var plant_lr1 = _create_potted_plant(0.28, 0.65, 1.1)
	plant_lr1.position = Vector3(-7.8, 0, -6.2)
	set_full_house.add_child(plant_lr1)
	
	var plant_lr2 = _create_potted_plant(0.25, 0.6, 0.95)
	plant_lr2.position = Vector3(-0.6, 0, -6.2)
	set_full_house.add_child(plant_lr2)
	
	# --------------------------------------------------------------------------
	# PANEL 5: STAIRS TO ROOM (Architectural Open-Tread Glass Staircase)
	# --------------------------------------------------------------------------
	var stair_wall = CSGBox3D.new()
	stair_wall.size = Vector3(0.25, 7.2, 6.0)
	stair_wall.position = Vector3(1.9, 3.6, -3.2)
	stair_wall.material = mat_white_wall
	set_full_house.add_child(stair_wall)
	
	# 10 Polished Marble Steps rising to Y = 3.6
	for i in range(10):
		var step = CSGBox3D.new()
		step.size = Vector3(1.6, 0.36, 0.55)
		step.position = Vector3(0.8, 0.18 + (i * 0.36), -5.8 + (i * 0.55))
		step.material = mat_marble_floor
		set_full_house.add_child(step)
	
	# Continuous Black Handrail & Glass Balustrade alongside steps
	var stair_glass = CSGBox3D.new()
	stair_glass.size = Vector3(0.04, 1.1, 5.6)
	stair_glass.position = Vector3(0.0, 2.3, -3.3)
	stair_glass.rotation_degrees = Vector3(33.0, 0, 0)
	stair_glass.material = mat_glass
	set_full_house.add_child(stair_glass)
	
	var stair_rail = CSGBox3D.new()
	stair_rail.size = Vector3(0.08, 0.08, 6.2)
	stair_rail.position = Vector3(0.0, 2.85, -3.3)
	stair_rail.rotation_degrees = Vector3(33.0, 0, 0)
	stair_rail.material = mat_black_metal
	set_full_house.add_child(stair_rail)
	
	# "DREAM BIG" Framed Black Poster on Staircase Wall (Panel 5 Signature!)
	var poster_frame = CSGBox3D.new()
	poster_frame.size = Vector3(0.04, 1.5, 1.1)
	poster_frame.position = Vector3(1.76, 2.6, -3.5)
	poster_frame.material = mat_black_metal
	set_full_house.add_child(poster_frame)
	
	var poster_label = Label3D.new()
	poster_label.text = "DREAM\nBIG"
	poster_label.font_size = 42
	poster_label.modulate = Color(1.0, 1.0, 1.0)
	poster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	poster_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	poster_label.position = Vector3(1.73, 2.6, -3.5)
	poster_label.rotation_degrees = Vector3(0, -90, 0)
	set_full_house.add_child(poster_label)
	
	# Vertical Cylinder Wall Sconces illuminating steps
	for sc_pos in [Vector3(1.75, 1.6, -4.8), Vector3(1.75, 2.7, -3.0), Vector3(1.75, 3.8, -1.2)]:
		var sc_body = CSGCylinder3D.new()
		sc_body.radius = 0.05
		sc_body.height = 0.38
		sc_body.position = sc_pos
		sc_body.material = mat_black_metal
		set_full_house.add_child(sc_body)
		
		var sc_light = OmniLight3D.new()
		sc_light.position = sc_pos + Vector3(-0.15, 0, 0)
		sc_light.light_color = Color(1.0, 0.92, 0.7)
		sc_light.light_energy = 1.8
		sc_light.omni_range = 3.5
		set_full_house.add_child(sc_light)
	
	# Potted floor plant at bottom of stairs
	var plant_stair = _create_potted_plant(0.24, 0.6, 1.0)
	plant_stair.position = Vector3(0.2, 0, -6.2)
	set_full_house.add_child(plant_stair)
	
	# --------------------------------------------------------------------------
	# PANEL 6: UPPER FLOOR HALL / MEZZANINE (Overlooking Living Room)
	# --------------------------------------------------------------------------
	# Glass Balustrade guarding the open edge looking down into living room
	var balustrade_glass = CSGBox3D.new()
	balustrade_glass.size = Vector3(0.04, 1.05, 6.8)
	balustrade_glass.position = Vector3(-0.75, 4.25, -3.4)
	balustrade_glass.material = mat_glass
	set_full_house.add_child(balustrade_glass)
	
	var balustrade_rail = CSGBox3D.new()
	balustrade_rail.size = Vector3(0.08, 0.08, 6.8)
	balustrade_rail.position = Vector3(-0.75, 4.8, -3.4)
	balustrade_rail.material = mat_black_metal
	set_full_house.add_child(balustrade_rail)
	
	# Wooden doors along upper hallway
	var door_arjun = CSGBox3D.new()
	door_arjun.size = Vector3(1.1, 2.2, 0.08)
	door_arjun.position = Vector3(-1.4, 4.8, 0.15)
	door_arjun.material = mat_wood_warm
	set_full_house.add_child(door_arjun)
	
	var door_master = CSGBox3D.new()
	door_master.size = Vector3(0.08, 2.2, 1.1)
	door_master.position = Vector3(1.88, 4.8, -2.5)
	door_master.material = mat_wood_warm
	set_full_house.add_child(door_master)
	
	# Hallway Art Posters & Window
	var poster_hall1 = CSGBox3D.new()
	poster_hall1.size = Vector3(0.04, 1.1, 0.8)
	poster_hall1.position = Vector3(1.88, 5.2, -4.5)
	poster_hall1.material = _create_mat(Color(0.15, 0.35, 0.65))
	set_full_house.add_child(poster_hall1)
	
	var hall_window = CSGBox3D.new()
	hall_window.size = Vector3(2.2, 1.6, 0.1)
	hall_window.position = Vector3(0.5, 5.2, -6.95)
	hall_window.material = _create_mat(Color(0.85, 0.95, 1.0, 0.4), 0.1, 0.0, Color(0.9, 0.95, 1.0), 1.5)
	set_full_house.add_child(hall_window)
	
	# --------------------------------------------------------------------------
	# PANEL 4: KITCHEN & DINING (Ground Floor Right)
	# --------------------------------------------------------------------------
	# Dark Charcoal Modular Base Cabinets along Z = -6.4
	var base_cabinets = CSGBox3D.new()
	base_cabinets.size = Vector3(4.8, 0.85, 0.9)
	base_cabinets.position = Vector3(5.5, 0.42, -6.4)
	base_cabinets.material = mat_charcoal_wall
	set_full_house.add_child(base_cabinets)
	
	# Seamless White Quartz Countertop
	var kitchen_counter = CSGBox3D.new()
	kitchen_counter.size = Vector3(5.0, 0.08, 1.0)
	kitchen_counter.position = Vector3(5.5, 0.88, -6.4)
	kitchen_counter.material = mat_countertop
	set_full_house.add_child(kitchen_counter)
	
	# Overhead Matching Upper Cabinets
	var upper_cabinets = CSGBox3D.new()
	upper_cabinets.size = Vector3(4.6, 0.85, 0.55)
	upper_cabinets.position = Vector3(5.5, 2.5, -6.6)
	upper_cabinets.material = mat_charcoal_wall
	set_full_house.add_child(upper_cabinets)
	
	# Gas Stove / Cooktop
	var stove = CSGBox3D.new()
	stove.size = Vector3(1.1, 0.06, 0.65)
	stove.position = Vector3(5.5, 0.92, -6.4)
	stove.material = _create_mat(Color(0.25, 0.27, 0.3), 0.3, 0.8)
	set_full_house.add_child(stove)
	
	# Overhead Stainless Steel Chimney Hood
	var chimney_hood = CSGBox3D.new()
	chimney_hood.size = Vector3(1.2, 0.35, 0.7)
	chimney_hood.position = Vector3(5.5, 2.15, -6.4)
	chimney_hood.material = mat_silver_metal
	set_full_house.add_child(chimney_hood)
	
	var chimney_duct = CSGBox3D.new()
	chimney_duct.size = Vector3(0.45, 1.2, 0.4)
	chimney_duct.position = Vector3(5.5, 2.9, -6.4)
	chimney_duct.material = mat_silver_metal
	set_full_house.add_child(chimney_duct)
	
	# Chai Pot on Stove Burner
	var chai_pot = CSGCylinder3D.new()
	chai_pot.radius = 0.2
	chai_pot.height = 0.25
	chai_pot.position = Vector3(5.5, 1.08, -6.4)
	chai_pot.material = mat_silver_metal
	set_full_house.add_child(chai_pot)
	
	# Rising Tea Steam Mesh
	tea_steam_mesh = MeshInstance3D.new()
	var steam_s = SphereMesh.new()
	steam_s.radius = 0.14
	steam_s.height = 0.3
	tea_steam_mesh.mesh = steam_s
	tea_steam_mesh.material_override = _create_mat(Color(1, 1, 1, 0.4), 0.9, 0.0, Color.WHITE, 0.6)
	tea_steam_mesh.position = Vector3(5.5, 1.4, -6.4)
	set_full_house.add_child(tea_steam_mesh)
	
	# Countertop Microwave Oven
	var microwave = CSGBox3D.new()
	microwave.size = Vector3(0.7, 0.42, 0.48)
	microwave.position = Vector3(7.1, 1.15, -6.4)
	microwave.material = _create_mat(Color(0.18, 0.18, 0.2), 0.4, 0.6)
	set_full_house.add_child(microwave)
	
	# Water Dispenser (White Stand + Inverted Blue Carboy Bottle - Panel 4 Signature!)
	var wd_stand = CSGBox3D.new()
	wd_stand.size = Vector3(0.42, 0.85, 0.42)
	wd_stand.position = Vector3(2.5, 0.42, -6.4)
	wd_stand.material = _create_mat(Color(0.96, 0.96, 0.96), 0.4)
	set_full_house.add_child(wd_stand)
	
	var wd_bottle = CSGCylinder3D.new()
	wd_bottle.radius = 0.16
	wd_bottle.height = 0.45
	wd_bottle.position = Vector3(2.5, 1.1, -6.4)
	wd_bottle.material = mat_water_blue
	set_full_house.add_child(wd_bottle)
	
	# Tall Double-Door Silver Refrigerator
	var fridge = CSGBox3D.new()
	fridge.size = Vector3(0.95, 1.95, 0.85)
	fridge.position = Vector3(8.2, 0.98, -6.3)
	fridge.material = mat_silver_metal
	set_full_house.add_child(fridge)
	
	# Center Dining Table with 4 Chairs & Centerpiece Plant
	var dining_table = CSGBox3D.new()
	dining_table.size = Vector3(2.2, 0.78, 1.1)
	dining_table.position = Vector3(5.5, 0.39, -3.2)
	dining_table.material = mat_wood_warm
	set_full_house.add_child(dining_table)
	
	var dining_plant = _create_potted_plant(0.14, 0.14, 0.28, true)
	dining_plant.position = Vector3(5.5, 0.78, -3.2)
	set_full_house.add_child(dining_plant)
	
	var mat_chair_grey = _create_mat(Color(0.24, 0.26, 0.29), 0.7)
	for ch_pos in [Vector3(4.8, 0.45, -2.4), Vector3(6.2, 0.45, -2.4), Vector3(4.8, 0.45, -4.0), Vector3(6.2, 0.45, -4.0)]:
		var chair = CSGBox3D.new()
		chair.size = Vector3(0.45, 0.85, 0.45)
		chair.position = ch_pos
		chair.material = mat_chair_grey
		set_full_house.add_child(chair)
	
	# Mummy NPC cooking at stove
	char_mummy = _build_rigged_human("Mummy", Color(0.85, 0.2, 0.35), Color(0.85, 0.2, 0.35), false, false, true)
	char_mummy.position = Vector3(5.5, 0, -5.2)
	char_mummy.rotation_degrees = Vector3(0, 0, 0)
	set_full_house.add_child(char_mummy)
	
	# --------------------------------------------------------------------------
	# PANEL 2: ARJUN'S ROOM (Protagonist Bedroom - 1st Floor Left)
	# --------------------------------------------------------------------------
	# Large Royal Blue Area Rug under bed & desk
	var blue_rug = CSGBox3D.new()
	blue_rug.size = Vector3(4.8, 0.02, 4.2)
	blue_rug.position = Vector3(-4.5, 3.62, 3.5)
	blue_rug.material = mat_rug_blue
	set_full_house.add_child(blue_rug)
	
	# Modern Platform Bed
	var bed_platform = CSGBox3D.new()
	bed_platform.size = Vector3(2.4, 0.35, 2.8)
	bed_platform.position = Vector3(-4.5, 3.78, 2.5)
	bed_platform.material = mat_charcoal_wall
	set_full_house.add_child(bed_platform)
	
	var mattress = CSGBox3D.new()
	mattress.size = Vector3(2.2, 0.25, 2.6)
	mattress.position = Vector3(-4.5, 4.05, 2.5)
	mattress.material = _create_mat(Color(0.9, 0.92, 0.96))
	set_full_house.add_child(mattress)
	
	# Blue Pixelated / Checkered Quilt Cover
	var quilt = CSGBox3D.new()
	quilt.size = Vector3(2.2, 0.22, 2.2)
	quilt.position = Vector3(-4.5, 4.18, 2.3)
	quilt.material = mat_quilt_blue
	set_full_house.add_child(quilt)
	
	# Patterned Pixel Quilt Accent Squares
	for qx in [-0.6, 0.0, 0.6]:
		for qz in [-0.5, 0.5]:
			var qtile = CSGBox3D.new()
			qtile.size = Vector3(0.42, 0.02, 0.42)
			qtile.position = Vector3(-4.5 + qx, 4.29, 2.3 + qz)
			qtile.material = _create_mat(Color(0.08, 0.24, 0.65) if (qx == 0.0) else Color(0.18, 0.52, 0.95))
			set_full_house.add_child(qtile)
	
	# Two Royal Blue Pillows at Headboard
	for px in [-5.1, -3.9]:
		var pil = CSGBox3D.new()
		pil.size = Vector3(0.9, 0.18, 0.55)
		pil.position = Vector3(px, 4.25, 3.4)
		pil.material = _create_mat(Color(0.15, 0.42, 0.88))
		set_full_house.add_child(pil)
	
	# Sleeping Protagonist in Black Hoodie with White Sleeve Details!
	char_player_sleeping = _build_rigged_human("ProtagonistSleeping", Color(0.12, 0.12, 0.14), Color(0.14, 0.14, 0.17))
	char_player_sleeping.position = Vector3(-4.5, 4.15, 2.5)
	char_player_sleeping.rotation_degrees = Vector3(-90, 0, 0)
	set_full_house.add_child(char_player_sleeping)
	
	# Posters on Periwinkle Accent Wall:
	# 1. "GAME ON" Poster (Black frame, white text & controller)
	var p_gameon_frame = CSGBox3D.new()
	p_gameon_frame.size = Vector3(0.85, 1.15, 0.03)
	p_gameon_frame.position = Vector3(-5.4, 5.4, 0.25)
	p_gameon_frame.material = mat_black_metal
	set_full_house.add_child(p_gameon_frame)
	
	var p_gameon_lbl = Label3D.new()
	p_gameon_lbl.text = "GAME\nON\n🎮"
	p_gameon_lbl.font_size = 36
	p_gameon_lbl.modulate = Color(1.0, 1.0, 1.0)
	p_gameon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_gameon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p_gameon_lbl.position = Vector3(-5.4, 5.4, 0.27)
	set_full_house.add_child(p_gameon_lbl)
	
	# 2. Golden Crown "👑" Poster
	var p_crown_frame = CSGBox3D.new()
	p_crown_frame.size = Vector3(0.75, 0.95, 0.03)
	p_crown_frame.position = Vector3(-3.6, 5.4, 0.25)
	p_crown_frame.material = mat_black_metal
	set_full_house.add_child(p_crown_frame)
	
	var p_crown_lbl = Label3D.new()
	p_crown_lbl.text = "👑"
	p_crown_lbl.font_size = 54
	p_crown_lbl.modulate = Color(0.98, 0.82, 0.15)
	p_crown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_crown_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p_crown_lbl.position = Vector3(-3.6, 5.4, 0.27)
	set_full_house.add_child(p_crown_lbl)
	
	# Floating Wooden Shelves with Books & Plants
	for sy in [5.4, 4.8]:
		var sh = CSGBox3D.new()
		sh.size = Vector3(1.4, 0.05, 0.25)
		sh.position = Vector3(-1.8, sy, 1.2)
		sh.material = mat_wood_warm
		set_full_house.add_child(sh)
		var b_plant = _create_potted_plant(0.08, 0.1, 0.14, true)
		b_plant.position = Vector3(-1.4, sy + 0.05, 1.2)
		set_full_house.add_child(b_plant)
	
	# Corner Gaming Desk
	var desk = CSGBox3D.new()
	desk.size = Vector3(2.2, 0.75, 0.9)
	desk.position = Vector3(-1.6, 3.98, 4.5)
	desk.material = mat_charcoal_wall
	set_full_house.add_child(desk)
	
	# PC Tower Chassis with Cyan RGB Strip
	var pc_tower = CSGBox3D.new()
	pc_tower.size = Vector3(0.28, 0.55, 0.55)
	pc_tower.position = Vector3(-2.4, 4.65, 4.6)
	pc_tower.material = mat_black_metal
	set_full_house.add_child(pc_tower)
	
	var pc_rgb = CSGBox3D.new()
	pc_rgb.size = Vector3(0.02, 0.45, 0.45)
	pc_rgb.position = Vector3(-2.25, 4.65, 4.6)
	pc_rgb.material = mat_cyan_led
	set_full_house.add_child(pc_rgb)
	
	# Ultrawide Gaming Monitor with Glowing Blue Display
	var monitor = CSGBox3D.new()
	monitor.size = Vector3(1.25, 0.62, 0.06)
	monitor.position = Vector3(-1.4, 4.75, 4.5)
	monitor.material = mat_pc_blue
	set_full_house.add_child(monitor)
	
	# Racing Gaming Chair (Black with Royal Blue Bolsters)
	var chair_base = CSGBox3D.new()
	chair_base.size = Vector3(0.6, 0.45, 0.6)
	chair_base.position = Vector3(-1.4, 3.82, 3.4)
	chair_base.material = mat_black_metal
	set_full_house.add_child(chair_base)
	
	var chair_back = CSGBox3D.new()
	chair_back.size = Vector3(0.55, 0.85, 0.12)
	chair_back.position = Vector3(-1.4, 4.45, 3.1)
	chair_back.material = _create_mat(Color(0.12, 0.12, 0.14))
	set_full_house.add_child(chair_back)
	
	var chair_blue_strip = CSGBox3D.new()
	chair_blue_strip.size = Vector3(0.35, 0.75, 0.04)
	chair_blue_strip.position = Vector3(-1.4, 4.45, 3.16)
	chair_blue_strip.material = _create_mat(Color(0.12, 0.45, 0.95))
	set_full_house.add_child(chair_blue_strip)
	
	# Bedroom Window & Royal Blue Draped Curtains
	var bed_win = CSGBox3D.new()
	bed_win.size = Vector3(2.2, 1.8, 0.1)
	bed_win.position = Vector3(-1.0, 5.0, 6.95)
	bed_win.material = _create_mat(Color(0.85, 0.95, 1.0, 0.4), 0.1, 0.0, Color(1.0, 0.96, 0.8), 2.0)
	set_full_house.add_child(bed_win)
	
	var curt_l = CSGBox3D.new()
	curt_l.size = Vector3(0.45, 2.2, 0.15)
	curt_l.position = Vector3(-2.3, 5.0, 6.85)
	curt_l.material = mat_curtain_blue
	set_full_house.add_child(curt_l)
	
	var curt_r = CSGBox3D.new()
	curt_r.size = Vector3(0.45, 2.2, 0.15)
	curt_r.position = Vector3(0.3, 5.0, 6.85)
	curt_r.material = mat_curtain_blue
	set_full_house.add_child(curt_r)
	
	# Tall Dark Charcoal Double-Door Wardrobe
	var wardrobe = CSGBox3D.new()
	wardrobe.size = Vector3(0.7, 2.5, 1.8)
	wardrobe.position = Vector3(-8.6, 4.85, 2.5)
	wardrobe.material = mat_charcoal_wall
	set_full_house.add_child(wardrobe)
	
	# Bedside Nightstand & Lamp
	var nightstand = CSGBox3D.new()
	nightstand.size = Vector3(0.55, 0.55, 0.55)
	nightstand.position = Vector3(-6.2, 3.88, 3.4)
	nightstand.material = mat_wood_warm
	set_full_house.add_child(nightstand)
	
	var lamp = CSGCylinder3D.new()
	lamp.radius = 0.14
	lamp.height = 0.35
	lamp.position = Vector3(-6.2, 4.35, 3.4)
	lamp.material = _create_mat(Color(1.0, 0.95, 0.8), 0.2, 0.0, Color(1.0, 0.92, 0.7), 2.2)
	set_full_house.add_child(lamp)
	
	# Spinning Ceiling Fan
	var fan_pivot = Node3D.new()
	fan_pivot.position = Vector3(-4.5, 6.8, 3.5)
	set_full_house.add_child(fan_pivot)
	var fan_rod = CSGCylinder3D.new()
	fan_rod.radius = 0.04
	fan_rod.height = 0.6
	fan_rod.position = Vector3(0, 0.3, 0)
	fan_rod.material = mat_white_wall
	fan_pivot.add_child(fan_rod)
	ceiling_fan_blades = Node3D.new()
	fan_pivot.add_child(ceiling_fan_blades)
	for r in [0, 120, 240]:
		var blade = CSGBox3D.new()
		blade.size = Vector3(1.2, 0.02, 0.15)
		blade.position = Vector3(0.6, 0, 0)
		blade.rotation_degrees = Vector3(0, r, 0)
		blade.material = _create_mat(Color(0.85, 0.85, 0.85))
		ceiling_fan_blades.add_child(blade)

# ------------------------------------------------------------------------------
# ACT 4: MODERN TWO-STORY VILLA EXTERIOR & NEIGHBORHOOD (Matching Panel 1)
# ------------------------------------------------------------------------------
func _build_act4_neighborhood_van() -> void:
	set_neighborhood_street = Node3D.new()
	set_neighborhood_street.name = "Set_NeighborhoodStreet"
	set_neighborhood_street.position = Vector3(600, 0, 0)
	add_child(set_neighborhood_street)
	
	var mat_villa_white = _create_mat(Color(0.96, 0.96, 0.97), 0.85)
	var mat_villa_charcoal = _create_mat(Color(0.18, 0.19, 0.22), 0.6)
	var mat_asphalt = _create_mat(Color(0.2, 0.2, 0.22), 0.9)
	var mat_sidewalk = _create_mat(Color(0.68, 0.69, 0.72), 0.8)
	var mat_hedge = _create_mat(Color(0.14, 0.50, 0.18), 0.85)
	var mat_black_gate = _create_mat(Color(0.12, 0.13, 0.15), 0.3, 0.7)
	var mat_glass = _create_mat(Color(0.75, 0.90, 1.0, 0.35), 0.05, 0.1)
	var mat_gold_lamp = _create_mat(Color(1.0, 0.9, 0.55), 0.2, 0.0, Color(1.0, 0.9, 0.55), 3.0)
	
	# Asphalt Road
	var road = CSGBox3D.new()
	road.size = Vector3(30.0, 0.2, 80.0)
	road.position = Vector3(0, -0.1, 0)
	road.material = mat_asphalt
	set_neighborhood_street.add_child(road)
	
	# Yellow Center Dividing Line
	var yellow_line = CSGBox3D.new()
	yellow_line.size = Vector3(0.25, 0.02, 80.0)
	yellow_line.position = Vector3(0, 0.01, 0)
	yellow_line.material = _create_mat(Color(0.95, 0.8, 0.15), 0.6)
	set_neighborhood_street.add_child(yellow_line)
	
	# Paved Sidewalk in front of Villa
	var sidewalk = CSGBox3D.new()
	sidewalk.size = Vector3(18.0, 0.15, 4.0)
	sidewalk.position = Vector3(2.5, 0.05, 1.5)
	sidewalk.material = mat_sidewalk
	set_neighborhood_street.add_child(sidewalk)
	
	# --------------------------------------------------------------------------
	# TWO-STORY MODERN VILLA MAIN BUILDING (Panel 1)
	# --------------------------------------------------------------------------
	var villa_body = CSGBox3D.new()
	villa_body.size = Vector3(14.0, 7.0, 8.5)
	villa_body.position = Vector3(4.0, 3.5, -4.5)
	villa_body.material = mat_villa_white
	set_neighborhood_street.add_child(villa_body)
	
	# Dark Architectural Borders & Parapet Coping
	var roof_trim = CSGBox3D.new()
	roof_trim.size = Vector3(14.4, 0.4, 8.9)
	roof_trim.position = Vector3(4.0, 7.1, -4.5)
	roof_trim.material = mat_villa_charcoal
	set_neighborhood_street.add_child(roof_trim)
	
	# Ground Floor Front Entrance Porch / Portico
	var porch_canopy = CSGBox3D.new()
	porch_canopy.size = Vector3(4.2, 0.35, 2.2)
	porch_canopy.position = Vector3(2.5, 3.3, -0.8)
	porch_canopy.material = mat_villa_charcoal
	set_neighborhood_street.add_child(porch_canopy)
	
	# Front Entrance Porch Niche & Doorway Opening
	var porch_door_niche = CSGBox3D.new()
	porch_door_niche.size = Vector3(1.8, 2.6, 0.5)
	porch_door_niche.position = Vector3(2.5, 1.3, -0.25)
	porch_door_niche.material = _create_mat(Color(0.12, 0.12, 0.14), 0.8) # Dark lit hallway opening
	set_neighborhood_street.add_child(porch_door_niche)
	
	# Front Entrance Door with Hinge Pivot
	front_door_pivot = Node3D.new()
	front_door_pivot.position = Vector3(1.8, 0, 0.0) # Hinge on left jamb
	set_neighborhood_street.add_child(front_door_pivot)
	
	front_door_mesh = CSGBox3D.new()
	front_door_mesh.size = Vector3(1.4, 2.4, 0.08)
	front_door_mesh.position = Vector3(0.7, 1.2, 0.0)
	front_door_mesh.material = _create_mat(Color(0.42, 0.28, 0.15), 0.6)
	front_door_pivot.add_child(front_door_mesh)
	
	# Warm Porch Recessed Light
	var porch_light = OmniLight3D.new()
	porch_light.position = Vector3(2.5, 3.1, -0.8)
	porch_light.light_color = Color(1.0, 0.92, 0.75)
	porch_light.light_energy = 2.5
	porch_light.omni_range = 6.0
	set_neighborhood_street.add_child(porch_light)
	
	# Ground Floor Window (3x3 grid pane on left)
	var win_g = CSGBox3D.new()
	win_g.size = Vector3(2.8, 2.0, 0.15)
	win_g.position = Vector3(-1.5, 1.5, -0.2)
	win_g.material = _create_mat(Color(0.15, 0.15, 0.18), 0.3, 0.8)
	set_neighborhood_street.add_child(win_g)
	
	# --------------------------------------------------------------------------
	# 1ST-FLOOR RECESSED BALCONY WITH GLASS RAILING (Panel 1)
	# --------------------------------------------------------------------------
	var balcony_frame = CSGBox3D.new()
	balcony_frame.size = Vector3(4.8, 3.3, 2.2)
	balcony_frame.position = Vector3(5.5, 5.2, -1.0)
	balcony_frame.material = mat_villa_charcoal
	set_neighborhood_street.add_child(balcony_frame)
	
	var balcony_void = CSGBox3D.new()
	balcony_void.size = Vector3(4.4, 3.0, 2.0)
	balcony_void.position = Vector3(5.5, 5.2, -0.9)
	balcony_void.material = mat_villa_white
	set_neighborhood_street.add_child(balcony_void)
	
	# Transparent Glass Balustrade & Black Handrail
	var balcony_glass = CSGBox3D.new()
	balcony_glass.size = Vector3(4.3, 1.05, 0.06)
	balcony_glass.position = Vector3(5.5, 4.15, 0.1)
	balcony_glass.material = mat_glass
	set_neighborhood_street.add_child(balcony_glass)
	
	var balcony_rail = CSGBox3D.new()
	balcony_rail.size = Vector3(4.4, 0.08, 0.08)
	balcony_rail.position = Vector3(5.5, 4.7, 0.1)
	balcony_rail.material = mat_villa_charcoal
	set_neighborhood_street.add_child(balcony_rail)
	
	# 1st-Floor Left Window (3x3 grid)
	var win_1f = CSGBox3D.new()
	win_1f.size = Vector3(2.8, 2.0, 0.15)
	win_1f.position = Vector3(-1.5, 5.2, -0.2)
	win_1f.material = _create_mat(Color(0.15, 0.15, 0.18), 0.3, 0.8)
	set_neighborhood_street.add_child(win_1f)
	
	# --------------------------------------------------------------------------
	# FRONT BOUNDARY WALL, TRIMMED HEDGE & BLACK SLAT GATE (Panel 1)
	# --------------------------------------------------------------------------
	# White Base Boundary Wall
	var b_wall_l = CSGBox3D.new()
	b_wall_l.size = Vector3(5.5, 0.65, 0.25)
	b_wall_l.position = Vector3(-2.2, 0.32, 3.5)
	b_wall_l.material = mat_villa_white
	set_neighborhood_street.add_child(b_wall_l)
	
	var b_wall_r = CSGBox3D.new()
	b_wall_r.size = Vector3(5.5, 0.65, 0.25)
	b_wall_r.position = Vector3(7.2, 0.32, 3.5)
	b_wall_r.material = mat_villa_white
	set_neighborhood_street.add_child(b_wall_r)
	
	# Neatly Trimmed Green Box Hedge along top of wall
	var hedge_l = CSGBox3D.new()
	hedge_l.size = Vector3(5.5, 0.55, 0.35)
	hedge_l.position = Vector3(-2.2, 0.9, 3.5)
	hedge_l.material = mat_hedge
	set_neighborhood_street.add_child(hedge_l)
	
	var hedge_r = CSGBox3D.new()
	hedge_r.size = Vector3(5.5, 0.55, 0.35)
	hedge_r.position = Vector3(7.2, 0.9, 3.5)
	hedge_r.material = mat_hedge
	set_neighborhood_street.add_child(hedge_r)
	
	# Sturdy White Gate Pillars flanking entrance
	var pillar_l = CSGBox3D.new()
	pillar_l.size = Vector3(0.8, 1.85, 0.8)
	pillar_l.position = Vector3(0.8, 0.92, 3.5)
	pillar_l.material = mat_villa_white
	set_neighborhood_street.add_child(pillar_l)
	
	var pillar_r = CSGBox3D.new()
	pillar_r.size = Vector3(0.8, 1.85, 0.8)
	pillar_r.position = Vector3(4.4, 0.92, 3.5)
	pillar_r.material = mat_villa_white
	set_neighborhood_street.add_child(pillar_r)
	
	# "A-101" Plaque on Right Pillar (Panel 1 Signature!)
	var plaque = CSGBox3D.new()
	plaque.size = Vector3(0.05, 0.28, 0.45)
	plaque.position = Vector3(4.42, 1.25, 3.5)
	plaque.material = mat_black_gate
	set_neighborhood_street.add_child(plaque)
	
	var plaque_lbl = Label3D.new()
	plaque_lbl.text = "A-101"
	plaque_lbl.font_size = 38
	plaque_lbl.modulate = Color(1.0, 1.0, 1.0)
	plaque_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plaque_lbl.position = Vector3(4.45, 1.25, 3.5)
	plaque_lbl.rotation_degrees = Vector3(0, 90, 0)
	set_neighborhood_street.add_child(plaque_lbl)
	
	# Wall Sconce above Plaque
	var plaque_sconce = CSGBox3D.new()
	plaque_sconce.size = Vector3(0.08, 0.15, 0.15)
	plaque_sconce.position = Vector3(4.42, 1.55, 3.5)
	plaque_sconce.material = mat_gold_lamp
	set_neighborhood_street.add_child(plaque_sconce)
	
	var sconce_light = OmniLight3D.new()
	sconce_light.position = Vector3(4.6, 1.55, 3.5)
	sconce_light.light_color = Color(1.0, 0.92, 0.7)
	sconce_light.light_energy = 1.8
	sconce_light.omni_range = 3.0
	set_neighborhood_street.add_child(sconce_light)
	
	# Modern Horizontal Black Slat Gate with Dual Opening Pivots
	gate_pivot_l = Node3D.new()
	gate_pivot_l.position = Vector3(0.85, 0, 3.5) # Left pillar hinge
	set_neighborhood_street.add_child(gate_pivot_l)
	
	var gate_l = CSGBox3D.new()
	gate_l.size = Vector3(1.7, 1.45, 0.06)
	gate_l.position = Vector3(0.85, 0.85, 0)
	gate_l.material = mat_black_gate
	gate_pivot_l.add_child(gate_l)
	for s_i in range(6):
		var slat_l = CSGBox3D.new()
		slat_l.size = Vector3(1.65, 0.12, 0.08)
		slat_l.position = Vector3(0.85, 0.25 + (s_i * 0.22), 0)
		slat_l.material = mat_black_gate
		gate_pivot_l.add_child(slat_l)
	
	gate_pivot_r = Node3D.new()
	gate_pivot_r.position = Vector3(4.35, 0, 3.5) # Right pillar hinge
	set_neighborhood_street.add_child(gate_pivot_r)
	
	var gate_r = CSGBox3D.new()
	gate_r.size = Vector3(1.7, 1.45, 0.06)
	gate_r.position = Vector3(-0.85, 0.85, 0)
	gate_r.material = mat_black_gate
	gate_pivot_r.add_child(gate_r)
	for s_i in range(6):
		var slat_r = CSGBox3D.new()
		slat_r.size = Vector3(1.65, 0.12, 0.08)
		slat_r.position = Vector3(-0.85, 0.25 + (s_i * 0.22), 0)
		slat_r.material = mat_black_gate
		gate_pivot_r.add_child(slat_r)
	
	# Two Tall Black Modern Post Lamps on sidewalk corners
	for lamp_x in [-4.5, 9.5]:
		var post = CSGBox3D.new()
		post.size = Vector3(0.18, 2.8, 0.18)
		post.position = Vector3(lamp_x, 1.4, 3.5)
		post.material = mat_black_gate
		set_neighborhood_street.add_child(post)
		
		var lantern = CSGBox3D.new()
		lantern.size = Vector3(0.42, 0.45, 0.42)
		lantern.position = Vector3(lamp_x, 2.9, 3.5)
		lantern.material = mat_gold_lamp
		set_neighborhood_street.add_child(lantern)
		
		var l_omni = OmniLight3D.new()
		l_omni.position = Vector3(lamp_x, 2.9, 3.5)
		l_omni.light_color = Color(1.0, 0.9, 0.55)
		l_omni.light_energy = 3.0
		l_omni.omni_range = 8.0
		set_neighborhood_street.add_child(l_omni)
	
	# Neighboring Houses & Trees across the street
	for z in [-20, -5, 12, 28]:
		var opp_house = CSGBox3D.new()
		opp_house.size = Vector3(9.0, 5.0, 10.0)
		opp_house.position = Vector3(-11.0, 2.5, z)
		opp_house.material = _create_mat(Color(0.75 + randf()*0.1, 0.65 + randf()*0.1, 0.55))
		set_neighborhood_street.add_child(opp_house)
	
	for z in [-26, -14, 2, 16, 28]:
		var tree = _create_detailed_forest_tree(true)
		tree.position = Vector3(-4.0, 0, z)
		set_neighborhood_street.add_child(tree)
		street_trees.append(tree)
	
	# School Van parked on road outside gate
	school_van_exterior = _build_detailed_school_van()
	school_van_exterior.position = Vector3(-0.5, 0, 5.5)
	set_neighborhood_street.add_child(school_van_exterior)
	
	# Sprinting Protagonist in Black Hoodie with Backpack
	char_player_sprint = _build_rigged_human("ProtagonistSprint", Color(0.12, 0.12, 0.14), Color(0.14, 0.14, 0.17), false, false, false, false, true)
	char_player_sprint.position = Vector3(2.5, 0, 0.0)
	char_player_sprint.rotation_degrees = Vector3(0, 0, 0)
	char_player_sprint.visible = false
	set_neighborhood_street.add_child(char_player_sprint)

# ------------------------------------------------------------------------------
# ACT 5: INDIAN SCHOOL BUS INTERIOR (Matching User Reference Image)
# ------------------------------------------------------------------------------
func _build_act5_van_interior() -> void:
	set_van_interior = Node3D.new()
	set_van_interior.name = "Set_VanInterior"
	set_van_interior.position = Vector3(800, 0, 0)
	add_child(set_van_interior)
	
	var mat_bus_yellow = _create_mat(Color(0.98, 0.76, 0.12), 0.55, 0.1)
	var mat_dark_floor = _create_mat(Color(0.2, 0.22, 0.24), 0.8, 0.0)
	var mat_aisle_mat = _create_mat(Color(0.34, 0.36, 0.4), 0.9, 0.0)
	var mat_black_trim = _create_mat(Color(0.12, 0.13, 0.15), 0.7, 0.1)
	var mat_seat_blue = _create_mat(Color(0.08, 0.35, 0.82), 0.65, 0.05)
	var mat_seat_frame = _create_mat(Color(0.2, 0.22, 0.25), 0.7, 0.2)
	var mat_glass = _create_mat(Color(0.72, 0.86, 0.96, 0.28), 0.1, 0.05)
	var mat_red_sign = _create_mat(Color(0.85, 0.1, 0.1), 0.4, 0.0)
	var mat_bar = _create_mat(Color(0.82, 0.82, 0.85), 0.2, 0.9)
	var mat_green_fan = _create_mat(Color(0.12, 0.52, 0.22), 0.5, 0.1)
	
	var mat_ceiling_light = StandardMaterial3D.new()
	mat_ceiling_light.albedo_color = Color(1.0, 1.0, 0.95)
	mat_ceiling_light.emission_enabled = true
	mat_ceiling_light.emission = Color(1.0, 1.0, 0.95)
	mat_ceiling_light.emission_energy_multiplier = 2.2
	
	var mat_screen = StandardMaterial3D.new()
	mat_screen.albedo_color = Color(0.15, 0.65, 0.95)
	mat_screen.emission_enabled = true
	mat_screen.emission = Color(0.15, 0.65, 0.95)
	mat_screen.emission_energy_multiplier = 2.5

	# 1. FLOOR & AISLE RUNNER (Reference Image Panels)
	var floor_base = CSGBox3D.new()
	floor_base.size = Vector3(2.9, 0.1, 8.2)
	floor_base.position = Vector3(0, -0.05, 0.5)
	floor_base.material = mat_dark_floor
	set_van_interior.add_child(floor_base)
	
	var aisle_runner = CSGBox3D.new()
	aisle_runner.size = Vector3(0.76, 0.11, 8.0)
	aisle_runner.position = Vector3(0, -0.045, 0.5)
	aisle_runner.material = mat_aisle_mat
	set_van_interior.add_child(aisle_runner)

	# 2. YELLOW ROOF & RECESSED CEILING LIGHTS (Reference Top-Left & Bottom-Right)
	var roof_slab = CSGBox3D.new()
	roof_slab.size = Vector3(2.9, 0.1, 8.2)
	roof_slab.position = Vector3(0, 2.35, 0.5)
	roof_slab.material = mat_bus_yellow
	set_van_interior.add_child(roof_slab)
	
	for z_pos in [-1.5, 0.8, 3.0]:
		var light_frame = CSGBox3D.new()
		light_frame.size = Vector3(0.72, 0.03, 1.02)
		light_frame.position = Vector3(0, 2.30, z_pos)
		light_frame.material = mat_black_trim
		set_van_interior.add_child(light_frame)
		
		var light_panel = CSGBox3D.new()
		light_panel.size = Vector3(0.64, 0.04, 0.94)
		light_panel.position = Vector3(0, 2.29, z_pos)
		light_panel.material = mat_ceiling_light
		set_van_interior.add_child(light_panel)
		
		var omni = OmniLight3D.new()
		omni.position = Vector3(0, 2.15, z_pos)
		omni.light_color = Color(1.0, 0.98, 0.92)
		omni.omni_range = 4.2
		omni.light_energy = 0.85
		set_van_interior.add_child(omni)

	# 3. SIDE WALLS & WINDOWS
	# Left Wall (X = -1.45)
	var left_low_wall = CSGBox3D.new()
	left_low_wall.size = Vector3(0.08, 0.85, 8.0)
	left_low_wall.position = Vector3(-1.41, 0.425, 0.5)
	left_low_wall.material = mat_bus_yellow
	set_van_interior.add_child(left_low_wall)
	
	var left_roof_rail = CSGBox3D.new()
	left_roof_rail.size = Vector3(0.08, 0.45, 8.0)
	left_roof_rail.position = Vector3(-1.41, 2.125, 0.5)
	left_roof_rail.material = mat_bus_yellow
	set_van_interior.add_child(left_roof_rail)
	
	var win_z_positions = [-1.6, 0.2, 1.8, 3.4]
	for wz in win_z_positions:
		var frame = CSGBox3D.new()
		frame.size = Vector3(0.06, 0.95, 1.5)
		frame.position = Vector3(-1.41, 1.35, wz)
		frame.material = mat_black_trim
		set_van_interior.add_child(frame)
		
		var glass = CSGBox3D.new()
		glass.size = Vector3(0.03, 0.88, 1.44)
		glass.position = Vector3(-1.41, 1.35, wz)
		glass.material = mat_glass
		set_van_interior.add_child(glass)
	
	for pz in [-2.5, -0.7, 1.0, 2.6, 4.3]:
		var pillar = CSGBox3D.new()
		pillar.size = Vector3(0.1, 1.05, 0.22)
		pillar.position = Vector3(-1.41, 1.35, pz)
		pillar.material = mat_bus_yellow
		set_van_interior.add_child(pillar)
		
	# Red Emergency Exit plaque above side window (Reference Bottom-Left Panel)
	var side_em_sign = CSGBox3D.new()
	side_em_sign.size = Vector3(0.04, 0.16, 0.75)
	side_em_sign.position = Vector3(-1.38, 2.05, 0.2)
	side_em_sign.material = mat_red_sign
	set_van_interior.add_child(side_em_sign)
	
	# Red Emergency Glass Breaker Box on left pillar
	var em_hammer = CSGBox3D.new()
	em_hammer.size = Vector3(0.04, 0.22, 0.12)
	em_hammer.position = Vector3(-1.38, 1.45, -0.7)
	em_hammer.material = mat_red_sign
	set_van_interior.add_child(em_hammer)
	
	# Horizontal Safety Bars across protagonist's sliding window
	for i in range(3):
		var bar = CSGCylinder3D.new()
		bar.radius = 0.012
		bar.height = 1.48
		bar.rotation_degrees = Vector3(90, 0, 0)
		bar.position = Vector3(-1.38, 1.05 + (i * 0.22), 0.2)
		bar.material = mat_bar
		set_van_interior.add_child(bar)

	# Right Wall (X = +1.45)
	var right_low_wall = CSGBox3D.new()
	right_low_wall.size = Vector3(0.08, 0.85, 8.0)
	right_low_wall.position = Vector3(1.41, 0.425, 0.5)
	right_low_wall.material = mat_bus_yellow
	set_van_interior.add_child(right_low_wall)
	
	var right_roof_rail = CSGBox3D.new()
	right_roof_rail.size = Vector3(0.08, 0.45, 8.0)
	right_roof_rail.position = Vector3(1.41, 2.125, 0.5)
	right_roof_rail.material = mat_bus_yellow
	set_van_interior.add_child(right_roof_rail)
	
	for wz in win_z_positions:
		var frame_r = CSGBox3D.new()
		frame_r.size = Vector3(0.06, 0.95, 1.5)
		frame_r.position = Vector3(1.41, 1.35, wz)
		frame_r.material = mat_black_trim
		set_van_interior.add_child(frame_r)
		
		var glass_r = CSGBox3D.new()
		glass_r.size = Vector3(0.03, 0.88, 1.44)
		glass_r.position = Vector3(1.41, 1.35, wz)
		glass_r.material = mat_glass
		set_van_interior.add_child(glass_r)
	
	for pz in [-2.5, -0.7, 1.0, 2.6, 4.3]:
		var pillar_r = CSGBox3D.new()
		pillar_r.size = Vector3(0.1, 1.05, 0.22)
		pillar_r.position = Vector3(1.41, 1.35, pz)
		pillar_r.material = mat_bus_yellow
		set_van_interior.add_child(pillar_r)

	# 4. REAR WALL & LARGE REAR WINDOW WITH "EMERGENCY EXIT" SIGN (Reference Top-Left & Bottom-Right)
	var rear_wall = CSGBox3D.new()
	rear_wall.size = Vector3(2.9, 2.4, 0.08)
	rear_wall.position = Vector3(0, 1.15, 4.55)
	rear_wall.material = mat_bus_yellow
	set_van_interior.add_child(rear_wall)
	
	var rear_win_frame = CSGBox3D.new()
	rear_win_frame.size = Vector3(1.85, 0.88, 0.1)
	rear_win_frame.position = Vector3(0, 1.4, 4.54)
	rear_win_frame.material = mat_black_trim
	set_van_interior.add_child(rear_win_frame)
	
	var rear_glass = CSGBox3D.new()
	rear_glass.size = Vector3(1.77, 0.8, 0.04)
	rear_glass.position = Vector3(0, 1.4, 4.54)
	rear_glass.material = mat_glass
	set_van_interior.add_child(rear_glass)
	
	var rear_em_sign = CSGBox3D.new()
	rear_em_sign.size = Vector3(0.9, 0.22, 0.04)
	rear_em_sign.position = Vector3(0, 1.98, 4.51)
	rear_em_sign.material = mat_red_sign
	set_van_interior.add_child(rear_em_sign)
	
	# 5. FRONT WINDSHIELD & DASHBOARD CONSOLE (Reference Top-Right Panel)
	var front_bulkhead = CSGBox3D.new()
	front_bulkhead.size = Vector3(2.9, 0.8, 0.1)
	front_bulkhead.position = Vector3(0, 0.4, -3.5)
	front_bulkhead.material = mat_bus_yellow
	set_van_interior.add_child(front_bulkhead)
	
	var front_windshield_frame = CSGBox3D.new()
	front_windshield_frame.size = Vector3(2.8, 1.3, 0.1)
	front_windshield_frame.position = Vector3(0, 1.55, -3.5)
	front_windshield_frame.material = mat_black_trim
	set_van_interior.add_child(front_windshield_frame)
	
	var front_windshield_glass = CSGBox3D.new()
	front_windshield_glass.size = Vector3(2.72, 1.22, 0.04)
	front_windshield_glass.position = Vector3(0, 1.55, -3.5)
	front_windshield_glass.material = mat_glass
	set_van_interior.add_child(front_windshield_glass)
	
	var center_divider = CSGBox3D.new()
	center_divider.size = Vector3(0.08, 1.25, 0.12)
	center_divider.position = Vector3(0, 1.55, -3.5)
	center_divider.material = mat_black_trim
	set_van_interior.add_child(center_divider)
	
	var mirror = CSGBox3D.new()
	mirror.size = Vector3(0.55, 0.18, 0.06)
	mirror.position = Vector3(0, 2.05, -3.3)
	mirror.material = mat_black_trim
	set_van_interior.add_child(mirror)
	
	var dash_main = CSGBox3D.new()
	dash_main.size = Vector3(2.5, 0.65, 0.65)
	dash_main.position = Vector3(-0.15, 0.72, -3.1)
	dash_main.material = mat_black_trim
	set_van_interior.add_child(dash_main)
	
	var gauge_pod = CSGBox3D.new()
	gauge_pod.size = Vector3(0.75, 0.32, 0.22)
	gauge_pod.position = Vector3(-0.65, 1.0, -3.02)
	gauge_pod.rotation_degrees = Vector3(-25, 0, 0)
	gauge_pod.material = mat_black_trim
	set_van_interior.add_child(gauge_pod)
	
	var btn_colors = [Color(0.9, 0.2, 0.2), Color(0.9, 0.5, 0.1), Color(0.15, 0.8, 0.2), Color(0.2, 0.4, 0.9), Color(0.95, 0.85, 0.1)]
	for i in range(btn_colors.size()):
		var btn = CSGBox3D.new()
		btn.size = Vector3(0.04, 0.04, 0.04)
		btn.position = Vector3(-0.15 + (i * 0.07), 0.95, -2.85)
		btn.material = _create_mat(btn_colors[i], 0.4, 0.1)
		set_van_interior.add_child(btn)
		
	var lcd_screen = CSGBox3D.new()
	lcd_screen.size = Vector3(0.24, 0.16, 0.04)
	lcd_screen.position = Vector3(0.35, 0.95, -2.85)
	lcd_screen.material = mat_screen
	set_van_interior.add_child(lcd_screen)
	
	var gear_console = CSGBox3D.new()
	gear_console.size = Vector3(0.24, 0.35, 0.4)
	gear_console.position = Vector3(-0.15, 0.2, -2.65)
	gear_console.material = mat_black_trim
	set_van_interior.add_child(gear_console)
	
	var gear_stick = CSGBox3D.new()
	gear_stick.size = Vector3(0.04, 0.45, 0.04)
	gear_stick.position = Vector3(-0.15, 0.45, -2.6)
	gear_stick.rotation_degrees = Vector3(-12, 0, 0)
	gear_stick.material = _create_mat(Color(0.2, 0.2, 0.22), 0.3, 0.7)
	set_van_interior.add_child(gear_stick)
	
	var gear_knob = CSGSphere3D.new()
	gear_knob.radius = 0.045
	gear_knob.position = Vector3(-0.15, 0.68, -2.55)
	gear_knob.material = mat_black_trim
	set_van_interior.add_child(gear_knob)
	
	var steering_col = CSGCylinder3D.new()
	steering_col.radius = 0.04
	steering_col.height = 0.55
	steering_col.rotation_degrees = Vector3(50, 0, 0)
	steering_col.position = Vector3(-0.65, 0.75, -2.65)
	steering_col.material = mat_black_trim
	set_van_interior.add_child(steering_col)
	
	var wheel = CSGTorus3D.new()
	wheel.inner_radius = 0.17
	wheel.outer_radius = 0.23
	wheel.rotation_degrees = Vector3(50, 0, 0)
	wheel.position = Vector3(-0.65, 0.98, -2.48)
	wheel.material = mat_black_trim
	set_van_interior.add_child(wheel)
	
	# 6. ACCESSORIES (Vintage Green Fan & Red Fire Extinguisher)
	# Vintage Green Mini Dashboard Fan (Reference Top-Right Panel)
	var fan_bracket = CSGBox3D.new()
	fan_bracket.size = Vector3(0.03, 0.16, 0.03)
	fan_bracket.position = Vector3(0.78, 1.95, -3.25)
	fan_bracket.material = mat_black_trim
	set_van_interior.add_child(fan_bracket)
	
	var fan_cage = CSGTorus3D.new()
	fan_cage.inner_radius = 0.15
	fan_cage.outer_radius = 0.19
	fan_cage.rotation_degrees = Vector3(90, 0, 0)
	fan_cage.position = Vector3(0.78, 1.85, -3.22)
	fan_cage.material = mat_green_fan
	set_van_interior.add_child(fan_cage)
	
	var fan_hub = CSGCylinder3D.new()
	fan_hub.radius = 0.05
	fan_hub.height = 0.06
	fan_hub.rotation_degrees = Vector3(90, 0, 0)
	fan_hub.position = Vector3(0.78, 1.85, -3.22)
	fan_hub.material = mat_green_fan
	set_van_interior.add_child(fan_hub)
	
	van_fan_blades = Node3D.new()
	van_fan_blades.name = "VanFanBlades"
	van_fan_blades.position = Vector3(0.78, 1.85, -3.21)
	set_van_interior.add_child(van_fan_blades)
	
	for i in range(4):
		var blade = CSGBox3D.new()
		blade.size = Vector3(0.045, 0.13, 0.01)
		blade.position = Vector3(0, 0.07, 0)
		blade.rotation_degrees = Vector3(0, 30, 0)
		blade.material = mat_green_fan
		var blade_pivot = Node3D.new()
		blade_pivot.rotation_degrees.z = i * 90.0
		blade_pivot.add_child(blade)
		van_fan_blades.add_child(blade_pivot)
		
	# Red Fire Extinguisher on front-right A-pillar (Reference Top-Right Panel)
	var ext_cylinder = CSGCylinder3D.new()
	ext_cylinder.radius = 0.075
	ext_cylinder.height = 0.44
	ext_cylinder.position = Vector3(1.32, 1.45, -3.2)
	ext_cylinder.material = mat_red_sign
	set_van_interior.add_child(ext_cylinder)
	
	for by in [1.32, 1.58]:
		var band = CSGTorus3D.new()
		band.inner_radius = 0.075
		band.outer_radius = 0.088
		band.position = Vector3(1.32, by, -3.2)
		band.material = mat_bar
		set_van_interior.add_child(band)
		
	var ext_nozzle = CSGBox3D.new()
	ext_nozzle.size = Vector3(0.04, 0.12, 0.04)
	ext_nozzle.position = Vector3(1.32, 1.72, -3.2)
	ext_nozzle.material = mat_black_trim
	set_van_interior.add_child(ext_nozzle)

	# 7. DRIVER IN KHAKI UNIFORM & BLUE PEAKED CAP (Reference Top-Right Panel)
	var driver_seat = _create_bus_seat_unit(true, mat_seat_blue, mat_seat_frame)
	driver_seat.position = Vector3(-0.65, 0, -2.45)
	set_van_interior.add_child(driver_seat)
	
	var driver_npc = _build_rigged_human("VanDriverNPC", Color(0.78, 0.70, 0.52), Color(0.72, 0.64, 0.48), false, false, false, true)
	driver_npc.position = Vector3(-0.65, 0.45, -2.4)
	driver_npc.rotation_degrees = Vector3(0, 180, 0)
	set_van_interior.add_child(driver_npc)
	
	var d_cap_crown = CSGBox3D.new()
	d_cap_crown.size = Vector3(0.40, 0.16, 0.42)
	d_cap_crown.position = Vector3(0, 1.88, 0.02)
	d_cap_crown.material = _create_mat(Color(0.12, 0.32, 0.75))
	driver_npc.get_node("Body").add_child(d_cap_crown)
	
	var d_cap_brim = CSGBox3D.new()
	d_cap_brim.size = Vector3(0.36, 0.04, 0.20)
	d_cap_brim.position = Vector3(0, 1.82, 0.24)
	d_cap_brim.material = mat_black_trim
	driver_npc.get_node("Body").add_child(d_cap_brim)
	
	var d_arm_l = driver_npc.get_node_or_null("Body/ArmL_Pivot")
	var d_arm_r = driver_npc.get_node_or_null("Body/ArmR_Pivot")
	if d_arm_l:
		d_arm_l.rotation_degrees = Vector3(-65, 20, 0)
	if d_arm_r:
		d_arm_r.rotation_degrees = Vector3(-65, -20, 0)

	# 8. PASSENGER SEAT ROWS (Vivid Royal Blue Cushions with Beveled Tops)
	var row_z = [-1.3, 0.2, 1.7, 3.1]
	for rz in row_z:
		var s_left = _create_bus_seat_unit(true, mat_seat_blue, mat_seat_frame)
		s_left.position = Vector3(-0.88, 0, rz)
		set_van_interior.add_child(s_left)
		
		var s_right = _create_bus_seat_unit(false, mat_seat_blue, mat_seat_frame)
		s_right.position = Vector3(0.88, 0, rz)
		set_van_interior.add_child(s_right)
		
	# Protagonist sitting on Row 2 Left Window Seat (Looking out through window)
	char_player_window = _build_rigged_human("ProtagonistWindow", Color(0.95, 0.95, 0.95), Color(0.18, 0.28, 0.55), false, false, false, true, true)
	char_player_window.position = Vector3(-1.05, 0.45, 0.2)
	char_player_window.rotation_degrees = Vector3(0, 80, 0)
	set_van_interior.add_child(char_player_window)
	
	# School Kid Passenger sitting on Row 3 Right Seat
	var kid_npc = _build_rigged_human("KidPassenger", Color(0.95, 0.95, 0.95), Color(0.18, 0.28, 0.55), false, false, false, true, true)
	kid_npc.position = Vector3(0.88, 0.45, 1.7)
	kid_npc.rotation_degrees = Vector3(0, 180, 0)
	set_van_interior.add_child(kid_npc)

	# 9. SEAMLESS LOOPING EXTERIOR SCENERY (Front Windshield Road & Side Streets)
	van_scenery_scroll = Node3D.new()
	van_scenery_scroll.name = "VanSceneryScroll"
	van_scenery_scroll.position = Vector3(0, 0, 0)
	set_van_interior.add_child(van_scenery_scroll)
	
	_build_looping_scenery(van_scenery_scroll)

func _create_bus_seat_unit(is_left: bool, mat_blue: Material, mat_frame: Material) -> Node3D:
	var s_root = Node3D.new()
	
	var leg_front = CSGBox3D.new()
	leg_front.size = Vector3(0.88, 0.38, 0.05)
	leg_front.position = Vector3(0, 0.19, 0.18)
	leg_front.material = mat_frame
	s_root.add_child(leg_front)
	
	var leg_back = CSGBox3D.new()
	leg_back.size = Vector3(0.88, 0.38, 0.05)
	leg_back.position = Vector3(0, 0.19, -0.18)
	leg_back.material = mat_frame
	s_root.add_child(leg_back)
	
	var cushion = CSGBox3D.new()
	cushion.size = Vector3(0.92, 0.16, 0.50)
	cushion.position = Vector3(0, 0.44, 0)
	cushion.material = mat_blue
	s_root.add_child(cushion)
	
	var backrest = CSGBox3D.new()
	backrest.size = Vector3(0.92, 0.58, 0.12)
	backrest.position = Vector3(0, 0.77, -0.22)
	backrest.material = mat_blue
	s_root.add_child(backrest)
	
	var top_chamfer = CSGBox3D.new()
	top_chamfer.size = Vector3(0.82, 0.10, 0.11)
	top_chamfer.position = Vector3(0, 1.08, -0.22)
	top_chamfer.material = mat_blue
	s_root.add_child(top_chamfer)
	
	var handle = CSGBox3D.new()
	handle.size = Vector3(0.04, 0.16, 0.06)
	var handle_x = 0.44 if is_left else -0.44
	handle.position = Vector3(handle_x, 1.10, -0.22)
	handle.material = mat_frame
	s_root.add_child(handle)
	
	return s_root

func _build_looping_scenery(parent: Node3D) -> void:
	var mat_road = _create_mat(Color(0.24, 0.25, 0.28), 0.85, 0.0)
	var mat_yellow_line = _create_mat(Color(0.96, 0.82, 0.1), 0.5, 0.0)
	var mat_sidewalk = _create_mat(Color(0.68, 0.69, 0.72), 0.9, 0.0)
	var mat_curb = _create_mat(Color(0.5, 0.52, 0.55), 0.9, 0.0)
	
	var road = CSGBox3D.new()
	road.size = Vector3(8.4, 0.1, 100.0)
	road.position = Vector3(0, -0.1, -30.0)
	road.material = mat_road
	parent.add_child(road)
	
	for i in range(30):
		var dash = CSGBox3D.new()
		dash.size = Vector3(0.18, 0.02, 1.6)
		dash.position = Vector3(0, -0.04, 18.0 - (i * 3.6))
		dash.material = mat_yellow_line
		parent.add_child(dash)
		
	for side in [-1, 1]:
		var sidewalk = CSGBox3D.new()
		sidewalk.size = Vector3(4.5, 0.2, 100.0)
		sidewalk.position = Vector3(side * 6.5, -0.02, -30.0)
		sidewalk.material = mat_sidewalk
		parent.add_child(sidewalk)
		
		var curb = CSGBox3D.new()
		curb.size = Vector3(0.25, 0.25, 100.0)
		curb.position = Vector3(side * 4.3, 0.01, -30.0)
		curb.material = mat_curb
		parent.add_child(curb)
		
	var house_colors = [
		Color(0.92, 0.84, 0.72),
		Color(0.88, 0.75, 0.65),
		Color(0.90, 0.88, 0.80),
		Color(0.78, 0.82, 0.85)
	]
	
	for i in range(12):
		var z_pos = 15.0 - (i * 8.0)
		
		var tree_l = _create_blocky_tree()
		tree_l.position = Vector3(-5.2, 0.0, z_pos)
		parent.add_child(tree_l)
		
		var house_l = _create_blocky_house(house_colors[i % house_colors.size()])
		house_l.position = Vector3(-9.5, 0.0, z_pos - 3.5)
		house_l.rotation_degrees = Vector3(0, 90, 0)
		parent.add_child(house_l)
		
		var tree_r = _create_blocky_tree()
		tree_r.position = Vector3(5.2, 0.0, z_pos - 4.0)
		parent.add_child(tree_r)
		
		var house_r = _create_blocky_house(house_colors[(i + 1) % house_colors.size()])
		house_r.position = Vector3(9.5, 0.0, z_pos - 1.0)
		house_r.rotation_degrees = Vector3(0, -90, 0)
		parent.add_child(house_r)

func _create_blocky_tree() -> Node3D:
	var root = Node3D.new()
	var mat_wood = _create_mat(Color(0.42, 0.26, 0.15))
	var mat_leaf_1 = _create_mat(Color(0.2, 0.6, 0.22))
	var mat_leaf_2 = _create_mat(Color(0.26, 0.68, 0.28))
	var mat_leaf_3 = _create_mat(Color(0.3, 0.74, 0.32))
	
	var trunk = CSGBox3D.new()
	trunk.size = Vector3(0.45, 2.4, 0.45)
	trunk.position = Vector3(0, 1.2, 0)
	trunk.material = mat_wood
	root.add_child(trunk)
	
	var foliage_1 = CSGBox3D.new()
	foliage_1.size = Vector3(2.2, 1.2, 2.2)
	foliage_1.position = Vector3(0, 2.6, 0)
	foliage_1.material = mat_leaf_1
	root.add_child(foliage_1)
	
	var foliage_2 = CSGBox3D.new()
	foliage_2.size = Vector3(1.7, 1.0, 1.7)
	foliage_2.position = Vector3(0, 3.6, 0)
	foliage_2.material = mat_leaf_2
	root.add_child(foliage_2)
	
	var foliage_3 = CSGBox3D.new()
	foliage_3.size = Vector3(1.1, 0.8, 1.1)
	foliage_3.position = Vector3(0, 4.4, 0)
	foliage_3.material = mat_leaf_3
	root.add_child(foliage_3)
	
	return root

func _create_blocky_house(wall_col: Color) -> Node3D:
	var root = Node3D.new()
	var mat_wall = _create_mat(wall_col)
	var mat_roof = _create_mat(Color(0.65, 0.32, 0.22))
	var mat_door = _create_mat(Color(0.35, 0.22, 0.12))
	var mat_win = _create_mat(Color(0.72, 0.86, 0.95), 0.2, 0.2)
	
	var house_body = CSGBox3D.new()
	house_body.size = Vector3(4.8, 3.2, 4.2)
	house_body.position = Vector3(0, 1.6, 0)
	house_body.material = mat_wall
	root.add_child(house_body)
	
	var roof = CSGBox3D.new()
	roof.size = Vector3(5.2, 0.8, 4.6)
	roof.position = Vector3(0, 3.5, 0)
	roof.material = mat_roof
	root.add_child(roof)
	
	for wx in [-1.4, 1.4]:
		var win = CSGBox3D.new()
		win.size = Vector3(1.1, 0.9, 0.08)
		win.position = Vector3(wx, 1.8, 2.14)
		win.material = mat_win
		root.add_child(win)
		
	var door = CSGBox3D.new()
	door.size = Vector3(0.9, 1.8, 0.08)
	door.position = Vector3(0, 0.9, 2.14)
	door.material = mat_door
	root.add_child(door)
	
	return root

# --- RIGGED HUMAN BUILDER ---
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
	
	var torso = CSGBox3D.new()
	torso.size = Vector3(0.55, 0.65, 0.34)
	torso.position = Vector3(0, 1.15, 0)
	torso.material = mat_shirt
	body.add_child(torso)
	
	if has_backpack:
		var bag = CSGBox3D.new()
		bag.size = Vector3(0.42, 0.5, 0.24)
		bag.position = Vector3(0, 1.15, -0.25)
		bag.material = _create_mat(Color(0.15, 0.35, 0.75))
		body.add_child(bag)
	
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
	var mat_trunk = _create_tree_bark_material(Color(0.24, 0.15, 0.09) if not is_morning else Color(0.3, 0.2, 0.12))
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
	
	# Passenger Folding Door on Right Side (Facing sidewalk)
	van_passenger_door = Node3D.new()
	van_passenger_door.position = Vector3(1.16, 0.45, 0.0)
	van.add_child(van_passenger_door)
	
	var door_leaf = CSGBox3D.new()
	door_leaf.size = Vector3(0.06, 1.5, 0.95)
	door_leaf.position = Vector3(0.0, 0.75, 0.45)
	door_leaf.material = mat_yellow
	van_passenger_door.add_child(door_leaf)
	
	var door_win = CSGBox3D.new()
	door_win.size = Vector3(0.08, 0.65, 0.7)
	door_win.position = Vector3(0.0, 1.05, 0.45)
	door_win.material = mat_glass
	van_passenger_door.add_child(door_win)
	
	return van

# --- CUTSCENE FLOW & PROCEDURAL ANIMATIONS ---
func _start_prologue() -> void:
	# Keep normal letterbox and skip hidden until splash completes
	letterbox_top.visible = false
	letterbox_bottom.visible = false
	skip_btn.visible = false
	fade_overlay.color.a = 0.0
	
	# Start camera looking at dark start position
	cam_pivot.position = Vector3(0, 1.8, 30.0)
	cam.rotation_degrees = Vector3(-6, 0, 0)
	
	# Initial state: Pure pitch black screen, hidden splatter, 0 letters
	title_splash_root.visible = true
	title_splash_root.modulate.a = 1.0
	title_content.modulate.a = 1.0
	title_blood_splatter.modulate.a = 0.0
	title_horror_label.visible_characters = 0
	title_credits_label.visible_characters = 0
	
	# Brief suspense pause in pitch black
	await get_tree().create_timer(0.4).timeout
	if not is_title_splash_active: return
	
	if audio_heartbeat: audio_heartbeat.play()
	if audio_title_voice: audio_title_voice.play()
	
	# Blood splatter fades in behind the text
	var tw_splat = create_tween()
	tw_splat.tween_property(title_blood_splatter, "modulate:a", 0.95, 0.6)
	
	# 1. Letter-by-letter Typewriter animation for "THE HORROR MISSION" (synced with title speech ~2.2s)
	var title_len = title_horror_label.text.length()
	var tw_type1 = create_tween()
	tw_type1.tween_property(title_horror_label, "visible_characters", title_len, 2.2).set_trans(Tween.TRANS_LINEAR)
	
	await tw_type1.finished
	if not is_title_splash_active: return
	
	# Visceral shudder on title completion (subtle rotation shake, never moving position from center!)
	var tw_shk = create_tween()
	for i in range(4):
		tw_shk.tween_property(title_content, "rotation_degrees", randf_range(-1.2, 1.2), 0.04)
	tw_shk.tween_property(title_content, "rotation_degrees", 0.0, 0.05)
	
	await get_tree().create_timer(0.4).timeout
	if not is_title_splash_active: return
	
	# 2. Letter-by-letter Typewriter animation for "Created By Sahil and Written By Aashutosh" (synced with credits speech ~2.4s)
	var cred_len = title_credits_label.text.length()
	var tw_type2 = create_tween()
	tw_type2.tween_property(title_credits_label, "visible_characters", cred_len, 2.4).set_trans(Tween.TRANS_LINEAR)
	
	await tw_type2.finished
	if not is_title_splash_active: return
	
	# 3. Subtle breathing blood-red pulse
	var tw_pulse = create_tween().set_loops(2)
	tw_pulse.tween_property(title_horror_label, "scale", Vector2(1.03, 1.03), 0.8).set_trans(Tween.TRANS_SINE)
	tw_pulse.tween_property(title_horror_label, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	
	# Hold for 1.8 seconds (voice completes cleanly) then smoothly dismiss into game
	await get_tree().create_timer(1.8).timeout
	_dismiss_title_splash()

func _dismiss_title_splash() -> void:
	if not is_title_splash_active: return
	is_title_splash_active = false
	
	# Smoothly fade out title voice if still playing or if dismissed early by player tap
	if audio_title_voice and audio_title_voice.playing:
		var tw_vox = create_tween()
		tw_vox.tween_property(audio_title_voice, "volume_db", -30.0, 0.8)
		tw_vox.tween_callback(func():
			if is_instance_valid(audio_title_voice):
				audio_title_voice.stop()
		)
	
	# Ensure all letters are shown when fading out
	if title_horror_label: title_horror_label.visible_characters = -1
	if title_credits_label: title_credits_label.visible_characters = -1
	
	var tw = create_tween()
	tw.tween_property(title_splash_root, "modulate:a", 0.0, 1.1).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		title_splash_root.visible = false
		letterbox_top.visible = true
		letterbox_bottom.visible = true
		skip_btn.visible = true
		
		if audio_ambience_night: audio_ambience_night.play()
		if audio_bgm_song: audio_bgm_song.play()
		
		_advance_beat()
	)

func _process(delta: float) -> void:
	anim_time += delta
	
	# 1. Follow camera & limb walking in Beat 0
	if current_beat == 0 and char_group_walk:
		_animate_char_walk(char_sahil_walk, anim_time, 5.0)
		_animate_char_walk(char_aashu_walk, anim_time + 0.3, 5.0)
		_animate_char_walk(char_kripal_walk, anim_time + 0.6, 5.0)
		_animate_char_walk(char_player_walk, anim_time + 0.9, 5.0)
		
		# Move forward down the road together
		char_group_walk.position.z -= delta * 2.0
		cam_pivot.position.z -= delta * 2.0
	
	# 1b. Clear Road Parting & Kripal Walking in Beat 5 (Matching User Screenshot Scene)
	if current_beat == 5 and char_group_walk:
		_animate_char_walk(char_kripal_walk, anim_time, 4.8)
		_animate_char_walk(char_sahil_walk, anim_time, 4.2)
		_animate_char_walk(char_aashu_walk, anim_time + 0.3, 4.2)
		_animate_char_walk(char_player_walk, anim_time + 0.6, 4.2)
		
		# Kripal walks straight forward down the center road towards the dark forest shortcut!
		char_kripal_walk.position.z -= delta * 2.8
		
		# Sahil & Aashutosh turn left and walk into town side road
		char_sahil_walk.position.x -= delta * 2.2
		char_sahil_walk.rotation_degrees.y = -85.0
		char_aashu_walk.position.x -= delta * 2.0
		char_aashu_walk.rotation_degrees.y = -85.0
		
		# Protagonist turns right towards home
		char_player_walk.position.x += delta * 2.2
		char_player_walk.rotation_degrees.y = 85.0
		
		# Camera slowly dollies forward following Kripal down the road
		cam_pivot.position.z -= delta * 0.9
	
	# 2. Forest walk animation in Beat 6
	if current_beat == 6 and char_kripal_forest:
		_animate_char_walk(char_kripal_forest, anim_time, 4.5)
		char_kripal_forest.position.z -= delta * 1.5 # Walks forward along trail
		cam_pivot.position.z -= delta * 1.5
	
	# 3. Forest panic sprint animation in Beat 8
	if current_beat == 8 and char_kripal_forest:
		_animate_char_walk(char_kripal_forest, anim_time, 13.0, true) # Fast sprint
		char_kripal_forest.position.z += delta * 6.5 # Sprints back toward camera
	
	# 4. Ceiling fan spinning in bedroom
	if ceiling_fan_blades:
		ceiling_fan_blades.rotation.y += delta * 6.0
	
	# 5. Swaying trees (Hawa ke jhoke)
	var wind_sway = sin(anim_time * 2.2) * 0.04
	for tr in street_trees: tr.rotation.z = wind_sway
	for ft in forest_trees: ft.rotation.z = wind_sway * 0.7
	
	# 6. Forest anomaly light & scale pulse
	if current_beat in [6, 7] and forest_anomaly_light:
		var p = (sin(anim_time * 7.0) + 1.0) * 0.5
		forest_anomaly_light.light_energy = 3.5 + (p * 6.0)
		if forest_anomaly_core: forest_anomaly_core.scale = Vector3.ONE * (0.85 + p * 0.5)
	
	# 7. TV screen flickering in living room
	if current_beat in [10, 11] and tv_screen_mesh:
		var tv_mat = tv_screen_mesh.material as StandardMaterial3D
		if tv_mat:
			var flick = sin(anim_time * 14.0) * 0.2 + 0.8
			tv_mat.emission_energy_multiplier = 2.2 * flick
	
	# 8. Chai steam rising
	if tea_steam_mesh:
		tea_steam_mesh.position.y = 1.35 + (fmod(anim_time * 0.6, 0.4))
		tea_steam_mesh.scale = Vector3.ONE * (0.8 + fmod(anim_time * 0.8, 0.5))
	
	# 9. Sprinting Protagonist in Act 4 (From front porch through open gate to school van)
	if current_beat == 15 and char_player_sprint and char_player_sprint.visible:
		_animate_char_walk(char_player_sprint, anim_time, 12.0, true)
		if char_player_sprint.position.z < 3.5:
			# Running from porch (Z=-0.2) down walkway to open gate (Z=3.5)
			char_player_sprint.position.z += delta * 3.8
			char_player_sprint.rotation_degrees.y = 0.0
		elif char_player_sprint.position.x > 0.85:
			# Stepping cleanly through open gate towards van passenger door at (X=0.65, Z=5.8)
			char_player_sprint.position.x -= delta * 3.2
			char_player_sprint.position.z += delta * 2.2
			char_player_sprint.rotation_degrees.y = -60.0
		else:
			# Stepping UP onto the bus entrance step!
			char_player_sprint.position.y += delta * 2.2
			char_player_sprint.position.x -= delta * 1.5
			if char_player_sprint.position.y >= 0.4:
				char_player_sprint.visible = false # Safely inside the van!
				if audio_door_close: audio_door_close.play()
				if van_passenger_door:
					var tw_vd = create_tween()
					tw_vd.tween_property(van_passenger_door, "rotation_degrees:y", 0.0, 0.4)
		cam_pivot.position.x = lerpf(cam_pivot.position.x, 600.0 + char_player_sprint.position.x * 0.5, delta * 2.0)
	
	# 10. Van scenery scrolling and dashboard fan rotation in Act 5
	if current_beat in [16, 17, 18, 19, 20] and van_scenery_scroll:
		van_scenery_scroll.position.z += delta * 16.0
		if van_scenery_scroll.position.z >= 24.0:
			van_scenery_scroll.position.z -= 24.0
	
	if van_fan_blades:
		van_fan_blades.rotation_degrees.z += delta * 720.0
	
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

func _input(event: InputEvent) -> void:
	if is_title_splash_active:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed):
			_dismiss_title_splash()
			return
	
	# Only Keyboard Enter / Space for optional PC debugging skip, no touch screen tapping interference!
	if event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER]:
		_advance_beat()

func _on_skip_pressed() -> void:
	if skipped: return
	skipped = true
	_transition_to_classroom()

func _on_continue_pressed() -> void:
	_transition_to_classroom()

func _transition_to_classroom() -> void:
	is_beat_active = false
	if audio_bgm_song and audio_bgm_song.playing:
		var tw_audio = create_tween()
		tw_audio.tween_property(audio_bgm_song, "volume_db", -40.0, 0.7)
		tw_audio.tween_callback(func():
			if is_instance_valid(audio_bgm_song):
				audio_bgm_song.stop()
		)
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
		# --- ACT 1: WALKING UNDER BLOOD SKY (FOLLOW CAM) -> HALT & FIRST-PERSON MODE ---
		0:
			# Follow cam moving with friends down the road
			auto_advance_time = 6.0
			_show_title_card("रात 8:30 PM — लाल आसमान के साये में", "THE BLOOD SKY ROAD — PANSEMAL")
			_set_dialogue("FRIENDS (WALKING HOME)", Color(0.9, 0.85, 0.4),
				"मैच खत्म होने के बाद चारों दोस्त सड़क पर साथ-साथ बातें करते हुए आगे बढ़ रहे थे...",
				"After playing cricket, the four friends walked together down the road under the eerie blood sky...")
			
		1:
			# Friends HALT. Switch to FIRST-PERSON (FP) MODE looking directly at friends!
			auto_advance_time = 6.0
			_hide_title_card()
			fp_crosshair.visible = true
			
			char_player_walk.visible = false # Hide third person body
			char_sahil_walk.position = Vector3(-0.7, 0, -1.8)
			char_sahil_walk.rotation_degrees = Vector3(0, 155, 0)
			char_aashu_walk.position = Vector3(0.8, 0, -1.9)
			char_aashu_walk.rotation_degrees = Vector3(0, -155, 0)
			char_kripal_walk.position = Vector3(0.1, 0, -2.4)
			char_kripal_walk.rotation_degrees = Vector3(0, 180, 0)
			
			cam_pivot.position = char_group_walk.position + Vector3(0, 1.68, 0)
			cam.rotation_degrees = Vector3(-4, -15, 0) # Focus on Sahil
			
			_set_dialogue("SAHIL (FIRST-PERSON VIEW)", Color(0.35, 0.85, 0.4),
				"\"भाई सच में, आज गार्डन में क्रिकेट खेलने में बहुत मज़ा आया! लेकिन अचानक ये आसमान कितना अजीब लाल हो गया है...\"",
				"\"Bhai sach me, aaj garden me cricket khelne me bohot maza aaya! Lekin achanak ye aasman kitna ajeeb laal ho gaya hai...\"")
			_play_voice("res://audio/prologue_sahil_1.mp3")
			
		2:
			# FP Cam glances at Aashutosh
			auto_advance_time = 6.2
			_tween_cam(cam_pivot.position, Vector3(-4, 20, 0), 1.2)
			_set_dialogue("AASHUTOSH", Color(0.95, 0.65, 0.3),
				"\"हाँ यार, मौसम अचानक बहुत अजीब लग रहा है जैसे कोई तूफ़ान आने वाला हो... और 8:30 भी बज गए, कल सुबह स्कूल जाना है।\"",
				"\"Haan yaar, mausam achanak bohot ajeeb lag raha hai jaise koi toofan aane wala ho... Kal subah school jana hai.\"")
			_play_voice("res://audio/prologue_aashu_1.mp3")
			
		3:
			# Protagonist speaks in FP mode looking toward Kripal
			auto_advance_time = 6.5
			_tween_cam(cam_pivot.position, Vector3(-3, 2, 0), 1.0)
			_set_dialogue("YOU (PROTAGONIST)", Color(0.4, 0.75, 1.0),
				"\"कृपाल, तू अकेले जंगल वाले रास्ते से जाता है ना? वहाँ तो दिन में भी अँधेरा रहता है, तू मेन रोड से घूम के चला जा ना भाई?\"",
				"\"Kripal, tu akele jungle wale raste se jata hai na? Wahan to din me bhi andhera rehta hai, main road se nikal ja na?\"")
			_play_voice("res://audio/prologue_player_1.mp3")
			
		4:
			# Kripal answers carefree
			auto_advance_time = 6.5
			_tween_cam(cam_pivot.position, Vector3(-4, 0, 0), 1.0)
			_set_dialogue("KRIPAL", Color(1.0, 0.4, 0.4),
				"\"अरे भाई तुम सब इतना डरते क्यों हो? मैं तो बचपन से इसी शॉर्टकट से निकलता हूँ। कुछ नहीं होता यार! कल सुबह स्कूल वैन में मिलते हैं!\"",
				"\"Arrey bhai tum sab itna darte kyu ho? Main to bachpan se isi shortcut se nikalta hoon. Kal subah van me milte hain!\"")
			_play_voice("res://audio/prologue_kripal_1.mp3")
			
		5:
			# Clean road parting sequence (Matching user screenshot view with Kripal walking forward)
			auto_advance_time = 5.8
			fp_crosshair.visible = false
			char_player_walk.visible = true
			
			_set_dialogue("CLEAR ROAD (तीराहे पर अलग होना)", Color(0.85, 0.85, 0.9),
				"चारों दोस्त तीराहे पर अलग हो गए... साहिल-आशुतोष बाएँ मुड़े, और कृपाल घने अंधेरे जंगल की तरफ चल पड़ा...",
				"The friends parted ways on the clear road... Kripal headed forward into the dark forest path...")
			
			# Position group right at the crossroads (Z = -20.0) facing -Z down the clear road!
			char_group_walk.position = Vector3(0, 0, -20.0)
			char_sahil_walk.position = Vector3(-1.0, 0, 0.2)
			char_sahil_walk.rotation_degrees = Vector3(0, 0, 0)
			char_aashu_walk.position = Vector3(-0.3, 0, 0.5)
			char_aashu_walk.rotation_degrees = Vector3(0, 0, 0)
			char_player_walk.position = Vector3(1.2, 0, 0.4)
			char_player_walk.rotation_degrees = Vector3(0, 0, 0)
			char_kripal_walk.position = Vector3(0.0, 0, -0.8)
			char_kripal_walk.rotation_degrees = Vector3(0, 0, 0)
			
			# Camera framing clear road directly behind the group looking down the road, matching user photo!
			cam_pivot.position = Vector3(0, 2.3, -15.5)
			cam.rotation_degrees = Vector3(-6, 0, 0)
			
		# --- ACT 2: DENSE FOREST & GLOWING ANOMALY (CLEAR LINE OF SIGHT) ---
		6:
			# Kripal walking down the forest trail towards the brilliant light!
			auto_advance_time = 6.0
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(200, 1.8, 14.0) # Directly behind Kripal looking forward
				cam.rotation_degrees = Vector3(-6, 0, 0) # Clear view of Kripal AND the glowing light ahead!
			)
			_set_dialogue("DENSE FOREST — 8:45 PM", Color(0.6, 0.85, 1.0),
				"रात का गहरा सन्नाटा... पेड़ों के बीच अजीब नीली रौशनी... कृपाल अकेला जंगल के रास्ते पर चल रहा था...",
				"The deep silence of the forest... Kripal walks alone along the dark dirt trail towards the strange light...")
			
		7:
			# Kripal stops, camera cuts to an over-the-shoulder close view of the pulsing light!
			auto_advance_time = 5.5
			_tween_cam(Vector3(200.5, 1.7, 3.0), Vector3(-4, 0, 0), 2.0)
			if audio_whisper: audio_whisper.play()
			
			_set_dialogue("KRIPAL", Color(1.0, 0.4, 0.4),
				"\"ये... ये जंगल के इतने अंदर ऐसी अजीब नीली रौशनी कहाँ से आ रही है...? यहाँ तो कोई रहता भी नहीं...\"",
				"\"Ye... ye jungle ke itne andar aisi ajeeb neeli roshni kahan se aa rahi hai...? Yahan to koi rehta bhi nahi...\"")
			_play_voice("res://audio/prologue_kripal_forest1.mp3")
			
		8:
			# Anomaly flares up / Jump shock & Kripal PANIC SPRINT
			auto_advance_time = 5.5
			if audio_jumpscare: audio_jumpscare.play()
			if audio_heartbeat: audio_heartbeat.play()
			
			# Flash terrifying ghost face on screen for 0.4s
			if jumpscare_flash_rect:
				var tex_ghost = load("res://textures/ghost_face_1_hollow.png")
				if not tex_ghost: tex_ghost = load("res://textures/ghost_jumpscare.png")
				jumpscare_flash_rect.texture = tex_ghost
				jumpscare_flash_rect.visible = true
				jumpscare_flash_rect.modulate.a = 0.95
				jumpscare_flash_rect.scale = Vector2(0.9, 0.9)
				var tw_fl = create_tween()
				tw_fl.tween_property(jumpscare_flash_rect, "scale", Vector2(1.5, 1.5), 0.38)
				tw_fl.parallel().tween_property(jumpscare_flash_rect, "modulate:a", 0.0, 0.38)
				tw_fl.tween_callback(func(): jumpscare_flash_rect.visible = false)
			
			# Face camera on Kripal turning in sheer terror!
			cam_pivot.position = Vector3(200, 1.6, 8.0)
			cam.rotation_degrees = Vector3(-4, 180, 0) # Looking at Kripal's terrified face!
			char_kripal_forest.rotation_degrees.y = 0.0 # Turned to run back
			
			_set_dialogue("KRIPAL (PANIC SPRINT)", Color(1.0, 0.2, 0.2),
				"\"न-नहीं... ये क्या चीज़ है?!! ये तो मेरी तरफ आ रही है!! मुझे यहाँ से भागना होगा!!\"",
				"\"N-Nahi... Ye kya cheez hai?!! Ye to meri taraf aa rahi hai!! Mujhe bhagna hoga!!\"")
			_play_voice("res://audio/prologue_kripal_panic.mp3")
			
			var tw_shk = create_tween()
			for i in range(8):
				tw_shk.tween_property(cam, "position", Vector3(randf_range(-0.18, 0.18), randf_range(-0.18, 0.18), 0), 0.05)
			tw_shk.tween_property(cam, "position", Vector3.ZERO, 0.1)
			
		9:
			# Kripal slams his house door shut
			auto_advance_time = 4.5
			if audio_door_open: audio_door_open.play()
			char_kripal_forest.visible = false
			
			_set_dialogue("KRIPAL'S HOUSE", Color(0.9, 0.8, 0.3),
				"कृपाल बदहवास हालत में सरपट भागते हुए जंगल से बाहर निकला और अपने घर का दरवाजा धड़ाम से बंद कर लिया!",
				"In sheer terror, Kripal sprinted out of the woods, reached his house and slammed the door shut!")
			
		# --- ACT 3: FULL TWO-STORY MODERN HOUSE (Matching User Reference Panels 2, 3, 4, 5, 6) ---
		10:
			# Panel 2: Arjun's Room (Bed with blue pixel quilt, Game On & Crown posters, blue rug, gaming PC desk)
			auto_advance_time = 6.2
			if audio_ambience_night and audio_ambience_night.playing: audio_ambience_night.stop()
			if audio_heartbeat and audio_heartbeat.playing: audio_heartbeat.stop()
			if audio_ambience_morning: audio_ambience_morning.play()
			
			world_env.environment = morning_sky_env
			blood_sky_light.visible = false
			sun_light.visible = true
			
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(396.6, 4.65, 4.2) # Framing Arjun's Room matching Panel 2
				cam.rotation_degrees = Vector3(-13, 30, 0)
			)
			
			_show_title_card("अगली सुबह — 7:15 AM", "THE NEXT MORNING — ARJUN'S ROOM")
			_set_dialogue("ARJUN'S ROOM (कमरे में सोते हुए)", Color(0.4, 0.75, 1.0),
				"सुबह 7:15... नीले पर्दों से छनकर खिड़की से मीठी धूप आ रही है... पंखा घूम रहा है और आप गहरी नींद में सो रहे हैं...",
				"7:15 AM... Morning sunlight filters through the blue curtains... Game On posters on wall as you sleep peacefully in bed...")
			
		11:
			# Panel 3 & 5: Hall (Living Room) with Papa on Navy Sofa, TV with glowing cyan LED backlight halo, open glass staircase & mezzanine!
			auto_advance_time = 5.8
			_hide_title_card()
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(394.2, 1.55, 0.2) # Living room view framing Papa, TV with cyan LED halo & staircase
				cam.rotation_degrees = Vector3(-6, -24, 0)
			)
			_set_dialogue("PAPA (LIVING ROOM MEIN TV DEKHTE HUE)", Color(1.0, 0.85, 0.35),
				"\"अरे बेटा! 7:15 हो गए... उठ जाओ जल्दी! आज फिर तुम्हारी स्कूल वैन छूट जाएगी!\"",
				"\"Arrey beta! 7:15 ho gaye... Uth jao jaldi! Aaj phir school van chhoot jayegi!\"")
			_play_voice("res://audio/prologue_papa_call.mp3")
			
		12:
			# Panel 4: Modular Kitchen with Mummy at Stove, Chimney Hood, Water Dispenser & Fridge
			auto_advance_time = 5.8
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(403.8, 1.55, -0.6) # Kitchen view framing Mummy, chimney hood, water dispenser & dining
				cam.rotation_degrees = Vector3(-8, -12, 0)
			)
			_set_dialogue("MUMMY (KITCHEN SE CHAI BANATE HUE)", Color(1.0, 0.45, 0.55),
				"\"चाय बन गई है! पहले मुँह-हाथ धो लो और स्कूल यूनिफॉर्म पहनो! वैन किसी भी वक्त पहुँचती होगी!\"",
				"\"Chai ban gayi hai! Pehle muh-haath dho lo aur uniform pehno! Van kisi bhi waqt pahunchti hogi!\"")
			_play_voice("res://audio/prologue_mummy_call.mp3")
			
		13:
			# Panel 2: Waking Up in Bedroom
			auto_advance_time = 5.5
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(396.6, 4.65, 4.2)
				cam.rotation_degrees = Vector3(-13, 30, 0)
			)
			
			var tw_bed = create_tween()
			tw_bed.tween_property(char_player_sleeping, "rotation_degrees:x", 0.0, 1.8)
			
			_set_dialogue("PROTAGONIST (BEDROOM MEIN UTH TE HUE)", Color(0.4, 0.75, 1.0),
				"\"हाँ पापा, हाँ मम्मी... उठ रहा हूँ बस 5 मिनट! चाय नीचे आके पीता हूँ...\"",
				"\"Haan Papa, haan Mummy! Bas 5 minute... uth raha hoon! Chai peeta hoon...\"")
			_play_voice("res://audio/prologue_player_wake.mp3")
			
		# --- ACT 4: MODERN VILLA EXTERIOR, A-101 GATE & VAN SPRINT (Panel 1) ---
		14:
			# Panel 1: Modern Two-Story Villa Exterior with A-101 plaque, black slat gate, hedge boundary & school van
			auto_advance_time = 6.5
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(602.5, 2.4, 9.8) # Full view of modern villa matching Panel 1
				cam.rotation_degrees = Vector3(-6, 0, 0)
			)
			if audio_van_horn: audio_van_horn.play()
			
			# Gate swings open cleanly for arrival
			if gate_pivot_l:
				create_tween().tween_property(gate_pivot_l, "rotation_degrees:y", -95.0, 1.2)
			if gate_pivot_r:
				create_tween().tween_property(gate_pivot_r, "rotation_degrees:y", 95.0, 1.2)
			
			# Van passenger door opens ready for student
			if van_passenger_door:
				create_tween().tween_property(van_passenger_door, "rotation_degrees:y", 85.0, 1.0)
			
			_set_dialogue("SCHOOL VAN DRIVER UNCLE (BEEP BEEP!)", Color(1.0, 0.88, 0.2),
				"\"भाभी जी! जल्दी भेजो ना बच्चे को! 7:35 हो गए हैं, आगे कृपाल और बाकी बच्चों को भी पिक करना है... लेट हो रहा है!\"",
				"\"Bhabhi ji! Jaldi bhejo na bachhe ko! 7:35 ho gaye hain, aage Kripal aur baki bachhon ko bhi lena hai... late ho raha hai!\"")
			_play_voice("res://audio/prologue_driver_call.mp3")
			
		15:
			# Panel 1: Front door swings open cleanly on hinge, Arjun steps out from porch, through open gate into van
			auto_advance_time = 5.8
			if front_door_pivot:
				create_tween().tween_property(front_door_pivot, "rotation_degrees:y", -105.0, 0.8)
			char_player_sprint.visible = true
			char_player_sprint.position = Vector3(2.5, 0, -0.2)
			char_player_sprint.rotation_degrees = Vector3(0, 0, 0)
			_tween_cam(Vector3(602.0, 2.0, 6.2), Vector3(-6, -26, 0), 4.5)
			_set_dialogue("PROTAGONIST RUNNING TO VAN", Color(0.35, 0.85, 0.95),
				"\"अरे बाप रे! वैन तो आ भी गई! जल्दी बैग पकड़ो!\"\n— आप गेट से दौड़ते हुए स्कूल वैन में बैठ जाते हैं!",
				"\"Arey baap re! Van to aa bhi gayi! Jaldi bag pakdo!\"\n— You sprint through the open gate and board the school van!")
			_play_voice("res://audio/prologue_player_hurry.mp3")
			
		# --- ACT 5: INDIAN SCHOOL VAN INTERIOR & WINDOW GAZING (SONG / BGM SCENE) ---
		16:
			# Panel 1 & 4 View: Front-to-back aisle view showing blue seats, yellow roof, glowing LEDs, and rear Emergency Exit
			auto_advance_time = 5.8
			if audio_door_close: audio_door_close.play()
			if audio_van_engine: audio_van_engine.play()
			
			_fade_to_black_and_call(func():
				cam_pivot.position = Vector3(800.0, 1.48, -1.8)
				cam.rotation_degrees = Vector3(-4, 180, 0)
			)
			_set_dialogue("INSIDE SCHOOL BUS (वैन चल पड़ी)", Color(1.0, 0.85, 0.3),
				"\"रोज़ का यही नाटक है तुम्हारा... चलो बैठो जल्दी, दरवाजा बंद करो!\"\n— वैन का दरवाजा बंद हुआ और वैन आगे बढ़ी...",
				"\"Roz ka yahi naatak hai tumhara... chalo baitho jaldi, darwaja band karo!\"\n— The school bus drove forward down the sunny streets...")
			_play_voice("res://audio/prologue_driver_inside.mp3")
			
		17:
			# Panel 2 View: Driver over-the-shoulder looking forward through windshield down the road
			auto_advance_time = 6.2
			_tween_cam(Vector3(799.62, 1.48, -1.9), Vector3(-3, 0, 0), 1.2)
			
			_set_dialogue("SCHOOL BUS DRIVER (ON THE ROAD)", Color(1.0, 0.85, 0.2),
				"\"चलो भाई सब लोग संभल के बैठो! वैन टाइम से पहुंचनी चाहिए आज!\"\n— सुबह की धूप में वैन सड़क पर आगे बढ़ती है...",
				"\"Chalo bhai sab log sambhal ke baitho! Van time se pahunchni chahiye aaj!\"\n— The bus cruises down the sunny street under the bright morning sun...")
			
		18:
			# Panel 3 View: Across the aisle looking at Protagonist seated by the window
			auto_advance_time = 6.8
			_tween_cam(Vector3(800.5, 1.35, -0.3), Vector3(-3, 130, 0), 1.2)
			
			_set_dialogue("PROTAGONIST (LOOKING OUT THE WINDOW)", Color(0.4, 0.8, 1.0),
				"खिड़की से बाहर सुबह की ठंडी हवा, पेड़ और घर पीछे छूट रहे हैं... और वैन कृपाल के घर की तरफ मुड़ रही है...",
				"Looking out the window past the safety bars as morning breeze, trees and houses rush past... the van turns towards Kripal's house...")
			
		19:
			# Cinematic 3/4 Window Gazing Close-Up
			auto_advance_time = 6.5
			_tween_cam(Vector3(799.35, 1.3, 0.55), Vector3(-2, -100, 0), 1.0)
			
			_set_dialogue("PROTAGONIST (मन में सोचते हुए)", Color(0.4, 0.75, 1.0),
				"\"वैन अब कृपाल के घर की तरफ मुड़ रही है... पर कल रात से उसका फोन स्विच ऑफ क्यों आ रहा है...? क्या रात को सच में कुछ हुआ था...?\"",
				"\"Van ab Kripal ke ghar ki taraf mud rahi hai... Par kal raat se uska phone switch off kyu aa raha hai...? Kya raat ko sach me kuchh hua tha...?\"")
			_play_voice("res://audio/prologue_player_window.mp3")
			
		20:
			# Driver mentions Kripal as bus approaches
			auto_advance_time = 5.2
			_tween_cam(Vector3(799.8, 1.45, -1.6), Vector3(-2, -35, 0), 1.0)
			
			_set_dialogue("VAN DRIVER", Color(1.0, 0.85, 0.2),
				"\"देखते हैं आज कृपाल तैयार मिलता है या वो भी सोता ही मिलेगा...\"",
				"\"Dekhte hain aaj Kripal taiyaar milta hai ya wo bhi sota hi milega...\"")
			
		21:
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
