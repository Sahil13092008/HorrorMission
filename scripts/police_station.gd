extends Node3D

# police_station.gd
# Pansemal District Police Station:
# 1. Option to sit down on visitor chair with Aunty in front of Inspector R.K. Sharma.
# 2. Complete dialogue in natural Hindi with audio & official FIR registration.
# 3. Stepping outside: Sahil reassures Aunty ("आंटी आप टेंशन मत लीजिए, पुलिस कृपाल को जरूर ढूंढ निकालेगी!").
# 4. Heading to respective homes, complete blackout, and suspenseful "2 DAYS LATER..." sequence!

@onready var player: Node3D = $Player
@onready var camera_pivot: Node3D = $Player/CameraPivot
@onready var camera: Camera3D = $Player/CameraPivot/Camera3D
@onready var player_visual: Node3D = $Player/VisualModel

@onready var sahil: Node3D = $Characters/Sahil
@onready var aashutosh: Node3D = $Characters/Aashutosh
@onready var kripal_mummy: Node3D = $Characters/KripalMummy
@onready var thanedaar: Node3D = $Characters/Thanedaar
@onready var ceiling_fan_blades: Node3D = $RoomGeometry/CeilingFan/Blades

# Audio
@onready var voice_audio: AudioStreamPlayer = $Audio/VoiceAudio
@onready var fan_buzz_audio: AudioStreamPlayer = $Audio/FanBuzzAudio
@onready var radio_chatter_audio: AudioStreamPlayer = $Audio/RadioChatterAudio
@onready var paper_scribble_audio: AudioStreamPlayer = $Audio/PaperScribbleAudio
@onready var stamp_thud_audio: AudioStreamPlayer = $Audio/StampThudAudio
@onready var door_close_audio: AudioStreamPlayer = $Audio/DoorCloseAudio
@onready var thunder_audio: AudioStreamPlayer = $Audio/ThunderAudio
@onready var suspense_audio: AudioStreamPlayer = $Audio/SuspenseAudio

# UI
@onready var police_ui: CanvasLayer = $PoliceUI
@onready var sit_prompt: Label = $PoliceUI/HUD/SitPrompt
@onready var dialogue_box: PanelContainer = $PoliceUI/DialogueBox
@onready var speaker_label: Label = $PoliceUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_text: Label = $PoliceUI/DialogueBox/Margin/VBox/DialogueText
@onready var advance_tip: Label = $PoliceUI/DialogueBox/Margin/VBox/AdvanceTip
@onready var fir_overlay: Control = $PoliceUI/FIROverlay
@onready var fir_stamp: Label = $PoliceUI/FIROverlay/Panel/Margin/VBox/StampContainer/StampLabel
@onready var mission_card: PanelContainer = $PoliceUI/MissionCompleteCard
@onready var proceed_departure_btn: Button = $PoliceUI/MissionCompleteCard/Margin/VBox/ProceedBtn
@onready var departure_overlay: ColorRect = $PoliceUI/DepartureOverlay
@onready var departure_subtitle: Label = $PoliceUI/DepartureOverlay/Subtitle
@onready var two_days_later_screen: ColorRect = $PoliceUI/TwoDaysLaterScreen
@onready var chapter_end_card: PanelContainer = $PoliceUI/ChapterEndCard
@onready var start_chapter2_btn: Button = $PoliceUI/ChapterEndCard/Margin/VBox/BtnBox/StartCh2Btn
@onready var replay_station_btn: Button = $PoliceUI/ChapterEndCard/Margin/VBox/BtnBox/ReplayBtn
@onready var view_toggle_btn: Button = $PoliceUI/HUD/ViewToggleBtn

# Camera & Settings
var is_first_person: bool = false
var mouse_captured: bool = true
var cam_rot_x: float = 0.0
var cam_rot_y: float = 0.0
const MOUSE_SENSITIVITY: float = 0.0028

# State
var is_seated: bool = false
var dialogue_index: int = 0
var can_advance_dialogue: bool = false
var dialogue_in_progress: bool = false
var cutscene_active: bool = false
var fan_speed: float = 12.0

# Preloaded Audio
var stream_thanedaar_1 = preload("res://audio/police_thanedaar_1.mp3")
var stream_player_1 = preload("res://audio/police_player_1.mp3")
var stream_mummy_1 = preload("res://audio/police_mummy_1.mp3")
var stream_sahil_1 = preload("res://audio/police_sahil_1.mp3")
var stream_aashu_1 = preload("res://audio/police_aashu_1.mp3")
var stream_thanedaar_2 = preload("res://audio/police_thanedaar_2.mp3")
var stream_player_2 = preload("res://audio/police_player_2.mp3")
var stream_sahil_comfort = preload("res://audio/sahil_comfort_aunty.mp3")
var stream_suspense = preload("res://audio/suspense_2days_later.wav")

# Dialogues Array (Pure Hindi Dialogues)
var dialogues = [
	{
		"speaker": "👮 थानेदार आर. के. शर्मा (INSPECTOR SHARMA)",
		"color": Color(1.0, 0.84, 0.3),
		"text": "नमस्ते। बताइए, इतनी रात को आप सब यहाँ किस लिए आए हैं? क्या परेशानी है?",
		"audio": null
	},
	{
		"speaker": "🎒 तू (PLAYER)",
		"color": Color(0.4, 0.9, 1.0),
		"text": "सर, हमारे दोस्त कृपाल का क्लासरूम से शाम को अपहरण हो गया है! वहाँ खून के निशान और यह पर्ची मिली — FIND ME AT BHANGARH!",
		"audio": null
	},
	{
		"speaker": "👩 कृपाल की माँ (KRIPAL'S MOTHER) 😭",
		"color": Color(1.0, 0.45, 0.65),
		"text": "साहब जी, मेरा एक ही बेटा है... वो कल से घर नहीं लौटा। भगवान के लिए कृपया उसे ढूंढिए साहब!",
		"audio": null
	},
	{
		"speaker": "🧢 साहिल (SAHIL)",
		"color": Color(1.0, 0.35, 0.35),
		"text": "सर, यह कोई आम किडनैपिंग नहीं है। पर्ची पर राजस्थान के भानगढ़ किले का ज़िक्र है!",
		"audio": null
	},
	{
		"speaker": "👓 आशुतोष (AASHUTOSH)",
		"color": Color(0.5, 0.7, 1.0),
		"text": "हाँ सर, वहाँ अजीब सी परानॉर्मल ऊर्जा महसूस हो रही थी! कोई सामान्य इंसान ऐसा नहीं कर सकता!",
		"audio": null
	},
	{
		"speaker": "👮 थानेदार आर. के. शर्मा (INSPECTOR SHARMA)",
		"color": Color(1.0, 0.84, 0.3),
		"text": "ठीक है, शांत हो जाइए। हम आपातकालीन गुमशुदगी और अपहरण की FIR दर्ज कर रहे हैं। लेकिन भानगढ़ राजस्थान में है, दूसरे राज्य में टीम सुबह ही रवाना हो पाएगी। अभी आप सब घर जाइए।",
		"audio": null
	},
	{
		"speaker": "🎒 तू (PLAYER)",
		"color": Color(0.4, 0.9, 1.0),
		"text": "ठीक है सर, धन्यवाद। (मन में: पर हम सुबह तक हाथ पर हाथ धरे नहीं बैठ सकते...)",
		"audio": null
	}
]

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	dialogues[0]["audio"] = stream_thanedaar_1
	dialogues[1]["audio"] = stream_player_1
	dialogues[2]["audio"] = stream_mummy_1
	dialogues[3]["audio"] = stream_sahil_1
	dialogues[4]["audio"] = stream_aashu_1
	dialogues[5]["audio"] = stream_thanedaar_2
	dialogues[6]["audio"] = stream_player_2
	
	if proceed_departure_btn:
		proceed_departure_btn.pressed.connect(_on_proceed_departure_pressed)
	if start_chapter2_btn:
		start_chapter2_btn.pressed.connect(_on_start_chapter2_pressed)
	if replay_station_btn:
		replay_station_btn.pressed.connect(_on_replay_station_pressed)
	if view_toggle_btn:
		view_toggle_btn.pressed.connect(toggle_camera_mode)
		
	# UI Initial states
	if dialogue_box: dialogue_box.visible = false
	if fir_overlay: fir_overlay.visible = false
	if mission_card: mission_card.visible = false
	if departure_overlay: departure_overlay.visible = false
	if two_days_later_screen: two_days_later_screen.visible = false
	if chapter_end_card: chapter_end_card.visible = false
	if sit_prompt:
		sit_prompt.visible = true
		sit_prompt.text = "🪑 [E] दबाकर कुर्सी पर बैठें (PRESS [E] TO SIT ON VISITOR CHAIR)"
	
	update_camera_mode()
	
	if fan_buzz_audio: fan_buzz_audio.play()
	if radio_chatter_audio: radio_chatter_audio.play()
	
	# Auto sit down after 3.0s if player doesn't press E
	get_tree().create_timer(8.0).timeout.connect(func():
		if not is_seated:
			sit_down_on_chair()
	)


func _physics_process(delta: float) -> void:
	if is_seated or cutscene_active:
		return
		
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	input_dir = input_dir.normalized()
	
	if input_dir != Vector2.ZERO:
		var move_dir = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var walk_speed: float = 2.4
		player.position.x += move_dir.x * walk_speed * delta
		player.position.z += move_dir.z * walk_speed * delta
		
	# Keep player strictly on floor (Y = 0.0) and inside police office room bounds
	player.position.y = 0.0
	player.position.x = clamp(player.position.x, -4.5, 4.5)
	player.position.z = clamp(player.position.z, -1.8, 4.8)
	
	# Check proximity to visitor chairs
	var dist_to_chair: float = player.position.distance_to(Vector3(0.55, 0, 0.4))
	if dist_to_chair < 1.8:
		if sit_prompt:
			sit_prompt.visible = true
			sit_prompt.text = "🪑 [E] दबाकर कुर्सी पर बैठें (PRESS [E] TO SIT ON VISITOR CHAIR)"
	else:
		if sit_prompt:
			sit_prompt.visible = true
			sit_prompt.text = "🚶 थानेदार की मेज़ के सामने वाली कुर्सी की तरफ बढ़ें और [E] दबाएं"

func _process(delta: float) -> void:
	if ceiling_fan_blades and fan_speed > 0:
		ceiling_fan_blades.rotate_y(fan_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured and not cutscene_active:
		cam_rot_y -= event.relative.x * MOUSE_SENSITIVITY
		cam_rot_x -= event.relative.y * MOUSE_SENSITIVITY
		cam_rot_x = clamp(cam_rot_x, -deg_to_rad(65), deg_to_rad(65))
		
		if player:
			player.rotation.y = cam_rot_y
		if camera_pivot:
			camera_pivot.rotation.x = cam_rot_x

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			toggle_camera_mode()
		elif event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if not is_seated:
				sit_down_on_chair()
			elif dialogue_in_progress and can_advance_dialogue:
				advance_dialogue()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_seated:
			sit_down_on_chair()
		elif dialogue_in_progress and can_advance_dialogue:
			advance_dialogue()

func toggle_camera_mode() -> void:
	is_first_person = not is_first_person
	update_camera_mode()

func update_camera_mode() -> void:
	if not camera: return
	if is_first_person:
		camera.position = Vector3(0, 0, 0)
		camera.rotation = Vector3.ZERO
		if player_visual: player_visual.visible = false
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] VIEW: 1ST PERSON"
	else:
		camera.position = Vector3(0, 0.2, 1.6)
		camera.rotation = Vector3(deg_to_rad(-6.0), 0, 0)
		if player_visual: player_visual.visible = true
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] VIEW: 3RD PERSON"

func sit_down_on_chair() -> void:
	if is_seated: return
	is_seated = true
	if sit_prompt: sit_prompt.visible = false
	
	# Smoothly seat player on right visitor chair and Aunty on left visitor chair
	var tw = create_tween()
	# Player sits on right chair at (0.55, 0.0, 0.4)
	tw.parallel().tween_property(player, "position", Vector3(0.55, 0.0, 0.4), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Lower camera pivot to seated eye height (Y = 1.05m)
	if camera_pivot:
		tw.parallel().tween_property(camera_pivot, "position:y", 1.05, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Aunty sits on left chair at (-0.55, 0.0, 0.4)
	tw.parallel().tween_property(kripal_mummy, "position", Vector3(-0.55, 0.0, 0.4), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Sahil and Aashutosh stand behind chairs
	tw.parallel().tween_property(sahil, "position", Vector3(-1.1, 0.0, 1.0), 0.8)
	tw.parallel().tween_property(aashutosh, "position", Vector3(1.1, 0.0, 1.0), 0.8)
	
	await tw.finished
	start_dialogue_sequence()

func start_dialogue_sequence() -> void:
	dialogue_in_progress = true
	dialogue_index = 0
	if dialogue_box:
		dialogue_box.visible = true
		dialogue_box.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(dialogue_box, "modulate:a", 1.0, 0.5)
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
		
	if dialogue_index == 5:
		trigger_fir_filing_fx()
		
	await get_tree().create_timer(0.6).timeout
	can_advance_dialogue = true

func advance_dialogue() -> void:
	if not can_advance_dialogue: return
	dialogue_index += 1
	display_current_dialogue()

func trigger_fir_filing_fx() -> void:
	if paper_scribble_audio:
		paper_scribble_audio.play()
		
	if fir_overlay:
		fir_overlay.visible = true
		fir_overlay.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(fir_overlay, "modulate:a", 1.0, 0.6)
		
	await get_tree().create_timer(1.4).timeout
	if stamp_thud_audio:
		stamp_thud_audio.play()
	if fir_stamp:
		fir_stamp.visible = true
		fir_stamp.scale = Vector2(2.5, 2.5)
		fir_stamp.modulate.a = 0.0
		var stamp_tw = create_tween()
		stamp_tw.parallel().tween_property(fir_stamp, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		stamp_tw.parallel().tween_property(fir_stamp, "modulate:a", 1.0, 0.2)

func end_dialogue_sequence() -> void:
	dialogue_in_progress = false
	if dialogue_box: dialogue_box.visible = false
	
	if mission_card:
		mission_card.visible = true
		mission_card.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(mission_card, "modulate:a", 1.0, 0.8)
		
	mouse_captured = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_proceed_departure_pressed() -> void:
	if proceed_departure_btn:
		proceed_departure_btn.disabled = true
	if mission_card:
		mission_card.visible = false
	if fir_overlay:
		fir_overlay.visible = false
		
	start_departure_cutscene()

func start_departure_cutscene() -> void:
	cutscene_active = true
	
	# Sound of station door closing
	if door_close_audio:
		door_close_audio.play()
		
	# Transition to street outside police station
	if departure_overlay:
		departure_overlay.visible = true
		departure_overlay.modulate.a = 0.0
		var fade_tw = create_tween()
		fade_tw.tween_property(departure_overlay, "modulate:a", 0.95, 0.8)
		await fade_tw.finished
		
	if thunder_audio:
		thunder_audio.play()
		
	# Sahil comforts Aunty: "आंटी आप टेंशन मत लीजिए, पुलिस कृपाल को जरूर ढूंढ निकालेगी!"
	if departure_subtitle:
		departure_subtitle.visible = true
		departure_subtitle.text = "🧢 साहिल: 'आंटी आप टेंशन मत लीजिए, पुलिस कृपाल को जरूर ढूंढ निकालेगी!'"
		
	if voice_audio and stream_sahil_comfort:
		voice_audio.stop()
		voice_audio.stream = stream_sahil_comfort
		voice_audio.play()
		await voice_audio.finished
	else:
		await get_tree().create_timer(3.5).timeout
		
	# Everyone disperses to their respective homes
	if departure_subtitle:
		departure_subtitle.text = "सब अपने-अपने घर चले जाते हैं... (साहिल अपने घर, आशुतोष अपने घर, और तू अपने घर)..."
	await get_tree().create_timer(3.5).timeout
	
	# Trigger the suspenseful "2 DAYS LATER..." Black Screen!
	trigger_2_days_later_sequence()

func trigger_2_days_later_sequence() -> void:
	if departure_overlay:
		departure_overlay.visible = false
		
	if two_days_later_screen:
		two_days_later_screen.visible = true
		two_days_later_screen.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(two_days_later_screen, "modulate:a", 1.0, 1.2)
		
	# Play deep suspense atmosphere
	if suspense_audio:
		suspense_audio.play()
		
	# Wait 4.5 seconds for dramatic suspense
	await get_tree().create_timer(4.5).timeout
	
	# Show Chapter End Card
	if chapter_end_card:
		chapter_end_card.visible = true
		chapter_end_card.modulate.a = 0.0
		var end_tw = create_tween()
		end_tw.tween_property(chapter_end_card, "modulate:a", 1.0, 0.8)

func _on_start_chapter2_pressed() -> void:
	if start_chapter2_btn:
		start_chapter2_btn.disabled = true
		start_chapter2_btn.text = "➔ LOADING CHAPTER 2: BHANGARH RUINS..."
	get_tree().change_scene_to_file("res://scenes/bhangarh_ruins.tscn")

func _on_replay_station_pressed() -> void:
	get_tree().reload_current_scene()
