# street_to_kripal.gd
# Pansemal Town Street Journey:
# 1. St. Augustine School Exit & Bicycle Ride in Thunderstorm
# 2. Arrive at Kripal's residence -> Option to DISMOUNT BICYCLE [E] & park on kickstand
# 3. Walk to front door on foot -> Ring Doorbell [E] -> Convo with Kripal's Mother
# 4. Kripal's family car parked outside -> Enter Driver Seat [E]
# 5. Drive Kripal's car through Pansemal street to the Police Station (with Aunty & friends inside)
# 6. Exit car with [BACKSPACE] -> Walk up Indian Brown Sandstone Police Station steps -> Enter [E]

extends Node3D

# --- Audio Players ---
@onready var ambience_audio: AudioStreamPlayer = $Audio/AmbienceAudio
@onready var doorbell_audio: AudioStreamPlayer = $Audio/DoorbellAudio
@onready var home_door_audio: AudioStreamPlayer = $Audio/HomeDoorAudio
@onready var voice_audio: AudioStreamPlayer = $Audio/VoiceAudio
@onready var footstep_audio: AudioStreamPlayer = $Audio/FootstepAudio
@onready var thunder_audio: AudioStreamPlayer = $Audio/ThunderAudio
@onready var cycle_audio: AudioStreamPlayer = $Audio/CycleAudio
@onready var bell_audio: AudioStreamPlayer = $Audio/BellAudio
@onready var car_start_audio: AudioStreamPlayer = $Audio/CarStartAudio
@onready var car_engine_audio: AudioStreamPlayer = $Audio/CarEngineAudio
@onready var car_door_open_audio: AudioStreamPlayer = $Audio/CarDoorOpenAudio
@onready var car_door_close_audio: AudioStreamPlayer = $Audio/CarDoorCloseAudio

# --- World & Environment ---
@onready var moonlight: DirectionalLight3D = $Moonlight
@onready var lightning_light: DirectionalLight3D = $LightningLight
@onready var door_hinge: Node3D = $KripalHouse/DoorHinge
@onready var door_trigger: Area3D = $KripalHouse/DoorTrigger
@onready var police_door_trigger: Area3D = $EnvironmentProps/PansemalTownHouses/PansemalPoliceStation/PoliceDoorTrigger
@onready var kripal_mummy: Node3D = $KripalHouse/KripalMummy
@onready var convo_camera: Camera3D = $DoorConvoCamera
@onready var sahil: CharacterBody3D = $Companions/SahilCompanion
@onready var aashutosh: CharacterBody3D = $Companions/AashutoshCompanion
@onready var pedestrian1: Node3D = $EnvironmentProps/Pedestrians/Pedestrian1
@onready var pedestrian2: Node3D = $EnvironmentProps/Pedestrians/Pedestrian2
@onready var trees_parent: Node3D = $EnvironmentProps/Trees

# Police Station lights
@onready var police_light_red: OmniLight3D = $EnvironmentProps/PansemalTownHouses/PansemalPoliceStation/PoliceLightRed
@onready var police_light_blue: OmniLight3D = $EnvironmentProps/PansemalTownHouses/PansemalPoliceStation/PoliceLightBlue
@onready var gps_arrows: Node3D = $EnvironmentProps/GPSRoadArrows

# Kripal's Car & Parked Cycles
@onready var kripal_car: CharacterBody3D = $KripalCar
@onready var car_trigger: Area3D = $KripalCar/CarTrigger
@onready var car_camera: Camera3D = $KripalCar/CarCameraPivot/CarCamera
@onready var parked_bicycles: Node3D = $ParkedBicycles

# --- Player Nodes ---
@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $Player/CameraPivot
@onready var camera: Camera3D = $Player/CameraPivot/Camera3D
@onready var flashlight: SpotLight3D = $Player/CameraPivot/Flashlight
@onready var player_collision: CollisionShape3D = $Player/CollisionShape3D
@onready var visual_model: Node3D = $Player/VisualModel
@onready var player_cycle: Node3D = $Player/CycleModel
@onready var sahil_cycle: Node3D = $Companions/SahilCompanion/CycleModel
@onready var aashu_cycle: Node3D = $Companions/AashutoshCompanion/CycleModel

# Procedural Bicycle Limbs & Wheels (Player)
@onready var p_arms_node: Node3D = $Player/VisualModel/ArmsNode
@onready var p_legs_node: Node3D = $Player/VisualModel/LegsNode
@onready var p_leg_l_thigh: Node3D = $Player/VisualModel/LegsNode/LegL_Thigh
@onready var p_leg_l_shin: Node3D = $Player/VisualModel/LegsNode/LegL_Shin
@onready var p_boot_l_base: Node3D = $Player/VisualModel/LegsNode/BootL_Base
@onready var p_boot_l_sole: Node3D = $Player/VisualModel/LegsNode/BootL_Sole
@onready var p_leg_r_thigh: Node3D = $Player/VisualModel/LegsNode/LegR_Thigh
@onready var p_leg_r_shin: Node3D = $Player/VisualModel/LegsNode/LegR_Shin
@onready var p_boot_r_base: Node3D = $Player/VisualModel/LegsNode/BootR_Base
@onready var p_boot_r_sole: Node3D = $Player/VisualModel/LegsNode/BootR_Sole
@onready var p_front_wheel: Node3D = $Player/CycleModel/FrontWheel
@onready var p_rear_wheel: Node3D = $Player/CycleModel/RearWheel

# Procedural Bicycle Limbs & Wheels (Sahil)
@onready var s_arms_node: Node3D = $Companions/SahilCompanion/VisualModel/ArmsNode
@onready var s_legs_node: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode
@onready var s_leg_l_thigh: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/LegL_Thigh
@onready var s_leg_l_shin: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/LegL_Shin
@onready var s_boot_l_base: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/BootL_Base
@onready var s_boot_l_sole: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/BootL_Sole
@onready var s_leg_r_thigh: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/LegR_Thigh
@onready var s_leg_r_shin: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/LegR_Shin
@onready var s_boot_r_base: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/BootR_Base
@onready var s_boot_r_sole: Node3D = $Companions/SahilCompanion/VisualModel/LegsNode/BootR_Sole
@onready var s_front_wheel: Node3D = $Companions/SahilCompanion/CycleModel/FrontWheel
@onready var s_rear_wheel: Node3D = $Companions/SahilCompanion/CycleModel/RearWheel

# Procedural Bicycle Limbs & Wheels (Aashutosh)
@onready var a_arms_node: Node3D = $Companions/AashutoshCompanion/VisualModel/ArmsNode
@onready var a_legs_node: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode
@onready var a_leg_l_thigh: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/LegL_Thigh
@onready var a_leg_l_shin: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/LegL_Shin
@onready var a_boot_l_base: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/BootL_Base
@onready var a_boot_l_sole: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/BootL_Sole
@onready var a_leg_r_thigh: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/LegR_Thigh
@onready var a_leg_r_shin: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/LegR_Shin
@onready var a_boot_r_base: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/BootR_Base
@onready var a_boot_r_sole: Node3D = $Companions/AashutoshCompanion/VisualModel/LegsNode/BootR_Sole
@onready var a_front_wheel: Node3D = $Companions/AashutoshCompanion/CycleModel/FrontWheel
@onready var a_rear_wheel: Node3D = $Companions/AashutoshCompanion/CycleModel/RearWheel

var pedal_phase: float = 0.0
var default_limb_transforms: Dictionary = {}

# --- UI Nodes ---
@onready var lightning_flash_ui: ColorRect = $StreetUI/LightningFlashUI
@onready var view_toggle_btn: Button = $StreetUI/HUDContainer/HBox/ViewToggleBtn
@onready var map_toggle_btn: Button = $StreetUI/HUDContainer/HBox/MapToggleBtn
@onready var action_prompt: Label = $StreetUI/HUDContainer/ActionPrompt
@onready var objective_banner: Label = $StreetUI/ObjectiveBanner
@onready var mini_map_panel: PanelContainer = $StreetUI/MiniMapPanel
@onready var radar_display: Control = $StreetUI/MiniMapPanel/Margin/VBox/RadarDisplay
@onready var distance_label: Label = $StreetUI/MiniMapPanel/Margin/VBox/DistanceLabel
@onready var town_map_overlay: PanelContainer = $StreetUI/TownMapOverlay
@onready var close_map_btn: Button = $StreetUI/TownMapOverlay/Margin/VBox/HeaderHBox/CloseMapBtn
@onready var map_canvas: Control = $StreetUI/TownMapOverlay/Margin/VBox/MapCanvas
@onready var dialogue_box: PanelContainer = $StreetUI/DialogueBox
@onready var speaker_label: Label = $StreetUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_text: Label = $StreetUI/DialogueBox/Margin/VBox/DialogueText
@onready var advance_tip: Label = $StreetUI/DialogueBox/Margin/VBox/AdvanceTip
@onready var next_chapter_card: ColorRect = $StreetUI/NextChapterCard
@onready var start_police_btn: Button = $StreetUI/NextChapterCard/Margin/VBox/BtnBox/StartPoliceBtn
@onready var replay_btn: Button = $StreetUI/NextChapterCard/Margin/VBox/BtnBox/ReplayStreetBtn
@onready var prompt_label: Label = $StreetUI/PromptLabel
@onready var subtitle: Label = $StreetUI/Subtitle

# --- State Enums ---
enum PlayerMode {
	CYCLING,         # Initial bicycle ride through thunderstorm
	FOOT_KRIPAL,     # Dismounted from cycle, walking to Kripal's door
	DRIVING_CAR,     # Driving Kripal's car with Aunty & friends to Police Station
	FOOT_POLICE      # Exited car at Police Station, entering station
}
var current_mode: PlayerMode = PlayerMode.CYCLING

# Movement & Physics Constants
const CYCLE_SPEED: float = 7.5
const SPRINT_CYCLE_SPEED: float = 12.0
const WALK_SPEED: float = 3.6
const ACCEL: float = 18.0
const MOUSE_SENSITIVITY: float = 0.0028
var gravity: float = 9.8

# Car Physics
var car_speed: float = 0.0
const CAR_MAX_SPEED: float = 15.0
const CAR_ACCEL: float = 10.0
const CAR_STEER_SPEED: float = 2.6

# Camera & Input State
var is_first_person: bool = false
var camera_rot_x: float = 0.0
var mouse_captured: bool = true
var is_cycling: bool = true
var cycle_bob_timer: float = 0.0
var cycle_tilt: float = 0.0

# Interaction Flags
var can_dismount: bool = false
var is_near_door: bool = false
var is_near_car: bool = false
var can_reenter_car: bool = false
var is_near_police_door: bool = false
var door_opened: bool = false
var cutscene_active: bool = false
var is_town_map_open: bool = false
var dialogue_in_progress: bool = false
var dialogue_index: int = 0
var can_advance_dialogue: bool = false
var intro_cam_tw: Tween = null

# Weather & Atmosphere Timers
var lightning_timer: float = 3.5
var is_lightning_flashing: bool = false
var pulse_time: float = 0.0
var radar_update_timer: float = 0.0
var car_cooldown_timer: float = 0.0
var _last_interaction_frame: int = -1

# Preloaded Audio
var stream_cycle_riding: AudioStream = preload("res://audio/cycle_riding.wav")
var stream_cycle_bell: AudioStream = preload("res://audio/cycle_bell.wav")
var stream_thunder_strike: AudioStream = preload("res://audio/thunder_strike.wav")
var stream_thunder_distant: AudioStream = preload("res://audio/thunder_distant.wav")
var stream_storm_ambience: AudioStream = preload("res://audio/storm_rain_wind.wav")

# Dialogues with Kripal's Mother
var stream_mummy_1: AudioStream = preload("res://audio/mummy_line_1.mp3")
var stream_player_talk: AudioStream = preload("res://audio/player_talk_mummy.mp3")
var stream_sahil_talk: AudioStream = preload("res://audio/sahil_talk_mummy.mp3")
var stream_aashu_talk: AudioStream = preload("res://audio/aashu_talk_mummy.mp3")
var stream_mummy_crying: AudioStream = preload("res://audio/mummy_crying.mp3")
var stream_player_comfort: AudioStream = preload("res://audio/player_comfort_mummy.mp3")
var stream_sahil_police: AudioStream = preload("res://audio/sahil_police_plan.mp3")

# Landmarks
var landmarks = {
	"school": {"name": "सेंट ऑगस्टीन स्कूल", "pos": Vector3(0, 0, 16), "color": Color(0.9, 0.7, 0.2)},
	"sahil_home": {"name": "साहिल निवास", "pos": Vector3(-11.0, 0, -22), "color": Color(1.0, 0.75, 0.2)},
	"player_home": {"name": "मेरा घर", "pos": Vector3(11.0, 0, -42), "color": Color(0.3, 0.9, 0.4)},
	"aashu_home": {"name": "आशुतोष निवास", "pos": Vector3(-11.0, 0, -62), "color": Color(0.85, 0.45, 1.0)},
	"kripal": {"name": "कृपाल निवास", "pos": Vector3(9.0, 0, -85), "color": Color(1.0, 0.25, 0.25)},
	"police": {"name": "पानसेमल पुलिस थाना", "pos": Vector3(11.5, 0, -235), "color": Color(0.2, 0.5, 1.0)}
}

var dialogues = [
	{
		"speaker": "👩 कृपाल की माँ (KRIPAL'S MOTHER)",
		"color": Color(1.0, 0.45, 0.65),
		"text": "अरे साहिल, आशुतोष? तुम दोनों इतनी रात को यहाँ? और कृपाल कहाँ है? वो तो तुम लोगों के साथ ही था ना स्कूल में?",
		"audio": null
	},
	{
		"speaker": "🎒 तू (PLAYER)",
		"color": Color(0.4, 0.9, 1.0),
		"text": "आंटी... स्कूल की छुट्टी के बाद जब हम बाहर जाने लगे, तब क्लासरूम में अचानक लाइट चली गई और बहुत अजीब आवाज़ें आईं...",
		"audio": null
	},
	{
		"speaker": "🧢 साहिल (SAHIL)",
		"color": Color(1.0, 0.35, 0.35),
		"text": "हाँ आंटी, लाइट आने पर कृपाल अपनी डेस्क से गायब था! और उसकी डेस्क पर खून से सनी एक पर्ची मिली...",
		"audio": null
	},
	{
		"speaker": "👓 आशुतोष (AASHUTOSH)",
		"color": Color(0.5, 0.7, 1.0),
		"text": "उस पर्ची पर लिखा था — 'FIND ME AT BHANGARH'... आंटी, क्या कृपाल ने कभी भानगढ़ के बारे में कुछ बताया था?",
		"audio": null
	},
	{
		"speaker": "👩 कृपाल की माँ (KRIPAL'S MOTHER) 😭 [रोते हुए]",
		"color": Color(1.0, 0.45, 0.65),
		"text": "हे भगवान! भानगढ़?! नहीं... वो पुराना तांत्रिक का श्राप! कृपाल के दादाजी हमेशा कहते थे कि हमारे परिवार पर किसी काले साये की नज़र है! बच्चों, तुम्हें कृपाल को बचाना होगा! मैं तुम्हें भानगढ़ का पुराना नक्शा और ताबीज देती हूँ!",
		"audio": null
	},
	{
		"speaker": "🎒 तू (PLAYER)",
		"color": Color(0.4, 0.9, 1.0),
		"text": "आंटी, आप रोइए मत! हम कृपाल को कुछ नहीं होने देंगे। चलिए, हम अभी पानसेमल पुलिस स्टेशन चलते हैं और कम्प्लेन लिखाते हैं!",
		"audio": null
	},
	{
		"speaker": "🧢 साहिल (SAHIL)",
		"color": Color(1.0, 0.35, 0.35),
		"text": "हाँ आंटी, बाहर कृपाल की गाड़ी खड़ी है! चलिए सब गाड़ी में बैठिए, हम अभी सीधे पुलिस थाने चलते हैं!",
		"audio": null
	}
]

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not InputMap.has_action("exit_car"):
		InputMap.add_action("exit_car")
	_set_checkpoint_control_mode("adventure")
	
	dialogues[0]["audio"] = stream_mummy_1
	dialogues[1]["audio"] = stream_player_talk
	dialogues[2]["audio"] = stream_sahil_talk
	dialogues[3]["audio"] = stream_aashu_talk
	dialogues[4]["audio"] = stream_mummy_crying
	dialogues[5]["audio"] = stream_player_comfort
	dialogues[6]["audio"] = stream_sahil_police
	
	update_camera_mode()
	if player:
		player.floor_snap_length = 0.5
		player.floor_max_angle = deg_to_rad(45.0)
	
	if ambience_audio and stream_storm_ambience:
		ambience_audio.stream = stream_storm_ambience
		ambience_audio.volume_db = -4.0
		ambience_audio.play()
		
	if view_toggle_btn:
		view_toggle_btn.pressed.connect(toggle_camera_mode)
	if map_toggle_btn:
		map_toggle_btn.pressed.connect(toggle_town_map)
	if close_map_btn:
		close_map_btn.pressed.connect(toggle_town_map)
	if start_police_btn:
		start_police_btn.pressed.connect(_on_start_police_pressed)
	if replay_btn:
		replay_btn.pressed.connect(_on_replay_street_pressed)
		
	if radar_display:
		radar_display.draw.connect(_on_radar_draw)
	if map_canvas:
		map_canvas.draw.connect(_on_map_canvas_draw)
		
	if door_trigger:
		door_trigger.body_entered.connect(_on_door_trigger_entered)
		door_trigger.body_exited.connect(_on_door_trigger_exited)
	if police_door_trigger:
		police_door_trigger.body_entered.connect(_on_police_trigger_entered)
		police_door_trigger.body_exited.connect(_on_police_trigger_exited)
	if car_trigger:
		car_trigger.body_entered.connect(_on_car_trigger_entered)
		car_trigger.body_exited.connect(_on_car_trigger_exited)
	if kripal_car:
		kripal_car.floor_snap_length = 0.5
		kripal_car.floor_max_angle = deg_to_rad(45.0)
		kripal_car.floor_constant_speed = true
		kripal_car.max_slides = 4
		
	if dialogue_box: dialogue_box.visible = false
	if next_chapter_card: next_chapter_card.visible = false
	if prompt_label: prompt_label.visible = false
	if kripal_mummy: kripal_mummy.visible = false
	if action_prompt: action_prompt.visible = false
	if parked_bicycles: parked_bicycles.visible = false
	if gps_arrows: gps_arrows.visible = false
	
	_set_checkpoint_control_mode("adventure")
	_save_default_limb_transforms()
	_setup_cinematic_graphics()
	_enhance_street_buildings()
	
	start_school_exit_intro()

func _save_default_limb_transforms() -> void:
	var nodes_to_save = [
		p_arms_node, p_legs_node, p_leg_l_thigh, p_leg_l_shin, p_boot_l_base, p_boot_l_sole,
		p_leg_r_thigh, p_leg_r_shin, p_boot_r_base, p_boot_r_sole,
		s_arms_node, s_legs_node, s_leg_l_thigh, s_leg_l_shin, s_boot_l_base, s_boot_l_sole,
		s_leg_r_thigh, s_leg_r_shin, s_boot_r_base, s_boot_r_sole,
		a_arms_node, a_legs_node, a_leg_l_thigh, a_leg_l_shin, a_boot_l_base, a_boot_l_sole,
		a_leg_r_thigh, a_leg_r_shin, a_boot_r_base, a_boot_r_sole
	]
	for node in nodes_to_save:
		if node and is_instance_valid(node):
			default_limb_transforms[node] = {
				"pos": node.position,
				"rot": node.rotation
			}

func _restore_default_limb_transforms() -> void:
	for node in default_limb_transforms:
		if is_instance_valid(node):
			node.position = default_limb_transforms[node]["pos"]
			node.rotation = default_limb_transforms[node]["rot"]

func _animate_rider_limbs(
	arms_node: Node3D,
	leg_l_thigh: Node3D, leg_l_shin: Node3D, boot_l_base: Node3D, boot_l_sole: Node3D,
	leg_r_thigh: Node3D, leg_r_shin: Node3D, boot_r_base: Node3D, boot_r_sole: Node3D,
	front_wheel: Node3D, rear_wheel: Node3D,
	phase: float, forward_speed: float, delta: float, steering: float
) -> void:
	# 1. Hands gripping handlebar forward realistically
	if arms_node:
		arms_node.rotation.x = deg_to_rad(-42.0)
		arms_node.rotation.z = -steering * 0.08
		arms_node.position.z = 0.06
		arms_node.position.y = -0.02
		
	# 2. Left Leg (phase)
	var left_pedal_y = cos(phase)
	var left_pedal_z = sin(phase)
	if leg_l_thigh:
		leg_l_thigh.rotation.x = -0.52 + left_pedal_z * 0.38
		leg_l_thigh.position.y = 0.52 + left_pedal_y * 0.04
		leg_l_thigh.position.z = left_pedal_z * 0.04
	if leg_l_shin:
		leg_l_shin.rotation.x = 0.42 + left_pedal_y * 0.28
		leg_l_shin.position.y = 0.22 + left_pedal_y * 0.08
		leg_l_shin.position.z = 0.06 + left_pedal_z * 0.10
	if boot_l_base:
		boot_l_base.position.y = 0.08 + left_pedal_y * 0.11
		boot_l_base.position.z = 0.04 + left_pedal_z * 0.13
		boot_l_base.rotation.x = -left_pedal_z * 0.15
	if boot_l_sole:
		boot_l_sole.position.y = 0.025 + left_pedal_y * 0.11
		boot_l_sole.position.z = 0.04 + left_pedal_z * 0.13
		boot_l_sole.rotation.x = -left_pedal_z * 0.15

	# 3. Right Leg (phase + PI)
	var right_phase = phase + PI
	var right_pedal_y = cos(right_phase)
	var right_pedal_z = sin(right_phase)
	if leg_r_thigh:
		leg_r_thigh.rotation.x = -0.52 + right_pedal_z * 0.38
		leg_r_thigh.position.y = 0.52 + right_pedal_y * 0.04
		leg_r_thigh.position.z = right_pedal_z * 0.04
	if leg_r_shin:
		leg_r_shin.rotation.x = 0.42 + right_pedal_y * 0.28
		leg_r_shin.position.y = 0.22 + right_pedal_y * 0.08
		leg_r_shin.position.z = 0.06 + right_pedal_z * 0.10
	if boot_r_base:
		boot_r_base.position.y = 0.08 + right_pedal_y * 0.11
		boot_r_base.position.z = 0.04 + right_pedal_z * 0.13
		boot_r_base.rotation.x = -right_pedal_z * 0.15
	if boot_r_sole:
		boot_r_sole.position.y = 0.025 + right_pedal_y * 0.11
		boot_r_sole.position.z = 0.04 + right_pedal_z * 0.13
		boot_r_sole.rotation.x = -right_pedal_z * 0.15

	# 4. Wheel spinning with road movement
	var roll_speed = (forward_speed / 0.36) * delta
	if front_wheel and roll_speed != 0.0:
		front_wheel.rotate_y(roll_speed)
	if rear_wheel and roll_speed != 0.0:
		rear_wheel.rotate_y(roll_speed)

func start_school_exit_intro() -> void:
	cutscene_active = true
	camera.position = Vector3(0, 1.35, -4.6)
	camera.rotation_degrees = Vector3(-6.0, 180.0, 0.0)
	
	# Position all 3 friends side-by-side on their bicycles under school gate
	if sahil:
		sahil.visible = true
		sahil.global_position = player.global_position + Vector3(-1.6, 0.0, 0.5)
		sahil.rotation.y = player.rotation.y
		if sahil_cycle: sahil_cycle.visible = true
	if aashutosh:
		aashutosh.visible = true
		aashutosh.global_position = player.global_position + Vector3(1.6, 0.0, 0.5)
		aashutosh.rotation.y = player.rotation.y
		if aashu_cycle: aashu_cycle.visible = true
	if player_cycle:
		player_cycle.visible = true
	if visual_model:
		visual_model.rotation.y = PI
		visual_model.rotation.z = 0.0
	
	show_subtitle("⛈️ [तूफान, बारिश और बादलों की गर्जना]... सेंट ऑगस्टीन स्कूल से बाहर निकलते हुए...", 3.2)
	trigger_lightning(true)
	
	await get_tree().create_timer(1.8).timeout
	if not cutscene_active: return
	show_subtitle("🧢 साहिल: 'मौसम बहुत खराब हो रहा है! तेज साइकिल चलाओ, कृपाल के घर पहुँचना है!'", 2.8)
	
	await get_tree().create_timer(2.4).timeout
	if not cutscene_active: return
	intro_cam_tw = create_tween()
	intro_cam_tw.tween_property(camera, "position", Vector3(0, 0.75, 3.4), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	intro_cam_tw.tween_property(camera, "rotation_degrees", Vector3.ZERO, 1.4).set_trans(Tween.TRANS_QUAD)
	
	await intro_cam_tw.finished
	if not cutscene_active: return
	cutscene_active = false
	objective_banner.text = "✦ MISSION: RIDE BICYCLE IN THUNDERSTORM TO KRIPAL'S HOUSE [WASD / TOUCH]"

func skip_school_exit_intro() -> void:
	if not cutscene_active: return
	cutscene_active = false
	if intro_cam_tw and intro_cam_tw.is_valid():
		intro_cam_tw.kill()
	camera.position = Vector3(0, 0.75, 3.4)
	camera.rotation_degrees = Vector3.ZERO
	if visual_model:
		visual_model.rotation.y = PI
		visual_model.rotation.z = 0.0
	if objective_banner:
		objective_banner.text = "✦ MISSION: RIDE BICYCLE IN THUNDERSTORM TO KRIPAL'S HOUSE [WASD / TOUCH]"
	show_subtitle("🚲 तूफ़ानी शाम में कृपाल के घर की तरफ साइकिल चलाओ!", 2.5)

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and not is_town_map_open:
		if not cutscene_active and current_mode != PlayerMode.DRIVING_CAR:
			player.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
			camera_rot_x -= event.relative.y * MOUSE_SENSITIVITY
			camera_rot_x = clamp(camera_rot_x, -deg_to_rad(75), deg_to_rad(75))
			camera_pivot.rotation.x = camera_rot_x

	if (event is InputEventKey and event.pressed and not event.echo) or event.is_action_pressed("interact") or event.is_action_pressed("exit_car") or event.is_action_pressed("flashlight"):
		if event is InputEventKey and event.keycode == KEY_M:
			toggle_town_map()
			get_viewport().set_input_as_handled()
		elif (event is InputEventKey and event.keycode == KEY_V):
			toggle_camera_mode()
			get_viewport().set_input_as_handled()
		elif (event is InputEventKey and event.keycode == KEY_B) and current_mode == PlayerMode.CYCLING and not cutscene_active:
			ring_cycle_bell()
			get_viewport().set_input_as_handled()
		elif (event.is_action_pressed("exit_car") or (event is InputEventKey and event.keycode == KEY_BACKSPACE)) and current_mode == PlayerMode.DRIVING_CAR:
			if car_cooldown_timer <= 0.0:
				exit_car()
			get_viewport().set_input_as_handled()
		elif (event is InputEventKey and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or event.is_action_pressed("interact"):
			handle_interaction()
			get_viewport().set_input_as_handled()

	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		if cutscene_active:
			skip_school_exit_intro()
		elif dialogue_in_progress and can_advance_dialogue:
			advance_dialogue()

func handle_interaction() -> void:
	var cur_frame = Engine.get_process_frames()
	if cur_frame == _last_interaction_frame:
		return
	_last_interaction_frame = cur_frame

	if cutscene_active:
		skip_school_exit_intro()
		return
		
	if dialogue_in_progress and can_advance_dialogue:
		advance_dialogue()
		return

	# MODE 1: CYCLING
	if current_mode == PlayerMode.CYCLING:
		# Dismount when approaching or at Kripal's house
		if can_dismount or player.global_position.z <= -68.0:
			dismount_bicycle()
		else:
			ring_cycle_bell()
		return

	# MODE 2: FOOT AT KRIPAL'S HOUSE
	elif current_mode == PlayerMode.FOOT_KRIPAL:
		var dist_to_door: float = player.global_position.distance_to(Vector3(9.0, 0.5, -85.0))
		var dist_to_car: float = player.global_position.distance_to(kripal_car.global_position) if kripal_car else 999.0
		if not door_opened:
			if is_near_door or dist_to_door < 4.5:
				start_door_interaction()
			else:
				show_subtitle("🚶 कृपाल के घर के मुख्य दरवाजे के पास जाकर घंटी [E] बजाएं", 2.0)
		else:
			if (is_near_car or dist_to_car < 6.5) and car_cooldown_timer <= 0.0:
				enter_car()
			elif is_near_door or dist_to_door < 4.0:
				show_subtitle("👩 कृपाल की माँ: 'बेटा, बाहर गाड़ी खड़ी है, जल्दी उसमें बैठो!'", 2.5)
			else:
				show_subtitle("🚗 सामने खड़ी कृपाल की गाड़ी के पास जाकर [E] दबाएं", 2.0)
		return

	# MODE 3: DRIVING CAR
	elif current_mode == PlayerMode.DRIVING_CAR:
		# In driving car mode, [E] only exits when vehicle has arrived at destination (police station) and stopped!
		if car_cooldown_timer <= 0.0 and abs(car_speed) < 1.0:
			var dist_to_police = abs(kripal_car.global_position.z - (-235.0)) if kripal_car else 999.0
			if dist_to_police < 25.0 or kripal_car.global_position.z <= -215.0:
				exit_car()
			else:
				show_subtitle("🚗 पुलिस स्टेशन पहुँचने के लिए सड़क पर चमकते तीरों का पीछा करें!", 2.0)
		return

	# MODE 4: FOOT AT POLICE STATION OR ROAD
	elif current_mode == PlayerMode.FOOT_POLICE:
		var dist_to_police: float = player.global_position.distance_to(Vector3(11.5, 0, -235.0))
		var dist_to_car: float = player.global_position.distance_to(kripal_car.global_position) if kripal_car else 999.0
		
		# Prioritize entering the police station
		if is_near_police_door or dist_to_police < 5.5:
			_on_start_police_pressed()
			return
		# Only allow re-entering car if player stepped far away (>4.5m) first, returned close (<2.5m), and cooldown finished!
		elif can_reenter_car and car_cooldown_timer <= 0.0 and (is_near_car or dist_to_car < 2.5):
			enter_car()
			return
		else:
			if dist_to_police < 15.0:
				show_subtitle("🚪 पुलिस थाने के मुख्य द्वार के पास जाकर [E] दबाएं", 2.0)
			else:
				show_subtitle("🚪 पुलिस थाने के मुख्य द्वार की तरफ बढ़ें", 2.0)
			return

func dismount_bicycle() -> void:
	current_mode = PlayerMode.FOOT_KRIPAL
	is_cycling = false
	can_dismount = false
	_restore_default_limb_transforms()
	if action_prompt: action_prompt.visible = false

	# Hide riding cycle meshes on player and companions
	if player_cycle: player_cycle.visible = false
	if sahil_cycle: sahil_cycle.visible = false
	if aashu_cycle: aashu_cycle.visible = false

	# Reset visual models to ground standing position
	if visual_model:
		visual_model.position = Vector3.ZERO
		visual_model.rotation = Vector3(0, PI, 0)
	if sahil and sahil.has_node("VisualModel"): sahil.get_node("VisualModel").position = Vector3.ZERO
	if aashutosh and aashutosh.has_node("VisualModel"): aashutosh.get_node("VisualModel").position = Vector3.ZERO

	# Spawn parked bicycles beside the road
	if parked_bicycles:
		parked_bicycles.visible = true
		parked_bicycles.global_position = player.global_position + Vector3(1.2, 0, 0)

	objective_banner.text = "✦ कृपाल के घर के सामने पहुँच गए! सामने वाले दरवाजे की घंटी [E] बजाएं"
	show_subtitle("🚲 [साइकिल पार्क की]... सामने कृपाल का घर है, दरवाजे पर जाएँ और डोरबेल बजाएं!", 3.5)

func ring_cycle_bell() -> void:
	if bell_audio and stream_cycle_bell:
		bell_audio.pitch_scale = randf_range(0.96, 1.04)
		bell_audio.play()
	show_subtitle("🔔 [साइकिल की घंटी: ट्रिन-ट्रिन!]", 1.2)

func _process(delta: float) -> void:
	lightning_timer -= delta
	if lightning_timer <= 0.0 and not is_lightning_flashing:
		lightning_timer = randf_range(4.5, 9.0)
		var is_close: bool = (randf() < 0.4)
		trigger_lightning(is_close)

func trigger_lightning(is_close: bool = false) -> void:
	if is_lightning_flashing: return
	is_lightning_flashing = true
	
	if thunder_audio:
		thunder_audio.stream = stream_thunder_strike if is_close else stream_thunder_distant
		thunder_audio.pitch_scale = randf_range(0.9, 1.1)
		thunder_audio.volume_db = 4.0 if is_close else 0.0
		thunder_audio.play()
		
	var max_energy: float = 9.5 if is_close else 5.0
	var flash_alpha: float = 0.50 if is_close else 0.25
	
	var tw = create_tween()
	if lightning_light:
		tw.tween_property(lightning_light, "light_energy", max_energy, 0.05)
		tw.tween_property(lightning_light, "light_energy", max_energy * 0.3, 0.04)
		tw.tween_property(lightning_light, "light_energy", max_energy * 1.1, 0.08)
		tw.tween_property(lightning_light, "light_energy", 0.0, 0.4).set_ease(Tween.EASE_OUT)
		
	var tw_ui = create_tween()
	if lightning_flash_ui:
		tw_ui.tween_property(lightning_flash_ui, "color:a", flash_alpha, 0.05)
		tw_ui.tween_property(lightning_flash_ui, "color:a", 0.08, 0.04)
		tw_ui.tween_property(lightning_flash_ui, "color:a", flash_alpha * 0.8, 0.08)
		tw_ui.tween_property(lightning_flash_ui, "color:a", 0.0, 0.45).set_ease(Tween.EASE_OUT)
		
	if is_close and camera and not cutscene_active and current_mode != PlayerMode.DRIVING_CAR:
		var base_y = camera.position.y
		var cam_tw = create_tween()
		cam_tw.tween_property(camera, "position:y", base_y + 0.08, 0.04)
		cam_tw.tween_property(camera, "position:y", base_y - 0.06, 0.04)
		cam_tw.tween_property(camera, "position:y", base_y, 0.08)
		
	await tw.finished
	is_lightning_flashing = false

func _physics_process(delta: float) -> void:
	pulse_time += delta
	if car_cooldown_timer > 0.0:
		car_cooldown_timer -= delta
	# Safety Floor Clamping - Permanently prevents falling through ground into void
	if player and player.global_position.y < -0.10:
		player.global_position.y = 0.05
		player.velocity.y = 0.0
	if kripal_car and (current_mode == PlayerMode.DRIVING_CAR or kripal_car.global_position.y < -0.10 or kripal_car.global_position.y > 0.8):
		kripal_car.global_position.y = 0.35
		kripal_car.velocity.y = 0.0
		kripal_car.rotation.x = 0.0
		kripal_car.rotation.z = 0.0

	_process_pedestrians(delta)
	
	radar_update_timer += delta
	if radar_update_timer >= 0.1:
		radar_update_timer = 0.0
		_update_radar_hud()
	
	# Police beacon flashing lights
	if police_light_red and police_light_blue:
		var flash = sin(pulse_time * 8.0)
		police_light_red.light_energy = 5.0 if flash > 0 else 0.5
		police_light_blue.light_energy = 5.0 if flash <= 0 else 0.5
		
	if cutscene_active or is_town_map_open:
		if not player.is_on_floor():
			player.velocity.y -= gravity * delta
			player.move_and_slide()
		if cycle_audio and cycle_audio.playing: cycle_audio.stop()
		return
		
	# Catch interact action in physics process as backup for mobile touch
	if Input.is_action_just_pressed("interact"):
		handle_interaction()

	# MODE 1: CYCLING
	if current_mode == PlayerMode.CYCLING:
		var dist_to_kripal: int = int(abs(player.global_position.z - (-85.0)))
		# Check if approaching Kripal's house to show dismount option
		if player.global_position.z <= -68.0:
			can_dismount = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚲 [E] / ACTION दबाकर साइकिल से उतरें (PRESS [E] TO DISMOUNT BICYCLE)"
			if objective_banner:
				objective_banner.text = "🏠 KRIPAL'S HOUSE REACHED! PRESS [E] TO DISMOUNT & GO TO FRONT DOOR"
		else:
			if objective_banner:
				objective_banner.text = "🚲 RIDE BICYCLE TO KRIPAL'S RESIDENCE [DISTANCE: %d M] — FOLLOW GOLDEN BEACON" % dist_to_kripal
				
		_handle_cycling_movement(delta)
		
	# MODE 2: FOOT AT KRIPAL HOUSE
	elif current_mode == PlayerMode.FOOT_KRIPAL:
		_handle_foot_movement(delta)
		_update_walking_companions(delta)
		
		var dist_to_door: float = player.global_position.distance_to(Vector3(9.0, 0.5, -85.0))
		var dist_to_car: float = player.global_position.distance_to(kripal_car.global_position) if kripal_car else 999.0
		
		if (is_near_door or dist_to_door < 4.5) and not door_opened:
			is_near_door = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🔔 [E] दबाकर डोरबेल बजाएं (PRESS [E] TO RING DOORBELL)"
		elif (is_near_car or dist_to_car < 6.5) and door_opened:
			is_near_car = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚗 [E] / ACTION दबाकर कार में बैठें और चलाएं (PRESS [E] TO DRIVE CAR)"
		else:
			if dist_to_door >= 4.5: is_near_door = false
			if dist_to_car >= 7.0: is_near_car = false
			if action_prompt and not can_advance_dialogue:
				if not door_opened:
					action_prompt.visible = true
					action_prompt.text = "🚶 कृपाल के घर के दरवाजे की तरफ बढ़ें और घंटी बजाएं [E]"
				else:
					action_prompt.visible = true
					action_prompt.text = "🚗 सामने खड़ी कार की तरफ बढ़ें और [E] दबाएं"
				
	# MODE 3: DRIVING CAR
	elif current_mode == PlayerMode.DRIVING_CAR:
		_handle_car_driving(delta)
		
	# MODE 4: FOOT AT POLICE STATION
	elif current_mode == PlayerMode.FOOT_POLICE:
		_handle_foot_movement(delta)
		_update_walking_companions(delta)
		
		var dist_to_police = player.global_position.distance_to(Vector3(11.5, 0, -235.0))
		var dist_to_car: float = player.global_position.distance_to(kripal_car.global_position) if kripal_car else 999.0
		
		# Player must walk far away from the car (> 4.5m) to unlock re-entering
		if dist_to_car > 4.5:
			can_reenter_car = true
		
		if is_near_police_door or dist_to_police < 5.5:
			is_near_police_door = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚪 [E] दबाकर थाने में प्रवेश करें (PRESS [E] TO ENTER POLICE STATION)"
		elif can_reenter_car and (is_near_car or dist_to_car < 2.5):
			is_near_car = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚗 [E] / ACTION दबाकर वापस कार में बैठें (ENTER CAR)"
		else:
			if dist_to_car >= 2.5 or not can_reenter_car:
				is_near_car = false
			if dist_to_police >= 5.5:
				is_near_police_door = false
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚶 पुलिस थाने के मुख्य द्वार की तरफ बढ़ें (WALK TOWARDS POLICE ENTRANCE)"

func _handle_cycling_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir == Vector2.ZERO:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("move_forward") or Input.is_action_pressed("ui_up"): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("move_backward") or Input.is_action_pressed("ui_down"): input_dir.y += 1.0
	input_dir = input_dir.normalized()
	
	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint")
	var max_speed: float = SPRINT_CYCLE_SPEED if is_sprinting else CYCLE_SPEED
	var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0.0
		
	if direction != Vector3.ZERO:
		player.velocity.x = move_toward(player.velocity.x, direction.x * max_speed, ACCEL * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * max_speed, ACCEL * delta)
		
		if cycle_audio:
			if not cycle_audio.playing: cycle_audio.play()
			cycle_audio.pitch_scale = lerp(0.85, 1.45, player.velocity.length() / SPRINT_CYCLE_SPEED)
			
		cycle_bob_timer += delta * (16.0 if is_sprinting else 10.0)
		var target_tilt = -input_dir.x * 0.14
		cycle_tilt = lerp(cycle_tilt, target_tilt, 8.0 * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, ACCEL * 1.8 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, ACCEL * 1.8 * delta)
		cycle_tilt = lerp(cycle_tilt, 0.0, 6.0 * delta)
		if cycle_audio and cycle_audio.playing: cycle_audio.stop()
		
	player.move_and_slide()
	
	# Procedural Realistic Rider & Limb Animations (Hands gripping handlebar, legs pedaling rhythmically, wheels spinning)
	var forward_speed = player.velocity.length()
	if forward_speed > 0.15:
		pedal_phase += delta * forward_speed * 1.8
		
	# Animate Player (Arms holding grips, legs pedaling)
	_animate_rider_limbs(
		p_arms_node,
		p_leg_l_thigh, p_leg_l_shin, p_boot_l_base, p_boot_l_sole,
		p_leg_r_thigh, p_leg_r_shin, p_boot_r_base, p_boot_r_sole,
		p_front_wheel, p_rear_wheel,
		pedal_phase, forward_speed, delta, input_dir.x
	)
	
	# Natural rider body tilt into turns (preserve forward PI orientation)
	if visual_model:
		visual_model.rotation.z = cycle_tilt * 0.8
		visual_model.rotation.y = PI - input_dir.x * 0.08
	
	# Animate Sahil companion limbs & wheels
	_animate_rider_limbs(
		s_arms_node,
		s_leg_l_thigh, s_leg_l_shin, s_boot_l_base, s_boot_l_sole,
		s_leg_r_thigh, s_leg_r_shin, s_boot_r_base, s_boot_r_sole,
		s_front_wheel, s_rear_wheel,
		pedal_phase + 0.45, forward_speed, delta, 0.0
	)
	
	# Animate Aashutosh companion limbs & wheels
	_animate_rider_limbs(
		a_arms_node,
		a_leg_l_thigh, a_leg_l_shin, a_boot_l_base, a_boot_l_sole,
		a_leg_r_thigh, a_leg_r_shin, a_boot_r_base, a_boot_r_sole,
		a_front_wheel, a_rear_wheel,
		pedal_phase + 0.90, forward_speed, delta, 0.0
	)
	
	_update_companions(delta, direction)

func _handle_foot_movement(delta: float) -> void:
	if cycle_audio and cycle_audio.playing: cycle_audio.stop()
	
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir == Vector2.ZERO:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("move_forward") or Input.is_action_pressed("ui_up"): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("move_backward") or Input.is_action_pressed("ui_down"): input_dir.y += 1.0
	input_dir = input_dir.normalized()
	
	var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0.0
		
	var is_sprint: bool = Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint")
	var foot_speed: float = 6.0 if is_sprint else WALK_SPEED
	if direction != Vector3.ZERO:
		player.velocity.x = direction.x * foot_speed
		player.velocity.z = direction.z * foot_speed
		if footstep_audio and not footstep_audio.playing:
			footstep_audio.pitch_scale = randf_range(0.9, 1.1)
			footstep_audio.play()
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, ACCEL * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, ACCEL * delta)
		
	player.move_and_slide()

func _handle_car_driving(delta: float) -> void:
	var forward_input: float = 0.0
	var steer_input: float = 0.0
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_forward"):
		forward_input += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_backward"):
		forward_input -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		steer_input += 1.0   # Turn Left
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		steer_input -= 1.0   # Turn Right
		
	# Accelerate forward or reverse/brake
	if forward_input > 0:
		if car_speed < -0.1:
			car_speed = move_toward(car_speed, 0.0, CAR_ACCEL * 3.0 * delta)
		else:
			car_speed = move_toward(car_speed, CAR_MAX_SPEED, CAR_ACCEL * 1.5 * delta)
	elif forward_input < 0:
		if car_speed > 0.5:
			car_speed = move_toward(car_speed, 0.0, CAR_ACCEL * 3.0 * delta)
		else:
			car_speed = move_toward(car_speed, -CAR_MAX_SPEED * 0.5, CAR_ACCEL * 1.5 * delta)
	else:
		car_speed = move_toward(car_speed, 0.0, CAR_ACCEL * 1.0 * delta)
		
	# Steer car: allow steering whenever A or D is pressed (both stationary & moving)
	if steer_input != 0.0:
		var dir_factor: float = -1.0 if car_speed < -0.1 else 1.0
		var turn_rate: float = CAR_STEER_SPEED * 1.2
		if abs(car_speed) < 0.5 and forward_input == 0:
			turn_rate *= 0.8
		kripal_car.rotate_y(steer_input * turn_rate * delta * dir_factor)
		
	# Lock pitch and roll so car never tilts up or rolls over
	kripal_car.rotation.x = 0.0
	kripal_car.rotation.z = 0.0
	
	# Forward velocity along car facing direction
	var car_fwd: Vector3 = kripal_car.transform.basis.z.normalized()
	var target_velocity: Vector3 = car_fwd * car_speed
	target_velocity.y = 0.0
	kripal_car.velocity = target_velocity
	kripal_car.move_and_slide()
	
	# Keep car firmly grounded on the road surface
	kripal_car.global_position.y = 0.35
	kripal_car.velocity.y = 0.0
	kripal_car.rotation.x = 0.0
	kripal_car.rotation.z = 0.0
	
	# Sync player position with car
	player.global_position = kripal_car.global_position
	
	# Engine audio modulation
	if car_engine_audio:
		car_engine_audio.pitch_scale = lerp(0.85, 1.6, abs(car_speed) / CAR_MAX_SPEED)
		
	# Dynamic GPS HUD Route & Distance indicator
	var dist_to_police: int = int(abs(kripal_car.global_position.z - (-235.0)))
	if objective_banner:
		if kripal_car.global_position.z > -205.0:
			objective_banner.text = "🧭 GPS ROUTE: ⬆️ GO STRAIGHT DOWN MAIN ROAD [POLICE STATION: %d M]" % dist_to_police
		elif kripal_car.global_position.z > -228.0:
			objective_banner.text = "🧭 GPS ROUTE: ➡️ SLOW DOWN & TURN RIGHT INTO POLICE COMPOUND [DISTANCE: %d M]" % dist_to_police
		else:
			objective_banner.text = "🎯 ARRIVED AT POLICE STATION! PRESS [EXIT CAR] OR [E] TO EXIT"
		
	# Action prompt update
	if action_prompt:
		action_prompt.visible = true
		if kripal_car.global_position.z <= -215.0:
			action_prompt.text = "🚗 [EXIT CAR] या [E] दबाकर कार से उतरें (PRESS [EXIT CAR] OR [E] TO EXIT)"
		else:
			action_prompt.text = "🚗 [GAS] ACCEL | [BRAKE] REV | [STEER L/R] TURN | [EXIT CAR] LEAVE"

func enter_car() -> void:
	if current_mode == PlayerMode.DRIVING_CAR:
		return
	if car_cooldown_timer > 0.0:
		return
	current_mode = PlayerMode.DRIVING_CAR
	car_cooldown_timer = 2.5
	can_reenter_car = false
	is_near_car = false
	_set_checkpoint_control_mode("vehicle")
	if action_prompt: action_prompt.text = "🚗 [GAS] ACCEL | [BRAKE] REV | [STEER L/R] TURN | [EXIT CAR] LEAVE"
	
	# Disable player and companion collisions completely to eliminate physics blockage
	if player_collision:
		player_collision.set_deferred("disabled", true)
	if player:
		player.collision_layer = 0
		player.collision_mask = 0
		player.velocity = Vector3.ZERO
	if visual_model:
		visual_model.visible = false
	if sahil:
		sahil.collision_layer = 0
		sahil.collision_mask = 0
		sahil.velocity = Vector3.ZERO
		sahil.visible = false
		var scol = sahil.get_node_or_null("CollisionShape3D")
		if scol: scol.set_deferred("disabled", true)
	if aashutosh:
		aashutosh.collision_layer = 0
		aashutosh.collision_mask = 0
		aashutosh.velocity = Vector3.ZERO
		aashutosh.visible = false
		var acol = aashutosh.get_node_or_null("CollisionShape3D")
		if acol: acol.set_deferred("disabled", true)
	if kripal_mummy:
		kripal_mummy.collision_layer = 0
		kripal_mummy.collision_mask = 0
		kripal_mummy.velocity = Vector3.ZERO
		kripal_mummy.visible = false
		var mummy_col = kripal_mummy.get_node_or_null("CollisionShape3D")
		if mummy_col:
			mummy_col.set_deferred("disabled", true)
		
	# Setup car physics and ground firmly
	if kripal_car:
		kripal_car.collision_mask = 1 # Only collide with world environment, never companions
		kripal_car.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		kripal_car.global_position.y = 0.35
		kripal_car.velocity = Vector3.ZERO
		kripal_car.rotation.x = 0.0
		kripal_car.rotation.z = 0.0
	car_speed = 0.0
	
	# Switch to car chase camera immediately
	if car_camera: car_camera.make_current()
	
	# Show GPS navigation road arrows
	if gps_arrows: gps_arrows.visible = true
	
	if car_door_open_audio: car_door_open_audio.play()
	if car_door_close_audio: car_door_close_audio.play()
	if car_start_audio: car_start_audio.play()
	if car_engine_audio: car_engine_audio.play()
	
	objective_banner.text = "✦ GPS NAVIGATION: FOLLOW GLOWING ROAD ARROWS TO PANSEMAL POLICE STATION"
	show_subtitle("🚗 [कार स्टार्ट हुई]... सड़क पर चमकते तीरों (GPS ARROWS) का पीछा करते हुए पुलिस स्टेशन चलें!", 4.0)

func exit_car() -> void:
	if current_mode != PlayerMode.DRIVING_CAR:
		return
	if car_cooldown_timer > 0.0:
		return
	current_mode = PlayerMode.FOOT_POLICE
	car_cooldown_timer = 2.5
	can_reenter_car = false
	is_near_car = false
	_set_checkpoint_control_mode("adventure")
	car_speed = 0.0
	if kripal_car:
		kripal_car.velocity = Vector3.ZERO
		kripal_car.collision_mask = 7
	if car_engine_audio: car_engine_audio.stop()
	
	if car_door_open_audio: car_door_open_audio.play()
	if car_door_close_audio: car_door_close_audio.play()
	
	# Restore player camera & character models
	if camera: camera.make_current()
	if visual_model: visual_model.visible = true
	
	# Place player safely beside car on the sidewalk (-3.8m away to clear trigger and avoid car body)
	var exit_offset = kripal_car.transform.basis * Vector3(-3.8, 0.05, 0.0)
	player.global_position = kripal_car.global_position + exit_offset
	player.global_position.y = 0.05
	player.velocity = Vector3.ZERO
	
	# Re-enable player and companion collisions
	if player:
		player.collision_layer = 1
		player.collision_mask = 1
	if player_collision:
		player_collision.set_deferred("disabled", false)
	if sahil:
		sahil.collision_layer = 2
		sahil.collision_mask = 1
		sahil.visible = true
		sahil.global_position = player.global_position + Vector3(1.0, 0, 0.6)
		var scol = sahil.get_node_or_null("CollisionShape3D")
		if scol: scol.set_deferred("disabled", false)
	if aashutosh:
		aashutosh.collision_layer = 2
		aashutosh.collision_mask = 1
		aashutosh.visible = true
		aashutosh.global_position = player.global_position + Vector3(-1.4, 0, 0.8)
		var acol = aashutosh.get_node_or_null("CollisionShape3D")
		if acol: acol.set_deferred("disabled", false)
	if kripal_mummy:
		kripal_mummy.collision_layer = 2
		kripal_mummy.collision_mask = 1
		kripal_mummy.visible = true
		kripal_mummy.global_position = player.global_position + Vector3(-0.8, 0, 0.4)
		var mummy_col = kripal_mummy.get_node_or_null("CollisionShape3D")
		if mummy_col: mummy_col.set_deferred("disabled", false)
		
	var dist_to_police = player.global_position.distance_to(Vector3(11.5, 0, -235.0))
	if dist_to_police < 25.0:
		objective_banner.text = "✦ पानसेमल पुलिस थाने की सीढ़ियां चढ़ें और अंदर प्रवेश करें [E]"
		show_subtitle("🚓 [गाड़ी से बाहर निकले]... सामने पानसेमल पुलिस थाना है, अंदर चलें!", 3.5)
		if action_prompt:
			action_prompt.visible = true
			action_prompt.text = "🚪 [E] दबाकर थाने में प्रवेश करें (PRESS [E] TO ENTER POLICE STATION)"
	else:
		objective_banner.text = "✦ कार से बाहर निकले — वापस बैठने के लिए कार के पास जाकर [E] दबाएं"
		show_subtitle("🚶 [गाड़ी से बाहर निकले]... वापस गाड़ी चलाने के लिए कार के पास [E] दबाएं", 3.0)
		if action_prompt:
			action_prompt.visible = true
			action_prompt.text = "🚗 [E] / ACTION दबाकर वापस कार में बैठें (ENTER CAR)"

func _update_walking_companions(delta: float) -> void:
	# Companions follow BEHIND the player on foot so they never block the front path
	if sahil and sahil.visible:
		var follow_s = player.transform.basis * Vector3(-1.2, 0, 1.2)
		var target_s = player.global_position + follow_s
		sahil.global_position = sahil.global_position.lerp(target_s, 4.0 * delta)
		sahil.rotation.y = lerp_angle(sahil.rotation.y, player.rotation.y, 6.0 * delta)
	if aashutosh and aashutosh.visible:
		var follow_a = player.transform.basis * Vector3(1.2, 0, 1.2)
		var target_a = player.global_position + follow_a
		aashutosh.global_position = aashutosh.global_position.lerp(target_a, 4.0 * delta)
		aashutosh.rotation.y = lerp_angle(aashutosh.rotation.y, player.rotation.y, 6.0 * delta)
	if kripal_mummy and kripal_mummy.visible and current_mode == PlayerMode.FOOT_POLICE:
		var target_m = player.global_position + Vector3(-0.6, 0, 1.2)
		kripal_mummy.global_position = kripal_mummy.global_position.lerp(target_m, 3.5 * delta)

func _update_companions(delta: float, player_dir: Vector3) -> void:
	if sahil and sahil.visible:
		var flank_l = player.transform.basis * Vector3(-1.6, 0, 0.5)
		var target_sahil_pos = player.global_position + flank_l
		sahil.global_position = sahil.global_position.lerp(target_sahil_pos, 5.0 * delta)
		sahil.rotation.y = lerp_angle(sahil.rotation.y, player.rotation.y, 7.0 * delta)
			
	if aashutosh and aashutosh.visible:
		var flank_r = player.transform.basis * Vector3(1.6, 0, 0.5)
		var target_aashu_pos = player.global_position + flank_r
		aashutosh.global_position = aashutosh.global_position.lerp(target_aashu_pos, 5.0 * delta)
		aashutosh.rotation.y = lerp_angle(aashutosh.rotation.y, player.rotation.y, 7.0 * delta)

func _process_pedestrians(delta: float) -> void:
	if pedestrian1:
		pedestrian1.position.z -= delta * 0.9
		if pedestrian1.position.z < -65.0: pedestrian1.position.z = -15.0
	if pedestrian2:
		pedestrian2.position.z += delta * 0.8
		if pedestrian2.position.z > -10.0: pedestrian2.position.z = -60.0

func _update_radar_hud() -> void:
	if distance_label:
		var target_pos = landmarks["police"]["pos"] if (current_mode == PlayerMode.DRIVING_CAR or current_mode == PlayerMode.FOOT_POLICE or door_opened) else landmarks["kripal"]["pos"]
		var target_name = "थाना पानसेमल" if (current_mode == PlayerMode.DRIVING_CAR or current_mode == PlayerMode.FOOT_POLICE or door_opened) else "कृपाल निवास"
		var dist = player.global_position.distance_to(target_pos)
		distance_label.text = "%s: %d m" % [target_name, int(dist)]
	if radar_display:
		radar_display.queue_redraw()

func _on_radar_draw() -> void:
	if not radar_display or not player: return
	var center = radar_display.size / 2.0
	var radar_radius = min(center.x, center.y) - 6.0
	
	radar_display.draw_circle(center, radar_radius, Color(0.04, 0.08, 0.12, 0.90))
	radar_display.draw_arc(center, radar_radius, 0, TAU, 32, Color(0.18, 0.45, 0.8, 0.7), 1.6)
	radar_display.draw_arc(center, radar_radius * 0.5, 0, TAU, 24, Color(0.18, 0.45, 0.8, 0.3), 1.0)
	
	# Player forward heading arrow in center of radar
	var p_fwd = Vector2(0, -6.0)
	var p_left = Vector2(-4.0, 3.5)
	var p_right = Vector2(4.0, 3.5)
	radar_display.draw_colored_polygon([center + p_fwd, center + p_left, center + p_right], Color(0.3, 0.9, 1.0, 1.0))
	
	var active_target_key = "police" if (current_mode == PlayerMode.DRIVING_CAR or current_mode == PlayerMode.FOOT_POLICE or door_opened) else "kripal"
	
	for key in landmarks:
		var lm = landmarks[key]
		var rel_3d = lm["pos"] - player.global_position
		var angle = -player.rotation.y
		if current_mode == PlayerMode.DRIVING_CAR and kripal_car:
			angle = -kripal_car.rotation.y + PI
		var rot_x = rel_3d.x * cos(angle) - rel_3d.z * sin(angle)
		var rot_z = rel_3d.x * sin(angle) + rel_3d.z * cos(angle)
		
		var scale_factor = 0.50
		var pos_2d = center + Vector2(rot_x * scale_factor, rot_z * scale_factor)
		var dist_to_center = pos_2d.distance_to(center)
		
		if dist_to_center > radar_radius - 6.0:
			if key == active_target_key:
				var dir_2d = (pos_2d - center).normalized()
				var rim_pos = center + dir_2d * (radar_radius - 7.0)
				radar_display.draw_circle(rim_pos, 5.0, lm["color"])
				radar_display.draw_arc(rim_pos, 7.0, 0, TAU, 16, Color(1, 1, 1, 0.85), 1.5)
		else:
			var dot_radius = 5.0 if key == active_target_key else 3.5
			radar_display.draw_circle(pos_2d, dot_radius, lm["color"])
			if key == active_target_key:
				radar_display.draw_arc(pos_2d, dot_radius + 3.0, 0, TAU, 16, Color(1, 1, 1, 0.85), 1.2)

func toggle_town_map() -> void:
	is_town_map_open = not is_town_map_open
	if town_map_overlay:
		town_map_overlay.visible = is_town_map_open
	if is_town_map_open:
		mouse_captured = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if map_canvas: map_canvas.queue_redraw()
	else:
		mouse_captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_map_canvas_draw() -> void:
	if not map_canvas: return
	var c_size: Vector2 = map_canvas.size
	var font: Font = ThemeDB.fallback_font
	
	# Background
	map_canvas.draw_rect(Rect2(Vector2.ZERO, c_size), Color(0.04, 0.06, 0.10, 0.98))
	
	# Map Title Header
	map_canvas.draw_string(font, Vector2(20, 28), "🗺️ PANSEMAL TOWN MAP (पानसेमल शहर का नक्शा)", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.85, 0.3))
	map_canvas.draw_string(font, Vector2(c_size.x - 170, 28), "[M] TO CLOSE MAP", HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, Color(0.7, 0.7, 0.7))
	
	var road_x: float = c_size.x * 0.44
	var map_top_y: float = 48.0
	var map_bot_y: float = c_size.y - 28.0
	var road_len: float = map_bot_y - map_top_y
	
	# Road Asphalt Body
	map_canvas.draw_rect(Rect2(road_x - 24.0, map_top_y, 48.0, road_len), Color(0.18, 0.20, 0.23, 1.0))
	# Road Curbs/Edges
	map_canvas.draw_line(Vector2(road_x - 24.0, map_top_y), Vector2(road_x - 24.0, map_bot_y), Color(0.75, 0.75, 0.75, 0.8), 2.0)
	map_canvas.draw_line(Vector2(road_x + 24.0, map_top_y), Vector2(road_x + 24.0, map_bot_y), Color(0.75, 0.75, 0.75, 0.8), 2.0)
	
	# Dashed Yellow Center Stripe
	var dash_step: float = 14.0
	var y_pos: float = map_top_y
	while y_pos < map_bot_y:
		map_canvas.draw_line(Vector2(road_x, y_pos), Vector2(road_x, min(y_pos + 8.0, map_bot_y)), Color(0.95, 0.85, 0.35, 0.85), 2.0)
		y_pos += dash_step
		
	# Helper lambda to map 3D Z to map Y
	var z_to_y = func(z_coord: float) -> float:
		var factor = (25.0 - z_coord) / (25.0 - (-245.0))
		return lerp(map_top_y + 10.0, map_bot_y - 15.0, clamp(factor, 0.0, 1.0))
		
	# Landmark definitions on Map
	var map_items = [
		{"name": "🏫 सेंट ऑगस्टीन स्कूल (SCHOOL)", "z": 20.0, "right": true, "col": Color(0.9, 0.75, 0.3), "target": false},
		{"name": "🏠 साहिल निवास (SAHIL'S HOUSE)", "z": -22.0, "right": false, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "📚 सार्वजनिक वाचनालय (LIBRARY)", "z": -22.0, "right": true, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "🏠 मेरा घर (HERO'S HOUSE)", "z": -40.0, "right": true, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "🎬 संगम सिनेमा (SANGAM CINEMA)", "z": -48.0, "right": false, "col": Color(1.0, 0.6, 0.2), "target": false},
		{"name": "🍬 स्वीट्स भण्डार (SWEETS)", "z": -60.0, "right": true, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "🏠 आशुतोष निवास (AASHU'S HOUSE)", "z": -72.0, "right": false, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "★ 🏠 कृपाल निवास एवं कार 🚗 [TARGET 1] ★", "z": -85.0, "right": true, "col": Color(1.0, 0.82, 0.15), "target": true},
		{"name": "🏥 प्राथमिक स्वास्थ्य केंद्र (CLINIC)", "z": -96.0, "right": false, "col": Color(0.3, 0.9, 0.5), "target": false},
		{"name": "🏬 सुपर बाज़ार (SUPER BAZAR)", "z": -112.0, "right": true, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "☕ पाटीदार बेकरी (BAKERY)", "z": -126.0, "right": false, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "💊 संजीवनी मेडिकल (MEDICAL)", "z": -140.0, "right": true, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "🏦 भारतीय स्टेट बैंक & ATM (SBI)", "z": -160.0, "right": false, "col": Color(0.3, 0.6, 1.0), "target": false},
		{"name": "🔧 शर्मा ऑटो गैराज (GARAGE)", "z": -172.0, "right": true, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "📱 इलेक्ट्रॉनिक्स (ELECTRONICS)", "z": -192.0, "right": false, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "📮 मुख्य डाकघर (POST OFFICE)", "z": -196.0, "right": true, "col": Color(1.0, 0.4, 0.4), "target": false},
		{"name": "🏛️ नगर परिषद (TOWN HALL)", "z": -225.0, "right": false, "col": Color(0.8, 0.8, 0.8), "target": false},
		{"name": "★ 🚓 पानसेमल पुलिस थाना (POLICE) [TARGET 2] ★", "z": -235.0, "right": true, "col": Color(0.2, 0.75, 1.0), "target": true}
	]
	
	for item in map_items:
		var item_y = z_to_y.call(item["z"])
		var box_x = road_x + 32.0 if item["right"] else road_x - 175.0
		var box_w = 142.0
		var box_h = 18.0
		
		# Draw connector line from road to building
		map_canvas.draw_line(Vector2(road_x + (24.0 if item["right"] else -24.0), item_y), Vector2(box_x + (0 if item["right"] else box_w), item_y), Color(0.5, 0.5, 0.5, 0.4), 1.0)
		
		# Draw box
		if item["target"]:
			# Highlight target with glowing border
			map_canvas.draw_rect(Rect2(box_x - 2, item_y - 9, box_w + 4, box_h + 2), item["col"], false, 2.0)
			map_canvas.draw_rect(Rect2(box_x, item_y - 8, box_w, box_h), Color(item["col"].r, item["col"].g, item["col"].b, 0.25))
			map_canvas.draw_string(font, Vector2(box_x + 3, item_y + 4), item["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, item["col"])
		else:
			map_canvas.draw_rect(Rect2(box_x, item_y - 7, box_w, box_h), Color(0.1, 0.14, 0.2, 0.75))
			map_canvas.draw_string(font, Vector2(box_x + 3, item_y + 4), item["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, item["col"])
			
	# Draw Live Player Position on Map
	if player:
		var p_y = z_to_y.call(player.global_position.z)
		var p_x = road_x + clamp(player.global_position.x * 2.5, -20.0, 20.0)
		map_canvas.draw_circle(Vector2(p_x, p_y), 6.0, Color(0.2, 1.0, 0.3, 1.0))
		map_canvas.draw_arc(Vector2(p_x, p_y), 8.5, 0, TAU, 16, Color(1, 1, 1, 0.9), 2.0)
		map_canvas.draw_string(font, Vector2(p_x + 11, p_y + 4), "◄ तुम यहाँ हो (YOU)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.2, 1.0, 0.3))

func toggle_camera_mode() -> void:
	is_first_person = not is_first_person
	update_camera_mode()

func update_camera_mode() -> void:
	if not camera or not visual_model: return
	if is_first_person:
		camera.position = Vector3(0, 0.35, -0.15)
		visual_model.visible = false
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] कैमरा: 1st Person"
	else:
		camera.position = Vector3(0, 0.75, 3.4)
		visual_model.visible = true
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] कैमरा: 3rd Person"

func _on_door_trigger_entered(body: Node3D) -> void:
	if body == player and not door_opened:
		is_near_door = true

func _on_door_trigger_exited(body: Node3D) -> void:
	if body == player:
		is_near_door = false

func _on_police_trigger_entered(body: Node3D) -> void:
	if body == player or (kripal_car and body == kripal_car):
		is_near_police_door = true

func _on_police_trigger_exited(body: Node3D) -> void:
	if body == player or (kripal_car and body == kripal_car):
		is_near_police_door = false

func _on_car_trigger_entered(body: Node3D) -> void:
	if body == player:
		if current_mode == PlayerMode.FOOT_POLICE and not can_reenter_car:
			return
		is_near_car = true

func _on_car_trigger_exited(body: Node3D) -> void:
	if body == player:
		is_near_car = false

func start_door_interaction() -> void:
	if cutscene_active: return
	cutscene_active = true
	door_opened = true
	is_near_door = false
	if action_prompt: action_prompt.visible = false

	# Ensure characters are visible and cycle meshes are hidden
	if visual_model:
		visual_model.visible = true
		visual_model.position = Vector3.ZERO
	if sahil:
		sahil.visible = true
		if sahil.has_node("VisualModel"): sahil.get_node("VisualModel").position = Vector3.ZERO
	if aashutosh:
		aashutosh.visible = true
		if aashutosh.has_node("VisualModel"): aashutosh.get_node("VisualModel").position = Vector3.ZERO
	if player_cycle: player_cycle.visible = false
	if sahil_cycle: sahil_cycle.visible = false
	if aashu_cycle: aashu_cycle.visible = false

	# Position conversation camera in front yard angled directly at the doorway conversation
	if convo_camera:
		convo_camera.global_position = Vector3(6.2, 1.65, -82.6)
		convo_camera.look_at(Vector3(8.3, 1.35, -85.0), Vector3.UP)
		convo_camera.make_current()

	if doorbell_audio:
		doorbell_audio.play()

	show_subtitle("🔔 [डोरबेल बजी: डिंग-डोंग]... अंदर से किसी के आने की आहट सुनाई दे रही है...", 2.5)

	# Walk boys to porch and turn them to face the door (+X direction towards X = 9.0)
	var tw = create_tween()
	tw.tween_property(player, "global_position", Vector3(8.0, 0.1, -85.0), 1.2)
	tw.parallel().tween_property(sahil, "global_position", Vector3(7.6, 0.1, -86.2), 1.2)
	tw.parallel().tween_property(aashutosh, "global_position", Vector3(7.6, 0.1, -83.8), 1.2)
	tw.parallel().tween_property(player, "rotation:y", deg_to_rad(-90), 1.2)
	if sahil: tw.parallel().tween_property(sahil, "rotation:y", deg_to_rad(-90), 1.2)
	if aashutosh: tw.parallel().tween_property(aashutosh, "rotation:y", deg_to_rad(-90), 1.2)

	await tw.finished

	if home_door_audio:
		home_door_audio.play()

	var door_tw = create_tween()
	door_tw.tween_property(door_hinge, "rotation_degrees:y", -85.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if kripal_mummy:
		kripal_mummy.visible = true
		kripal_mummy.position = Vector3(-1.8, 0.1, 0.0)
		kripal_mummy.rotation = Vector3(0, deg_to_rad(-90), 0)
		var mummy_tw = create_tween()
		mummy_tw.tween_property(kripal_mummy, "position", Vector3(-3.45, 0.1, 0.0), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await door_tw.finished
	start_dialogue_sequence()

func start_dialogue_sequence() -> void:
	dialogue_in_progress = true
	dialogue_index = 0
	if dialogue_box: dialogue_box.visible = true
	display_current_dialogue()

func display_current_dialogue() -> void:
	if dialogue_index >= dialogues.size():
		end_dialogue_sequence()
		return
		
	can_advance_dialogue = false
	var d = dialogues[dialogue_index]
	
	if speaker_label:
		speaker_label.text = d["speaker"]
		speaker_label.modulate = d["color"]
	if dialogue_text:
		dialogue_text.text = d["text"]
	if advance_tip:
		advance_tip.text = "[CLICK / SPACE TO CONTINUE]"
		
	if voice_audio and d["audio"]:
		voice_audio.stop()
		voice_audio.stream = d["audio"]
		voice_audio.play()
		
	await get_tree().create_timer(0.6).timeout
	can_advance_dialogue = true

func advance_dialogue() -> void:
	if not can_advance_dialogue: return
	dialogue_index += 1
	display_current_dialogue()

func end_dialogue_sequence() -> void:
	dialogue_in_progress = false
	cutscene_active = false
	if dialogue_box: dialogue_box.visible = false
	if subtitle: subtitle.text = ""
	if camera: camera.make_current()
	
	# Aunty, Sahil, Aashutosh walk towards the car
	var walk_tw = create_tween()
	if kripal_mummy:
		walk_tw.parallel().tween_property(kripal_mummy, "global_position", Vector3(4.8, 0.1, -77.0), 1.6)
	if sahil:
		walk_tw.parallel().tween_property(sahil, "global_position", Vector3(4.8, 0.1, -79.0), 1.6)
	if aashutosh:
		walk_tw.parallel().tween_property(aashutosh, "global_position", Vector3(2.4, 0.1, -79.0), 1.6)
		
	objective_banner.text = "✦ कृपाल की कार में बैठें [E] और पानसेमल पुलिस स्टेशन ड्राइव करें"
	show_subtitle("👩 कृपाल की माँ: 'कृपाल की गाड़ी बाहर खड़ी है... चलो सब इसमें बैठो, हम अभी पुलिस स्टेशन चलते हैं!'", 4.5)
	
	if action_prompt:
		action_prompt.visible = true
		action_prompt.text = "🚗 [E] दबाकर कार में बैठें और चलाएं (PRESS [E] TO DRIVE CAR)"

func show_subtitle(text: String, duration: float) -> void:
	if not subtitle: return
	subtitle.text = text
	subtitle.modulate.a = 1.0
	await get_tree().create_timer(duration).timeout
	if subtitle and subtitle.text == text:
		var tw = create_tween()
		tw.tween_property(subtitle, "modulate:a", 0.0, 0.6)

func _on_start_police_pressed() -> void:
	if start_police_btn:
		start_police_btn.disabled = true
		start_police_btn.text = "🚓 ENTERING PANSEMAL POLICE STATION..."
	var tw = create_tween()
	if next_chapter_card:
		tw.tween_property(next_chapter_card, "modulate:a", 0.0, 0.4)
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://scenes/police_station.tscn")

func _on_replay_street_pressed() -> void:
	get_tree().reload_current_scene()

func _set_checkpoint_control_mode(mode: String) -> void:
	var cm = get_node_or_null("/root/CheckpointManager")
	if cm and cm.has_method("set_control_mode"):
		cm.set_control_mode(mode)

# ==============================================================================
# CINEMATIC GRAPHICS & ARCHITECTURAL DETAILING (SCHOOL TO KRIPAL ROUTE)
# ==============================================================================

var _shared_wall_normal: NoiseTexture2D = null
var _shared_shutter_normal: NoiseTexture2D = null
var _shared_wood_normal: NoiseTexture2D = null
var _shared_road_normal: NoiseTexture2D = null

func _init_procedural_normal_textures() -> void:
	if _shared_wall_normal == null:
		var fn_wall = FastNoiseLite.new()
		fn_wall.noise_type = FastNoiseLite.TYPE_SIMPLEX
		fn_wall.frequency = 0.18
		_shared_wall_normal = NoiseTexture2D.new()
		_shared_wall_normal.width = 128
		_shared_wall_normal.height = 128
		_shared_wall_normal.noise = fn_wall
		_shared_wall_normal.as_normal_map = true
		_shared_wall_normal.bump_strength = 2.2
		
	if _shared_shutter_normal == null:
		var fn_shutter = FastNoiseLite.new()
		fn_shutter.noise_type = FastNoiseLite.TYPE_PERLIN
		fn_shutter.frequency = 0.45
		_shared_shutter_normal = NoiseTexture2D.new()
		_shared_shutter_normal.width = 128
		_shared_shutter_normal.height = 128
		_shared_shutter_normal.noise = fn_shutter
		_shared_shutter_normal.as_normal_map = true
		_shared_shutter_normal.bump_strength = 3.2

	if _shared_wood_normal == null:
		var fn_wood = FastNoiseLite.new()
		fn_wood.noise_type = FastNoiseLite.TYPE_PERLIN
		fn_wood.frequency = 0.28
		_shared_wood_normal = NoiseTexture2D.new()
		_shared_wood_normal.width = 128
		_shared_wood_normal.height = 128
		_shared_wood_normal.noise = fn_wood
		_shared_wood_normal.as_normal_map = true
		_shared_wood_normal.bump_strength = 2.4

	if _shared_road_normal == null:
		var fn_road = FastNoiseLite.new()
		fn_road.noise_type = FastNoiseLite.TYPE_SIMPLEX
		fn_road.frequency = 0.24
		_shared_road_normal = NoiseTexture2D.new()
		_shared_road_normal.width = 128
		_shared_road_normal.height = 128
		_shared_road_normal.noise = fn_road
		_shared_road_normal.as_normal_map = true
		_shared_road_normal.bump_strength = 1.8

func _create_pbr_wall_mat(color: Color, uv_scale: float = 3.5, roughness: float = 0.82) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if _shared_wall_normal:
		mat.normal_enabled = true
		mat.normal_texture = _shared_wall_normal
		mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	return mat

func _setup_cinematic_graphics() -> void:
	_init_procedural_normal_textures()
	
	# 1. WorldEnvironment Next-Gen Configuration
	var world_env = get_node_or_null("WorldEnvironment")
	if world_env and world_env.environment:
		var env = world_env.environment
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.05
		env.tonemap_white = 1.15
		env.glow_enabled = true
		env.glow_intensity = 0.55
		env.glow_bloom = 0.22
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
		env.glow_hdr_threshold = 1.0
		env.ssao_enabled = true
		env.ssao_radius = 1.8
		env.ssao_intensity = 2.4
		env.ssao_power = 1.5
		env.fog_enabled = true
		env.fog_light_color = Color(0.06, 0.08, 0.14)
		env.fog_density = 0.020
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.06
		env.adjustment_saturation = 1.12
		
	# 2. Moonlight Shadows
	if moonlight:
		moonlight.shadow_enabled = true
		moonlight.shadow_blur = 1.5
		moonlight.light_energy = 0.35
		
	# 3. Drifting Storm Ground Mist Particles across the street
	var existing_mist = get_node_or_null("StreetGroundMist")
	if not existing_mist:
		var mist = CPUParticles3D.new()
		mist.name = "StreetGroundMist"
		mist.amount = 55
		mist.lifetime = 6.0
		mist.preprocess = 3.0
		mist.randomness = 0.85
		mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		mist.emission_box_extents = Vector3(12.0, 0.3, 130.0)
		mist.position = Vector3(0.0, 0.35, -125.0)
		mist.direction = Vector3(0.35, 0.02, 0.1)
		mist.spread = 25.0
		mist.gravity = Vector3(0, 0.005, 0)
		mist.initial_velocity_min = 0.25
		mist.initial_velocity_max = 0.65
		
		var mist_mat = StandardMaterial3D.new()
		mist_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mist_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mist_mat.albedo_color = Color(0.68, 0.74, 0.88, 0.14)
		
		var mist_mesh = SphereMesh.new()
		mist_mesh.radius = 0.75
		mist_mesh.height = 0.4
		mist_mesh.material = mist_mat
		mist.mesh = mist_mesh
		add_child(mist)
		
	# 4. Cinematic Horror Vignette Overlay on StreetUI
	var ui_node = get_node_or_null("StreetUI")
	if ui_node and not ui_node.get_node_or_null("HorrorVignette"):
		var vignette_rect = TextureRect.new()
		vignette_rect.name = "HorrorVignette"
		vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vig_tex = load("res://textures/vignette.png")
		if vig_tex:
			vignette_rect.texture = vig_tex
			vignette_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			vignette_rect.stretch_mode = TextureRect.STRETCH_SCALE
			vignette_rect.modulate = Color(1.0, 1.0, 1.0, 0.52)
			ui_node.add_child(vignette_rect)
			ui_node.move_child(vignette_rect, 0)

func _enhance_street_buildings() -> void:
	_init_procedural_normal_textures()
	
	# Concrete Chhajja (Sunshade) Material
	var mat_chhajja = StandardMaterial3D.new()
	mat_chhajja.albedo_color = Color(0.92, 0.90, 0.85)
	mat_chhajja.roughness = 0.75
	if _shared_wall_normal:
		mat_chhajja.normal_enabled = true
		mat_chhajja.normal_texture = _shared_wall_normal
		mat_chhajja.uv1_scale = Vector3(2.0, 2.0, 2.0)
		
	# Corrugated Iron Shutter Material
	var mat_shutter = StandardMaterial3D.new()
	mat_shutter.albedo_color = Color(0.55, 0.58, 0.62)
	mat_shutter.metallic = 0.75
	mat_shutter.roughness = 0.38
	if _shared_shutter_normal:
		mat_shutter.normal_enabled = true
		mat_shutter.normal_texture = _shared_shutter_normal
		mat_shutter.uv1_scale = Vector3(1.0, 6.0, 1.0)
		
	# Teak Wood Door Material
	var mat_door = StandardMaterial3D.new()
	mat_door.albedo_color = Color(0.38, 0.20, 0.12)
	mat_door.roughness = 0.55
	if _shared_wood_normal:
		mat_door.normal_enabled = true
		mat_door.normal_texture = _shared_wood_normal
		mat_door.uv1_scale = Vector3(2.0, 2.0, 2.0)
		
	# Sintex Water Tank Material
	var mat_sintex = StandardMaterial3D.new()
	mat_sintex.albedo_color = Color(0.12, 0.13, 0.15)
	mat_sintex.roughness = 0.75
	
	# Warm Glowing Window Material
	var mat_win_warm = StandardMaterial3D.new()
	mat_win_warm.albedo_color = Color(1.0, 0.88, 0.55)
	mat_win_warm.emission_enabled = true
	mat_win_warm.emission = Color(1.0, 0.85, 0.45)
	mat_win_warm.emission_energy_multiplier = 2.4

	# Individual Building Color & Styling Dictionary
	var building_specs = {
		"SahilHouse": {
			"wall_col": Color(0.20, 0.52, 0.88), # Vibrant Jodhpur Royal Blue
			"trim_col": Color(0.96, 0.96, 0.94),
			"has_chhajjas": true
		},
		"CityLibrary": {
			"wall_col": Color(0.78, 0.56, 0.32), # Warm Sandstone Ochre
			"trim_col": Color(0.94, 0.90, 0.82),
			"has_chhajjas": true
		},
		"PlayerHouse": {
			"wall_col": Color(0.92, 0.72, 0.18), # Warm Indian Turmeric Yellow
			"trim_col": Color(0.45, 0.22, 0.14),
			"has_chhajjas": true
		},
		"SangamCinema": {
			"wall_col": Color(0.55, 0.15, 0.22), # Deep Bollywood Burgundy
			"trim_col": Color(0.96, 0.85, 0.25),
			"has_chhajjas": false
		},
		"SweetsNamkeenShop": {
			"wall_col": Color(0.94, 0.50, 0.14), # Saffron Sweet Shop Orange
			"trim_col": Color(0.96, 0.94, 0.90),
			"has_chhajjas": false
		},
		"AashutoshHouse": {
			"wall_col": Color(0.26, 0.70, 0.44), # Fresh Pistachio Mint Green
			"trim_col": Color(0.96, 0.96, 0.94),
			"has_chhajjas": true
		},
		"CityClinic": {
			"wall_col": Color(0.86, 0.94, 0.96), # Hospital Pale Mint White
			"trim_col": Color(0.18, 0.60, 0.32),
			"has_chhajjas": true
		},
		"SuperBazar": {
			"wall_col": Color(0.86, 0.30, 0.28), # Modern Coral Red
			"trim_col": Color(0.96, 0.96, 0.94),
			"has_chhajjas": false
		},
		"PatidarBakery": {
			"wall_col": Color(0.88, 0.62, 0.28), # Warm Golden Biscuit
			"trim_col": Color(0.42, 0.24, 0.15),
			"has_chhajjas": false
		},
		"SanjeevaniMedical": {
			"wall_col": Color(0.20, 0.65, 0.58), # Clinical Sea Green
			"trim_col": Color(0.94, 0.96, 0.94),
			"has_chhajjas": false
		},
		"SBI_Bank": {
			"wall_col": Color(0.08, 0.26, 0.68), # Authentic SBI Royal Blue
			"trim_col": Color(0.96, 0.96, 0.96),
			"has_chhajjas": true
		},
		"SharmaGarage": {
			"wall_col": Color(0.36, 0.40, 0.44), # Industrial Slate Grey
			"trim_col": Color(0.24, 0.26, 0.28),
			"has_chhajjas": false
		},
		"ElectronicsShop": {
			"wall_col": Color(0.50, 0.30, 0.70), # Tech Violet
			"trim_col": Color(0.92, 0.88, 0.96),
			"has_chhajjas": false
		},
		"HeadPostOffice": {
			"wall_col": Color(0.82, 0.18, 0.18), # Indian Postal Crimson Red
			"trim_col": Color(0.88, 0.78, 0.55),
			"has_chhajjas": true
		},
		"TownHall": {
			"wall_col": Color(0.82, 0.68, 0.45), # Heritage Sandstone Ochre
			"trim_col": Color(0.96, 0.95, 0.92),
			"has_chhajjas": true
		},
		"PansemalPoliceStation": {
			"wall_col": Color(0.78, 0.62, 0.42), # Police Sandstone Khaki
			"trim_col": Color(0.12, 0.28, 0.72),
			"has_chhajjas": true
		}
	}
	
	# Apply styling across Pansemal Town Houses
	var town_houses = get_node_or_null("EnvironmentProps/PansemalTownHouses")
	if town_houses:
		for b_name in building_specs:
			var b_node = town_houses.get_node_or_null(b_name)
			if b_node:
				var spec = building_specs[b_name]
				var mat_wall = _create_pbr_wall_mat(spec["wall_col"])
				var mat_trim = _create_pbr_wall_mat(spec["trim_col"], 2.0, 0.70)
				
				# Style Main Building Box
				var b_main = b_node.get_node_or_null("Building")
				if b_main and b_main is CSGBox3D:
					b_main.material = mat_wall
					
				# Style Parapet Wall
				var b_parapet = b_node.get_node_or_null("Parapet")
				if b_parapet and b_parapet is CSGBox3D:
					b_parapet.material = mat_trim
					
				# Style Shutters with PBR Corrugated Metal
				var shutter = b_node.get_node_or_null("Shutter")
				if shutter and shutter is CSGBox3D:
					shutter.material = mat_shutter
				var wide_shutter = b_node.get_node_or_null("WideShutter")
				if wide_shutter and wide_shutter is CSGBox3D:
					wide_shutter.material = mat_shutter
					
				# Style Doors with Teak Wood PBR
				var door = b_node.get_node_or_null("Door")
				if door and door is CSGBox3D:
					door.material = mat_door
					
				# Style Windows with warm interior emission
				for win_name in ["Win", "Win1", "Win2", "Win3"]:
					var win = b_node.get_node_or_null(win_name)
					if win and win is CSGBox3D:
						win.material = mat_win_warm
						
				# Add architectural chhajjas (concrete sunshades) over windows if flagged
				if spec["has_chhajjas"]:
					for win_name in ["Win", "Win1", "Win2", "Win3"]:
						var win = b_node.get_node_or_null(win_name)
						if win and win is CSGBox3D and not win.get_node_or_null("Chhajja"):
							var chhajja = CSGBox3D.new()
							chhajja.name = "Chhajja"
							chhajja.size = Vector3(win.size.x + 0.35, 0.08, win.size.z + 0.35)
							chhajja.position = Vector3(0.12 if win.position.x > 0 else -0.12, win.size.y * 0.5 + 0.08, 0)
							chhajja.material = mat_chhajja
							chhajja.use_collision = false
							win.add_child(chhajja)

	# Style St. Augustine School
	var school = get_node_or_null("EnvironmentProps/PansemalTownHouses/StAugustineSchool")
	if school:
		var mat_school_brick = _create_pbr_wall_mat(Color(0.82, 0.35, 0.20), 4.0)
		var mat_school_trim = _create_pbr_wall_mat(Color(0.96, 0.92, 0.82), 2.0, 0.65)
		for part_name in ["MainBuilding", "LeftWing", "RightWing", "ClockTower"]:
			var part = school.get_node_or_null(part_name)
			if part and part is CSGBox3D:
				part.material = mat_school_brick
		var portico = school.get_node_or_null("EntrancePortico")
		if portico and portico is CSGBox3D:
			portico.material = mat_school_trim
		for pillar_name in ["PorticoPillarL", "PorticoPillarR"]:
			var pillar = school.get_node_or_null(pillar_name)
			if pillar and pillar is CSGBox3D:
				pillar.material = mat_school_trim
		# Add sunshades over school windows
		for win_name in ["WinF1L", "WinF1R", "WinF2L", "WinF2R", "WinLeftWing", "WinRightWing"]:
			var win = school.get_node_or_null(win_name)
			if win and win is CSGBox3D and not win.get_node_or_null("Chhajja"):
				var chhajja = CSGBox3D.new()
				chhajja.name = "Chhajja"
				chhajja.size = Vector3(win.size.x + 0.4, 0.09, win.size.z + 0.4)
				chhajja.position = Vector3(0, win.size.y * 0.5 + 0.08, 0.15)
				chhajja.material = mat_chhajja
				chhajja.use_collision = false
				win.add_child(chhajja)

	# Style Kripal's House ($KripalHouse) with signature Indian Ocean Teal and details
	var kh = get_node_or_null("KripalHouse")
	if kh:
		var mat_kh_wall = _create_pbr_wall_mat(Color(0.18, 0.62, 0.68), 3.5) # Deep Indian Ocean Emerald Teal
		var mat_kh_parapet = _create_pbr_wall_mat(Color(0.96, 0.95, 0.92), 2.0, 0.68) # Clean Cream Trim
		var mat_kh_brick = _create_pbr_wall_mat(Color(0.82, 0.42, 0.22), 3.0) # Terracotta boundary & pillars
		
		var house_struct = kh.get_node_or_null("HouseStructure")
		if house_struct and house_struct is CSGBox3D:
			house_struct.material = mat_kh_wall
			
		var terrace_cabin = kh.get_node_or_null("TerraceCabin")
		if terrace_cabin and terrace_cabin is CSGBox3D:
			terrace_cabin.material = mat_kh_wall
			
		var roof_parapet = kh.get_node_or_null("RoofParapet")
		if roof_parapet and roof_parapet is CSGBox3D:
			roof_parapet.material = mat_kh_parapet
			
		for b_wall in ["BoundaryWallL", "BoundaryWallR", "GatePillarL", "GatePillarR"]:
			var wall_node = kh.get_node_or_null(b_wall)
			if wall_node and wall_node is CSGBox3D:
				wall_node.material = mat_kh_brick
				
		var porch_roof = kh.get_node_or_null("PorchRoof")
		if porch_roof and porch_roof is CSGBox3D:
			porch_roof.material = mat_kh_brick
			
		var door_frame = kh.get_node_or_null("DoorFrame")
		if door_frame and door_frame is CSGBox3D:
			door_frame.material = mat_kh_parapet
			
		# Windows with warm interior lighting and concrete chhajjas (sunshades)
		for win_name in ["Window1", "Window2", "WindowF2_1", "WindowF2_2"]:
			var win = kh.get_node_or_null(win_name)
			if win and win is CSGBox3D:
				win.material = mat_win_warm
				if not win.get_node_or_null("Chhajja"):
					var chhajja = CSGBox3D.new()
					chhajja.name = "Chhajja"
					chhajja.size = Vector3(0.45, 0.08, win.size.z + 0.35)
					chhajja.position = Vector3(-0.15, win.size.y * 0.5 + 0.08, 0)
					chhajja.rotation_degrees = Vector3(0, 0, 8.0) # Slanted down to deflect rain
					chhajja.material = mat_chhajja
					chhajja.use_collision = false
					win.add_child(chhajja)
					
		# Rooftop Sintex tank
		var tank = kh.get_node_or_null("SintexTank")
		if tank and tank is CSGCylinder3D:
			tank.material = mat_sintex
			
		# Carved entrance door
		var door_mesh = kh.get_node_or_null("DoorHinge/MainDoor")
		if door_mesh and door_mesh is CSGBox3D:
			door_mesh.material = mat_door

