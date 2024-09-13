if not ((GAME_LOCALE or GetLocale()) == "frFR") then
    return
end

local addonName, BGW = ...
local L = BGW.L
L = L or {}

-- Constants
L["Head"] = "Tête"
L["Neck"] = "Cou"
L["Shoulders"] = "Epaules"
L["Cloak"] = "Dos"
L["Chest"] = "Torse"
L["Wrists"] = "Poignets"
L["Hands"] = "Mains"
L["Waist"] = "Taille"
L["Legs"] = "Jambes"
L["Feet"] = "Pieds"
L["Finger"] = "Doigt"
L["Trinket"] = "Bijou"
L["MainHand"] = "Main principale"
L["OffHand"] = "Main secondaire"

-- Menu
L["Gear"] = "Mon Equipement"
L["Wishlist"] = "Ma Liste"
L["Todo"] = "TODO"
L["GuildLists"] = "Listes de la Guilde"
L["LootHistory"] = "Historique des Loots"
L["ImportExport"] = "Import / Export"

-- Content
L["Empty"] = "Vider"
L["Import"] = "Importer"
L["ImportWishlist"] = "Importer une liste"
L["Export"] = "Exporter"
L["ImportExportWishlist"] = "Import / Export une liste"
L["ImportExportGuildWishlists"] = "Import / Export les listes de la guilde"
L["Sync"] = "Synchronisation"
L["ShareWishlist"] = "Partage ma liste"
L["SyncGuild"] = "Synchronisation GUILDE"

L["Needs"] = "a besoin de"
L["SelectAll"] = "Selectionner tout"