extends Node2D

enum Stage { EGG, BABY, TEEN_GOOD, TEEN_BAD, ADULT, ELDER }

var pet_name = "Bulk"
var hunger = 100.0
var happiness = 100.0
var cleanliness = 100.0
var energy = 100.0
var level = 1
var xp = 0
var xp_needed = 75
var birth_time = 0
var age_minutes = 0
var current_stage = Stage.EGG
var evolution_pending = ""
var is_sleeping = false
var is_sick = false
var is_ghost = false
var poop_count = 0
var poop_list = []
var has_egg = true
var egg_start_time = 0
var egg_hatch_time = 0
var current_location = "cabin"
var total_plays = 0
var total_feeds = 0
var total_cleans = 0

var pet_sprite
var bg_sprite
var title_label
var age_label
var stage_label
var egg_label
var stats_labels = []
var xp_label
var message_label
var buttons = []
var location_btn
var evolve_btn
var poop_container

const SPRITE_PATH = "res://assets/sprites/"

func _ready():
	randomize()
	_build_ui()
	_load_game()
	if birth_time == 0:
		_start_new_game()
	else:
		has_egg = false
	_update_ui()

func _process(delta):
	if has_egg:
		var now = Time.get_unix_time_from_system()
		if now >= egg_hatch_time:
			_hatch_egg()
		var elapsed = now - egg_start_time
		pet_sprite.position.y = 300 + sin(now * 3) * 5
		egg_label.text = "Hatching in %d min..." % max(0, ceil((egg_hatch_time - now) / 60.0))
		return
	
	age_minutes = int((Time.get_unix_time_from_system() - birth_time) / 60)
	_update_stats()
	_check_evolution()
	_check_death()
	_update_ui()
	_save_game()

func _build_ui():
	bg_sprite = Sprite2D.new()
	bg_sprite.position = Vector2(270, 500)
	bg_sprite.scale = Vector2(0.5, 0.5)
	add_child(bg_sprite)
	_load_bg()
	
	title_label = Label.new()
	title_label.text = "BULKAGACHI"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 20)
	add_child(title_label)
	
	stage_label = Label.new()
	stage_label.position = Vector2(420, 15)
	stage_label.add_theme_font_size_override("font_size", 14)
	add_child(stage_label)
	
	age_label = Label.new()
	age_label.position = Vector2(20, 40)
	age_label.add_theme_font_size_override("font_size", 14)
	add_child(age_label)
	
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
	
	xp_label = Label.new()
	xp_label.text = "XP: 0/75"
	xp_label.position = Vector2(20, 90)
	xp_label.add_theme_font_size_override("font_size", 12)
	add_child(xp_label)
	
	location_btn = Button.new()
	location_btn.text = "📍 Cabin"
	location_btn.position = Vector2(20, 115)
	location_btn.size = Vector2(100, 35)
	location_btn.pressed.connect(_on_location_pressed)
	add_child(location_btn)
	
	evolve_btn = Button.new()
	evolve_btn.text = "✨ EVOLVE"
	evolve_btn.position = Vector2(380, 115)
	evolve_btn.size = Vector2(100, 35)
	evolve_btn.visible = false
	evolve_btn.pressed.connect(_on_evolve_pressed)
	add_child(evolve_btn)
	
	egg_label = Label.new()
	egg_label.text = "Tap egg to check..."
	egg_label.position = Vector2(150, 200)
	egg_label.add_theme_font_size_override("font_size", 16)
	egg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(egg_label)
	
	pet_sprite = Sprite2D.new()
	pet_sprite.position = Vector2(240, 280)
	pet_sprite.scale = Vector2(1.5, 1.5)
	add_child(pet_sprite)
	
	poop_container = VBoxContainer.new()
	poop_container.position = Vector2(50, 380)
	add_child(poop_container)
	
	message_label = Label.new()
	message_label.position = Vector2(70, 250)
	message_label.size = Vector2(340, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	add_child(message_label)
	
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
	
	var pet_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 100)
	collision.shape = shape
	pet_area.add_child(collision)
	pet_area.position = Vector2(240, 280)
	pet_area.input_event.connect(_on_pet_input)
	add_child(pet_area)

func _load_bg():
	var name = "bg-cabin.png"
	if current_location != "cabin":
		name = "bg-" + current_location + ".png"
	var path = SPRITE_PATH + name
	if ResourceLoader.exists(path):
		bg_sprite.texture = load(path)

func _update_stats():
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

func _spawn_poop():
	if poop_list.size() < 8:
		poop_list.append({"is_golden": randf() < 0.05})
		poop_count = poop_list.size()
		_update_poops()

func _update_poops():
	for c in poop_container.get_children():
		c.queue_free()
	for p in poop_list:
		var lbl = Label.new()
		lbl.text = "💩"
		if p.get("is_golden", false):
			lbl.text = "✨💩"
		lbl.add_theme_font_size_override("font_size", 18)
		poop_container.add_child(lbl)

func _check_evolution():
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

func _hatch_egg():
	has_egg = false
	birth_time = Time.get_unix_time_from_system()
	age_minutes = 0
	current_stage = Stage.BABY
	happiness = 100
	energy = 100
	_add_xp(25)
	show_message("🥚 WELCOME!")

func _check_death():
	if is_ghost:
		return
	if hunger <= 0:
		is_ghost = true
		show_message("👻 GHOST MODE")
		current_location = "tomb"
		_load_bg()

func _update_ui():
	var values = [hunger, happiness, cleanliness, energy]
	var icons = ["🍗 ", "💛 ", "✨ ", "⚡ "]
	var colors = [Color(1, 0.6, 0.4), Color(1, 0.5, 0.6), Color(0.5, 0.9, 1), Color(1, 0.9, 0.4)]
	for i in range(4):
		stats_labels[i].text = icons[i] + str(int(values[i]))
		if values[i] < 30:
			stats_labels[i].modulate = Color.RED
		else:
			stats_labels[i].modulate = colors[i]
	
	var age_str = "%dh" % (age_minutes / 60)
	if age_minutes >= 1440:
		age_str = "%dd" % (age_minutes / 1440)
	age_label.text = "Age: %s | Lv %d" % [age_str, level]
	
	xp_label.text = "XP: %d/%d" % [xp, xp_needed]
	
	match current_stage:
		0: stage_label.text = "🥚 EGG"
		1: stage_label.text = "🐣 BABY"
		2: stage_label.text = "🐥 GOOD"
		3: stage_label.text = "🐥 BAD"
		4: stage_label.text = "🐓 ADULT"
		5: stage_label.text = "🧓 ELDER"
	
	location_btn.text = "📍 " + current_location.capitalize()
	egg_label.visible = has_egg
	
	var disabled = is_sleeping or is_ghost or has_egg
	buttons[0].disabled = disabled
	buttons[1].disabled = disabled
	buttons[2].disabled = disabled
	buttons[4].disabled = not is_sick
	buttons[5].disabled = is_sleeping
	buttons[6].disabled = is_sleeping
	buttons[3].disabled = is_ghost
	buttons[3].text = "☀️" if is_sleeping else "💤"
	
	_update_sprite()

func _update_sprite():
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
		0: sprite_name = "egg.png"
		1: sprite_name = "baby-" + mood + ".png"
		2: sprite_name = "teen-good-" + mood + ".png"
		3: sprite_name = "teen-bad-" + mood + ".png"
		4: sprite_name = "bulk-" + mood + ".png"
		5: sprite_name = "elder-" + mood + ".png"
	
	var path = SPRITE_PATH + sprite_name
	if ResourceLoader.exists(path):
		pet_sprite.texture = load(path)

func show_message(text):
	message_label.text = text
	get_tree().create_timer(2.5).timeout.connect(func(): 
		if message_label.text == text:
			message_label.text = ""
	)

func _on_feed_pressed():
	if has_egg or is_sleeping or is_ghost:
		return
	hunger = min(100.0, hunger + 30)
	energy = max(0.0, energy - 2)
	total_feeds += 1
	_add_xp(10)
	show_message("Yum!")

func _on_play_pressed():
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

func _on_clean_pressed():
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

func _on_sleep_pressed():
	if has_egg or is_ghost:
		return
	is_sleeping = not is_sleeping
	if is_sleeping:
		show_message("Goodnight...")
	else:
		show_message("Good morning!")

func _on_medicine_pressed():
	if has_egg or is_ghost or not is_sick:
		return
	is_sick = false
	happiness = min(100.0, happiness + 20)
	show_message("Cured!")

func _on_rest_pressed():
	if has_egg or is_ghost or is_sleeping:
		return
	energy = min(100.0, energy + 15)
	show_message("+15 Energy!")

func _on_schmeg_pressed():
	if has_egg or is_ghost or is_sleeping:
		return
	energy = min(100.0, energy + 30)
	show_message("⚡ Energy!")

func _on_location_pressed():
	var locations = ["cabin", "camp", "city", "beach", "mountain", "club"]
	var idx = locations.find(current_location)
	current_location = locations[(idx + 1) % locations.size()]
	_load_bg()
	show_message("📍 " + current_location.to_upper())

func _on_evolve_pressed():
	if evolution_pending == "":
		return
	match evolution_pending:
		"TEEN": current_stage = Stage.TEEN_GOOD
		"ADULT": current_stage = Stage.ADULT
		"ELDER": current_stage = Stage.ELDER
	evolution_pending = ""
	evolve_btn.visible = false
	show_message("✨ EVOLVED!")

func _on_pet_input(viewport, event, shape_idx):
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

func _add_xp(amount):
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 50 + level * 25
		show_message("LEVEL UP! LV %d" % level)

func _save_game():
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

func _load_game():
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

func _start_new_game():
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
