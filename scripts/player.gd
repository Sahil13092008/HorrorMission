extends CharacterBody3D

const SPEED = 3.5
const SPRINT_SPEED = 6.0
const MOUSE_SENSITIVITY = 0.003
const GRAVITY = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var flashlight = $Head/Flashlight
@onready var raycast = $Head/RayCast3D

@onready var interact_label = $UI/InteractPrompt
@onready var popup_ui = $UI/NotePopup
@onready var popup_title = $UI/NotePopup/MarginContainer/VBoxContainer/Title
@onready var popup_text = $UI/NotePopup/MarginContainer/VBoxContainer/NoteText

@onready var jumpscare_ui = $UI/JumpscareLayer
@onready var ghost_face = $UI/JumpscareLayer/GhostFace
@onready var red_backdrop = $UI/JumpscareLayer/RedBackdrop
@onready var jumpscare_audio = $Audio/JumpscareAudio
@onready var scream_audio = $Audio/ScreamAudio

var is_in_dialogue = false
var is_jumpscare_active = false
var trauma: float = 0.0
var original_cam_pos: Vector3 = Vector3.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_label.visible = false
	popup_ui.visible = false
	jumpscare_ui.visible = false
	original_cam_pos = camera.position

func _input(event):
	if is_jumpscare_active:
		return

	# If classroom group discussion, chapter card, or bhangarh map is active, let classroom handle it!
	var classroom = get_parent()
	if classroom and (classroom.get("is_in_group_discussion") == true or classroom.get("is_in_chapter_card") == true or classroom.get("is_in_bhangarh_map") == true):
		return

	# If clicked on the screen, lock mouse (on desktop only)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_in_dialogue and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not OS.has_feature("mobile"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Handle mouse and mobile touch-drag camera rotation
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and not is_in_dialogue:
		if not OS.has_feature("mobile") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if (event is InputEventKey and event.pressed) or event.is_action_pressed("interact") or event.is_action_pressed("flashlight"):
		# Toggle mouse capture / close simple popups with ESC
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			if is_in_dialogue:
				close_popup()
			else:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				else:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		# Toggle Flashlight (Key F or Mobile Button)
		if ((event is InputEventKey and event.keycode == KEY_F) or event.is_action_pressed("flashlight")) and not is_in_dialogue:
			flashlight.visible = !flashlight.visible

		# Interact (Key E or Mobile Button)
		if (event is InputEventKey and event.keycode == KEY_E) or event.is_action_pressed("interact"):
			if is_in_dialogue:
				close_popup()
			elif raycast.is_colliding():
				var collider = raycast.get_collider()
				if collider and collider.is_in_group("interactable"):
					if collider.has_method("interact"):
						collider.interact(self)

func _physics_process(delta):
	# Camera trauma shake
	if trauma > 0:
		trauma = max(0, trauma - delta * 0.7)
		var shake = trauma * trauma
		camera.position = original_cam_pos + Vector3(
			randf_range(-1.0, 1.0) * shake * 0.4,
			randf_range(-1.0, 1.0) * shake * 0.4,
			0.0
		)
		camera.rotation.z = randf_range(-1.0, 1.0) * shake * 0.15
	else:
		camera.position = original_cam_pos
		camera.rotation.z = 0.0

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if is_in_dialogue or is_jumpscare_active:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Handle movement
	var current_speed = SPEED
	if Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir == Vector2.ZERO:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("move_forward") or Input.is_action_pressed("ui_up"): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("move_backward") or Input.is_action_pressed("ui_down"): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"): input_dir.x += 1
	input_dir = input_dir.normalized()

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Check what player is looking at
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("interactable"):
			interact_label.visible = true
			if collider.has_meta("prompt"):
				interact_label.text = "[E] " + str(collider.get_meta("prompt"))
			else:
				interact_label.text = "[E] Inspect"
		else:
			interact_label.visible = false
	else:
		interact_label.visible = false

func show_popup(title: String, text: String):
	is_in_dialogue = true
	popup_title.text = title
	popup_text.text = text
	popup_ui.visible = true
	interact_label.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_note(text: String):
	# Immediately trigger the terrifying 4-second jumpscare!
	trigger_chit_jumpscare()

func trigger_chit_jumpscare():
	if is_jumpscare_active: return
	is_jumpscare_active = true
	is_in_dialogue = true
	interact_label.visible = false
	popup_ui.visible = false
	
	# Activate Jumpscare Overlay with horrifying user-provided faces
	var tex_bloody = load("res://textures/ghost_face_2_bloody_red.png")
	var tex_scream = load("res://textures/ghost_face_3_scream.png")
	if tex_bloody and ghost_face:
		ghost_face.texture = tex_bloody
	
	jumpscare_ui.visible = true
	ghost_face.scale = Vector2(0.85, 0.85)
	ghost_face.rotation = 0.0
	trauma = 1.0
	
	# Play full 4-second demonic jumpscare audio
	if jumpscare_audio:
		var custom_st = load("res://audio/scary_jumpscare_impact.mp3")
		if custom_st:
			jumpscare_audio.stream = custom_st
		jumpscare_audio.volume_db = 6.0
		jumpscare_audio.play()

	# 4-Second Jumpscare Sequence: Ghost lunges, screen pulses blood-red, flashlight strobes
	var elapsed = 0.0
	var total_duration = 4.0
	
	while elapsed < total_duration:
		var dt = 0.06
		elapsed += dt
		trauma = 1.0
		
		# Animate ghost face scale: lunges from 0.85 up to 1.65 in your face
		var target_scale = lerp(0.9, 1.65, min(1.0, elapsed / 1.4)) + randf_range(-0.12, 0.12)
		ghost_face.scale = Vector2(target_scale, target_scale)
		ghost_face.rotation = randf_range(-0.1, 0.1)
		
		# Psychological flicker between bloody jagged smile and screaming void jaw
		if tex_scream and tex_bloody:
			if elapsed > 1.0 and elapsed < 2.5 and fmod(elapsed, 0.22) < 0.09:
				ghost_face.texture = tex_scream
			else:
				ghost_face.texture = tex_bloody
		
		# Pure pitch black darkness behind ghost face
		if red_backdrop:
			red_backdrop.color = Color(0, 0, 0, 1)
			
		if randf() > 0.35:
			flashlight.visible = !flashlight.visible
			
		await get_tree().create_timer(dt).timeout

	# Jumpscare ends: Ghost instantly vanishes!
	jumpscare_ui.visible = false
	flashlight.visible = true
	is_jumpscare_active = false
	
	# LOUD PLAYER TERROR SCREAM & GASP AUDIO PLAYS!
	if scream_audio:
		scream_audio.play()
		
	# Trauma wave for residual trembling
	trauma = 0.8
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Trigger the group discussion and story continuation in classroom!
	var classroom = get_parent()
	if classroom and classroom.has_method("start_group_discussion"):
		classroom.start_group_discussion()

# Smoothly turns the player camera to face whoever is talking
func look_at_target_smoothly(target_pos: Vector3, duration: float = 0.65):
	var head_global = head.global_position
	var look_dir = (target_pos - head_global).normalized()
	
	var target_yaw = atan2(-look_dir.x, -look_dir.z)
	var flat_dist = Vector2(look_dir.x, look_dir.z).length()
	var target_pitch = clamp(-atan2(look_dir.y, flat_dist), deg_to_rad(-60), deg_to_rad(60))
	
	var tween = create_tween().set_parallel(true)
	# Wrap-safe rotation
	var diff_yaw = fposmod(target_yaw - rotation.y + PI, PI * 2) - PI
	tween.tween_property(self, "rotation:y", rotation.y + diff_yaw, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(head, "rotation:x", target_pitch, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func close_popup():
	is_in_dialogue = false
	popup_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func trigger_camera_shake(amount: float = 0.5):
	trauma = clamp(trauma + amount, 0.0, 1.0)
