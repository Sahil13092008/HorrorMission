extends Node3D

# ==============================================================
# PHONE_CALL_CONVO.GD
# 3-Way Group Phone Conference across 3 Rooms (2 Days Later)
# Characters: Aashutosh, Player (Tu), Sahil
# ==============================================================

# Cameras
@onready var cam_aashu: Camera3D = $Room_Aashutosh/Camera_Aashutosh
@onready var cam_player: Camera3D = $Room_Player/Camera_Player
@onready var cam_sahil: Camera3D = $Room_Sahil/Camera_Sahil

# Character Head Nodes for speaking animation
@onready var head_aashu: Node3D = $Room_Aashutosh/Aashutosh/HeadNode
@onready var head_player: Node3D = $Room_Player/PlayerCharacter/VisualModel/HeadNode
@onready var head_sahil: Node3D = $Room_Sahil/Sahil/HeadNode

# Audio
@onready var voice_audio: AudioStreamPlayer = $Audio/VoiceAudio
@onready var sfx_audio: AudioStreamPlayer = $Audio/SFXAudio
@onready var rain_audio: AudioStreamPlayer = $Audio/RainAudio

# UI
@onready var top_call_bar: PanelContainer = $PhoneUI/TopCallBar
@onready var call_status: Label = $PhoneUI/TopCallBar/Margin/HBox/CallStatus
@onready var badge_aashu: Label = $PhoneUI/TopCallBar/Margin/HBox/BadgeAashu
@onready var badge_player: Label = $PhoneUI/TopCallBar/Margin/HBox/BadgePlayer
@onready var badge_sahil: Label = $PhoneUI/TopCallBar/Margin/HBox/BadgeSahil

@onready var subtitle_panel: PanelContainer = $PhoneUI/SubtitlePanel
@onready var speaker_label: Label = $PhoneUI/SubtitlePanel/Margin/VBox/SpeakerLabel
@onready var dialogue_text: Label = $PhoneUI/SubtitlePanel/Margin/VBox/DialogueText
@onready var advance_tip: Label = $PhoneUI/SubtitlePanel/Margin/VBox/AdvanceTip

@onready var expedition_card: PanelContainer = $PhoneUI/ExpeditionCard
@onready var proceed_btn: Button = $PhoneUI/ExpeditionCard/Margin/VBox/ProceedBtn
@onready var skip_call_btn: Button = $PhoneUI/TopCallBar/Margin/HBox/SkipCallBtn

# Safe audio streams loaded at runtime without blocking parse
var sfx_ring: AudioStream
var sfx_pickup: AudioStream

var stream_aashu_1: AudioStream
var stream_player_1: AudioStream
var stream_sahil_1: AudioStream
var stream_player_2: AudioStream
var stream_sahil_2: AudioStream
var stream_aashu_2: AudioStream

func load_stream_safe(path: String) -> AudioStream:
	if FileAccess.file_exists(path + ".import") and ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var bytes = f.get_buffer(f.get_length())
			if path.ends_with(".mp3"):
				var mp3 = AudioStreamMP3.new()
				mp3.data = bytes
				return mp3
			elif path.ends_with(".wav"):
				var wav = AudioStreamWAV.new()
				if bytes.size() > 44 and bytes.slice(0, 4).get_string_from_ascii() == "RIFF":
					wav.data = bytes.slice(44)
				else:
					wav.data = bytes
				return wav
	return null

# Dialogues Array matching user story exactly
var dialogues = [
	{
		"speaker_id": "aashutosh",
		"speaker": "👓 आशुतोष (AASHUTOSH) — [अपने कमरे से]",
		"color": Color(0.45, 0.8, 1.0),
		"text": "\"भाई, मैं कृपाल के घर गया था यार... उसके पेरेंट्स बहुत टेंशन में हैं और बहुत दुखी हैं!\"",
		"audio": null
	},
	{
		"speaker_id": "player",
		"speaker": "🎒 तू (YOU) — [अपने कमरे से]",
		"color": Color(0.35, 0.95, 1.0),
		"text": "\"हाँ यार, वो तो होंगे ही ना... आखिर कृपाल दो दिन से गायब है!\"",
		"audio": null
	},
	{
		"speaker_id": "sahil",
		"speaker": "🧢 साहिल (SAHIL) — [अपने कमरे से]",
		"color": Color(1.0, 0.85, 0.3),
		"text": "\"हाँ भाई, मैं अभी पुलिस स्टेशन से ही आ रहा हूँ कि कृपाल के केस में कोई लीड मिली होगी... पर पुलिस कह रही थी कि हमने पूरा भानगढ़ छान मारा, पर हमें कृपाल का कुछ पता नहीं लगा!\"",
		"audio": null
	},
	{
		"speaker_id": "player",
		"speaker": "🎒 तू (YOU) — [अपने कमरे से]",
		"color": Color(0.35, 0.95, 1.0),
		"text": "\"भाई, अभी तो हमें ही कुछ करना होगा!\"",
		"audio": null
	},
	{
		"speaker_id": "sahil",
		"speaker": "🧢 साहिल (SAHIL) — [अपने कमरे से]",
		"color": Color(1.0, 0.85, 0.3),
		"text": "\"सब अपने-अपने गैजेट्स लेके बॉयज़ स्कूल पहुँचो, वहाँ आगे का प्लान बनाते हैं!\"",
		"audio": null
	},
	{
		"speaker_id": "aashutosh",
		"speaker": "👓 आशुतोष (AASHUTOSH) — [अपने कमरे से]",
		"color": Color(0.45, 0.8, 1.0),
		"text": "\"हाँ भाई, मैं अपना सारा ईएमएफ और रिसर्च सामान बैग में पैक करके अपनी साइकिल से बॉयज़ स्कूल पहुँच रहा हूँ!\"",
		"audio": null
	},
	{
		"speaker_id": "player",
		"speaker": "🎒 तू (YOU) — [अपने कमरे से]",
		"color": Color(0.35, 0.95, 1.0),
		"text": "\"ठीक है, मैं भी अपने सारे ज़रूरी गैजेट्स बैग में पैक करता हूँ और साइकिल लेके सीधे बॉयज़ स्कूल निकलता हूँ!\"",
		"audio": null
	}
]

var dialogue_index: int = 0
var can_advance: bool = false
var is_call_active: bool = false
var call_duration: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	sfx_ring = load_stream_safe("res://audio/phone_ring.wav")
	sfx_pickup = load_stream_safe("res://audio/phone_pickup.wav")
	
	stream_aashu_1 = load_stream_safe("res://audio/call_aashu_1.mp3")
	stream_player_1 = load_stream_safe("res://audio/call_player_1.mp3")
	stream_sahil_1 = load_stream_safe("res://audio/call_sahil_1.mp3")
	stream_player_2 = load_stream_safe("res://audio/call_player_2.mp3")
	stream_sahil_2 = load_stream_safe("res://audio/call_sahil_2.mp3")
	stream_aashu_2 = load_stream_safe("res://audio/call_aashu_2.mp3")
	
	dialogues[0]["audio"] = stream_aashu_1
	dialogues[1]["audio"] = stream_player_1
	dialogues[2]["audio"] = stream_sahil_1
	dialogues[3]["audio"] = stream_player_2
	dialogues[4]["audio"] = stream_sahil_2
	dialogues[5]["audio"] = stream_aashu_2
	
	if proceed_btn:
		proceed_btn.pressed.connect(_on_proceed_chapter2_pressed)
	if skip_call_btn:
		skip_call_btn.pressed.connect(end_phone_call)
		
	if subtitle_panel:
		subtitle_panel.visible = false
	if expedition_card:
		expedition_card.visible = false
		
	# Start with phone connection sequence
	start_phone_call_sequence()

func _process(delta: float) -> void:
	if is_call_active:
		call_duration += delta
		var minutes = int(call_duration) / 60
		var seconds = int(call_duration) % 60
		if call_status:
			call_status.text = "🟢 LIVE 3-WAY CONFERENCE CALL [%02d:%02d] — [2 DAYS LATER]" % [minutes, seconds]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			end_phone_call()
			return
			
	if not can_advance: return
	
	if (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E)) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("interact"):
		if dialogue_index >= dialogues.size():
			_on_proceed_chapter2_pressed()
		else:
			advance_dialogue()

func start_phone_call_sequence() -> void:
	# Show Player's room initially while phone rings
	switch_to_camera("player")
	
	if call_status:
		call_status.text = "📲 CONNECTING 3-WAY CONFERENCE CALL..."
		call_status.modulate = Color(1.0, 0.85, 0.3)
		
	# Ringing sound
	if sfx_audio and sfx_ring:
		sfx_audio.stream = sfx_ring
		sfx_audio.play()
		await get_tree().create_timer(1.8).timeout
		
	# Call Connected Pickup sound
	if sfx_audio and sfx_pickup:
		sfx_audio.stream = sfx_pickup
		sfx_audio.play()
		await get_tree().create_timer(0.4).timeout
		
	is_call_active = true
	if call_status:
		call_status.modulate = Color(0.2, 1.0, 0.5)
		
	if subtitle_panel:
		subtitle_panel.visible = true
		subtitle_panel.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(subtitle_panel, "modulate:a", 1.0, 0.5)
		
	dialogue_index = 0
	display_current_dialogue()

func display_current_dialogue() -> void:
	if dialogue_index >= dialogues.size():
		end_phone_call()
		return
		
	can_advance = false
	var d = dialogues[dialogue_index]
	var speaker_id: String = d["speaker_id"]
	
	# Switch to the speaker's room camera!
	switch_to_camera(speaker_id)
	
	# Update Subtitles
	if speaker_label:
		speaker_label.text = d["speaker"]
		speaker_label.modulate = d["color"]
	if dialogue_text:
		dialogue_text.text = d["text"]
	if advance_tip:
		advance_tip.text = "[CLICK / SPACE TO ADVANCE ➔]"
		
	# Update Top Bar Caller Badges
	update_caller_badges(speaker_id)
	
	# Play High-Quality Hindi Voice Line
	if voice_audio and d["audio"]:
		voice_audio.stop()
		voice_audio.stream = d["audio"]
		voice_audio.play()
		animate_head_speaking(speaker_id)
		
	await get_tree().create_timer(0.8).timeout
	can_advance = true

func advance_dialogue() -> void:
	if not can_advance: return
	dialogue_index += 1
	display_current_dialogue()

func switch_to_camera(speaker_id: String) -> void:
	if cam_aashu: cam_aashu.current = false
	if cam_player: cam_player.current = false
	if cam_sahil: cam_sahil.current = false
	
	var active_cam: Camera3D = null
	match speaker_id:
		"aashutosh":
			active_cam = cam_aashu
		"player":
			active_cam = cam_player
		"sahil":
			active_cam = cam_sahil
			
	if active_cam:
		active_cam.current = true
		active_cam.position.z = 1.75
		var tw = create_tween()
		tw.tween_property(active_cam, "position:z", 1.55, 6.0).set_trans(Tween.TRANS_SINE)

func update_caller_badges(active_speaker: String) -> void:
	# Aashutosh
	if badge_aashu:
		if active_speaker == "aashutosh":
			badge_aashu.text = "👓 AASHUTOSH [🗣️ SPEAKING]"
			badge_aashu.modulate = Color(0.3, 1.0, 0.5)
		else:
			badge_aashu.text = "👓 AASHUTOSH [ONLINE]"
			badge_aashu.modulate = Color(0.65, 0.75, 0.85)
			
	# Player
	if badge_player:
		if active_speaker == "player":
			badge_player.text = "🎒 YOU (तू) [🗣️ SPEAKING]"
			badge_player.modulate = Color(0.3, 1.0, 0.5)
		else:
			badge_player.text = "🎒 YOU (तू) [ONLINE]"
			badge_player.modulate = Color(0.65, 0.75, 0.85)
			
	# Sahil
	if badge_sahil:
		if active_speaker == "sahil":
			badge_sahil.text = "🧢 SAHIL [🗣️ SPEAKING]"
			badge_sahil.modulate = Color(0.3, 1.0, 0.5)
		else:
			badge_sahil.text = "🧢 SAHIL [ONLINE]"
			badge_sahil.modulate = Color(0.65, 0.75, 0.85)

func animate_head_speaking(speaker_id: String) -> void:
	var target_head: Node3D = null
	match speaker_id:
		"aashutosh": target_head = head_aashu
		"player": target_head = head_player
		"sahil": target_head = head_sahil
		
	if target_head:
		var tw = create_tween().set_loops(4)
		tw.tween_property(target_head, "rotation_degrees:x", 4.0, 0.35)
		tw.tween_property(target_head, "rotation_degrees:x", -2.0, 0.35)

func end_phone_call() -> void:
	can_advance = false
	is_call_active = false
	
	if sfx_audio and sfx_pickup:
		sfx_audio.stream = sfx_pickup
		sfx_audio.play()
		
	if call_status:
		call_status.text = "🔴 CALL ENDED — MISSION: PACK GADGETS & RIDE TO BOYS SCHOOL"
		call_status.modulate = Color(1.0, 0.6, 0.2)
		
	# Switch directly to Protagonist in his room for the packing sequence
	start_bag_packing_sequence()

func start_bag_packing_sequence() -> void:
	switch_to_camera("player")
	if cam_player:
		cam_player.position = Vector3(0.0, 1.45, 0.4)
		cam_player.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	
	# Spawn desk gadget props in Room_Player
	var room_player_node = get_node_or_null("Room_Player")
	var desk_node = get_node_or_null("Room_Player/Desk")
	var player_vis = get_node_or_null("Room_Player/PlayerCharacter/VisualModel")
	
	var mat_bag = StandardMaterial3D.new()
	mat_bag.albedo_color = Color(0.12, 0.18, 0.32) # Dark navy blue backpack
	mat_bag.roughness = 0.8
	
	var mat_torch = StandardMaterial3D.new()
	mat_torch.albedo_color = Color(0.1, 0.1, 0.12)
	mat_torch.metallic = 0.7
	
	var mat_lens = StandardMaterial3D.new()
	mat_lens.albedo_color = Color(1.0, 0.9, 0.4)
	mat_lens.emission_enabled = true
	mat_lens.emission = Color(1.0, 0.9, 0.4)
	mat_lens.emission_energy_multiplier = 2.0
	
	var mat_emf = StandardMaterial3D.new()
	mat_emf.albedo_color = Color(0.08, 0.45, 0.15)
	mat_emf.emission_enabled = true
	mat_emf.emission = Color(0.1, 0.9, 0.2)
	mat_emf.emission_energy_multiplier = 1.5
	
	var mat_radio = StandardMaterial3D.new()
	mat_radio.albedo_color = Color(0.2, 0.2, 0.22)
	
	var props_root = Node3D.new()
	props_root.name = "PackingProps"
	if room_player_node:
		room_player_node.add_child(props_root)
	
	# Desk Backpack
	var desk_backpack = CSGBox3D.new()
	desk_backpack.size = Vector3(0.38, 0.46, 0.28)
	desk_backpack.position = Vector3(-0.45, 0.92, -1.5)
	desk_backpack.material = mat_bag
	props_root.add_child(desk_backpack)
	
	# Torch
	var prop_torch = CSGCylinder3D.new()
	prop_torch.radius = 0.04
	prop_torch.height = 0.24
	prop_torch.position = Vector3(-0.05, 0.92, -1.45)
	prop_torch.rotation_degrees = Vector3(90, 0, 0)
	prop_torch.material = mat_torch
	props_root.add_child(prop_torch)
	
	var prop_torch_head = CSGCylinder3D.new()
	prop_torch_head.radius = 0.055
	prop_torch_head.height = 0.05
	prop_torch_head.position = Vector3(0, 0.11, 0)
	prop_torch_head.material = mat_lens
	prop_torch.add_child(prop_torch_head)
	
	# EMF Meter
	var prop_emf = CSGBox3D.new()
	prop_emf.size = Vector3(0.12, 0.04, 0.22)
	prop_emf.position = Vector3(0.20, 0.92, -1.45)
	prop_emf.material = mat_emf
	props_root.add_child(prop_emf)
	
	# Walkie-Talkie
	var prop_radio = CSGBox3D.new()
	prop_radio.size = Vector3(0.09, 0.05, 0.18)
	prop_radio.position = Vector3(0.42, 0.92, -1.45)
	prop_radio.material = mat_radio
	props_root.add_child(prop_radio)
	
	var radio_antenna = CSGCylinder3D.new()
	radio_antenna.radius = 0.012
	radio_antenna.height = 0.14
	radio_antenna.position = Vector3(0.03, 0, -0.12)
	radio_antenna.rotation_degrees = Vector3(90, 0, 0)
	radio_antenna.material = mat_torch
	prop_radio.add_child(radio_antenna)
	
	# Subtitle announcement
	if subtitle_panel:
		subtitle_panel.visible = true
		subtitle_panel.modulate.a = 1.0
	if speaker_label:
		speaker_label.text = "🎒 मिशन: कमरे में जरूरी गैजेट्स व सामान की पैकिंग"
		speaker_label.modulate = Color(0.3, 0.95, 1.0)
	if dialogue_text:
		dialogue_text.text = "[तीनों दोस्तों ने अपने-अपने कमरों में सामान पैक करना शुरू किया... तूने टॉर्च, ईएमएफ डिटेक्टर, वॉकी-टॉकी और भानगढ़ के नोट्स बैग में भरे!]"
	if advance_tip:
		advance_tip.text = "[PACKING GADGETS INTO BACKPACK...]"
	
	# Smoothly animate gadgets sliding into the backpack!
	var tw_pack = create_tween()
	tw_pack.parallel().tween_property(prop_torch, "position", desk_backpack.position + Vector3(0, 0.1, 0), 0.9)
	tw_pack.parallel().tween_property(prop_torch, "scale", Vector3.ZERO, 0.9)
	tw_pack.parallel().tween_property(prop_emf, "position", desk_backpack.position + Vector3(0, 0.1, 0), 1.1)
	tw_pack.parallel().tween_property(prop_emf, "scale", Vector3.ZERO, 1.1)
	tw_pack.parallel().tween_property(prop_radio, "position", desk_backpack.position + Vector3(0, 0.1, 0), 1.3)
	tw_pack.parallel().tween_property(prop_radio, "scale", Vector3.ZERO, 1.3)
	
	await tw_pack.finished
	
	# Play zip / pack equip sound
	if sfx_audio:
		var stream_zip = load_stream_safe("res://audio/fir_stamp.wav")
		if not stream_zip: stream_zip = load_stream_safe("res://audio/complaint_writing.wav")
		if stream_zip:
			sfx_audio.stream = stream_zip
			sfx_audio.play()
	
	# Hide desk backpack and mount full 3D Backpack onto PlayerCharacter's back!
	desk_backpack.visible = false
	if player_vis:
		var back_pack = CSGBox3D.new()
		back_pack.name = "EquippedBackpack"
		back_pack.size = Vector3(0.36, 0.44, 0.22)
		back_pack.position = Vector3(0.0, 0.92, 0.22) # Strapped to back
		back_pack.material = mat_bag
		player_vis.add_child(back_pack)
		
		# Outer pouch
		var pouch = CSGBox3D.new()
		pouch.size = Vector3(0.26, 0.24, 0.08)
		pouch.position = Vector3(0.0, -0.05, 0.13)
		pouch.material = StandardMaterial3D.new()
		pouch.material.albedo_color = Color(0.18, 0.22, 0.35)
		back_pack.add_child(pouch)
		
		# Water Bottle on side
		var bottle = CSGCylinder3D.new()
		bottle.radius = 0.04
		bottle.height = 0.20
		bottle.position = Vector3(0.20, 0.0, 0.04)
		bottle.material = StandardMaterial3D.new()
		bottle.material.albedo_color = Color(0.2, 0.7, 0.9)
		back_pack.add_child(bottle)
	
	# Player dialogue
	if speaker_label:
		speaker_label.text = "🎒 तू (YOU) — [अपने कमरे से]"
		speaker_label.modulate = Color(0.35, 0.95, 1.0)
	if dialogue_text:
		dialogue_text.text = "\"सारे जरूरी गैजेट्स बैग में पैक हो गए! अब बाहर से अपनी साइकिल लेकर तुरंत बॉयज़ स्कूल निकलता हूँ!\""
	if advance_tip:
		advance_tip.text = "[CLICK / ENTER TO START CYCLE RIDE ➔]"
	
	await get_tree().create_timer(1.2).timeout
	
	# Show Proceed to Boys School Card
	if expedition_card:
		expedition_card.visible = true
		expedition_card.modulate.a = 0.0
		var card_title = expedition_card.get_node_or_null("Margin/VBox/Title")
		if card_title and card_title is Label:
			card_title.text = "🚲 MISSION: RIDE BICYCLE TO BOYS SCHOOL"
		var card_desc = expedition_card.get_node_or_null("Margin/VBox/Description")
		if card_desc and card_desc is Label:
			card_desc.text = "सामान बैग में पैक हो गया है! अब साइकिल चलाकर बॉयज़ स्कूल पहुँचें और आगे का पूरा प्लान बनाएं!"
		if proceed_btn:
			proceed_btn.text = "🚲 START CYCLE RIDE TO BOYS SCHOOL / साइकिल से बॉयज़ स्कूल निकलें ➔"
		var card_tw = create_tween()
		card_tw.tween_property(expedition_card, "modulate:a", 1.0, 0.8)
		
		# Enable clicking anywhere or pressing key to transition
		can_advance = true

func _on_proceed_chapter2_pressed() -> void:
	if proceed_btn:
		proceed_btn.disabled = true
		proceed_btn.text = "🚲 LOADING CYCLE RIDE TO BOYS SCHOOL..."
	
	# Fade out smoothly
	if subtitle_panel:
		var tw = create_tween()
		tw.tween_property(subtitle_panel, "modulate:a", 0.0, 0.4)
	
	get_tree().change_scene_to_file("res://scenes/cycle_to_school.tscn")
