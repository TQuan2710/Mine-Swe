extends Node2D

var TOTAL_MINES : int = 40
var time_elapsed : float
var remaining_mines : int
var first_click : bool

func _ready():
	new_game()

func new_game():
	first_click = true
	time_elapsed = 0
	remaining_mines = TOTAL_MINES
	$TileMap.new_game()
	$GameOver.hide()
	get_tree().paused = false

func _on_tile_map_flag_place():
	remaining_mines = remaining_mines - 1

func _on_tile_map_flag_remove():
	remaining_mines = remaining_mines + 1

func _on_tile_map_end_game():
	end_game(-1)

func end_game(result):
	get_tree().paused = true
	$GameOver.show()
	if result == -1:
		$GameOver.get_node("Label").text = "BRUHHHHH"
	else:
		$GameOver.get_node("Label").text = "YOU WIN!"

func _on_game_over_restart():
	new_game()

func _process(delta):
	time_elapsed = time_elapsed + delta
	$HUD.get_node("Label_Flag").text = str(int(time_elapsed))
	$HUD.get_node("Label_Time").text = str(remaining_mines)
