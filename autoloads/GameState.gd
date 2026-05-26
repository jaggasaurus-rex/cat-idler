extends Node

signal cat_purchased

var money: float = 0.0
var cats: int = 0
var next_cat_cost: float = 20.0


func click() -> void:
	money += 1.0


func buy_cat() -> void:
	if money < next_cat_cost:
		return
	money -= next_cat_cost
	cats += 1
	next_cat_cost *= 2.0
	cat_purchased.emit()
