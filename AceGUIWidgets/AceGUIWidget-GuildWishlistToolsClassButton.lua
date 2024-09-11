local Type, Version = "GWTClassButton", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

local width, height = 32, 32

function Show(self,anchorUser,title,...)
  if not title then return end
  local x,y =  0, self.frame:GetHeight()
  if type(anchorUser) == "table" then
      x = anchorUser[2]
      y = anchorUser[3]
      anchorUser = anchorUser[1] or "ANCHOR_RIGHT"
  elseif not anchorUser then
      anchorUser = "ANCHOR_RIGHT"
  end
  GameTooltip:SetOwner(self.frame,anchorUser or "ANCHOR_RIGHT",x,y)
  GameTooltip:SetText(title)
  for i=1,select("#", ...) do
      local line = select(i, ...)
      if type(line) == "table" then
          if not line.right then
              if line[1] then
                  GameTooltip:AddLine(unpack(line))
              end
          else
              GameTooltip:AddDoubleLine(line[1], line.right, line[2],line[3],line[4], line[2],line[3],line[4])
          end
      else
          GameTooltip:AddLine(line)
      end
  end
  GameTooltip:Show()
end

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

      else

      end
    end

    function self.callbacks.OnEnter()
      --GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMLEFT", 0, self.frame:GetHeight())
      --local link = select(2,GetItemInfo(self.item)) or ""
      --GameTooltip:SetHyperlink(link)
      --GameTooltip:Show()
      Show(self,"ANCHOR_BOTTOMLEFT",self.name,{self.descr,1,1,1,true})
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
  ["SetItem"] = function(self, id)
    self.id = id
    local icon = "Interface\\Icons\\INV_MISC_QUESTIONMARK"
    if id then
      local _,name,descr,specializationIcon = GetSpecializationInfoByID(id)
      self.name = name
      self.descr = descr
      icon = specializationIcon
    end

    self.icon:SetTexture(icon)
  end,
  ["Disable"] = function(self)
    self.background:Hide();
    self.frame:Disable();
  end,
  ["Enable"] = function(self)
    self.background:Show();
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
  icon:SetPoint("LEFT", button, "LEFT");

  button.description = {};

  button:SetScript("OnEnter", function()

  end);
  button:SetScript("OnLeave", function()

  end);

  local widget = {
    frame = button,
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
