extends Node3D

# THE PLUG - Prototype 0.1
# A vertical mobile management/adventure prototype.
# All world art is procedural so the project can be committed immediately without external assets.

const SAVE_PATH := "user://the_plug_save.json"
const GAME_MINUTES_PER_REAL_SECOND := 2.0
const DAY_MINUTES := 24 * 60

var cash: int = 150
var product_oz: float = 0.5
var seeds: int = 3
var pots: int = 0
var soil: int = 0
var fertilizer: int = 0
var watering_can: bool = false
var grow_light: bool = false
var plants: Array = []
var game_minutes: float = 8 * 60
var last_real_time: int = 0
var reputation: int = 0
var current_screen: String = "world"

var player: CharacterBody3D
var camera: Camera3D
var status_label: Label
var phone_panel: Panel
var modal: Panel
var modal_title: Label
var modal_body: Label
var modal_buttons: VBoxContainer
var toast: Label

var locations := {
	"garden": Vector3(-7, 0, -7),
	"grandma": Vector3(-7, 0, 5),
	"shed": Vector3(-3, 0, 5),
	"gas": Vector3(6, 0, -7),
	"liquor": Vector3(7, 0, 1),
	"park": Vector3(0, 0, -10),
	"police": Vector3(9, 0, 7),
	"fire": Vector3(-9, 0, 8)
}

func _ready() -> void:
	_load_game()
	_build_world()
	_build_player()
	_build_ui()
	_update_ui()
	last_real_time = int(Time.get_unix_time_from_system())

func _process(delta: float) -> void:
	var now := int(Time.get_unix_time_from_system())
	var elapsed := max(0, now - last_real_time)
	if elapsed > 0:
		game_minutes += float(elapsed) * GAME_MINUTES_PER_REAL_SECOND
		last_real_time = now
		_update_plants()
		_save_game()
	_update_ui()

func _physics_process(delta: float) -> void:
	if current_screen != "world" or player == null:
		return
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vec.length() > 0.0:
		player.velocity.x = input_vec.x * 4.5
		player.velocity.z = input_vec.y * 4.5
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, 18.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, 18.0 * delta)
	player.move_and_slide()
	player.global_position.x = clamp(player.global_position.x, -13.0, 13.0)
	player.global_position.z = clamp(player.global_position.z, -13.0, 13.0)
	camera.global_position = player.global_position + Vector3(0, 15, 13)
	camera.look_at(player.global_position + Vector3(0, 0, 1), Vector3.UP)

func _build_world() -> void:
	# Ground
	_add_box("Ground", Vector3(28, 0.2, 28), Vector3(0, -0.1, 0), Color("263027"))
	# Roads
	_add_box("RoadNS", Vector3(4.5, 0.08, 28), Vector3(2, 0.02, 0), Color("30343a"))
	_add_box("RoadEW", Vector3(28, 0.08, 4.5), Vector3(0, 0.03, -2), Color("30343a"))
	# Sidewalk strips
	_add_box("Sidewalk1", Vector3(1.0, 0.1, 28), Vector3(-0.75, 0.06, 0), Color("77756c"))
	_add_box("Sidewalk2", Vector3(1.0, 0.1, 28), Vector3(4.75, 0.06, 0), Color("77756c"))
	_add_box("Sidewalk3", Vector3(28, 0.1, 1.0), Vector3(0, 0.06, -4.75), Color("77756c"))
	_add_box("Sidewalk4", Vector3(28, 0.1, 1.0), Vector3(0, 0.06, 0.75), Color("77756c"))

	# Buildings / landmarks
	_add_building("Garden Center", locations.garden, Vector3(4.0, 2.6, 3.2), Color("526b3d"))
	_add_building("Grandma's House", locations.grandma, Vector3(3.6, 2.3, 3.2), Color("8a6e5b"))
	_add_building("Your Shed", locations.shed, Vector3(2.8, 2.0, 2.5), Color("5d5146"))
	_add_building("Gas Station", locations.gas, Vector3(4.0, 2.2, 3.0), Color("4c6470"))
	_add_building("Liquor Store", locations.liquor, Vector3(3.2, 2.1, 2.7), Color("6c5267"))
	_add_building("Police Station", locations.police, Vector3(4.2, 2.8, 3.5), Color("4c5868"))
	_add_building("Fire Department", locations.fire, Vector3(4.0, 2.7, 3.5), Color("7a4a3d"))

	# Park
	var park := MeshInstance3D.new()
	park.name = "Park"
	var pm := BoxMesh.new()
	pm.size = Vector3(6, 0.12, 5)
	park.mesh = pm
	park.position = locations.park + Vector3(0, 0.08, 0)
	park.material_override = _mat(Color("3e7046"))
	add_child(park)
	_add_box("Court", Vector3(3.5, 0.06, 2.0), locations.park + Vector3(0, 0.17, 0), Color("6d6d65"))

	# Trees
	for p in [Vector3(-11,0,-10), Vector3(-10,0,2), Vector3(-12,0,11), Vector3(5,0,11), Vector3(11,0,-10), Vector3(11,0,3), Vector3(0,0,11), Vector3(-5,0,-10)]:
		_add_tree(p)

	# Location labels in world
	for key in locations.keys():
		_add_world_label(key, locations[key] + Vector3(0, 3.0, 0))

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = locations.grandma + Vector3(0, 1, 4)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.42
	body.mesh = capsule
	body.material_override = _mat(Color("c58b5b"))
	player.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.42
	collider.shape = shape
	player.add_child(collider)
	add_child(player)

	camera = Camera3D.new()
	camera.position = player.position + Vector3(0, 15, 13)
	camera.current = true
	camera.fov = 45
	add_child(camera)
	camera.look_at(player.position, Vector3.UP)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	var top := ColorRect.new()
	top.color = Color("111315")
	top.position = Vector2(0, 0)
	top.size = Vector2(720, 112)
	layer.add_child(top)

	var title := Label.new()
	title.text = "THE PLUG"
	title.position = Vector2(24, 12)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("f2c230"))
	layer.add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(24, 55)
	status_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(status_label)

	var phone := Button.new()
	phone.text = "📱 PHONE"
	phone.position = Vector2(545, 20)
	phone.size = Vector2(145, 64)
	phone.add_theme_font_size_override("font_size", 18)
	phone.pressed.connect(_open_phone)
	layer.add_child(phone)

	# Bottom movement pad / quick actions
	var move_hint := Label.new()
	move_hint.text = "WASD / touch the arrows to move"
	move_hint.position = Vector2(22, 1190)
	move_hint.add_theme_font_size_override("font_size", 16)
	move_hint.modulate = Color(1,1,1,0.7)
	layer.add_child(move_hint)

	var actions := HBoxContainer.new()
	actions.position = Vector2(20, 1110)
	actions.size = Vector2(680, 70)
	actions.add_theme_constant_override("separation", 10)
	layer.add_child(actions)
	for spec in [["🪴 SHED", "shed"], ["🛒 STORE", "garden"], ["🗺 MAP", "map"]]:
		var b := Button.new()
		b.text = spec[0]
		b.custom_minimum_size = Vector2(215, 65)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_quick_action.bind(spec[1]))
		actions.add_child(b)

	toast = Label.new()
	toast.position = Vector2(24, 1040)
	toast.size = Vector2(672, 50)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 18)
	toast.modulate = Color("f2c230")
	layer.add_child(toast)

	# Modal
	modal = Panel.new()
	modal.position = Vector2(35, 150)
	modal.size = Vector2(650, 900)
	modal.visible = false
	layer.add_child(modal)

	modal_title = Label.new()
	modal_title.position = Vector2(25, 20)
	modal_title.size = Vector2(600, 60)
	modal_title.add_theme_font_size_override("font_size", 30)
	modal_title.add_theme_color_override("font_color", Color("f2c230"))
	modal.add_child(modal_title)

	modal_body = Label.new()
	modal_body.position = Vector2(25, 90)
	modal_body.size = Vector2(600, 260)
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_theme_font_size_override("font_size", 19)
	modal.add_child(modal_body)

	modal_buttons = VBoxContainer.new()
	modal_buttons.position = Vector2(25, 370)
	modal_buttons.size = Vector2(600, 490)
	modal_buttons.add_theme_constant_override("separation", 12)
	modal.add_child(modal_buttons)

func _open_phone() -> void:
	current_screen = "phone"
	_show_modal("YOUR PHONE", "DAY %d\n%02d:%02d AM/PM\n\nCash: $%d\nProduct: %.1f oz\nSeeds: %d\nReputation: %d\n\nYour phone is the control center for messages, business, inventory, crew and the map." % [_day(), _hour_12(), _minute(), cash, product_oz, seeds, reputation], [["BUSINESS", "business"], ["INVENTORY", "inventory"], ["MAP", "map"], ["CLOSE", "close"]])

func _quick_action(action: String) -> void:
	match action:
		"shed": _open_shed()
		"garden": _open_store()
		"map": _show_map()

func _open_store() -> void:
	current_screen = "modal"
	_show_modal("GARDEN CENTER", "Get the basics before you can start your first grow.\n\nCash: $%d\nPots: %d | Soil: %d | Fertilizer: %d\nWatering Can: %s | Grow Light: %s" % [cash, pots, soil, fertilizer, "YES" if watering_can else "NO", "YES" if grow_light else "NO"], [
		["BUY POT — $8", "pot"], ["BUY SOIL — $12", "soil"], ["BUY FERTILIZER — $10", "fert"], ["BUY WATERING CAN — $15", "water"], ["BUY GROW LIGHT — $35", "light"], ["LEAVE STORE", "close"]])

func _buy(item: String) -> void:
	var price := 0
	match item:
		"pot":
			price = 8
			if cash >= price: cash -= price; pots += 1; _toast("Bought a pot.")
		"soil":
			price = 12
			if cash >= price: cash -= price; soil += 1; _toast("Bought soil.")
		"fert":
			price = 10
			if cash >= price: cash -= price; fertilizer += 1; _toast("Bought fertilizer.")
		"water":
			price = 15
			if cash >= price and not watering_can: cash -= price; watering_can = true; _toast("Bought a watering can.")
		"light":
			price = 35
			if cash >= price and not grow_light: cash -= price; grow_light = true; _toast("Bought a cheap grow light.")
		else: return
	if cash < price:
		_toast("Not enough cash.")
	_save_game()
	_open_store()

func _open_shed() -> void:
	current_screen = "modal"
	var ready_count := 0
	for p in plants:
		if float(p.get("growth", 0.0)) >= 100.0: ready_count += 1
	var text := "Your first grow room.\n\nPlants: %d / %d\nReady: %d\nSeeds: %d\nPots: %d\nWatering can: %s\nFertilizer: %d\nGrow light: %s\n\nPlanting requires a pot + soil + seed." % [plants.size(), pots, ready_count, seeds, pots, "YES" if watering_can else "NO", fertilizer, "YES" if grow_light else "NO"]
	_show_modal("YOUR SHED", text, [["PLANT A SEED", "plant"], ["HARVEST READY PLANT", "harvest"], ["CLOSE", "close"]])

func _plant() -> void:
	if seeds <= 0:
		_toast("You're out of seeds.")
		return
	if plants.size() >= pots:
		_toast("You need another pot.")
		return
	if soil <= 0:
		_toast("You need soil.")
		return
	seeds -= 1
	soil -= 1
	plants.append({"growth": 0.0, "quality": 25.0, "planted_at": game_minutes})
	_toast("Seed planted. Come back as it grows.")
	_save_game()
	_open_shed()

func _harvest() -> void:
	for i in range(plants.size() - 1, -1, -1):
		if float(plants[i].get("growth", 0.0)) >= 100.0:
			var quality: float = float(plants[i].get("quality", 25.0))
			var yield_oz := 0.12 + quality / 1000.0
			product_oz += yield_oz
			plants.remove_at(i)
			_toast("Harvested %.2f oz. Product added to inventory." % yield_oz)
			_save_game()
			_open_shed()
			return
	_toast("Nothing is ready yet.")

func _show_map() -> void:
	current_screen = "modal"
	_show_modal("NEIGHBORHOOD MAP", "A small town is your first playground. Walk around and tap into the places that matter.\n\n🏚 Your Shed\n🛒 Garden Center\n⛽ Gas Station\n🍺 Liquor Store\n🌳 Park\n🚓 Police Station\n🚒 Fire Department\n\nPrototype note: these locations are placeholders for future events, shops and consequences.", [["GO TO SHED", "goto_shed"], ["GO TO GARDEN CENTER", "goto_garden"], ["CLOSE", "close"]])

func _show_business() -> void:
	_show_modal("BUSINESS", "Current operation: STARTING OUT\n\nCash: $%d\nInventory: %.1f oz\nPlants growing: %d\nReputation: %d\n\nNext milestone: get your shed operational, grow the first batch, then unlock your first customer opportunities." % [cash, product_oz, plants.size(), reputation], [["CLOSE", "close"]])

func _show_inventory() -> void:
	_show_modal("INVENTORY", "PRODUCT: %.1f oz\nSEEDS: %d\nPOTS: %d\nSOIL: %d\nFERTILIZER: %d\nWATERING CAN: %s\nGROW LIGHT: %s" % [product_oz, seeds, pots, soil, fertilizer, "YES" if watering_can else "NO", "YES" if grow_light else "NO"], [["CLOSE", "close"]])

func _show_modal(title_text: String, body_text: String, buttons: Array) -> void:
	modal.visible = true
	modal_title.text = title_text
	modal_body.text = body_text
	for child in modal_buttons.get_children(): child.queue_free()
	for spec in buttons:
		var b := Button.new()
		b.text = spec[0]
		b.custom_minimum_size = Vector2(600, 58)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_modal_action.bind(spec[1]))
		modal_buttons.add_child(b)

func _modal_action(action: String) -> void:
	match action:
		"close":
			modal.visible = false
			current_screen = "world"
		"pot", "soil", "fert", "water", "light": _buy(action)
		"plant": _plant()
		"harvest": _harvest()
		"business": _show_business()
		"inventory": _show_inventory()
		"map": _show_map()
		"goto_shed":
			modal.visible = false; player.position = locations.shed + Vector3(0, 1, 3); current_screen = "world"
		"goto_garden":
			modal.visible = false; player.position = locations.garden + Vector3(0, 1, 3); current_screen = "world"

func _update_plants() -> void:
	for p in plants:
		var age := max(0.0, game_minutes - float(p.get("planted_at", game_minutes)))
		var growth := min(100.0, age / 90.0 * 100.0)
		p["growth"] = growth
		var quality := 25.0
		if watering_can: quality += 15.0
		if fertilizer > 0: quality += 15.0
		if grow_light: quality += 15.0
		p["quality"] = min(100.0, quality)

func _update_ui() -> void:
	if status_label == null: return
	status_label.text = "DAY %d  •  %02d:%02d  •  $%d  •  %.1f OZ  •  🌱 %d" % [_day(), _hour_12(), _minute(), cash, product_oz, plants.size()]

func _day() -> int:
	return int(game_minutes / DAY_MINUTES) + 1

func _hour_12() -> int:
	var h := int(game_minutes / 60.0) % 24
	return (h + 11) % 12 + 1

func _minute() -> int:
	return int(game_minutes) % 60

func _toast(text: String) -> void:
	if toast:
		toast.text = text
		get_tree().create_timer(2.2).timeout.connect(func():
			if toast: toast.text = ""
		)

func _add_box(n: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(color)
	add_child(mi)

func _add_building(n: String, pos: Vector3, size: Vector3, color: Color) -> void:
	_add_box(n, size, pos + Vector3(0, size.y / 2.0, 0), color)
	_add_box(n + "Roof", Vector3(size.x + 0.25, 0.25, size.z + 0.25), pos + Vector3(0, size.y + 0.12, 0), color.darkened(0.25))

func _add_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = 1.5
	cyl.top_radius = 0.18
	cyl.bottom_radius = 0.22
	trunk.mesh = cyl
	trunk.position = pos + Vector3(0, 0.75, 0)
	trunk.material_override = _mat(Color("5b4634"))
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	crown.mesh = sphere
	crown.position = pos + Vector3(0, 2.0, 0)
	crown.material_override = _mat(Color("3e6b3d"))
	add_child(crown)

func _add_world_label(text: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text.replace("_", " ").to_upper()
	label.position = pos
	label.font_size = 32
	label.outline_size = 8
	label.modulate = Color("f2c230")
	add_child(label)

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m

func _save_game() -> void:
	var data := {
		"cash": cash,
		"product_oz": product_oz,
		"seeds": seeds,
		"pots": pots,
		"soil": soil,
		"fertilizer": fertilizer,
		"watering_can": watering_can,
		"grow_light": grow_light,
		"plants": plants,
		"game_minutes": game_minutes,
		"reputation": reputation,
		"saved_at": Time.get_unix_time_from_system()
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return
	cash = int(parsed.get("cash", cash))
	product_oz = float(parsed.get("product_oz", product_oz))
	seeds = int(parsed.get("seeds", seeds))
	pots = int(parsed.get("pots", pots))
	soil = int(parsed.get("soil", soil))
	fertilizer = int(parsed.get("fertilizer", fertilizer))
	watering_can = bool(parsed.get("watering_can", watering_can))
	grow_light = bool(parsed.get("grow_light", grow_light))
	plants = parsed.get("plants", plants)
	game_minutes = float(parsed.get("game_minutes", game_minutes))
	reputation = int(parsed.get("reputation", reputation))
	var saved_at := int(parsed.get("saved_at", Time.get_unix_time_from_system()))
	var elapsed := max(0, int(Time.get_unix_time_from_system()) - saved_at)
	game_minutes += float(elapsed) * GAME_MINUTES_PER_REAL_SECOND
