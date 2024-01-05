extends TileMap

signal end_game
signal won_game
signal flag_place
signal flag_remove

const ROWS : int = 14
const COLS : int = 15
const CELL_SIZE : int = 50
var tile_id : int = 0
var mine_layer : int = 0
var number_layer : int = 1
var grass_layer : int = 2
var flag_layer : int = 3
var hover_layer : int = 4
var tile_atlas := Vector2i(4, 0)
var grass1_atlas := Vector2i(3, 0)
var grass2_atlas := Vector2i(2, 0)
var flag_atlas := Vector2i(5, 0)
var hover_atlas := Vector2i(6, 0)
var number_atlas : Array = generate_number_atlas()
var mine_coodinate := []

var mine_pos : Vector2i

func generate_number_atlas():
	var number_array = []
	for i in range(8):
		number_array.append(Vector2i(i, 1))
	return number_array

func _ready():
	new_game()

func new_game():
	clear()
	mine_coodinate.clear()
	generate_mines()
	generate_numbers()
	generate_grass()

func generate_mines():
	for i in range(get_parent().TOTAL_MINES):
		mine_pos = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		while mine_coodinate.has(mine_pos):
			mine_pos = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
		mine_coodinate.append(mine_pos)
		set_cell(mine_layer, mine_pos, tile_id, tile_atlas)

func generate_numbers():
	clear_layer(number_layer)
	for i in get_empty_cells():
		var mine_count : int = 0
		for j in get_surround_cell(i):
			if is_mine(j):
				mine_count = mine_count + 1
		if mine_count > 0:
			set_cell(number_layer, i, tile_id, number_atlas[mine_count - 1])

func generate_grass():
	for i in range(COLS):
		for j in range(ROWS):
			if (i + j) % 2 == 1:
				set_cell(grass_layer, Vector2i(i, j), tile_id, grass1_atlas)
			else:
				set_cell(grass_layer, Vector2i(i, j), tile_id, grass2_atlas)

func get_empty_cells():
	var empty_cells = []
	for y in range(ROWS):
		for x in range(COLS):
			if not is_mine(Vector2i(x, y)):
				empty_cells.append(Vector2i(x, y))
	return empty_cells

func get_surround_cell(middle_cell):
	var surround_cells := []
	var target_cell : Vector2i
	for i in range(3):
		for j in range(3):
			target_cell = Vector2i(middle_cell.x + i - 1, middle_cell.y + j - 1)
			if target_cell != middle_cell && target_cell.x >= 0 && target_cell.y >= 0 && target_cell.x < COLS && target_cell.y < ROWS:
				surround_cells.append(target_cell)
	return surround_cells

func is_mine(pos):
	return get_cell_source_id(mine_layer, pos) != -1

func is_grass(pos):
	return get_cell_source_id(grass_layer, pos) != -1

func is_number(pos):
	return get_cell_source_id(number_layer, pos) != -1

func is_flag(pos):
	return get_cell_source_id(flag_layer, pos) != -1

func highlight_cell():
	var mouse_pos := local_to_map(get_local_mouse_position())
	clear_layer(hover_layer)
	if is_grass(mouse_pos):
		set_cell(hover_layer, mouse_pos, tile_id, hover_atlas)
	else:
		if is_number(mouse_pos):
			set_cell(hover_layer, mouse_pos, tile_id, hover_atlas)

func _input(event):
	if event is InputEventMouseButton:
		if  event.position.y < ROWS * CELL_SIZE:
			var map_pos := local_to_map(event.position)
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if not is_flag(map_pos):
					if is_mine(map_pos):
						if get_parent().first_click:
							move_mine(map_pos)
							generate_numbers()
						else:
							end_game.emit()
							show_mines()
					else:
						open_mine(map_pos)
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				set_flags(map_pos)

func open_mine(pos):
	var reveal_cells := []
	var cells_to_reveal := [pos]
	while not cells_to_reveal.is_empty():
		erase_cell(grass_layer, cells_to_reveal[0])
		reveal_cells.append(cells_to_reveal[0])
		if is_flag(cells_to_reveal[0]):
			erase_cell(flag_layer, cells_to_reveal[0])
			flag_remove.emit()
		if not is_number(cells_to_reveal[0]):
			cells_to_reveal = reveal_surround_cells(cells_to_reveal, reveal_cells)
			
		cells_to_reveal.erase(cells_to_reveal[0])

func reveal_surround_cells(a, b):
	for i in get_surround_cell(a[0]):
		if not b.has(i):
			if not a.has(a):
				a.append(i)
	return a

func set_flags(pos):
	if is_grass(pos):
		if is_flag(pos):
			erase_cell(flag_layer, pos)
			flag_remove.emit()
		else:
				set_cell(flag_layer, pos, tile_id, flag_atlas)
				flag_place.emit()

func show_mines():
	for mine in mine_coodinate:
		if is_mine(mine):
			erase_cell(grass_layer, mine)

func move_mine(pos):
	for i in range(COLS):
		for j in range(ROWS):
			if not is_mine(Vector2i(i, j)) and get_parent().first_click == true:
				mine_coodinate[mine_coodinate.find(pos)] = Vector2i(i, j)
				erase_cell(mine_layer, pos)
				set_cell(mine_layer, Vector2i(i, j), tile_id, tile_atlas)
				get_parent().first_click = false

func _process(delta):
	highlight_cell()
