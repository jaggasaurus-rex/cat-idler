extends Control

const CAT_SCENE := preload("res://scenes/CatCharacter.tscn")

@onready var money_label: Label = $MoneyLabel
@onready var cats_label: Label = $CatsLabel
@onready var purchase_cat_button: Button = $PurchaseCatButton
@onready var cat_container: Node2D = $CatContainer


func _ready() -> void:
	GameState.cat_purchased.connect(_on_cat_purchased)


func _process(_delta: float) -> void:
	money_label.text = "Money: $%.1f" % GameState.money
	cats_label.text = "Cats: %d" % GameState.cats
	purchase_cat_button.text = "Purchase Cat ($%.0f)" % GameState.next_cat_cost
	purchase_cat_button.visible = GameState.money >= GameState.next_cat_cost


func _on_earn_money_button_pressed() -> void:
	GameState.click()


func _on_purchase_cat_button_pressed() -> void:
	GameState.buy_cat()


func _on_cat_purchased() -> void:
	var cat := CAT_SCENE.instantiate()
	cat.scale = Vector2(0.4, 0.4)
	cat_container.add_child(cat)
	_reposition_cats()


# Keeps all purchased cats evenly spaced and centered around the
# container's origin so the row self-centres as it grows.
func _reposition_cats() -> void:
	var children := cat_container.get_children()
	var count := children.size()
	var spacing := 72.0
	var start_x := -(count - 1) * spacing / 2.0
	for i in count:
		children[i].position = Vector2(start_x + i * spacing, 0.0)
