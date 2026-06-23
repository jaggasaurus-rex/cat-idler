extends Node
# 54 string constants — edit this file to change all user-visible text.

## HUD — live labels updated every frame (use %s as the placeholder slot)
const HUD_MONEY           := "Money: $%s"
const HUD_CATS            := "Cats: %s/%s"
const HUD_ONLY_PAWS_RATE  := "OnlyPaws: $%.2f/sec"
const HUD_CAT_FOOD        := "Cat Food: %s"
const HUD_TOKENS          := "Tokens: %s"
const HUD_BOTS            := "Bots: %s"
const HUD_MEGA_BOTS       := "Mega-Bots: %s"
const HUD_RESEARCH_CATS   := "Cats researching: %s"
const HUD_CAT_INTELLIGENCE := "Cat Intelligence: %s"

## Cyborg Cats — live label + conversion/upgrade button templates
const HUD_CYBORG_CATS     := "Cyborg Cats: %s"
const BTN_MAKE_CYBORG     := "Make Cyborg Cat ($%s) [-1 cat]"
const BTN_CYBORG_MULTIPLIER := "Cyborg Enhancement x%s\n$%s"

## HUD — research panel state
const RESEARCH_NO_ACTIVE  := "No Active Research"
const RESEARCH_IN_PROGRESS := "In Progress…"
const RESEARCH_NEEDS_CATS := "Needs %s+ cats assigned to begin"

## Buttons — static labels set once in _ready()
const BTN_EARN_MONEY      := "Work at McPawnalds"
const BTN_ONLY_PAWS       := "Sell pics on OnlyPaws"
const BTN_ONLY_PAWS_ON    := "OnlyPaws: ON"
const BTN_ONLY_PAWS_OFF   := "OnlyPaws: OFF"

## Buttons — cost templates updated every frame
const BTN_PURCHASE_CAT    := "Purchase Cat ($%s)"
const BTN_MANAGER_BOT     := "OnlyPaws Manager-Bot ($%s)"
const BTN_MEGA_BOT        := "Mega-Bot ($%s)"
const BTN_BUY_FOOD        := "Buy Food ($%s)"
const BTN_BUY_FOOD_AUTO   := "Buy Food ($%s) ∞"
const BTN_BUY_TOKENS      := "Buy Tokens ($%s)"
const BTN_BUY_TOKENS_AUTO := "Buy Tokens ($%s) ∞"
const BTN_FUND_RESEARCH   := "Fund Research ($%s)"

## Buttons — shop items with embedded cost (set in _ready() after format)
const BTN_AUTO_FEEDER     := "Auto-Feeder\n$%s"
const BTN_BOT_MANAGER     := "Manager-Bot Manager\n$%s"
const BTN_PAWSCO          := "PawsCo Membership\nStart buying food in bulk\n$%s"
const BTN_AI_ENTERPRISE   := "AI Enterprise Membership\nReduce token price\n$%s"
const BTN_ROBO_SWEEPER    := "Buy Robo-Shit Sweeper ($%s)"

## Bubbles
const BUBBLE_VIRAL        := "💰"
const BUBBLE_INSPIRATION  := "💡"

## Poop
const POOP_EMOJI          := "💩"

## Robo-Shit Sweeper
const SWEEPER_EMOJI: String = "🤖"

## Developer debug menu
const DEBUG_MENU_TITLE: String = "Debug Menu"
const DEBUG_POOP_OFF_LABEL: String = "Poop Off"

## Research items — name / subtitle / description keyed by item id
const RESEARCH_CAT_POWER_NAME    := "Cat Power Unite"
const RESEARCH_CAT_POWER_SUB     := "Cat Intelligence +1"
const RESEARCH_CAT_POWER_DESC    := "This will make your cats smart enough to research upgrades for you, but they're not exactly tiny geniuses right now. So, it's going to take a LOT of cats to kick it off."

const RESEARCH_AI_MODEL_NAME     := "Research AI model Upgrade"
const RESEARCH_AI_MODEL_SUB      := ""
const RESEARCH_AI_MODEL_DESC     := "This will unlock better Manager-Bots"

const RESEARCH_ROBO_SWEEPER_NAME: String = "Robo-Shit Sweeper"
const RESEARCH_ROBO_SWEEPER_SUB: String = "Automated waste removal"
const RESEARCH_ROBO_SWEEPER_DESC: String = "A robot that handles the dirty work so your cats don't have to."

const RESEARCH_CYBORG_NAME: String = "Cyborg Cats"
const RESEARCH_CYBORG_SUB: String = "Biologically enhanced earners"
const RESEARCH_CYBORG_DESC: String = "Splice some circuitry into your cuddliest moneymakers. Cyborg cats earn a multiplier on the full per-cat income rate and never poop — but it costs a whole cat plus a pretty penny to build each one."

## Research item id -> display name, for the active-research label lookup
const RESEARCH_NAMES: Dictionary = {
	"cat_power_unite":  RESEARCH_CAT_POWER_NAME,
	"ai_model_upgrade": RESEARCH_AI_MODEL_NAME,
	"robo_shit_sweeper": RESEARCH_ROBO_SWEEPER_NAME,
	"cyborg_cats": RESEARCH_CYBORG_NAME,
}

## Popup text — one const per popup, exact text preserved from Main.tscn
const POPUP_ONLY_PAWS := "NEW ACHIEVEMENT: Work It Gurl\n\nThose cats sure are cute, but at this point they gotta earn their keep somehow.\n\nREWARD: Unlocked OnlyPaws\n\nPut those little toe beans to work on OnlyPaws. Earn some 'passive' income."

const POPUP_FIRST_CAT := "NEW ACHIEVEMENT: Cat\n\nYou purchased your first cat. They are cute and cuddly. Enjoy.\nYou definitely won't want more.\n\nREWARD: Responsibilities!\n\nYou gotta keep that cute little guy happily fed!"

const POPUP_CRAMPED := "Your cute furry friends are starting to get a little cramped. Better figure out your space issues if you want them to keep making you money!"

const POPUP_RIOT := "The kitties are rioting! They cannot work under these conditions AND DEMAND more space."

const POPUP_BOT_UNLOCK := "NEW ACHIEVEMENT: Cat Harem\n\nYou're growing quite the little posse of pusses. So many that it's gotta be difficult to manage all those glamour shots on your own.\n\nREWARD: OnlyPaws Manager-Bots Unlocked\n\nHire some AI bots to help you out and boost your income. Just don't forget — bots get hungry too. Gotta feed them those tokens!"

const POPUP_BOT_MANAGER_UNLOCK := "New upgrade available: Manager-Bot Manager."

const POPUP_UPGRADES_TAB := "NEW ACHIEVEMENT! ADHD Cat Parent\n\nYou're just going about your day, hyperfocused on whatever hobby you chose this week. When BAM — you remembered you forgot to buy that important thing needed to keep you alive!\n\nREWARD: Upgrades\nYou can now purchase upgrades to enable your lazine...I mean automate the tedious things in life. Go check out the Upgrades tab for more information!"

const POPUP_CAT_CRUSHER := "NEW ACHIEVEMENT: Cat Crusher!\nYou managed to squeeze more cats into a space than was originally considered possible by all laws of physics. I guess cats really are liquid.\nREWARD: Your cats are now smart enough to devise escape plans. When happiness is low, they'll start looking for other hoarders to rule over...I mean love."

const POPUP_STARVATION_1 := "NEW ACHIEVEMENT: Fasting Never Hurt Anyone\n\nI'm gonna level with you. This looks bad. Food is the cheapest resource. It's one button click. It's faster than A-Meow-zon delivery. BE BETTER.\n\nREWARD: Pity Food\n\nYour cats are cute, so I'm gonna help you out here. ONCE...Only once. I'm serious. After that, well, just know they gotta eat something."

const POPUP_STARVATION_2 := "NEW ACHIEVEMENT: Third-World Dictator\n\nOh, so you just want all these beautiful, loving creatures to work for free. Well, they gotta eat something.\n\nREWARD: You'll figure it out\n\nYou are going to see some food appear in your inventory, but you will lose a cat. Don't worry about that, totally nothing bad happened to it."

const POPUP_STARVATION_RECURRING := "You know the drill"

const POPUP_STARVATION_ASSHOLE := "Asshole"

const POPUP_GAME_OVER_1 := "NEW ACHIEVEMENT: Literally Hitler\n\nYou really aren't supposed to be at this point. That means you purposefully got yourself here. You purposefully let those poor little innocent kitties suffer. TIME AND TIME AGAIN. And let's be honest. You enjoyed it. You sick bastard.\n\nREWARD: Nothing\n\nYou don't get shit for being a terrible cat parent. In fact, you know what. Game over."

const POPUP_GAME_OVER_2 := "Fuck you"

const POPUP_INSPIRATION := "[PLACEHOLDER — edit this string in Strings.gd]"

const POPUP_VIRAL := "NEW ACHIEVEMENT: Whale Hunting Baby!\n\nOne of your furry little charaltan's has caught the eye of a particularly \"giving\" patron. Snatch that money before they change their mind!\n\nREWARD: Dirty Filthy Disgusting Money\nEver so often one of your cats will go viral. When they do, a bubble will pop up over their head. Click the bubble before it goes away to get a small burst of money."

const POPUP_AI_OVERLORDS := "NEW ACHIEVEMENT: AI Overlords\n\nLooks like your cute little guy figured out how to upgrade your manager bots to a better model. This totally won't have any negative consequences later down the line.\n\nREWARD: Mega Manager-Bots\n\nJon Meowremy rejoices as your cats usher a new age of truly heinous manager practices to the forefront of capitalism. These mega-bots provide double the benefits of the puny little normal bots, but also at double the price."

const POPUP_CYBORG := "NEW ACHIEVEMENT: Resistance Is Fur-tile\n\nYour lab cats cracked the secret to bolting hardware onto a housecat without voiding the warranty. Science!\n\nREWARD: Cyborg Cats\n\nConvert a normal cat into a cyborg cat. Cyborgs cost one whole cat plus an escalating pile of money, but they multiply the full per-cat income rate and never, ever poop. Upgrade the multiplier in tiers to keep scaling."
