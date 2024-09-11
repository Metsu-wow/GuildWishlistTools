local Type, Version = "GWTItemButton", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local width, height = 248, 32

local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(width);
    self:SetHeight(height);
  end,
  ["Initialize"] = function(self)
    self.callbacks = {}

    function self.callbacks.OnClickNormal(_, mouseButton)
      if (IsControlKeyDown()) then

      elseif (IsShiftKeyDown()) then
        if DEFAULT_CHAT_FRAME.editBox and DEFAULT_CHAT_FRAME.editBox:IsVisible() then
          local old = DEFAULT_CHAT_FRAME.editBox:GetText()

          if self.item then
            local link = self.item or ""
            DEFAULT_CHAT_FRAME.editBox:SetText(old .. link)
          end
        end
      else

      end
    end

    function self.callbacks.OnEnter()
      GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMLEFT", 0, self.frame:GetHeight())
      
      if self.item then
        local link = self.item or ""
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
      end
    end

    function self.callbacks.OnLeave()
      GameTooltip:Hide()
    end

    function self.callbacks.OnKeyDown(_, key)
      --
    end

    function self.callbacks.OnDragStart()
      --
    end

    function self.callbacks.OnDragStop()
      --
    end

    self.frame:SetScript("OnClick", self.callbacks.OnClickNormal);
    self.frame:SetScript("OnKeyDown", self.callbacks.OnKeyDown);
    self.frame:SetScript("OnEnter", self.callbacks.OnEnter);
    self.frame:SetScript("OnLeave", self.callbacks.OnLeave);
    self.frame:EnableKeyboard(false);
    self.frame:SetMovable(true);
    self.frame:RegisterForDrag("LeftButton");
    self.frame:SetScript("OnDragStart", self.callbacks.OnDragStart);
    self.frame:SetScript("OnDragStop", self.callbacks.OnDragStop);
    self:Enable();
  end,
  ["SetItem"] = function(self, item)
    self.item = item
    local icon = "Interface\\Icons\\INV_MISC_QUESTIONMARK"
    if item then
      local name = select(1,GetItemInfo(item))
      icon = select(10,GetItemInfo(item))
      self.title:SetText(name)
    end
    
    self.icon:SetTexture(icon)
  end,
  ["Disable"] = function(self)
    self.background:Hide();
    self.frame:Disable();
  end,
  ["Enable"] = function(self)
    self.background:Show();
    self.title:Show()
    self.frame:Enable();
  end,
  ["Pick"] = function(self)
    self.frame:LockHighlight();
  end,
  ["ClearPick"] = function(self)
    self.frame:UnlockHighlight();
  end,
  ["SetIndex"] = function(self, index)
    self.index = index
  end,
  ["SetTitle"] = function(self, title)
    self.titletext = title;
    self.title:SetText(title);
  end,
  ["HideTitle"] = function(self)
    self.title:Hide()
    self:SetWidth(32);
  end,

}

--Constructor
local function Constructor()
  local name = "GWTItemButton" .. AceGUI:GetNextWidgetNum(Type);
  local button = CreateFrame("BUTTON", name, UIParent, "OptionsListButtonTemplate");
  button:SetHeight(height);
  button:SetWidth(width);
  button.dgroup = nil;
  button.data = {};

  local background = button:CreateTexture(nil, "BACKGROUND", nil, 0);
  button.background = background;
  background:SetTexture("Interface\\BUTTONS\\UI-Listbox-Highlight2.blp");
  background:SetBlendMode("ADD");
  background:SetVertexColor(0.5, 0.5, 0.5, 0.25);
  background:SetPoint("TOP", button, "TOP");
  background:SetPoint("BOTTOM", button, "BOTTOM");
  background:SetPoint("LEFT", button, "LEFT");
  background:SetPoint("RIGHT", button, "RIGHT");

  local icon = button:CreateTexture(nil, "OVERLAY", nil, 0);
  button.icon = icon;
  icon:SetWidth(height);
  icon:SetHeight(height);
  --icon:SetBlendMode("ADD");
  --icon:SetVertexColor(1, 0, 0, 1);
  icon:SetPoint("LEFT", button, "LEFT");

  local title = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  button.title = title;
  title:SetHeight(14);
  title:SetJustifyH("LEFT");
  title:SetPoint("TOP", button, "TOP", 0, -2);
  title:SetPoint("LEFT", icon, "RIGHT", 2, 0);
  title:SetPoint("RIGHT", button, "RIGHT");

  button.description = {};

  button:SetScript("OnEnter", function()

  end);
  button:SetScript("OnLeave", function()

  end);

  local widget = {
    frame = button,
    title = title,
    icon = icon,
    background = background,
    type = Type
  }
  for method, func in pairs(methods) do
    ---@diagnostic disable-next-line: assign-type-mismatch
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget);
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
