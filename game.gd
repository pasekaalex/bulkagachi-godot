extends Node2D

# Game state
var hunger = 100.0
var happiness = 100.0
var cleanliness = 100.0
var energy = 100.0
var level = 1
var age_hours = 0
var current_stage = 0  # 0=egg, 1=baby, 2=teen, 3=adult, 4=elder
var is_sleeping = false
var is_sick = false
var is_ghost = false
var has_egg = true
var location = "cabin"

# UI elements
var bg
var pet
var stats = {}
var buttons = {}
var message
var location_btn
var location_menu
var evolve_btn

func _ready():
	randomize()
	setup_ui()
	load_game()
	if not has_egg:
		age_hours = get_age_hours()
	update_all()

func _process(delta):
	if has_egg:
		return
	age_hours = get_age_hours()
	decrease_stats()
	update_all()
	save_game()

func setup_ui():
	# Background
	bg = Sprite2D.new()
	bg.position = Vector2(180, 280)
	bg.scale = Vector2(0.55, 0.55)
	add_child(bg)
	
	# Pet
	pet = Sprite2D.new()
	pet.position = Vector2(180, 280)
	add_child(pet)
	
	# Title
	var title = Label.new()
	title.text = "BULKAGACHI"
	title.position = Vector2(80, 5)
	title.add_theme_font_size_override("font_size", 20)
	add_child(title)
	
	# Level/Age
	var info = Label.new()
	info.position = Vector2(10, 30)
	info.add_theme_font_size_override("font_size", 11)
	add_child(info)
	stats["info"] = info
	
	# Location button
	location_btn = Button.new()
	location_btn.text = "CABIN"
	location_btn.position = Vector2(10, 72)
	location_btn.size = Vector2(80, 24)
	location_btn.pressed.connect(_toggle_location)
	add_child(location_btn)
	
	# Stats bars
	var y = 100
	var names = ["HUNGER", "HAPPY", "CLEAN", "ENERGY"]
	var colors = [Color(1, 0.5, 0.3), Color(1, 0.4, 0.5), Color(0.4, 0.8, 1), Color(1, 0.85, 0.3)]
	for i in range(4):
		var lbl = Label.new()
		lbl.text = names[i]
		lbl.position = Vector2(10, y)
		lbl.add_theme_font_size_override("font_size", 10)
		add_child(lbl)
		
		var bar_bg = ColorRect.new()
		bar_bg.color = Color(0.15, 0.15, 0.2)
		bar_bg.position = Vector2(70, y)
		bar_bg.size = Vector2(200, 12)
		add_child(bar_bg)
		
		var bar = ColorRect.new()
		bar.color = colors[i]
		bar.position = Vector2(70, y)
		bar.size = Vector2(200, 12)
		add_child(bar)
		stats[names[i].to_lower()] = bar
		
		var val = Label.new()
		val.text = "100%"
		val.position = Vector2(275, y)
		val.add_theme_font_size_override("font_size", 10)
		add_child(val)
		stats[names[i].to_lower() + "_val"] = val
		
		y += 18
	
	# Action buttons
	var btn_names = ["FEED", "PLAY", "CLEAN", "SLEEP", "MEDS", "SCHMEG", "REST"]
	var icons = ["🍗", "🎾", "🧼", "💤", "💊", "⚡", "🪑"]
	var funcs = [_on_feed, _on_play, _on_clean, _on_sleep, _on_meds, _on_schmeg, _on_rest]
	var bx = 10
	var by = 400
	for i in range(7):
		if i == 4:
			bx = 10
			by = 445
		var btn = Button.new()
		btn.text = icons[i]
		btn.position = Vector2(bx, by)
		btn.size = Vector2(75, 40)
		btn.pressed.connect(funcs[i])
		add_child(btn)
		buttons[btn_names[i]] = btn
		bx += 85
	
	# Message
	message = Label.new()
	message.position = Vector2(60, 220)
	message.size = Vector2(240, 30)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	add_child(message)
	
	# Location menu
	location_menu = VBoxContainer.new()
	location_menu.position = Vector2(10, 97)
	location_menu.visible = false
	add_child(location_menu)
	for loc in ["cabin", "camp", "city", "beach", "mountain", "club"]:
		var b = Button.new()
		b.text = loc.to_upper()
		b.size = Vector2(80, 22)
		b.pressed.connect(func(): _set_location(loc))
		location_menu.add_child(b)
	
	# Evolve button
	evolve_btn = Button.new()
	evolve_btn.text = "EVOLVE"
	evolve_btn.position = Vector2(260, 72)
	evolve_btn.size = Vector2(70, 24)
	evolve_btn.visible = false
	evolve_btn.pressed.connect(_on_evolve)
	add_child(evolve_btn)

func update_all():
	# Background
	var bg_name = "bg-" + location + ".png"
	if location == "cabin":
		bg_name = "bg-cabin.png"
	if is_ghost:
		bg_name = "bg-tomb-day.png"
	bg.texture = load("res://assets/sprites/" + bg_name)
	
	# Pet
	var pet_name = "baby"
	if current_stage == 0:
		pet_name = "egg"
	elif current_stage == 2:
		pet_name = "teen-good"
	elif current_stage == 3:
		pet_name = "bulk"
	elif current_stage == 4:
		pet_name = "elder"
	
	var mood = "happy"
	if is_ghost:
		mood = "ghost"
	elif is_sick:
		mood = "sick"
	elif is_sleeping:
		mood = "sleep"
	elif hunger < 30:
		mood = "hungry"
	elif happiness < 30:
		mood = "sad"
	
	var tex_path = "res://assets/sprites/" + pet_name + "-" + mood + ".png"
	if FileAccess.file_exists(tex_path):
		pet.texture = load(tex_path)
	
	# Stats
	var vals = {"hunger": hunger, "happy": happiness, "clean": cleanliness, "energy": energy}
	var colors = [Color(1, 0.5, 0.3), Color(1, 0.4, 0.5), Color(0.4, 0.8, 1), Color(1, 0.85, 0.3)]
	var i = 0
	for k in vals:
		var v = vals[k]
		stats[k].size.x = max(1, 200 * v / 100)
		stats[k].modulate = Color.RED if v < 30 else colors[i]
		stats[k + "_val"].text = str(int(v)) + "%"
		i += 1
	
	# Info
	var stage_name = "EGG"
	if current_stage == 1: stage_name = "BABY"
	elif current_stage == 2: stage_name = "TEEN"
	elif current_stage == 3: stage_name = "BULK"
	elif current_stage == 4: stage_name = "ELDER"
	if is_ghost: stage_name = "GHOST"
	stats["info"].text = stage_name + " | LV " + str(level) + " | " + str(age_hours) + "h"
	
	location_btn.text = location.to_upper()
	
	# Button states
	var dis = is_sleeping or is_ghost or has_egg
	buttons["FEED"].disabled = dis
	buttons["PLAY"].disabled = dis
	buttons["CLEAN"].disabled = dis
	buttons["MEDS"].disabled = not is_sick
	buttons["SCHMEG"].disabled = is_sleeping
	buttons["REST"].disabled = is_sleeping
	buttons["SLEEP"].disabled = is_ghost
	buttons["SLEEP"].text = "☀️" if is_sleeping else "💤"
	
	# Evolve
	evolve_btn.visible = should_evolve()

func decrease_stats():
	if is_sleeping:
		energy = min(100, energy + 0.02)
		if energy >= 100:
			is_sleeping = false
			msg("Good morning!")
	else:
		hunger = max(0, hunger - 0.001)
		happiness = max(0, happiness - 0.0008)
		cleanliness = max(0, cleanliness - 0.0003)
		energy = max(0, energy - 0.0006)
	
	if hunger <= 0 and not is_ghost:
		is_ghost = true
		msg("GHOST MODE!")

func get_age_hours():
	if has_egg or birth_time == 0:
		return 0
	return int((Time.get_unix_time_from_system() - birth_time) / 3600)

var birth_time = 0

func _toggle_location():
	location_menu.visible = not location_menu.visible

func _set_location(loc):
	location = loc
	location_menu.visible = false
	msg(loc.to_upper())
	update_all()

func _on_feed():
	hunger = min(100, hunger + 30)
	energy = max(0, energy - 3)
	level_xp(10)
	msg("Yum!")

func _on_play():
	if energy < 10:
		msg("Too tired!")
		return
	happiness = min(100, happiness + 20)
	energy = max(0, energy - 15)
	level_xp(15)
	msg("Fun!")

func _on_clean():
	cleanliness = 100
	is_sick = false
	level_xp(10)
	msg("Clean!")

func _on_sleep():
	is_sleeping = not is_sleeping
	msg("Goodnight!" if is_sleeping else "Wake up!")

func _on_meds():
	if is_sick:
		is_sick = false
		happiness = min(100, happiness + 20)
		msg("Cured!")

func _on_schmeg():
	energy = min(100, energy + 30)
	msg("Energy!")

func _on_rest():
	energy = min(100, energy + 15)
	msg("+15 Energy!")

func _on_evolve():
	current_stage += 1
	msg("EVOLVED!")
	update_all()

func should_evolve():
	if current_stage == 1 and age_hours >= 8:
		return true
	if current_stage == 2 and age_hours >= 24:
		return true
	if current_stage == 3 and age_hours >= 168:
		return true
	return false

func level_xp(amt):
	level += amt
	# Simple level up every 100 xp
	if level > level * 100:
		level = 1

func msg(text):
	message.text = text
	get_tree().create_timer(2.0).timeout.connect(func():
		if message.text == text:
			message.text = ""
	)

func save_game():
	var d = {
		"has_egg": has_egg,
		"birth_time": birth_time,
		"level": level,
		"hunger": hunger,
		"happiness": happiness,
		"cleanliness": cleanliness,
		"energy": energy,
		"current_stage": current_stage,
		"is_sleeping": is_sleeping,
		"is_sick": is_sick,
		"is_ghost": is_ghost,
		"location": location,
	}
	var f = FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

func load_game():
	if not FileAccess.file_exists("user://save.json"):
		# New game
		has_egg = true
		birth_time = Time.get_unix_time_from_system() + 3600
		return
	var f = FileAccess.open("user://save.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if d:
		has_egg = d.get("has_egg", true)
		birth_time = d.get("birth_time", 0)
		level = d.get("level", 1)
		hunger = d.get("hunger", 100.0)
		happiness = d.get("happiness", 100.0)
		cleanliness = d.get("cleanliness", 100.0)
		energy = d.get("energy", 100.0)
		current_stage = d.get("current_stage", 0)
		is_sleeping = d.get("is_sleeping", false)
		is_sick = d.get("is_sick", false)
		is_ghost = d.get("is_ghost", false)
		location = d.get("location", "cabin")
