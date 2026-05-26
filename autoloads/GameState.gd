extends Node

var fish: float = 0.0
var fish_per_click: float = 1.0


func click() -> void:
	fish += fish_per_click
