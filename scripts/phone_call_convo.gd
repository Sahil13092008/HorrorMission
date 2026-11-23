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
	if ResourceLoader.exists(path):
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
				wav.data = bytes
				wav.format = AudioStreamWAV.FORMAT_16_BITS
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
		"text": "\"हाँ भाई बिल्कुल! सब अपना-अपना सामान पैक करो, आज रात हम सीधे भानगढ़ खंडहर के लिए निकलेंगे!\"",
		"audio": null
	},
	{
		"speaker_id": "aashutosh",
		"speaker": "👓 आशुतोष (AASHUTOSH) — [अपने कमरे से]",
		"color": Color(0.45, 0.8, 1.0),
		"text": "\"हाँ भाई, सारा ईएमएफ और थर्मल इक्विपमेंट तैयार है! कृपाल को किसी भी हाल में ढूंढना होगा!\"",
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
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
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
		
		# Auto advance after voice finishes if player hasn't clicked
		var current_idx = dialogue_index
		voice_audio.finished.connect(func():
			if dialogue_index == current_idx:
				await get_tree().create_timer(0.6).timeout
				if dialogue_index == current_idx:
					advance_dialogue()
		, CONNECT_ONE_SHOT)
		
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
		call_status.text = "🔴 CALL ENDED — MISSION DECISION FINALIZED"
		call_status.modulate = Color(1.0, 0.3, 0.3)
		
	if subtitle_panel:
		var fade_tw = create_tween()
		fade_tw.tween_property(subtitle_panel, "modulate:a", 0.0, 0.5)
		await fade_tw.finished
		subtitle_panel.visible = false
		
	# Reveal Chapter 1 Finale Briefing Card
	if expedition_card:
		expedition_card.visible = true
		expedition_card.modulate.a = 0.0
		var card_tw = create_tween()
		card_tw.tween_property(expedition_card, "modulate:a", 1.0, 0.8)

func _on_proceed_chapter2_pressed() -> void:
	if proceed_btn:
		proceed_btn.disabled = true
		proceed_btn.text = "➔ LOADING CHAPTER 2: EXPEDITION TO BHANGARH FORT..."
	get_tree().change_scene_to_file("res://scenes/bhangarh_ruins.tscn")
