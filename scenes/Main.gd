extends Control

const CAT_SCENE := preload("res://scenes/CatCharacter.tscn")

@onready var money_label: Label = $MoneyLabel
@onready var cats_label: Label = $CatsLabel
@onready var purchase_cat_button: Button = $PurchaseCatButton
@onready var cat_container: Node2D = $CatContainer
@onready var onlypaws_button: Button = $OnlypawsButton
@onready var onlypaws_income_label: Label = $OnlypawsIncomeLabel
@onready var onlypaws_info_panel: PanelContainer = $OnlypawsInfoPanel


func _ready() -> void:
	GameState.cat_purchased.connect(_on_cat_purchased)


func _process(_delta: float) -> void:
	money_label.text = "Money: $%.2f" % GameState.money
	cats_label.text = "Cats: %d" % GameState.cats
	purchase_cat_button.text = "Purchase Cat ($%.2f)" % GameState.next_cat_cost
	onlypaws_income_label.text = "Onlypaws: $%.0f/sec" % GameState.paws_income_rate

	if GameState.shop_unlocked and not purchase_cat_button.visible:
		purchase_cat_button.visible = true

	# One-way latch — both the button and income label appear together
	if GameState.onlypaws_unlocked and not onlypaws_button.visible:
		onlypaws_button.visible = true
		onlypaws_income_label.visible = true


func _on_earn_money_button_pressed() -> void:
	GameState.click()


func _on_purchase_cat_button_pressed() -> void:
	GameState.buy_cat()


# Info panel is a toggle — the button itself has no game effect.
func _on_onlypaws_button_pressed() -> void:
	onlypaws_info_panel.visible = not onlypaws_info_panel.visible


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
