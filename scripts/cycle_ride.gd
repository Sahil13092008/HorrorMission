# cycle_ride.gd
# Cinematic Bicycle Journey Cutscene: Friends racing to Kripal's house
# Features:
# - Blood red supernatural sky with volumetric fog
# - Violent lightning strikes & thunder audio
# - 3 Friends (Player, Sahil, Aashutosh) pedaling bicycles with spinning wheels & headlights
# - Cinematic multi-camera director (Front low-angle, side tracking, chase follow, arrival)
# - Synced Hindi dialogue & English mission objective UI
# - Seamless transition into scenes/street_to_kripal.tscn

extends Node3D

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var moonlight: DirectionalLight3D = $Moonlight
@onready var lightning_light: DirectionalLight3D = $LightningLight
@onready var lightning_overlay: ColorRect = $CutsceneUI/LightningOverlay
@onready var fade_overlay: ColorRect = $CutsceneUI/FadeOverlay

@onready var camera_main: Camera3D = $CameraMain

# Bicycle Squad & Members
@onready var bicycle_squad: Node3D = $BicycleSquad
@onready var player_bike: Node3D = $BicycleSquad/PlayerBike
@onready var sahil_bike: Node3D = $BicycleSquad/SahilBike
@onready var aashu_bike: Node3D = $BicycleSquad/AashuBike

# Wheels & Pedals for Animation
@onready var p_wheel_f: Node3D = $BicycleSquad/PlayerBike/WheelFront
@onready var p_wheel_r: Node3D = $BicycleSquad/PlayerBike/WheelRear
@onready var p_pedals: Node3D = $BicycleSquad/PlayerBike/PedalCrank
@onready var p_leg_l: Node3D = $BicycleSquad/PlayerBike/RiderPlayer/LegL
@onready var p_leg_r: Node3D = $BicycleSquad/PlayerBike/RiderPlayer/LegR

@onready var s_wheel_f: Node3D = $BicycleSquad/SahilBike/WheelFront
@onready var s_wheel_r: Node3D = $BicycleSquad/SahilBike/WheelRear
@onready var s_pedals: Node3D = $BicycleSquad/SahilBike/PedalCrank
@onready var s_leg_l: Node3D = $BicycleSquad/SahilBike/RiderSahil/LegL
@onready var s_leg_r: Node3D = $BicycleSquad/SahilBike/RiderSahil/LegR

@onready var a_wheel_f: Node3D = $BicycleSquad/AashuBike/WheelFront
@onready var a_wheel_r: Node3D = $BicycleSquad/AashuBike/WheelRear
@onready var a_pedals: Node3D = $BicycleSquad/AashuBike/PedalCrank
@onready var a_leg_l: Node3D = $BicycleSquad/AashuBike/RiderAashu/LegL
@onready var a_leg_r: Node3D = $BicycleSquad/AashuBike/RiderAashu/LegR

# Trees for wind swaying
@onready var trees_container: Node3D = $EnvironmentProps/Trees

# Audio
@onready var ambience_audio: AudioStreamPlayer = $Audio/AmbienceAudio
@onready var bicycle_audio: AudioStreamPlayer = $Audio/BicycleAudio
@onready var thunder_audio: AudioStreamPlayer = $Audio/ThunderAudio

# UI Nodes
@onready var mission_banner: PanelContainer = $CutsceneUI/MissionBanner
@onready var dialogue_box: PanelContainer = $CutsceneUI/DialogueBox
@onready var speaker_avatar: TextureRect = $CutsceneUI/DialogueBox/Margin/HBox/AvatarFrame/Avatar
@onready var speaker_name_label: Label = $CutsceneUI/DialogueBox/Margin/HBox/VBox/SpeakerName
@onready var dialogue_text_label: Label = $CutsceneUI/DialogueBox/Margin/HBox/VBox/DialogueText
@onready var skip_btn: Button = $CutsceneUI/SkipBtn

# Avatars
var avatar_player = preload("res://textures/avatar_player.png")
var avatar_sahil = preload("res://textures/avatar_sahil.png")
var avatar_aashutosh = preload("res://textures/avatar_aashutosh.png")

# Sfx
var sfx_thunder = preload("res://audio/thunder_strike.wav")

# State
var elapsed_time: float = 0.0
var squad_speed: float = 8.5
var squad_start_z: float = 28.0
var squad_target_z: float = -68.0
var is_transitioning: bool = false
var camera_shake: float = 0.0
var pedal_phase: float = 0.0

var dialogue_events = [
	{
		"time": 1.2,
		"duration": 4.0,
		"speaker": "👤 खिलाड़ी (YOU / PLAYER)",
		"avatar": "player",
		"color": Color(0.3, 0.9, 1.0),
		"text": "साहिल, आशुतोष... और तेज़ पैडल मारो! कृपाल बहुत बड़ी मुसीबत में है, हमें तुरंत उसके घर पहुँचना होगा!"
	},
	{
		"time": 5.6,
		"duration": 4.2,
		"speaker": "👦 साहिल (SAHIL)",
		"avatar": "sahil",
		"color": Color(1.0, 0.75, 0.2),
		"text": "भाई! यह अचानक पूरा आसमान खून जैसा लाल क्यों हो गया? इतनी भयानक कड़कड़ाती बिजली तो मैंने कभी नहीं देखी!"
	},
	{
		"time": 10.2,
		"duration": 4.5,
		"speaker": "👓 आशुतोष (AASHUTOSH) 😨 [कांपते हुए]",
		"avatar": "aashu",
		"color": Color(1.0, 0.5, 0.2),
		"text": "दोस्तों... मुझे बहुत खौफनाक अहसास हो रहा है! उस क्लासरूम में जो शैतानी साया था, उसका असर पूरे शहर पर फैल रहा है!"
	},
	{
		"time": 15.0,
		"duration": 3.2,
		"speaker": "👤 खिलाड़ी (YOU / PLAYER)",
		"avatar": "player",
		"color": Color(0.3, 0.9, 1.0),
		"text": "वो सामने कृपाल का घर आ गया! सब लोग रुको, जल्दी दरवाज़ा खटखटाते हैं!"
	}
]

var lightning_times = [1.8, 5.2, 9.6, 13.8]
var triggered_lightning = []
var active_dialogue_idx: int = -1

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)
		
	if lightning_overlay:
		lightning_overlay.visible = true
		lightning_overlay.modulate.a = 0.0
		
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 0.0, 1.2)
		
	if dialogue_box:
		dialogue_box.visible = false
		
	if bicycle_squad:
		bicycle_squad.position.z = squad_start_z
		
	if bicycle_audio:
		bicycle_audio.play()

func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER, KEY_E]) or \
	   (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("interact"):
		_on_skip_pressed()

func _physics_process(delta: float) -> void:
	if is_transitioning:
		return
		
	elapsed_time += delta
	pedal_phase += delta * squad_speed * 1.5
	
	# Move Bicycle Squad along Z towards Kripal's house
	if bicycle_squad:
		# Gradually slow down near the destination
		if bicycle_squad.position.z < -52.0:
			squad_speed = max(2.8, squad_speed - delta * 3.5)
		bicycle_squad.position.z -= squad_speed * delta
		
	# Rotate Wheels & Crank Pedals
	var wheel_rot = delta * squad_speed * 4.0
	_rotate_cycle_parts(wheel_rot, delta)
	
	# Animate Rider Legs (Pedaling movement)
	_animate_legs()
	
	# Animate Trees in storm wind
	_animate_trees(delta)
	
	# Camera Director
	_update_camera(delta)
	
	# Check Lightning Events
	_check_lightning()
	
	# Check Dialogue Events
	_check_dialogues()
	
	# Check Completion
	if elapsed_time >= 18.2 or (bicycle_squad and bicycle_squad.position.z <= squad_target_z):
		finish_cutscene()

func _rotate_cycle_parts(wheel_rot: float, delta: float) -> void:
	# Wheels
	if p_wheel_f: p_wheel_f.rotate_x(wheel_rot)
	if p_wheel_r: p_wheel_r.rotate_x(wheel_rot)
	if s_wheel_f: s_wheel_f.rotate_x(wheel_rot)
	if s_wheel_r: s_wheel_r.rotate_x(wheel_rot)
	if a_wheel_f: a_wheel_f.rotate_x(wheel_rot)
	if a_wheel_r: a_wheel_r.rotate_x(wheel_rot)
	
	# Pedals
	if p_pedals: p_pedals.rotate_x(wheel_rot * 0.7)
	if s_pedals: s_pedals.rotate_x(wheel_rot * 0.7)
	if a_pedals: a_pedals.rotate_x(wheel_rot * 0.7)
	
	# Subtle bicycle body sway
	var sway = sin(elapsed_time * 5.5) * deg_to_rad(2.0)
	if player_bike: player_bike.rotation.z = sway
	if sahil_bike: sahil_bike.rotation.z = sin(elapsed_time * 5.5 + 1.2) * deg_to_rad(2.2)
	if aashu_bike: aashu_bike.rotation.z = sin(elapsed_time * 5.5 + 2.4) * deg_to_rad(2.4)

func _animate_legs() -> void:
	var leg_swing = sin(pedal_phase) * 0.35
	if p_leg_l and p_leg_r:
		p_leg_l.rotation.x = -0.55 + leg_swing
		p_leg_r.rotation.x = -0.55 - leg_swing
	if s_leg_l and s_leg_r:
		s_leg_l.rotation.x = -0.55 + sin(pedal_phase + 1.2) * 0.35
		s_leg_r.rotation.x = -0.55 - sin(pedal_phase + 1.2) * 0.35
	if a_leg_l and a_leg_r:
		a_leg_l.rotation.x = -0.55 + sin(pedal_phase + 2.4) * 0.35
		a_leg_r.rotation.x = -0.55 - sin(pedal_phase + 2.4) * 0.35

func _animate_trees(delta: float) -> void:
	if not trees_container: return
	var t = elapsed_time * 3.2
	for i in range(trees_container.get_child_count()):
		var tree = trees_container.get_child(i)
		tree.rotation.z = sin(t + i * 0.7) * 0.05
		tree.rotation.x = cos(t * 0.8 + i * 0.5) * 0.03

func _update_camera(delta: float) -> void:
	if not camera_main or not bicycle_squad: return
	
	var squad_pos = bicycle_squad.global_position
	
	# Camera Shake decay
	if camera_shake > 0.0:
		camera_shake = max(0.0, camera_shake - delta * 3.0)
		camera_main.h_offset = (randf() * 2.0 - 1.0) * camera_shake
		camera_main.v_offset = (randf() * 2.0 - 1.0) * camera_shake
	else:
		camera_main.h_offset = 0.0
		camera_main.v_offset = 0.0
	
	# Shot 1 (0.0s - 4.8s): Low Angle Front View (Watching squad rush towards camera)
	if elapsed_time < 4.8:
		var target_pos = Vector3(0.4, 0.85, squad_pos.z - 8.5)
		camera_main.global_position = camera_main.global_position.lerp(target_pos, delta * 4.0)
		camera_main.look_at(squad_pos + Vector3(0, 1.1, 0), Vector3.UP)
		
	# Shot 2 (4.8s - 9.5s): Dynamic Side Tracking Shot (Low tracking alongside wheels & bikes)
	elif elapsed_time < 9.5:
		var side_target = Vector3(-4.2, 1.2, squad_pos.z + 0.8)
		camera_main.global_position = camera_main.global_position.lerp(side_target, delta * 3.5)
		camera_main.look_at(squad_pos + Vector3(0, 1.1, -1.0), Vector3.UP)
		
	# Shot 3 (9.5s - 14.5s): High Over-the-Shoulder Chase Camera (Looking over them at the blood sky & road)
	elif elapsed_time < 14.5:
		var chase_target = Vector3(0.0, 3.2, squad_pos.z + 5.5)
		camera_main.global_position = camera_main.global_position.lerp(chase_target, delta * 3.8)
		camera_main.look_at(squad_pos + Vector3(0, 1.2, -8.0), Vector3.UP)
		
	# Shot 4 (14.5s - end): Arrival Front/Angle Shot near Kripal's gate as bikes arrive
	else:
		var arrive_target = Vector3(2.5, 1.6, -72.0)
		camera_main.global_position = camera_main.global_position.lerp(arrive_target, delta * 2.5)
		camera_main.look_at(squad_pos + Vector3(0, 1.1, 0), Vector3.UP)

func _check_lightning() -> void:
	for t in lightning_times:
		if elapsed_time >= t and not (t in triggered_lightning):
			triggered_lightning.append(t)
			trigger_lightning_strike()
			break

func trigger_lightning_strike() -> void:
	camera_shake = 0.4
	
	# Screen flash
	if lightning_overlay:
		lightning_overlay.modulate.a = 0.95
		var tw = create_tween()
		tw.tween_property(lightning_overlay, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Lightning directional light flash
	if lightning_light:
		lightning_light.light_energy = 11.0
		var ltw = create_tween()
		ltw.tween_property(lightning_light, "light_energy", 2.0, 0.08)
		ltw.tween_property(lightning_light, "light_energy", 9.0, 0.06)
		ltw.tween_property(lightning_light, "light_energy", 0.0, 0.35)
		
	# Thunder audio
	if thunder_audio and sfx_thunder:
		thunder_audio.stream = sfx_thunder
		thunder_audio.pitch_scale = randf_range(0.92, 1.08)
		thunder_audio.play()

func _check_dialogues() -> void:
	for i in range(dialogue_events.size()):
		var evt = dialogue_events[i]
		if elapsed_time >= evt["time"] and elapsed_time < evt["time"] + evt["duration"]:
			if active_dialogue_idx != i:
				active_dialogue_idx = i
				_show_dialogue(evt)
			return
	if active_dialogue_idx != -1:
		active_dialogue_idx = -1
		if dialogue_box:
			dialogue_box.visible = false

func _show_dialogue(evt: Dictionary) -> void:
	if not dialogue_box: return
	dialogue_box.visible = true
	speaker_name_label.text = evt["speaker"]
	speaker_name_label.add_theme_color_override("font_color", evt["color"])
	dialogue_text_label.text = evt["text"]
	
	if evt["avatar"] == "player" and avatar_player:
		speaker_avatar.texture = avatar_player
	elif evt["avatar"] == "sahil" and avatar_sahil:
		speaker_avatar.texture = avatar_sahil
	elif evt["avatar"] == "aashu" and avatar_aashutosh:
		speaker_avatar.texture = avatar_aashutosh

func _on_skip_pressed() -> void:
	if is_transitioning: return
	finish_cutscene()

func finish_cutscene() -> void:
	if is_transitioning: return
	is_transitioning = true
	
	if fade_overlay:
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.8)
		if bicycle_audio:
			tw.parallel().tween_property(bicycle_audio, "volume_db", -20.0, 0.8)
		if ambience_audio:
			tw.parallel().tween_property(ambience_audio, "volume_db", -20.0, 0.8)
		await tw.finished
		
	get_tree().change_scene_to_file("res://scenes/street_to_kripal.tscn")
