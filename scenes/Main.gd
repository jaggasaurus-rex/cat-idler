extends Control

@onready var fish_label: Label = $FishLabel


func _process(_delta: float) -> void:
	fish_label.text = "Fish: %.1f" % GameState.fish


func _on_pet_cat_button_pressed() -> void:
	GameState.click()
