extends Node3D

# police_station.gd
# Pansemal District Police Station: Emergency FIR sequence, dialogue with Inspector R.K. Sharma,
# official registration of Kripal's abduction, and the midnight departure plan to Bhangarh.

# Strict Rules:
# - Posters, Buttons, Objectives, Alerts: 100% English
# - Dialogues, Subtitles, Voice Audio: Natural Hindi
# - [V] Toggle 1st Person & 3rd Person View

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

# UI
@onready var police_ui: CanvasLayer = $PoliceUI
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
@onready var chapter_end_card: PanelContainer = $PoliceUI/ChapterEndCard
@onready var start_chapter2_btn: Button = $PoliceUI/ChapterEndCard/Margin/VBox/BtnBox/StartCh2Btn
@onready var replay_station_btn: Button = $PoliceUI/ChapterEndCard/Margin/VBox/BtnBox/ReplayBtn
@onready var view_toggle_btn: Button = $PoliceUI/HUD/ViewToggleBtn

# Camera & Settings
var is_first_person: bool = true
var mouse_captured: bool = true
var cam_rot_x: float = 0.0
var cam_rot_y: float = 0.0
const MOUSE_SENSITIVITY: float = 0.0028

# State
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
var stream_sahil_plan = preload("res://audio/police_sahil_night_plan.mp3")

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
	
	# Connect UI buttons
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
	if chapter_end_card: chapter_end_card.visible = false
	
	update_camera_mode()
	
	# Start ambient electric fan and radio
	if fan_buzz_audio: fan_buzz_audio.play()
	if radio_chatter_audio: radio_chatter_audio.play()
	
	# Start scene sequence after brief walk-in
	start_police_sequence()

func _process(delta: float) -> void:
	# Rotate ceiling fan
	if ceiling_fan_blades and fan_speed > 0:
		ceiling_fan_blades.rotate_y(fan_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look when captured and not in modal UI
	if event is InputEventMouseMotion and mouse_captured and not cutscene_active:
		cam_rot_y -= event.relative.x * MOUSE_SENSITIVITY
		cam_rot_x -= event.relative.y * MOUSE_SENSITIVITY
		cam_rot_x = clamp(cam_rot_x, -deg_to_rad(65), deg_to_rad(65))
		
		if player:
			player.rotation.y = cam_rot_y
		if camera_pivot:
			camera_pivot.rotation.x = cam_rot_x

	# Toggle 1st / 3rd Person camera with [V]
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			toggle_camera_mode()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_E or event.keycode == KEY_ENTER:
			if dialogue_in_progress and can_advance_dialogue:
				advance_dialogue()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_in_progress and can_advance_dialogue:
			advance_dialogue()

func toggle_camera_mode() -> void:
	is_first_person = not is_first_person
	update_camera_mode()

func update_camera_mode() -> void:
	if not camera: return
	if is_first_person:
		camera.position = Vector3(0, 1.55, 0.0)
		if player_visual: player_visual.visible = false
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] VIEW: 1ST PERSON"
	else:
		camera.position = Vector3(0, 1.75, 2.6)
		if player_visual: player_visual.visible = true
		if view_toggle_btn: view_toggle_btn.text = "👁️ [V] VIEW: 3RD PERSON"

func start_police_sequence() -> void:
	await get_tree().create_timer(1.2).timeout
	# Inspector Sharma looks up and starts dialogue
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
		
	# Play matching voice line
	if voice_audio and d["audio"]:
		voice_audio.stop()
		voice_audio.stream = d["audio"]
		voice_audio.play()
		
	# Trigger special FX on specific dialogue lines
	if dialogue_index == 5:
		# Line 6: Thanedaar files FIR -> writing SFX and FIR Overlay + Stamp!
		trigger_fir_filing_fx()
		
	await get_tree().create_timer(0.6).timeout
	can_advance_dialogue = true

func advance_dialogue() -> void:
	if not can_advance_dialogue: return
	dialogue_index += 1
	display_current_dialogue()

func trigger_fir_filing_fx() -> void:
	# Scribble SFX
	if paper_scribble_audio:
		paper_scribble_audio.play()
		
	# Slide in FIR Document
	if fir_overlay:
		fir_overlay.visible = true
		fir_overlay.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(fir_overlay, "modulate:a", 1.0, 0.6)
		
	# After 1.4s, slam stamp down!
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
	
	# Show Chapter 1 Part III Mission Complete Card
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
		
	# Start Departure Cutscene (Outside Police Station)
	start_departure_cutscene()

func start_departure_cutscene() -> void:
	cutscene_active = true
	
	# Sound of station door closing
	if door_close_audio:
		door_close_audio.play()
		
	# Fade screen to dark night street
	if departure_overlay:
		departure_overlay.visible = true
		departure_overlay.modulate.a = 0.0
		var fade_tw = create_tween()
		fade_tw.tween_property(departure_overlay, "modulate:a", 0.95, 0.8)
		await fade_tw.finished
		
	# Distant thunder
	if thunder_audio:
		thunder_audio.play()
		
	# Sahil's night departure plan voice & text
	if departure_subtitle:
		departure_subtitle.visible = true
		departure_subtitle.text = "🧢 साहिल: \"पुलिस सुबह जाएगी, पर कृपाल के पास इतना वक्त नहीं हो सकता! चलो, सब अपने-अपने घर जाओ, जरूरी सामान (टॉर्च, कैमरा, बैटरी, फर्स्ट एड) पैक करो। हम आधे घंटे में मेरी गाड़ी के पास मिलते हैं और आज रात ही भानगढ़ निकलेंगे!\""
		
	if voice_audio and stream_sahil_plan:
		voice_audio.stop()
		voice_audio.stream = stream_sahil_plan
		voice_audio.play()
		await voice_audio.finished
	else:
		await get_tree().create_timer(7.5).timeout
		
	# Narrative line: Leaving for home to pack
	if departure_subtitle:
		departure_subtitle.text = "रात 11:30 बजे... तीनों दोस्त अपनी-अपनी साइकिलों पर घर की ओर रवाना होते हैं... बैग पैक करके आज रात ही भानगढ़ निकलना होगा..."
	await get_tree().create_timer(3.5).timeout
	
	# Show final Chapter 1 Completion & Chapter 2 Unlock Card
	if chapter_end_card:
		chapter_end_card.visible = true
		chapter_end_card.modulate.a = 0.0
		var end_tw = create_tween()
		end_tw.tween_property(chapter_end_card, "modulate:a", 1.0, 0.8)

func _on_start_chapter2_pressed() -> void:
	if start_chapter2_btn:
		start_chapter2_btn.disabled = true
		start_chapter2_btn.text = "➔ LOADING CHAPTER 2: BHANGARH RUINS..."
	# Transitions to Bhangarh Ruins (Chapter 2)
	get_tree().change_scene_to_file("res://scenes/bhangarh_ruins.tscn")

func _on_replay_station_pressed() -> void:
	get_tree().reload_current_scene()
