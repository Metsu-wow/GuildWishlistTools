local AddonName, GWT = ...
local L = GWT.L
local CONSTANTS = GWT.CONSTANTS
local CURRENT_SEASON = GWT.CURRENT_SEASON
local db

GWT = LibStub("AceAddon-3.0"):NewAddon("GuildWishlistTools", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")

local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("GuildWishlistTools", {  
	type = "data source",  
	text = "GuildWishlistTools",  
	icon = "Interface\\AddOns\\"..AddonName.."\\Textures\\MinimapIcon",
	OnClick = function() GWT:ShowInterface() end,
})  
local icon = LibStub("LibDBIcon-1.0")  

local WoW11 = select(4, GetBuildInfo()) >= 110000
local AceGUI = LibStub("AceGUI-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

local defaults = {
  global = {
    characters = {},
    guilds = {},
    lootHistory = {},
  },
	char = {
    character = {
      guid = 0,
      battleTag = "",
      classID = 0,
      currentSpecializationID = 0,
      lastUpdate = 0,
      gear = {},
      wishlist = {},
    },
		options = {},
  },
  profile = {
    minimap = {
      hide = false,
    }
  },
}

--[[local amidrassilEncounterIds = {
  2564, --Gnarlroot
  2554, --Igira the Cruel
  2557, --Volcoross
  2555, --Council of Dreams
  2553, --Larodar, Keeper of the Flame
  2556, --Nymue, Weaver of the Cycle
  2563, --Smolderon
  2565, --Tindral Sageswift, Seer of the Flame
  2519, --Fyrakk the Blazing
}]]--

local slotsDropdown = {}

local guildName, classID, currentSpecializationID
local raidItemsBySlot, dungeonItemsBySlot, seasonItems = {}

-- function that draws the widgets for the gear tab
local function DrawGroupGear(container)
  local desc = AceGUI:Create("Label")
  desc:SetText(L["Gear"])
  desc:SetFullWidth(true)
  container:AddChild(desc)

  for i=1,#CONSTANTS.characterSlotIds do
    local itemLink  = GetInventoryItemLink("player", CONSTANTS.characterSlotIds[i])
    local itemButton = AceGUI:Create("GWTItemButton")

    if itemLink then
      local item = Item:CreateFromItemLink(itemLink)

      item:ContinueOnItemLoad(function()
        GWT.db.char.character.gear[currentSpecializationID][i] = {
          itemID = item:GetItemID(),
          itemLink = itemLink,
          obtentionMethod = nil,
          isSetItem = nil,
          instanceID = nil,
          enconterID = nil,
        }
      end)

      itemButton:SetItem(itemLink)
      itemButton:Initialize()
      itemButton:Enable()
      container:AddChild(itemButton)
    end
  end
end

-- function that draws the label + dropdown for a slot
local function DrawDropdownForSlot(container, slot)
  local desc = AceGUI:Create("Label")
  desc:SetText(CONSTANTS.characterSlotLabels[slot])
  desc:SetFullWidth(true)
  container:AddChild(desc)

  local dropdown = AceGUI:Create("Dropdown")

  dropdown:SetWidth(500)

  local items = {}

  if CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]] then
    dropdown:AddItem(CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]].itemID, CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]].display)
  end

  for i=1,#CURRENT_SEASON.raidInstanceIds do
    for j = 1, #raidItemsBySlot[slot][CURRENT_SEASON.raidInstanceIds[i]] do
      dropdown:AddItem(raidItemsBySlot[slot][CURRENT_SEASON.raidInstanceIds[i]][j].itemID, raidItemsBySlot[slot][CURRENT_SEASON.raidInstanceIds[i]][j].display)
    end
  end

  for i=1,#CURRENT_SEASON.dungeonInstanceIds do
    for j = 1, #dungeonItemsBySlot[slot][CURRENT_SEASON.dungeonInstanceIds[i]] do
      dropdown:AddItem(dungeonItemsBySlot[slot][CURRENT_SEASON.dungeonInstanceIds[i]][j].itemID, dungeonItemsBySlot[slot][CURRENT_SEASON.dungeonInstanceIds[i]][j].display)
    end
  end

  for itemID, item in ipairs(dropdown.pullout.items) do
    item:SetOnEnter(function()
      GameTooltip:SetOwner(item.frame, "ANCHOR_BOTTOMLEFT", 0, item.frame:GetHeight())

      if item.userdata.value then
        local itemInfo = seasonItems[item.userdata.value]
        GameTooltip:SetHyperlink(itemInfo.link)
        GameTooltip:Show()
      end
    end)
    item:SetOnLeave(function()
      GameTooltip:Hide()
    end)
  end


  local itemID

  if GWT.db.char.character.wishlist[currentSpecializationID][slot] then
    itemID = GWT.db.char.character.wishlist[currentSpecializationID][slot].itemID
  else
    itemID = 0
  end

  dropdown:SetValue(itemID)

  dropdown:SetCallback("OnValueChanged", function(widget, event, key)
    local guid = UnitGUID("player")
    GWT.db.char.character.guid = guid
    GWT.db.char.character.battleTag = C_BattleNet.GetAccountInfoByID(select(3, BNGetInfo())).battleTag
    GWT.db.char.character.classID = classID
    GWT.db.char.character.currentSpecializationID = currentSpecializationID
    local item = seasonItems[key]
    if item then
      GWT.db.char.character.wishlist[currentSpecializationID][slot] = {
        itemID = key,
        itemLink = item.link,
        obtentionMethod = nil,
        isSetItem = nil,
        instanceID = nil,
        enconterID = nil,
      }
    end

    --handle the main hand slot case for two hands
    if slot == 15 then
      local classID, subclassID = select(12, GetItemInfo(key))

      if classID == Enum.ItemClass.Weapon and (subclassID == Enum.ItemWeaponSubclass.Axe2H or 
      subclassID == Enum.ItemWeaponSubclass.Mace2H or subclassID == Enum.ItemWeaponSubclass.Polearm or
      subclassID == Enum.ItemWeaponSubclass.Sword2H or subclassID == Enum.ItemWeaponSubclass.Staff) and 
      currentSpecializationID ~= 72 then
        slotsDropdown[16]:SetValue(nil)
        slotsDropdown[16]:SetDisabled(true)
        GWT.db.char.character.wishlist[currentSpecializationID][16] = {
          itemID = 0,
          itemLink = nil,
          obtentionMethod = nil,
          isSetItem = nil,
          instanceID = nil,
          enconterID = nil,
        }
      else
        slotsDropdown[16]:SetDisabled(false)
      end
    end

    GWT.db.char.character.lastUpdate = time()
    GWT.db.global.characters[guid] = GWT.db.char.character
    GWT.db.global.guilds[guildName][guid] = GWT.db.char.character
  end)

  --handle the off hand slot case for two hands
  if slot == 16 then
    local mainHandID = slotsDropdown[15]:GetValue()

    if mainHandID then
      local classID, subclassID = select(12, GetItemInfo(mainHandID))

      if classID == Enum.ItemClass.Weapon and (subclassID == Enum.ItemWeaponSubclass.Axe2H or 
        subclassID == Enum.ItemWeaponSubclass.Mace2H or subclassID == Enum.ItemWeaponSubclass.Polearm or
        subclassID == Enum.ItemWeaponSubclass.Sword2H or subclassID == Enum.ItemWeaponSubclass.Staff) and 
        currentSpecializationID ~= 72 then
          dropdown:SetDisabled(true)
      end
    end
  end

  slotsDropdown[slot] = dropdown

  container:AddChild(dropdown)

  local clear = AceGUI:Create("Icon")

  clear:SetImageSize(32, 32)
  clear:SetImage("Interface\\Icons\\INV_MISC_QUESTIONMARK")

  clear:SetCallback("OnClick", function(widget)
    local guid = UnitGUID("player")
    dropdown:SetValue(true)
    if GWT.db.char.character.wishlist[currentSpecializationID] and GWT.db.char.character.wishlist[currentSpecializationID][slot] then
      GWT.db.char.character.wishlist[currentSpecializationID][slot] = {
        itemID = 0,
        itemLink = nil,
        obtentionMethod = nil,
        isSetItem = nil,
        instanceID = nil,
        enconterID = nil,
      }
    end
    GWT.db.char.character.lastUpdate = time()
    GWT.db.global.characters[guid] = GWT.db.char.character
    GWT.db.global.guilds[guildName][guid] = GWT.db.char.character
  end)

  container:AddChild(clear)
end

local function ScrollFrameTemplate(container)
  scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  container:AddChild(scrollcontainer)

  scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  scrollcontainer:AddChild(scroll)

  return scroll
end

-- function that draws the widgets for the wishlist tab
local function DrawGroupWishlist(container)
  local scroll = ScrollFrameTemplate(container)

  for i=1,#CONSTANTS.characterSlotFilterIds do
    DrawDropdownForSlot(scroll, i)
  end
end

-- function that draws the widgets for the todo tab
local function DrawGroupTodo(container)
  local scroll = ScrollFrameTemplate(container)

  local inlineGroup = AceGUI:Create("InlineGroup")
  inlineGroup:SetLayout("Flow")
  inlineGroup:SetFullWidth(true)
  inlineGroup:SetTitle(L["ImportExportWishlist"])
  scroll:AddChild(inlineGroup)
end

local function DrawWishlistForGUID(guid, character)
  _, class, _, _, _, name = GetPlayerInfoByGUID(guid)

  if class ~= nil then
    local simpleGroup = AceGUI:Create("SimpleGroup")
    simpleGroup:SetLayout("Flow")
    simpleGroup:SetFullWidth(true)
    scroll:AddChild(simpleGroup)

    local specButton = AceGUI:Create("GWTClassButton")
    specButton:SetItem(character.currentSpecializationID)
    specButton:Initialize()
    specButton:Enable()
    simpleGroup:AddChild(specButton)

    local memberName = AceGUI:Create("Label")
    memberName:SetText(name)
    memberName:SetColor(CONSTANTS.classColors[class].r, CONSTANTS.classColors[class].g, CONSTANTS.classColors[class].b)
    memberName:SetWidth(100)
    simpleGroup:AddChild(memberName)

    for i=1,#CONSTANTS.characterSlotIds do
      local itemLink

      if (character.wishlist[character.currentSpecializationID][i] and character.wishlist[character.currentSpecializationID][i].itemID) then
        itemLink = character.wishlist[character.currentSpecializationID][i].itemLink or select(2,GetItemInfo(character.wishlist[character.currentSpecializationID][i].itemID))
      end

      local itemButton = AceGUI:Create("GWTItemButton")

      if itemLink then
        itemButton:SetItem(itemLink)
      else
        itemButton:SetItem()
      end

      itemButton:Initialize()
      itemButton:Enable()
      itemButton:HideTitle()
      simpleGroup:AddChild(itemButton)
    end
  end
end

-- function that draws the widgets for the guild wishlists tab
local function DrawGroupGuildWishlists(container)
  local scroll = ScrollFrameTemplate(container)

  if guildName ~= nil and GWT.db.global.guilds[guildName] ~= nil then
    -- foreach(iterable, callback(index, value))
    foreach(GWT.db.global.guilds[guildName], DrawWishlistForGUID)
  end
end

local function DrawLootHistory(i, lootHistory)
  local simpleGroup = AceGUI:Create("SimpleGroup")
  simpleGroup:SetLayout("Flow")
  simpleGroup:SetFullWidth(true)
  scroll:AddChild(simpleGroup)

  local itemButton = AceGUI:Create("GWTItemButton")

  if itemLink then
    itemButton:SetItem(lootHistory.itemLink)
    itemButton:Initialize()
    itemButton:Enable()
    container:AddChild(itemButton)
  end
end

-- function that draws the widgets for the loot history tab
local function DrawGroupLootHistory(container)
  local scroll = ScrollFrameTemplate(container)

  foreach(GWT.db.global.lootHistory, DrawLootHistory)
end

-- function that draws the widgets for the import/export tab
local function DrawGroupImportExport(container)
  local scroll = ScrollFrameTemplate(container)

  local inlineGroup = AceGUI:Create("InlineGroup")
  inlineGroup:SetLayout("Flow")
  inlineGroup:SetFullWidth(true)
  inlineGroup:SetTitle(L["ImportExportWishlist"])
  scroll:AddChild(inlineGroup)

  local exportButton = AceGUI:Create("Button")
  exportButton:SetText(L["Export"])
  exportButton:SetWidth(200)
  exportButton:SetCallback("OnClick", function()
    GWT:OpenExportDialog(GWT:SerializeCompress(GWT.db.char.character, true))
    GWT:ShareWishlist()
  end)
  inlineGroup:AddChild(exportButton)

  local importButton = AceGUI:Create("Button")
  importButton:SetText(L["Import"])
  importButton:SetWidth(200)
  importButton:SetCallback("OnClick", function()
    GWT:OpenImportDialog()
  end)
  inlineGroup:AddChild(importButton)

  local inlineGroup = AceGUI:Create("InlineGroup")
  inlineGroup:SetLayout("Flow")
  inlineGroup:SetFullWidth(true)
  inlineGroup:SetTitle(L["ImportExportGuildWishlists"])
  scroll:AddChild(inlineGroup)

  local exportButton = AceGUI:Create("Button")
  exportButton:SetText(L["Export"])
  exportButton:SetWidth(200)
  exportButton:SetCallback("OnClick", function()
    GWT:OpenExportDialog(GWT:SerializeCompress(GWT.db.global.guilds[guildName], true))
  end)
  inlineGroup:AddChild(exportButton)

  local importStringGlobal

  local editbox = AceGUI:Create("EditBox")
  editbox:SetCallback("OnEnterPressed", function(widget, event, text) importStringGlobal = text end)
  inlineGroup:AddChild(editbox)

  local importButton = AceGUI:Create("Button")
  importButton:SetText(L["Import"])
  importButton:SetWidth(200)
  importButton:SetCallback("OnClick", function()
    local _, wishlists = GWT:DecompressDeserialize(importStringGlobal, true)
    GWT:ImportWishlists(wishlists)
  end)
  inlineGroup:AddChild(importButton)

  local inlineGroup = AceGUI:Create("InlineGroup")
  inlineGroup:SetLayout("Flow")
  inlineGroup:SetFullWidth(true)
  inlineGroup:SetTitle(L["Sync"])
  scroll:AddChild(inlineGroup)

  local exportButton = AceGUI:Create("Button")
  exportButton:SetText(L["ShareWishlist"])
  exportButton:SetWidth(200)
  exportButton:SetCallback("OnClick", function()
    GWT:ShareWishlist()
  end)
  inlineGroup:AddChild(exportButton)

  local importButton = AceGUI:Create("Button")
  importButton:SetText(L["SyncGuild"])
  importButton:SetWidth(200)
  importButton:SetCallback("OnClick", function()
    GWT:SyncWishlists()
  end)
  inlineGroup:AddChild(importButton)

  --[[local numGuildMembers = GetNumGuildMembers()
  for i=1,numGuildMembers do
    local name, _, _, lvl, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
    local memberName = AceGUI:Create("Label")
    memberName:SetText(name)
    memberName:SetColor(CONSTANTS.classColors[class].r, CONSTANTS.classColors[class].g, CONSTANTS.classColors[class].b)
    memberName:SetFullWidth(true)
    scroll:AddChild(memberName)
  end]]--
end

-- Callback function for OnGroupSelected
local function SelectGroup(container, event, group)
    container:ReleaseChildren()
    if group == "gear" then
      DrawGroupGear(container)
    elseif group == "wishlist" then
      DrawGroupWishlist(container)
    elseif group == "todo" then
      DrawGroupTodo(container)
    elseif group == "guildwishlists" then
      DrawGroupGuildWishlists(container)
    elseif group == "loothistory" then
      DrawGroupLootHistory(container)
    elseif group == "importexport" then
      DrawGroupImportExport(container)
    end
end

SLASH_GUILDWISHLIST1 = "/gwt"
SLASH_GUILDWISHLIST2 = "/guildwishlisttools"

function SlashCmdList.GUILDWISHLIST(cmd, editbox)
  cmd = cmd:lower()
  local rqst, arg = strsplit(' ', cmd)
  GWT:ShowInterface()
end

function GWT:ShowInterface()
  GWT:Init()

  -- Create the frame container
  local frame = AceGUI:Create("Frame")
  frame:SetTitle("Guild Wishlist Tools")
  --frame:SetStatusText("AceGUI-3.0 Example Container Frame")
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
  -- Fill Layout - the TabGroup widget will fill the whole frame
  frame:SetLayout("Fill")
  
  -- Create the TabGroup
  local tab =  AceGUI:Create("TabGroup")
  tab:SetLayout("Flow")
  -- Setup which tabs to show
  tab:SetTabs({
    {text=L["Gear"], value="gear"},
    {text=L["Wishlist"], value="wishlist"},
    --{text=L["Todo"], value="todo"},
    {text=L["GuildLists"], value="guildwishlists"},
    {text=L["LootHistory"], value="loothistory"},
    {text=L["ImportExport"], value="importexport"}
  })

  -- Register callback
  tab:SetCallback("OnGroupSelected", SelectGroup)

  -- Set initial Tab (this will fire the OnGroupSelected callback)
  tab:SelectTab("gear")
  
  -- add to the frame container
  frame:AddChild(tab)

  GWT.mainFrame = frame;

  GWT:MakeImportFrame(frame)
  GWT:MakeExportFrame(frame)
end

function GWT:GetEncounterLoot(instanceId, encounterId)
  EJ_SelectInstance(instanceId)
  EJ_SelectEncounter(encounterId)
  local numLoot = EJ_GetNumLoot()
  local items = {}
  local itemInfo = {}
  for i = 1, numLoot do
     local itemInfo = C_EncounterJournal.GetLootInfoByIndex(i)
     if itemInfo.name then
        items[i] = itemInfo
     end
  end

  return items
end

function GWT:GetInstanceLoot(instanceID, difficultyID)
  EJ_SetLootFilter(classID, currentSpecializationID)
  EJ_SelectInstance(instanceID)
  EJ_SetDifficulty(difficultyID)
  local numLoot = EJ_GetNumLoot()
  --print(numLoot)
  local items = {}
  local itemInfo = {}
  for i = 1, numLoot do
     local lootInfo = C_EncounterJournal.GetLootInfoByIndex(i)
     if lootInfo.name then
        local itemClassID, itemSubclassID = select(12, GetItemInfo(lootInfo.itemID))
        --exclude cosmetics
        if not(itemClassID == 4 and itemSubclassID == 5) then
          items[#items+1] = lootInfo
        end
        --print(lootInfo.link)
     end
  end
  --print(EJ_GetLootFilter())
  return items
end

function GWT:GetInstanceLootBySlot(instanceID, slot, difficultyID)
  C_EncounterJournal.SetSlotFilter(slot)
  local items = GWT:GetInstanceLoot(instanceID, difficultyID)
  C_EncounterJournal.SetSlotFilter(15) --15 for reset
  return items
end

function GWT:ImportWishlist(wishlist)
  if GWT.db.global.guilds[guildName][wishlist.guid] then
    if wishlist.lastUpdate > GWT.db.global.guilds[guildName][wishlist.guid].lastUpdate then
      GWT.db.global.guilds[guildName][wishlist.guid] = wishlist
    end
  else
      GWT.db.global.guilds[guildName][wishlist.guid] = wishlist
  end
end

function GWT:ImportWishlists(wishlists)
  for playerId, wishlist in pairs(wishlists) do
    if playerId ~= GWT.db.char.character.guid then
      GWT:ImportWishlist(wishlist)
    end
  end
end

function GWT:OnEnable()
  GWT:RegisterEvent("LOOT_READY")
  GWT:RegisterEvent("START_LOOT_ROLL")
  GWT:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")

  GWT:RegisterComm("GWTShare")
  GWT:RegisterComm("GWTSync")
end

function GWT:OnInitialize()
  GWT.db = LibStub("AceDB-3.0"):New("GuildWishlistTools" .. "DB", defaults)

  icon:Register("GuildWishlistTools", LDB, GWT.db.profile.minimap)

  GWT:Init()
end

function GWT:OnDisable()
  GWT:UnregisterEvent("LOOT_READY")
  GWT:UnregisterEvent("START_LOOT_ROLL")
  GWT:UnregisterEvent("ENCOUNTER_LOOT_RECEIVED")

  GWT:UnregisterComm("GWTShare")
  GWT:UnregisterComm("GWTSync")
end

function GWT:LOOT_READY()
  --print("loot_ready")
  for i = 1, GetNumLootItems() do
    local lootType = GetLootSlotType(i)
    local texture, item, quantity, _, quality, locked = GetLootSlotInfo(i)
    if lootType == 1 then
      local itemLink = GetLootSlotLink(i)
      local guid = GetLootSourceInfo(i) --guid source
      local _, _, _, _, itemGuid = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
      GWT:SomeoneNeed(itemGuid, itemLink)
    end
  end
end

function GWT:START_LOOT_ROLL()
  --print("START_LOOT_ROLL")
  for i = 1, GetNumLootItems() do
    local lootType = GetLootSlotType(i)
    local texture, item, quantity, _, quality, locked = GetLootSlotInfo(i)
    if lootType == 1 then
      local itemLink = GetLootSlotLink(i)
      local guid = GetLootSourceInfo(i) --guid source
      local _, _, _, _, itemGuid = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
      GWT:SomeoneNeed(itemGuid, itemLink)
    end
  end
end

function GWT:ENCOUNTER_LOOT_RECEIVED(encounterID, itemID, itemLink, quantity, playerName, className)
  local instanceName,_,difficulty,_,_,_,_,instanceID = GetInstanceInfo()

  local currTime = time()

  if GWT:ArrayHasValue(CURRENT_SEASON.dungeonInstanceIds, instanceID) or GWT:ArrayHasValue(CURRENT_SEASON.raidInstanceIds, instanceID) then
    local _, _, itemRarity = GetItemInfo(itemLink)
    if itemRarity and itemRarity < 2 then
      return
    end

    GWT.db.global.lootHistory[#GWT.db.global.lootHistory + 1] = {
      itemID = itemID,
      itemLink = itemLink,
      playerName = playerName,
      instanceID = instanceID,
      encounterID = encounterID,
    }
  end
end

function GWT:SomeoneNeed(itemGuid, itemLink)
  local itemName, _, _, ilvl, _, _, _, _, equipLoc, _, _, classID, subclassID = GetItemInfo(itemLink)
  for playerId, character in pairs(GWT.db.global.characters) do
    if character.wishlist then
      local _, class, _, _, _, name = GetPlayerInfoByGUID(character.guid)

      for i=1,#character.wishlist do
        if ((classID == 15 and subclassID == 0) and CURRENT_SEASON.tokens[itemGuid]) then
          if GWT:ArrayHasValue(CURRENT_SEASON.tokens[itemGuid].classIDs, class) then
            print(name .. " " .. L["Needs"] .. " " .. itemName)
          end
        elseif (character.wishlist[i] and character.wishlist[i].itemID) then
          if character.wishlist[i].itemID == itemGuid then
            print(name .. " " .. L["Needs"] .. " " .. itemName)
          end
        end
      end
    end
  end
end

function GWT:ArrayHasValue(array, val)
  for index, value in ipairs(array) do
    if value == val then
        return true
    end
  end

  return false
end

function GWT:MakeImportFrame(frame)
  frame.importFrame = AceGUI:Create("Frame")
  local import = frame.importFrame
  import:SetTitle(L["Import"])
  import:SetWidth(400)
  import:SetHeight(150)
  import:EnableResize(false)
  import:SetLayout("Flow")
  --import:SetCallback("OnClose", function(widget) end)
  import.statustext:GetParent():Hide()

  local importString = ""
  import.importBox = AceGUI:Create("EditBox")
  local editbox = import.importBox
  editbox:SetLabel(L["ImportWishlist"].." :")
  editbox:SetWidth(255)
  editbox.OnTextChanged = function(widget, event, text) importString = text end
  editbox:SetCallback("OnTextChanged", editbox.OnTextChanged)
  editbox:DisableButton(true)
  import:AddChild(editbox)

  import.importButton = AceGUI:Create("Button")
  local importButton = import.importButton
  importButton:SetText(L["Import"])
  importButton:SetWidth(100)
  importButton:SetCallback("OnClick", function() 
    local _, wishlist = GWT:DecompressDeserialize(importString, true)
    GWT:ImportWishlist(wishlist)
    GWT.mainFrame.importFrame:Hide()
  end)
  import:AddChild(importButton)
  import:Hide()
end

function GWT:OpenImportDialog()
  GWT.mainFrame.importFrame:ClearAllPoints()
  GWT.mainFrame.importFrame:SetPoint("CENTER", 0, 50)
  GWT.mainFrame.importFrame:Show()
  GWT.mainFrame.importFrame.importBox:SetText("")
  GWT.mainFrame.importFrame.importBox:SetFocus()
  --GWT.mainFrame.importLabel:SetText(nil)
end

function GWT:MakeExportFrame(frame)
  frame.exportFrame = AceGUI:Create("Frame")
  frame.exportFrame:SetTitle(L["Export"])
  frame.exportFrame:SetWidth(600)
  frame.exportFrame:SetHeight(400)
  frame.exportFrame:EnableResize(false)
  frame.exportFrame:SetLayout("Flow")
  frame.exportFrame:SetCallback("OnClose", function(widget)
    frame.exportFrame.statustext:GetParent():Hide()
  end)
  frame.exportFrame.editBox = AceGUI:Create("MultiLineEditBox")
  frame.exportFrame.editBox:SetWidth(600)
  frame.exportFrame.editBox:DisableButton(true)
  frame.exportFrame.editBox:SetNumLines(20)

  function frame.exportFrame.editBox:SelectAll()
    local text = frame.exportFrame.editBox:GetText()
    frame.exportFrame.editBox:HighlightText(0, string.len(text))
    frame.exportFrame.editBox:SetFocus()
  end

  frame.exportFrame.selectAllButton = AceGUI:Create("Button")
  local selectAllButton = frame.exportFrame.selectAllButton
  selectAllButton:SetText(L["SelectAll"])
  selectAllButton:SetCallback("OnClick", function(widget, callbackName, value)
    frame.exportFrame.editBox:SelectAll()
    --GWT.copyHelper:SmartShow(frame, 0, 50)
  end)

  frame.exportFrame:AddChild(frame.exportFrame.editBox)
  frame.exportFrame:AddChild(selectAllButton)
  frame.exportFrame:Hide()
end

function GWT:OpenExportDialog(export)
  GWT.mainFrame.exportFrame:ClearAllPoints()
  GWT.mainFrame.exportFrame:SetPoint("CENTER", 0, 50)
  GWT.mainFrame.exportFrame:Show()
  GWT.mainFrame.exportFrame.editBox:SetText(export)
  GWT.mainFrame.exportFrame.editBox:HighlightText(0, string.len(export))
  GWT.mainFrame.exportFrame.editBox:SetFocus()
end

function GWT:ShareWishlist()
  --deux args suivants : callback et 3 args callback
  self:SendCommMessage("GWTShare", GWT:SerializeCompress(GWT.db.char.character), "GUILD", nil, "BULK")
end

function GWT:SyncWishlists()
  --deux args suivants : callback et 3 args callback
  self:SendCommMessage("GWTSync", GWT:SerializeCompress(GWT.db.global.guilds[guildName]), "GUILD", nil, "BULK")
end

function GWT:OnCommReceived(prefix, message, distribution, sender)
  if prefix == "GWTShare" then
    local _, wishlist = GWT:DecompressDeserialize(message)
    GWT:ImportWishlist(wishlist)
  end

  if prefix == "GWTSync" then
    local _, wishlists = GWT:DecompressDeserialize(message)
    GWT:ImportWishlists(wishlists)
  end
end

function GWT:SerializeCompress(data, forExport)
  local serializedData = AceSerializer:Serialize(data)
  local compressedData = LibDeflate:CompressDeflate(serializedData)

  if forExport then
    return LibDeflate:EncodeForPrint(compressedData)
  else
    return LibDeflate:EncodeForWoWAddonChannel(compressedData)
  end
end

function GWT:DecompressDeserialize(data, forExport)
  local decodedData

  if forExport then
    decodedData = LibDeflate:DecodeForPrint(data)
  else
    decodedData = LibDeflate:DecodeForWoWAddonChannel(data)
  end
  
  local decompressedData = LibDeflate:DecompressDeflate(decodedData)
  return AceSerializer:Deserialize(decompressedData)
end

function GWT:IsPlayerInGuild()
  return IsInGuild() and GetGuildInfo("player")
end

function GWT:Init()
  guildName = GWT:IsPlayerInGuild()

  if guildName then
    if not GWT.db.global.guilds[guildName] then
      GWT.db.global.guilds[guildName] = {}
    end
  end

  GWT:LoadData()
end

function GWT:LoadData()
  classID = select(3, UnitClass("player"))
  local currentSpec = GetSpecialization()
  currentSpecializationID = GetSpecializationInfo(currentSpec)

  if not GWT.db.char.character.gear[currentSpecializationID] then
    GWT.db.char.character.gear[currentSpecializationID] = {}
  end

  if not GWT.db.char.character.wishlist[currentSpecializationID] then
    GWT.db.char.character.wishlist[currentSpecializationID] = {}
  end

  if currentSpecializationID == 577 or currentSpecializationID == 581 or currentSpecializationID == 251 or currentSpecializationID == 259 
  or currentSpecializationID == 260 or currentSpecializationID == 261 or currentSpecializationID == 72 then
    CONSTANTS.characterSlotFilterIds[16] = 10
  else
    CONSTANTS.characterSlotFilterIds[16] = 11
  end

  local raidItems = {}
  local dungeonItems = {}
  local items = {}

  for slot=1,#CONSTANTS.characterSlotFilterIds do
    if CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]] then
      local item = Item:CreateFromItemID(CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]].itemID)

      item:ContinueOnItemLoad(function()
        local name = item:GetItemName()
        local icon = item:GetItemIcon()
        CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]].name = name
        CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]].link = item:GetItemLink()
        CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]].display = CreateTextureMarkup(icon, 64, 64, 20, 20, 0.1, 0.9, 0.1, 0.9, 0, 0).." "..name
        items[item:GetItemID()] = CURRENT_SEASON.setsByClass[classID].setItems[CONSTANTS.characterSlotFilterIds[slot]]
      end)
    end

    for i=1,#CURRENT_SEASON.raidInstanceIds do
      if not raidItems[slot] then
        raidItems[slot] = {}
      end

      raidItems[slot][CURRENT_SEASON.raidInstanceIds[i]] = GWT:GetInstanceLootBySlot(CURRENT_SEASON.raidInstanceIds[i], CONSTANTS.characterSlotFilterIds[slot], 16)

      for j = 1, #raidItems[slot][CURRENT_SEASON.raidInstanceIds[i]] do
        raidItems[slot][CURRENT_SEASON.raidInstanceIds[i]][j].display = CreateTextureMarkup(raidItems[slot][CURRENT_SEASON.raidInstanceIds[i]][j].icon, 64, 64, 20, 20, 0.1, 0.9, 0.1, 0.9, 0, 0).." "..raidItems[slot][CURRENT_SEASON.raidInstanceIds[i]][j].name
        items[raidItems[slot][CURRENT_SEASON.raidInstanceIds[i]][j].itemID] = raidItems[slot][CURRENT_SEASON.raidInstanceIds[i]][j]
      end
    end

    for i=1,#CURRENT_SEASON.dungeonInstanceIds do
      if not dungeonItems[slot] then
        dungeonItems[slot] = {}
      end

      dungeonItems[slot][CURRENT_SEASON.dungeonInstanceIds[i]] = GWT:GetInstanceLootBySlot(CURRENT_SEASON.dungeonInstanceIds[i], CONSTANTS.characterSlotFilterIds[slot], 8)

      for j = 1, #dungeonItems[slot][CURRENT_SEASON.dungeonInstanceIds[i]] do
        dungeonItems[slot][CURRENT_SEASON.dungeonInstanceIds[i]][j].display = CreateTextureMarkup(dungeonItems[slot][CURRENT_SEASON.dungeonInstanceIds[i]][j].icon, 64, 64, 20, 20, 0.1, 0.9, 0.1, 0.9, 0, 0).." "..dungeonItems[slot][CURRENT_SEASON.dungeonInstanceIds[i]][j].name
        items[dungeonItems[slot][CURRENT_SEASON.dungeonInstanceIds[i]][j].itemID] = dungeonItems[slot][CURRENT_SEASON.dungeonInstanceIds[i]][j]
      end
    end
  end

  raidItemsBySlot = raidItems
  dungeonItemsBySlot = dungeonItems
  seasonItems = items
end