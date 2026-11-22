extends Node3D

# --- PLAYER NODES ---
@onready var kripal = $KripalPlayer
@onready var visual_model = $KripalPlayer/VisualModel
@onready var head_node = $KripalPlayer/VisualModel/HeadNode
@onready var camera_pivot = $KripalPlayer/CameraPivot
@onready var camera = $KripalPlayer/CameraPivot/Camera3D
@onready var flashlight = $KripalPlayer/CameraPivot/Flashlight

# Limbs for procedural walking animation
@onready var leg_l = $KripalPlayer/VisualModel/LegsNode/LegL_Thigh
@onready var leg_r = $KripalPlayer/VisualModel/LegsNode/LegR_Thigh
@onready var arm_l = $KripalPlayer/VisualModel/ArmsNode/ArmL_Upper
@onready var arm_r = $KripalPlayer/VisualModel/ArmsNode/ArmR_Upper

# --- ENVIRONMENT & GHOST ---
@onready var floor_lantern = $FloorLantern
@onready var ghost_entity = $GhostEntity
@onready var ghost_eyes = $GhostEntity/GhostHead/EyeLight

# --- AUDIO PLAYERS ---
@onready var ambience_audio = $Audio/AmbienceAudio
@onready var voice_audio = $Audio/VoiceAudio
@onready var whisper_audio = $Audio/WhisperAudio
@onready var footstep_audio = $Audio/FootstepAudio
@onready var scream_audio = $Audio/ScreamAudio
@onready var heartbeat_audio = $Audio/HeartbeatAudio

# --- UI ELEMENTS ---
@onready var cutscene_ui = $CutsceneUI
@onready var blink_overlay = $CutsceneUI/BlinkOverlay
@onready var hud_container = $CutsceneUI/HUDContainer
@onready var view_toggle_btn = $CutsceneUI/HUDContainer/HBox/ViewToggleBtn
@onready var controls_tip = $CutsceneUI/HUDContainer/HBox/ControlsTip
@onready var objective_banner = $CutsceneUI/ObjectiveBanner
@onready var subtitle = $CutsceneUI/Subtitle
@onready var jumpscare_overlay = $CutsceneUI/JumpscareOverlay
@onready var ghost_face = $CutsceneUI/JumpscareOverlay/GhostFace
@onready var signal_lost_card = $CutsceneUI/SignalLostCard
@onready var continue_btn = $CutsceneUI/SignalLostCard/Margin/VBox/ContinueBtn

# Audio preloads
var voice_wake_1 = preload("res://audio/kripal_wake_1.mp3")
var voice_wake_2 = preload("res://audio/kripal_wake_2.mp3")
var voice_freeze = preload("res://audio/kripal_freeze.mp3")

# --- CAMERA VIEW MODES ---
enum ViewMode { FIRST_PERSON, THIRD_PERSON }
var current_view: ViewMode = ViewMode.THIRD_PERSON

const TPV_OFFSET = Vector3(0.40, 0.18, 2.0)
const FPV_OFFSET = Vector3(0.0, 0.0, 0.05)

# --- MOVEMENT SETTINGS ---
const WALK_SPEED = 3.2
const SPRINT_SPEED = 5.5
const MOUSE_SENSITIVITY = 0.0028
const GRAVITY = 9.8

# State tracking
var is_control_active = false
var is_jumpscare_triggered = false
var has_shouted_call = false
var has_triggered_whisper = false
var has_turned_toward_ghost = false

var walk_anim_time: float = 0.0
var footstep_timer: float = 0.0
var camera_shake_trauma: float = 0.0
var default_cam_local_pos: Vector3 = TPV_OFFSET

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initial UI Setup
	jumpscare_overlay.visible = false
	signal_lost_card.visible = false
	ghost_entity.visible = false
	hud_container.visible = false
	objective_banner.visible = false
	
	blink_overlay.visible = true
	blink_overlay.modulate.a = 1.0
	
	if continue_btn:
		continue_btn.pressed.connect(on_continue_clicked)
	if view_toggle_btn:
		view_toggle_btn.pressed.connect(toggle_view)

	# Initial Kripal state: lying unconscious on the cold stone floor
	kripal.position = Vector3(0.0, 0.15, 1.8)
	visual_model.position = Vector3(0.0, 0.15, 0.0)
	visual_model.rotation_degrees = Vector3(0.0, 90.0, 85.0)
	
	# Initial cinematic camera looking at Kripal on the ground
	camera.position = Vector3(0.9, -0.65, -0.6)
	camera.rotation_degrees = Vector3(15.0, 42.0, -8.0)
	default_cam_local_pos = camera.position
	
	# Start awakening prologue
	start_awakening_cutscene()

func _input(event):
	# Mouse look rotation
	if event is InputEventMouseMotion and is_control_active and not is_jumpscare_triggered:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
		kripal.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-65), deg_to_rad(75))

	if event is InputEventKey and event.pressed:
		# Toggle 1st / 3rd Person View with Key V
		if event.keycode == KEY_V and is_control_active and not is_jumpscare_triggered:
			toggle_view()

		# Toggle Flashlight with Key F
		if event.keycode == KEY_F and is_control_active and not is_jumpscare_triggered:
			flashlight.visible = !flashlight.visible

		# Escape to free/capture mouse
		if event.keycode == KEY_ESCAPE and not is_jumpscare_triggered:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Click to recapture mouse
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_control_active and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not is_jumpscare_triggered:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_view():
	if current_view == ViewMode.THIRD_PERSON:
		set_view_mode(ViewMode.FIRST_PERSON)
	else:
		set_view_mode(ViewMode.THIRD_PERSON)

func set_view_mode(mode: ViewMode):
	current_view = mode
	var tw = create_tween().set_parallel(true)
	if current_view == ViewMode.FIRST_PERSON:
		tw.tween_property(camera, "position", FPV_OFFSET, 0.25).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(camera, "rotation_degrees", Vector3.ZERO, 0.25)
		default_cam_local_pos = FPV_OFFSET
		if head_node:
			head_node.visible = false
		if view_toggle_btn:
			view_toggle_btn.text = "👁️ [V] कैमरा: 1st Person"
	else:
		if head_node:
			head_node.visible = true
		tw.tween_property(camera, "position", TPV_OFFSET, 0.25).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(camera, "rotation_degrees", Vector3.ZERO, 0.25)
		default_cam_local_pos = TPV_OFFSET
		if view_toggle_btn:
			view_toggle_btn.text = "👁️ [V] कैमरा: 3rd Person"

func start_awakening_cutscene():
	subtitle.text = "..."
	await get_tree().create_timer(0.8).timeout
	
	# Double-blink opening eyes
	var blink_tw = create_tween()
	blink_tw.tween_property(blink_overlay, "modulate:a", 0.35, 0.5)
	blink_tw.tween_property(blink_overlay, "modulate:a", 0.75, 0.3)
	blink_tw.tween_property(blink_overlay, "modulate:a", 0.0, 0.8)
	await blink_tw.finished
	blink_overlay.visible = false

	await get_tree().create_timer(0.3).timeout

	# 1st Dialogue: Waking up in confusion
	subtitle.text = "कृपाल: \"अरे... मेरा सिर बहुत दर्द कर रहा है... मैं कहाँ आ गया?!\""
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))

	if voice_audio and voice_wake_1:
		voice_audio.stream = voice_wake_1
		voice_audio.play()
		await voice_audio.finished

	await get_tree().create_timer(0.4).timeout

	# Kripal rises up from the ground
	var rise_tw = create_tween().set_parallel(true)
	rise_tw.tween_property(visual_model, "position:y", 0.0, 1.8).set_trans(Tween.TRANS_QUAD)
	rise_tw.tween_property(visual_model, "rotation_degrees", Vector3(0.0, 180.0, 0.0), 1.8).set_trans(Tween.TRANS_QUAD)
	rise_tw.tween_property(camera, "position", TPV_OFFSET, 1.8).set_trans(Tween.TRANS_QUAD)
	rise_tw.tween_property(camera, "rotation_degrees", Vector3.ZERO, 1.8).set_trans(Tween.TRANS_QUAD)
	
	await rise_tw.finished
	default_cam_local_pos = TPV_OFFSET

	# Activate Player Control!
	is_control_active = true
	hud_container.visible = true
	objective_banner.visible = true
	subtitle.text = ""
	
	# Prompt player to choose/toggle view or start moving
	set_view_mode(ViewMode.THIRD_PERSON)

func _physics_process(delta):
	# Camera trauma shake processing
	if camera_shake_trauma > 0:
		camera_shake_trauma = max(0, camera_shake_trauma - delta * 0.85)
		var shake = camera_shake_trauma * camera_shake_trauma
		camera.position = default_cam_local_pos + Vector3(
			randf_range(-1.0, 1.0) * shake * 0.45,
			randf_range(-1.0, 1.0) * shake * 0.45,
			0.0
		)
		camera.rotation_degrees.z = randf_range(-1.0, 1.0) * shake * 12.0
	elif is_control_active:
		camera.position = default_cam_local_pos
		camera.rotation_degrees.z = 0.0

	# Apply gravity
	if not kripal.is_on_floor():
		kripal.velocity.y -= GRAVITY * delta

	if not is_control_active or is_jumpscare_triggered:
		kripal.velocity.x = 0
		kripal.velocity.z = 0
		kripal.move_and_slide()
		return

	# Handle player movement
	var is_sprinting = Input.is_key_pressed(KEY_SHIFT)
	var speed = SPRINT_SPEED if is_sprinting else WALK_SPEED

	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction = (kripal.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		kripal.velocity.x = direction.x * speed
		kripal.velocity.z = direction.z * speed
		
		# Procedural limb animation in Third Person View
		var anim_speed = 10.0 if is_sprinting else 7.0
		walk_anim_time += delta * anim_speed
		
		if leg_l and leg_r:
			leg_l.rotation.x = sin(walk_anim_time) * 0.4
			leg_r.rotation.x = -sin(walk_anim_time) * 0.4
		if arm_l and arm_r:
			arm_l.rotation.x = -sin(walk_anim_time) * 0.35
			arm_r.rotation.x = sin(walk_anim_time) * 0.35

		# Footsteps sound
		footstep_timer -= delta
		if footstep_timer <= 0:
			if footstep_audio:
				footstep_audio.pitch_scale = randf_range(0.92, 1.08)
				footstep_audio.play()
			footstep_timer = 0.30 if is_sprinting else 0.46
	else:
		kripal.velocity.x = move_toward(kripal.velocity.x, 0, speed)
		kripal.velocity.z = move_toward(kripal.velocity.z, 0, speed)
		
		# Return limbs to rest
		if leg_l and leg_r:
			leg_l.rotation.x = move_toward(leg_l.rotation.x, 0, delta * 3.5)
			leg_r.rotation.x = move_toward(leg_r.rotation.x, 0, delta * 3.5)
		if arm_l and arm_r:
			arm_l.rotation.x = move_toward(arm_l.rotation.x, 0, delta * 3.5)
			arm_r.rotation.x = move_toward(arm_r.rotation.x, 0, delta * 3.5)

	kripal.move_and_slide()

	# Check exploration triggers based on position and movement
	check_story_triggers()

func check_story_triggers():
	if not is_control_active or is_jumpscare_triggered:
		return

	# Trigger 1: Call out for Sahil & Aashutosh when player starts exploring forward
	if not has_shouted_call and kripal.position.z < 1.0:
		has_shouted_call = true
		trigger_shout_dialogue()

	# Trigger 2: Venture deep into the ruins -> Terrifying Demonic Whisper!
	if has_shouted_call and not has_triggered_whisper and kripal.position.z < -3.2:
		has_triggered_whisper = true
		trigger_demon_whisper()

	# Trigger 3: If whisper triggered, detect if player looks behind or wait 3.5s
	if has_triggered_whisper and not is_jumpscare_triggered:
		# Check if player rotation Y or camera is looking back (towards positive Z)
		var forward = -kripal.global_transform.basis.z
		if forward.z > 0.4: # player turned around facing back!
			trigger_jumpscare()

func trigger_shout_dialogue():
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
	subtitle.text = "कृपाल: \"चारों तरफ सिर्फ अंधेरा और पुराने पत्थर हैं... मुझे बाहर निकलने का रास्ता ढूँढना होगा...\""
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	await get_tree().create_timer(3.2).timeout
	if not has_triggered_whisper:
		subtitle.text = ""

func trigger_demon_whisper():
	# Wind ambience fades into dead silence
	if ambience_audio:
		var tw_mute = create_tween()
		tw_mute.tween_property(ambience_audio, "volume_db", -32.0, 0.8)

	await get_tree().create_timer(0.6).timeout

	# Demonic whisper: "...कृपा...ल..."
	subtitle.text = "खौफनाक साया (गहरी फुसफुसाहट): \"...कृपा...ल...\""
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

	# Frantic heartbeat accelerates
	if heartbeat_audio:
		heartbeat_audio.volume_db = 4.0
		heartbeat_audio.pitch_scale = 1.35

	if whisper_audio:
		whisper_audio.play()
		await whisper_audio.finished

	await get_tree().create_timer(0.3).timeout

	# Kripal freezes in trembling terror
	subtitle.text = "कृपाल (कांपती आवाज़ में): \"क... कौन है वहाँ?! कौन बोल रहा है?!\""
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))

	if voice_audio and voice_freeze:
		voice_audio.stream = voice_freeze
		voice_audio.play()

	# Red blinking warning on objective banner!
	objective_banner.text = "⚠️ खौफनाक साया पीछे है! पीछे मुड़कर देखें! (LOOK BEHIND YOU!)"
	objective_banner.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))

	# Spawn Ghost Entity in the dark archway behind Kripal
	ghost_entity.visible = true
	ghost_entity.position = Vector3(0.0, 1.4, kripal.position.z + 4.2)
	if ghost_eyes: ghost_eyes.light_energy = 6.0

	# If player doesn't turn within 3.5 seconds, force jumpscare
	await get_tree().create_timer(3.5).timeout
	if not is_jumpscare_triggered:
		trigger_jumpscare()

func trigger_jumpscare():
	if is_jumpscare_triggered: return
	is_jumpscare_triggered = true
	is_control_active = false
	
	subtitle.text = ""
	objective_banner.visible = false
	hud_container.visible = false

	# Whip camera and Kripal around to face ghost
	var look_back_tw = create_tween().set_parallel(true)
	look_back_tw.tween_property(kripal, "rotation_degrees:y", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)
	look_back_tw.tween_property(camera_pivot, "rotation_degrees", Vector3.ZERO, 0.4)
	
	# THE JUMPSCARE!
	camera_shake_trauma = 1.0

	# Ghost lunges straight at camera
	var lunge_tw = create_tween()
	lunge_tw.tween_property(ghost_entity, "position", kripal.position + Vector3(0.0, 1.2, 0.3), 0.22)

	# 2D Screen Jumpscare face flashes and screams
	jumpscare_overlay.visible = true
	ghost_face.scale = Vector2(0.8, 0.8)
	var face_tw = create_tween()
	face_tw.tween_property(ghost_face, "scale", Vector2(1.7, 1.7), 0.25).set_trans(Tween.TRANS_BACK)

	# Bloodcurdling scream
	if scream_audio:
		scream_audio.play()

	# Camera violently crashes to the ground
	var drop_tw = create_tween().set_parallel(true)
	drop_tw.tween_property(camera, "position:y", -1.2, 0.35)
	drop_tw.tween_property(camera, "rotation_degrees:z", 55.0, 0.35)
	
	# Flashlight flickers out
	await get_tree().create_timer(0.2).timeout
	if flashlight: flashlight.visible = false
	await get_tree().create_timer(0.1).timeout
	if flashlight: flashlight.visible = true
	await get_tree().create_timer(0.08).timeout
	if flashlight: flashlight.visible = false

	await get_tree().create_timer(2.8).timeout

	# Cut to black & Signal Lost Card
	jumpscare_overlay.visible = false
	signal_lost_card.visible = true
	signal_lost_card.modulate.a = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var card_tw = create_tween()
	card_tw.tween_property(signal_lost_card, "modulate:a", 1.0, 1.0)

func on_continue_clicked():
	get_tree().change_scene_to_file("res://scenes/classroom.tscn")
