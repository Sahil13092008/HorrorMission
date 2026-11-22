# ============================================================
# police_station.gd
# Scene: scenes/police_station.tscn
#
# Story: Player + Sahil + Aashutosh + Kripal's Parents arrive
#        at Pansemal Police Station, explain the situation,
#        file a complaint (FIR), then all go home.
#
# Dialogue: 100% Hindi subtitles (spoken) + English UI banners
# ============================================================

extends Node3D

# ── Audio nodes ──────────────────────────────────────────────
@onready var ambience_audio : AudioStreamPlayer = $Audio/AmbienceAudio
@onready var voice_audio    : AudioStreamPlayer = $Audio/VoiceAudio
@onready var sfx_audio      : AudioStreamPlayer = $Audio/SFXAudio

# ── UI nodes ─────────────────────────────────────────────────
@onready var mission_banner  : Label       = $UI/CanvasLayer/MissionBanner
@onready var dialogue_box    : PanelContainer = $UI/CanvasLayer/DialogueBox
@onready var portrait_rect   : TextureRect = $UI/CanvasLayer/DialogueBox/HBox/Portrait
@onready var speaker_label   : Label       = $UI/CanvasLayer/DialogueBox/HBox/VBox/Speaker
@onready var text_label      : Label       = $UI/CanvasLayer/DialogueBox/HBox/VBox/Text
@onready var advance_tip     : Label       = $UI/CanvasLayer/DialogueBox/HBox/VBox/Tip
@onready var fade_overlay    : ColorRect   = $UI/CanvasLayer/FadeOverlay

# ── Character nodes ───────────────────────────────────────────
@onready var officer_npc     : Node3D = $Characters/PoliceOfficer
@onready var kripal_mummy    : Node3D = $Characters/KripalMummy
@onready var sahil_char      : Node3D = $Characters/Sahil
@onready var aashu_char      : Node3D = $Characters/Aashutosh
@onready var player_char     : Node3D = $Characters/Player

# ── Props ─────────────────────────────────────────────────────
@onready var stamp_prop      : Node3D = $Props/StampProp
@onready var fir_paper       : Node3D = $Props/FIRPaper

# ── Preloaded Audio ───────────────────────────────────────────
var snd_ambience  = preload("res://audio/police_station_ambience.wav")
var snd_stamp     = preload("res://audio/fir_stamp.wav")
var snd_writing   = preload("res://audio/complaint_writing.wav")
var snd_door      = preload("res://audio/station_door.wav")

# ── Portraits ─────────────────────────────────────────────────
var avatar_player  = preload("res://textures/avatar_player.png")
var avatar_sahil   = preload("res://textures/avatar_sahil.png")
var avatar_aashu   = preload("res://textures/avatar_aashutosh.png")
var avatar_mummy   = preload("res://textures/avatar_player.png")   # fallback if no mummy avatar
var avatar_officer = preload("res://textures/avatar_mission.png")  # fallback

# ── Dialogue data ─────────────────────────────────────────────
# Format: { speaker, color, portrait, text, sfx (optional) }
var dialogues = [
	{
		"speaker": "POLICE OFFICER (थानेदार साहब) 👮",
		"color": Color(0.4, 0.8, 1.0),
		"portrait": "officer",
		"text": "\"नमस्ते। बताइए, क्या शिकायत है आपकी? यहाँ किस लिए आए हैं?\""
	},
	{
		"speaker": "YOU (तुम) 🗣️",
		"color": Color(0.3, 0.9, 1.0),
		"portrait": "player",
		"text": "\"सर, हमारे दोस्त कृपाल का कल शाम को स्कूल के क्लासरूम से अपहरण हो गया। हमें एक पर्ची मिली थी — FIND ME AT BHANGARH!\""
	},
	{
		"speaker": "KRIPAL'S MOTHER (कृपाल की माँ) 😢",
		"color": Color(1.0, 0.7, 0.9),
		"portrait": "mummy",
		"text": "\"सर जी, मेरा बेटा... मेरा बेटा कहाँ है? वो कल से घर नहीं आया। कृपया उसे ढूंढो!\""
	},
	{
		"speaker": "SAHIL (साहिल) 🗣️",
		"color": Color(1.0, 0.85, 0.2),
		"portrait": "sahil",
		"text": "\"सर, यह पर्ची उसकी डेस्क पर मिली थी और उसके खून के निशान भी थे। हमें लगता है उसे भानगढ़ किले में किसी ने खींच लिया।\""
	},
	{
		"speaker": "AASHUTOSH (आशुतोष) 🗣️",
		"color": Color(1.0, 0.45, 0.2),
		"portrait": "aashu",
		"text": "\"हाँ सर, मेरे EMF मीटर पर भी असामान्य रीडिंग आई थी। कुछ तो परानॉर्मल था वहाँ पर!\""
	},
	{
		"speaker": "POLICE OFFICER (थानेदार साहब) 👮",
		"color": Color(0.4, 0.8, 1.0),
		"portrait": "officer",
		"text": "\"ठीक है। हम इस मामले की जाँच करेंगे। आपका FIR दर्ज किया जाता है। अभी के लिए आप सब घर जाइए, हम कल सुबह भानगढ़ की जाँच शुरू करेंगे।\""
	},
	{
		"speaker": "YOU (तुम) 🗣️",
		"color": Color(0.3, 0.9, 1.0),
		"portrait": "player",
		"text": "\"ठीक है सर, धन्यवाद। पर हम खुद भी कृपाल को ढूंढने की कोशिश करेंगे।\""
	},
	{
		"speaker": "★ MISSION COMPLETE ★",
		"color": Color(1.0, 0.2, 0.2),
		"portrait": "officer",
		"text": "\"FIR दर्ज हो गई। अब सब अपने-अपने घर जाओ और कल की तैयारी करो!\""
	}
]

var dialogue_index = 0
var is_in_dialogue = false
var complaint_filed = false

# ── Lifecycle ─────────────────────────────────────────────────
func _ready():
	# Hide UI initially
	if mission_banner: mission_banner.visible = false
	if dialogue_box:   dialogue_box.visible = false
	if fade_overlay:   fade_overlay.visible = true
	if fade_overlay:   fade_overlay.color = Color(0, 0, 0, 1)

	# Start ambience
	if ambience_audio:
		ambience_audio.stream = snd_ambience
		ambience_audio.loop   = true
		ambience_audio.play()

	# Fade in
	await get_tree().create_timer(0.3).timeout
	fade_in()


func _input(event):
	if not is_in_dialogue: return
	var advance = (
		(event is InputEventKey and event.pressed and
		 event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER])
		or
		(event is InputEventMouseButton and event.pressed and
		 event.button_index == MOUSE_BUTTON_LEFT)
	)
	if advance:
		get_viewport().set_input_as_handled()
		advance_dialogue()


# ── Fade helpers ──────────────────────────────────────────────
func fade_in():
	fade_overlay.visible = true
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	await tw.finished
	fade_overlay.visible = false
	await get_tree().create_timer(0.5).timeout
	show_mission_banner("CHAPTER 1 — PART III : PANSEMAL POLICE STATION", 3.0)


func fade_out(duration := 1.5):
	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 0)
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tw.finished


# ── Mission banner ────────────────────────────────────────────
func show_mission_banner(text: String, hold := 2.5):
	if not mission_banner: return
	mission_banner.text = text
	mission_banner.visible = true
	mission_banner.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(mission_banner, "modulate:a", 1.0, 0.6)
	await tw.finished
	await get_tree().create_timer(hold).timeout
	tw = create_tween()
	tw.tween_property(mission_banner, "modulate:a", 0.0, 0.6)
	await tw.finished
	mission_banner.visible = false
	# Start dialogue after banner
	await get_tree().create_timer(0.4).timeout
	start_dialogue()


# ── Dialogue ──────────────────────────────────────────────────
func start_dialogue():
	dialogue_index = 0
	is_in_dialogue = true
	show_dialogue_line(dialogue_index)


func show_dialogue_line(idx: int):
	if idx >= dialogues.size():
		end_dialogue()
		return

	var d = dialogues[idx]
	speaker_label.text    = d["speaker"]
	speaker_label.add_theme_color_override("font_color", d["color"])
	text_label.text       = d["text"]
	advance_tip.text      = "[ E / SPACE / CLICK — NEXT ]"

	# Set portrait
	match d["portrait"]:
		"player":   portrait_rect.texture = avatar_player
		"sahil":    portrait_rect.texture = avatar_sahil
		"aashu":    portrait_rect.texture = avatar_aashu
		"mummy":    portrait_rect.texture = avatar_mummy
		_:          portrait_rect.texture = avatar_officer

	dialogue_box.visible = true

	# Play SFX at key moments
	if idx == 5:   # Officer says FIR darz
		await get_tree().create_timer(0.3).timeout
		if sfx_audio:
			sfx_audio.stream = snd_writing
			sfx_audio.play()
		await get_tree().create_timer(2.0).timeout
		if sfx_audio:
			sfx_audio.stream = snd_stamp
			sfx_audio.play()
		# Animate FIR paper
		if fir_paper:
			var tw = create_tween()
			tw.tween_property(fir_paper, "scale", Vector3(1.2, 1.2, 1.2), 0.4)
			tw.tween_property(fir_paper, "scale", Vector3(1.0, 1.0, 1.0), 0.2)


func advance_dialogue():
	dialogue_index += 1
	if dialogue_index >= dialogues.size():
		end_dialogue()
	else:
		show_dialogue_line(dialogue_index)


func end_dialogue():
	is_in_dialogue   = false
	complaint_filed  = true
	dialogue_box.visible = false

	await get_tree().create_timer(0.5).timeout
	play_exit_animation()


# ── Exit animation ────────────────────────────────────────────
func play_exit_animation():
	# Show mission complete banner
	await show_mission_banner("COMPLAINT FILED  —  CHAPTER 1 : PART III COMPLETE", 2.5)

	# Walk characters toward door
	if player_char:
		var tw = create_tween()
		tw.tween_property(player_char, "position:z", player_char.position.z + 4.0, 1.5)
	if sahil_char:
		var tw2 = create_tween()
		tw2.tween_property(sahil_char, "position:z", sahil_char.position.z + 4.0, 1.5)
	if aashu_char:
		var tw3 = create_tween()
		tw3.tween_property(aashu_char, "position:z", aashu_char.position.z + 4.0, 1.5)
	if kripal_mummy:
		var tw4 = create_tween()
		tw4.tween_property(kripal_mummy, "position:z", kripal_mummy.position.z + 4.0, 1.7)

	# Door sound
	await get_tree().create_timer(1.0).timeout
	if sfx_audio:
		sfx_audio.stream = snd_door
		sfx_audio.play()

	await get_tree().create_timer(1.5).timeout

	# Fade out → go home (back to street scene)
	await fade_out(1.5)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/street_to_kripal.tscn")
