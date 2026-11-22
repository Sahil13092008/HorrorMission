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
@onready var visual_model: Node3D = $Player/VisualModel
@onready var player_cycle: Node3D = $Player/VisualModel/CycleModel
@onready var sahil_cycle: Node3D = $Companions/SahilCompanion/CycleModel
@onready var aashu_cycle: Node3D = $Companions/AashutoshCompanion/CycleModel

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
const CAR_MAX_SPEED: float = 12.5
const CAR_ACCEL: float = 7.5
const CAR_STEER_SPEED: float = 1.8

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
var is_near_police_door: bool = false
var door_opened: bool = false
var cutscene_active: bool = false
var is_town_map_open: bool = false
var dialogue_in_progress: bool = false
var dialogue_index: int = 0
var can_advance_dialogue: bool = false

# Weather & Atmosphere Timers
var lightning_timer: float = 3.5
var is_lightning_flashing: bool = false
var pulse_time: float = 0.0

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
		
	if dialogue_box: dialogue_box.visible = false
	if next_chapter_card: next_chapter_card.visible = false
	if prompt_label: prompt_label.visible = false
	if kripal_mummy: kripal_mummy.visible = false
	if action_prompt: action_prompt.visible = false
	if parked_bicycles: parked_bicycles.visible = false
	if gps_arrows: gps_arrows.visible = false
	
	start_school_exit_intro()

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
	
	show_subtitle("⛈️ [तूफान, बारिश और बादलों की गर्जना]... सेंट ऑगस्टीन स्कूल से बाहर निकलते हुए...", 3.2)
	trigger_lightning(true)
	
	await get_tree().create_timer(1.8).timeout
	show_subtitle("🧢 साहिल: 'मौसम बहुत खराब हो रहा है! तेज साइकिल चलाओ, कृपाल के घर पहुँचना है!'", 2.8)
	
	await get_tree().create_timer(2.4).timeout
	var cam_tw = create_tween()
	cam_tw.tween_property(camera, "position", Vector3(0, 0.75, 3.4), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	cam_tw.tween_property(camera, "rotation_degrees", Vector3.ZERO, 1.4).set_trans(Tween.TRANS_QUAD)
	
	await cam_tw.finished
	cutscene_active = false
	objective_banner.text = "✦ MISSION: RIDE BICYCLE IN THUNDERSTORM TO KRIPAL'S HOUSE [WASD / SHIFT]"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured and not cutscene_active and not is_town_map_open:
		if current_mode != PlayerMode.DRIVING_CAR:
			player.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
			camera_rot_x -= event.relative.y * MOUSE_SENSITIVITY
			camera_rot_x = clamp(camera_rot_x, -deg_to_rad(75), deg_to_rad(75))
			camera_pivot.rotation.x = camera_rot_x

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_town_map()
		elif event.keycode == KEY_V:
			toggle_camera_mode()
		elif event.keycode == KEY_B and current_mode == PlayerMode.CYCLING and not cutscene_active:
			ring_cycle_bell()
		elif event.keycode == KEY_BACKSPACE and current_mode == PlayerMode.DRIVING_CAR:
			exit_car()
		elif event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			handle_interaction()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_in_progress and can_advance_dialogue:
			advance_dialogue()

func handle_interaction() -> void:
	if dialogue_in_progress and can_advance_dialogue:
		advance_dialogue()
		return
		
	if cutscene_active: return
	
	var dist_door_quick = player.global_position.distance_to(Vector3(9.0, 0.5, -85.0))
	if (is_near_door or dist_door_quick < 6.5) and not door_opened:
		if current_mode == PlayerMode.CYCLING:
			dismount_bicycle()
		start_door_interaction()
		return

	if current_mode == PlayerMode.CYCLING:
		if can_dismount:
			dismount_bicycle()
		else:
			ring_cycle_bell()
	elif current_mode == PlayerMode.FOOT_KRIPAL:
		if is_near_door and not door_opened:
			start_door_interaction()
		elif is_near_car and door_opened:
			enter_car()
	elif current_mode == PlayerMode.DRIVING_CAR:
		if abs(car_speed) < 2.0:
			exit_car()
	elif current_mode == PlayerMode.FOOT_POLICE:
		var dist_to_police = player.global_position.distance_to(Vector3(11.5, 0, -235.0))
		if is_near_police_door or dist_to_police < 10.0:
			_on_start_police_pressed()

func dismount_bicycle() -> void:
	current_mode = PlayerMode.FOOT_KRIPAL
	is_cycling = false
	can_dismount = false
	if action_prompt: action_prompt.visible = false
	
	# Hide riding cycle meshes on player and companions
	if player_cycle: player_cycle.visible = false
	if sahil_cycle: sahil_cycle.visible = false
	if aashu_cycle: aashu_cycle.visible = false
	
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
	# Safety Floor Clamping - Permanently prevents falling through ground into void
	if player and player.global_position.y < -0.10:
		player.global_position.y = 0.05
		player.velocity.y = 0.0
	if kripal_car and kripal_car.global_position.y < -0.10:
		kripal_car.global_position.y = 0.25
		kripal_car.velocity.y = 0.0

	_process_pedestrians(delta)
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
		
	# MODE 1: CYCLING
	if current_mode == PlayerMode.CYCLING:
		var dist_to_kripal: int = int(abs(player.global_position.z - (-85.0)))
		# Check if approaching Kripal's house to show dismount option
		if player.global_position.z <= -75.0:
			can_dismount = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚲 [E] दबाकर साइकिल से उतरें (PRESS [E] TO DISMOUNT BICYCLE)"
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
		var dist_to_car: float = player.global_position.distance_to(Vector3(5.6, 0.35, -76.0))
		
		if (is_near_door or dist_to_door < 6.5) and not door_opened:
			is_near_door = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🔔 [E] दबाकर डोरबेल बजाएं (PRESS [E] TO RING DOORBELL)"
		elif (is_near_car or dist_to_car < 4.0) and door_opened:
			is_near_car = true
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚗 [E] दबाकर कार में बैठें और चलाएं (PRESS [E] TO DRIVE CAR)"
		else:
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
		if is_near_police_door or dist_to_police < 10.0:
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚪 [E] दबाकर थाने में प्रवेश करें (PRESS [E] TO ENTER POLICE STATION)"
			if dist_to_police < 3.2:
				_on_start_police_pressed()
		else:
			if action_prompt:
				action_prompt.visible = true
				action_prompt.text = "🚶 पुलिस थाने के मुख्य द्वार की तरफ बढ़ें (WALK TOWARDS POLICE ENTRANCE)"

func _handle_cycling_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	input_dir = input_dir.normalized()
	
	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)
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
	_update_companions(delta, direction)

func _handle_foot_movement(delta: float) -> void:
	if cycle_audio and cycle_audio.playing: cycle_audio.stop()
	
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	input_dir = input_dir.normalized()
	
	var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0.0
		
	var is_sprint: bool = Input.is_key_pressed(KEY_SHIFT)
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
	
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		forward_input += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		forward_input -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		steer_input += 1.0   # Turn Left
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		steer_input -= 1.0   # Turn Right
		
	# Accelerate forward or reverse/brake
	if forward_input > 0:
		car_speed = move_toward(car_speed, CAR_MAX_SPEED, CAR_ACCEL * delta)
	elif forward_input < 0:
		car_speed = move_toward(car_speed, -CAR_MAX_SPEED * 0.5, CAR_ACCEL * 1.4 * delta)
	else:
		car_speed = move_toward(car_speed, 0.0, CAR_ACCEL * 0.8 * delta)
		
	# Steer car: steer_input > 0 (A pressed) turns Left, steer_input < 0 (D pressed) turns Right!
	if abs(car_speed) > 0.1 and steer_input != 0.0:
		var dir_factor = 1.0 if car_speed >= 0 else -1.0
		kripal_car.rotate_y(steer_input * CAR_STEER_SPEED * delta * dir_factor)
		
	# Move car along its forward basis (car front points along Z in our model)
	var car_fwd = kripal_car.transform.basis.z.normalized()
	kripal_car.velocity = car_fwd * car_speed
	kripal_car.move_and_slide()
	
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
			objective_banner.text = "🎯 ARRIVED AT POLICE STATION! PRESS [BACKSPACE] OR [E] TO EXIT CAR"
		
	# Action prompt update
	if action_prompt:
		action_prompt.visible = true
		if kripal_car.global_position.z <= -215.0:
			action_prompt.text = "🚗 [BACKSPACE] या [E] दबाकर कार से उतरें (PRESS [BACKSPACE] OR [E] TO EXIT CAR)"
		else:
			action_prompt.text = "🚗 [W] FORWARD | [S] REVERSE | [A] LEFT | [D] RIGHT | [BACKSPACE] EXIT"

func enter_car() -> void:
	current_mode = PlayerMode.DRIVING_CAR
	if action_prompt: action_prompt.text = "🚗 [W] FORWARD | [S] REVERSE | [A/D] STEER | [BACKSPACE] EXIT CAR"
	
	if car_door_open_audio: car_door_open_audio.play()
	await get_tree().create_timer(0.3).timeout
	if car_door_close_audio: car_door_close_audio.play()
	if car_start_audio: car_start_audio.play()
	
	await get_tree().create_timer(0.8).timeout
	if car_engine_audio:
		car_engine_audio.play()
		
	# Hide player and companions visual models inside car
	if visual_model: visual_model.visible = false
	if kripal_mummy: kripal_mummy.visible = false
	if sahil: sahil.visible = false
	if aashutosh: aashutosh.visible = false
	
	# Switch to car chase camera
	if car_camera: car_camera.make_current()
	
	# Show GPS navigation road arrows
	if gps_arrows: gps_arrows.visible = true
	
	objective_banner.text = "✦ GPS NAVIGATION: FOLLOW GLOWING ROAD ARROWS TO PANSEMAL POLICE STATION"
	show_subtitle("🚗 [कार स्टार्ट हुई]... सड़क पर चमकते तीरों (GPS ARROWS) का पीछा करते हुए पुलिस स्टेशन चलें!", 4.0)

func exit_car() -> void:
	current_mode = PlayerMode.FOOT_POLICE
	car_speed = 0.0
	if car_engine_audio: car_engine_audio.stop()
	
	if car_door_open_audio: car_door_open_audio.play()
	if car_door_close_audio: car_door_close_audio.play()
	
	# Restore player camera & character models
	if camera: camera.make_current()
	if visual_model: visual_model.visible = true
	
	# Place player safely beside car
	player.global_position = kripal_car.global_position + Vector3(-2.2, 0.2, 0)
	
	# Position companions outside car
	if kripal_mummy:
		kripal_mummy.visible = true
		kripal_mummy.global_position = player.global_position + Vector3(-0.8, 0, 0.4)
	if sahil:
		sahil.visible = true
		sahil.global_position = player.global_position + Vector3(1.0, 0, 0.6)
	if aashutosh:
		aashutosh.visible = true
		aashutosh.global_position = player.global_position + Vector3(-1.4, 0, 0.8)
		
	objective_banner.text = "✦ पानसेमल पुलिस थाने की सीढ़ियां चढ़ें और अंदर प्रवेश करें [E]"
	show_subtitle("🚓 [गाड़ी से बाहर निकले]... सामने पानसेमल पुलिस थाना है, अंदर चलें!", 3.5)
	if action_prompt:
		action_prompt.visible = true
		action_prompt.text = "🚪 [E] दबाकर थाने में प्रवेश करें (PRESS [E] TO ENTER POLICE STATION)"
	if action_prompt:
		action_prompt.visible = true
		action_prompt.text = "🚪 [E] दबाकर थाने में प्रवेश करें (PRESS [E] TO ENTER POLICE STATION)"

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
	
	if doorbell_audio:
		doorbell_audio.play()
		
	show_subtitle("🔔 [डोरबेल बजी: डिंग-डोंग]... अंदर से किसी के आने की आहट सुनाई दे रही है...", 2.5)
	
	var tw = create_tween()
	tw.tween_property(player, "global_position", Vector3(8.0, 0.1, -85.0), 1.2)
	tw.parallel().tween_property(sahil, "global_position", Vector3(7.6, 0.1, -86.2), 1.2)
	tw.parallel().tween_property(aashutosh, "global_position", Vector3(7.6, 0.1, -83.8), 1.2)
	tw.parallel().tween_property(player, "rotation:y", deg_to_rad(90), 1.2)
	if sahil: tw.parallel().tween_property(sahil, "rotation:y", deg_to_rad(90), 1.2)
	if aashutosh: tw.parallel().tween_property(aashutosh, "rotation:y", deg_to_rad(90), 1.2)
	
	await tw.finished
	
	if home_door_audio:
		home_door_audio.play()
		
	var door_tw = create_tween()
	door_tw.tween_property(door_hinge, "rotation_degrees:y", -85.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if kripal_mummy:
		kripal_mummy.visible = true
		kripal_mummy.position.x = -2.6
		var mummy_tw = create_tween()
		mummy_tw.tween_property(kripal_mummy, "position:x", -2.9, 1.2)
		
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
	
	# Aunty, Sahil, Aashutosh walk towards the car
	var walk_tw = create_tween()
	if kripal_mummy:
		walk_tw.parallel().tween_property(kripal_mummy, "global_position", Vector3(4.8, 0.1, -75.0), 1.6)
	if sahil:
		walk_tw.parallel().tween_property(sahil, "global_position", Vector3(4.8, 0.1, -77.2), 1.6)
	if aashutosh:
		walk_tw.parallel().tween_property(aashutosh, "global_position", Vector3(6.6, 0.1, -77.2), 1.6)
		
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
