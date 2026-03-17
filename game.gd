extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# BULKAGACHI - Full Game Engine (Godot 4.x)
# ══════════════════════════════════════════════════════════════════════════════

# ENUMS
enum Stage { EGG, BABY, TEEN_GOOD, TEEN_BAD, ADULT, ELDER }
enum Weather { SUNNY, RAIN, SNOW, STORM }

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
var is_angry: bool = false
var is_ghost: bool = false
var poop_count: int = 0
var poop_list: Array = []
var has_egg: bool = true
var egg_start_time: int = 0
var egg_hatch_time: int = 0
var current_location: String = "cabin"
var weather: Weather = Weather.SUNNY
var total_plays: int = 0
var total_feeds: int = 0
var total_cleans: int = 0
var total_sleeps: int = 0
var golden_poops_found: int = 0
var achievements: Dictionary = {}
var combo_count: int = 0
var last_interact_time: int = 0

# UI Elements
var pet_sprite: Sprite2D
var bg_sprite: Sprite2D
var title_label: Label
var age_label: Label
var stage_label: Label
var egg_label: Label
var hunger_label: Label
var happiness_label: Label
var clean_label: Label
var energy_label: Label
var xp_label: Label
var message_label: Label
var location_btn: Button
var feed_btn: Button
var play_btn: Button
var clean_btn: Button
var sleep_btn: Button
var medicine_btn: Button
var rest_btn: Button
var schmeg_btn: Button
var music_btn: Button
var stats_btn: Button
var evolve_btn: Button

# Animation
var bob_offset: float = 0.0

const SPRITE_PATH = "res://assets/sprites/"
const BG_PATH = "res://assets/sprites/"

func _ready() -> void:
	randomize()
	_build_ui()
	_load_game()
	if not has_egg and birth_time == 0:
		_start_new_game()
	show_message("🥚 Welcome! Egg will hatch in 1 hour.")
	_update_ui()

func _process(delta: float) -> void:
	if has_egg:
		var now = Time.get_unix_time_from_system()
		if now >= egg_hatch_time:
			_hatch_egg()
		var elapsed = now - egg_start_time
		var progress = min(elapsed / 3600.0, 1.0)
		bob_offset = sin(now * 0.5) * (0.04 + progress * 0.04)
		_update_ui()
		return
	
	age_minutes = int((Time.get_unix_time_from_system() - birth_time) / 60)
	_update_stats()
	_check_evolution()
	_check_death()
	_update_ui()
	_save_game()

func _build_ui() -> void:
	# Background
	bg_sprite = Sprite2D.new()
	bg_sprite.position = Vector2(270, 585)
	add_child(bg_sprite)
	_load_bg()
	
	# Pet
	pet_sprite = Sprite2D.new()
	pet_sprite.position = Vector2(270, 450)
	pet_sprite.scale = Vector2(3, 3)
	add_child(pet_sprite)
	
	# Title
	title_label = Label.new()
	title_label.text = "🐣 BULKAGACHI"
	title_label.position = Vector2(20, 20)
	title_label.add_theme_font_size_override("font_size", 24)
	add_child(title_label)
	
	# Age
	age_label = Label.new()
	age_label.text = "Age: 0h | Lv 1"
	age_label.position = Vector2(20, 50)
	age_label.add_theme_font_size_override("font_size", 16)
	add_child(age_label)
	
	# Stage
	stage_label = Label.new()
	stage_label.text = "🥚 EGG"
	stage_label.position = Vector2(400, 20)
	stage_label.add_theme_font_size_override("font_size", 18)
	add_child(stage_label)
	
	# Egg label
	egg_label = Label.new()
	egg_label.text = "Hatching in 60 min..."
	egg_label.position = Vector2(150, 80)
	egg_label.add_theme_font_size_override("font_size", 14)
	add_child(egg_label)
	
	# Stats
	hunger_label = Label.new()
	hunger_label.text = "🍗 100"
	hunger_label.position = Vector2(20, 120)
	add_child(hunger_label)
	
	happiness_label = Label.new()
	happiness_label.text = "💛 100"
	happiness_label.position = Vector2(150, 120)
	add_child(happiness_label)
	
	clean_label = Label.new()
	clean_label.text = "✨ 100"
	clean_label.position = Vector2(280, 120)
	add_child(clean_label)
	
	energy_label = Label.new()
	energy_label.text = "⚡ 100"
	energy_label.position = Vector2(410, 120)
	add_child(energy_label)
	
	# XP
	xp_label = Label.new()
	xp_label.text = "XP: 0/75"
	xp_label.position = Vector2(20, 150)
	xp_label.add_theme_font_size_override("font_size", 14)
	add_child(xp_label)
	
	# Location button
	location_btn = Button.new()
	location_btn.text = "📍 Cabin"
	location_btn.position = Vector2(20, 180)
	location_btn.size = Vector2(100, 40)
	location_btn.pressed.connect(_on_location_pressed)
	add_child(location_btn)
	
	# Stats button
	stats_btn = Button.new()
	stats_btn.text = "📊"
	stats_btn.position = Vector2(130, 180)
	stats_btn.size = Vector2(40, 40)
	stats_btn.pressed.connect(_show_stats)
	add_child(stats_btn)
	
	# Evolve button
	evolve_btn = Button.new()
	evolve_btn.text = "✨ EVOLVE"
	evolve_btn.position = Vector2(380, 180)
	evolve_btn.size = Vector2(100, 40)
	evolve_btn.visible = false
	evolve_btn.pressed.connect(_on_evolve_pressed)
	add_child(evolve_btn)
	
	# Message
	message_label = Label.new()
	message_label.text = ""
	message_label.position = Vector2(100, 300)
	message_label.size = Vector2(340, 40)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	add_child(message_label)
	
	# Action buttons - row 1
	feed_btn = _make_button("🍗", Vector2(20, 600), _on_feed_pressed)
	play_btn = _make_button("🎾", Vector2(110, 600), _on_play_pressed)
	clean_btn = _make_button("🧼", Vector2(200, 600), _on_clean_pressed)
	sleep_btn = _make_button("💤", Vector2(290, 600), _on_sleep_pressed)
	medicine_btn = _make_button("💊", Vector2(380, 600), _on_medicine_pressed)
	
	# Action buttons - row 2
	rest_btn = _make_button("🪑", Vector2(110, 660), _on_rest_pressed)
	schmeg_btn = _make_button("⚡", Vector2(200, 660), _on_schmeg_pressed)
	music_btn = _make_button("🎵", Vector2(290, 660), _on_music_pressed)
	
	# Pet click
	pet_sprite.input_event.connect(_on_pet_clicked)

func _make_button(text: String, pos: Vector2, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(80, 50)
	btn.pressed.connect(callback)
	add_child(btn)
	return btn

func _load_bg() -> void:
	var name = "bg-cabin.png"
	if current_location != "cabin":
		name = "bg-" + current_location + ".png"
	var path = BG_PATH + name
	if ResourceLoader.exists(path):
		bg_sprite.texture = load(path)

func _update_stats() -> void:
	if is_sleeping:
		energy = min(100.0, energy + 0.02)
		if energy >= 100:
			is_sleeping = false
			show_message("Good morning!")
	else:
		hunger = max(0.0, hunger - 0.001)
		happiness = max(0.0, happiness - 0.0008)
		cleanliness = max(0.0, cleanliness - 0.0003)
		energy = max(0.0, energy - 0.0007)
	
	if randf() < 0.0001:
		_spawn_poop()

func _spawn_poop() -> void:
	if poop_list.size() < 10:
		poop_list.append({"x": randf() * 400 + 50, "y": randf() * 200 + 300, "is_golden": randf() < 0.05})
		poop_count = poop_list.size()

func _check_evolution() -> void:
	if evolution_pending != "" or birth_time == 0:
		return
	var age_hours = age_minutes / 60
	match current_stage:
		Stage.BABY:
			if age_hours >= 8:
				evolution_pending = "TEEN"
				show_message("✨ TEEN READY!")
		Stage.TEEN_GOOD, Stage.TEEN_BAD:
			if age_hours >= 24:
				evolution_pending = "ADULT"
				show_message("✨ ADULT READY!")
		Stage.ADULT:
			if age_hours >= 168:
				evolution_pending = "ELDER"
				show_message("✨ ELDER READY!")
	evolve_btn.visible = evolution_pending != ""

func _hatch_egg() -> void:
	has_egg = false
	birth_time = Time.get_unix_time_from_system()
	age_minutes = 0
	current_stage = Stage.BABY
	happiness = 100
	energy = 100
	_add_xp(25)
	show_message("🥚 WELCOME " + pet_name + "!")

func _check_death() -> void:
	if is_ghost:
		return
	if hunger <= 0:
		is_ghost = true
		show_message("👻 BULK BECAME A GHOST!")
		current_location = "tomb"
		_load_bg()

func _update_ui() -> void:
	# Stats
	hunger_label.text = "🍗 %d" % hunger
	happiness_label.text = "💛 %d" % happiness
	clean_label.text = "✨ %d" % cleanliness
	energy_label.text = "⚡ %d" % energy
	
	# Colors
	hunger_label.modulate = Color.RED if hunger < 30 else Color.WHITE
	happiness_label.modulate = Color.RED if happiness < 30 else Color.WHITE
	clean_label.modulate = Color.RED if cleanliness < 30 else Color.WHITE
	energy_label.modulate = Color.RED if energy < 30 else Color.WHITE
	
	# Age
	var age_str = "%dh" % (age_minutes / 60)
	if age_minutes >= 1440:
		age_str = "%dd" % (age_minutes / 1440)
	age_label.text = "Age: %s | Lv %d" % [age_str, level]
	
	# XP
	xp_label.text = "XP: %d/%d" % [xp, xp_needed]
	
	# Stage
	match current_stage:
		Stage.EGG: stage_label.text = "🥚 EGG"
		Stage.BABY: stage_label.text = "🐣 BABY"
		Stage.TEEN_GOOD: stage_label.text = "🐥 GOOD"
		Stage.TEEN_BAD: stage_label.text = "🐥 BAD"
		Stage.ADULT: stage_label.text = "🐓 ADULT"
		Stage.ELDER: stage_label.text = "🧓 ELDER"
	
	# Egg countdown
	if has_egg and egg_hatch_time > 0:
		var now = Time.get_unix_time_from_system()
		var mins_left = ceil((egg_hatch_time - now) / 60.0)
		egg_label.text = "Hatching in %d min..." % max(0, mins_left)
		egg_label.visible = true
	else:
		egg_label.visible = false
	
	# Location
	location_btn.text = "📍 " + current_location.capitalize()
	
	# Update sprite
	_update_sprite()
	
	# Buttons
	var disabled = is_sleeping or is_ghost or has_egg
	feed_btn.disabled = disabled
	play_btn.disabled = disabled
	clean_btn.disabled = disabled
	medicine_btn.disabled = not is_sick
	rest_btn.disabled = is_sleeping
	schmeg_btn.disabled = is_sleeping
	sleep_btn.disabled = is_ghost
	sleep_btn.text = "☀️" if is_sleeping else "💤"

func _update_sprite() -> void:
	var mood = "happy"
	if has_egg:
		mood = "egg"
	elif is_ghost:
		mood = "ghost"
	elif is_sick:
		mood = "sick"
	elif is_sleeping:
		mood = "sleep"
	elif is_angry:
		mood = "angry"
	elif hunger < 30:
		mood = "hungry"
	elif happiness < 30:
		mood = "sad"
	
	var sprite_name = ""
	match current_stage:
		Stage.EGG: sprite_name = "egg.png"
		Stage.BABY: sprite_name = "baby-" + mood + ".png"
		Stage.TEEN_GOOD: sprite_name = "teen-good-" + mood + ".png"
		Stage.TEEN_BAD: sprite_name = "teen-bad-" + mood + ".png"
		Stage.ADULT: sprite_name = "bulk-" + mood + ".png"
		Stage.ELDER: sprite_name = "elder-" + mood + ".png"
	
	var path = SPRITE_PATH + sprite_name
	if ResourceLoader.exists(path):
		pet_sprite.texture = load(path)
	
	# Animate
	pet_sprite.position = Vector2(270, 450 + bob_offset * 10)

func show_message(text: String) -> void:
	message_label.text = text
	get_tree().create_timer(3.0).timeout.connect(func(): 
		if message_label.text == text:
			message_label.text = ""
	)

# ACTIONS
func _on_feed_pressed() -> void:
	if has_egg or is_sleeping or is_ghost:
		return
	hunger = min(100.0, hunger + 30)
	energy = max(0.0, energy - 2)
	total_feeds += 1
	_add_xp(10)
	show_message("Yum!")

func _on_play_pressed() -> void:
	if has_egg or is_sleeping or is_ghost:
		return
	if energy < 10:
		show_message("Too tired!")
		return
	happiness = min(100.0, happiness + 20)
	energy = max(0.0, energy - 15)
	total_plays += 1
	_add_xp(15)
	show_message("Fun!")

func _on_clean_pressed() -> void:
	if has_egg or is_sleeping or is_ghost:
		return
	cleanliness = 100.0
	poop_list.clear()
	poop_count = 0
	is_sick = false
	total_cleans += 1
	_add_xp(10)
	show_message("Sparkling clean!")

func _on_sleep_pressed() -> void:
	if has_egg or is_ghost:
		return
	is_sleeping = not is_sleeping
	if is_sleeping:
		total_sleeps += 1
		show_message("Goodnight...")
	else:
		show_message("Good morning!")

func _on_medicine_pressed() -> void:
	if has_egg or is_ghost or not is_sick:
		return
	is_sick = false
	happiness = min(100.0, happiness + 20)
	show_message("Cured!")

func _on_rest_pressed() -> void:
	if has_egg or is_ghost or is_sleeping:
		return
	energy = min(100.0, energy + 15)
	show_message("+15 Energy!")

func _on_schmeg_pressed() -> void:
	if has_egg or is_ghost or is_sleeping:
		return
	energy = min(100.0, energy + 30)
	show_message("⚡ Energy!")

func _on_location_pressed() -> void:
	var locations = ["cabin", "camp", "city", "beach", "mountain", "club"]
	var idx = locations.find(current_location)
	current_location = locations[(idx + 1) % locations.size()]
	_load_bg()
	show_message("📍 " + current_location.to_upper())

func _on_evolve_pressed() -> void:
	if evolution_pending == "":
		return
	match evolution_pending:
		"TEEN": current_stage = Stage.TEEN_GOOD
		"ADULT": current_stage = Stage.ADULT
		"ELDER": current_stage = Stage.ELDER
	evolution_pending = ""
	evolve_btn.visible = false
	show_message("✨ EVOLVED!")

func _on_music_pressed() -> void:
	show_message("🎵 Music toggle")

func _show_stats() -> void:
	var stats = "🍗 Fed: %d\n🎾 Played: %d\n🧼 Cleaned: %d\n😴 Sleeps: %d\n⭐ Level: %d" % [total_feeds, total_plays, total_cleans, total_sleeps, level]
	show_message(stats)

func _on_pet_clicked(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if has_egg:
			if egg_hatch_time > 0:
				egg_hatch_time -= 30
				var now = Time.get_unix_time_from_system()
				var mins_left = ceil((egg_hatch_time - now) / 60.0)
				show_message("🥚 %d min!" % max(0, mins_left))
			return
		if is_ghost:
			show_message("👻")
			return
		happiness = min(100.0, happiness + 5)
		_add_xp(5)
		show_message("❤️")

func _add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 50 + level * 25
		show_message("LEVEL UP! LV %d" % level)

func _save_game() -> void:
	var save_data = {
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
		"is_sleeping": is_sleeping,
		"is_sick": is_sick,
		"is_ghost": is_ghost,
		"poop_count": poop_count,
		"current_location": current_location,
		"total_plays": total_plays,
		"total_feeds": total_feeds,
		"total_cleans": total_cleans,
		"total_sleeps": total_sleeps,
		"golden_poops_found": golden_poops_found,
		"achievements": achievements,
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
	is_sleeping = json.get("is_sleeping", false)
	is_sick = json.get("is_sick", false)
	is_ghost = json.get("is_ghost", false)
	poop_count = json.get("poop_count", 0)
	current_location = json.get("current_location", "cabin")
	total_plays = json.get("total_plays", 0)
	total_feeds = json.get("total_feeds", 0)
	total_cleans = json.get("total_cleans", 0)
	total_sleeps = json.get("total_sleeps", 0)
	golden_poops_found = json.get("golden_poops_found", 0)
	achievements = json.get("achievements", {})
	if birth_time > 0:
		age_minutes = int((Time.get_unix_time_from_system() - birth_time) / 60)
	if has_egg and Time.get_unix_time_from_system() >= egg_hatch_time:
		_hatch_egg()

func _start_new_game() -> void:
	has_egg = true
	egg_start_time = Time.get_unix_time_from_system()
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
