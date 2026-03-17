extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# BULKAGACHI - Godot 4.x
# ══════════════════════════════════════════════════════════════════════════════

# ENUMS
enum Stage { EGG, BABY, TEEN_GOOD, TEEN_BAD, ADULT, ELDER }

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
var evolution_pending: String = ""
var is_sleeping: bool = false
var is_sick: bool = false
var is_ghost: bool = false
var poop_count: int = 0
var poop_list: Array = []
var has_egg: bool = true
var egg_start_time: int = 0
var egg_hatch_time: int = 0
var current_location: String = "cabin"
var total_plays: int = 0
var total_feeds: int = 0
var total_cleans: int = 0

# UI Elements
var pet_sprite: Sprite2D
var bg_sprite: Sprite2D
var title_label: Label
var age_label: Label
var stage_label: Label
var egg_label: Label
var stats_labels: Array = []
var xp_label: Label
var message_label: Label
var buttons: Array = []
var location_btn: Button
var evolve_btn: Button
var poop_container: VBoxContainer

const SPRITE_PATH = "res://assets/sprites/"
const BG_PATH = "res://assets/sprites/"

func _ready() -> void:
	randomize()
	_build_ui()
	_load_game()
	if birth_time == 0:
		_start_new_game()
	else:
		has_egg = false
	_update_ui()

func _process(_delta: float) -> void:
	if has_egg:
		var now = Time.get_unix_time_from_system()
		if now >= egg_hatch_time:
			_hatch_egg()
		var elapsed = now - egg_start_time
		var progress = min(elapsed / 3600.0, 1.0)
		pet_sprite.position.y = 300 + sin(now * 3) * 5
		egg_label.text = "Hatching in %d min..." % max(0, ceil((egg_hatch_time - now) / 60.0))
		return
	
	age_minutes = int((Time.get_unix_time_from_system() - birth_time) / 60)
	_update_stats()
	_check_evolution()
	_check_death()
	_update_ui()
	_save_game()

func _build_ui() -> void:
	# Background - scaled to fit
	bg_sprite = Sprite2D.new()
	bg_sprite.position = Vector2(270, 500)
	bg_sprite.scale = Vector2(0.5, 0.5)
	add_child(bg_sprite)
	_load_bg()
	
	# Title
	title_label = Label.new()
	title_label.text = "🐣 BULKAGACHI"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 20)
	add_child(title_label)
	
	# Stage label
	stage_label = Label.new()
	stage_label.position = Vector2(420, 15)
	stage_label.add_theme_font_size_override("font_size", 14)
	add_child(stage_label)
	
	# Age
	age_label = Label.new()
	age_label.position = Vector2(20, 40)
	age_label.add_theme_font_size_override("font_size", 14)
	add_child(age_label)
	
	# Stats row
	var stat_names = ["🍗", "💛", "✨", "⚡"]
	var stat_colors = [Color(1, 0.6, 0.4), Color(1, 0.5, 0.6), Color(0.5, 0.9, 1), Color(1, 0.9, 0.4)]
	for i in range(4):
		var lbl = Label.new()
		lbl.text = stat_names[i] + " 100"
		lbl.position = Vector2(20 + i * 115, 65)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = stat_colors[i]
		add_child(lbl)
		stats_labels.append(lbl)
	
	# XP
	xp_label = Label.new()
	xp_label.text = "XP: 0/75"
	xp_label.position = Vector2(20, 90)
	xp_label.add_theme_font_size_override("font_size", 12)
	add_child(xp_label)
	
	# Location button
	location_btn = Button.new()
	location_btn.text = "📍 Cabin"
	location_btn.position = Vector2(20, 115)
	location_btn.size = Vector2(100, 35)
	location_btn.pressed.connect(_on_location_pressed)
	add_child(location_btn)
	
	# Evolve button
	evolve_btn = Button.new()
	evolve_btn.text = "✨ EVOLVE"
	evolve_btn.position = Vector2(380, 115)
	evolve_btn.size = Vector2(100, 35)
	evolve_btn.visible = false
	evolve_btn.pressed.connect(_on_evolve_pressed)
	add_child(evolve_btn)
	
	# Egg label
	egg_label = Label.new()
	egg_label.text = "Tap egg to check..."
	egg_label.position = Vector2(150, 200)
	egg_label.add_theme_font_size_override("font_size", 16)
	egg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(egg_label)
	
	# Pet sprite - smaller, centered
	pet_sprite = Sprite2D.new()
	pet_sprite.position = Vector2(240, 280)
	pet_sprite.scale = Vector2(1.5, 1.5)
	add_child(pet_sprite)
	
	# Poop container
	poop_container = VBoxContainer.new()
	poop_container.position = Vector2(50, 380)
	add_child(poop_container)
	
	# Message
	message_label = Label.new()
	message_label.position = Vector2(70, 250)
	message_label.size = Vector2(340, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	add_child(message_label)
	
	# Action buttons - bottom of screen
	var btn_data = [
		["🍗", Vector2(15, 500), _on_feed_pressed],
		["🎾", Vector2(105, 500), _on_play_pressed],
		["🧼", Vector2(195, 500), _on_clean_pressed],
		["💤", Vector2(285, 500), _on_sleep_pressed],
		["💊", Vector2(375, 500), _on_medicine_pressed],
		["🪑", Vector2(105, 560), _on_rest_pressed],
		["⚡", Vector2(195, 560), _on_schmeg_pressed],
	]
	
	for data in btn_data:
		var btn = Button.new()
		btn.text = data[0]
		btn.position = data[1]
		btn.size = Vector2(80, 45)
		btn.pressed.connect(data[2])
		add_child(btn)
		buttons.append(btn)
	
	# Make pet clickable - use input event on area
	var pet_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 100)
	collision.shape = shape
	pet_area.add_child(collision)
	pet_area.position = Vector2(240, 280)
	pet_area.input_event.connect(_on_pet_input)
	add_child(pet_area)

func _load_bg() -> void:
	var name = "bg-cabin.png"
	if current_location != "cabin":
		name = "bg-" + current_location + ".png"
	var path = BG_PATH + name
	if ResourceLoader.exists(path):
		bg_sprite.texture = load(path)

func _update_stats() -> void:
	if is_sleeping:
		energy = min(100.0, energy + 0.015)
		if energy >= 100:
			is_sleeping = false
			show_message("Good morning!")
	else:
		hunger = max(0.0, hunger - 0.0008)
		happiness = max(0.0, happiness - 0.0006)
		cleanliness = max(0.0, cleanliness - 0.0002)
		energy = max(0.0, energy - 0.0005)
	
	if randf() < 0.00008:
		_spawn_poop()

func _spawn_poop() -> void:
	if poop_list.size() < 8:
		poop_list.append({"is_golden": randf() < 0.05})
		poop_count = poop_list.size()
		_update_poops()

func _update_poops() -> void:
	for c in poop_container.get_children():
		c.queue_free()
	for p in poop_list:
		var lbl = Label.new()
		lbl.text = "✨💩" if p.get("is_golden", false) else "💩"
		lbl.add_theme_font_size_override("font_size", 18)
		poop_container.add_child(lbl)

func _check_evolution() -> void:
	if evolution_pending != "" or birth_time == 0:
		return
	var hours = age_minutes / 60
	match current_stage:
		Stage.BABY:
			if hours >= 8:
				evolution_pending = "TEEN"
				show_message("✨ TEEN READY!")
		Stage.TEEN_GOOD, Stage.TEEN_BAD:
			if hours >= 24:
				evolution_pending = "ADULT"
				show_message("✨ ADULT READY!")
	Stage.ADULT:
			if hours >= 168:
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
		show_message("👻 GHOST MODE")
		current_location = "tomb"
		_load_bg()

func _update_ui() -> void:
	# Stats
	var values = [hunger, happiness, cleanliness, energy]
	for i in range(4):
		stats_labels[i].text = ["🍗 ", "💛 ", "✨ ", "⚡ "[i] + str(int(values[i]))
		if values[i] < 30:
			stats_labels[i].modulate = Color.RED
		else:
			stats_labels[i].modulate = [Color(1, 0.6, 0.4), Color(1, 0.5, 0.6), Color(0.5, 0.9, 1), Color(1, 0.9, 0.4)][i]
	
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
	
	# Location
	location_btn.text = "📍 " + current_location.capitalize()
	
	# Egg label visibility
	egg_label.visible = has_egg
	
	# Buttons
	var disabled = is_sleeping or is_ghost or has_egg
	buttons[0].disabled = disabled  # feed
	buttons[1].disabled = disabled  # play
	buttons[2].disabled = disabled  # clean
	buttons[4].disabled = not is_sick  # medicine
	buttons[5].disabled = is_sleeping  # rest
	buttons[6].disabled = is_sleeping  # schmeg
	buttons[3].disabled = is_ghost  # sleep
	
	buttons[3].text = "☀️" if is_sleeping else "💤"
	
	# Sprite
	_update_sprite()

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

func show_message(text: String) -> void:
	message_label.text = text
	get_tree().create_timer(2.5).timeout.connect(func(): 
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
	_update_poops()
	show_message("Sparkling clean!")

func _on_sleep_pressed() -> void:
	if has_egg or is_ghost:
		return
	is_sleeping = not is_sleeping
	if is_sleeping:
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

func _on_pet_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if has_egg:
			if egg_hatch_time > 0:
				egg_hatch_time -= 30
				var now = Time.get_unix_time_from_system()
				show_message("🥚 %d min!" % max(0, ceil((egg_hatch_time - now) / 60.0)))
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
	show_message("🥚 Welcome! Egg will hatch in 1 hour.")
