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

var bg_sprite
var pet_sprite
var title_label
var stage_label
var age_label
var stats_container
var stats_bars = []
var stats_labels = []
var message_label
var location_btn
var evolve_btn
var location_menu
var buttons = []
var collection_btn
var collection_panel
var collection_labels = []

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
		pet_sprite.position.y = 280 + sin(now * 3) * 5
		return
	
	age_minutes = int((Time.get_unix_time_from_system() - birth_time) / 60)
	_update_stats()
	_check_evolution()
	_check_death()
	_update_ui()
	_save_game()

func _build_ui():
	# Background
	bg_sprite = Sprite2D.new()
	bg_sprite.position = Vector2(180, 280)
	bg_sprite.scale = Vector2(0.55, 0.55)
	add_child(bg_sprite)
	_load_bg()
	
	# Title
	title_label = Label.new()
	title_label.text = "BULKAGACHI"
	title_label.position = Vector2(80, 8)
	title_label.add_theme_font_size_override("font_size", 22)
	add_child(title_label)
	
	# Stage
	stage_label = Label.new()
	stage_label.text = "LV 1"
	stage_label.position = Vector2(280, 8)
	stage_label.add_theme_font_size_override("font_size", 12)
	add_child(stage_label)
	
	# Age
	age_label = Label.new()
	age_label.text = "Age: 0h"
	age_label.position = Vector2(10, 32)
	age_label.add_theme_font_size_override("font_size", 11)
	add_child(age_label)
	
	# Stats container
	stats_container = VBoxContainer.new()
	stats_container.position = Vector2(10, 100)
	stats_container.add_theme_constant_override("separation", 8)
	add_child(stats_container)
	
	# Create 4 stat rows
	var stat_info = [
		["HUNGER", "🍗", Color(1, 0.5, 0.3)],
		["HAPPY", "💛", Color(1, 0.4, 0.5)],
		["CLEAN", "✨", Color(0.4, 0.8, 1)],
		["ENERGY", "⚡", Color(1, 0.85, 0.3)]
	]
	for info in stat_info:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(340, 20)
		stats_container.add_child(row)
		
		var name_lbl = Label.new()
		name_lbl.text = info[0] + " "
		name_lbl.custom_minimum_size = Vector2(60, 0)
		name_lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(name_lbl)
		
		var bar_bg = ColorRect.new()
		bar_bg.color = Color(0.15, 0.15, 0.2)
		bar_bg.custom_minimum_size = Vector2(200, 14)
		row.add_child(bar_bg)
		
		var bar_fill = ColorRect.new()
		bar_fill.color = info[2]
		bar_fill.custom_minimum_size = Vector2(200, 14)
		bar_bg.add_child(bar_fill)
		stats_bars.append(bar_fill)
		
		var val_lbl = Label.new()
		val_lbl.text = "100%"
		val_lbl.custom_minimum_size = Vector2(40, 0)
		val_lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(val_lbl)
		stats_labels.append(val_lbl)
	
	# Location button
	location_btn = Button.new()
	location_btn.text = "📍 CABIN"
	location_btn.position = Vector2(10, 75)
	location_btn.size = Vector2(90, 22)
	location_btn.pressed.connect(_show_location_menu)
	add_child(location_btn)
	
	# Collection button
	collection_btn = Button.new()
	collection_btn.text = "📊"
	collection_btn.position = Vector2(280, 75)
	collection_btn.size = Vector2(30, 22)
	collection_btn.pressed.connect(_toggle_collection)
	add_child(collection_btn)
	
	# Collection panel
	collection_panel = PanelContainer.new()
	collection_panel.position = Vector2(10, 50)
	collection_panel.size = Vector2(340, 60)
	collection_panel.visible = false
	add_child(collection_panel)
	var col_vbox = VBoxContainer.new()
	collection_panel.add_child(col_vbox)
	var col_items = ["Fed: 0", "Played: 0", "Cleaned: 0", "Golden: 0", "Lv: 1"]
	for item in col_items:
		var l = Label.new()
		l.text = item
		l.add_theme_font_size_override("font_size", 10)
		col_vbox.add_child(l)
		collection_labels.append(l)
	
	# Location menu
	location_menu = VBoxContainer.new()
	location_menu.position = Vector2(10, 98)
	location_menu.visible = false
	add_child(location_menu)
	var locs = ["cabin", "camp", "city", "beach", "mountain", "club"]
	for loc in locs:
		var b = Button.new()
		b.text = "📍 " + loc.to_upper()
		b.size = Vector2(90, 22)
		b.pressed.connect(func(): _set_location(loc))
		location_menu.add_child(b)
	
	# Evolve button
	evolve_btn = Button.new()
	evolve_btn.text = "✨ EVOLVE"
	evolve_btn.position = Vector2(200, 75)
	evolve_btn.size = Vector2(70, 22)
	evolve_btn.visible = false
	evolve_btn.pressed.connect(_on_evolve)
	add_child(evolve_btn)
	
	# Pet sprite
	pet_sprite = Sprite2D.new()
	pet_sprite.position = Vector2(180, 280)
	pet_sprite.scale = Vector2(1.0, 1.0)
	add_child(pet_sprite)
	
	# Message
	message_label = Label.new()
	message_label.position = Vector2(60, 230)
	message_label.size = Vector2(240, 25)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	add_child(message_label)
	
	# Action buttons - row 1
	var row1 = [
		["🍗", Vector2(10, 400), _on_feed],
		["🎾", Vector2(95, 400), _on_play],
		["🧼", Vector2(180, 400), _on_clean],
		["💤", Vector2(265, 400), _on_sleep]
	]
	for r in row1:
		var b = Button.new()
		b.text = r[0]
		b.position = r[1]
		b.size = Vector2(75, 40)
		b.pressed.connect(r[2])
		add_child(b)
		buttons.append(b)
	
	# Action buttons - row 2
	var row2 = [
		["💊", Vector2(10, 450), _on_medicine],
		["⚡", Vector2(95, 450), _on_schmeg],
		["🪑", Vector2(180, 450), _on_rest]
	]
	for r in row2:
		var b = Button.new()
		b.text = r[0]
		b.position = r[1]
		b.size = Vector2(75, 40)
		b.pressed.connect(r[2])
		add_child(b)
		buttons.append(b)
	
	# Pet tap area
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 80)
	col.shape = shape
	area.add_child(col)
	area.position = Vector2(180, 280)
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
			poop_list.append({"is_golden": randf() < 0.05})
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
		show_message("GHOST MODE!")
		current_location = "tomb"
		_load_bg()

func _update_ui():
	var vals = [hunger, happiness, cleanliness, energy]
	var colors = [Color(1, 0.5, 0.3), Color(1, 0.4, 0.5), Color(0.4, 0.8, 1), Color(1, 0.85, 0.3)]
	
	for i in range(4):
		stats_labels[i].text = str(int(vals[i])) + "%"
		var bar_w = 200.0 * (vals[i] / 100.0)
		stats_bars[i].custom_minimum_size.x = max(1, bar_w)
		if vals[i] < 30:
			stats_bars[i].modulate = Color.RED
		else:
			stats_bars[i].modulate = colors[i]
	
	var age_str = str(age_minutes / 60) + "h"
	if age_minutes >= 1440:
		age_str = str(age_minutes / 1440) + "d"
	age_label.text = "Age: " + age_str + " | LV " + str(level)
	
	if is_ghost:
		stage_label.text = "GHOST"
		stage_label.modulate = Color(0.7, 0.7, 0.8)
	else:
		var stages = ["EGG", "BABY", "GOOD", "BAD", "BULK", "ELDER"]
		stage_label.text = stages[current_stage]
		stage_label.modulate = Color.WHITE
	
	location_btn.text = "📍 " + current_location.to_upper()
	
	var dis = is_sleeping or is_ghost or has_egg
	buttons[0].disabled = dis
	buttons[1].disabled = dis
	buttons[2].disabled = dis
	buttons[4].disabled = not is_sick
	buttons[5].disabled = is_sleeping
	buttons[6].disabled = is_sleeping
	buttons[3].disabled = is_ghost
	buttons[3].text = "☀️" if is_sleeping else "💤"
	
	# Update collection
	var col_text = ["Fed: " + str(total_feeds), "Played: " + str(total_plays), "Cleaned: " + str(total_cleans), "Golden: " + str(poop_count), "Lv: " + str(level)]
	for i in range(col_text.size()):
		collection_labels[i].text = col_text[i]
	
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
	collection_panel.visible = false

func _toggle_collection():
	collection_panel.visible = not collection_panel.visible
	location_menu.visible = false

func _set_location(loc):
	current_location = loc
	location_menu.visible = false
	_load_bg()
	show_message(loc.to_upper())

func _on_feed():
	if has_egg or is_sleeping or is_ghost:
		return
	hunger = min(100.0, hunger + 30)
	energy = max(0.0, energy - 2)
	total_feeds += 1
	_add_xp(10)
	show_message("Yum!")

func _on_play():
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

func _on_clean():
	if has_egg or is_sleeping or is_ghost:
		return
	cleanliness = 100.0
	poop_list.clear()
	poop_count = 0
	is_sick = false
	total_cleans += 1
	_add_xp(10)
	show_message("Clean!")

func _on_sleep():
	if has_egg or is_ghost:
		return
	is_sleeping = not is_sleeping
	show_message("Goodnight!" if is_sleeping else "Good morning!")

func _on_medicine():
	if has_egg or is_ghost or not is_sick:
		return
	is_sick = false
	happiness = min(100.0, happiness + 20)
	show_message("Cured!")

func _on_schmeg():
	if has_egg or is_ghost or is_sleeping:
		return
	energy = min(100.0, energy + 30)
	show_message("Energy!")

func _on_rest():
	if has_egg or is_ghost or is_sleeping:
		return
	energy = min(100.0, energy + 15)
	show_message("+15 Energy!")

func _on_evolve():
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
				show_message(str(max(0, ceil((egg_hatch_time - now) / 60.0))) + " min!")
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
