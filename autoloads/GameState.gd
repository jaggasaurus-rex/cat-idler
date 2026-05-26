extends Node

signal cat_purchased

const CAT_COST: float = 100.0

var money: float = 0.0
var cats: int = 0


func click() -> void:
	money += 1.0


func buy_cat() -> void:
	if money < CAT_COST:
		return
	money -= CAT_COST
	cats += 1
	cat_purchased.emit()
