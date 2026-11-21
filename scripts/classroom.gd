extends Node3D

@onready var tubelight_1 = $Lights/TubeLight1
@onready var tubelight_2 = $Lights/TubeLight2
@onready var tube_mesh_1 = $Lights/TubeFixture1/BulbMesh
@onready var tube_mesh_2 = $Lights/TubeFixture2/BulbMesh
@onready var sun_light = $DirectionalLight3D
@onready var world_env = $WorldEnvironment
@onready var chit_note = $Furniture/Desks/Desk_Kripal/ChitNote
@onready var scratch_marks = $Furniture/Desks/Desk_Kripal/ClawScratches
@onready var subtitle = $EventUI/Subtitle

@onready var char_sahil = $Characters/Sahil
@onready var char_aashutosh = $Characters/Aashutosh
@onready var char_kripal = $Characters/Kripal
@onready var player = $Player

@onready var fan_blades_1 = $CeilingFans/Fan1/Blades
@onready var fan_blades_2 = $CeilingFans/Fan2/Blades

@onready var sfx_ambience = $Audio/AmbienceAudio
@onready var sfx_power_cut = $Audio/PowerCutAudio
@onready var sfx_flicker = $Audio/FlickerAudio
@onready var voice_audio = $Audio/VoiceAudio
@onready var heartbeat_audio = $Audio/HeartbeatAudio
@onready var radio_audio = $Audio/RadioAudio
@onready var door_audio = $Audio/DoorAudio
@onready var radar_audio = $Audio/RadarAudio

# Doorway & Hinge
@onready var doorway = $Doorway
@onready var door_hinge = $Doorway/DoorHinge
@onready var door_prompt = $Doorway/DoorPrompt

# Group Discussion Dialogue UI
@onready var dialogue_box = $EventUI/DialogueBox
@onready var portrait_rect = $EventUI/DialogueBox/MarginContainer/HBoxContainer/PortraitFrame/Portrait
@onready var speaker_label = $EventUI/DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/SpeakerName
@onready var dialogue_label = $EventUI/DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/DialogueContent
@onready var advance_tip = $EventUI/DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/AdvanceTip

# Chapter 1 Title Card
@onready var chapter_card = $EventUI/ChapterCard
@onready var chapter_continue_btn = $EventUI/ChapterCard/Margin/VBox/ContinueBtn

# Bhangarh Map & Surveillance UI
@onready var bhangarh_map_ui = $EventUI/BhangarhMapUI
@onready var ping_ring = $EventUI/BhangarhMapUI/Margin/VBox/MainContentHBox/MapPanel/MapTexture/MarkerOverlay/KripalBeacon/PingRing
@onready var bodycam_image = $EventUI/BhangarhMapUI/Margin/VBox/MainContentHBox/BodycamPanel/BodycamVBox/BodycamImage
@onready var map_dialogue_feed = $EventUI/BhangarhMapUI/Margin/VBox/BottomBar/DialogueFeed
@onready var enter_bhangarh_btn = $EventUI/BhangarhMapUI/Margin/VBox/BottomBar/EnterBhangarhBtn
@onready var beacon_btn = $EventUI/BhangarhMapUI/Margin/VBox/MainContentHBox/MapPanel/MapTexture/MarkerOverlay/KripalBeacon/BeaconButton

# Speaker Spotlight for 3D in-game illumination
@onready var speaker_light = $Lights/SpeakerSpotlight

var fan_speed: float = 12.0
var target_fan_speed: float = 12.0

var is_in_group_discussion: bool = false
var dialogue_index: int = 0

var is_in_chapter_card: bool = false
var is_waiting_for_door_open: bool = false
var is_door_opening: bool = false
var is_in_bhangarh_map: bool = false
var radar_pulse_timer: float = 0.0

var avatar_player = preload("res://textures/avatar_player.png")
var avatar_sahil = preload("res://textures/avatar_sahil.png")
var avatar_aashutosh = preload("res://textures/avatar_aashutosh.png")
var avatar_mission = preload("res://textures/avatar_mission.png")

var sfx_heartbeat = preload("res://audio/heartbeat.wav")
var sfx_radio = preload("res://audio/radio_chirp.wav")
var sfx_door = preload("res://audio/door_creak.wav")
var sfx_radar = preload("res://audio/radar_ping.wav")

var voice_door = preload("res://audio/hindi_door.mp3")
var voice_map_sahil = preload("res://audio/hindi_map_sahil.mp3")
var voice_map_aashu = preload("res://audio/hindi_map_aashu.mp3")

# High-intensity dramatic Hindi voice lines
var voice_lines = [
	preload("res://audio/hindi_line_0.mp3"),
	preload("res://audio/hindi_line_1.mp3"),
	preload("res://audio/hindi_line_2.mp3"),
	preload("res://audio/hindi_line_3.mp3"),
	preload("res://audio/hindi_line_4.mp3"),
	preload("res://audio/hindi_line_5.mp3"),
	preload("res://audio/hindi_line_6.mp3"),
	preload("res://audio/hindi_line_7.mp3")
]

var dialogue_lines = [
	{
		"speaker_id": "player",
		"speaker": "YOU (तू / Protagonist) 🗣️ [PANICKED & SHAKING]",
		"color": Color(0.3, 0.9, 1.0),
		"portrait": "player",
		"pitch": 1.0,
		"text": "\"अरे भाई... ओ भाई! देखो... मेरे हाथ कांप रहे हैं यार! जैसे ही मैंने ये पर्ची उठाई... एक भयानक चुड़ैल सामने आ गई! भाई सच में... खून बह रहा था उसकी आँखों से!\""
	},
	{
		"speaker_id": "sahil",
		"speaker": "SAHIL (साहिल) 🗣️ [LEADER / CALM BUT HURRIED]",
		"color": Color(1.0, 0.85, 0.2),
		"portrait": "sahil",
		"pitch": 1.0,
		"text": "\"अबे शांत हो जा! पहले गहरी सांस ले... शांत हो! क्या हुआ बता?! ला, मुझे दिखा ये पर्ची... 'फाइंड मी एट भानगढ़'?! अरे ये क्या बकवास है यार?!\""
	},
	{
		"speaker_id": "aashutosh",
		"speaker": "AASHUTOSH (आशुतोष) 🗣️ [SHOCKED & ADRENALINE HIGH]",
		"color": Color(1.0, 0.45, 0.2),
		"portrait": "aashutosh",
		"pitch": 1.0,
		"text": "\"भाई तू सच बोल रहा है?! जिस सेकंड तू चीखा... मेरा मोशन सेंसर पूरा लाल हो गया! और ये... अरे ये डेस्क देखो यार! यहाँ पंजे के खूनी निशान पड़े हैं!\""
	},
	{
		"speaker_id": "player",
		"speaker": "YOU (तू / Protagonist) 🗣️ [VOICE TREMBLING]",
		"color": Color(0.3, 0.9, 1.0),
		"portrait": "player",
		"pitch": 1.0,
		"text": "\"अरे वो कोई इंसान नहीं था आशुतोष! उसके काले गड्ढे जैसी आँखें और नुकीले दाँत थे यार! वो... वो कृपाल को भानगढ़ ले गया भाई!\""
	},
	{
		"speaker_id": "sahil",
		"speaker": "SAHIL (साहिल) 🗣️ [SERIOUS & DETERMINED]",
		"color": Color(1.0, 0.85, 0.2),
		"portrait": "sahil",
		"pitch": 1.0,
		"text": "\"भानगढ़ किला... राजस्थान का भानगढ़?! अरे वहाँ तो सरकार ने बोर्ड लगाया है कि सूरज डूबने के बाद जो गया वो वापस नहीं आया... वो तांत्रिक का श्राप... वो सच है क्या?!\""
	},
	{
		"speaker_id": "aashutosh",
		"speaker": "AASHUTOSH (आशुतोष) 🗣️ [URGENT & READY]",
		"color": Color(1.0, 0.45, 0.2),
		"portrait": "aashutosh",
		"pitch": 1.0,
		"text": "\"तो कृपाल अभी उसी खंडहर में फंसा है यार! भाई हम सुबह का इंतज़ार नहीं कर सकते! हमारे पास ईएमएफ मीटर, थर्मल कैमरा और सारे ट्रैप्स हैं!\""
	},
	{
		"speaker_id": "sahil",
		"speaker": "SAHIL (साहिल) 🗣️ [RESOLUTE BROTHERHOOD]",
		"color": Color(1.0, 0.85, 0.2),
		"portrait": "sahil",
		"pitch": 1.0,
		"text": "\"कृपाल हमारा भाई है... उसे वहाँ उस भूत के साथ अकेले नहीं छोड़ेंगे! गाड़ी की चाबी निकालो, सारा सामान गाड़ी में डालो... आज रात ही भानगढ़ किले चलेंगे!\""
	},
	{
		"speaker_id": "mission",
		"speaker": "★ मिशन शुरू (MISSION BEGINS) ★ 🗣️",
		"color": Color(1.0, 0.2, 0.2),
		"portrait": "mission",
		"pitch": 1.0,
		"text": "\"मिशन शुरू: भानगढ़ किले का खूनी श्राप... अपनी टीम के साथ गाड़ी में बैठो और भानगढ़ के लिए निकलो!\""
	}
]

func _ready():
	chit_note.visible = false
	chit_note.process_mode = Node.PROCESS_MODE_DISABLED
	if scratch_marks:
		scratch_marks.visible = false
	if dialogue_box:
		dialogue_box.visible = false
	if chapter_card:
		chapter_card.visible = false
	if bhangarh_map_ui:
		bhangarh_map_ui.visible = false
	if door_prompt:
		door_prompt.visible = false
	if speaker_light:
		speaker_light.visible = false
	
	if chapter_continue_btn:
		chapter_continue_btn.pressed.connect(dismiss_chapter_card)
	if enter_bhangarh_btn:
		enter_bhangarh_btn.pressed.connect(on_enter_bhangarh_clicked)
	if beacon_btn:
		beacon_btn.pressed.connect(on_enter_bhangarh_clicked)

	set_tubes_active(true)
	sfx_ambience.play()
	start_prologue_sequence()

func _process(delta):
	fan_speed = move_toward(fan_speed, target_fan_speed, delta * 3.0)
	if fan_speed > 0:
		if fan_blades_1: fan_blades_1.rotate_y(fan_speed * delta)
		if fan_blades_2: fan_blades_2.rotate_y(fan_speed * delta)
		
	# Check distance to door when waiting for player to open door
	if is_waiting_for_door_open and not is_door_opening and player:
		var dist = player.global_position.distance_to(doorway.global_position)
		if dist < 3.8:
			if door_prompt: door_prompt.visible = true
		else:
			if door_prompt: door_prompt.visible = false
			
		# Auto-open if player walks right up to the door
		if dist < 1.8:
			trigger_door_open()

	# Bhangarh Map Radar Pulsing and Bodycam Static
	if is_in_bhangarh_map:
		radar_pulse_timer += delta
		if radar_pulse_timer >= 2.2:
			radar_pulse_timer = 0.0
			if radar_audio: radar_audio.play()
			pulse_radar_beacon()
			
		# Subtle live camera static flicker
		if bodycam_image and randf() < 0.2:
			var flicker = randf_range(0.9, 1.1)
			bodycam_image.modulate = Color(flicker, flicker, flicker, 1.0)

func _input(event):
	# 1. Advance Group Discussion
	if is_in_group_discussion:
		if event is InputEventKey and event.pressed:
			if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
				advance_discussion()
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			advance_discussion()
			get_viewport().set_input_as_handled()
			
	# 2. Advance Chapter 1 Card
	elif is_in_chapter_card:
		if event is InputEventKey and event.pressed:
			if event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
				dismiss_chapter_card()
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dismiss_chapter_card()
			get_viewport().set_input_as_handled()
			
	# 3. Open Classroom Door (Key E / Click when near door)
	elif is_waiting_for_door_open and not is_door_opening:
		if event is InputEventKey and event.pressed and event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
			if player and player.global_position.distance_to(doorway.global_position) < 4.5:
				trigger_door_open()
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if player and player.global_position.distance_to(doorway.global_position) < 4.5:
				trigger_door_open()
				get_viewport().set_input_as_handled()
				
	# 4. In Bhangarh Map: Space or Enter to Depart
	elif is_in_bhangarh_map:
		if event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER]:
			on_enter_bhangarh_clicked()
			get_viewport().set_input_as_handled()

func set_tubes_active(active: bool):
	if tubelight_1: tubelight_1.visible = active
	if tubelight_2: tubelight_2.visible = active
	var color = Color(0.9, 0.95, 1.0) if active else Color(0.05, 0.05, 0.05)
	var em_energy = 2.5 if active else 0.0
	if tube_mesh_1 and tube_mesh_1.material:
		tube_mesh_1.material.albedo_color = color
		tube_mesh_1.material.emission = color
		tube_mesh_1.material.emission_energy_multiplier = em_energy
	if tube_mesh_2 and tube_mesh_2.material:
		tube_mesh_2.material.albedo_color = color
		tube_mesh_2.material.emission = color
		tube_mesh_2.material.emission_energy_multiplier = em_energy

func start_prologue_sequence():
	await get_tree().create_timer(3.5).timeout
	subtitle.text = "शाम के 6 बज चुके हैं... स्कूल खाली हो रहा है।"
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

	await get_tree().create_timer(3.0).timeout
	sfx_flicker.play()
	set_tubes_active(false)
	await get_tree().create_timer(0.12).timeout
	set_tubes_active(true)
	await get_tree().create_timer(0.2).timeout
	set_tubes_active(false)
	await get_tree().create_timer(0.08).timeout
	set_tubes_active(true)
	subtitle.text = "अरे?! ये लाइट्स क्यों झिलमिला रही हैं..."

	await get_tree().create_timer(2.0).timeout
	sfx_power_cut.play()
	set_tubes_active(false)
	target_fan_speed = 0.0
	
	if player and player.has_method("trigger_camera_shake"):
		player.trigger_camera_shake(0.4)

	var tween = create_tween()
	tween.tween_property(sun_light, "light_energy", 0.0, 1.2)
	tween.parallel().tween_property(world_env.environment, "ambient_light_energy", 0.08, 1.5)
	
	subtitle.text = "बिजली चली गई! पूरी क्लास में अंधेरा छा गया..."
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	await get_tree().create_timer(2.2).timeout
	var sky_mat = world_env.environment.sky.sky_material
	var sky_tween = create_tween()
	sky_tween.tween_property(sky_mat, "sky_top_color", Color(0.5, 0.02, 0.02), 2.0)
	sky_tween.parallel().tween_property(sky_mat, "sky_horizon_color", Color(0.9, 0.1, 0.05), 2.0)
	sky_tween.parallel().tween_property(world_env.environment, "ambient_light_color", Color(0.6, 0.05, 0.05), 2.0)
	sky_tween.parallel().tween_property(world_env.environment, "ambient_light_energy", 0.35, 2.0)

	subtitle.text = "खिड़की से बाहर देखो... आसमान खूनी लाल हो गया है!"
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	await get_tree().create_timer(3.5).timeout
	sfx_flicker.play()
	set_tubes_active(true)
	await get_tree().create_timer(0.15).timeout
	set_tubes_active(false)
	await get_tree().create_timer(0.1).timeout
	set_tubes_active(true)
	
	target_fan_speed = 10.0

	# Kripal Disappears!
	if char_kripal:
		char_kripal.visible = false
		char_kripal.process_mode = Node.PROCESS_MODE_DISABLED
	
	chit_note.visible = true
	chit_note.process_mode = Node.PROCESS_MODE_INHERIT
	if scratch_marks:
		scratch_marks.visible = true

	subtitle.text = "कृपाल कहाँ गायब हो गया?! उसकी डेस्क पर खूनी पंजे के निशान हैं..."
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))

# ==========================================
# Post-Jumpscare Sequence: Friends Gather & Discuss
# ==========================================
func start_group_discussion():
	is_in_group_discussion = true
	subtitle.text = ""
	
	# Turn on heartbeat sound
	if heartbeat_audio and sfx_heartbeat:
		heartbeat_audio.stream = sfx_heartbeat
		heartbeat_audio.play()

	# Sahil and Aashutosh walk over to Kripal's desk
	if char_sahil:
		var tw_s = create_tween()
		tw_s.tween_property(char_sahil, "position", Vector3(-2.2, 0.0, -1.8), 1.8)
		char_sahil.look_at(Vector3(-3.2, 0.0, -2.5), Vector3.UP)
		char_sahil.rotation.x = 0
		char_sahil.rotation.z = 0
		
	if char_aashutosh:
		var tw_a = create_tween()
		tw_a.tween_property(char_aashutosh, "position", Vector3(-3.8, 0.0, -1.6), 2.0)
		char_aashutosh.look_at(Vector3(-3.2, 0.0, -2.5), Vector3.UP)
		char_aashutosh.rotation.x = 0
		char_aashutosh.rotation.z = 0

	await get_tree().create_timer(1.2).timeout

	dialogue_index = 0
	dialogue_box.visible = true
	show_current_dialogue_line()

func show_current_dialogue_line():
	if dialogue_index < dialogue_lines.size():
		var data = dialogue_lines[dialogue_index]
		speaker_label.text = data["speaker"]
		speaker_label.add_theme_color_override("font_color", data["color"])
		dialogue_label.text = data["text"]
		
		# 1. Update 2D Character Avatar Portrait in Dialogue Box
		if portrait_rect:
			match data["portrait"]:
				"player": portrait_rect.texture = avatar_player
				"sahil": portrait_rect.texture = avatar_sahil
				"aashutosh": portrait_rect.texture = avatar_aashutosh
				"mission": portrait_rect.texture = avatar_mission
				
		# 2. Smoothly rotate camera & shine spotlight on the speaking character
		var speaker_id = data["speaker_id"]
		highlight_speaker(speaker_id)
		
		# 3. Audio FX: Play walkie-talkie chirp for friends, heartbeat for player
		if speaker_id == "sahil" or speaker_id == "aashutosh":
			if radio_audio and sfx_radio: radio_audio.play()
			if heartbeat_audio: heartbeat_audio.volume_db = -6.0
		elif speaker_id == "player":
			if heartbeat_audio: heartbeat_audio.volume_db = 2.0
		
		# 4. Play the intense, dramatic Hindi voice line!
		if voice_audio and dialogue_index < voice_lines.size():
			voice_audio.stop()
			voice_audio.pitch_scale = 1.0
			voice_audio.stream = voice_lines[dialogue_index]
			voice_audio.play()
	else:
		# End of discussion -> Show Chapter 1 Title Screen!
		if voice_audio: voice_audio.stop()
		if heartbeat_audio: heartbeat_audio.stop()
		dialogue_box.visible = false
		is_in_group_discussion = false
		if speaker_light: speaker_light.visible = false
		show_chapter_title_card()

func highlight_speaker(speaker_id: String):
	# Reset 3D NameTags
	if char_sahil and char_sahil.has_node("NameTag"):
		char_sahil.get_node("NameTag").text = "SAHIL\n[The Analyst]"
	if char_aashutosh and char_aashutosh.has_node("NameTag"):
		char_aashutosh.get_node("NameTag").text = "AASHUTOSH\n[The Explorer]"

	if speaker_light:
		speaker_light.visible = true

	if speaker_id == "sahil":
		if char_sahil and char_sahil.has_node("NameTag"):
			char_sahil.get_node("NameTag").text = "🗣️ SAHIL (Speaking)\n[The Analyst]"
		if player:
			player.look_at_target_smoothly(Vector3(-2.2, 1.35, -1.8), 0.7)
		if speaker_light:
			speaker_light.position = Vector3(-2.2, 2.8, -1.8)
			speaker_light.light_color = Color(1.0, 0.9, 0.4)
			
	elif speaker_id == "aashutosh":
		if char_aashutosh and char_aashutosh.has_node("NameTag"):
			char_aashutosh.get_node("NameTag").text = "🗣️ AASHUTOSH (Speaking)\n[The Explorer]"
		if player:
			player.look_at_target_smoothly(Vector3(-3.8, 1.35, -1.6), 0.7)
		if speaker_light:
			speaker_light.position = Vector3(-3.8, 2.8, -1.6)
			speaker_light.light_color = Color(1.0, 0.5, 0.2)
			
	elif speaker_id == "player":
		if player:
			player.look_at_target_smoothly(Vector3(-3.2, 0.75, -2.5), 0.65)
		if speaker_light:
			speaker_light.position = Vector3(-3.0, 3.0, -2.5)
			speaker_light.light_color = Color(0.4, 0.8, 1.0)
			
	elif speaker_id == "mission":
		if player:
			player.look_at_target_smoothly(Vector3(-7.5, 2.5, 0.0), 0.8)
		if speaker_light:
			speaker_light.visible = false

func advance_discussion():
	if not is_in_group_discussion: return
	dialogue_index += 1
	show_current_dialogue_line()

# ==========================================
# Chapter 1 Title Card & Mission Description
# ==========================================
func show_chapter_title_card():
	is_in_chapter_card = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if chapter_card:
		chapter_card.visible = true
		chapter_card.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(chapter_card, "modulate:a", 1.0, 0.8)

func dismiss_chapter_card():
	if not is_in_chapter_card: return
	is_in_chapter_card = false
	
	if chapter_card:
		var tween = create_tween()
		tween.tween_property(chapter_card, "modulate:a", 0.0, 0.5)
		await tween.finished
		chapter_card.visible = false

	# Return mouse capture for player movement
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Start Team Walk to the Classroom Door!
	start_door_sequence()

# ==========================================
# Opening the Classroom Door Sequence
# ==========================================
func start_door_sequence():
	is_waiting_for_door_open = true
	
	# Sahil's voice calls out to open the door
	if voice_audio and voice_door:
		voice_audio.stop()
		voice_audio.pitch_scale = 1.0
		voice_audio.stream = voice_door
		voice_audio.play()

	subtitle.text = "🎯 मिशन: साहिल और आशुतोष के साथ क्लासरूम का मुख्य गेट खोलो [E दबाएं]"
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	# Sahil and Aashutosh run/walk over to the door!
	if char_sahil:
		var tw_s = create_tween()
		tw_s.tween_property(char_sahil, "position", Vector3(6.6, 0.0, 3.8), 2.0)
		char_sahil.look_at(doorway.global_position, Vector3.UP)
		char_sahil.rotation.x = 0
		char_sahil.rotation.z = 0
		
	if char_aashutosh:
		var tw_a = create_tween()
		tw_a.tween_property(char_aashutosh, "position", Vector3(6.6, 0.0, 5.2), 2.2)
		char_aashutosh.look_at(doorway.global_position, Vector3.UP)
		char_aashutosh.rotation.x = 0
		char_aashutosh.rotation.z = 0

	if door_prompt:
		door_prompt.visible = true

func trigger_door_open():
	if is_door_opening: return
	is_door_opening = true
	is_waiting_for_door_open = false
	
	if door_prompt:
		door_prompt.visible = false

	# Play creaking door audio
	if door_audio and sfx_door:
		door_audio.stream = sfx_door
		door_audio.play()

	subtitle.text = "🚪 क्लासरूम का भारी लकड़ी का गेट खुल रहा है..."
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	# Animate Door Hinge swinging open (85 degrees outwards!)
	if door_hinge:
		var tw = create_tween()
		tw.tween_property(door_hinge, "rotation:y", deg_to_rad(85.0), 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Camera looks at the opening doorway
	if player:
		if player.has_method("look_at_target_smoothly"):
			player.look_at_target_smoothly(doorway.global_position + Vector3(0, 1.3, 0), 0.8)
		if player.has_method("trigger_camera_shake"):
			player.trigger_camera_shake(0.3)

	await get_tree().create_timer(1.8).timeout

	# Smooth flash and transition to the Bhangarh Map screen!
	show_bhangarh_map()

# ==========================================
# Bhangarh Fort Map & Kripal's Live View
# ==========================================
func show_bhangarh_map():
	is_in_bhangarh_map = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if bhangarh_map_ui:
		bhangarh_map_ui.visible = true
		bhangarh_map_ui.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(bhangarh_map_ui, "modulate:a", 1.0, 0.7)

	# Initial Radar Sonar Ping
	if radar_audio and sfx_radar:
		radar_audio.stream = sfx_radar
		radar_audio.play()
	pulse_radar_beacon()

	# 1. Play Sahil's voice line explaining the map and Kripal's signal
	if voice_audio and voice_map_sahil:
		voice_audio.stop()
		voice_audio.pitch_scale = 1.0
		voice_audio.stream = voice_map_sahil
		voice_audio.play()

	if map_dialogue_feed:
		map_dialogue_feed.text = "साहिल: \"नक्शा देखो! कृपाल का जीपीएस सिग्नल भानगढ़ किले के सबसे गहरे खंडहरों से आ रहा है... वो वहीं कहीं फंसा है!\""

	# After Sahil finishes, Aashutosh chimes in
	await get_tree().create_timer(5.2).timeout
	if is_in_bhangarh_map and voice_audio and voice_map_aashu:
		voice_audio.stop()
		voice_audio.pitch_scale = 1.0
		voice_audio.stream = voice_map_aashu
		voice_audio.play()
		if map_dialogue_feed:
			map_dialogue_feed.text = "आशुतोष: \"वहाँ तो तांत्रिक की छतरी और पुराना राजमहल है भाई! वो सबसे खतरनाक जगह है! चलो तुरंत गाड़ी में बैठते हैं!\""

func pulse_radar_beacon():
	if not ping_ring: return
	ping_ring.scale = Vector2(0.4, 0.4)
	ping_ring.modulate.a = 0.95
	var tw = create_tween()
	tw.tween_property(ping_ring, "scale", Vector2(2.6, 2.6), 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ping_ring, "modulate:a", 0.0, 1.8)

func on_enter_bhangarh_clicked():
	if map_dialogue_feed:
		map_dialogue_feed.text = "🚨 कृपाल की लोकेशन से लाइव सिग्नल कनेक्ट हो रहा है... (ENTERING KRIPAL'S VIEW)"
	
	if enter_bhangarh_btn:
		enter_bhangarh_btn.disabled = true
		enter_bhangarh_btn.text = "🚨 भानगढ़ की ओर प्रस्थान..."
	if beacon_btn:
		beacon_btn.disabled = true

	# Dramatic transition fade out into Bhangarh ruins scene
	var tw = create_tween()
	tw.tween_property(bhangarh_map_ui, "modulate", Color(0.0, 0.0, 0.0, 1.0), 0.8)
	if sfx_ambience:
		tw.parallel().tween_property(sfx_ambience, "volume_db", -25.0, 0.8)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/bhangarh_ruins.tscn")
