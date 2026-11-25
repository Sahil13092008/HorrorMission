extends Node3D

# ==============================================================
# CYCLE_TO_SCHOOL.GD
# Playable Bicycle Ride from Home to Boys School (बॉयज़ स्कूल)
# Protagonist rides with backpack strapped to his back, arrives
# at Boys School, meets Sahil and Aashutosh, and finalizes the
# plan for Bhangarh Ruins!
# ==============================================================

# --- STATE & PHYSICS CONSTANTS ---
const CYCLE_SPEED: float = 9.5
const SPRINT_CYCLE_SPEED: float = 14.5
const ACCEL: float = 18.0
const TURN_SPEED: float = 2.2
const SCHOOL_GATE_Z: float = -92.0

var player_pos: Vector3 = Vector3(0.0, 0.0, 20.0)
var player_velocity: Vector3 = Vector3.ZERO
var rider_heading: float = 0.0 # Facing towards -Z
var cycle_tilt: float = 0.0
var pedal_phase: float = 0.0
var is_sprinting: bool = false
var is_arrived: bool = false
var cutscene_active: bool = false
var dialogue_idx: int = 0
var can_advance_dialogue: bool = false

# Touch control flags for mobile
var touch_pedal: bool = false
var touch_brake: bool = false
var touch_left: bool = false
var touch_right: bool = false
var touch_sprint: bool = false

# --- NODE REFERENCES ---
var world_env: WorldEnvironment
var sun_light: DirectionalLight3D
var cam_pivot: Node3D
var cam: Camera3D

var road_root: Node3D
var school_root: Node3D
var beacon_beam: CSGCylinder3D
var beacon_light: OmniLight3D

# Bicycle & Rider
var player_root: Node3D
var bike_frame: Node3D
var wheel_front: Node3D
var wheel_rear: Node3D
var pedal_crank: Node3D
var headlight_spot: SpotLight3D
var rider_backpack: Node3D
var rider_leg_l: Node3D
var rider_leg_r: Node3D
var rider_arm_l: Node3D
var rider_arm_r: Node3D

# Companions
var comp_sahil: Node3D
var comp_aashu: Node3D

# Audio Players
var audio_ambience: AudioStreamPlayer
var audio_cycle: AudioStreamPlayer
var audio_bell: AudioStreamPlayer
var audio_voice: AudioStreamPlayer

# UI Nodes
var ui_root: CanvasLayer
var mission_banner: PanelContainer
var banner_label: Label
var dist_label: Label
var subtitle_panel: PanelContainer
var speaker_label: Label
var dialogue_label: Label
var advance_tip: Label
var skip_btn: Button
var touch_hud: Control
var arrival_card: PanelContainer
var proceed_btn: Button

# Dialogues at Boys School
var arrival_dialogues = [
	{
		"speaker": "🧢 साहिल (SAHIL) — [बॉयज़ स्कूल गेट पर]",
		"color": Color(1.0, 0.85, 0.3),
		"text": "\"अरे आ गया भाई! सब गैजेट्स और जरूरी सामान ले आया ना बैग में?\""
	},
	{
		"speaker": "🎒 तू (YOU / खिलाड़ी) — [साइकिल से उतरते हुए]",
		"color": Color(0.35, 0.95, 1.0),
		"text": "\"हाँ भाई! टॉर्च, ईएमएफ डिटेक्टर, वॉकी-टॉकी और भानगढ़ के सारे नोट्स बैग में पैक हैं! तुम दोनों बताओ, क्या तैयारी है?\""
	},
	{
		"speaker": "👓 आशुतोष (AASHUTOSH) — [बैग दिखाते हुए]",
		"color": Color(0.45, 0.8, 1.0),
		"text": "\"मैंने सारा भानगढ़ का नक्शा, थर्मल सेंसर्स और एक्स्ट्रा बैटरियाँ पैक कर ली हैं। भानगढ़ के पुराने मुख्य द्वार के पास एक गुप्त रास्ता है, हमें वहीं से अंदर दाखिल होना होगा!\""
	},
	{
		"speaker": "🧢 साहिल (SAHIL)",
		"color": Color(1.0, 0.85, 0.3),
		"text": "\"बिल्कुल सही! आज रात हमें किसी भी हाल में भानगढ़ खंडहर के अंदर जाकर कृपाल को तलाशना होगा! चलो, सीधे भानगढ़ के लिए निकलते हैं!\""
	}
]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_setup_lighting_and_sky()
	_setup_audio()
	_build_street_environment()
	_build_boys_school()
	_build_player_bicycle()
	_build_companions_at_school()
	_build_ui()
	
	if audio_ambience: audio_ambience.play()

# --- AUDIO HELPERS ---
func _load_audio_safe(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream: return res
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var bytes = f.get_buffer(f.get_length())
			if path.ends_with(".wav"):
				var wav = AudioStreamWAV.new()
				if bytes.size() > 44 and bytes.slice(0, 4).get_string_from_ascii() == "RIFF":
					wav.data = bytes.slice(44)
				else:
					wav.data = bytes
				return wav
			elif path.ends_with(".mp3"):
				var mp3 = AudioStreamMP3.new()
				mp3.data = bytes
				return mp3
	return null

func _setup_audio() -> void:
	var a_root = Node.new()
	a_root.name = "AudioRoot"
	add_child(a_root)
	
	audio_ambience = AudioStreamPlayer.new()
	audio_ambience.stream = _load_audio_safe("res://audio/street_ambience.wav")
	if not audio_ambience.stream: audio_ambience.stream = _load_audio_safe("res://audio/ambience.wav")
	audio_ambience.volume_db = -6.0
	a_root.add_child(audio_ambience)
	
	audio_cycle = AudioStreamPlayer.new()
	audio_cycle.stream = _load_audio_safe("res://audio/cycle_riding.wav")
	if not audio_cycle.stream: audio_cycle.stream = _load_audio_safe("res://audio/bicycle_ride.wav")
	audio_cycle.volume_db = -4.0
	a_root.add_child(audio_cycle)
	
	audio_bell = AudioStreamPlayer.new()
	audio_bell.stream = _load_audio_safe("res://audio/cycle_bell.wav")
	audio_bell.volume_db = 2.0
	a_root.add_child(audio_bell)
	
	audio_voice = AudioStreamPlayer.new()
	audio_voice.volume_db = 4.0
	a_root.add_child(audio_voice)

# --- ENVIRONMENT & LIGHTING ---
func _setup_lighting_and_sky() -> void:
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.10, 0.18) # Deep evening twilight
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.42, 0.38)
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.24, 0.16, 0.22)
	env.fog_density = 0.012
	
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Warm evening low sun
	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.72, 0.45)
	sun_light.light_energy = 1.1
	sun_light.rotation_degrees = Vector3(-25.0, 45.0, 0.0)
	sun_light.shadow_enabled = true
	add_child(sun_light)
	
	# Follow camera pivot
	cam_pivot = Node3D.new()
	cam_pivot.name = "CameraPivot"
	add_child(cam_pivot)
	
	cam = Camera3D.new()
	cam.current = true
	cam.fov = 68.0
	cam.position = Vector3(0.0, 2.1, 4.4)
	cam.rotation_degrees = Vector3(-11.0, 0.0, 0.0)
	cam_pivot.add_child(cam)

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

# --- STREET ENVIRONMENT ---
func _build_street_environment() -> void:
	road_root = Node3D.new()
	road_root.name = "RoadRoot"
	add_child(road_root)
	
	var mat_road = _create_mat(Color(0.14, 0.14, 0.16), 0.9)
	var mat_sidewalk = _create_mat(Color(0.26, 0.24, 0.22), 0.85)
	var mat_dash = _create_mat(Color(0.92, 0.85, 0.25), 0.7)
	var mat_pole = _create_mat(Color(0.25, 0.25, 0.28), 0.4, 0.6)
	var mat_bulb = _create_mat(Color(1.0, 0.9, 0.5), 0.2, 0.0, Color(1.0, 0.85, 0.4), 3.5)
	var mat_hedge = _create_mat(Color(0.12, 0.32, 0.14), 0.9)
	var mat_wall = _create_mat(Color(0.42, 0.40, 0.38), 0.85)
	
	# Main Asphalt Road (Z from 35 down to -105 = 140m long, width = 8.6m)
	var road = CSGBox3D.new()
	road.size = Vector3(8.6, 0.1, 140.0)
	road.position = Vector3(0.0, -0.05, -35.0)
	road.material = mat_road
	road_root.add_child(road)
	
	# Yellow centerline dashes
	for z in range(-90, 32, 6):
		var dash = CSGBox3D.new()
		dash.size = Vector3(0.24, 0.11, 2.6)
		dash.position = Vector3(0.0, 0.01, float(z))
		dash.material = mat_dash
		road_root.add_child(dash)
	
	# Sidewalks (Left and Right)
	var sw_l = CSGBox3D.new()
	sw_l.size = Vector3(3.2, 0.22, 140.0)
	sw_l.position = Vector3(-5.9, 0.02, -35.0)
	sw_l.material = mat_sidewalk
	road_root.add_child(sw_l)
	
	var sw_r = CSGBox3D.new()
	sw_r.size = Vector3(3.2, 0.22, 140.0)
	sw_r.position = Vector3(5.9, 0.02, -35.0)
	sw_r.material = mat_sidewalk
	road_root.add_child(sw_r)
	
	# Street Lamp Posts & Warm OmniLights along sidewalk every 18m
	for z_lamp in range(-80, 30, 18):
		var side = -1 if (z_lamp % 36 == 0) else 1
		var pole_x = side * 5.2
		
		var pole = CSGBox3D.new()
		pole.size = Vector3(0.14, 5.2, 0.14)
		pole.position = Vector3(pole_x, 2.6, float(z_lamp))
		pole.material = mat_pole
		road_root.add_child(pole)
		
		var arm = CSGBox3D.new()
		arm.size = Vector3(1.2, 0.10, 0.10)
		arm.position = Vector3(pole_x + (-side * 0.5), 5.15, float(z_lamp))
		arm.material = mat_pole
		road_root.add_child(arm)
		
		var bulb = CSGSphere3D.new()
		bulb.radius = 0.18
		bulb.position = Vector3(pole_x + (-side * 0.95), 5.0, float(z_lamp))
		bulb.material = mat_bulb
		road_root.add_child(bulb)
		
		var lamp_light = OmniLight3D.new()
		lamp_light.position = Vector3(pole_x + (-side * 0.95), 4.8, float(z_lamp))
		lamp_light.light_color = Color(1.0, 0.88, 0.65)
		lamp_light.light_energy = 2.4
		lamp_light.omni_range = 14.0
		road_root.add_child(lamp_light)
		
		# Trees & Green Hedges along edges
		var tree_trunk = CSGCylinder3D.new()
		tree_trunk.radius = 0.22
		tree_trunk.height = 3.2
		tree_trunk.position = Vector3(side * 8.2, 1.6, float(z_lamp) + 4.0)
		tree_trunk.material = _create_mat(Color(0.28, 0.18, 0.10), 0.9)
		road_root.add_child(tree_trunk)
		
		var foliage = CSGSphere3D.new()
		foliage.radius = 1.4
		foliage.position = Vector3(side * 8.2, 3.8, float(z_lamp) + 4.0)
		foliage.material = mat_hedge
		road_root.add_child(foliage)
		
		# Neighborhood boundary walls
		var wall = CSGBox3D.new()
		wall.size = Vector3(0.3, 1.6, 12.0)
		wall.position = Vector3(side * 8.5, 0.8, float(z_lamp))
		wall.material = mat_wall
		road_root.add_child(wall)
	
	# Roadside Direction Signboard at Z = -25m
	var sign_root = Node3D.new()
	sign_root.position = Vector3(4.8, 0, -25.0)
	road_root.add_child(sign_root)
	
	var sign_pole = CSGBox3D.new()
	sign_pole.size = Vector3(0.12, 2.8, 0.12)
	sign_pole.position = Vector3(0, 1.4, 0)
	sign_pole.material = mat_pole
	sign_root.add_child(sign_pole)
	
	var sign_board = CSGBox3D.new()
	sign_board.size = Vector3(0.06, 0.95, 2.4)
	sign_board.position = Vector3(-0.02, 2.3, 0)
	sign_board.material = _create_mat(Color(0.08, 0.42, 0.22), 0.5) # Green highway board
	sign_root.add_child(sign_board)
	
	var sign_lbl = Label3D.new()
	sign_lbl.text = "🏫 शासकीय उत्कृष्ट बालक उच्चतर माध्यमिक विद्यालय ➔\n[GOVT. BOYS HIGHER SECONDARY SCHOOL — 70M]"
	sign_lbl.font_size = 28
	sign_lbl.modulate = Color(1.0, 1.0, 1.0)
	sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_lbl.position = Vector3(-0.06, 2.3, 0)
	sign_lbl.rotation_degrees = Vector3(0, -90, 0)
	sign_root.add_child(sign_lbl)

# --- BOYS SCHOOL BUILDING & GATES (Z = -95m) ---
func _build_boys_school() -> void:
	school_root = Node3D.new()
	school_root.name = "SchoolRoot"
	school_root.position = Vector3(0, 0, SCHOOL_GATE_Z)
	add_child(school_root)
	
	var mat_brick = _create_mat(Color(0.68, 0.28, 0.22), 0.8) # Classic Indian red brick school
	var mat_stone_cream = _create_mat(Color(0.92, 0.88, 0.80), 0.65) # Cream stone arches
	var mat_iron_gate = _create_mat(Color(0.12, 0.12, 0.14), 0.4, 0.8) # Black iron gate
	var mat_glass_win = _create_mat(Color(0.15, 0.22, 0.35), 0.2, 0.6)
	var mat_gold_arch = _create_mat(Color(0.95, 0.82, 0.25), 0.4, 0.7)
	
	# Courtyard Pavement inside school
	var court = CSGBox3D.new()
	court.size = Vector3(32.0, 0.12, 35.0)
	court.position = Vector3(0, -0.05, -17.5)
	court.material = _create_mat(Color(0.32, 0.32, 0.34))
	school_root.add_child(court)
	
	# Grand Entrance Gate Pillars (Left & Right)
	var pillar_l = CSGBox3D.new()
	pillar_l.size = Vector3(1.3, 4.8, 1.3)
	pillar_l.position = Vector3(-4.6, 2.4, 0)
	pillar_l.material = mat_stone_cream
	school_root.add_child(pillar_l)
	
	var pillar_r = CSGBox3D.new()
	pillar_r.size = Vector3(1.3, 4.8, 1.3)
	pillar_r.position = Vector3(4.6, 2.4, 0)
	pillar_r.material = mat_stone_cream
	school_root.add_child(pillar_r)
	
	# Arch Header Beam over gate
	var arch_beam = CSGBox3D.new()
	arch_beam.size = Vector3(10.5, 1.1, 0.9)
	arch_beam.position = Vector3(0, 4.8, 0)
	arch_beam.material = mat_stone_cream
	school_root.add_child(arch_beam)
	
	# Prominent School Nameplate
	var name_board = CSGBox3D.new()
	name_board.size = Vector3(9.2, 0.75, 0.12)
	name_board.position = Vector3(0, 4.8, 0.48)
	name_board.material = _create_mat(Color(0.12, 0.18, 0.45), 0.5) # Deep navy school plaque
	school_root.add_child(name_board)
	
	var name_lbl = Label3D.new()
	name_lbl.text = "🏫 शासकीय उत्कृष्ट बालक उच्चतर माध्यमिक विद्यालय — पानसेमल\n[GOVT. EXCELLENCE BOYS HIGHER SECONDARY SCHOOL]"
	name_lbl.font_size = 32
	name_lbl.modulate = Color(1.0, 0.92, 0.4) # Golden letters
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector3(0, 4.8, 0.56)
	school_root.add_child(name_lbl)
	
	# Wrought Iron School Gates (Open on sides)
	var gate_l = CSGBox3D.new()
	gate_l.size = Vector3(3.2, 3.2, 0.08)
	gate_l.position = Vector3(-3.2, 1.6, -1.2)
	gate_l.rotation_degrees = Vector3(0, 45, 0) # Swung open
	gate_l.material = mat_iron_gate
	school_root.add_child(gate_l)
	
	var gate_r = CSGBox3D.new()
	gate_r.size = Vector3(3.2, 3.2, 0.08)
	gate_r.position = Vector3(3.2, 1.6, -1.2)
	gate_r.rotation_degrees = Vector3(0, -45, 0) # Swung open
	gate_r.material = mat_iron_gate
	school_root.add_child(gate_r)
	
	# Main 2-Story School Building Facade
	var main_bldg = CSGBox3D.new()
	main_bldg.size = Vector3(28.0, 9.2, 12.0)
	main_bldg.position = Vector3(0, 4.6, -22.0)
	main_bldg.material = mat_brick
	school_root.add_child(main_bldg)
	
	# Central Entrance Portico with Colonial Pillars
	var portico = CSGBox3D.new()
	portico.size = Vector3(10.0, 7.5, 4.5)
	portico.position = Vector3(0, 3.75, -15.5)
	portico.material = mat_stone_cream
	school_root.add_child(portico)
	
	# Classroom Windows grid on facade
	for wx in [-10.5, -6.5, 6.5, 10.5]:
		for wy in [2.5, 6.2]:
			var win = CSGBox3D.new()
			win.size = Vector3(2.4, 2.0, 0.15)
			win.position = Vector3(wx, wy, -15.8)
			win.material = mat_glass_win
			school_root.add_child(win)
	
	# School Clock on pediment
	var clock = CSGCylinder3D.new()
	clock.radius = 0.65
	clock.height = 0.15
	clock.position = Vector3(0, 6.8, -13.2)
	clock.rotation_degrees = Vector3(90, 0, 0)
	clock.material = _create_mat(Color(0.95, 0.95, 0.95), 0.3)
	school_root.add_child(clock)
	
	# Warm Entrance Portico Floodlight
	var portico_light = OmniLight3D.new()
	portico_light.position = Vector3(0, 4.2, -13.0)
	portico_light.light_color = Color(1.0, 0.92, 0.72)
	portico_light.light_energy = 3.5
	portico_light.omni_range = 18.0
	school_root.add_child(portico_light)
	
	# Vertical Golden Waypoint Beacon Beam (Guides the player directly from home to school!)
	beacon_beam = CSGCylinder3D.new()
	beacon_beam.radius = 0.75
	beacon_beam.height = 50.0
	beacon_beam.position = Vector3(0, 25.0, -2.0)
	beacon_beam.material = _create_mat(Color(1.0, 0.85, 0.25, 0.35), 0.1, 0.0, Color(1.0, 0.8, 0.2), 3.0)
	beacon_beam.transparency = 0.4
	school_root.add_child(beacon_beam)
	
	beacon_light = OmniLight3D.new()
	beacon_light.position = Vector3(0, 2.5, -2.0)
	beacon_light.light_color = Color(1.0, 0.82, 0.25)
	beacon_light.light_energy = 2.8
	beacon_light.omni_range = 16.0
	school_root.add_child(beacon_light)

# --- PLAYER BICYCLE & PROTAGONIST WITH BACKPACK ---
func _build_player_bicycle() -> void:
	player_root = Node3D.new()
	player_root.name = "PlayerRider"
	player_root.position = player_pos
	add_child(player_root)
	
	bike_frame = Node3D.new()
	bike_frame.name = "BikeFrame"
	player_root.add_child(bike_frame)
	
	var mat_frame = _create_mat(Color(0.12, 0.25, 0.45), 0.4, 0.7) # Dark metallic blue cycle
	var mat_metal = _create_mat(Color(0.65, 0.65, 0.68), 0.25, 0.85) # Chrome components
	var mat_tire = _create_mat(Color(0.10, 0.10, 0.12), 0.85) # Black rubber
	var mat_saddle = _create_mat(Color(0.18, 0.12, 0.08), 0.7)
	
	# Main Diamond Frame Tubes
	var tube_top = CSGBox3D.new()
	tube_top.size = Vector3(0.06, 0.06, 0.82)
	tube_top.position = Vector3(0, 0.82, -0.05)
	tube_top.rotation_degrees = Vector3(-8.0, 0, 0)
	tube_top.material = mat_frame
	bike_frame.add_child(tube_top)
	
	var tube_down = CSGBox3D.new()
	tube_down.size = Vector3(0.06, 0.06, 0.92)
	tube_down.position = Vector3(0, 0.60, -0.08)
	tube_down.rotation_degrees = Vector3(38.0, 0, 0)
	tube_down.material = mat_frame
	bike_frame.add_child(tube_down)
	
	var tube_seat = CSGBox3D.new()
	tube_seat.size = Vector3(0.06, 0.06, 0.72)
	tube_seat.position = Vector3(0, 0.64, 0.28)
	tube_seat.rotation_degrees = Vector3(-16.0, 0, 0)
	tube_seat.material = mat_frame
	bike_frame.add_child(tube_seat)
	
	# Saddle
	var saddle = CSGBox3D.new()
	saddle.size = Vector3(0.22, 0.08, 0.32)
	saddle.position = Vector3(0, 0.98, 0.32)
	saddle.material = mat_saddle
	bike_frame.add_child(saddle)
	
	# Handlebars & Stem
	var stem = CSGBox3D.new()
	stem.size = Vector3(0.06, 0.32, 0.06)
	stem.position = Vector3(0, 0.96, -0.42)
	stem.material = mat_metal
	bike_frame.add_child(stem)
	
	var handlebar = CSGBox3D.new()
	handlebar.size = Vector3(0.68, 0.05, 0.05)
	handlebar.position = Vector3(0, 1.08, -0.42)
	handlebar.material = mat_metal
	bike_frame.add_child(handlebar)
	
	# Rubber Grips
	for gx in [-0.31, 0.31]:
		var grip = CSGBox3D.new()
		grip.size = Vector3(0.12, 0.07, 0.07)
		grip.position = Vector3(gx, 1.08, -0.42)
		grip.material = mat_tire
		bike_frame.add_child(grip)
	
	# Headlight (Casing + Lens + Forward SpotLight3D)
	var light_casing = CSGCylinder3D.new()
	light_casing.radius = 0.075
	light_casing.height = 0.12
	light_casing.position = Vector3(0, 0.98, -0.48)
	light_casing.rotation_degrees = Vector3(90, 0, 0)
	light_casing.material = mat_metal
	bike_frame.add_child(light_casing)
	
	var light_lens = CSGSphere3D.new()
	light_lens.radius = 0.07
	light_lens.position = Vector3(0, 0.98, -0.54)
	light_lens.material = _create_mat(Color(1.0, 0.95, 0.75), 0.2, 0.0, Color(1.0, 0.92, 0.6), 2.5)
	bike_frame.add_child(light_lens)
	
	headlight_spot = SpotLight3D.new()
	headlight_spot.position = Vector3(0, 0.98, -0.56)
	headlight_spot.light_color = Color(1.0, 0.96, 0.85)
	headlight_spot.light_energy = 3.6
	headlight_spot.spot_range = 28.0
	headlight_spot.spot_angle = 32.0
	bike_frame.add_child(headlight_spot)
	
	# Front Fork & Wheel
	var fork = CSGBox3D.new()
	fork.size = Vector3(0.14, 0.72, 0.05)
	fork.position = Vector3(0, 0.58, -0.44)
	fork.rotation_degrees = Vector3(14.0, 0, 0)
	fork.material = mat_metal
	bike_frame.add_child(fork)
	
	wheel_front = Node3D.new()
	wheel_front.position = Vector3(0, 0.36, -0.52)
	bike_frame.add_child(wheel_front)
	var wf_tire = CSGCylinder3D.new()
	wf_tire.radius = 0.36
	wf_tire.height = 0.06
	wf_tire.rotation_degrees = Vector3(0, 0, 90)
	wf_tire.material = mat_tire
	wheel_front.add_child(wf_tire)
	
	# Rear Wheel
	wheel_rear = Node3D.new()
	wheel_rear.position = Vector3(0, 0.36, 0.52)
	bike_frame.add_child(wheel_rear)
	var wr_tire = CSGCylinder3D.new()
	wr_tire.radius = 0.36
	wr_tire.height = 0.06
	wr_tire.rotation_degrees = Vector3(0, 0, 90)
	wr_tire.material = mat_tire
	wheel_rear.add_child(wr_tire)
	
	# Pedal Crankset
	pedal_crank = Node3D.new()
	pedal_crank.position = Vector3(0, 0.36, 0.0)
	bike_frame.add_child(pedal_crank)
	var crank_arm = CSGBox3D.new()
	crank_arm.size = Vector3(0.32, 0.04, 0.04)
	crank_arm.material = mat_metal
	pedal_crank.add_child(crank_arm)
	
	# --------------------------------------------------------------------------
	# PROTAGONIST RIDER CHARACTER (WITH BACKPACK STRAPPED ON BACK)
	# --------------------------------------------------------------------------
	var mat_skin = _create_mat(Color(0.86, 0.68, 0.54), 0.75)
	var mat_shirt = _create_mat(Color(0.14, 0.16, 0.22), 0.8) # Protagonist black/dark hoodie
	var mat_jeans = _create_mat(Color(0.18, 0.28, 0.44), 0.85) # Blue denim jeans
	var mat_hair = _create_mat(Color(0.08, 0.08, 0.09), 0.9)
	var mat_backpack = _create_mat(Color(0.10, 0.18, 0.34), 0.75) # Heavy-duty Adventure Backpack
	
	var rider_body = Node3D.new()
	rider_body.position = Vector3(0, 0.95, 0.22)
	bike_frame.add_child(rider_body)
	
	# Torso leaning forward slightly onto handlebars
	var torso = CSGBox3D.new()
	torso.size = Vector3(0.38, 0.48, 0.24)
	torso.position = Vector3(0, 0.24, 0)
	torso.rotation_degrees = Vector3(18.0, 0, 0) # Leaning forward
	torso.material = mat_shirt
	rider_body.add_child(torso)
	
	# Head
	var head = CSGBox3D.new()
	head.size = Vector3(0.24, 0.24, 0.24)
	head.position = Vector3(0, 0.58, -0.08)
	head.material = mat_skin
	rider_body.add_child(head)
	
	var hair = CSGBox3D.new()
	hair.size = Vector3(0.26, 0.12, 0.26)
	hair.position = Vector3(0, 0.68, -0.08)
	hair.material = mat_hair
	rider_body.add_child(hair)
	
	# --------------------------------------------------------------------------
	# 3D BACKPACK STRAPPED ON PROTAGONIST'S BACK (User requirement!)
	# --------------------------------------------------------------------------
	rider_backpack = Node3D.new()
	rider_backpack.name = "RiderBackpack"
	rider_backpack.position = Vector3(0, 0.26, 0.14)
	rider_backpack.rotation_degrees = Vector3(18.0, 0, 0)
	rider_body.add_child(rider_backpack)
	
	# Main Bag body
	var bag_mesh = CSGBox3D.new()
	bag_mesh.size = Vector3(0.36, 0.44, 0.22)
	bag_mesh.position = Vector3(0, 0, 0)
	bag_mesh.material = mat_backpack
	rider_backpack.add_child(bag_mesh)
	
	# Outer pocket
	var bag_pocket = CSGBox3D.new()
	bag_pocket.size = Vector3(0.26, 0.22, 0.08)
	bag_pocket.position = Vector3(0, -0.06, 0.13)
	bag_pocket.material = _create_mat(Color(0.18, 0.24, 0.42), 0.7)
	rider_backpack.add_child(bag_pocket)
	
	# Water bottle on side
	var bottle = CSGCylinder3D.new()
	bottle.radius = 0.04
	bottle.height = 0.22
	bottle.position = Vector3(0.20, 0, 0.04)
	bottle.material = _create_mat(Color(0.2, 0.75, 0.85), 0.4)
	rider_backpack.add_child(bottle)
	
	# Shoulder Straps wrapping to front of torso
	for sx in [-0.14, 0.14]:
		var strap = CSGBox3D.new()
		strap.size = Vector3(0.06, 0.42, 0.24)
		strap.position = Vector3(sx, 0, -0.08)
		strap.material = _create_mat(Color(0.08, 0.12, 0.20))
		rider_backpack.add_child(strap)
	
	# Arms reaching to handlebar grips
	rider_arm_l = CSGBox3D.new()
	rider_arm_l.size = Vector3(0.09, 0.46, 0.09)
	rider_arm_l.position = Vector3(-0.24, 0.28, -0.22)
	rider_arm_l.rotation_degrees = Vector3(45.0, 15.0, 0.0)
	rider_arm_l.material = mat_shirt
	rider_body.add_child(rider_arm_l)
	
	rider_arm_r = CSGBox3D.new()
	rider_arm_r.size = Vector3(0.09, 0.46, 0.09)
	rider_arm_r.position = Vector3(0.24, 0.28, -0.22)
	rider_arm_r.rotation_degrees = Vector3(45.0, -15.0, 0.0)
	rider_arm_r.material = mat_shirt
	rider_body.add_child(rider_arm_r)
	
	# Pedaling Legs
	rider_leg_l = CSGBox3D.new()
	rider_leg_l.size = Vector3(0.12, 0.44, 0.12)
	rider_leg_l.position = Vector3(-0.14, -0.25, -0.08)
	rider_leg_l.rotation_degrees = Vector3(25.0, 0, 0)
	rider_leg_l.material = mat_jeans
	rider_body.add_child(rider_leg_l)
	
	rider_leg_r = CSGBox3D.new()
	rider_leg_r.size = Vector3(0.12, 0.44, 0.12)
	rider_leg_r.position = Vector3(0.14, -0.25, -0.08)
	rider_leg_r.rotation_degrees = Vector3(25.0, 0, 0)
	rider_leg_r.material = mat_jeans
	rider_body.add_child(rider_leg_r)

# --- COMPANIONS WAITING AT BOYS SCHOOL GATE ---
func _build_companions_at_school() -> void:
	var comp_root = Node3D.new()
	comp_root.name = "CompanionsRoot"
	comp_root.position = Vector3(0, 0, SCHOOL_GATE_Z - 3.5)
	add_child(comp_root)
	
	var mat_skin = _create_mat(Color(0.86, 0.68, 0.54), 0.75)
	var mat_sahil_shirt = _create_mat(Color(0.85, 0.35, 0.15), 0.8) # Orange hoodie
	var mat_sahil_cap = _create_mat(Color(0.12, 0.35, 0.85), 0.7) # Blue cap
	var mat_aashu_shirt = _create_mat(Color(0.25, 0.55, 0.85), 0.8) # Blue collared shirt
	var mat_aashu_glass = _create_mat(Color(0.1, 0.1, 0.1), 0.2, 0.9)
	var mat_jeans = _create_mat(Color(0.15, 0.22, 0.36), 0.85)
	var mat_bag_sahil = _create_mat(Color(0.35, 0.15, 0.15), 0.8) # Reddish adventure bag
	var mat_bag_aashu = _create_mat(Color(0.18, 0.38, 0.25), 0.8) # Green army bag
	
	# --------------------------------------------------------------------------
	# SAHIL (Waiting on left with his red bicycle parked)
	# --------------------------------------------------------------------------
	comp_sahil = Node3D.new()
	comp_sahil.name = "CompanionSahil"
	comp_sahil.position = Vector3(-2.2, 0, 0)
	comp_root.add_child(comp_sahil)
	
	var s_torso = CSGBox3D.new()
	s_torso.size = Vector3(0.42, 0.65, 0.24)
	s_torso.position = Vector3(0, 1.15, 0)
	s_torso.material = mat_sahil_shirt
	comp_sahil.add_child(s_torso)
	
	var s_head = CSGBox3D.new()
	s_head.size = Vector3(0.24, 0.24, 0.24)
	s_head.position = Vector3(0, 1.62, 0)
	s_head.material = mat_skin
	comp_sahil.add_child(s_head)
	
	var s_cap = CSGBox3D.new()
	s_cap.size = Vector3(0.26, 0.08, 0.32)
	s_cap.position = Vector3(0, 1.74, 0.04)
	s_cap.material = mat_sahil_cap
	comp_sahil.add_child(s_cap)
	
	var s_bag = CSGBox3D.new()
	s_bag.size = Vector3(0.36, 0.46, 0.22)
	s_bag.position = Vector3(0, 1.18, -0.18)
	s_bag.material = mat_bag_sahil
	comp_sahil.add_child(s_bag)
	
	var s_legs = CSGBox3D.new()
	s_legs.size = Vector3(0.36, 0.80, 0.18)
	s_legs.position = Vector3(0, 0.42, 0)
	s_legs.material = mat_jeans
	comp_sahil.add_child(s_legs)
	
	# Sahil's Parked Red Bicycle beside him
	var s_bike = Node3D.new()
	s_bike.position = Vector3(-0.7, 0, 0.2)
	s_bike.rotation_degrees = Vector3(0, 15, 0)
	comp_sahil.add_child(s_bike)
	var sb_frame = CSGBox3D.new()
	sb_frame.size = Vector3(0.06, 0.55, 1.4)
	sb_frame.position = Vector3(0, 0.55, 0)
	sb_frame.material = _create_mat(Color(0.85, 0.15, 0.15), 0.5, 0.7)
	s_bike.add_child(sb_frame)
	
	# --------------------------------------------------------------------------
	# AASHUTOSH (Waiting on right with his blue bicycle)
	# --------------------------------------------------------------------------
	comp_aashu = Node3D.new()
	comp_aashu.name = "CompanionAashutosh"
	comp_aashu.position = Vector3(2.2, 0, 0)
	comp_root.add_child(comp_aashu)
	
	var a_torso = CSGBox3D.new()
	a_torso.size = Vector3(0.40, 0.65, 0.24)
	a_torso.position = Vector3(0, 1.15, 0)
	a_torso.material = mat_aashu_shirt
	comp_aashu.add_child(a_torso)
	
	var a_head = CSGBox3D.new()
	a_head.size = Vector3(0.24, 0.24, 0.24)
	a_head.position = Vector3(0, 1.62, 0)
	a_head.material = mat_skin
	comp_aashu.add_child(a_head)
	
	var a_glass = CSGBox3D.new()
	a_glass.size = Vector3(0.26, 0.06, 0.08)
	a_glass.position = Vector3(0, 1.62, 0.12)
	a_glass.material = mat_aashu_glass
	comp_aashu.add_child(a_glass)
	
	var a_bag = CSGBox3D.new()
	a_bag.size = Vector3(0.36, 0.46, 0.22)
	a_bag.position = Vector3(0, 1.18, -0.18)
	a_bag.material = mat_bag_aashu
	comp_aashu.add_child(a_bag)
	
	var a_legs = CSGBox3D.new()
	a_legs.size = Vector3(0.36, 0.80, 0.18)
	a_legs.position = Vector3(0, 0.42, 0)
	a_legs.material = mat_jeans
	comp_aashu.add_child(a_legs)
	
	# Aashutosh's Parked Blue Bicycle beside him
	var a_bike = Node3D.new()
	a_bike.position = Vector3(0.7, 0, 0.2)
	a_bike.rotation_degrees = Vector3(0, -15, 0)
	comp_aashu.add_child(a_bike)
	var ab_frame = CSGBox3D.new()
	ab_frame.size = Vector3(0.06, 0.55, 1.4)
	ab_frame.position = Vector3(0, 0.55, 0)
	ab_frame.material = _create_mat(Color(0.15, 0.45, 0.85), 0.5, 0.7)
	a_bike.add_child(ab_frame)

# --- USER INTERFACE (HUD, CONTROLS, SUBTITLES, ARRIVAL CARD) ---
func _build_ui() -> void:
	ui_root = CanvasLayer.new()
	ui_root.name = "CycleHUD"
	ui_root.layer = 120
	add_child(ui_root)
	
	# Top Mission Banner
	mission_banner = PanelContainer.new()
	mission_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	mission_banner.offset_left = 30
	mission_banner.offset_top = 18
	mission_banner.offset_right = -130
	mission_banner.offset_bottom = 74
	ui_root.add_child(mission_banner)
	
	var b_hbox = HBoxContainer.new()
	mission_banner.add_child(b_hbox)
	
	banner_label = Label.new()
	banner_label.text = "🚲 MISSION: RIDE BICYCLE TO BOYS SCHOOL [बॉयज़ स्कूल पहुँचें]"
	banner_label.add_theme_font_size_override("font_size", 16)
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	banner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_hbox.add_child(banner_label)
	
	dist_label = Label.new()
	dist_label.text = "📍 DISTANCE: 112 M"
	dist_label.add_theme_font_size_override("font_size", 16)
	dist_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	b_hbox.add_child(dist_label)
	
	# Skip Button (Top Right)
	skip_btn = Button.new()
	skip_btn.text = "SKIP ⏭️"
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -110
	skip_btn.offset_top = 18
	skip_btn.offset_right = -20
	skip_btn.offset_bottom = 74
	skip_btn.pressed.connect(_on_skip_pressed)
	ui_root.add_child(skip_btn)
	
	# Subtitle Panel (Bottom Center)
	subtitle_panel = PanelContainer.new()
	subtitle_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle_panel.offset_left = 50
	subtitle_panel.offset_top = -140
	subtitle_panel.offset_right = -50
	subtitle_panel.offset_bottom = -25
	subtitle_panel.visible = false
	ui_root.add_child(subtitle_panel)
	
	var sub_vbox = VBoxContainer.new()
	subtitle_panel.add_child(sub_vbox)
	
	speaker_label = Label.new()
	speaker_label.text = "🎒 तू (YOU / खिलाड़ी)"
	speaker_label.add_theme_font_size_override("font_size", 16)
	speaker_label.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0))
	sub_vbox.add_child(speaker_label)
	
	dialogue_label = Label.new()
	dialogue_label.text = "..."
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 18)
	sub_vbox.add_child(dialogue_label)
	
	advance_tip = Label.new()
	advance_tip.text = "[CLICK / SPACE TO CONTINUE ➔]"
	advance_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	advance_tip.add_theme_font_size_override("font_size", 12)
	advance_tip.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	sub_vbox.add_child(advance_tip)
	
	# Mobile Touch Buttons HUD (Only shown on mobile / touch screen)
	_build_touch_controls()
	
	# Arrival Card (Initially hidden)
	arrival_card = PanelContainer.new()
	arrival_card.set_anchors_preset(Control.PRESET_CENTER)
	arrival_card.offset_left = -280
	arrival_card.offset_top = -140
	arrival_card.offset_right = 280
	arrival_card.offset_bottom = 140
	arrival_card.visible = false
	ui_root.add_child(arrival_card)
	
	var ac_vbox = VBoxContainer.new()
	arrival_card.add_child(ac_vbox)
	
	var ac_title = Label.new()
	ac_title.text = "🏆 MISSION COMPLETE: BOYS SCHOOL PLAN FINALIZED!"
	ac_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ac_title.add_theme_font_size_override("font_size", 18)
	ac_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	ac_vbox.add_child(ac_title)
	
	var ac_desc = Label.new()
	ac_desc.text = "बॉयज़ स्कूल में तीनों दोस्त अपने-अपने गैजेट्स व सामान के साथ मिले!\nभानगढ़ खंडहर के अंदर गुप्त रास्ते से दाखिल होने का पूरा प्लान तैयार हुआ।"
	ac_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ac_desc.add_theme_font_size_override("font_size", 14)
	ac_vbox.add_child(ac_desc)
	
	proceed_btn = Button.new()
	proceed_btn.text = "🏰 PROCEED TO BHANGARH RUINS / भानगढ़ खंडहर चलें ➔"
	proceed_btn.custom_minimum_size = Vector2(0, 52)
	proceed_btn.add_theme_font_size_override("font_size", 16)
	proceed_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	proceed_btn.pressed.connect(_on_proceed_to_bhangarh_pressed)
	ac_vbox.add_child(proceed_btn)

func _build_touch_controls() -> void:
	touch_hud = Control.new()
	touch_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(touch_hud)
	
	var is_touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if not is_touch:
		# Keep touch controls hidden on desktop unless user touches screen
		touch_hud.visible = false
	
	# Left Steering Buttons
	var btn_l = Button.new()
	btn_l.text = "◀"
	btn_l.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn_l.offset_left = 25
	btn_l.offset_top = -140
	btn_l.offset_right = 95
	btn_l.offset_bottom = -70
	btn_l.add_theme_font_size_override("font_size", 28)
	btn_l.button_down.connect(func(): touch_left = true)
	btn_l.button_up.connect(func(): touch_left = false)
	touch_hud.add_child(btn_l)
	
	var btn_r = Button.new()
	btn_r.text = "▶"
	btn_r.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn_r.offset_left = 110
	btn_r.offset_top = -140
	btn_r.offset_right = 180
	btn_r.offset_bottom = -70
	btn_r.add_theme_font_size_override("font_size", 28)
	btn_r.button_down.connect(func(): touch_right = true)
	btn_r.button_up.connect(func(): touch_right = false)
	touch_hud.add_child(btn_r)
	
	# Bell Button
	var btn_bell = Button.new()
	btn_bell.text = "🔔 BELL"
	btn_bell.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	btn_bell.offset_left = 25
	btn_bell.offset_top = -60
	btn_bell.offset_right = 180
	btn_bell.offset_bottom = -15
	btn_bell.add_theme_font_size_override("font_size", 14)
	btn_bell.pressed.connect(_ring_bell)
	touch_hud.add_child(btn_bell)
	
	# Right Pedal & Brake Buttons
	var btn_pedal = Button.new()
	btn_pedal.text = "🚲 PEDAL"
	btn_pedal.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_pedal.offset_left = -190
	btn_pedal.offset_top = -140
	btn_pedal.offset_right = -105
	btn_pedal.offset_bottom = -70
	btn_pedal.add_theme_font_size_override("font_size", 16)
	btn_pedal.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	btn_pedal.button_down.connect(func(): touch_pedal = true)
	btn_pedal.button_up.connect(func(): touch_pedal = false)
	touch_hud.add_child(btn_pedal)
	
	var btn_sprint = Button.new()
	btn_sprint.text = "⚡ SPRINT"
	btn_sprint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_sprint.offset_left = -95
	btn_sprint.offset_top = -140
	btn_sprint.offset_right = -20
	btn_sprint.offset_bottom = -70
	btn_sprint.add_theme_font_size_override("font_size", 14)
	btn_sprint.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	btn_sprint.button_down.connect(func(): touch_sprint = true)
	btn_sprint.button_up.connect(func(): touch_sprint = false)
	touch_hud.add_child(btn_sprint)
	
	var btn_brake = Button.new()
	btn_brake.text = "🛑 BRAKE"
	btn_brake.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_brake.offset_left = -190
	btn_brake.offset_top = -60
	btn_brake.offset_right = -20
	btn_brake.offset_bottom = -15
	btn_brake.add_theme_font_size_override("font_size", 16)
	btn_brake.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	btn_brake.button_down.connect(func(): touch_brake = true)
	btn_brake.button_up.connect(func(): touch_brake = false)
	touch_hud.add_child(btn_brake)

func _ring_bell() -> void:
	if audio_bell:
		audio_bell.stop()
		audio_bell.pitch_scale = randf_range(0.95, 1.08)
		audio_bell.play()

# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_B, KEY_SPACE]:
			if not cutscene_active:
				_ring_bell()
	
	if can_advance_dialogue:
		if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_E]) or \
		   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
		   (event is InputEventScreenTouch and event.pressed):
			_advance_dialogue()

# --- PHYSICS PROCESS (BICYCLE RIDING) ---
func _physics_process(delta: float) -> void:
	if cutscene_active:
		return
		
	# Input gathering (Keyboard + Touch)
	var steer_input: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or touch_left:
		steer_input += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or touch_right:
		steer_input -= 1.0
		
	var forward_input: float = 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or touch_pedal:
		forward_input += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or touch_brake:
		forward_input -= 0.6
		
	is_sprinting = Input.is_key_pressed(KEY_SHIFT) or touch_sprint
	var max_spd = SPRINT_CYCLE_SPEED if is_sprinting else CYCLE_SPEED
	
	# Turning & Banking
	if abs(steer_input) > 0.05:
		rider_heading += steer_input * TURN_SPEED * delta
		var target_tilt = steer_input * 0.18
		cycle_tilt = lerp(cycle_tilt, target_tilt, 7.0 * delta)
	else:
		cycle_tilt = lerp(cycle_tilt, 0.0, 6.0 * delta)
		
	# Clamp player heading so he primarily moves down the street towards Boys School (-Z)
	rider_heading = clamp(rider_heading, -0.65, 0.65)
	
	# Acceleration & Velocity
	var forward_dir = Vector3(-sin(rider_heading), 0, -cos(rider_heading)).normalized()
	if forward_input > 0.05:
		player_velocity = player_velocity.move_toward(forward_dir * max_spd, ACCEL * delta)
		if audio_cycle:
			if not audio_cycle.playing: audio_cycle.play()
			audio_cycle.pitch_scale = lerp(0.85, 1.4, player_velocity.length() / SPRINT_CYCLE_SPEED)
	elif forward_input < -0.05:
		player_velocity = player_velocity.move_toward(Vector3.ZERO, ACCEL * 2.2 * delta)
		if audio_cycle and audio_cycle.playing: audio_cycle.stop()
	else:
		player_velocity = player_velocity.move_toward(Vector3.ZERO, ACCEL * 0.8 * delta)
		if audio_cycle and audio_cycle.playing: audio_cycle.stop()
		
	player_pos += player_velocity * delta
	# Clamp X within street sidewalks
	player_pos.x = clamp(player_pos.x, -3.8, 3.8)
	
	# Update 3D Visual Transforms
	if player_root:
		player_root.position = player_pos
		player_root.rotation.y = rider_heading
	if bike_frame:
		bike_frame.rotation.z = cycle_tilt
		
	# Update Camera follow
	if cam_pivot:
		cam_pivot.position = player_pos
		cam_pivot.rotation.y = rider_heading * 0.75
		
	# Animate Rolling Wheels & Pedals
	var cur_speed = player_velocity.length()
	if cur_speed > 0.1:
		pedal_phase += delta * cur_speed * 2.2
		var roll = delta * cur_speed * 4.0
		if wheel_front: wheel_front.rotate_x(roll)
		if wheel_rear: wheel_rear.rotate_x(roll)
		if pedal_crank: pedal_crank.rotation.x = pedal_phase
		
		# Animate rider legs
		if rider_leg_l: rider_leg_l.rotation.x = sin(pedal_phase) * 0.45 + 0.25
		if rider_leg_r: rider_leg_r.rotation.x = -sin(pedal_phase) * 0.45 + 0.25
		
	# Update Distance to Boys School Gate HUD
	var dist_m = max(0, int(abs(player_pos.z - SCHOOL_GATE_Z)))
	if dist_label:
		dist_label.text = "📍 DISTANCE TO BOYS SCHOOL: %d M" % dist_m
		
	# Trigger Arrival when reaching school gate
	if player_pos.z <= (SCHOOL_GATE_Z + 5.0) and not is_arrived:
		_trigger_school_arrival()

# --- ARRIVAL AT BOYS SCHOOL CUTSCENE ---
func _trigger_school_arrival() -> void:
	is_arrived = true
	cutscene_active = true
	
	if audio_cycle and audio_cycle.playing:
		audio_cycle.stop()
		
	if touch_hud:
		touch_hud.visible = false
		
	# Decelerate smoothly to halt in front of Sahil and Aashutosh
	var target_stop = Vector3(0.0, 0.0, SCHOOL_GATE_Z - 1.5)
	var tw_stop = create_tween()
	tw_stop.tween_property(player_root, "position", target_stop, 1.4).set_trans(Tween.TRANS_QUAD)
	
	# Camera smoothly transitions to medium group shot of all 3 friends
	var tw_cam = create_tween()
	tw_cam.parallel().tween_property(cam_pivot, "position", target_stop, 1.4)
	tw_cam.parallel().tween_property(cam, "position", Vector3(0.0, 1.65, 3.8), 1.4)
	tw_cam.parallel().tween_property(cam, "rotation_degrees", Vector3(-4.0, 0.0, 0.0), 1.4)
	
	await tw_stop.finished
	
	# Protagonist dismounts feet
	if rider_leg_l: rider_leg_l.rotation.x = 0.0
	if rider_leg_r: rider_leg_r.rotation.x = 0.0
	
	# Ring bell on arrival!
	_ring_bell()
	
	# Start dialogue sequence between friends
	dialogue_idx = 0
	_display_arrival_dialogue()

func _display_arrival_dialogue() -> void:
	if dialogue_idx >= arrival_dialogues.size():
		_finish_arrival_scene()
		return
		
	can_advance_dialogue = false
	var d = arrival_dialogues[dialogue_idx]
	
	if subtitle_panel:
		subtitle_panel.visible = true
	if speaker_label:
		speaker_label.text = d["speaker"]
		speaker_label.modulate = d["color"]
	if dialogue_label:
		dialogue_label.text = d["text"]
	if advance_tip:
		advance_tip.text = "[CLICK / ENTER TO ADVANCE ➔]"
		
	await get_tree().create_timer(0.6).timeout
	can_advance_dialogue = true

func _advance_dialogue() -> void:
	if not can_advance_dialogue: return
	dialogue_idx += 1
	_display_arrival_dialogue()

func _finish_arrival_scene() -> void:
	can_advance_dialogue = false
	if subtitle_panel:
		subtitle_panel.visible = false
		
	if arrival_card:
		arrival_card.visible = true
		arrival_card.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(arrival_card, "modulate:a", 1.0, 0.8)

func _on_skip_pressed() -> void:
	if is_arrived: return
	player_pos = Vector3(0.0, 0.0, SCHOOL_GATE_Z + 4.0)
	_trigger_school_arrival()

func _on_proceed_to_bhangarh_pressed() -> void:
	if proceed_btn:
		proceed_btn.disabled = true
		proceed_btn.text = "🏰 LOADING BHANGARH RUINS..."
	get_tree().change_scene_to_file("res://scenes/bhangarh_ruins.tscn")
