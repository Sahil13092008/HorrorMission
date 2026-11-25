extends Node3D

# ==============================================================
# CYCLE_TO_SCHOOL.GD
# Real Town Journey: House -> Turn 1 (Chowk) -> Market Road ->
# Turn 2 (School Corner) -> School Boulevard -> Main Gate ->
# MASSIVE OUTSIDE PLAYGROUND (विशाल खेल मैदान) ->
# Friends Waiting Outside on the Ground with Backpacks & Cycles!
# ==============================================================

# --- ROUTE WAYPOINTS & STATE ---
const CYCLE_SPEED: float = 9.8
const SPRINT_CYCLE_SPEED: float = 14.8
const ACCEL: float = 18.0
const TURN_SPEED: float = 2.4

# Route Key Locations
const START_POS: Vector3 = Vector3(0.0, 0.0, 60.0)      # Protagonist's house street
const TURN1_CHOWK_Z: float = -5.0                       # Turn 1: Chowk (Turn Left to -X)
const TURN2_CORNER_X: float = -70.0                     # Turn 2: School Corner (Turn Right to -Z)
const SCHOOL_GATE_Z: float = -85.0                      # Grand School Main Gate
const GROUND_MEETING_POS: Vector3 = Vector3(-70.0, 0.0, -135.0) # Friends waiting on the big ground!

var player_pos: Vector3 = START_POS
var player_velocity: Vector3 = Vector3.ZERO
var rider_heading: float = 0.0 # 0 rad = -Z (North), PI/2 = -X (West), -PI/2 = +X (East), PI = +Z (South)
var cycle_tilt: float = 0.0
var pedal_phase: float = 0.0
var is_sprinting: bool = false
var is_arrived: bool = false
var cutscene_active: bool = false
var dialogue_idx: int = 0
var can_advance_dialogue: bool = false

# Touch control flags
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

# Companions
var comp_sahil: Node3D
var comp_aashu: Node3D

# Audio Players
var audio_ambience: AudioStreamPlayer
var audio_cycle: AudioStreamPlayer
var audio_bell: AudioStreamPlayer
var audio_voice: AudioStreamPlayer

var stream_sahil_arr: AudioStream
var stream_player_arr: AudioStream
var stream_aashu_arr: AudioStream
var stream_sahil_pln: AudioStream

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

# Dialogues on the Big Outside Ground
var arrival_dialogues = [
	{
		"speaker": "🧢 साहिल (SAHIL) — [स्कूल के बाहर वाले मैदान में]",
		"color": Color(1.0, 0.85, 0.3),
		"text": "\"अरे आ गया भाई! सब गैजेट्स और जरूरी सामान ले आया ना बैग में?\""
	},
	{
		"speaker": "🎒 तू (YOU / खिलाड़ी) — [मैदान में साइकिल से उतरते हुए]",
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
	_build_town_streets_with_turns()
	_build_boys_school_and_ground()
	_build_player_bicycle()
	_build_companions_on_ground()
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
	audio_voice.volume_db = 5.0
	a_root.add_child(audio_voice)
	
	stream_sahil_arr = _load_audio_safe("res://audio/school_sahil_arrival.mp3")
	stream_player_arr = _load_audio_safe("res://audio/school_player_arrival.mp3")
	stream_aashu_arr = _load_audio_safe("res://audio/school_aashu_arrival.mp3")
	stream_sahil_pln = _load_audio_safe("res://audio/school_sahil_plan.mp3")
	
	arrival_dialogues[0]["audio"] = stream_sahil_arr
	arrival_dialogues[1]["audio"] = stream_player_arr
	arrival_dialogues[2]["audio"] = stream_aashu_arr
	arrival_dialogues[3]["audio"] = stream_sahil_pln

# --- ENVIRONMENT & LIGHTING ---
func _setup_lighting_and_sky() -> void:
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.11, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.60, 0.48, 0.42)
	env.ambient_light_energy = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.26, 0.18, 0.24)
	env.fog_density = 0.007
	
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.75, 0.50)
	sun_light.light_energy = 1.25
	sun_light.rotation_degrees = Vector3(-28.0, 42.0, 0.0)
	sun_light.shadow_enabled = true
	add_child(sun_light)
	
	cam_pivot = Node3D.new()
	cam_pivot.name = "CameraPivot"
	cam_pivot.position = player_pos
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

# --- TOWN STREET NETWORK WITH REAL TURNS ---
# Segment 1: Home Road (Z: 65 down to -5, X: 0)
# Turn 1: Chowk at (0, 0, -5) -> Turn Left to -X
# Segment 2: Market Road (X: 0 down to -70, Z: -5)
# Turn 2: School Corner at (-70, 0, -5) -> Turn Right to -Z
# Segment 3: School Avenue (Z: -5 down to -85, X: -70)
func _build_town_streets_with_turns() -> void:
	road_root = Node3D.new()
	road_root.name = "RoadRoot"
	add_child(road_root)
	
	var mat_road = _create_mat(Color(0.14, 0.14, 0.16), 0.9)
	var mat_sidewalk = _create_mat(Color(0.28, 0.26, 0.24), 0.85)
	var mat_dash = _create_mat(Color(0.92, 0.85, 0.25), 0.7)
	var mat_pole = _create_mat(Color(0.25, 0.25, 0.28), 0.4, 0.6)
	var mat_bulb = _create_mat(Color(1.0, 0.9, 0.5), 0.2, 0.0, Color(1.0, 0.85, 0.4), 3.5)
	var mat_hedge = _create_mat(Color(0.12, 0.32, 0.14), 0.9)
	var mat_wall = _create_mat(Color(0.44, 0.42, 0.40), 0.85)
	var mat_shop = _create_mat(Color(0.35, 0.45, 0.55), 0.8)
	
	# --------------------------------------------------------------------------
	# SEGMENT 1: Home Neighborhood Street (Z: 65m down to -5m, at X = 0)
	# --------------------------------------------------------------------------
	var road1 = CSGBox3D.new()
	road1.size = Vector3(8.6, 0.1, 72.0)
	road1.position = Vector3(0.0, -0.05, 30.0)
	road1.material = mat_road
	road_root.add_child(road1)
	
	# Dashes for Road 1
	for z in range(0, 62, 6):
		var dash = CSGBox3D.new()
		dash.size = Vector3(0.24, 0.11, 2.6)
		dash.position = Vector3(0.0, 0.01, float(z))
		dash.material = mat_dash
		road_root.add_child(dash)
		
	# Sidewalks for Road 1
	for side in [-1, 1]:
		var sw1 = CSGBox3D.new()
		sw1.size = Vector3(3.2, 0.22, 72.0)
		sw1.position = Vector3(side * 5.9, 0.02, 30.0)
		sw1.material = mat_sidewalk
		road_root.add_child(sw1)
		
		# Street lamps and houses along Road 1
		for lz in [50, 32, 14]:
			var pole = CSGBox3D.new()
			pole.size = Vector3(0.14, 5.2, 0.14)
			pole.position = Vector3(side * 5.2, 2.6, float(lz))
			pole.material = mat_pole
			road_root.add_child(pole)
			
			var bulb = CSGSphere3D.new()
			bulb.radius = 0.18
			bulb.position = Vector3(side * 4.4, 5.0, float(lz))
			bulb.material = mat_bulb
			road_root.add_child(bulb)
			
			var lamp_light = OmniLight3D.new()
			lamp_light.position = Vector3(side * 4.4, 4.8, float(lz))
			lamp_light.light_color = Color(1.0, 0.88, 0.65)
			lamp_light.light_energy = 2.4
			lamp_light.omni_range = 14.0
			road_root.add_child(lamp_light)
			
			# House facade
			var house = CSGBox3D.new()
			house.size = Vector3(5.5, 4.2, 10.0)
			house.position = Vector3(side * 9.8, 2.1, float(lz))
			house.material = _create_mat(Color(0.85, 0.82, 0.75))
			road_root.add_child(house)
	
	# --------------------------------------------------------------------------
	# TURN 1: CHOWK / T-JUNCTION (At Z = -5, X = 0)
	# --------------------------------------------------------------------------
	var chowk = CSGBox3D.new()
	chowk.size = Vector3(14.0, 0.1, 14.0)
	chowk.position = Vector3(-2.0, -0.05, -5.0)
	chowk.material = mat_road
	road_root.add_child(chowk)
	
	# Prominent Signboard at Chowk telling player to Turn Left!
	var sign_chowk = Node3D.new()
	sign_chowk.position = Vector3(4.8, 0, -5.0)
	road_root.add_child(sign_chowk)
	
	var sc_board = CSGBox3D.new()
	sc_board.size = Vector3(0.08, 1.2, 2.6)
	sc_board.position = Vector3(0, 2.2, 0)
	sc_board.material = _create_mat(Color(0.08, 0.45, 0.22), 0.5)
	sign_chowk.add_child(sc_board)
	
	var sc_lbl = Label3D.new()
	sc_lbl.text = "↰ बाएँ मुड़ें (TURN LEFT)\n🏫 उत्कृष्ट बालक उच्चतर माध्यमिक विद्यालय ➔\n[BOYS SCHOOL — 180M]"
	sc_lbl.font_size = 28
	sc_lbl.modulate = Color(1.0, 0.95, 0.3)
	sc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc_lbl.position = Vector3(-0.06, 2.2, 0)
	sc_lbl.rotation_degrees = Vector3(0, -90, 0)
	sign_chowk.add_child(sc_lbl)
	
	# Streetlight illuminating the Chowk
	var chowk_light = OmniLight3D.new()
	chowk_light.position = Vector3(0, 5.0, -5.0)
	chowk_light.light_color = Color(1.0, 0.92, 0.70)
	chowk_light.light_energy = 3.2
	chowk_light.omni_range = 16.0
	road_root.add_child(chowk_light)
	
	# --------------------------------------------------------------------------
	# SEGMENT 2: Market Connecting Road (X: 0 down to -70m, along Z = -5)
	# --------------------------------------------------------------------------
	var road2 = CSGBox3D.new()
	road2.size = Vector3(72.0, 0.1, 8.6)
	road2.position = Vector3(-35.0, -0.05, -5.0)
	road2.material = mat_road
	road_root.add_child(road2)
	
	# Dashes along Road 2 (East-West)
	for x in range(-66, -4, 6):
		var dash2 = CSGBox3D.new()
		dash2.size = Vector3(2.6, 0.11, 0.24)
		dash2.position = Vector3(float(x), 0.01, -5.0)
		dash2.material = mat_dash
		road_root.add_child(dash2)
		
	# Sidewalks and town shops along Road 2
	for z_side in [-1, 1]:
		var sw2 = CSGBox3D.new()
		sw2.size = Vector3(72.0, 0.22, 3.2)
		sw2.position = Vector3(-35.0, 0.02, -5.0 + (z_side * 5.9))
		sw2.material = mat_sidewalk
		road_root.add_child(sw2)
		
		# Town shops (किराना, चाय, स्टेशनरी)
		for sx in [-18, -35, -52]:
			var shop = CSGBox3D.new()
			shop.size = Vector3(9.5, 3.8, 4.5)
			shop.position = Vector3(float(sx), 1.9, -5.0 + (z_side * 9.5))
			shop.material = mat_shop
			road_root.add_child(shop)
			
			# Warm shop lamp
			var shop_light = OmniLight3D.new()
			shop_light.position = Vector3(float(sx), 3.2, -5.0 + (z_side * 5.2))
			shop_light.light_color = Color(1.0, 0.85, 0.6)
			shop_light.light_energy = 2.0
			shop_light.omni_range = 10.0
			road_root.add_child(shop_light)
	
	# --------------------------------------------------------------------------
	# TURN 2: SCHOOL CORNER / T-JUNCTION (At X = -70, Z = -5)
	# --------------------------------------------------------------------------
	var corner2 = CSGBox3D.new()
	corner2.size = Vector3(14.0, 0.1, 14.0)
	corner2.position = Vector3(-70.0, -0.05, -5.0)
	corner2.material = mat_road
	road_root.add_child(corner2)
	
	# Signboard at Turn 2 telling player to Turn Right!
	var sign_corner2 = Node3D.new()
	sign_corner2.position = Vector3(-70.0, 0, 1.2)
	road_root.add_child(sign_corner2)
	
	var sc2_board = CSGBox3D.new()
	sc2_board.size = Vector3(2.8, 1.2, 0.08)
	sc2_board.position = Vector3(0, 2.2, 0)
	sc2_board.material = _create_mat(Color(0.08, 0.45, 0.22), 0.5)
	sign_corner2.add_child(sc2_board)
	
	var sc2_lbl = Label3D.new()
	sc2_lbl.text = "↱ दाएँ मुड़ें (TURN RIGHT)\n🏫 बालक उच्चतर माध्यमिक विद्यालय प्रवेश द्वार ➔\n[MAIN SCHOOL GATE — 80M]"
	sc2_lbl.font_size = 28
	sc2_lbl.modulate = Color(1.0, 0.95, 0.3)
	sc2_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sc2_lbl.position = Vector3(0, 2.2, -0.06)
	sign_corner2.add_child(sc2_lbl)
	
	# --------------------------------------------------------------------------
	# SEGMENT 3: Grand School Boulevard (Z: -5 down to -85m, along X = -70)
	# --------------------------------------------------------------------------
	var road3 = CSGBox3D.new()
	road3.size = Vector3(9.2, 0.1, 80.0)
	road3.position = Vector3(-70.0, -0.05, -45.0)
	road3.material = mat_road
	road_root.add_child(road3)
	
	for z in range(-82, -8, 6):
		var dash3 = CSGBox3D.new()
		dash3.size = Vector3(0.24, 0.11, 2.6)
		dash3.position = Vector3(-70.0, 0.01, float(z))
		dash3.material = mat_dash
		road_root.add_child(dash3)
		
	# Sidewalks with avenue trees and lamp posts
	for side in [-1, 1]:
		var sw3 = CSGBox3D.new()
		sw3.size = Vector3(3.4, 0.22, 80.0)
		sw3.position = Vector3(-70.0 + (side * 6.3), 0.02, -45.0)
		sw3.material = mat_sidewalk
		road_root.add_child(sw3)
		
		for lz in [-20, -40, -60, -78]:
			var pole = CSGBox3D.new()
			pole.size = Vector3(0.14, 5.2, 0.14)
			pole.position = Vector3(-70.0 + (side * 5.4), 2.6, float(lz))
			pole.material = mat_pole
			road_root.add_child(pole)
			
			var bulb = CSGSphere3D.new()
			bulb.radius = 0.18
			bulb.position = Vector3(-70.0 + (side * 4.6), 5.0, float(lz))
			bulb.material = mat_bulb
			road_root.add_child(bulb)
			
			var lamp_light = OmniLight3D.new()
			lamp_light.position = Vector3(-70.0 + (side * 4.6), 4.8, float(lz))
			lamp_light.light_color = Color(1.0, 0.90, 0.70)
			lamp_light.light_energy = 2.6
			lamp_light.omni_range = 15.0
			road_root.add_child(lamp_light)

# --- BOYS SCHOOL & MASSIVE OUTSIDE PLAYGROUND (मैदान) ---
func _build_boys_school_and_ground() -> void:
	school_root = Node3D.new()
	school_root.name = "BoysSchoolComplex"
	add_child(school_root)
	
	var mat_brick = _create_mat(Color(0.68, 0.28, 0.22), 0.8)
	var mat_stone_cream = _create_mat(Color(0.92, 0.88, 0.80), 0.65)
	var mat_iron_gate = _create_mat(Color(0.12, 0.12, 0.14), 0.4, 0.8)
	var mat_clay_ground = _create_mat(Color(0.52, 0.40, 0.28), 0.95) # Sports playground soil
	var mat_turf = _create_mat(Color(0.20, 0.44, 0.16), 0.9)
	var mat_track = _create_mat(Color(0.64, 0.28, 0.20), 0.95)
	var mat_pitch = _create_mat(Color(0.72, 0.62, 0.46), 0.9)
	var mat_tin_roof = _create_mat(Color(0.38, 0.42, 0.45), 0.4, 0.7)
	var mat_slogan_wall = _create_mat(Color(0.88, 0.86, 0.82), 0.7)
	
	# --------------------------------------------------------------------------
	# 1. GRAND SCHOOL MAIN GATE (At Z = -85.0, X = -70.0)
	# --------------------------------------------------------------------------
	var gate_x = -70.0
	var gate_z = SCHOOL_GATE_Z
	
	var pillar_l = CSGBox3D.new()
	pillar_l.size = Vector3(1.5, 5.5, 1.5)
	pillar_l.position = Vector3(gate_x - 5.5, 2.75, gate_z)
	pillar_l.material = mat_stone_cream
	school_root.add_child(pillar_l)
	
	var pillar_r = CSGBox3D.new()
	pillar_r.size = Vector3(1.5, 5.5, 1.5)
	pillar_r.position = Vector3(gate_x + 5.5, 2.75, gate_z)
	pillar_r.material = mat_stone_cream
	school_root.add_child(pillar_r)
	
	var arch_beam = CSGBox3D.new()
	arch_beam.size = Vector3(12.5, 1.3, 1.1)
	arch_beam.position = Vector3(gate_x, 5.5, gate_z)
	arch_beam.material = mat_stone_cream
	school_root.add_child(arch_beam)
	
	var name_board = CSGBox3D.new()
	name_board.size = Vector3(11.0, 0.95, 0.15)
	name_board.position = Vector3(gate_x, 5.5, gate_z + 0.56)
	name_board.material = _create_mat(Color(0.10, 0.16, 0.45), 0.5)
	school_root.add_child(name_board)
	
	var name_lbl = Label3D.new()
	name_lbl.text = "🏫 शासकीय उत्कृष्ट बालक उच्चतर माध्यमिक विद्यालय — पानसेमल\n[GOVT. EXCELLENCE BOYS HIGHER SECONDARY SCHOOL]"
	name_lbl.font_size = 32
	name_lbl.modulate = Color(1.0, 0.92, 0.35)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector3(gate_x, 5.5, gate_z + 0.65)
	school_root.add_child(name_lbl)
	
	# Open Wrought Iron Gates
	var gate_l = CSGBox3D.new()
	gate_l.size = Vector3(3.8, 3.8, 0.08)
	gate_l.position = Vector3(gate_x - 4.0, 1.9, gate_z - 1.5)
	gate_l.rotation_degrees = Vector3(0, 60, 0)
	gate_l.material = mat_iron_gate
	school_root.add_child(gate_l)
	
	var gate_r = CSGBox3D.new()
	gate_r.size = Vector3(3.8, 3.8, 0.08)
	gate_r.position = Vector3(gate_x + 4.0, 1.9, gate_z - 1.5)
	gate_r.rotation_degrees = Vector3(0, -60, 0)
	gate_r.material = mat_iron_gate
	school_root.add_child(gate_r)
	
	# Security Watchman Cabin beside the gate
	var guard_cabin = CSGBox3D.new()
	guard_cabin.size = Vector3(3.5, 3.0, 3.2)
	guard_cabin.position = Vector3(gate_x + 8.5, 1.5, gate_z)
	guard_cabin.material = _create_mat(Color(0.85, 0.82, 0.76))
	school_root.add_child(guard_cabin)
	
	var guard_lbl = Label3D.new()
	guard_lbl.text = "सुरक्षा चौकी\n[SECURITY]"
	guard_lbl.font_size = 22
	guard_lbl.modulate = Color(0.1, 0.1, 0.1)
	guard_lbl.position = Vector3(gate_x + 8.5, 2.6, gate_z + 1.62)
	school_root.add_child(guard_lbl)
	
	# --------------------------------------------------------------------------
	# 2. ENORMOUS OUTSIDE SCHOOL PLAYGROUND (95m WIDE X 90m LONG!)
	# --------------------------------------------------------------------------
	# Ground extends from Z = -85m down to Z = -175m, centered at X = -70.0
	var ground_z_center = -130.0
	var ground_len = 90.0
	var ground_wid = 95.0
	
	# Main Clay Sports Ground
	var ground = CSGBox3D.new()
	ground.size = Vector3(ground_wid, 0.12, ground_len)
	ground.position = Vector3(gate_x, -0.05, ground_z_center)
	ground.material = mat_clay_ground
	school_root.add_child(ground)
	
	# Green grass turf surrounding ground
	var turf_l = CSGBox3D.new()
	turf_l.size = Vector3(16.0, 0.14, ground_len)
	turf_l.position = Vector3(gate_x - 39.5, -0.04, ground_z_center)
	turf_l.material = mat_turf
	school_root.add_child(turf_l)
	
	var turf_r = CSGBox3D.new()
	turf_r.size = Vector3(16.0, 0.14, ground_len)
	turf_r.position = Vector3(gate_x + 39.5, -0.04, ground_z_center)
	turf_r.material = mat_turf
	school_root.add_child(turf_r)
	
	# Red clay running track oval
	var track = CSGBox3D.new()
	track.size = Vector3(64.0, 0.13, 78.0)
	track.position = Vector3(gate_x, -0.045, ground_z_center)
	track.material = mat_track
	school_root.add_child(track)
	
	var inner_play = CSGBox3D.new()
	inner_play.size = Vector3(54.0, 0.14, 68.0)
	inner_play.position = Vector3(gate_x, -0.04, ground_z_center)
	inner_play.material = mat_clay_ground
	school_root.add_child(inner_play)
	
	# --------------------------------------------------------------------------
	# 3. DETAILED SCHOOL FEATURES ON THE GROUND
	# --------------------------------------------------------------------------
	# Cricket Pitch on the Left of Ground
	var pitch = CSGBox3D.new()
	pitch.size = Vector3(3.6, 0.15, 22.0)
	pitch.position = Vector3(gate_x - 18.0, -0.03, -125.0)
	pitch.material = mat_pitch
	school_root.add_child(pitch)
	
	for pz in [-135.0, -115.0]:
		for wx in [-0.15, 0.0, 0.15]:
			var stump = CSGCylinder3D.new()
			stump.radius = 0.025
			stump.height = 0.75
			stump.position = Vector3(gate_x - 18.0 + wx, 0.38, pz)
			stump.material = _create_mat(Color(0.85, 0.72, 0.45), 0.7)
			school_root.add_child(stump)
	
	# Central Elevated Flag Dais with Tiranga
	var flag_dais = CSGCylinder3D.new()
	flag_dais.radius = 4.2
	flag_dais.height = 0.25
	flag_dais.position = Vector3(gate_x, 0.08, -135.0)
	flag_dais.material = mat_stone_cream
	school_root.add_child(flag_dais)
	
	var flag_pole = CSGCylinder3D.new()
	flag_pole.radius = 0.06
	flag_pole.height = 9.5
	flag_pole.position = Vector3(gate_x, 4.75, -135.0)
	flag_pole.material = _create_mat(Color(0.9, 0.9, 0.92), 0.2, 0.9)
	school_root.add_child(flag_pole)
	
	var f_saffron = CSGBox3D.new()
	f_saffron.size = Vector3(0.04, 0.38, 1.25)
	f_saffron.position = Vector3(gate_x + 0.02, 9.1, -134.4)
	f_saffron.material = _create_mat(Color(1.0, 0.55, 0.1), 0.6)
	school_root.add_child(f_saffron)
	
	var f_white = CSGBox3D.new()
	f_white.size = Vector3(0.04, 0.38, 1.25)
	f_white.position = Vector3(gate_x + 0.02, 8.72, -134.4)
	f_white.material = _create_mat(Color(0.98, 0.98, 0.98), 0.6)
	school_root.add_child(f_white)
	
	var f_green = CSGBox3D.new()
	f_green.size = Vector3(0.04, 0.38, 1.25)
	f_green.position = Vector3(gate_x + 0.02, 8.34, -134.4)
	f_green.material = _create_mat(Color(0.1, 0.65, 0.2), 0.6)
	school_root.add_child(f_green)
	
	# Assembly Stage / मंच
	var stage = CSGBox3D.new()
	stage.size = Vector3(12.0, 1.1, 6.5)
	stage.position = Vector3(gate_x, 0.55, -155.0)
	stage.material = mat_stone_cream
	school_root.add_child(stage)
	
	var stage_lbl = Label3D.new()
	stage_lbl.text = "।। असेंबली प्रार्थना मंच ।।\n[SCHOOL ASSEMBLY STAGE]"
	stage_lbl.font_size = 24
	stage_lbl.modulate = Color(0.1, 0.2, 0.4)
	stage_lbl.position = Vector3(gate_x, 0.6, -151.7)
	school_root.add_child(stage_lbl)
	
	# Cycle Stand / Bicycle Shed on the right side
	var cycle_shed = CSGBox3D.new()
	cycle_shed.size = Vector3(18.0, 3.2, 5.5)
	cycle_shed.position = Vector3(gate_x + 28.0, 1.6, -100.0)
	cycle_shed.material = mat_tin_roof
	school_root.add_child(cycle_shed)
	
	var shed_lbl = Label3D.new()
	shed_lbl.text = "🚲 छात्र साइकिल स्टैंड\n[STUDENTS CYCLE PARKING SHED]"
	shed_lbl.font_size = 24
	shed_lbl.modulate = Color(1.0, 0.95, 0.4)
	shed_lbl.position = Vector3(gate_x + 28.0, 3.4, -97.2)
	school_root.add_child(shed_lbl)
	
	# Drinking Water Station / शीतल पेयजल टंकी
	var water_stn = CSGBox3D.new()
	water_stn.size = Vector3(4.5, 2.4, 2.2)
	water_stn.position = Vector3(gate_x - 26.0, 1.2, -100.0)
	water_stn.material = _create_mat(Color(0.25, 0.65, 0.85))
	school_root.add_child(water_stn)
	
	var water_lbl = Label3D.new()
	water_lbl.text = "💧 शीतल एवं स्वच्छ पेयजल\n[DRINKING WATER STATION]"
	water_lbl.font_size = 22
	water_lbl.modulate = Color(1, 1, 1)
	water_lbl.position = Vector3(gate_x - 26.0, 2.6, -98.8)
	school_root.add_child(water_lbl)
	
	# Boundary Walls with Inspiring Hindi Slogans
	var slogan_wall = CSGBox3D.new()
	slogan_wall.size = Vector3(35.0, 2.8, 0.4)
	slogan_wall.position = Vector3(gate_x - 26.0, 1.4, -85.0)
	slogan_wall.material = mat_slogan_wall
	school_root.add_child(slogan_wall)
	
	var sw_lbl1 = Label3D.new()
	sw_lbl1.text = "।। विद्या ददाति विनयं ।।  •  ।। ज्ञानार्थ प्रवेश, सेवार्थ प्रस्थान ।।"
	sw_lbl1.font_size = 26
	sw_lbl1.modulate = Color(0.65, 0.15, 0.15)
	sw_lbl1.position = Vector3(gate_x - 26.0, 1.8, -84.7)
	school_root.add_child(sw_lbl1)
	
	var slogan_wall2 = CSGBox3D.new()
	slogan_wall2.size = Vector3(35.0, 2.8, 0.4)
	slogan_wall2.position = Vector3(gate_x + 26.0, 1.4, -85.0)
	slogan_wall2.material = mat_slogan_wall
	school_root.add_child(slogan_wall2)
	
	var sw_lbl2 = Label3D.new()
	sw_lbl2.text = "सर्व शिक्षा अभियान — सब पढ़ें, सब बढ़ें  •  स्वच्छ विद्यालय, स्वस्थ भारत"
	sw_lbl2.font_size = 24
	sw_lbl2.modulate = Color(0.12, 0.45, 0.20)
	sw_lbl2.position = Vector3(gate_x + 26.0, 1.8, -84.7)
	school_root.add_child(sw_lbl2)
	
	# 4 Stadium Floodlight Towers lighting up the outside ground
	var flood_coords = [
		Vector3(gate_x - 38.0, 0, -92.0),
		Vector3(gate_x + 38.0, 0, -92.0),
		Vector3(gate_x - 38.0, 0, -165.0),
		Vector3(gate_x + 38.0, 0, -165.0)
	]
	for fc in flood_coords:
		var ft_pole = CSGBox3D.new()
		ft_pole.size = Vector3(0.4, 13.0, 0.4)
		ft_pole.position = fc + Vector3(0, 6.5, 0)
		ft_pole.material = _create_mat(Color(0.35, 0.38, 0.42), 0.3, 0.8)
		school_root.add_child(ft_pole)
		
		var flood_light = OmniLight3D.new()
		flood_light.position = fc + Vector3(0, 12.5, 0)
		flood_light.light_color = Color(1.0, 0.96, 0.88)
		flood_light.light_energy = 3.6
		flood_light.omni_range = 35.0
		school_root.add_child(flood_light)
	
	# --------------------------------------------------------------------------
	# 4. GRAND 2-STORY SCHOOL BUILDING (Standing at back of ground, Z = -172m)
	# --------------------------------------------------------------------------
	var bldg = CSGBox3D.new()
	bldg.size = Vector3(56.0, 11.5, 16.0)
	bldg.position = Vector3(gate_x, 5.75, -172.0)
	bldg.material = mat_brick
	school_root.add_child(bldg)
	
	# Classroom windows
	for wx in [-22.0, -15.0, -8.0, 8.0, 15.0, 22.0]:
		for wy in [3.2, 7.8]:
			var win = CSGBox3D.new()
			win.size = Vector3(2.6, 2.2, 0.15)
			win.position = Vector3(gate_x + wx, wy, -163.9)
			win.material = _create_mat(Color(0.15, 0.25, 0.40), 0.2, 0.6)
			school_root.add_child(win)
			
	# School Clock
	var clock = CSGCylinder3D.new()
	clock.radius = 0.95
	clock.height = 0.15
	clock.position = Vector3(gate_x, 9.2, -163.8)
	clock.rotation_degrees = Vector3(90, 0, 0)
	clock.material = _create_mat(Color(0.96, 0.96, 0.96), 0.3)
	school_root.add_child(clock)
	
	# Golden Waypoint Beacon rising from the meeting point on the ground!
	beacon_beam = CSGCylinder3D.new()
	beacon_beam.radius = 0.85
	beacon_beam.height = 65.0
	beacon_beam.position = Vector3(GROUND_MEETING_POS.x, 32.5, GROUND_MEETING_POS.z)
	beacon_beam.material = _create_mat(Color(1.0, 0.85, 0.25, 0.35), 0.1, 0.0, Color(1.0, 0.8, 0.2), 3.0)
	beacon_beam.transparency = 0.4
	school_root.add_child(beacon_beam)

# --- PLAYER BICYCLE & PROTAGONIST WITH BACKPACK ---
func _build_player_bicycle() -> void:
	player_root = Node3D.new()
	player_root.name = "PlayerRider"
	player_root.position = player_pos
	add_child(player_root)
	
	bike_frame = Node3D.new()
	bike_frame.name = "BikeFrame"
	player_root.add_child(bike_frame)
	
	var mat_frame = _create_mat(Color(0.12, 0.25, 0.45), 0.4, 0.7)
	var mat_metal = _create_mat(Color(0.65, 0.65, 0.68), 0.25, 0.85)
	var mat_tire = _create_mat(Color(0.10, 0.10, 0.12), 0.85)
	var mat_saddle = _create_mat(Color(0.18, 0.12, 0.08), 0.7)
	
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
	
	var saddle = CSGBox3D.new()
	saddle.size = Vector3(0.22, 0.08, 0.32)
	saddle.position = Vector3(0, 0.98, 0.32)
	saddle.material = mat_saddle
	bike_frame.add_child(saddle)
	
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
	
	for gx in [-0.31, 0.31]:
		var grip = CSGBox3D.new()
		grip.size = Vector3(0.12, 0.07, 0.07)
		grip.position = Vector3(gx, 1.08, -0.42)
		grip.material = mat_tire
		bike_frame.add_child(grip)
	
	# Headlight (SpotLight3D)
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
	
	# Wheels
	wheel_front = Node3D.new()
	wheel_front.position = Vector3(0, 0.36, -0.52)
	bike_frame.add_child(wheel_front)
	var wf_tire = CSGCylinder3D.new()
	wf_tire.radius = 0.36
	wf_tire.height = 0.06
	wf_tire.rotation_degrees = Vector3(0, 0, 90)
	wf_tire.material = mat_tire
	wheel_front.add_child(wf_tire)
	
	wheel_rear = Node3D.new()
	wheel_rear.position = Vector3(0, 0.36, 0.52)
	bike_frame.add_child(wheel_rear)
	var wr_tire = CSGCylinder3D.new()
	wr_tire.radius = 0.36
	wr_tire.height = 0.06
	wr_tire.rotation_degrees = Vector3(0, 0, 90)
	wr_tire.material = mat_tire
	wheel_rear.add_child(wr_tire)
	
	pedal_crank = Node3D.new()
	pedal_crank.position = Vector3(0, 0.36, 0.0)
	bike_frame.add_child(pedal_crank)
	var crank_arm = CSGBox3D.new()
	crank_arm.size = Vector3(0.32, 0.04, 0.04)
	crank_arm.material = mat_metal
	pedal_crank.add_child(crank_arm)
	
	# Rider Model with 3D Backpack
	var mat_skin = _create_mat(Color(0.86, 0.68, 0.54), 0.75)
	var mat_shirt = _create_mat(Color(0.14, 0.16, 0.22), 0.8)
	var mat_jeans = _create_mat(Color(0.18, 0.28, 0.44), 0.85)
	var mat_hair = _create_mat(Color(0.08, 0.08, 0.09), 0.9)
	var mat_backpack = _create_mat(Color(0.10, 0.18, 0.34), 0.75)
	
	var rider_body = Node3D.new()
	rider_body.position = Vector3(0, 0.95, 0.22)
	bike_frame.add_child(rider_body)
	
	var torso = CSGBox3D.new()
	torso.size = Vector3(0.38, 0.48, 0.24)
	torso.position = Vector3(0, 0.24, 0)
	torso.rotation_degrees = Vector3(18.0, 0, 0)
	torso.material = mat_shirt
	rider_body.add_child(torso)
	
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
	
	# 3D BACKPACK STRAPPED ON BACK
	rider_backpack = Node3D.new()
	rider_backpack.name = "RiderBackpack"
	rider_backpack.position = Vector3(0, 0.26, 0.14)
	rider_backpack.rotation_degrees = Vector3(18.0, 0, 0)
	rider_body.add_child(rider_backpack)
	
	var bag_mesh = CSGBox3D.new()
	bag_mesh.size = Vector3(0.36, 0.44, 0.22)
	bag_mesh.position = Vector3(0, 0, 0)
	bag_mesh.material = mat_backpack
	rider_backpack.add_child(bag_mesh)
	
	var bag_pocket = CSGBox3D.new()
	bag_pocket.size = Vector3(0.26, 0.22, 0.08)
	bag_pocket.position = Vector3(0, -0.06, 0.13)
	bag_pocket.material = _create_mat(Color(0.18, 0.24, 0.42), 0.7)
	rider_backpack.add_child(bag_pocket)
	
	var bottle = CSGCylinder3D.new()
	bottle.radius = 0.04
	bottle.height = 0.22
	bottle.position = Vector3(0.20, 0, 0.04)
	bottle.material = _create_mat(Color(0.2, 0.75, 0.85), 0.4)
	rider_backpack.add_child(bottle)
	
	for sx in [-0.14, 0.14]:
		var strap = CSGBox3D.new()
		strap.size = Vector3(0.06, 0.42, 0.24)
		strap.position = Vector3(sx, 0, -0.08)
		strap.material = _create_mat(Color(0.08, 0.12, 0.20))
		rider_backpack.add_child(strap)
	
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

# --- SAHIL & AASHUTOSH WAITING IN THE OUTSIDE BIG GROUND ---
func _build_companions_on_ground() -> void:
	var comp_root = Node3D.new()
	comp_root.name = "CompanionsOnGround"
	comp_root.position = GROUND_MEETING_POS
	add_child(comp_root)
	
	var mat_skin = _create_mat(Color(0.86, 0.68, 0.54), 0.75)
	var mat_sahil_shirt = _create_mat(Color(0.85, 0.35, 0.15), 0.8)
	var mat_sahil_cap = _create_mat(Color(0.12, 0.35, 0.85), 0.7)
	var mat_aashu_shirt = _create_mat(Color(0.25, 0.55, 0.85), 0.8)
	var mat_aashu_glass = _create_mat(Color(0.1, 0.1, 0.1), 0.2, 0.9)
	var mat_jeans = _create_mat(Color(0.15, 0.22, 0.36), 0.85)
	var mat_bag_sahil = _create_mat(Color(0.35, 0.15, 0.15), 0.8)
	var mat_bag_aashu = _create_mat(Color(0.18, 0.38, 0.25), 0.8)
	
	# SAHIL on the ground
	comp_sahil = Node3D.new()
	comp_sahil.name = "SahilOnGround"
	comp_sahil.position = Vector3(-2.4, 0, 0)
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
	
	# Sahil's red bicycle parked on kickstand on the ground
	var s_bike = Node3D.new()
	s_bike.position = Vector3(-0.9, 0, 0.2)
	s_bike.rotation_degrees = Vector3(0, 25, 0)
	comp_sahil.add_child(s_bike)
	var sb_frame = CSGBox3D.new()
	sb_frame.size = Vector3(0.06, 0.55, 1.4)
	sb_frame.position = Vector3(0, 0.55, 0)
	sb_frame.material = _create_mat(Color(0.85, 0.15, 0.15), 0.5, 0.7)
	s_bike.add_child(sb_frame)
	
	# AASHUTOSH on the ground
	comp_aashu = Node3D.new()
	comp_aashu.name = "AashutoshOnGround"
	comp_aashu.position = Vector3(2.4, 0, 0)
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
	
	var a_bike = Node3D.new()
	a_bike.position = Vector3(0.9, 0, 0.2)
	a_bike.rotation_degrees = Vector3(0, -25, 0)
	comp_aashu.add_child(a_bike)
	var ab_frame = CSGBox3D.new()
	ab_frame.size = Vector3(0.06, 0.55, 1.4)
	ab_frame.position = Vector3(0, 0.55, 0)
	ab_frame.material = _create_mat(Color(0.15, 0.45, 0.85), 0.5, 0.7)
	a_bike.add_child(ab_frame)

# --- USER INTERFACE (HUD, TOUCH BUTTONS, SUBTITLES, ARRIVAL CARD) ---
func _build_ui() -> void:
	ui_root = CanvasLayer.new()
	ui_root.name = "CycleHUD"
	ui_root.layer = 120
	add_child(ui_root)
	
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
	banner_label.text = "🚲 RIDE BICYCLE TO BOYS SCHOOL [रास्ते पर मुड़ते हुए स्कूल पहुँचें]"
	banner_label.add_theme_font_size_override("font_size", 15)
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	banner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_hbox.add_child(banner_label)
	
	dist_label = Label.new()
	dist_label.text = "📍 65M TO CHOWK"
	dist_label.add_theme_font_size_override("font_size", 15)
	dist_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	b_hbox.add_child(dist_label)
	
	skip_btn = Button.new()
	skip_btn.text = "SKIP ⏭️"
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -110
	skip_btn.offset_top = 18
	skip_btn.offset_right = -20
	skip_btn.offset_bottom = 74
	skip_btn.pressed.connect(_on_skip_pressed)
	ui_root.add_child(skip_btn)
	
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
	
	_build_touch_controls()
	
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
	ac_desc.text = "बॉयज़ स्कूल के बाहर वाले विशाल मैदान में तीनों दोस्त मिले!\nभानगढ़ खंडहर के अंदर गुप्त रास्ते से दाखिल होने का पूरा प्लान तैयार हुआ।"
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
		touch_hud.visible = false
	
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

# --- FULL 3D BICYCLE DRIVING WITH TURNS ---
func _physics_process(delta: float) -> void:
	if cutscene_active:
		return
		
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
	
	# Full 360-degree free steering so player can easily take left and right turns!
	if abs(steer_input) > 0.05:
		rider_heading += steer_input * TURN_SPEED * delta
		var target_tilt = steer_input * 0.18
		cycle_tilt = lerp(cycle_tilt, target_tilt, 7.0 * delta)
	else:
		cycle_tilt = lerp(cycle_tilt, 0.0, 6.0 * delta)
		
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
	
	# Clamp boundaries based on route zone
	if player_pos.z > TURN1_CHOWK_Z:
		# Road 1: Home Street
		player_pos.x = clamp(player_pos.x, -4.5, 4.5)
	elif player_pos.z <= TURN1_CHOWK_Z and player_pos.z >= (TURN1_CHOWK_Z - 12.0) and player_pos.x > TURN2_CORNER_X:
		# Road 2: Market Connecting Street
		player_pos.z = clamp(player_pos.z, -10.0, 0.0)
	elif player_pos.x <= (TURN2_CORNER_X + 6.0) and player_pos.z > SCHOOL_GATE_Z:
		# Road 3: School Boulevard
		player_pos.x = clamp(player_pos.x, TURN2_CORNER_X - 4.5, TURN2_CORNER_X + 4.5)
	else:
		# Outside Big Playground: Massive 90m x 90m freedom!
		player_pos.x = clamp(player_pos.x, TURN2_CORNER_X - 44.0, TURN2_CORNER_X + 44.0)
		player_pos.z = clamp(player_pos.z, -170.0, SCHOOL_GATE_Z)
		
	if player_root:
		player_root.position = player_pos
		player_root.rotation.y = rider_heading
	if bike_frame:
		bike_frame.rotation.z = cycle_tilt
		
	if cam_pivot:
		cam_pivot.position = player_pos
		cam_pivot.rotation.y = rider_heading
		
	var cur_speed = player_velocity.length()
	if cur_speed > 0.1:
		pedal_phase += delta * cur_speed * 2.2
		var roll = delta * cur_speed * 4.0
		if wheel_front: wheel_front.rotate_x(roll)
		if wheel_rear: wheel_rear.rotate_x(roll)
		if pedal_crank: pedal_crank.rotation.x = pedal_phase
		
		if rider_leg_l: rider_leg_l.rotation.x = sin(pedal_phase) * 0.45 + 0.25
		if rider_leg_r: rider_leg_r.rotation.x = -sin(pedal_phase) * 0.45 + 0.25
		
	# Dynamic Navigational HUD based on player position on route
	_update_nav_hud()
	
	# Trigger Arrival when reaching Sahil and Aashutosh on the outside ground!
	if player_pos.distance_to(GROUND_MEETING_POS) <= 5.5 and not is_arrived:
		_trigger_school_arrival()

func _update_nav_hud() -> void:
	if not dist_label or not banner_label: return
	
	if player_pos.z > (TURN1_CHOWK_Z + 8.0):
		var d = int(player_pos.z - TURN1_CHOWK_Z)
		banner_label.text = "🚲 RIDE DOWN STREET ➔ CHOWK AHEAD [सीधे चौराहे की तरफ जाएँ]"
		dist_label.text = "📍 %d M TO CHOWK" % d
	elif player_pos.z <= (TURN1_CHOWK_Z + 8.0) and player_pos.x > -12.0:
		banner_label.text = "↰ TURN LEFT AT CHOWK INTO MARKET ROAD [चौराहे से बाएँ मुड़ें]"
		dist_label.text = "📍 ↰ TURN LEFT"
	elif player_pos.x <= -12.0 and player_pos.x > (TURN2_CORNER_X + 10.0):
		var d2 = int(abs(player_pos.x - TURN2_CORNER_X))
		banner_label.text = "🚲 MARKET ROAD ➔ TURN RIGHT AT CORNER [सीधे जाकर दाएँ मुड़ें]"
		dist_label.text = "📍 %d M TO SCHOOL TURN" % d2
	elif player_pos.x <= (TURN2_CORNER_X + 10.0) and player_pos.z > (SCHOOL_GATE_Z + 5.0):
		var dg = int(abs(player_pos.z - SCHOOL_GATE_Z))
		banner_label.text = "↱ TURN RIGHT ➔ HEAD TOWARDS SCHOOL GATE [स्कूल गेट की तरफ]"
		dist_label.text = "📍 SCHOOL GATE: %d M" % dg
	else:
		var df = int(player_pos.distance_to(GROUND_MEETING_POS))
		banner_label.text = "🏟️ OUTSIDE GROUND: MEET SAHIL & AASHUTOSH [मैदान में दोस्तों से मिलें]"
		dist_label.text = "📍 FRIENDS: %d M" % df

# --- ARRIVAL ON OUTSIDE BIG GROUND (WITH HINDI VOICE ACTING) ---
func _trigger_school_arrival() -> void:
	is_arrived = true
	cutscene_active = true
	
	if audio_cycle and audio_cycle.playing:
		audio_cycle.stop()
		
	if touch_hud:
		touch_hud.visible = false
		
	var target_stop = GROUND_MEETING_POS + Vector3(0.0, 0.0, 2.4)
	var tw_stop = create_tween()
	tw_stop.tween_property(player_root, "position", target_stop, 1.4).set_trans(Tween.TRANS_QUAD)
	
	var tw_cam = create_tween()
	tw_cam.parallel().tween_property(cam_pivot, "position", target_stop, 1.4)
	tw_cam.parallel().tween_property(cam, "position", Vector3(0.0, 1.65, 3.8), 1.4)
	tw_cam.parallel().tween_property(cam, "rotation_degrees", Vector3(-4.0, 0.0, 0.0), 1.4)
	
	await tw_stop.finished
	
	if rider_leg_l: rider_leg_l.rotation.x = 0.0
	if rider_leg_r: rider_leg_r.rotation.x = 0.0
	
	_ring_bell()
	
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
		
	if audio_voice and d.has("audio") and d["audio"]:
		audio_voice.stop()
		audio_voice.stream = d["audio"]
		audio_voice.play()
		
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
	player_pos = GROUND_MEETING_POS + Vector3(0.0, 0.0, 3.0)
	_trigger_school_arrival()

func _on_proceed_to_bhangarh_pressed() -> void:
	if proceed_btn:
		proceed_btn.disabled = true
		proceed_btn.text = "🏰 LOADING BHANGARH RUINS..."
	get_tree().change_scene_to_file("res://scenes/bhangarh_ruins.tscn")
