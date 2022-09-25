local AddonName, Private = ...

-- Lua APIs
local pairs  = pairs

-- WoW APIs
local CreateFrame, GetSpellInfo = CreateFrame, GetSpellInfo

local AceGUI = LibStub("AceGUI-3.0")

local MacroMicro = MacroMicro

local iconPicker

local spellCache = MacroMicro.spellCache

local function ConstructIconPicker(frame)
  local group = AceGUI:Create("InlineGroup");
  group.frame:SetParent(frame);
  group.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -17, 30); -- 12
  group.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -50);
  group.frame:Hide();
  group:SetLayout("fill");

  local scroll = AceGUI:Create("ScrollFrame");
  scroll:SetLayout("flow");
  scroll.frame:SetClipsChildren(true);
  group:AddChild(scroll);

  local function iconPickerFill(subname, doSort)
    scroll:ReleaseChildren();

    -- Work around special numbers such as inf and nan
    if (tonumber(subname)) then
      local spellId = tonumber(subname);
      if (abs(spellId) < math.huge and tostring(spellId) ~= "nan") then
        subname = GetSpellInfo(spellId)
      end
    end

    if subname then
      subname = subname:lower();
    end

    local usedIcons = {};
    local AddButton = function(name, icon)
      local button = AceGUI:Create("Icon");
      button:SetLabel(name);
      button:SetImage(icon);
      button:SetCallback("OnClick", function()
        group.pickCallback(icon);
        --group:Pick(icon);
      end);
      scroll:AddChild(button);

      usedIcons[icon] = true;
    end

    local num = 0;
    if(subname and subname ~= "") then
      for name, icons in pairs(spellCache.Get()) do
        if(name:lower():find(subname, 1, true)) then
          if icons.spells then
            for spell, icon in icons.spells:gmatch("(%d+)=(%d+)") do
              local iconId = tonumber(icon)
              if (not usedIcons[iconId]) then
                AddButton(name, iconId)
                num = num + 1;
                if(num >= 500) then
                  break;
                end
              end
            end
          elseif icons.achievements then
            for _, icon in icons.achievements:gmatch("(%d+)=(%d+)") do
              local iconId = tonumber(icon)
              if (not usedIcons[iconId]) then
                AddButton(name, iconId)
                num = num + 1;
                if(num >= 500) then
                  break;
                end
              end
            end
          end
        end

        if(num >= 500) then
          break;
        end
      end
    end
  end

  local blizzardIcons = {}
  GetLooseMacroIcons(blizzardIcons);
  GetLooseMacroItemIcons(blizzardIcons);
  GetMacroIcons(blizzardIcons);
  GetMacroItemIcons(blizzardIcons);

  local input = CreateFrame("EditBox", nil, group.frame, "InputBoxTemplate");
  input:SetScript("OnTextChanged", function(...) iconPickerFill(input:GetText(), false); end);
  input:SetScript("OnEnterPressed", function(...) iconPickerFill(input:GetText(), true); end);
  input:SetAutoFocus(false);
--  input:SetScript("OnEscapePressed", function(...) input:SetText(""); iconPickerFill(input:GetText(), true); end);
  input:SetWidth(170);
  input:SetHeight(15);
  input:SetPoint("BOTTOMRIGHT", group.frame, "TOPRIGHT", -12, -5);

  local inputLabel = input:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  inputLabel:SetText("Search");
  inputLabel:SetJustifyH("RIGHT");
  inputLabel:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 0, 5);

  local icon = AceGUI:Create("Icon");
  icon.frame:Disable();
  icon.frame:SetParent(group.frame);
  icon.frame:SetPoint("BOTTOMLEFT", group.frame, "TOPLEFT", 15, -15);

  local iconLabel = input:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge");
  iconLabel:SetNonSpaceWrap("true");
  iconLabel:SetJustifyH("LEFT");
  iconLabel:SetPoint("LEFT", icon.frame, "RIGHT", 5, 0);
  iconLabel:SetPoint("RIGHT", input, "LEFT", -50, 0);

  function group.Pick(self, texturePath)
    local valueToPath = Private.ValueToPath
    if self.groupIcon then
      valueToPath(self.baseObject, self.paths[self.baseObject.id], texturePath)
    --   MacroMicro.Add(self.baseObject)
    --   MacroMicro.ClearAndUpdateOptions(self.baseObject.id)
    --   MacroMicro.UpdateThumbnail(self.baseObject)
    -- else
    --   for child in Private.TraverseLeafsOrAura(self.baseObject) do
    --     valueToPath(child, self.paths[child.id], texturePath)
    --     MacroMicro.Add(child)
    --     MacroMicro.ClearAndUpdateOptions(child.id)
    --     MacroMicro.UpdateThumbnail(child);
    --   end
    end
    local success = icon:SetImage(texturePath) and texturePath;
    print(success);
    if(success) then
      iconLabel:SetText(texturePath);
    else
      iconLabel:SetText();
    end
  end

  function group.Open(self, baseObject, paths, groupIcon, pickCallback)
    self.pickCallback = pickCallback;
    local valueFromPath = Private.ValueFromPath
    self.baseObject = baseObject
    self.paths = paths
    self.groupIcon = groupIcon
    if groupIcon then
      local value = valueFromPath(self.baseObject, paths[self.baseObject.id])
      self.givenPath = value
    -- else
    --   self.givenPath = {};
    --   for child in Private.TraverseLeafsOrAura(baseObject) do
    --     if(child) then
    --       local value = valueFromPath(child, paths[child.id])
    --       self.givenPath[child.id] = value or "";
    --     end
    --   end
    end
    -- group:Pick(self.givenPath);
    frame.window = "icon";
    --frame:UpdateFrameVisible()
    input:SetText("");
    input:SetFocus();
  end

  function group.Close()
    frame.window = "default";
    --frame:UpdateFrameVisible()
    --MacroMicro.FillOptions()
  end

  function group.CancelClose()
    local valueToPath = Private.ValueToPath
    if group.groupIcon then
      valueToPath(group.baseObject, group.paths[group.baseObject.id], group.givenPath)
    --   MacroMicro.Add(group.baseObject)
    --   MacroMicro.ClearAndUpdateOptions(group.baseObject.id)
    --   MacroMicro.UpdateThumbnail(group.baseObject)
    -- else
    --   for child in Private.TraverseLeafsOrAura(group.baseObject) do
    --     if (group.givenPath[child.id]) then
    --       valueToPath(child, group.paths[child.id], group.givenPath[child.id])
    --       MacroMicro.Add(child);
    --       MacroMicro.ClearAndUpdateOptions(child.id)
    --       MacroMicro.UpdateThumbnail(child);
    --     end
    --   end
    end

    group.Close();
  end

  local cancel = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  cancel:SetScript("OnClick", group.CancelClose);
  cancel:SetPoint("bottomright", frame, "bottomright", -27, 11);
  cancel:SetHeight(20);
  cancel:SetWidth(100);
  cancel:SetText("Cancel");

  local close = CreateFrame("Button", nil, group.frame, "UIPanelButtonTemplate");
  close:SetScript("OnClick", group.Close);
  close:SetPoint("RIGHT", cancel, "LEFT", -10, 0);
  close:SetHeight(20);
  close:SetWidth(100);
  close:SetText("Okay");

  return group
end

function Private.IconPicker(frame)
  iconPicker = iconPicker or ConstructIconPicker(frame)
  return iconPicker
end
