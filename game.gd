extends Node2D

# Game state
var hunger = 100.0
var happiness = 100.0
var cleanliness = 100.0
var energy = 100.0
var level = 1
var age_hours = 0
var current_stage = 1
var is_sleeping = false
var is_sick = false
var is_ghost = false
var has_egg = true
var location = "cabin"
var birth_time = 0

# Sprites
var bg_sprite: Sprite2D
var pet_sprite: Sprite2D

# UI
var msg_label: Label
var location_btn: Button
var evolve_btn: Button
var location_menu: VBoxContainer
var stat_bars = {}
var stat_labels = {}
var action_btns = {}

const SPRITES = "res://assets/sprites/"

func _ready():
	randomize()
	_build_ui()
	_load_save()
	if birth_time == 0:
		_new_game()
	age_hours = get_age()
	update_display()

func _process(delta):
	if has_egg:
		return
	age_hours = get_age()
	_tick()
	update_display()
	_save()

func _build_ui():
	# Background
	bg_sprite = Sprite2D.new()
	bg_sprite.position = Vector2(180, 320)
	bg_sprite.scale = Vector2(0.6, 0.6)
	add_child(bg_sprite)
	
	# Pet - small!
	pet_sprite = Sprite2D.new()
	pet_sprite.position = Vector2(180, 280)
	pet_sprite.scale = Vector2(0.15, 0.15)
	add_child(pet_sprite)
	
	# Header - LV | STAGE
	var info = Label.new()
	info.position = Vector2(10, 8)
	info.add_theme_font_size_override("font_size", 14)
	info.name = "info"
	add_child(info)
	
	# Stats - labels on LEFT, bars on RIGHT
	var stats_y = 40
	var stat_names = ["HUNGER", "HAPPY", "CLEAN", "ENERGY"]
	var stat_colors = [Color(1, 0.5, 0.3), Color(1, 0.4, 0.5), Color(0.4, 0.8, 1), Color(1, 0.85, 0.3)]
	for i in range(4):
		# Label on left
		var lbl = Label.new()
		lbl.text = stat_names[i]
		lbl.position = Vector2(10, stats_y)
		lbl.add_theme_font_size_override("font_size", 11)
		add_child(lbl)
		stat_labels[stat_names[i].to_lower()] = lbl
		
		# Bar on right
		var bar_bg = ColorRect.new()
		bar_bg.color = Color(0.1, 0.1, 0.15)
		bar_bg.position = Vector2(80, stats_y)
		bar_bg.size = Vector2(160, 14)
		add_child(bar_bg)
		
		var bar_fill = ColorRect.new()
		bar_fill.color = stat_colors[i]
		bar_fill.position = Vector2(80, stats_y)
		bar_fill.size = Vector2(160, 14)
		bar_fill.name = "bar"
		bar_bg.add_child(bar_fill)
		stat_bars[stat_names[i].to_lower()] = bar_fill
		
		stats_y += 18
	
	# Location button
	location_btn = Button.new()
	location_btn.text = "TRAVEL"
	location_btn.position = Vector2(10, 115)
	location_btn.size = Vector2(70, 26)
	location_btn.pressed.connect(_toggle_loc_menu)
	add_child(location_btn)
	
	# Evolve button
	evolve_btn = Button.new()
	evolve_btn.text = "EVOLVE"
	evolve_btn.position = Vector2(260, 115)
	evolve_btn.size = Vector2(70, 26)
	evolve_btn.visible = false
	evolve_btn.pressed.connect(_evolve)
	add_child(evolve_btn)
	
	# Location menu
	location_menu = VBoxContainer.new()
	location_menu.position = Vector2(10, 142)
	location_menu.visible = false
	add_child(location_menu)
	for loc in ["cabin", "camp", "city", "beach", "mountain", "club"]:
		var b = Button.new()
		b.text = loc
		b.size = Vector2(70, 24)
		b.pressed.connect(func(): _set_loc(loc))
		location_menu.add_child(b)
	
	# Action buttons - 2 rows of 4
	var actions = [
		["FEED", "🍗", 10, 460],
		["PLAY", "🎾", 95, 460],
		["CLEAN", "🧼", 180, 460],
		["SLEEP", "💤", 265, 460],
		["MEDS", "💊", 10, 510],
		["SCHMEG", "⚡", 95, 510],
		["REST", "🪑", 180, 510],
		["TRAVEL", "🌍", 265, 510],
	]
	for a in actions:
		var btn = Button.new()
		btn.text = a[1]
		btn.position = Vector2(a[2], a[3])
		btn.size = Vector2(75, 42)
		btn.pressed.connect(_action.bind(a[0]))
		add_child(btn)
		action_btns[a[0]] = btn
	
	# Message
	msg_label = Label.new()
	msg_label.position = Vector2(60, 180)
	msg_label.size = Vector2(240, 25)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 14)
	add_child(msg_label)

func _action(act):
	match act:
		"FEED":
			hunger = min(100, hunger + 30)
			energy = max(0, energy - 3)
			_xp(10)
			_msg("Yum!")
		"PLAY":
			if energy < 10:
				_msg("Too tired!")
				return
			happiness = min(100, happiness + 20)
			energy = max(0, energy - 15)
			_xp(15)
			_msg("Fun!")
		"CLEAN":
			cleanliness = 100
			is_sick = false
			_xp(10)
			_msg("Clean!")
		"SLEEP":
			is_sleeping = not is_sleeping
			_msg("Goodnight!" if is_sleeping else "Wake up!")
		"MEDS":
			if is_sick:
				is_sick = false
				happiness = min(100, happiness + 20)
				_msg("Cured!")
		"SCHMEG":
			energy = min(100, energy + 30)
			_msg("Energy!")
		"REST":
			energy = min(100, energy + 15)
			_msg("+15 Energy!")
		"TRAVEL":
			_toggle_loc_menu()

func _xp(amt):
	level += amt

func _msg(t):
	msg_label.text = t
	get_tree().create_timer(2.0).timeout.connect(func():
		if msg_label.text == t:
			msg_label.text = ""
	)

func _tick():
	if is_sleeping:
		energy = min(100, energy + 0.02)
		if energy >= 100:
			is_sleeping = false
			_msg("Good morning!")
	else:
		hunger = max(0, hunger - 0.001)
		happiness = max(0, happiness - 0.0008)
		cleanliness = max(0, cleanliness - 0.0003)
		energy = max(0, energy - 0.0006)
	
	if hunger <= 0 and not is_ghost:
		is_ghost = true
		_msg("GHOST MODE!")

func get_age():
	if birth_time == 0:
		return 0
	return int((Time.get_unix_time_from_system() - birth_time) / 3600)

func _evolve():
	current_stage += 1
	_msg("EVOLVED!")
	update_display()

func _toggle_loc_menu():
	location_menu.visible = not location_menu.visible

func _set_loc(loc):
	location = loc
	location_menu.visible = false
	_msg(loc.to_upper())
	update_display()

func _load_save():
	if FileAccess.file_exists("user://save.json"):
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
			current_stage = d.get("current_stage", 1)
			is_sleeping = d.get("is_sleeping", false)
			is_sick = d.get("is_sick", false)
			is_ghost = d.get("is_ghost", false)
			location = d.get("location", "cabin")

func _save():
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

func _new_game():
	has_egg = true
	birth_time = Time.get_unix_time_from_system() + 3600

func update_display():
	# Background - use night variants!
	var bg_name = "bg-cabin.png"
	if is_ghost:
		bg_name = "bg-tomb-night.png"
	elif location == "camp": bg_name = "bg-camp-night.png"
	elif location == "city": bg_name = "bg-city-night.png"
	elif location == "beach": bg_name = "bg-beach.png"
	elif location == "mountain": bg_name = "bg-mountain.png"
	elif location == "club": bg_name = "bg-club.png"
	
	var bg_path = SPRITES + bg_name
	if ResourceLoader.exists(bg_path):
		bg_sprite.texture = load(bg_path)
	
	# Pet
	var stage_names = ["egg", "baby", "teen-good", "bulk", "elder"]
	var mood = "happy"
	if is_ghost: mood = "ghost"
	elif is_sick: mood = "sick"
	elif is_sleeping: mood = "sleep"
	elif hunger < 30: mood = "hungry"
	elif happiness < 30: mood = "sad"
	
	var pet_path = SPRITES + stage_names[current_stage] + "-" + mood + ".png"
	if ResourceLoader.exists(pet_path):
		pet_sprite.texture = load(pet_path)
	
	# Stats
	var stats = {"hunger": hunger, "happy": happiness, "clean": cleanliness, "energy": energy}
	var colors = [Color(1, 0.5, 0.3), Color(1, 0.4, 0.5), Color(0.4, 0.8, 1), Color(1, 0.85, 0.3)]
	var i = 0
	for k in stats:
		var v = stats[k]
		stat_bars[k].size.x = max(1, 160 * v / 100)
		stat_bars[k].modulate = Color.RED if v < 30 else colors[i]
		i += 1
	
	# Info - LV | GHOST
	var stages = ["EGG", "BABY", "TEEN", "BULK", "ELDER"]
	var st = stages[current_stage]
	if is_ghost: st = "GHOST"
	get_node("info").text = "LV " + str(level) + " " + st
	
	# Buttons
	var dis = is_sleeping or is_ghost or has_egg
	action_btns["FEED"].disabled = dis
	action_btns["PLAY"].disabled = dis
	action_btns["CLEAN"].disabled = dis
	action_btns["MEDS"].disabled = not is_sick
	action_btns["SCHMEG"].disabled = is_sleeping
	action_btns["REST"].disabled = is_sleeping
	action_btns["SLEEP"].disabled = is_ghost
	action_btns["SLEEP"].text = "☀️" if is_sleeping else "💤"
	
	# Evolve
	evolve_btn.visible = false
	if current_stage == 1 and age_hours >= 8: evolve_btn.visible = true
	if current_stage == 2 and age_hours >= 24: evolve_btn.visible = true
	if current_stage == 3 and age_hours >= 168: evolve_btn.visible = true
	
	location_menu.visible = false
