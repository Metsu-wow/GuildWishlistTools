if not ((GAME_LOCALE or GetLocale()) == "enUS") then
    return
end

local addonName, BGW = ...
local L = BGW.L
L = L or {}

-- Constants
L["Head"] = "Head"
L["Neck"] = "Neck"
L["Shoulders"] = "Shoulders"
L["Cloak"] = "Cloak"
L["Chest"] = "Chest"
L["Wrists"] = "Wrists"
L["Hands"] = "Hands"
L["Waist"] = "Waist"
L["Legs"] = "Legs"
L["Feet"] = "Feet"
L["Finger"] = "Finger"
L["Trinket"] = "Trinket"
L["MainHand"] = "Main hand"
L["OffHand"] = "Off hand"

-- Menu
L["Gear"] = "Gear"
L["Wishlist"] = "Wishlist"
L["Todo"] = "TODO"
L["GuildLists"] = "Guild Wishlists"
L["LootHistory"] = "Loots History"
L["ImportExport"] = "Import / Export"

-- Content
L["Import"] = "Import"
L["ImportWishlist"] = "Import wishlist"
L["Export"] = "Export"
L["ImportExportWishlist"] = "Import / Export wishlist"
L["ImportExportGuildWishlists"] = "Import / Export guild wishlists"
L["Sync"] = "Synchronization"
L["ShareWishlist"] = "Share wishlist"
L["SyncGuild"] = "Sync guild wishlists"

L["Needs"] = "needs"
L["SelectAll"] = "Select All"