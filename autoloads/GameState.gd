extends Node

signal cat_purchased

var money: float = 0.0
var cats: int = 0
var next_cat_cost: float = 20.0
var shop_unlocked: bool = false


func click() -> void:
	money += 1.0
	if not shop_unlocked and money >= next_cat_cost:
		shop_unlocked = true


func buy_cat() -> void:
	if money < next_cat_cost:
		return
	money -= next_cat_cost
	cats += 1
	next_cat_cost *= 2.0
	cat_purchased.emit()
