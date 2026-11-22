# street_to_kripal.gd
# Full manual WASD exploration along the street to Kripal's residence.
# Features:
# - Manual WASD + Sprint + Mouse Look
# - 1st Person / 3rd Person Camera Toggle
# - Companions (Sahil & Aashutosh) walking alongside
# - Walking pedestrians along sidewalks
# - Top-right Mini-Map Radar with road, trees, pedestrians, companions, and house beacon
# - Doorbell trigger and interaction
# - Door opening animation and Kripal's Mother reveal
# - Voiced Hindi conversation explaining Kripal's abduction and Bhangarh clues
# - Chapter 2 Mission transition card

extends Node3D

# --- Audio Nodes ---
@onready var ambience_audio: AudioStreamPlayer = $Audio/AmbienceAudio
@onready var doorbell_audio: AudioStreamPlayer = $Audio/DoorbellAudio
@onready var home_door_audio: AudioStreamPlayer = $Audio/HomeDoorAudio
@onready var voice_audio: AudioStreamPlayer = $Audio/VoiceAudio
@onready var footstep_audio: AudioStreamPlayer = $Audio/FootstepAudio

# --- Environment & World ---
@onready var door_hinge: Node3D = $KripalHouse/DoorHinge
@onready var door_trigger: Area3D = $KripalHouse/DoorTrigger
@onready var kripal_mummy: Node3D = $KripalHouse/KripalMummy
@onready var sahil: CharacterBody3D = $Companions/SahilCompanion
@onready var aashutosh: CharacterBody3D = $Companions/AashutoshCompanion
@onready var pedestrian1: Node3D = $EnvironmentProps/Pedestrians/Pedestrian1
@onready var pedestrian2: Node3D = $EnvironmentProps/Pedestrians/Pedestrian2
@onready var trees_parent: Node3D = $EnvironmentProps/Trees

# --- Player Nodes ---
@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $Player/CameraPivot
@onready var camera: Camera3D = $Player/CameraPivot/Camera3D
@onready var flashlight: SpotLight3D = $Player/CameraPivot/Flashlight
@onready var visual_model: Node3D = $Player/VisualModel

# --- UI Nodes ---
@onready var view_toggle_btn: Button = $StreetUI/HUDContainer/HBox/ViewToggleBtn
@onready var objective_banner: Label = $StreetUI/ObjectiveBanner
@onready var mini_map_panel: PanelContainer = $StreetUI/MiniMapPanel
@onready var radar_display: Control = $StreetUI/MiniMapPanel/Margin/VBox/RadarDisplay
@onready var distance_label: Label = $StreetUI/MiniMapPanel/Margin/VBox/DistanceLabel
@onready var prompt_label: Label = $StreetUI/PromptLabel
@onready var subtitle: Label = $StreetUI/Subtitle
@onready var dialogue_box: PanelContainer = $StreetUI/DialogueBox
@onready var speaker_label: Label = $StreetUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_text: Label = $StreetUI/DialogueBox/Margin/VBox/DialogueText
@onready var advance_tip: Label = $StreetUI/DialogueBox/Margin/VBox/AdvanceTip
@onready var next_chapter_card: ColorRect = $StreetUI/NextChapterCard
@onready var start_bhangarh_btn: Button = $StreetUI/NextChapterCard/Margin/VBox/BtnBox/StartBhangarhBtn
@onready var replay_street_btn: Button = $StreetUI/NextChapterCard/Margin/VBox/BtnBox/ReplayStreetBtn

# --- Preloaded Audio Streams ---
var stream_mummy_1: AudioStream = preload("res://audio/mummy_line_1.mp3")
var stream_mummy_2: AudioStream = preload("res://audio/mummy_line_2.mp3")
var stream_chirp: AudioStream = preload("res://audio/radio_chirp.wav")

# --- Movement Variables ---
const WALK_SPEED: float = 4.2
const SPRINT_SPEED: float = 7.2
const ACCEL: float = 12.0
const MOUSE_SENSITIVITY: float = 0.0028
var gravity: float = 9.8

var camera_rot_x: float = 0.0
var is_third_person: bool = false
var is_flashlight_on: bool = true
var footstep_timer: float = 0.0

# --- State Variables ---
var is_near_door: bool = false
var cutscene_active: bool = false
var door_opened: bool = false
var dialogue_in_progress: bool = false
var dialogue_index: int = 0
var can_advance_dialogue: bool = false
var pulse_time: float = 0.0

# Pedestrian patrol state
var ped1_z_speed: float = -1.4
var ped2_z_speed: float = 1.3

# Dialogues with Kripal's Mother
var dialogues = [
	{
		"speaker": "👩 कृपाल की माँ (KRIPAL'S MOTHER)",
		"text": "अरे बेटा, इतनी रात को तुम सब एक साथ? क्या बात है? और कृपाल कहाँ है? वो तो तुम्हारे साथ ही क्लास में था ना?",
		"audio": null,
		"color": Color(1.0, 0.75, 0.4, 1.0)
	},
	{
		"speaker": "👤 खिलाड़ी (YOU / PLAYER)",
		"text": "आंटी जी... कृपाल के साथ बहुत भयानक हादसा हुआ है! वो क्लासरूम में एक अजीब साए के पीछे गया और अचानक गायब हो गया... कोई खौफनाक शैतान उसे घसीटते हुए खींच ले गया!",
		"audio": null,
		"color": Color(0.4, 0.85, 1.0, 1.0)
	},
	{
		"speaker": "👦 साहिल (SAHIL)",
		"text": "हाँ आंटी, उसकी डेस्क पर खून से लिखा एक खौफनाक नोट मिला है... उसपर लिखा था 'Find me at भानगढ़'! वो शैतानी साया कृपाल को भानगढ़ के पुराने खंडहर में ले गया है!",
		"audio": null,
		"color": Color(0.95, 0.65, 0.3, 1.0)
	},
	{
		"speaker": "👓 आशुतोष (AASHUTOSH)",
		"text": "और आंटी, मेरे ईएमएफ और मोशन सेंसर्स भी उस वक्त बहुत भयानक रीडिंग दिखा रहे थे... कोई बहुत पुरानी और ताकतवर तांत्रिक शक्ति थी वहाँ!",
		"audio": null,
		"color": Color(1.0, 0.5, 0.2, 1.0)
	},
	{
		"speaker": "👩 कृपाल की माँ (KRIPAL'S MOTHER)",
		"text": "हे भगवान! भानगढ़?! नहीं... उसके दादाजी हमेशा उस पुराने खंडहर और तांत्रिक के श्राप की बात करते थे... रुको, ये रक्षा-सूत्र और वो पुरानी डायरी ले जाओ! भगवान के लिए मेरे कृपाल को सही-सलामत वापस ले आओ बच्चों!",
		"audio": null,
		"color": Color(1.0, 0.75, 0.4, 1.0)
	}
]

func _ready() -> void:
	dialogues[0]["audio"] = stream_mummy_1
	dialogues[4]["audio"] = stream_mummy_2
	
	# Setup initial camera view
	update_camera_mode()
	
	# Mouse capture for manual look
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Connect UI buttons
	if view_toggle_btn:
		view_toggle_btn.pressed.connect(toggle_camera_mode)
	if start_bhangarh_btn:
		start_bhangarh_btn.pressed.connect(_on_start_bhangarh_pressed)
	if replay_street_btn:
		replay_street_btn.pressed.connect(_on_replay_street_pressed)
		
	# Connect radar drawing
	if radar_display:
		radar_display.draw.connect(_on_radar_draw)
		
	# Connect door trigger
	if door_trigger:
		door_trigger.body_entered.connect(_on_door_trigger_entered)
		door_trigger.body_exited.connect(_on_door_trigger_exited)
		
	# Hide initial cutscene UI
	if prompt_label:
		prompt_label.visible = false
	if dialogue_box:
		dialogue_box.visible = false
	if next_chapter_card:
		next_chapter_card.visible = false
	if kripal_mummy:
		kripal_mummy.visible = false
		
	# Intro hint
	show_subtitle("कृपाल के घर की ओर बढ़ें... सड़क के अंत में उसका घर (कृपाल निवास) है।", 4.5)

func _input(event: InputEvent) -> void:
	# Mouse look when captured
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not cutscene_active:
			player.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera_rot_x -= event.relative.y * MOUSE_SENSITIVITY
			camera_rot_x = clamp(camera_rot_x, -deg_to_rad(75), deg_to_rad(75))
			camera_pivot.rotation.x = camera_rot_x
			
	# Key shortcuts
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				
		elif event.keycode == KEY_V:
			toggle_camera_mode()
			
		elif event.keycode == KEY_F:
			is_flashlight_on = !is_flashlight_on
			if flashlight:
				flashlight.visible = is_flashlight_on
				
		elif event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if is_near_door and not cutscene_active:
				start_door_interaction()
			elif dialogue_in_progress and can_advance_dialogue:
				advance_dialogue()
				
	# Left click interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and not next_chapter_card.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
		if is_near_door and not cutscene_active:
			start_door_interaction()
		elif dialogue_in_progress and can_advance_dialogue:
			advance_dialogue()

func _physics_process(delta: float) -> void:
	pulse_time += delta
	
	# Pedestrians patrol
	_process_pedestrians(delta)
	
	# Mini-map redraw & distance update
	_update_radar_hud()
	
	# If cutscene or dialogue is active, player doesn't move manually
	if cutscene_active:
		if not player.is_on_floor():
			player.velocity.y -= gravity * delta
			player.move_and_slide()
		return
		
	# Manual WASD Movement
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# Also support WASD explicitly
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.y += 1.0
	input_dir = input_dir.normalized()
	
	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)
	var current_speed: float = SPRINT_SPEED if is_sprinting else WALK_SPEED
	
	var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0.0
		
	if direction != Vector3.ZERO:
		player.velocity.x = move_toward(player.velocity.x, direction.x * current_speed, ACCEL * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * current_speed, ACCEL * delta)
		
		# Footstep audio
		footstep_timer += delta
		var step_interval: float = 0.28 if is_sprinting else 0.42
		if footstep_timer >= step_interval:
			footstep_timer = 0.0
			if footstep_audio and player.is_on_floor():
				footstep_audio.pitch_scale = randf_range(0.92, 1.08)
				footstep_audio.play()
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, ACCEL * 1.5 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, ACCEL * 1.5 * delta)
		footstep_timer = 0.0
		
	player.move_and_slide()
	
	# Keep companions following alongside player
	_update_companions(delta, direction)

func _update_companions(delta: float, player_dir: Vector3) -> void:
	if not sahil or not aashutosh or not player: return
	
	# Target positions slightly behind and to the sides
	var p_trans: Transform3D = player.global_transform
	var sahil_target: Vector3 = p_trans.origin - p_trans.basis.x * 1.5 + p_trans.basis.z * 1.2
	var aashu_target: Vector3 = p_trans.origin + p_trans.basis.x * 1.5 + p_trans.basis.z * 1.2
	
	# Smoothly move companions
	sahil.global_position = sahil.global_position.lerp(sahil_target, 5.0 * delta)
	aashutosh.global_position = aashutosh.global_position.lerp(aashu_target, 5.0 * delta)
	
	# Orient companions to face the same general direction as player
	sahil.rotation.y = lerp_angle(sahil.rotation.y, player.rotation.y, 6.0 * delta)
	aashutosh.rotation.y = lerp_angle(aashutosh.rotation.y, player.rotation.y, 6.0 * delta)

func _process_pedestrians(delta: float) -> void:
	if pedestrian1:
		pedestrian1.position.z += ped1_z_speed * delta
		if pedestrian1.position.z < -65.0:
			pedestrian1.position.z = -65.0
			ped1_z_speed = 1.4
			pedestrian1.rotation.y = deg_to_rad(180)
		elif pedestrian1.position.z > -12.0:
			pedestrian1.position.z = -12.0
			ped1_z_speed = -1.4
			pedestrian1.rotation.y = 0.0
			
	if pedestrian2:
		pedestrian2.position.z += ped2_z_speed * delta
		if pedestrian2.position.z > -10.0:
			pedestrian2.position.z = -10.0
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
	
	var center: Vector2 = radar_display.size * 0.5
	var radar_radius: float = min(center.x, center.y) - 6.0
	var radar_range_m: float = 48.0 # meters visible on radar
	var scale_factor: float = radar_radius / radar_range_m
	
	# Radar background circle
	radar_display.draw_circle(center, radar_radius, Color(0.05, 0.08, 0.14, 0.9))
	radar_display.draw_arc(center, radar_radius, 0, TAU, 32, Color(0.25, 0.75, 1.0, 0.8), 2.0)
	radar_display.draw_arc(center, radar_radius * 0.5, 0, TAU, 24, Color(0.2, 0.5, 0.7, 0.35), 1.0)
	
	# Crosshairs
	radar_display.draw_line(Vector2(center.x, center.y - radar_radius), Vector2(center.x, center.y + radar_radius), Color(0.2, 0.5, 0.7, 0.25), 1.0)
	radar_display.draw_line(Vector2(center.x - radar_radius, center.y), Vector2(center.x + radar_radius, center.y), Color(0.2, 0.5, 0.7, 0.25), 1.0)
	
	var p_pos: Vector3 = player.global_position
	
	# Road edges on radar
	var left_curb_x: float = center.x + (-4.0 - p_pos.x) * scale_factor
	var right_curb_x: float = center.x + (4.0 - p_pos.x) * scale_factor
	radar_display.draw_line(Vector2(left_curb_x, center.y - radar_radius), Vector2(left_curb_x, center.y + radar_radius), Color(0.5, 0.5, 0.55, 0.4), 1.5)
	radar_display.draw_line(Vector2(right_curb_x, center.y - radar_radius), Vector2(right_curb_x, center.y + radar_radius), Color(0.5, 0.5, 0.55, 0.4), 1.5)
	
	# Helper callable to convert world to radar coordinate
	# Up is negative Z (street direction)
	var world_to_radar = func(w_pos: Vector3) -> Vector2:
		var dx: float = (w_pos.x - p_pos.x) * scale_factor
		var dz: float = (w_pos.z - p_pos.z) * scale_factor
		return Vector2(center.x + dx, center.y + dz)
		
	# Draw Trees (green dots)
	if trees_parent:
		for tree in trees_parent.get_children():
			var r_pos: Vector2 = world_to_radar.call(tree.global_position)
			if center.distance_to(r_pos) < radar_radius - 2.0:
				radar_display.draw_circle(r_pos, 3.5, Color(0.2, 0.85, 0.3, 0.8))
				
	# Draw Pedestrians (yellow dots)
	if pedestrian1:
		var r_ped1: Vector2 = world_to_radar.call(pedestrian1.global_position)
		if center.distance_to(r_ped1) < radar_radius - 2.0:
			radar_display.draw_circle(r_ped1, 3.2, Color(1.0, 0.85, 0.2, 0.9))
	if pedestrian2:
		var r_ped2: Vector2 = world_to_radar.call(pedestrian2.global_position)
		if center.distance_to(r_ped2) < radar_radius - 2.0:
			radar_display.draw_circle(r_ped2, 3.2, Color(1.0, 0.85, 0.2, 0.9))
			
	# Draw Companions (cyan/blue dots)
	if sahil:
		var r_sahil: Vector2 = world_to_radar.call(sahil.global_position)
		if center.distance_to(r_sahil) < radar_radius - 2.0:
			radar_display.draw_circle(r_sahil, 3.5, Color(0.3, 0.7, 1.0, 0.95))
	if aashutosh:
		var r_aashu: Vector2 = world_to_radar.call(aashutosh.global_position)
		if center.distance_to(r_aashu) < radar_radius - 2.0:
			radar_display.draw_circle(r_aashu, 3.5, Color(1.0, 0.6, 0.2, 0.95))
			
	# Draw Kripal's House Objective Marker (Pulsating Red/Gold)
	var house_pos: Vector3 = Vector3(0, 0, -78.0)
	var r_house: Vector2 = world_to_radar.call(house_pos)
	var dir_to_house: Vector2 = (r_house - center).normalized()
	var dist_to_r_house: float = center.distance_to(r_house)
	
	var clamped_house_pos: Vector2 = r_house
	if dist_to_r_house > radar_radius - 8.0:
		clamped_house_pos = center + dir_to_house * (radar_radius - 8.0)
		
	var pulse: float = (sin(pulse_time * 6.0) + 1.0) * 0.5
	var marker_color: Color = Color(1.0, 0.2 + pulse * 0.5, 0.1, 1.0)
	radar_display.draw_circle(clamped_house_pos, 5.0 + pulse * 2.0, marker_color)
	radar_display.draw_circle(clamped_house_pos, 2.5, Color(1.0, 1.0, 0.8, 1.0))
	
	# Draw Player Arrow at Center
	var p_forward: Vector3 = -player.global_transform.basis.z
	var angle: float = atan2(p_forward.x, -p_forward.z)
	var arrow_size: float = 7.0
	var tip: Vector2 = center + Vector2(sin(angle), -cos(angle)) * arrow_size
	var left: Vector2 = center + Vector2(sin(angle + 2.5), -cos(angle + 2.5)) * (arrow_size * 0.7)
	var right: Vector2 = center + Vector2(sin(angle - 2.5), -cos(angle - 2.5)) * (arrow_size * 0.7)
	radar_display.draw_colored_polygon(PackedVector2Array([tip, left, center, right]), Color(0.2, 1.0, 0.4, 1.0))

func toggle_camera_mode() -> void:
	is_third_person = !is_third_person
	update_camera_mode()

func update_camera_mode() -> void:
	if not camera or not visual_model: return
	if is_third_person:
		camera.position = Vector3(0, 0.6, 3.2)
		visual_model.visible = true
		if view_toggle_btn:
			view_toggle_btn.text = "👁️ [V] कैमरा: 3rd Person"
	else:
		camera.position = Vector3(0, 0, 0)
		visual_model.visible = false
		if view_toggle_btn:
			view_toggle_btn.text = "👁️ [V] कैमरा: 1st Person"

func _on_door_trigger_entered(body: Node3D) -> void:
	if body == player and not door_opened:
		is_near_door = true
		if prompt_label:
			prompt_label.visible = true

func _on_door_trigger_exited(body: Node3D) -> void:
	if body == player:
		is_near_door = false
		if prompt_label and not cutscene_active:
			prompt_label.visible = false

func start_door_interaction() -> void:
	if cutscene_active: return
	cutscene_active = true
	door_opened = true
	is_near_door = false
	
	if prompt_label:
		prompt_label.visible = false
		
	# Play Doorbell Chime
	if doorbell_audio:
		doorbell_audio.play()
		
	show_subtitle("🔔 [डोरबेल बजी: डिंग-डोंग]... अंदर से किसी के आने की आहट सुनाई दे रही है...", 2.5)
	
	# Position player and companions neatly facing the door
	var tw = create_tween()
	tw.tween_property(player, "global_position", Vector3(0, 0.1, -73.2), 1.2)
	tw.parallel().tween_property(sahil, "global_position", Vector3(-1.6, 0.1, -73.6), 1.2)
	tw.parallel().tween_property(aashutosh, "global_position", Vector3(1.6, 0.1, -73.6), 1.2)
	
	# Smoothly orient player to look straight at the door
	tw.parallel().tween_property(player, "rotation:y", deg_to_rad(180), 1.2)
	tw.parallel().tween_property(camera_pivot, "rotation:x", deg_to_rad(5), 1.2)
	
	await tw.finished
	
	# Switch camera to third person cinematic view for dialogue
	is_third_person = true
	update_camera_mode()
	camera.position = Vector3(0, 0.8, 3.8)
	
	# After short pause, door unlocks and opens
	await get_tree().create_timer(1.2).timeout
	
	if home_door_audio:
		home_door_audio.play()
		
	# Swing door open 80 degrees
	var door_tw = create_tween()
	door_tw.tween_property(door_hinge, "rotation_degrees:y", 80.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Reveal Kripal's Mother
	if kripal_mummy:
		kripal_mummy.visible = true
		kripal_mummy.position.z = -0.6
		var mummy_tw = create_tween()
		mummy_tw.tween_property(kripal_mummy, "position:z", 0.1, 1.2)
		
	await door_tw.finished
	await get_tree().create_timer(0.5).timeout
	
	# Begin Mother Dialogue sequence
	start_dialogue_sequence()

func start_dialogue_sequence() -> void:
	dialogue_in_progress = true
	dialogue_index = 0
	if dialogue_box:
		dialogue_box.visible = true
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
		
	# Play voice audio if available
	if d["audio"] != null and voice_audio:
		voice_audio.stop()
		voice_audio.stream = d["audio"]
		voice_audio.play()
	elif voice_audio:
		# Play short radio chirp for player/companion speech
		voice_audio.stop()
		voice_audio.stream = stream_chirp
		voice_audio.volume_db = -6.0
		voice_audio.play()
		
	# Enable advance after short delay so dialogue isn't accidentally skipped
	await get_tree().create_timer(1.2).timeout
	can_advance_dialogue = true
	if advance_tip:
		advance_tip.text = "[CLICK या E / SPACE दबाएं ▶]"

func advance_dialogue() -> void:
	if not can_advance_dialogue: return
	dialogue_index += 1
	display_current_dialogue()

func end_dialogue_sequence() -> void:
	dialogue_in_progress = false
	if dialogue_box:
		dialogue_box.visible = false
	if subtitle:
		subtitle.text = ""
		
	# Show Chapter 2 Mission Transition Card
	if next_chapter_card:
		next_chapter_card.visible = true
		next_chapter_card.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(next_chapter_card, "modulate:a", 1.0, 0.8)
		
	# Make mouse cursor visible so player can click buttons
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_subtitle(text: String, duration: float) -> void:
	if not subtitle: return
	subtitle.text = text
	subtitle.modulate.a = 1.0
	await get_tree().create_timer(duration).timeout
	if subtitle and subtitle.text == text:
		var tw = create_tween()
		tw.tween_property(subtitle, "modulate:a", 0.0, 0.6)

func _on_start_bhangarh_pressed() -> void:
	if start_bhangarh_btn:
		start_bhangarh_btn.disabled = true
		start_bhangarh_btn.text = "🚗 भानगढ़ किले की ओर प्रस्थान..."
	get_tree().change_scene_to_file("res://scenes/bhangarh_ruins.tscn")

func _on_replay_street_pressed() -> void:
	get_tree().reload_current_scene()
