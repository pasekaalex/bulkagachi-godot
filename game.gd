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
var location_btn
var evolve_btn
var location_menu
var buttons = []

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
		pet_sprite.position.y = 250 + sin(now * 3) * 5
		egg_label.text = "Hatching in %d min..." % max(0, ceil((egg_hatch_time - now) / 60.0))
		return
	
	age_minutes = int((Time.get_unix_time_from_system() - birth_time) / 60)
	_update_stats()
	_check_evolution()
	_check_death()
	_update_ui()
	_save_game()

func _build_ui():
	# Background - cover screen
	bg_sprite = Sprite2D.new()
	bg_sprite.position = Vector2(270, 400)
	bg_sprite.scale = Vector2(0.85, 0.85)
	add_child(bg_sprite)
	_load_bg()
	
	# Title
	title_label = Label.new()
	title_label.text = "BULKAGACHI"
	title_label.position = Vector2(10, 10)
	title_label.add_theme_font_size_override("font_size", 18)
	add_child(title_label)
	
	# Stage
	stage_label = Label.new()
	stage_label.position = Vector2(430, 10)
	stage_label.add_theme_font_size_override("font_size", 12)
	add_child(stage_label)
	
	# Age
	age_label = Label.new()
	age_label.position = Vector2(10, 32)
	age_label.add_theme_font_size_override("font_size", 12)
	add_child(age_label)
	
	# Stats
	var stat_data = [
		["🍗", Vector2(10, 55), Color(1, 0.6, 0.4)],
		["💛", Vector2(100, 55), Color(1, 0.5, 0.6)],
		["✨", Vector2(190, 55), Color(0.5, 0.9, 1)],
		["⚡", Vector2(280, 55), Color(1, 0.9, 0.4)]
	]
	for d in stat_data:
		var lbl = Label.new()
		lbl.text = d[0] + " 100"
		lbl.position = d[1]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = d[2]
		add_child(lbl)
		stats_labels.append(lbl)
	
	# XP
	xp_label = Label.new()
	xp_label.text = "XP: 0/75"
	xp_label.position = Vector2(370, 55)
	xp_label.add_theme_font_size_override("font_size", 10)
	add_child(xp_label)
	
	# Location button
	location_btn = Button.new()
	location_btn.text = "📍"
	location_btn.position = Vector2(10, 75)
	location_btn.size = Vector2(50, 25)
	location_btn.pressed.connect(_show_location_menu)
	add_child(location_btn)
	
	# Evolve button
	evolve_btn = Button.new()
	evolve_btn.text = "EVOLVE"
	evolve_btn.position = Vector2(430, 75)
	evolve_btn.size = Vector2(60, 25)
	evolve_btn.visible = false
	evolve_btn.pressed.connect(_on_evolve_pressed)
	add_child(evolve_btn)
	
	# Location menu (hidden)
	location_menu = VBoxContainer.new()
	location_menu.position = Vector2(10, 100)
	location_menu.visible = false
	add_child(location_menu)
	var locs = ["cabin", "camp", "city", "beach", "mountain", "club"]
	for loc in locs:
		var btn = Button.new()
		btn.text = "📍 " + loc
		btn.size = Vector2(80, 25)
		btn.pressed.connect(func(): _set_location(loc))
		location_menu.add_child(btn)
	
	# Egg label
	egg_label = Label.new()
	egg_label.text = "Tap egg..."
	egg_label.position = Vector2(150, 180)
	egg_label.add_theme_font_size_override("font_size", 14)
	egg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(egg_label)
	
	# Pet sprite
	pet_sprite = Sprite2D.new()
	pet_sprite.position = Vector2(240, 230)
	pet_sprite.scale = Vector2(1.2, 1.2)
	add_child(pet_sprite)
	
	# Message
	message_label = Label.new()
	message_label.position = Vector2(50, 200)
	message_label.size = Vector2(380, 25)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	add_child(message_label)
	
	# Action buttons
	var btn_info = [
		["🍗", Vector2(10, 320), _on_feed_pressed],
		["🎾", Vector2(80, 320), _on_play_pressed],
		["🧼", Vector2(150, 320), _on_clean_pressed],
		["💤", Vector2(220, 320), _on_sleep_pressed],
		["💊", Vector2(290, 320), _on_medicine_pressed],
		["🪑", Vector2(360, 320), _on_rest_pressed],
		["⚡", Vector2(80, 365), _on_schmeg_pressed],
	]
	for info in btn_info:
		var btn = Button.new()
		btn.text = info[0]
		btn.position = info[1]
		btn.size = Vector2(60, 35)
		btn.pressed.connect(info[2])
		add_child(btn)
		buttons.append(btn)
	
	# Pet area
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 80)
	col.shape = shape
	area.add_child(col)
	area.position = Vector2(240, 230)
	area.input_event.connect(_on_pet_tap)
	add_child(area)

func _load_bg():
	var name = "bg-cabin.png"
	if current_location != "cabin":
		name = "bg-" + current_location + ".png"
		if current_location == "tomb":
			name = "bg-tomb-day.png"
	var path = SPRITE_PATH + name
	if not ResourceLoader.exists(path):
		path = SPRITE_PATH + "bg-cabin.png"
	if ResourceLoader.exists(path):
		bg_sprite.texture = load(path)

func _update_stats():
	if is_sleeping:
		energy = min(100.0, energy + 0.01)
		if energy >= 100:
			is_sleeping = false
			show_message("Good morning!")
	else:
		hunger = max(0.0, hunger - 0.0005)
		happiness = max(0.0, happiness - 0.0004)
		cleanliness = max(0.0, cleanliness - 0.0001)
		energy = max(0.0, energy - 0.0003)
	
	if randf() < 0.00005:
		if poop_list.size() < 5:
			poop_list.append({"is_golden": randf() < 0.05, "x": 50 + randf() * 300, "y": 280 + randf() * 50})
			poop_count = poop_list.size()

func _check_evolution():
	if evolution_pending != "" or birth_time == 0:
		return
	var hours = age_minutes / 60
	match current_stage:
		Stage.BABY:
			if hours >= 8:
				evolution_pending = "TEEN"
				show_message("TEEN READY!")
		Stage.TEEN_GOOD, Stage.TEEN_BAD:
			if hours >= 24:
				evolution_pending = "ADULT"
				show_message("ADULT READY!")
		Stage.ADULT:
			if hours >= 168:
				evolution_pending = "ELDER"
				show_message("ELDER READY!")
	evolve_btn.visible = evolution_pending != ""

func _hatch_egg():
	has_egg = false
	birth_time = Time.get_unix_time_from_system()
	age_minutes = 0
	current_stage = Stage.BABY
	happiness = 100
	energy = 100
	_add_xp(25)
	show_message("WELCOME!")

func _check_death():
	if is_ghost:
		return
	if hunger <= 0:
		is_ghost = true
		show_message("GHOST MODE")
		current_location = "tomb"
		_load_bg()

func _update_ui():
	var vals = [hunger, happiness, cleanliness, energy]
	var icons = ["🍗 ", "💛 ", "✨ ", "⚡ "]
	var colors = [Color(1, 0.6, 0.4), Color(1, 0.5, 0.6), Color(0.5, 0.9, 1), Color(1, 0.9, 0.4)]
	for i in range(4):
		stats_labels[i].text = icons[i] + str(int(vals[i]))
		stats_labels[i].modulate = Color.RED if vals[i] < 30 else colors[i]
	
	var age_str = "%dh" % (age_minutes / 60)
	if age_minutes >= 1440:
		age_str = "%dd" % (age_minutes / 1440)
	age_label.text = "Age: %s | Lv %d" % [age_str, level]
	
	xp_label.text = "XP: %d/%d" % [xp, xp_needed]
	
	var stage_names = ["EGG", "BABY", "GOOD", "BAD", "ADULT", "ELDER"]
	stage_label.text = stage_names[current_stage]
	
	location_btn.text = "📍"
	egg_label.visible = has_egg
	
	var dis = is_sleeping or is_ghost or has_egg
	buttons[0].disabled = dis
	buttons[1].disabled = dis
	buttons[2].disabled = dis
	buttons[4].disabled = not is_sick
	buttons[5].disabled = is_sleeping
	buttons[6].disabled = is_sleeping
	buttons[3].disabled = is_ghost
	buttons[3].text = "☀️" if is_sleeping else "💤"
	
	location_menu.visible = false
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
	
	var names = ["egg", "baby", "teen-good", "teen-bad", "bulk", "elder"]
	var path = SPRITE_PATH + names[current_stage] + "-" + mood + ".png"
	if ResourceLoader.exists(path):
		pet_sprite.texture = load(path)

func show_message(text):
	message_label.text = text
	get_tree().create_timer(2.0).timeout.connect(func(): 
		if message_label.text == text:
			message_label.text = ""
	)

func _show_location_menu():
	location_menu.visible = not location_menu.visible

func _set_location(loc):
	current_location = loc
	location_menu.visible = false
	_load_bg()
	show_message(loc.to_upper())

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
	show_message("Clean!")

func _on_sleep_pressed():
	if has_egg or is_ghost:
		return
	is_sleeping = not is_sleeping
	show_message("Goodnight!" if is_sleeping else "Good morning!")

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
	show_message("Energy!")

func _on_evolve_pressed():
	if evolution_pending == "":
		return
	match evolution_pending:
		"TEEN": current_stage = Stage.TEEN_GOOD
		"ADULT": current_stage = Stage.ADULT
		"ELDER": current_stage = Stage.ELDER
	evolution_pending = ""
	evolve_btn.visible = false
	show_message("EVOLVED!")

func _on_pet_tap(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if has_egg:
			if egg_hatch_time > 0:
				egg_hatch_time -= 30
				var now = Time.get_unix_time_from_system()
				show_message("%d min!" % max(0, ceil((egg_hatch_time - now) / 60.0)))
			return
		if is_ghost:
			return
		happiness = min(100.0, happiness + 5)
		_add_xp(5)
		show_message("❤️")

func _add_xp(amt):
	xp += amt
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 50 + level * 25
		show_message("LEVEL UP!")

func _save_game():
	var d = {
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
	var f = FileAccess.open("user://bulkagachi_save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

func _load_game():
	if not FileAccess.file_exists("user://bulkagachi_save.json"):
		return
	var f = FileAccess.open("user://bulkagachi_save.json", FileAccess.READ)
	var j = JSON.parse_string(f.get_as_text())
	f.close()
	if j == null:
		return
	has_egg = j.get("has_egg", true)
	egg_start_time = j.get("egg_start_time", 0)
	egg_hatch_time = j.get("egg_hatch_time", 0)
	birth_time = j.get("birth_time", 0)
	level = j.get("level", 1)
	xp = j.get("xp", 0)
	xp_needed = j.get("xp_needed", 75)
	hunger = j.get("hunger", 100.0)
	happiness = j.get("happiness", 100.0)
	cleanliness = j.get("cleanliness", 100.0)
	energy = j.get("energy", 100.0)
	current_stage = j.get("current_stage", Stage.EGG)
	is_sleeping = j.get("is_sleeping", false)
	is_sick = j.get("is_sick", false)
	is_ghost = j.get("is_ghost", false)
	poop_count = j.get("poop_count", 0)
	current_location = j.get("current_location", "cabin")
	total_plays = j.get("total_plays", 0)
	total_feeds = j.get("total_feeds", 0)
	total_cleans = j.get("total_cleans", 0)
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
	show_message("Welcome! Egg hatches in 1 hour.")
