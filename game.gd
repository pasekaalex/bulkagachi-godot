extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# BULKAGACHI - Full Game Engine (Godot 4.x)
# Port from original BulkagachiEngine.ts
# ══════════════════════════════════════════════════════════════════════════════

# ENUMS
enum Stage { EGG, BABY, TEEN_GOOD, TEEN_BAD, ADULT, ELDER }
enum Weather { SUNNY, RAIN, SNOW, STORM }

const WEATHER_LOCATIONS = ["camp", "city", "mountain"]
const DECAY_NIGHT_MULT = 0.7

# GAME STATE
var pet_name: String = "Bulk"
var hunger: float = 100.0
var happiness: float = 100.0
var cleanliness: float = 100.0
var energy: float = 100.0
var level: int = 1
var xp: int = 0
var xp_needed: int = 75
var birth_time: int = 0
var age_minutes: int = 0
var current_stage: Stage = Stage.EGG
var teen_type: String = ""
var evolution_pending: String = ""
var is_sleeping: bool = false
var is_sick: bool = false
var is_angry: bool = false  # Wake up angry if sleep too short
var sleep_start_time: int = 0
var is_ghost: bool = false
var ghost_since: int = 0
var poop_count: int = 0
var poop_list: Array = []
var has_egg: bool = true
var egg_start_time: int = 0
var egg_hatch_time: int = 0
var current_location: String = "cabin"
var weather: Weather = Weather.SUNNY
var weather_timer: float = 0.0
var total_plays: int = 0
var total_feeds: int = 0
var total_cleans: int = 0
var total_sleeps: int = 0
var medicine_used: int = 0
var visited_locations: Array = []
var golden_poops_found: int = 0
var achievements: Dictionary = {}
var last_schmeg_time: int = 0

# Animation
var pace_offset: float = 0.0
var pace_direction: int = 1
var pace_timer: float = 0.0
var is_pacing: bool = true
var bob_offset: float = 0.0
var flip_offset: float = 1.0
var last_flip_time: int = 0
var egg_tilt: float = 0.0
var bounce_offset: float = 0.0
var is_bouncing: bool = false
var bounce_timer: float = 0.0

# Visual effects
var screen_shake: float = 0.0
var screen_shake_offset: Vector2 = Vector2.ZERO

# Floating effects sprites
var heart_sprite: Sprite2D
var schmeg_sprite: Sprite2D
var medicine_sprite: Sprite2D
var food_sprite: Sprite2D

# Audio
var audio_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var music_enabled: bool = true

# Play a simple beep sound
func _play_sound(type: String) -> void:
	# Simple synthesized sounds using Tones
	match type:
		"feed":
			_play_tone(440, 0.1, 0.2)  # Quick chirp
		"play":
			_play_tone(523, 0.1, 0.15)
			_play_tone(659, 0.15, 0.15)
		"clean":
			_play_tone(800, 0.1, 0.1)
			_play_tone(400, 0.2, 0.1)
		"pet":
			_play_tone(300, 0.05, 0.1)
			_play_tone(400, 0.1, 0.1)

func _play_tone(freq: float, start_time: float, duration: float) -> void:
	# For now we skip actual sound generation
	# In Godot you'd use AudioStreamPlayer with generated audio
	pass

# Effects
var floating_hearts: Array = []
var floating_schmegs: Array = []
var floating_medicines: Array = []
var floating_foods: Array = []

# ACHIEVEMENTS
const ACHIEVEMENTS = {
	"first_feed": {"title": "First Snack", "icon": "🍼"},
	"first_play": {"title": "Playtime!", "icon": "🎾"},
	"first_clean": {"title": "Sparkle Clean", "icon": "🧼"},
	"first_medicine": {"title": "Doctor Bulk", "icon": "💊"},
	"first_sleep": {"title": "Nap Time", "icon": "😴"},
	"level5": {"title": "Growing Up", "icon": "⭐"},
	"level10": {"title": "Teen Bulk", "icon": "🌟"},
	"level25": {"title": "Bulk Adult", "icon": "🌠"},
	"level50": {"title": "Legendary Bulk", "icon": "👑"},
	"level99": {"title": "MAXIMUM BULK", "icon": "💎"},
	"poop50": {"title": "Poop Master", "icon": "💩"},
	"poop100": {"title": "Poop Legend", "icon": "🚽"},
	"golden": {"title": "Lucky Find", "icon": "✨"},
	"age24h": {"title": "Day Old", "icon": "🎂"},
	"age7d": {"title": "Week Old", "icon": "📅"},
	"first_hatch": {"title": "New Life", "icon": "🐣"},
	"travel_camp": {"title": "Camper", "icon": "⛺"},
	"travel_city": {"title": "City Slicker", "icon": "🏙️"},
	"travel_beach": {"title": "Beachgoer", "icon": "🏖️"},
	"travel_mountain": {"title": "Mountain Climber", "icon": "🏔️"},
	"feed100": {"title": "Well Fed", "icon": "🍖"},
	"play100": {"title": "Playful", "icon": "🎮"},
	"sick_cured": {"title": "Healer", "icon": "🩺"},
	"teen_good": {"title": "Good Boy", "icon": "😇"},
	"teen_bad": {"title": "Bad Boy", "icon": "😈"},
	"elder": {"title": "Elder Bulk", "icon": "🧓"},
}

const SPRITE_PATH = "res://assets/sprites/"
const BG_PATH = "res://assets/backgrounds/"

# Node references
@onready var pet_sprite: Sprite2D = $Pet
@onready var bg_sprite: Sprite2D = $Background
@onready var hunger_label: Label = $UI/StatsGrid/HungerRow/Value
@onready var happiness_label: Label = $UI/StatsGrid/HappinessRow/Value
@onready var clean_label: Label = $UI/StatsGrid/CleanRow/Value
@onready var energy_label: Label = $UI/StatsGrid/EnergyRow/Value

# Stats colors (for label colors)
@onready var hunger_label: Label = $UI/StatsGrid/HungerRow/Value
@onready var xp_label: Label = $UI/XPLabel
@onready var stage_label: Label = $UI/StatsPanel/VBox/Header/StageLabel
@onready var egg_label: Label = $UI/StatsPanel/VBox/EggLabel

# Status indicators
@onready var poop_indicator: Label = $UI/StatusIndicators/PoopCount
@onready var weather_indicator: Label = $UI/StatusIndicators/WeatherIcon
@onready var sick_indicator: Label = $UI/StatusIndicators/SickIcon
@onready var sleep_indicator: Label = $UI/StatusIndicators/SleepIcon
@onready var ghost_indicator: Label = $UI/StatusIndicators/GhostIcon
@onready var hint_label: Label = $UI/Hint
@onready var age_label: Label = $UI/StatsPanel/VBox/Age
@onready var message_label: Label = $UI/MessageLabel
@onready var location_btn: Button = $UI/LocationBtn
@onready var feed_btn: Button = $UI/Actions/FeedBtn
@onready var play_btn: Button = $UI/Actions/PlayBtn
@onready var clean_btn: Button = $UI/Actions/CleanBtn
@onready var sleep_btn: Button = $UI/Actions/SleepBtn
@onready var medicine_btn: Button = $UI/Actions/MedicineBtn
@onready var rest_btn: Button = $UI/Actions/RestBtn
@onready var schmeg_btn: Button = $UI/Actions/SchmegBtn
@onready var music_btn: Button = $UI/MusicBtn
@onready var bg_overlay: ColorRect = $BgOverlay
@onready var collection_btn: Button = $UI/CollectionBtn
@onready var rename_btn: Button = $UI/RenameBtn
@onready var minigame_btn: Button = $UI/MiniGameBtn

# Mini-game
var minigame_active: bool = false
var minigame_score: int = 0
var minigame_time_remaining: int = 10

# Mini-game
var minigame_active: bool = false
var minigame_score: int = 0
var minigame_time: int = 10
var minigame_timer: int = 0

@onready var minigame_panel: Control = $UI/MiniGamePanel
@onready var minigame_btn: Button = $UI/RenameBtn  # Reuse rename button area for mini-game

# Mini-game
@onready var minigame_panel: Control = $UI/MiniGamePanel
@onready var tap_target: Button = $UI/MiniGamePanel/VBox/TapTarget
@onready var tap_score_label: Label = $UI/MiniGamePanel/VBox/ScoreLabel
@onready var tap_time_label: Label = $UI/MiniGamePanel/VBox/TimeLabel
@onready var minigame_close_btn: Button = $UI/MiniGamePanel/VBox/GameCloseBtn
@onready var collection_panel: Control = $UI/CollectionPanel
@onready var stats_list: Label = $UI/CollectionPanel/VBox/StatsList
@onready var achievements_list: Label = $UI/CollectionPanel/VBox/AchievementsList
@onready var close_collection_btn: Button = $UI/CollectionPanel/VBox/CloseBtn
@onready var evolve_btn: Button = $UI/EvolveBtn
@onready var teen_choice_panel: Control = $UI/TeenChoicePanel
@onready var good_btn: Button = $UI/TeenChoicePanel/VBox/GoodBtn
@onready var bad_btn: Button = $UI/TeenChoicePanel/VBox/BadBtn

# For rendering poops and effects
var poop_label: Label
var heart_sprite: Sprite2D
var ui_layer: CanvasLayer
var _last_weather_update: int = 0

func _ready() -> void:
	feed_btn.pressed.connect(_on_feed_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	clean_btn.pressed.connect(_on_clean_pressed)
	sleep_btn.pressed.connect(_on_sleep_pressed)
	medicine_btn.pressed.connect(_on_medicine_pressed)
	rest_btn.pressed.connect(_on_rest_pressed)
	schmeg_btn.pressed.connect(_on_schmeg_pressed)
	location_btn.pressed.connect(_on_location_pressed)
	evolve_btn.pressed.connect(_on_evolve_pressed)
	music_btn.pressed.connect(_on_music_pressed)
	collection_btn.pressed.connect(_on_collection_pressed)
	rename_btn.pressed.connect(_on_rename_pressed)
	minigame_btn.pressed.connect(_on_minigame_pressed)
	tap_target.pressed.connect(_on_tap_pressed)
	minigame_close_btn.pressed.connect(_on_minigame_close_pressed)
	close_collection_btn.pressed.connect(func(): collection_panel.visible = false)
	good_btn.pressed.connect(func(): choose_teen_path("good"))
	bad_btn.pressed.connect(func(): choose_teen_path("bad"))
	
	pet_sprite.input_event.connect(_on_pet_clicked)
	
	_load_game()
	if not has_egg and birth_time == 0:
		_start_new_game()
		show_message("🥚 Welcome! Your egg will hatch in 1 hour.")
	
	teen_choice_panel.visible = false
	
	# Create floating effect sprites
	heart_sprite = Sprite2D.new()
	schmeg_sprite = Sprite2D.new()
	medicine_sprite = Sprite2D.new()
	food_sprite = Sprite2D.new()
	
	# Try to load textures
	if ResourceLoader.exists(SPRITE_PATH + "heart.png"):
		heart_sprite.texture = load(SPRITE_PATH + "heart.png")
	if ResourceLoader.exists(SPRITE_PATH + "schmeg.png"):
		schmeg_sprite.texture = load(SPRITE_PATH + "schmeg.png")
	if ResourceLoader.exists(SPRITE_PATH + "schmeg.png"):
		medicine_sprite.texture = load(SPRITE_PATH + "schmeg.png")  # Use schmeg as medicine visual
	if ResourceLoader.exists(SPRITE_PATH + "cover-baby.png"):
		food_sprite.texture = load(SPRITE_PATH + "cover-baby.png")  # Use cover as food visual
	
	add_child(heart_sprite)
	add_child(schmeg_sprite)
	add_child(medicine_sprite)
	add_child(food_sprite)
	
	# Audio player
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Background music player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	bgm_player.volume_db = -10
	add_child(bgm_player)
	
	# Try to load and play background music
	if ResourceLoader.exists("res://assets/audio/bgm.mp3"):
		bgm_player.stream = load("res://assets/audio/bgm.mp3")
		bgm_player.play()
		bgm_player.volume_db = -15  # Start quiet
	
	_update_ui()

func _process(delta: float) -> void:
	var now = Time.get_unix_time_from_system()
	
	if has_egg:
		if now >= egg_hatch_time:
			_hatch_egg()
		var elapsed = now - egg_start_time
		var progress = min(elapsed / 60.0, 1.0)
		egg_tilt = sin(now * 0.5) * (0.04 + progress * 0.04)
		_update_ui()
		return
	
	age_minutes = int((now - birth_time) / 60)
	
	# Birthday celebrations
	var age_hours = age_minutes / 60
	if birth_time > 0:
		# 24 hour birthday
		if age_minutes >= 1440 and age_minutes < 1441:
			happiness = 100.0
			show_message("🎂 HAPPY 1ST BIRTHDAY!")
			_unlock_achievement("age24h")
		# 1 week birthday
		if age_minutes >= 10080 and age_minutes < 10081:
			happiness = 100.0
			show_message("🎉 HAPPY 1 WEEK BIRTHDAY!")
			_unlock_achievement("age7d")
	
	# Time-based greetings (once per hour max)
	if now - _last_greeting_time >= 3600:
		var hour = Time.get_datetime_dict_from_system().hour
		var greeting = ""
		if hour >= 5 and hour < 8:
			greeting = "🌅 Good morning!"
		elif hour >= 8 and hour < 12:
			greeting = "☀️ Hello!"
		elif hour >= 12 and hour < 14:
			greeting = "🌞 Good afternoon!"
		elif hour >= 14 and hour < 17:
			greeting = "🌤️ Good afternoon!"
		elif hour >= 17 and hour < 21:
			greeting = "🌆 Good evening!"
		elif hour >= 21 or hour < 5:
			greeting = "🌙 Good night!"
		
		if greeting and randf() < 0.3:  # 30% chance
			show_message(greeting)
			_last_greeting_time = now
	
	if now - _last_stat_update >= 1:
		_last_stat_update = now
		_update_stats(now)
		_check_evolution()
		_check_death()
		_save_game()
	
	if now - _last_weather_update >= 300:
		_last_weather_update = now
		_update_weather()
	
	_update_animations(now)
	_update_floating_effects(delta)
	_update_ui()
	
	# Mini-game timer
	if minigame_active:
		minigame_time_remaining -= delta
		if minigame_time_remaining <= 0:
			minigame_time_remaining = 0
			_on_minigame_close_pressed()
		_update_minigame_ui()
	
	# Screen shake decay
	if screen_shake > 0:
		screen_shake -= delta
		screen_shake_offset = Vector2(randf() * 10 - 5, randf() * 10 - 5) * screen_shake
	else:
		screen_shake_offset = Vector2.ZERO
	
	# Apply screen shake to UI
	ui_layer.position = screen_shake_offset

var _last_notification_time: int = 0
var _last_greeting_time: int = 0

func _update_stats(now: int) -> void:
	if is_sleeping:
		var hour = Time.get_datetime_dict_from_system().hour
		var regen_rate = 100.0 / 600.0
		if hour >= 18 or hour < 6:
			regen_rate *= 3
		energy = min(100.0, energy + regen_rate)
		if energy >= 100:
			is_sleeping = false
			show_message("Good morning!")
	else:
		var hunger_decay = 100.0 / 600.0
		var happiness_decay = 100.0 / 840.0
		var cleanliness_decay = 100.0 / 2160.0
		var energy_decay = 100.0 / 960.0
		
		var hour = Time.get_datetime_dict_from_system().hour
		if hour >= 18 or hour < 6:
			hunger_decay *= DECAY_NIGHT_MULT
			happiness_decay *= DECAY_NIGHT_MULT
			cleanliness_decay *= DECAY_NIGHT_MULT
			energy_decay *= DECAY_NIGHT_MULT
		
		match current_location:
			"camp":
				happiness_decay *= 0.7
			"city":
				cleanliness_decay *= 1.5
				energy_decay *= 1.5
			"beach":
				cleanliness_decay *= 1.3
				happiness_decay *= 0.8
				energy_decay *= 0.8
			"mountain":
				hunger_decay *= 0.7
				happiness_decay *= 0.6
				energy_decay *= 0.7
		
		var poop_penalty = poop_list.size() * 0.02
		
		hunger = max(0.0, hunger - hunger_decay)
		happiness = max(0.0, happiness - happiness_decay - poop_penalty)
		cleanliness = max(0.0, cleanliness - cleanliness_decay)
		energy = max(0.0, energy - energy_decay)
		
		if randf() < 0.001:
			_spawn_poop()
		
		# Send notifications for low stats (throttled to once per 5 minutes)
		if now - _last_notification_time >= 300:
			if hunger < 20:
				show_message("😰 Bulk is hungry!")
				_last_notification_time = now
			elif energy < 20:
				show_message("😴 Bulk is tired!")
				_last_notification_time = now
			elif happiness < 20:
				show_message("💔 Bulk is sad!")
				_last_notification_time = now

func _check_evolution() -> void:
	# Don't check if already pending or no age yet
	if evolution_pending != "" or birth_time == 0:
		return
	
	var age_hours = age_minutes / 60
	
	match current_stage:
		Stage.BABY:
			if age_hours >= 8 and teen_type == "":
				evolution_pending = "TEEN"
				teen_choice_panel.visible = true
				show_message("✨ TEEN READY! CHOOSE YOUR PATH!")
		Stage.TEEN_GOOD, Stage.TEEN_BAD:
			if age_hours >= 24:
				evolution_pending = "ADULT"
				show_message("✨ ADULT READY! PRESS EVOLVE!")
		Stage.ADULT:
			if age_hours >= 168:
				evolution_pending = "ELDER"
				show_message("✨ ELDER READY! PRESS EVOLVE!")
	
	evolve_btn.visible = evolution_pending != "" and evolution_pending != "TEEN"

func _hatch_egg() -> void:
	has_egg = false
	birth_time = Time.get_unix_time_from_system()
	age_minutes = 0
	current_stage = Stage.BABY
	# Starter bonus
	_add_xp(25)
	happiness = 100
	energy = 100
	_trigger_bounce()
	_trigger_screen_shake()
	_unlock_achievement("first_hatch")
	show_message("🥚 WELCOME " + pet_name.to_upper() + "!")
	show_message("❤️ +25 XP!")

func choose_teen_path(path: String) -> void:
	if evolution_pending != "TEEN":
		return
	
	teen_type = path
	teen_choice_panel.visible = false
	
	# Play special animation/effect
	_trigger_screen_shake()
	_trigger_bounce()
	
	if path == "good":
		current_stage = Stage.TEEN_GOOD
		_unlock_achievement("teen_good")
		show_message("✨ BECAME GOOD BOY!")
	else:
		current_stage = Stage.TEEN_BAD
		_unlock_achievement("teen_bad")
		show_message("✨ BECAME BAD BOY!")
	
	evolution_pending = ""
	_save_game()

func confirm_evolution() -> void:
	if evolution_pending == "" or evolution_pending == "TEEN":
		return
	
	match evolution_pending:
		"ADULT":
			current_stage = Stage.ADULT
			show_message("✨ EVOLVED TO ADULT!")
		"ELDER":
			current_stage = Stage.ELDER
			_unlock_achievement("elder")
			show_message("✨ EVOLVED TO ELDER!")
	
	evolution_pending = ""
	_save_game()

func _check_death() -> void:
	if is_ghost:
		return
	
	if hunger <= 0:
		is_ghost = true
		ghost_since = Time.get_unix_time_from_system()
		hunger = 100
		happiness = 100
		cleanliness = 100
		energy = 100
		show_message("👻 BULK BECAME A GHOST!")
		current_location = "tomb"

# ACTIONS
func _on_feed_pressed() -> void:
	if has_egg or is_sleeping or is_ghost:
		return
	
	# Combo system - interact within 2 seconds = combo
	var now = Time.get_unix_time_from_system()
	if now - last_interact_time < 2:
		combo_count += 1
		if combo_count >= 5:
			show_message("🔥 COMBO x" + str(combo_count) + "!")
	else:
		combo_count = 1
	last_interact_time = now
	
	var xp_bonus = 0
	if combo_count >= 5:
		xp_bonus = combo_count * 2
	
	hunger = min(100.0, hunger + 30)
	energy = max(0.0, energy - 2)
	total_feeds += 1
	_add_xp(10 + xp_bonus)
	_spawn_floating_food()
	_spawn_floating_heart()
	_trigger_bounce()
	show_message("Yum!")
	_play_sound("feed")
	
	if total_feeds == 1:
		_unlock_achievement("first_feed")
	if total_feeds >= 100:
		_unlock_achievement("feed100")
	
	_check_sickness()

func _on_play_pressed() -> void:
	if has_egg or is_sleeping or is_ghost:
		return
	
	if energy < 10:
		show_message("Too tired to play...")
		return
	
	# Combo
	var now = Time.get_unix_time_from_system()
	if now - last_interact_time < 2:
		combo_count += 1
	else:
		combo_count = 1
	last_interact_time = now
	
	var xp_bonus = 0
	if combo_count >= 5:
		xp_bonus = combo_count * 2
	
	happiness = min(100.0, happiness + 20)
	energy = max(0.0, energy - 15)
	total_plays += 1
	_add_xp(15 + xp_bonus)
	_spawn_floating_heart()
	_trigger_bounce()
	show_message("Fun!")
	_play_sound("play")
	
	if total_plays == 1:
		_unlock_achievement("first_play")
	if total_plays >= 100:
		_unlock_achievement("play100")
	
	_check_sickness()

func _on_clean_pressed() -> void:
	if has_egg or is_sleeping or is_ghost:
		return
	
	var golden_count = 0
	for poop in poop_list:
		if poop.get("is_golden", false):
			golden_count += 1
	
	if golden_count > 0:
		golden_poops_found += golden_count
		show_message("✨ FOUND %d GOLDEN POOP!" % golden_count)
		if golden_poops_found >= 1:
			_unlock_achievement("golden")
	
	poop_list.clear()
	poop_count = 0
	cleanliness = 100.0
	is_sick = false
	total_cleans += 1
	_add_xp(10)
	show_message("✨ Sparkling clean!")
	
	if total_cleans == 1:
		_unlock_achievement("first_clean")
	if total_cleans >= 50:
		_unlock_achievement("poop50")
	if total_cleans >= 100:
		_unlock_achievement("poop100")

func _on_sleep_pressed() -> void:
	if has_egg or is_ghost:
		return
	
	is_sleeping = not is_sleeping
	
	if is_sleeping:
		sleep_start_time = Time.get_unix_time_from_system()
		total_sleeps += 1
		show_message("Goodnight...")
		_unlock_achievement("first_sleep")
	else:
		# Check if slept long enough (at least 30 seconds for testing, real: 4 hours)
		var sleep_time = Time.get_unix_time_from_system() - sleep_start_time
		if sleep_time < 30:
			is_angry = true
			show_message("😠 Too short! Bulk is grumpy!")
		else:
			is_angry = false
			show_message("Good morning!")
			if hunger < 30:
				show_message("😠 Grumpy from hunger!")

func _on_medicine_pressed() -> void:
	if has_egg or is_ghost or not is_sick:
		return
	
	is_sick = false
	happiness = min(100.0, happiness + 20)
	_spawn_floating_medicine()
	show_message("💊 Cured!")
	_play_sound("clean")
	_unlock_achievement("first_medicine")

func _on_schmeg_pressed() -> void:
	if has_egg or is_ghost:
		return
	
	var now = Time.get_unix_time_from_system()
	if now - last_schmeg_time < 300:
		show_message("⏳ Cooldown...")
		return
	
	last_schmeg_time = now
	energy = min(100.0, energy + 30)
	_spawn_floating_schmeg()
	show_message("⚡ Energy!")
	_play_sound("play")

func _on_rest_pressed() -> void:
	if has_egg or is_ghost:
		return
	
	var now = Time.get_unix_time_from_system()
	if now - last_rest_time < 60:  # 1 minute cooldown
		show_message("⏳ Just rested!")
		return
	
	last_rest_time = now
	energy = min(100.0, energy + 15)
	show_message("🪑 Rested! +15 Energy")

func _on_location_pressed() -> void:
	var locations = ["cabin", "camp", "city", "beach", "mountain", "club"]
	var current_idx = locations.find(current_location)
	var next_idx = (current_idx + 1) % locations.size()
	
	var hour = Time.get_datetime_dict_from_system().hour
	if hour >= 18 or hour < 2:
		if locations[next_idx] in ["beach", "mountain"]:
			next_idx = locations.find("camp")
	
	current_location = locations[next_idx]
	if not current_location in visited_locations:
		visited_locations.append(current_location)
	_load_background()
	_play_location_music()
	show_message("📍 " + current_location.to_upper())
	
	match current_location:
		"camp": _unlock_achievement("travel_camp")
		"city": _unlock_achievement("travel_city")
		"beach": _unlock_achievement("travel_beach")
		"mountain": _unlock_achievement("travel_mountain")

func _on_evolve_pressed() -> void:
	confirm_evolution()

func _on_music_pressed() -> void:
	music_enabled = not music_enabled
	if music_enabled:
		_play_location_music()
		music_btn.text = "🎵 ON"
	else:
		bgm_player.stop()
		music_btn.text = "🔇 OFF"

func _on_collection_pressed() -> void:
	collection_panel.visible = not collection_panel.visible
	
	if collection_panel.visible:
		# Update stats
		var stats_text = "🍗 Fed: %d times\n" % total_feeds
		stats_text += "🎾 Played: %d times\n" % total_plays
		stats_text += "🧼 Cleaned: %d times\n" % total_cleans
		stats_text += "✨ Golden Poops: %d\n" % golden_poops_found
		stats_text += "⭐ Level: %d\n" % level
		stats_text += "� Total XP: %d\n" % xp
		stats_text += "⏱️ Time Played: %s" % _format_time(total_time_played())
		stats_list.text = stats_text
		
		# Update achievements
		var ach_text = ""
		for id in ACHIEVEMENTS:
			if achievements.has(id):
				ach_text += "✅ " + ACHIEVEMENTS[id].title + "\n"
			else:
				ach_text += "⬜ " + ACHIEVEMENTS[id].title + "\n"
		achievements_list.text = ach_text

func _format_time(seconds: int) -> String:
	var hours = seconds / 3600
	var mins = (seconds % 3600) / 60
	if hours > 0:
		return "%dh %dm" % [hours, mins]
	return "%dm" % mins

const COOL_NAMES = ["Bulk", "Chonk", "Puff", "Fluff", "Chunk", "Bean", "Peanut", "Mochi", "Dumpling", "Nugget", "Waffle", "Pancake", "Muffin", "Biscuit", "Cinnamon", "Ginger", "Oreo", "Cookie", "Brownie", "Cupcake"]

func _on_rename_pressed() -> void:
	# Cycle to next name
	var current_idx = COOL_NAMES.find(pet_name)
	if current_idx == -1:
		current_idx = 0
	else:
		current_idx = (current_idx + 1) % COOL_NAMES.size()
	pet_name = COOL_NAMES[current_idx]
	show_message("✨ Now named " + pet_name + "!")
	_save_game()

func _on_minigame_pressed() -> void:
	if has_egg or is_ghost:
		return
	
	minigame_panel.visible = not minigame_panel.visible
	
	if minigame_panel.visible:
		minigame_active = true
		minigame_score = 0
		minigame_time_remaining = 10
		_update_minigame_ui()
		# Start countdown
		_start_minigame()

func _start_minigame() -> void:
	minigame_time_remaining = 10
	_update_minigame_ui()
	# Game runs in _process

func _update_minigame_ui() -> void:
	tap_score_label.text = "Score: %d" % minigame_score
	tap_time_label.text = "Time: %ds" % minigame_time_remaining

func _on_tap_pressed() -> void:
	if minigame_active:
		minigame_score += 1
		_update_minigame_ui()

func _on_minigame_close_pressed() -> void:
	if minigame_active and minigame_score > 0:
		var xp_reward = minigame_score * 3
		_add_xp(xp_reward)
		show_message("🎮 +%d XP!" % xp_reward)
	minigame_active = false
	minigame_panel.visible = false

func _total_time_played() -> int:
	# Approximate - just use age for now
	return age_minutes * 60

func _play_location_music() -> void:
	if not music_enabled:
		return
	
	# Different music for different locations
	if current_location == "club":
		if ResourceLoader.exists("res://assets/audio/jazz.mp3"):
			bgm_player.stream = load("res://assets/audio/jazz.mp3")
			bgm_player.play()
	else:
		if ResourceLoader.exists("res://assets/audio/bgm.mp3"):
			bgm_player.stream = load("res://assets/audio/bgm.mp3")
			bgm_player.play()

func _on_pet_clicked(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if has_egg:
			# Tapping egg reduces hatch time (for testing)
			if egg_hatch_time > 0:
				egg_hatch_time -= 30  # Reduce by 30 seconds per tap
				var now = Time.get_unix_time_from_system()
				var time_left = max(0, egg_hatch_time - now)
				var mins_left = ceil(time_left / 60.0)
				show_message("🥚 %d min left!" % mins_left)
			return
		if is_ghost:
			show_message("👻 Can't pet ghosts...")
			return
		
		happiness = min(100.0, happiness + 5)
		_spawn_floating_heart()
		_trigger_bounce()
		_add_xp(5)
		show_message("❤️")
		_play_sound("pet"))

func _add_xp(amount: int) -> void:
	if current_location == "city":
		amount = int(amount * 1.5)
	
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 50 + level * 25
		show_message("LEVEL UP! LV %d" % level)
		
		match level:
			5: _unlock_achievement("level5")
			10: _unlock_achievement("level10")
			25: _unlock_achievement("level25")
			50: _unlock_achievement("level50")
			99: _unlock_achievement("level99")

func _unlock_achievement(id: String) -> void:
	if achievements.has(id):
		return
	
	achievements[id] = true
	var ach = ACHIEVEMENTS.get(id, {})
	show_message("🏆 " + ach.get("title", id))

func _update_weather() -> void:
	if not current_location in WEATHER_LOCATIONS:
		weather = Weather.SUNNY
		return
	
	var rand = randf()
	if rand < 0.5: weather = Weather.SUNNY
	elif rand < 0.7: weather = Weather.RAIN
	elif rand < 0.85: weather = Weather.STORM
	else: weather = Weather.SNOW

func _update_animations(now: int) -> void:
	# Bounce animation (when fed/played with)
	if is_bouncing:
		bounce_timer += 0.016
		bounce_offset = sin(bounce_timer * 15) * 20 * exp(-bounce_timer * 3)
		if bounce_timer > 0.5:
			is_bouncing = false
			bounce_offset = 0.0
	
	pace_timer += 0.016
	if pace_timer > 4 + randf() * 2:
		if is_pacing:
			is_pacing = false
			pace_timer = 0
		else:
			is_pacing = true
			pace_direction = 1 if randf() > 0.5 else -1
			pace_timer = 0
	
	if is_pacing and not is_sleeping:
		var speed = 0.15
		if current_location == "club":
			speed = 0.8
		pace_offset += pace_direction * speed
		var max_range = 10 if current_location != "club" else 40
		if abs(pace_offset) > max_range:
			pace_direction *= -1
	else:
		pace_offset *= 0.95
	
	if is_ghost:
		bob_offset = sin(now * 0.002) * 6
	elif has_egg:
		bob_offset = 0
	
	if now - last_flip_time > 2 + randf() * 2:
		flip_offset *= -1
		last_flip_time = now

func _update_floating_effects(delta: float) -> void:
	# Hearts
	for i in range(floating_hearts.size() - 1, -1, -1):
		var h = floating_hearts[i]
		h.offset += delta * 80
		h.alpha -= delta * 0.8
		if h.alpha <= 0:
			floating_hearts.remove_at(i)
	
	# Schmegs
	for i in range(floating_schmegs.size() - 1, -1, -1):
		var s = floating_schmegs[i]
		s.offset += delta * 100
		s.alpha -= delta * 1.0
		if s.alpha <= 0:
			floating_schmegs.remove_at(i)
	
	# Medicines
	for i in range(floating_medicines.size() - 1, -1, -1):
		var m = floating_medicines[i]
		m.offset += delta * 80
		m.alpha -= delta * 0.8
		if m.alpha <= 0:
			floating_medicines.remove_at(i)
	
	# Foods
	for i in range(floating_foods.size() - 1, -1, -1):
		var f = floating_foods[i]
		f.offset += delta * 60
		f.alpha -= delta * 0.7
		if f.alpha <= 0:
			floating_foods.remove_at(i)
	
	# Render floating effects
	_render_floating_effects()
	_render_poops()

func _render_poops() -> void:
	# Render poops as emoji text
	if poop_label:
		var poop_text = ""
		for poop in poop_list:
			if poop.get("is_golden", false):
				poop_text += "✨💩 "
			else:
				poop_text += "💩 "
		poop_label.text = poop_text
		poop_label.modulate = Color(1, 1, 1, 0.9)

func _render_floating_effects() -> void:
	# Hearts
	if floating_hearts.size() > 0 and heart_sprite.texture:
		heart_sprite.visible = true
		var h = floating_hearts[0]
		heart_sprite.position = Vector2(h.x, h.y - h.offset)
		heart_sprite.modulate = Color(1, 1, 1, h.alpha)
		heart_sprite.scale = Vector2(0.8, 0.8)
	else:
		heart_sprite.visible = false
	
	# Schmegs
	if floating_schmegs.size() > 0 and schmeg_sprite.texture:
		schmeg_sprite.visible = true
		var s = floating_schmegs[0]
		schmeg_sprite.position = Vector2(s.x, s.y - s.offset)
		schmeg_sprite.modulate = Color(1, 1, 1, s.alpha)
		schmeg_sprite.scale = Vector2(0.8, 0.8)
	else:
		schmeg_sprite.visible = false
	
	# Medicines
	if floating_medicines.size() > 0 and medicine_sprite.texture:
		medicine_sprite.visible = true
		var m = floating_medicines[0]
		medicine_sprite.position = Vector2(m.x, m.y - m.offset)
		medicine_sprite.modulate = Color(1, 1, 1, m.alpha)
		medicine_sprite.scale = Vector2(0.8, 0.8)
	else:
		medicine_sprite.visible = false
	
	# Foods
	if floating_foods.size() > 0 and food_sprite.texture:
		food_sprite.visible = true
		var f = floating_foods[0]
		food_sprite.position = Vector2(f.x, f.y - f.offset)
		food_sprite.modulate = Color(1, 1, 1, f.alpha)
		food_sprite.scale = Vector2(0.8, 0.8)
	else:
		food_sprite.visible = false

func _spawn_floating_heart() -> void:
	floating_hearts.append({"x": 240, "y": 300, "alpha": 1.0, "offset": 0})

func _spawn_floating_schmeg() -> void:
	floating_schmegs.append({"x": 240 + (randf() - 0.5) * 40, "y": 300, "alpha": 1.0, "offset": 0})

func _spawn_floating_medicine() -> void:
	floating_medicines.append({"x": 240 + (randf() - 0.5) * 40, "y": 300, "alpha": 1.0, "offset": 0})

func _spawn_floating_food() -> void:
	floating_foods.append({"x": 240 + (randf() - 0.5) * 50, "y": 300, "alpha": 1.0, "offset": 0})

func _spawn_poop() -> void:
	if poop_list.size() >= 10:
		return
	
	poop_list.append({
		"x": 50 + randf() * 200,
		"y": 200 + randf() * 100,
		"is_golden": randf() < 0.05
	})
	poop_count = poop_list.size()

func _trigger_bounce() -> void:
	is_bouncing = true
	bounce_timer = 0.0
	_trigger_screen_shake()

func _trigger_screen_shake() -> void:
	screen_shake = 0.3  # 300ms shake

func _check_sickness() -> void:
	if is_sick or is_ghost:
		return
	
	var chance = 0.02
	if current_location == "camp":
		chance *= 2
	
	if randf() < chance:
		is_sick = true
		show_message("🤢 Bulk is sick!")

func _update_ui() -> void:
	# Stats with numbers
	hunger_label.text = "%d" % hunger
	happiness_label.text = "%d" % happiness
	clean_label.text = "%d" % cleanliness
	energy_label.text = "%d" % energy
	
	# Stats colors (warning when low)
	var hunger_color = Color(1, 0.3, 0.3, 1) if hunger < 30 else Color(1, 0.55, 0.3, 1)
	var happiness_color = Color(1, 0.3, 0.3, 1) if happiness < 30 else Color(1, 0.45, 0.55, 1)
	var clean_color = Color(1, 0.3, 0.3, 1) if cleanliness < 30 else Color(0.4, 0.8, 1, 1)
	var energy_color = Color(1, 0.3, 0.3, 1) if energy < 30 else Color(1, 0.85, 0.3, 1)
	
	hunger_label.modulate = hunger_color
	happiness_label.modulate = happiness_color
	clean_label.modulate = clean_color
	energy_label.modulate = energy_color
	
	# XP
	xp_label.text = "XP: %d / %d" % [xp, xp_needed]
	
	# Age
	var age_str = "%dh" % (age_minutes / 60)
	if age_minutes >= 1440:
		age_str = "%dd" % (age_minutes / 1440)
	age_label.text = "Age: %s | Lv %d" % [age_str, level]
	
	# Stage label
	var stage_name = ""
	match current_stage:
		Stage.EGG: stage_name = "🥚 EGG"
		Stage.BABY: stage_name = "🐣 " + pet_name
		Stage.TEEN_GOOD: stage_name = "🐥 GOOD"
		Stage.TEEN_BAD: stage_name = "🐥 BAD"
		Stage.ADULT: stage_name = "🐓 " + pet_name
		Stage.ELDER: stage_name = "🧓 ELDER"
	stage_label.text = stage_name
	
	# Egg progress
	if has_egg and egg_hatch_time > 0:
		var now = Time.get_unix_time_from_system()
		var time_left = max(0, egg_hatch_time - now)
		var mins_left = ceil(time_left / 60.0)
		if mins_left > 1:
			egg_label.text = "🥚 Hatching in %d min..." % mins_left
		else:
			egg_label.text = "🥚 Any moment now!"
		egg_label.visible = true
	else:
		egg_label.visible = false
	
	# Location
	location_btn.text = "📍 " + current_location.capitalize()
	
	# Status indicators
	if poop_list.size() > 0:
		poop_indicator.text = "💩 %d" % poop_list.size()
	else:
		poop_indicator.text = ""
	
	# Show combo if active
	if combo_count >= 2:
		poop_indicator.text += " 🔥x%d" % combo_count
	
	# Achievements count
	var ach_count = achievements.size()
	if ach_count > 0:
		poop_indicator.text += " 🏆 %d" % ach_count
	
	# Weather
	match weather:
		Weather.SUNNY: weather_indicator.text = "☀️"
		Weather.RAIN: weather_indicator.text = "🌧️"
		Weather.SNOW: weather_indicator.text = "❄️"
		Weather.STORM: weather_indicator.text = "⛈️"
	
	# Night overlay (darken at night)
	var hour = Time.get_datetime_dict_from_system().hour
	var is_night = hour >= 18 or hour < 6
	if is_night:
		bg_overlay.color = Color(0, 0, 0, 0.35)  # Dark overlay at night
	else:
		bg_overlay.color = Color(0, 0, 0, 0.15)  # Light during day
	
	# Sick/Sleep/Ghost
	sick_indicator.text = "🤒" if is_sick else ""
	sleep_indicator.text = "💤" if is_sleeping else ""
	ghost_indicator.text = "👻" if is_ghost else ""
	
	# Button states
	var disabled = is_sleeping or is_ghost or has_egg
	feed_btn.disabled = disabled
	play_btn.disabled = disabled
	clean_btn.disabled = disabled
	medicine_btn.disabled = not is_sick or is_ghost or has_egg
	rest_btn.disabled = is_sleeping or is_ghost or has_egg
	schmeg_btn.disabled = is_sleeping or is_ghost or has_egg
	sleep_btn.disabled = is_ghost or has_egg
	
	# Show/hide hint
	hint_label.visible = not is_ghost and not has_egg
	
	if is_sleeping:
		sleep_btn.text = "☀️ Wake"
	else:
		sleep_btn.text = "💤 Sleep"
	
	_update_sprite()

func _update_sprite() -> void:
	var mood = _get_mood()
	var sprite_name = _get_sprite_name(mood)
	_load_sprite(sprite_name)

func _get_mood() -> String:
	if has_egg:
		var elapsed = Time.get_unix_time_from_system() - egg_start_time
		if elapsed >= 1200:
			return "cracked"
		return "neutral"
	
	if is_ghost:
		return "ghost"
	
	if is_sick:
		return "sick"
	
	if is_sleeping:
		return "sleep"
	
	if is_angry:
		return "angry"
	
	if hunger < 20:
		return "hungry"
	if happiness < 30:
		return "sad"
	if cleanliness < 30:
		return "cry"
	
	var hour = Time.get_datetime_dict_from_system().hour
	if hour >= 18 or hour < 6:
		if randf() < 0.1:
			return "tired"
	
	return "happy"

func _get_sprite_name(mood: String) -> String:
	match current_stage:
		Stage.EGG:
			return "egg.png" if mood == "neutral" else "egg-cracked.png"
		Stage.BABY:
			return "baby-" + mood + ".png"
		Stage.TEEN_GOOD:
			return "teen-good-" + mood + ".png"
		Stage.TEEN_BAD:
			return "teen-bad-" + mood + ".png"
		Stage.ADULT:
			return "bulk-" + mood + ".png"
		Stage.ELDER:
			return "elder-" + mood + ".png"
	return "egg.png"

func _load_sprite(name: String) -> void:
	var path = SPRITE_PATH + name
	if ResourceLoader.exists(path):
		pet_sprite.texture = load(path)
	
	pet_sprite.position = Vector2(240, 320)
	pet_sprite.position.x += pace_offset
	pet_sprite.position.y += bob_offset + bounce_offset
	pet_sprite.scale = Vector2(2.5, 2.5) * Vector2(flip_offset, 1)
	if has_egg:
		pet_sprite.rotation = egg_tilt

func _load_background() -> void:
	var name = "bg-" + current_location + ".png"
	var hour = Time.get_datetime_dict_from_system().hour
	var is_night = hour >= 18 or hour < 6
	
	if is_night and current_location != "beach" and current_location != "mountain":
		name = "bg-" + current_location + "-night.png"
	
	var path = BG_PATH + name
	if not ResourceLoader.exists(path):
		path = BG_PATH + "bg-cabin.png"
	
	bg_sprite.texture = load(path)

func show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate = Color(1, 0.9, 0.4, 1)  # Gold color for messages
	get_tree().create_timer(3.0).timeout.connect(func(): 
		if message_label.text == text:
			message_label.text = ""
			message_label.modulate = Color(1, 1, 1, 0)
	)

func _save_game() -> void:
	var save_data = {
		"pet_name": pet_name,
		"has_egg": has_egg,
		"egg_start_time": egg_start_time,
		"egg_hatch_time": egg_hatch_time,
		"birth_time": birth_time,
		"level": level,
		"xp": xp,
		"xp_needed": xp_needed,
		"hunger": hunger,
		"happiness": happiness,
		"cleanliness": cleanliness,
		"energy": energy,
		"current_stage": current_stage,
		"teen_type": teen_type,
		"evolution_pending": evolution_pending,
		"is_sleeping": is_sleeping,
		"sleep_start_time": sleep_start_time,
		"is_sick": is_sick,
		"is_angry": is_angry,
		"is_ghost": is_ghost,
		"ghost_since": ghost_since,
		"poop_count": poop_count,
		"poop_list": poop_list,
		"current_location": current_location,
		"total_plays": total_plays,
		"total_feeds": total_feeds,
		"total_cleans": total_cleans,
		"total_sleeps": total_sleeps,
		"medicine_used": medicine_used,
		"visited_locations": visited_locations,
		"golden_poops_found": golden_poops_found,
		"achievements": achievements,
		"last_schmeg_time": last_schmeg_time,
		"last_rest_time": last_rest_time,
		"last_interact_time": last_interact_time,
		"combo_count": combo_count,
		"music_enabled": music_enabled,
	}
	
	var file = FileAccess.open("user://bulkagachi_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func _load_game() -> void:
	if not FileAccess.file_exists("user://bulkagachi_save.json"):
		return
	
	var file = FileAccess.open("user://bulkagachi_save.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	
	if json == null:
		return
	
	pet_name = json.get("pet_name", "Bulk")
	has_egg = json.get("has_egg", true)
	egg_start_time = json.get("egg_start_time", 0)
	egg_hatch_time = json.get("egg_hatch_time", 0)
	birth_time = json.get("birth_time", 0)
	level = json.get("level", 1)
	xp = json.get("xp", 0)
	xp_needed = json.get("xp_needed", 75)
	hunger = json.get("hunger", 100.0)
	happiness = json.get("happiness", 100.0)
	cleanliness = json.get("cleanliness", 100.0)
	energy = json.get("energy", 100.0)
	current_stage = json.get("current_stage", Stage.EGG)
	teen_type = json.get("teen_type", "")
	evolution_pending = json.get("evolution_pending", "")
	is_sleeping = json.get("is_sleeping", false)
	sleep_start_time = json.get("sleep_start_time", 0)
	is_sick = json.get("is_sick", false)
	is_angry = json.get("is_angry", false)
	is_ghost = json.get("is_ghost", false)
	ghost_since = json.get("ghost_since", 0)
	poop_count = json.get("poop_count", 0)
	poop_list = json.get("poop_list", [])
	current_location = json.get("current_location", "cabin")
	total_plays = json.get("total_plays", 0)
	total_feeds = json.get("total_feeds", 0)
	total_cleans = json.get("total_cleans", 0)
	total_sleeps = json.get("total_sleeps", 0)
	medicine_used = json.get("medicine_used", 0)
	visited_locations = json.get("visited_locations", [])
	golden_poops_found = json.get("golden_poops_found", 0)
	achievements = json.get("achievements", {})
	last_schmeg_time = json.get("last_schmeg_time", 0)
	last_rest_time = json.get("last_rest_time", 0)
	last_interact_time = json.get("last_interact_time", 0)
	combo_count = json.get("combo_count", 0)
	music_enabled = json.get("music_enabled", true)
	
	# Apply music setting
	if not music_enabled:
		bgm_player.stop()
		music_btn.text = "🔇 OFF"
	
	if birth_time > 0:
		age_minutes = int((Time.get_unix_time_from_system() - birth_time) / 60)
	
	if has_egg and Time.get_unix_time_from_system() >= egg_hatch_time:
		_hatch_egg()
	
	_load_background()

func _start_new_game() -> void:
	has_egg = true
	egg_start_time = Time.get_unix_time_from_system()
	# Egg hatches in 1 hour
	egg_hatch_time = egg_start_time + 60 * 60
	birth_time = 0
	level = 1
	xp = 0
	xp_needed = 75
	hunger = 100.0
	happiness = 100.0
	cleanliness = 100.0
	energy = 100.0
	current_stage = Stage.EGG

	current_stage = Stage.EGG
	teen_type = 
	evolution_pending = 
	is_sleeping = false
	is_sick = false
	is_angry = false
	is_ghost = false
	poop_count = 0
	poop_list.clear()
	combo_count = 0
	total_plays = 0
	total_feeds = 0
	total_cleans = 0
	total_sleeps = 0
	medicine_used = 0
	golden_poops_found = 0
	achievements.clear()
	visited_locations.clear()

}
