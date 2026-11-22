# street_to_kripal.gd
# Pansemal Town Street Journey: St. Augustine School -> Bicycle Ride in Thunderstorm -> Kripal's Residence
# Features:
# - St. Augustine School, Pansemal background with grand architecture & illuminated signboard
# - 3 Bicycles (Player, Sahil, Aashutosh) with steering, headlight beams, pedaling & cycle bell [B]
# - Stormy weather with crackling lightning strikes, rolling thunder & rain wind ambience
# - Companions (Sahil & Aashutosh) riding bicycles alongside Player
# - Pansemal Town Map & Radar tracking all 6 landmarks (St. Augustine, Sahil, Player, Aashu, Police, Kripal)
# - 100% Spoken Hindi Dialogues with Kripal's Mother (mother weeping & Player comforting her)
# - Chapter 1 Mission Poster in English (Pansemal Police Station FIR)

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

# --- World & Environment ---
@onready var moonlight: DirectionalLight3D = $Moonlight
@onready var lightning_light: DirectionalLight3D = $LightningLight
@onready var door_hinge: Node3D = $KripalHouse/DoorHinge
@onready var door_trigger: Area3D = $KripalHouse/DoorTrigger
@onready var kripal_mummy: Node3D = $KripalHouse/KripalMummy
@onready var sahil: CharacterBody3D = $Companions/SahilCompanion
@onready var aashutosh: CharacterBody3D = $Companions/AashutoshCompanion
@onready var pedestrian1: Node3D = $EnvironmentProps/Pedestrians/Pedestrian1
@onready var pedestrian2: Node3D = $EnvironmentProps/Pedestrians/Pedestrian2
@onready var trees_parent: Node3D = $EnvironmentProps/Trees

# Police Station lights
@onready var police_light_red: OmniLight3D = $EnvironmentProps/PansemalTownHouses/PansemalPoliceStation/PoliceLightRed
@onready var police_light_blue: OmniLight3D = $EnvironmentProps/PansemalTownHouses/PansemalPoliceStation/PoliceLightBlue

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
@onready var objective_banner: Label = $StreetUI/ObjectiveBanner
@onready var mini_map_panel: PanelContainer = $StreetUI/MiniMapPanel
@onready var radar_display: Control = $StreetUI/MiniMapPanel/Margin/VBox/RadarDisplay
@onready var distance_label: Label = $StreetUI/MiniMapPanel/Margin/VBox/DistanceLabel
@onready var town_map_overlay: PanelContainer = $StreetUI/TownMapOverlay
@onready var close_map_btn: Button = $StreetUI/TownMapOverlay/Margin/VBox/HeaderHBox/CloseMapBtn
@onready var map_canvas: Control = $StreetUI/TownMapOverlay/Margin/VBox/MapCanvas
@onready var prompt_label: Label = $StreetUI/PromptLabel
@onready var subtitle: Label = $StreetUI/Subtitle
@onready var dialogue_box: PanelContainer = $StreetUI/DialogueBox
@onready var speaker_label: Label = $StreetUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_text: Label = $StreetUI/DialogueBox/Margin/VBox/DialogueText
@onready var advance_tip: Label = $StreetUI/DialogueBox/Margin/VBox/AdvanceTip
@onready var next_chapter_card: ColorRect = $StreetUI/NextChapterCard
@onready var start_police_btn: Button = $StreetUI/NextChapterCard/Margin/VBox/BtnBox/StartPoliceBtn
@onready var replay_street_btn: Button = $StreetUI/NextChapterCard/Margin/VBox/BtnBox/ReplayStreetBtn

# --- Preloaded Audio Streams ---
var stream_storm_ambience: AudioStream = preload("res://audio/storm_rain_wind.wav")
var stream_thunder_strike: AudioStream = preload("res://audio/thunder_strike.wav")
var stream_thunder_distant: AudioStream = preload("res://audio/thunder_distant.wav")
var stream_cycle_bell: AudioStream = preload("res://audio/cycle_bell.wav")
var stream_cycle_riding: AudioStream = preload("res://audio/cycle_riding.wav")

var stream_sahil_warning: AudioStream = preload("res://audio/storm_sahil_warning.mp3")
var stream_aashu_hurry: AudioStream = preload("res://audio/storm_aashu_hurry.mp3")
var stream_player_go: AudioStream = preload("res://audio/storm_player_go.mp3")

var stream_mummy_1: AudioStream = preload("res://audio/mummy_line_1.mp3")
var stream_player_talk: AudioStream = preload("res://audio/player_talk_mummy.mp3")
var stream_sahil_talk: AudioStream = preload("res://audio/sahil_talk_mummy.mp3")
var stream_aashu_talk: AudioStream = preload("res://audio/aashu_talk_mummy.mp3")
var stream_mummy_crying: AudioStream = preload("res://audio/mummy_crying.mp3")
var stream_player_comfort: AudioStream = preload("res://audio/player_comfort_mummy.mp3")
var stream_sahil_police: AudioStream = preload("res://audio/sahil_police_plan.mp3")

# --- Movement Variables ---
const CYCLE_SPEED: float = 9.8
const SPRINT_CYCLE_SPEED: float = 14.5
const ACCEL: float = 14.0
const MOUSE_SENSITIVITY: float = 0.0028
var gravity: float = 9.8

var camera_rot_x: float = 0.0
var is_third_person: bool = true
var is_flashlight_on: bool = true
var cycle_bob_timer: float = 0.0
var cycle_tilt: float = 0.0

# --- State Variables ---
var is_cycling: bool = true
var is_near_door: bool = false
var cutscene_active: bool = false
var door_opened: bool = false
var dialogue_in_progress: bool = false
var dialogue_index: int = 0
var can_advance_dialogue: bool = false
var pulse_time: float = 0.0
var is_town_map_open: bool = false

# Lightning System
var lightning_timer: float = 4.0
var is_lightning_flashing: bool = false

# Pedestrians patrol speed
var ped1_z_speed: float = -1.4
var ped2_z_speed: float = 1.3

# All Town Landmarks (Coordinates in world space)
var landmarks = {
	"school": {"name": "सेंट ऑगस्टीन स्कूल (ST. AUGUSTINE)", "pos": Vector3(0, 0, 16), "color": Color(0.2, 0.7, 1.0)},
	"sahil": {"name": "साहिल निवास", "pos": Vector3(-11, 0, -20), "color": Color(1.0, 0.75, 0.2)},
	"player": {"name": "मेरा घर", "pos": Vector3(11, 0, -35), "color": Color(0.3, 0.9, 0.4)},
	"aashu": {"name": "आशुतोष का घर", "pos": Vector3(-11, 0, -52), "color": Color(0.85, 0.45, 1.0)},
	"police": {"name": "पानसेमल पुलिस थाना", "pos": Vector3(11.5, 0, -66), "color": Color(0.2, 0.5, 1.0)},
	"kripal": {"name": "कृपाल निवास", "pos": Vector3(0, 0, -78), "color": Color(1.0, 0.25, 0.25)}
}

# 100% Spoken Hindi Dialogue with Kripal's Mother
var dialogues = [
	{
		"speaker": "👩 कृपाल की माँ (KRIPAL'S MOTHER)",
		"text": "अरे बेटा, तुम सब इतनी रात को यहाँ? क्या बात है? और कृपाल कहाँ है? वो तो तुम लोगों के साथ ही स्कूल में था ना?",
		"audio": null,
		"color": Color(1.0, 0.75, 0.4, 1.0)
	},
	{
		"speaker": "👤 खिलाड़ी (YOU / PLAYER)",
		"text": "आंटी जी... कृपाल के साथ बहुत भयानक हादसा हुआ है! क्लासरूम में एक अजीब खौफनाक साया आया और वो कृपाल को घसीट कर गायब कर ले गया!",
		"audio": null,
		"color": Color(0.3, 0.9, 1.0, 1.0)
	},
	{
		"speaker": "👦 साहिल (SAHIL)",
		"text": "हाँ आंटी, उसकी डेस्क पर खून से लिखा नोट मिला है! कोई तांत्रिक शक्ति उसे उठा ले गई है!",
		"audio": null,
		"color": Color(1.0, 0.75, 0.2, 1.0)
	},
	{
		"speaker": "👓 आशुतोष (AASHUTOSH)",
		"text": "और आंटी, मेरे सेंसर्स ने भी वहाँ बहुत खतरनाक रीडिंग पकड़ी थी... कोई शैतानी ताकत थी वहाँ!",
		"audio": null,
		"color": Color(1.0, 0.5, 0.2, 1.0)
	},
	{
		"speaker": "👩 कृपाल की माँ (KRIPAL'S MOTHER) 😭 [रोते हुए]",
		"text": "हे भगवान! नहीं... मेरा कृपाल! हे ईश्वर, मेरे बच्चे के साथ क्या हो गया?! (रोते हुए) मेरा बेटा कहाँ चला गया... मुझे मेरे कृपाल को ला दो बच्चों... हे भगवान, मैं क्या करूँ!",
		"audio": null,
		"color": Color(1.0, 0.4, 0.4, 1.0)
	},
	{
		"speaker": "👤 खिलाड़ी (YOU / PLAYER) 🗣️ [ढांढस बंधाते हुए]",
		"text": "आंटी जी, आप रोइए मत! बिल्कुल मत घबराइए... हम सब अभी तुरंत पानसेमल पुलिस स्टेशन चलते हैं और रिपोर्ट लिखवाते हैं! हम कृपाल को सही-सलामत वापस लाएँगे!",
		"audio": null,
		"color": Color(0.3, 0.9, 1.0, 1.0)
	},
	{
		"speaker": "👦 साहिल (SAHIL) 🗣️ [दृढ़ निश्चय]",
		"text": "हाँ आंटी, चलो देर मत करो! सब लोग पानसेमल पुलिस थाने चलो!",
		"audio": null,
		"color": Color(1.0, 0.75, 0.2, 1.0)
	}
]

func _ready() -> void:
	dialogues[0]["audio"] = stream_mummy_1
	dialogues[1]["audio"] = stream_player_talk
	dialogues[2]["audio"] = stream_sahil_talk
	dialogues[3]["audio"] = stream_aashu_talk
	dialogues[4]["audio"] = stream_mummy_crying
	dialogues[5]["audio"] = stream_player_comfort
	dialogues[6]["audio"] = stream_sahil_police
	
	# Start in 3rd person by default so user sees the bicycle & characters immediately
	is_third_person = true
	update_camera_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Start Storm & Rain Ambience loop
	if ambience_audio and stream_storm_ambience:
		ambience_audio.stream = stream_storm_ambience
		ambience_audio.volume_db = -6.0
		ambience_audio.play()
		
	if view_toggle_btn:
		view_toggle_btn.pressed.connect(toggle_camera_mode)
	if map_toggle_btn:
		map_toggle_btn.pressed.connect(toggle_town_map)
	if close_map_btn:
		close_map_btn.pressed.connect(toggle_town_map)
	if start_police_btn:
		start_police_btn.pressed.connect(_on_start_police_pressed)
	if replay_street_btn:
		replay_street_btn.pressed.connect(_on_replay_street_pressed)
		
	if radar_display:
		radar_display.draw.connect(_on_radar_draw)
	if map_canvas:
		map_canvas.draw.connect(_on_map_canvas_draw)
		
	if door_trigger:
		door_trigger.body_entered.connect(_on_door_trigger_entered)
		door_trigger.body_exited.connect(_on_door_trigger_exited)
		
	if prompt_label: prompt_label.visible = false
	if dialogue_box: dialogue_box.visible = false
	if next_chapter_card: next_chapter_card.visible = false
	if town_map_overlay: town_map_overlay.visible = false
	if kripal_mummy: kripal_mummy.visible = false
	if lightning_flash_ui: lightning_flash_ui.color.a = 0.0
	
	# Initial positioning at St. Augustine School Gate facing street (-Z)
	player.global_position = Vector3(0, 0.1, 10.5)
	player.rotation.y = 0.0
	sahil.global_position = Vector3(-1.6, 0.1, 10.5)
	sahil.rotation.y = 0.0
	aashutosh.global_position = Vector3(1.6, 0.1, 10.5)
	aashutosh.rotation.y = 0.0
	
	# Start Opening Stormy School Departure Sequence
	start_school_exit_intro()

func start_school_exit_intro() -> void:
	cutscene_active = true
	objective_banner.text = "✦ सेंट ऑगस्टीन स्कूल, पानसेमल से प्रस्थान • तूफान और तेज बिजलियां!"
	
	# Cinematic camera: in front of boys looking back at St. Augustine School!
	visual_model.visible = true
	camera.position = Vector3(0, 1.35, -4.6)
	camera.rotation_degrees = Vector3(-6.0, 180.0, 0.0)
	
	# Initial lightning strike illuminates St. Augustine School in background
	await get_tree().create_timer(0.4).timeout
	trigger_lightning(true)
	
	# Sahil warns about weather
	await get_tree().create_timer(1.0).timeout
	if voice_audio and stream_sahil_warning:
		voice_audio.stop()
		voice_audio.stream = stream_sahil_warning
		voice_audio.play()
	show_subtitle("👦 साहिल: 'मौसम अचानक कितना भयानक हो गया है... आसमान में बिजलियां कड़क रही हैं!'", 3.2)
	
	# Aashutosh urgency
	await get_tree().create_timer(3.4).timeout
	if voice_audio and stream_aashu_hurry:
		voice_audio.stop()
		voice_audio.stream = stream_aashu_hurry
		voice_audio.play()
	show_subtitle("👓 आशुतोष: 'हाँ भाई, जल्दी साइकिल पे बैठो! तूफान आने से पहले कृपाल के घर पहुँचना है!'", 3.5)
	
	# Player gives go signal
	await get_tree().create_timer(3.7).timeout
	if voice_audio and stream_player_go:
		voice_audio.stop()
		voice_audio.stream = stream_player_go
		voice_audio.play()
	show_subtitle("👤 खिलाड़ी: 'चलो भाइयो, तेजी से साइकिल चलाओ! [W, A, S, D से साइकिल चलाएं | B से घंटी बजाएं]'", 3.2)
	
	await get_tree().create_timer(2.6).timeout
	
	# Smooth camera sweep to 3rd person riding position behind the player
	var cam_tw = create_tween().set_parallel(true)
	cam_tw.tween_property(camera, "position", Vector3(0, 0.75, 3.4), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	cam_tw.tween_property(camera, "rotation_degrees", Vector3.ZERO, 1.4).set_trans(Tween.TRANS_QUAD)
	
	await cam_tw.finished
	cutscene_active = false
	objective_banner.text = "🚲 मिशन: तीनों दोस्त साइकिल से कृपाल के घर की ओर बढ़ें [W, A, S, D | SHIFT तेज | B घंटी]"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not cutscene_active and not is_town_map_open:
			player.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera_rot_x -= event.relative.y * MOUSE_SENSITIVITY
			camera_rot_x = clamp(camera_rot_x, -deg_to_rad(75), deg_to_rad(75))
			camera_pivot.rotation.x = camera_rot_x
			
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_town_map_open:
				toggle_town_map()
			elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				
		elif event.keycode == KEY_V:
			toggle_camera_mode()
			
		elif event.keycode == KEY_M:
			toggle_town_map()
			
		elif event.keycode == KEY_B:
			ring_cycle_bell()
			
		elif event.keycode == KEY_F:
			is_flashlight_on = !is_flashlight_on
			if flashlight: flashlight.visible = is_flashlight_on
				
		elif event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
			if is_near_door and not cutscene_active:
				start_door_interaction()
			elif dialogue_in_progress and can_advance_dialogue:
				advance_dialogue()
				
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_town_map_open: return
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and not next_chapter_card.visible and not is_town_map_open:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
		if is_near_door and not cutscene_active:
			start_door_interaction()
		elif dialogue_in_progress and can_advance_dialogue:
			advance_dialogue()
		elif not cutscene_active and not is_town_map_open:
			ring_cycle_bell()

func ring_cycle_bell() -> void:
	if bell_audio and stream_cycle_bell:
		bell_audio.pitch_scale = randf_range(0.96, 1.04)
		bell_audio.play()
	show_subtitle("🔔 [साइकिल की घंटी: ट्रिन-ट्रिन!]", 1.2)

func _process(delta: float) -> void:
	# Lightning Storm Controller
	lightning_timer -= delta
	if lightning_timer <= 0.0 and not is_lightning_flashing:
		lightning_timer = randf_range(4.5, 9.0)
		var is_close: bool = (randf() < 0.4)
		trigger_lightning(is_close)

func trigger_lightning(is_close: bool = false) -> void:
	if is_lightning_flashing: return
	is_lightning_flashing = true
	
	# Sound
	if thunder_audio:
		thunder_audio.stream = stream_thunder_strike if is_close else stream_thunder_distant
		thunder_audio.pitch_scale = randf_range(0.9, 1.1)
		thunder_audio.volume_db = 4.0 if is_close else 0.0
		thunder_audio.play()
		
	# Lightning flash sequence (burst 1 -> dip -> burst 2 -> fade)
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
		
	if is_close and camera and not cutscene_active:
		var base_y = camera.position.y
		var cam_tw = create_tween()
		cam_tw.tween_property(camera, "position:y", base_y + 0.08, 0.04)
		cam_tw.tween_property(camera, "position:y", base_y - 0.06, 0.04)
		cam_tw.tween_property(camera, "position:y", base_y, 0.08)
		
	await tw.finished
	is_lightning_flashing = false

func _physics_process(delta: float) -> void:
	pulse_time += delta
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
		if cycle_audio and cycle_audio.playing:
			cycle_audio.stop()
		return
		
	# Check if reached Kripal's house front yard gate
	if player.global_position.z <= -68.0 and is_cycling:
		is_cycling = false
		objective_banner.text = "✦ कृपाल निवास पहुँच गए! साइकिल खड़ी करके सामने वाले दरवाजे की घंटी [E] बजाएं"
		show_subtitle("🚲 [साइकिल पार्क की]... सामने कृपाल का घर है, दरवाजे पर जाएँ और डोरबेल बजाएं!", 4.0)
		
	# WASD Bicycle Riding Movement
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
		
		# Cycle Riding Sound
		if cycle_audio:
			if not cycle_audio.playing:
				cycle_audio.play()
			cycle_audio.pitch_scale = lerp(0.85, 1.45, player.velocity.length() / SPRINT_CYCLE_SPEED)
			
		# Cycle pedaling bobbing & banking tilt
		cycle_bob_timer += delta * (16.0 if is_sprinting else 10.0)
		var target_tilt = -input_dir.x * 0.14
		cycle_tilt = lerp(cycle_tilt, target_tilt, 8.0 * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, ACCEL * 1.8 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, ACCEL * 1.8 * delta)
		cycle_tilt = lerp(cycle_tilt, 0.0, 10.0 * delta)
		if cycle_audio and cycle_audio.playing:
			cycle_audio.stop()
			
	# Apply cycle tilt and pedaling bob to VisualModel
	if visual_model:
		visual_model.rotation.z = cycle_tilt
		var ped_bob = sin(cycle_bob_timer) * 0.03 if direction != Vector3.ZERO else 0.0
		visual_model.position.y = ped_bob
		
	player.move_and_slide()
	
	# Companions ride bicycles alongside player
	_update_companions(delta, direction)

func _update_companions(delta: float, player_dir: Vector3) -> void:
	if not sahil or not aashutosh or not player: return
	
	# Position Sahil on Left (-1.6m), Aashutosh on Right (+1.6m) side-by-side with player
	var p_trans: Transform3D = player.global_transform
	var sahil_target: Vector3 = p_trans.origin - p_trans.basis.x * 1.6 + p_trans.basis.z * 0.15
	var aashu_target: Vector3 = p_trans.origin + p_trans.basis.x * 1.6 + p_trans.basis.z * 0.15
	
	sahil.global_position = sahil.global_position.lerp(sahil_target, 7.0 * delta)
	aashutosh.global_position = aashutosh.global_position.lerp(aashu_target, 7.0 * delta)
	
	# Cycling bobbing animation for companions
	var bob_s: float = sin(cycle_bob_timer) * 0.03 if player_dir != Vector3.ZERO else 0.0
	var bob_a: float = cos(cycle_bob_timer) * 0.03 if player_dir != Vector3.ZERO else 0.0
	sahil.position.y = 0.1 + bob_s
	aashutosh.position.y = 0.1 + bob_a
	
	# Facing direction: companions match player facing
	sahil.rotation.y = lerp_angle(sahil.rotation.y, player.rotation.y, 8.0 * delta)
	aashutosh.rotation.y = lerp_angle(aashutosh.rotation.y, player.rotation.y, 8.0 * delta)

func _process_pedestrians(delta: float) -> void:
	if pedestrian1:
		pedestrian1.position.z += ped1_z_speed * delta
		if pedestrian1.position.z < -65.0:
			pedestrian1.position.z = -65.0
			ped1_z_speed = 1.4
			pedestrian1.rotation.y = deg_to_rad(180)
		elif pedestrian1.position.z > 2.0:
			pedestrian1.position.z = 2.0
			ped1_z_speed = -1.4
			pedestrian1.rotation.y = 0.0
			
	if pedestrian2:
		pedestrian2.position.z += ped2_z_speed * delta
		if pedestrian2.position.z > 2.0:
			pedestrian2.position.z = 2.0
			ped2_z_speed = -1.3
			pedestrian2.rotation.y = 0.0
		elif pedestrian2.position.z < -68.0:
			pedestrian2.position.z = -68.0
			ped2_z_speed = 1.3
			pedestrian2.rotation.y = deg_to_rad(180)

func _update_radar_hud() -> void:
	if not player: return
	var dist: float = player.global_position.distance_to(Vector3(0, 0, -78))
	if distance_label:
		distance_label.text = "📍 कृपाल का घर: %dm" % int(dist)
	if radar_display:
		radar_display.queue_redraw()

func _on_radar_draw() -> void:
	if not radar_display or not player: return
	var size = radar_display.size
	var center = size * 0.5
	var radar_radius = min(size.x, size.y) * 0.48
	
	# Radar background & grid
	radar_display.draw_circle(center, radar_radius, Color(0.04, 0.08, 0.14, 0.9))
	radar_display.draw_arc(center, radar_radius, 0, TAU, 32, Color(0.2, 0.8, 1.0, 0.7), 2.0)
	radar_display.draw_arc(center, radar_radius * 0.66, 0, TAU, 24, Color(0.15, 0.5, 0.7, 0.35), 1.0)
	radar_display.draw_arc(center, radar_radius * 0.33, 0, TAU, 16, Color(0.15, 0.5, 0.7, 0.25), 1.0)
	radar_display.draw_line(Vector2(center.x, center.y - radar_radius), Vector2(center.x, center.y + radar_radius), Color(0.15, 0.5, 0.7, 0.3), 1.0)
	radar_display.draw_line(Vector2(center.x - radar_radius, center.y), Vector2(center.x + radar_radius, center.y), Color(0.15, 0.5, 0.7, 0.3), 1.0)
	
	# Sweep effect
	var sweep_angle = fmod(pulse_time * 2.5, TAU)
	var sweep_end = center + Vector2(cos(sweep_angle), sin(sweep_angle)) * radar_radius
	radar_display.draw_line(center, sweep_end, Color(0.3, 0.9, 1.0, 0.6), 1.5)
	
	var radar_range_m: float = 65.0
	var scale_factor: float = radar_radius / radar_range_m
	var p_pos: Vector3 = player.global_position
	
	var world_to_radar = func(w_pos: Vector3) -> Vector2:
		var dx: float = (w_pos.x - p_pos.x) * scale_factor
		var dz: float = (w_pos.z - p_pos.z) * scale_factor
		return Vector2(center.x + dx, center.y + dz)
		
	# Draw Landmarks on Radar
	for key in landmarks:
		var lm = landmarks[key]
		var r_pos: Vector2 = world_to_radar.call(lm["pos"])
		if center.distance_to(r_pos) < radar_radius - 4.0:
			if key == "kripal":
				var pulse: float = (sin(pulse_time * 6.0) + 1.0) * 0.5
				radar_display.draw_circle(r_pos, 5.0 + pulse * 2.0, Color(1.0, 0.2, 0.2, 1.0))
				radar_display.draw_circle(r_pos, 2.5, Color(1.0, 1.0, 0.8, 1.0))
			elif key == "police":
				var p_color: Color = Color(1.0, 0.1, 0.1) if sin(pulse_time * 8.0) > 0 else Color(0.1, 0.4, 1.0)
				radar_display.draw_circle(r_pos, 4.0, p_color)
			elif key == "school":
				radar_display.draw_circle(r_pos, 4.2, Color(0.3, 0.75, 1.0, 1.0))
			else:
				radar_display.draw_circle(r_pos, 3.8, lm["color"])
				
	# Trees
	if trees_parent:
		for tree in trees_parent.get_children():
			var r_tree: Vector2 = world_to_radar.call(tree.global_position)
			if center.distance_to(r_tree) < radar_radius - 2.0:
				radar_display.draw_circle(r_tree, 2.8, Color(0.2, 0.85, 0.3, 0.7))
				
	# Pedestrians
	if pedestrian1:
		var r_ped1: Vector2 = world_to_radar.call(pedestrian1.global_position)
		if center.distance_to(r_ped1) < radar_radius - 2.0:
			radar_display.draw_circle(r_ped1, 3.2, Color(1.0, 0.85, 0.2, 0.9))
	if pedestrian2:
		var r_ped2: Vector2 = world_to_radar.call(pedestrian2.global_position)
		if center.distance_to(r_ped2) < radar_radius - 2.0:
			radar_display.draw_circle(r_ped2, 3.2, Color(1.0, 0.85, 0.2, 0.9))
			
	# Companions
	if sahil:
		var r_sahil: Vector2 = world_to_radar.call(sahil.global_position)
		if center.distance_to(r_sahil) < radar_radius - 2.0:
			radar_display.draw_circle(r_sahil, 3.5, Color(1.0, 0.75, 0.2, 1.0))
	if aashutosh:
		var r_aashu: Vector2 = world_to_radar.call(aashutosh.global_position)
		if center.distance_to(r_aashu) < radar_radius - 2.0:
			radar_display.draw_circle(r_aashu, 3.5, Color(0.85, 0.45, 1.0, 1.0))
			
	# Player Arrow
	var p_forward: Vector3 = -player.global_transform.basis.z
	var angle: float = atan2(p_forward.x, -p_forward.z)
	var arrow_size: float = 7.0
	var tip: Vector2 = center + Vector2(sin(angle), -cos(angle)) * arrow_size
	var left: Vector2 = center + Vector2(sin(angle + 2.5), -cos(angle + 2.5)) * (arrow_size * 0.7)
	var right: Vector2 = center + Vector2(sin(angle - 2.5), -cos(angle - 2.5)) * (arrow_size * 0.7)
	radar_display.draw_colored_polygon(PackedVector2Array([tip, left, center, right]), Color(0.2, 1.0, 0.4, 1.0))

func toggle_town_map() -> void:
	is_town_map_open = !is_town_map_open
	if town_map_overlay:
		town_map_overlay.visible = is_town_map_open
		if is_town_map_open:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			map_canvas.queue_redraw()
		else:
			if not next_chapter_card.visible:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_map_canvas_draw() -> void:
	if not map_canvas: return
	var size = map_canvas.size
	
	# Blueprint Background grid
	map_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.09, 0.15, 1.0), true)
	for x in range(0, int(size.x), 40):
		map_canvas.draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.12, 0.18, 0.28, 0.3), 1.0)
	for y in range(0, int(size.y), 40):
		map_canvas.draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.12, 0.18, 0.28, 0.3), 1.0)
		
	# Draw Main Road
	var road_center_x = size.x * 0.5
	var road_w = 70.0
	map_canvas.draw_rect(Rect2(road_center_x - road_w*0.5, 20, road_w, size.y - 40), Color(0.18, 0.20, 0.24, 1.0), true)
	map_canvas.draw_line(Vector2(road_center_x, 20), Vector2(road_center_x, size.y - 20), Color(0.9, 0.85, 0.3, 0.8), 2.0)
	
	# Draw Cross Streets
	map_canvas.draw_rect(Rect2(40, 110, size.x - 80, 42), Color(0.16, 0.18, 0.22, 0.9), true)
	map_canvas.draw_rect(Rect2(40, 240, size.x - 80, 42), Color(0.16, 0.18, 0.22, 0.9), true)
	
	# Street Names
	var font = ThemeDB.fallback_font
	map_canvas.draw_string(font, Vector2(road_center_x + 45, 136), "मंदिर मार्ग (TEMPLE RD)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.75, 0.8))
	map_canvas.draw_string(font, Vector2(road_center_x + 45, 266), "स्टेशन मार्ग (STATION RD)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.75, 0.8))
	map_canvas.draw_string(font, Vector2(road_center_x - 14, 50), "पानसेमल मुख्य बाजार मार्ग", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1, 0.9, 0.4))
	
	# Plot Buildings on Town Map
	var town_pts = [
		{"name": "🏫 सेंट ऑगस्टीन स्कूल\n(ST. AUGUSTINE SCHOOL)", "pos": Vector2(road_center_x, 42), "color": Color(0.2, 0.7, 1.0), "size": Vector2(160, 36)},
		{"name": "🏠 साहिल निवास\n(SAHIL'S HOUSE)", "pos": Vector2(road_center_x - 160, 115), "color": Color(1.0, 0.75, 0.2), "size": Vector2(130, 32)},
		{"name": "🏠 मेरा घर\n(PLAYER'S HOUSE)", "pos": Vector2(road_center_x + 160, 175), "color": Color(0.3, 0.9, 0.4), "size": Vector2(130, 32)},
		{"name": "🏠 आशुतोष का घर\n(AASHUTOSH'S HOUSE)", "pos": Vector2(road_center_x - 160, 245), "color": Color(0.85, 0.45, 1.0), "size": Vector2(130, 32)},
		{"name": "🚓 पानसेमल पुलिस थाना\n(POLICE STATION)", "pos": Vector2(road_center_x + 165, 290), "color": Color(0.2, 0.5, 1.0), "size": Vector2(145, 36)},
		{"name": "⭐ कृपाल निवास [TARGET]\n(KRIPAL'S HOUSE)", "pos": Vector2(road_center_x, 340), "color": Color(1.0, 0.25, 0.25), "size": Vector2(150, 36)}
	]
	
	for pt in town_pts:
		var p = pt["pos"]
		var s = pt["size"]
		var rect = Rect2(p.x - s.x * 0.5, p.y - s.y * 0.5, s.x, s.y)
		map_canvas.draw_rect(rect, pt["color"] * 0.35, true)
		map_canvas.draw_rect(rect, pt["color"], false, 2.0)
		map_canvas.draw_string(font, Vector2(rect.position.x + 8, rect.position.y + 16), pt["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		
	# Draw Player Current Position Marker
	var norm_z = clamp((-player.global_position.z + 12.0) / 90.0, 0.0, 1.0)
	var player_map_y = lerp(45.0, 340.0, norm_z)
	var player_pt = Vector2(road_center_x, player_map_y)
	map_canvas.draw_circle(player_pt, 7.0, Color(0.2, 1.0, 0.4, 1.0))
	map_canvas.draw_circle(player_pt, 3.5, Color(1.0, 1.0, 1.0, 1.0))
	map_canvas.draw_string(font, Vector2(player_pt.x + 12, player_pt.y + 4), "◄ आप यहाँ हैं (YOU ARE HERE)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.4))

func toggle_camera_mode() -> void:
	is_third_person = !is_third_person
	update_camera_mode()

func update_camera_mode() -> void:
	if not camera or not visual_model: return
	if is_third_person:
		camera.position = Vector3(0, 0.75, 3.4)
		visual_model.visible = true
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] कैमरा: 3rd Person"
	else:
		camera.position = Vector3(0, 0.35, -0.15)
		visual_model.visible = true # Keep handlebars visible in first person cycling!
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] कैमरा: 1st Person"

func _on_door_trigger_entered(body: Node3D) -> void:
	if body == player and not door_opened:
		is_near_door = true
		if prompt_label: prompt_label.visible = true

func _on_door_trigger_exited(body: Node3D) -> void:
	if body == player:
		is_near_door = false
		if prompt_label and not cutscene_active: prompt_label.visible = false

func start_door_interaction() -> void:
	if cutscene_active: return
	cutscene_active = true
	door_opened = true
	is_near_door = false
	if prompt_label: prompt_label.visible = false
	if is_town_map_open: toggle_town_map()
	if cycle_audio and cycle_audio.playing: cycle_audio.stop()
		
	# Play Doorbell Chime
	if doorbell_audio:
		doorbell_audio.play()
		
	show_subtitle("🔔 [डोरबेल बजी: डिंग-डोंग]... अंदर से किसी के आने की आहट सुनाई दे रही है...", 2.5)
	
	# Position player and companions neatly facing the door
	var tw = create_tween()
	tw.tween_property(player, "global_position", Vector3(0, 0.1, -73.2), 1.2)
	tw.parallel().tween_property(sahil, "global_position", Vector3(-1.4, 0.1, -73.4), 1.2)
	tw.parallel().tween_property(aashutosh, "global_position", Vector3(1.4, 0.1, -73.4), 1.2)
	tw.parallel().tween_property(player, "rotation:y", deg_to_rad(180), 1.2)
	tw.parallel().tween_property(camera_pivot, "rotation:x", deg_to_rad(5), 1.2)
	
	await tw.finished
	
	# Switch to cinematic dialogue camera
	is_third_person = true
	update_camera_mode()
	camera.position = Vector3(0, 0.8, 3.8)
	
	await get_tree().create_timer(1.2).timeout
	
	if home_door_audio:
		home_door_audio.play()
		
	# Swing door open 80 degrees
	var door_tw = create_tween()
	door_tw.tween_property(door_hinge, "rotation_degrees:y", 80.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if kripal_mummy:
		kripal_mummy.visible = true
		kripal_mummy.position.z = -0.6
		var mummy_tw = create_tween()
		mummy_tw.tween_property(kripal_mummy, "position:z", 0.1, 1.2)
		
	await door_tw.finished
	await get_tree().create_timer(0.5).timeout
	
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
		
	# Play full spoken voice line
	if d["audio"] != null and voice_audio:
		voice_audio.stop()
		voice_audio.stream = d["audio"]
		voice_audio.play()
		
	# Dynamic delay based on voice line length
	await get_tree().create_timer(1.2).timeout
	can_advance_dialogue = true
	if advance_tip: advance_tip.text = "[CLICK या E / SPACE दबाएं ▶]"

func advance_dialogue() -> void:
	if not can_advance_dialogue: return
	dialogue_index += 1
	display_current_dialogue()

func end_dialogue_sequence() -> void:
	dialogue_in_progress = false
	if dialogue_box: dialogue_box.visible = false
	if subtitle: subtitle.text = ""
		
	# Show Chapter 1 Mission Card: Pansemal Police Station
	if next_chapter_card:
		next_chapter_card.visible = true
		next_chapter_card.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(next_chapter_card, "modulate:a", 1.0, 0.8)
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
		start_police_btn.text = "🚓 RUSHING TO PANSEMAL POLICE STATION..."
	# -- Load police station interior scene --
	get_tree().change_scene_to_file("res://scenes/police_station.tscn")

func _on_replay_street_pressed() -> void:
	get_tree().reload_current_scene()
