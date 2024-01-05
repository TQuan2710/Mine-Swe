extends CanvasLayer

signal restart

func _on_reset_button_pressed():
	restart.emit()
