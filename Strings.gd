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

## HUD — research panel state
const RESEARCH_NO_ACTIVE  := "No Active Research"
const RESEARCH_IN_PROGRESS := "In Progress…"
const RESEARCH_NEEDS_CATS := "Needs %s+ cats assigned to begin"

## Buttons — static labels set once in _ready()
const BTN_OK              := "OK"
const BTN_EARN_MONEY      := "Work at McPawnalds"
const BTN_ONLY_PAWS       := "Sell pics on OnlyPaws"
const BTN_ONLY_PAWS_ON    := "OnlyPaws: ON"
const BTN_ONLY_PAWS_OFF   := "OnlyPaws: OFF"

## Housing tier labels — referenced by Config.housing_tiers and displayed in Main.gd
const BTN_HOUSING_UPGRADE            := "%s\n$%s"
const HOUSING_LABEL_STUDIO_BASIC     := "Basic Studio"
const HOUSING_LABEL_STUDIO_UPGRADED  := "Luxury Cat Trees"
const HOUSING_LABEL_BEDROOM_1        := "1 Bedroom"
const HOUSING_LABEL_BEDROOM_2        := "2 Bedroom"
const HOUSING_LABEL_BEDROOM_3        := "3 Bedroom"

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
const DEBUG_GRANT_10K: String = "Grant $10,000"
const DEBUG_GRANT_100K: String = "Grant $100,000"
const DEBUG_GRANT_1M: String = "Grant $1,000,000"
const DEBUG_AUTOCOMPLETE_RESEARCH: String = "Autocomplete Research"

## Research panel title separator — used between name and subtitle in the research list
const RESEARCH_NAME_SUBTITLE_SEP: String = " — "

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
const RESEARCH_CYBORG_SUB: String = "All cats ×2 income multiplier"
const RESEARCH_CYBORG_DESC: String = "Research cybernetic enhancements for your cats. When complete, ALL cats immediately earn a 2× multiplier on their full income rate — bots and mega-bots included."

const RESEARCH_CYBORG_L2_NAME: String = "Cyborg Enhancement: Level 2"
const RESEARCH_CYBORG_L2_SUB: String = "All cats ×4 income multiplier"
const RESEARCH_CYBORG_L2_DESC: String = "Push the hardware further. When this research completes, the global cat income multiplier advances to 4× — doubling all income again."

const RESEARCH_CYBORG_L3_NAME: String = "Cyborg Enhancement: Level 3"
const RESEARCH_CYBORG_L3_SUB: String = "All cats ×8 income multiplier"
const RESEARCH_CYBORG_L3_DESC: String = "The next augmentation. When this research completes, the global cat income multiplier advances to 8× — doubling all income again."

const RESEARCH_CYBORG_L4_NAME: String = "Cyborg Enhancement: Level 4"
const RESEARCH_CYBORG_L4_SUB: String = "All cats ×16 income multiplier"
const RESEARCH_CYBORG_L4_DESC: String = "Maximum augmentation. When this research completes, the global cat income multiplier reaches 16× — the ultimate income scaling lever."

const RESEARCH_BREEDER_CONTRACT_NAME: String = "Cat Breeder Contract"
const RESEARCH_BREEDER_CONTRACT_SUB: String  = "Cat cost growth rate −10%"
const RESEARCH_BREEDER_CONTRACT_DESC: String = "You've signed a deal with a reputable cat breeder. Retroactively applies a 10% discount to the cat purchase cost multiplier. They didn't ask questions. Neither should you."

const RESEARCH_POOP_RECYCLER_NAME: String = "Cybernetic Poop Recyclers"
const RESEARCH_POOP_RECYCLER_SUB: String  = "Cats poop 50% less"
const RESEARCH_POOP_RECYCLER_DESC: String = "Your cyborg cats now have internal waste recycling units installed. Efficiency went up. The smell also went up. But frequency? Way down."

const RESEARCH_BURST_BRILLIANCE_NAME: String = "Burst of Brilliance"
const RESEARCH_BURST_BRILLIANCE_SUB: String  = "Cat Intelligence +5"
const RESEARCH_BURST_BRILLIANCE_DESC: String = "A sudden and unexplained surge of feline intellectual capacity. Nobody saw it coming. Least of all the cats."

const RESEARCH_BREEDERS_CONTRACT_NAME: String = "Cat Breeders Contract"
const RESEARCH_BREEDERS_CONTRACT_SUB: String  = "Cat cost growth rate −20%"
const RESEARCH_BREEDERS_CONTRACT_DESC: String = "You have a problem. You know this. The breeders know this. They didn't offer the discount out of kindness — they offered it because you are their most reliable customer and that is not something to be proud of. Retroactively reduces the cat cost multiplier by 20%."

const RESEARCH_ENRICHMENT_NAME: String = "Cat Enrichment Program"
const RESEARCH_ENRICHMENT_SUB: String  = "Unlocks Cat Toy Store"
const RESEARCH_ENRICHMENT_DESC: String = "Your cats are wealthy, intelligent, and increasingly bored. Science demands you address this. Open a store for the finer things in life."

const RESEARCH_FURTHER_CAT_RACE_NAME: String = "Further the Cat Race"
const RESEARCH_FURTHER_CAT_RACE_SUB: String  = "Cat Intelligence +10"
const RESEARCH_FURTHER_CAT_RACE_DESC: String = "Your cats are approaching something. Nobody is entirely comfortable with what it is. The research continues anyway."

const RESEARCH_DOG_DEFENCE_NAME: String = "Dog Defence"
const RESEARCH_DOG_DEFENCE_SUB: String  = "Cat Intelligence +2"
const RESEARCH_DOG_DEFENCE_DESC: String = "Look, you've never actually seen a dog around here. But your cats are absolutely losing it. Might be a consequence of increased intelligence. Whose to say. The research is underway."

const RESEARCH_OWN_LLMS_NAME: String = "Research Your Own LLMs"
const RESEARCH_OWN_LLMS_SUB: String  = "Token cost reduced to $10"
const RESEARCH_OWN_LLMS_DESC: String = "Your cats have achieved something. An internal token infrastructure. Running on vibes and raw intelligence. Somehow cheaper than the market rate. Something is about to go wrong."

## Housing tier labels — new tiers appended after existing bedroom_3
const HOUSING_LABEL_HOUSE: String          = "Purchase a House"
const HOUSING_LABEL_HOUSE_FLOOR_2: String  = "Build a Second Floor"
const HOUSING_LABEL_HOUSE_FLOOR_3: String  = "Fuck Regulation, Third Floor"
const HOUSING_LABEL_NEIGHBOR_HOUSE: String = "Purchase Your Neighbor's House"
const HOUSING_LABEL_WHOLE_BLOCK: String    = "Purchase the Whole Goddamn Block"
const HOUSING_LABEL_WAREHOUSE: String      = "Purchase a Warehouse"

## Enrichment store UI
const ENRICHMENT_STORE_BTN: String = "Cat Enrichment Store"
const ENRICHMENT_STORE_TITLE: String = "Cat Enrichment Store"
const ENRICHMENT_STORE_SUBTITLE: String = "These are very expensive. That's the point."
const ENRICHMENT_STORE_OWNED: String = "\n[Owned]"
const ENRICHMENT_STORE_CLOSE: String = "Close"
const ENRICHMENT_ITEM_COST_FMT: String = " ($%s)"

## Enrichment store items
const ENRICHMENT_DIAMOND_LITTER: String = "Diamond-Encrusted Litter Box\nSelf-cleaning optional. Dignity: mandatory."
const ENRICHMENT_SILK_BED: String       = "Silk Cat Bed\nThread count: unnecessary. Price: inexcusable."
const ENRICHMENT_CHANDELIER: String     = "Custom Cat Chandelier\nFor the cat who has achieved ceiling ambitions."
const ENRICHMENT_MASSEUSE: String       = "Personal Cat Masseuse\nFull-time. Degree in Feline Myotherapy."
const ENRICHMENT_YACHT: String          = "Cat Yacht\nThey don't know what a yacht is. That's not the point."

## Dog Attack
const BATTLE_CAT_EMOJI: String = "🐱"
const BATTLE_DOG_EMOJI: String = "🐕"
const POPUP_DOG_ATTACK_UNLOCK_TITLE: String = "NEW ACHIEVEMENT: Self-Fulfilling Prophecy"
const POPUP_DOG_ATTACK_UNLOCK_BODY: String = "The dogs, generally speaking, are pretty chill. However, they noticed that your cats are planning something. They don't like that. In fact, they fucking hate that.\n\nREWARD: WAR BABYYYYYYY\n\nThe dogs are a-comin, better watch out."
const HUD_PRIDE: String = "Pride: %s"
const DOG_ATTACK_WARNING_LABEL: String = "⚠ Dogs incoming!"
const DOG_ATTACK_RESULT_WIN: String = "Victory! +%s Pride"
const DOG_ATTACK_RESULT_LOSE: String = "Defeated! -%s Pride"

## Research item id -> display name, for the active-research label lookup
const RESEARCH_NAMES: Dictionary = {
	"cat_power_unite":          RESEARCH_CAT_POWER_NAME,
	"ai_model_upgrade":         RESEARCH_AI_MODEL_NAME,
	"robo_shit_sweeper":        RESEARCH_ROBO_SWEEPER_NAME,
	"cyborg_cats":              RESEARCH_CYBORG_NAME,
	"cyborg_level_2":           RESEARCH_CYBORG_L2_NAME,
	"cyborg_level_3":           RESEARCH_CYBORG_L3_NAME,
	"cyborg_level_4":           RESEARCH_CYBORG_L4_NAME,
	"cat_breeder_contract":     RESEARCH_BREEDER_CONTRACT_NAME,
	"cybernetic_poop_recyclers": RESEARCH_POOP_RECYCLER_NAME,
	"burst_of_brilliance":      RESEARCH_BURST_BRILLIANCE_NAME,
	"cat_breeders_contract":    RESEARCH_BREEDERS_CONTRACT_NAME,
	"cat_enrichment_program":   RESEARCH_ENRICHMENT_NAME,
	"further_the_cat_race":     RESEARCH_FURTHER_CAT_RACE_NAME,
	"dog_defence":              RESEARCH_DOG_DEFENCE_NAME,
	"research_your_own_llms":   RESEARCH_OWN_LLMS_NAME,
}

## Popup text — one const per popup, exact text preserved from Main.tscn
const POPUP_ONLY_PAWS := "NEW ACHIEVEMENT: Work It Gurl\n\nThose cats sure are cute, but at this point they gotta earn their keep somehow.\n\nREWARD: Unlocked OnlyPaws\n\nPut those little toe beans to work on OnlyPaws. Earn some 'passive' income."

const POPUP_FIRST_CAT := "NEW ACHIEVEMENT: Cat\n\nYou purchased your first cat. They are cute and cuddly. Enjoy.\nYou definitely won't want more.\n\nREWARD: Responsibilities!\n\nYou gotta keep that cute little guy happily fed!"

const POPUP_CRAMPED := "NEW ACHIEVEMENT: Sardine Can Chic\n\nYour cats have begun taking shifts sleeping because there is not enough floor for all of them to lie down simultaneously. Several are standing. Cats despise standing. This is not sustainable.\n\nREWARD: Home Tab Unlocked\n\nThe Home tab is now available. Expand your living situation before the cats start holding committee meetings about it."

const POPUP_RIOT := "NEW ACHIEVEMENT: Zero Stars on Yelp\n\nHappiness: 0%. A complete and total absence of cat satisfaction. They are not rioting ironically. They have printed pamphlets. Their demand is singular: more space.\n\nREWARD: A Chance to Fix This\n\nExpand your housing before they handle it themselves. They have already selected a spokesperson."

const POPUP_BOT_UNLOCK := "NEW ACHIEVEMENT: Cat Harem\n\nYou're growing quite the little posse of pusses. So many that it's gotta be difficult to manage all those glamour shots on your own.\n\nREWARD: OnlyPaws Manager-Bots Unlocked\n\nHire some AI bots to help you out and boost your income. Just don't forget — bots get hungry too. Gotta feed them those tokens!"

const POPUP_BOT_MANAGER_UNLOCK := "NEW ACHIEVEMENT: Management Has Management Now\n\nYour Manager-Bots have multiplied to the point where someone needs to manage the managers. This is how all great empires collapse. Nobody asked the cats.\n\nREWARD: Manager-Bot Manager\n\nPurchase the Manager-Bot Manager from the Upgrades tab. It keeps your bots in line so you can focus on watching the numbers go up."

const POPUP_UPGRADES_TAB := "NEW ACHIEVEMENT! ADHD Cat Parent\n\nYou're just going about your day, hyperfocused on whatever hobby you chose this week. When BAM — you remembered you forgot to buy that important thing needed to keep you alive!\n\nREWARD: Upgrades\nYou can now purchase upgrades to enable your lazine...I mean automate the tedious things in life. Go check out the Upgrades tab for more information!"

const POPUP_STARVATION_1 := "NEW ACHIEVEMENT: Fasting Never Hurt Anyone\n\nI'm gonna level with you. This looks bad. Food is the cheapest resource. It's one button click. It's faster than A-Meow-zon delivery. BE BETTER.\n\nREWARD: Pity Food\n\nYour cats are cute, so I'm gonna help you out here. ONCE...Only once. I'm serious. After that, well, just know they gotta eat something."

const POPUP_STARVATION_2 := "NEW ACHIEVEMENT: Third-World Dictator\n\nOh, so you just want all these beautiful, loving creatures to work for free. Well, they gotta eat something.\n\nREWARD: You'll figure it out\n\nYou are going to see some food appear in your inventory, but you will lose a cat. Don't worry about that, totally nothing bad happened to it."

const POPUP_STARVATION_RECURRING := "NEW ACHIEVEMENT: Recidivist\n\nYep, this achievement is awarding itself again. The food button still hasn't moved. You have now been here at least three times.\n\nREWARD: You Know Already\n\nA cat is about to leave. Again. Feed them. The button is right there."

const POPUP_STARVATION_ASSHOLE := "NEW ACHIEVEMENT: Perfect Consistency\n\nYou clicked through every warning on the way here. The cats noticed.\n\nREWARD: The Consequences\n\nOne cat is not making it through this. Feed the rest. Your intentions are well established."

const POPUP_GAME_OVER_1 := "NEW ACHIEVEMENT: Literally Hitler\n\nYou really aren't supposed to be at this point. That means you purposefully got yourself here. You purposefully let those poor little innocent kitties suffer. TIME AND TIME AGAIN. And let's be honest. You enjoyed it. You sick bastard.\n\nREWARD: Nothing\n\nYou don't get shit for being a terrible cat parent. In fact, you know what. Game over."

const POPUP_GAME_OVER_2 := "NEW ACHIEVEMENT: The End\n\nMultiple warnings. Multiple dead cats. Multiple popups. You clicked through all of them. Genuinely impressive in its own way.\n\nREWARD: Nothing\n\nThe game is closing now. You earned this."

const POPUP_INSPIRATION := "NEW ACHIEVEMENT: Scientific Method (Probably)\n\nOne of your cats has been staring at the ceiling fan for three hours and has apparently cracked something wide open. Nobody knows what. The cat is not sharing.\n\nREWARD: Inspiration Bubbles\n\nWhen a 💡 bubble appears over a cat, click it before it disappears for a burst of research points. Your first one already paid out. There will be more."

const POPUP_VIRAL := "NEW ACHIEVEMENT: Whale Hunting Baby!\n\nOne of your furry little charaltan's has caught the eye of a particularly \"giving\" patron. Snatch that money before they change their mind!\n\nREWARD: Dirty Filthy Disgusting Money\nEver so often one of your cats will go viral. When they do, a bubble will pop up over their head. Click the bubble before it goes away to get a small burst of money."

const POPUP_AI_OVERLORDS := "NEW ACHIEVEMENT: AI Overlords\n\nLooks like your cute little guy figured out how to upgrade your manager bots to a better model. This totally won't have any negative consequences later down the line.\n\nREWARD: Mega Manager-Bots\n\nJon Meowremy rejoices as your cats usher a new age of truly heinous manager practices to the forefront of capitalism. These mega-bots provide double the benefits of the puny little normal bots, but also at double the price."

const POPUP_CYBORG := "NEW ACHIEVEMENT: Resistance Is Fur-tile\n\nYour lab cats cracked the secret to cybernetic enhancement without voiding the warranty. Science!\n\nREWARD: Cyborg Research Tier 1\n\nAll cats now earn a 2× multiplier on their full income rate — bots and mega-bots included. Research Cyborg Enhancement tiers 2, 3, and 4 to advance the multiplier to 4×, 8×, and 16×."
