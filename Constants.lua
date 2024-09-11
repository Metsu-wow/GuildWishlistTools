local AddonName, GWT = ...
local L = GWT.L
local CONSTANTS = GWT.CONSTANTS

--constantes existantes https://wowpedia.fandom.com/wiki/InventorySlotId

CONSTANTS.characterSlotIds = {
	1,	--INVSLOT_HEAD
	2,	--INVSLOT_NECK
	3,	--INVSLOT_SHOULDER
	15,	--INVSLOT_BACK
	5,	--INVSLOT_CHEST
	9,	--INVSLOT_WRIST
	10,	--INVSLOT_HAND
	6,	--INVSLOT_WAIST
	7,	--INVSLOT_LEGS
	8,	--INVSLOT_FEET
	11,	--INVSLOT_FINGER1
	12,	--INVSLOT_FINGER2
	13,	--INVSLOT_TRINKET1
	14,	--INVSLOT_TRINKET2
	16,	--INVSLOT_MAINHAND
	17,	--INVSLOT_OFFHAND
}

CONSTANTS.characterSlotLabels = {
	L["Head"],	--INVSLOT_HEAD
	L["Neck"],	--INVSLOT_NECK
	L["Shoulders"],	--INVSLOT_SHOULDER
	L["Cloak"],	--INVSLOT_BACK
	L["Chest"],	--INVSLOT_CHEST
	L["Wrists"],	--INVSLOT_WRIST
	L["Hands"],	--INVSLOT_HAND
	L["Waist"],	--INVSLOT_WAIST
	L["Legs"],	--INVSLOT_LEGS
	L["Feet"],	--INVSLOT_FEET
	L["Finger"].." 1",	--INVSLOT_FINGER1
	L["Finger"].." 2",	--INVSLOT_FINGER2
	L["Trinket"].." 1",	--INVSLOT_TRINKET1
	L["Trinket"].." 2",	--INVSLOT_TRINKET2
	L["MainHand"],	--INVSLOT_MAINHAND
	L["OffHand"],	--INVSLOT_OFFHAND
}

CONSTANTS.characterSlotFilterIds = {
	0,	--INVSLOT_HEAD
	1,	--INVSLOT_NECK
	2,	--INVSLOT_SHOULDER
	3,	--INVSLOT_BACK
	4,	--INVSLOT_CHEST
	5,	--INVSLOT_WRIST
	6,	--INVSLOT_HAND
	7,	--INVSLOT_WAIST
	8,	--INVSLOT_LEGS
	9,	--INVSLOT_FEET
	12,	--INVSLOT_FINGER1
	12,	--INVSLOT_FINGER2
	13,	--INVSLOT_TRINKET1
	13,	--INVSLOT_TRINKET2
	10,	--INVSLOT_MAINHAND
	11,	--INVSLOT_OFFHAND
}

CONSTANTS.slotFilterIds = {
    0, --Head
    1, --Neck
    2, --Shoulder
    3, --Cloak
    4, --Chest
    5, --Wrist
    6, --Hand
    7, --Waist
    8, --Legs
    9, --Feet
    10, --MainHand
    11, --OffHand
    12, --Finger
    13, --Trinket
    14, --Other
    15, --NoFilter
}

CONSTANTS.slotLabels = {
    "Head",
    "Neck",
    "Shoulder",
    "Cloak",
    "Chest",
    "Wrist",
    "Hand",
    "Waist",
    "Legs",
    "Feet",
    "MainHand",
    "OffHand",
    "Finger",
    "Trinket",
    "Other"
}

CONSTANTS.classColors = {
    ["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45},
    ["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43},
    ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
    ["MAGE"] = {r = 0.25, g = 0.78, b = 0.92},
    ["PRIEST"] = {r = 1.00, g = 1.00, b = 1.00},
    ["SHAMAN"] = {r = 0.00, g = 0.44, b = 0.87},
    ["WARLOCK"] = {r = 0.53, g = 0.53, b = 0.93},
    ["DEMONHUNTER"] = {r = 0.64, g = 0.19, b = 0.79},
    ["DEATHKNIGHT"] = {r = 0.77, g = 0.12, b = 0.23},
    ["DRUID"] = {r = 1.00, g = 0.49, b = 0.04},
    ["MONK"] = {r = 0.00, g = 1.00, b = 0.60},
    ["ROGUE"] = {r = 1.00, g = 0.96, b = 0.41},
    ["EVOKER"] = {r = 0.20, g = 0.58, b = 0.50},
}