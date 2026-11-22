extends Node3D

@onready var camera = $CutsceneCamera
@onready var flashlight = $CutsceneCamera/Flashlight
@onready var floor_lantern = $FloorLantern
@onready var kripal_model = $KripalModel
@onready var ghost_entity = $GhostEntity
@onready var ghost_eyes = $GhostEntity/GhostHead/EyeLight

# Audio Players
@onready var ambience_audio = $Audio/AmbienceAudio
@onready var voice_audio = $Audio/VoiceAudio
@onready var whisper_audio = $Audio/WhisperAudio
@onready var footstep_audio = $Audio/FootstepAudio
@onready var scream_audio = $Audio/ScreamAudio
@onready var heartbeat_audio = $Audio/HeartbeatAudio

# Cutscene UI
@onready var cutscene_ui = $CutsceneUI
@onready var blink_overlay = $CutsceneUI/BlinkOverlay
@onready var subtitle = $CutsceneUI/Subtitle
@onready var jumpscare_overlay = $CutsceneUI/JumpscareOverlay
@onready var ghost_face = $CutsceneUI/JumpscareOverlay/GhostFace
@onready var signal_lost_card = $CutsceneUI/SignalLostCard
@onready var continue_btn = $CutsceneUI/SignalLostCard/Margin/VBox/ContinueBtn

var voice_wake_1 = preload("res://audio/kripal_wake_1.mp3")
var voice_wake_2 = preload("res://audio/kripal_wake_2.mp3")
var voice_freeze = preload("res://audio/kripal_freeze.mp3")

var camera_shake_trauma: float = 0.0
var original_cam_pos: Vector3 = Vector3.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initial cutscene setup
	jumpscare_overlay.visible = false
	signal_lost_card.visible = false
	ghost_entity.visible = false
	
	# Kripal lying flat unconscious on cold stone floor
	kripal_model.position = Vector3(0.0, 0.15, 0.0)
	kripal_model.rotation_degrees = Vector3(0.0, 90.0, 85.0)
	
	# Camera on ground level in front-side of Kripal looking at him
	camera.position = Vector3(1.1, 0.55, 1.4)
	camera.look_at(Vector3(0.0, 0.25, 0.0), Vector3.UP)
	original_cam_pos = camera.position
	
	# Blink overlay covers screen initially in black
	blink_overlay.visible = true
	blink_overlay.modulate.a = 1.0
	
	if continue_btn:
		continue_btn.pressed.connect(on_continue_clicked)

	# Start cinematic horror sequence
	start_bhangarh_cutscene()

func _process(delta):
	# Camera trauma shake processing
	if camera_shake_trauma > 0:
		camera_shake_trauma = max(0, camera_shake_trauma - delta * 0.8)
		var shake = camera_shake_trauma * camera_shake_trauma
		camera.position = original_cam_pos + Vector3(
			randf_range(-1.0, 1.0) * shake * 0.45,
			randf_range(-1.0, 1.0) * shake * 0.45,
			0.0
		)
		camera.rotation_degrees.z = randf_range(-1.0, 1.0) * shake * 12.0

func start_bhangarh_cutscene():
	# 1. Groggily waking up in pitch darkness
	subtitle.text = "..."
	await get_tree().create_timer(0.8).timeout
	
	# Realistic eyelid blinking: open slightly, close, then open fully
	var blink_tw = create_tween()
	blink_tw.tween_property(blink_overlay, "modulate:a", 0.4, 0.5)
	blink_tw.tween_property(blink_overlay, "modulate:a", 0.8, 0.3)
	blink_tw.tween_property(blink_overlay, "modulate:a", 0.0, 0.8)
	await blink_tw.finished
	blink_overlay.visible = false

	await get_tree().create_timer(0.3).timeout

	# 1st dialogue: Groggy awakening while lying down
	subtitle.text = "कृपाल: \"अरे... मेरा सिर बहुत दर्द कर रहा है... मैं कहाँ आ गया?!\""
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))

	if voice_audio and voice_wake_1:
		voice_audio.stream = voice_wake_1
		voice_audio.play()
		await voice_audio.finished

	await get_tree().create_timer(0.4).timeout

	# 2. Kripal stands up and camera rises into dramatic over-the-shoulder view
	var rise_tw = create_tween().set_parallel(true)
	rise_tw.tween_property(kripal_model, "position:y", 0.0, 2.0).set_trans(Tween.TRANS_QUAD)
	rise_tw.tween_property(kripal_model, "rotation_degrees", Vector3(0.0, 180.0, 0.0), 2.0).set_trans(Tween.TRANS_QUAD)
	rise_tw.tween_property(camera, "position", Vector3(0.35, 1.55, 1.4), 2.0).set_trans(Tween.TRANS_QUAD)
	rise_tw.tween_property(camera, "rotation_degrees", Vector3(-4.0, 0.0, 0.0), 2.0).set_trans(Tween.TRANS_QUAD)
	
	await rise_tw.finished
	original_cam_pos = camera.position

	# Looking around confused at the ancient pillars and shadows
	subtitle.text = "कृपाल: \"ये... ये कैसी जगह है? चारों तरफ सिर्फ अंधेरा और पुराने पत्थर हैं...\""
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	
	# Kripal turns head left and right examining the eerie ruins
	var look_tw = create_tween()
	look_tw.tween_property(kripal_model, "rotation_degrees:y", 215.0, 1.2).set_trans(Tween.TRANS_SINE)
	look_tw.tween_interval(0.4)
	look_tw.tween_property(kripal_model, "rotation_degrees:y", 145.0, 1.4).set_trans(Tween.TRANS_SINE)
	look_tw.tween_interval(0.3)
	look_tw.tween_property(kripal_model, "rotation_degrees:y", 180.0, 0.8).set_trans(Tween.TRANS_SINE)
	
	await look_tw.finished
	await get_tree().create_timer(0.3).timeout

	# 3. Frantically calling out for Sahil & Aashutosh in Hindi!
	subtitle.text = "कृपाल: \"साहिल! आशुतोष! कहाँ हो भाई तुम लोग?! कोई है यहाँ?!\""
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	if heartbeat_audio:
		heartbeat_audio.volume_db = -8.0
		heartbeat_audio.play()

	if voice_audio and voice_wake_2:
		voice_audio.stream = voice_wake_2
		voice_audio.play()
		await voice_audio.finished

	await get_tree().create_timer(0.4).timeout

	# 4. Taking cautious footsteps forward down the ruined hallway
	subtitle.text = "कृपाल: \"मुझे यहाँ से बाहर निकलने का रास्ता ढूँढना होगा...\""
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if footstep_audio:
		footstep_audio.play()

	var walk_tw = create_tween().set_parallel(true)
	walk_tw.tween_property(kripal_model, "position:z", -2.8, 2.5)
	walk_tw.tween_property(camera, "position:z", -1.4, 2.5)
	
	await walk_tw.finished
	original_cam_pos = camera.position

	# 5. Sudden dead silence & Terrifying Demonic Whisper from behind!
	if footstep_audio: footstep_audio.stop()
	
	# Ambience fades down into dead silence
	if ambience_audio:
		var tw_mute = create_tween()
		tw_mute.tween_property(ambience_audio, "volume_db", -30.0, 0.6)

	await get_tree().create_timer(0.6).timeout

	# Chilling whisper: "...कृपा...ल..."
	subtitle.text = "खौफनाक साया (गहरी फुसफुसाहट): \"...कृपा...ल...\""
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

	# Frantic adrenaline heartbeat
	if heartbeat_audio:
		heartbeat_audio.volume_db = 4.0
		heartbeat_audio.pitch_scale = 1.35

	if whisper_audio:
		whisper_audio.play()
		await whisper_audio.finished

	await get_tree().create_timer(0.3).timeout

	# Kripal whispers in trembling terror
	subtitle.text = "कृपाल (कांपती आवाज़ में): \"क... कौन है वहाँ?! कौन बोल रहा है?!\""
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))

	if voice_audio and voice_freeze:
		voice_audio.stream = voice_freeze
		voice_audio.play()
		await voice_audio.finished

	await get_tree().create_timer(0.3).timeout

	# 6. Turning around 180 degrees & JUMPSCARE!
	ghost_entity.visible = true
	ghost_entity.position = Vector3(0.0, 1.4, 0.8)
	if ghost_eyes: ghost_eyes.light_energy = 6.0

	subtitle.text = ""

	# Camera & Kripal whip around 180 degrees to face the archway!
	var turn_tw = create_tween().set_parallel(true)
	turn_tw.tween_property(kripal_model, "rotation_degrees:y", 0.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	turn_tw.tween_property(camera, "position", Vector3(0.0, 1.45, -2.0), 0.9).set_trans(Tween.TRANS_QUAD)
	turn_tw.tween_property(camera, "rotation_degrees", Vector3(6.0, 180.0, 0.0), 0.9).set_trans(Tween.TRANS_QUAD)
	
	await turn_tw.finished

	# THE MOMENT HE LOOKS BEHIND: JUMPSCARE!
	camera_shake_trauma = 1.0

	# Ghost lunges straight at camera
	var lunge_tw = create_tween()
	lunge_tw.tween_property(ghost_entity, "position:z", -1.8, 0.22)

	# 2D Screen Jumpscare face flashes
	jumpscare_overlay.visible = true
	ghost_face.scale = Vector2(0.8, 0.8)
	var face_tw = create_tween()
	face_tw.tween_property(ghost_face, "scale", Vector2(1.7, 1.7), 0.25).set_trans(Tween.TRANS_BACK)

	# Loud shriek & Kripal's bloodcurdling scream
	if scream_audio:
		scream_audio.play()

	# Camera violently crashes to the ground
	var drop_tw = create_tween().set_parallel(true)
	drop_tw.tween_property(camera, "position:y", 0.18, 0.35)
	drop_tw.tween_property(camera, "rotation_degrees:z", 55.0, 0.35)
	
	# Flashlight flickers out into darkness
	await get_tree().create_timer(0.2).timeout
	if flashlight: flashlight.visible = false
	await get_tree().create_timer(0.1).timeout
	if flashlight: flashlight.visible = true
	await get_tree().create_timer(0.08).timeout
	if flashlight: flashlight.visible = false

	await get_tree().create_timer(2.8).timeout

	# 7. Cut to black & Signal Lost Card
	jumpscare_overlay.visible = false
	signal_lost_card.visible = true
	signal_lost_card.modulate.a = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var card_tw = create_tween()
	card_tw.tween_property(signal_lost_card, "modulate:a", 1.0, 1.0)

func on_continue_clicked():
	# Transition back to classroom or next chapter loading
	get_tree().change_scene_to_file("res://scenes/classroom.tscn")
