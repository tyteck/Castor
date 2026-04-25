local _, Castor = ...
local Options = Castor.Options
local L = Castor.L

local function db()
    return Castor.Config.db
end

local PANEL_W, PANEL_H = 280, 540
local PADDING = 14

local function makeBackdrop(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.85)
        frame:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
    end
end

local function addLabel(parent, anchor, yOffset, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, yOffset)
    fs:SetText(text)
    return fs
end

local function makeSlider(parent, key, minV, maxV, step, label, anchor, yOffset)
    local s = CreateFrame("Slider", "CastorSlider_"..key, parent, "OptionsSliderTemplate")
    s:SetWidth(PANEL_W - 2*PADDING - 50)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, yOffset - 14)

    _G[s:GetName().."Low"]:SetText(tostring(minV))
    _G[s:GetName().."High"]:SetText(tostring(maxV))
    _G[s:GetName().."Text"]:SetText(label)

    local val = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    val:SetPoint("LEFT", s, "RIGHT", 6, 0)

    local function refresh()
        local v = db()[key]
        s:SetValue(v)
        if step >= 1 then
            val:SetText(tostring(math.floor(v + 0.5)))
        else
            val:SetText(string.format("%.1f", v))
        end
    end

    s:SetScript("OnValueChanged", function(_, v)
        if step >= 1 then v = math.floor(v + 0.5) end
        Castor.Config:Set(key, v)
        if step >= 1 then
            val:SetText(tostring(v))
        else
            val:SetText(string.format("%.1f", v))
        end
    end)

    s.Refresh = refresh
    refresh()
    return s
end

local function makeCheckbox(parent, key, label, anchor, yOffset)
    local cb = CreateFrame("CheckButton", "CastorCheck_"..key, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", anchor, "TOPLEFT", -2, yOffset)
    local cbText = cb.Text or cb.text or _G[cb:GetName().."Text"]
    if cbText then cbText:SetText(label) end

    local function refresh() cb:SetChecked(db()[key] and true or false) end

    cb:SetScript("OnClick", function(self)
        Castor.Config:Set(key, self:GetChecked() and true or false)
    end)

    cb.Refresh = refresh
    refresh()
    return cb
end

local function makeCycleButton(parent, key, label, choices, anchor, yOffset)
    addLabel(parent, anchor, yOffset, label)

    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(PANEL_W - 2*PADDING, 22)
    b:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, yOffset - 14)

    local function refresh()
        local v = db()[key]
        for _, c in ipairs(choices) do
            if c.value == v then
                b:SetText(c.label)
                return
            end
        end
        b:SetText(tostring(v))
    end

    b:SetScript("OnClick", function()
        local current = db()[key]
        local idx = 1
        for i, c in ipairs(choices) do
            if c.value == current then idx = i break end
        end
        local nextChoice = choices[(idx % #choices) + 1]
        Castor.Config:Set(key, nextChoice.value)
        refresh()
    end)

    b.Refresh = refresh
    refresh()
    return b
end

function Options:Build()
    if self.panel then return self.panel end

    local panel = CreateFrame("Frame", "CastorOptionsPanel", UIParent, "BackdropTemplate")
    panel:SetSize(PANEL_W, PANEL_H)
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop",  panel.StopMovingOrSizing)
    panel:Hide()
    makeBackdrop(panel)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("Castor")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        if Castor.editing and Castor.EditMode then
            Castor.EditMode:Exit()
        else
            panel:Hide()
        end
    end)

    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT",  panel, "TOPLEFT",  PADDING, -32)
    content:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PADDING, -32)
    content:SetHeight(PANEL_H - 40)

    self.panel    = panel
    self.refreshables = {}

    local widgets = self.refreshables
    local y = 0

    table.insert(widgets, makeSlider(content, "maxIcons",  1,   20,  1,    L["Number of icons"], content, y))   y = y - 36
    table.insert(widgets, makeSlider(content, "iconSize",  16,  96,  1,    L["Icon size"],       content, y))   y = y - 36
    table.insert(widgets, makeSlider(content, "spacing",   0,   20,  1,    L["Spacing"],         content, y))   y = y - 36
    table.insert(widgets, makeSlider(content, "iconAlpha", 0.1, 1.0, 0.1,  L["Opacity"],         content, y))   y = y - 36
    table.insert(widgets, makeSlider(content, "hideAfter", 0,   60,  1,    L["Hide after (sec)"], content, y))  y = y - 40

    table.insert(widgets, makeCycleButton(content, "direction", L["Direction"], {
        { value = "horizontal_lr", label = L["Horizontal: left to right"] },
        { value = "horizontal_rl", label = L["Horizontal: right to left"] },
        { value = "vertical_td",   label = L["Vertical: top to bottom"]   },
        { value = "vertical_bu",   label = L["Vertical: bottom to top"]   },
    }, content, y)) y = y - 44

    table.insert(widgets, makeCycleButton(content, "lines", L["Rows / columns"], {
        { value = 1, label = L["1 line"]  },
        { value = 2, label = L["2 lines"] },
    }, content, y)) y = y - 44

    table.insert(widgets, makeCycleButton(content, "visibilityMode", L["Visibility"], {
        { value = "always",        label = L["Always visible"] },
        { value = "in_combat",     label = L["In combat only"] },
        { value = "out_of_combat", label = L["Out of combat"]  },
    }, content, y)) y = y - 44

    table.insert(widgets, makeCheckbox(content, "trackSpells", L["Track spells"], content, y)) y = y - 22
    table.insert(widgets, makeCheckbox(content, "trackItems",  L["Track items"],  content, y)) y = y - 22
    table.insert(widgets, makeCheckbox(content, "onlySuccess", L["Only successful casts"], content, y)) y = y - 22
    table.insert(widgets, makeCheckbox(content, "locked",      L["Lock frame"], content, y)) y = y - 30

    local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetBtn:SetSize(PANEL_W - 2*PADDING, 22)
    resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    resetBtn:SetText(L["Reset position"])
    resetBtn:SetScript("OnClick", function()
        Castor.Config:Set("posX", 0)
        Castor.Config:Set("posY", -200)
        Castor.Display:ApplyPosition()
    end)

    return panel
end

function Options:Init()
    self:Build()
end

function Options:Refresh()
    if not self.refreshables then return end
    for _, w in ipairs(self.refreshables) do
        if w.Refresh then w:Refresh() end
    end
end

local function smartAnchor(panel, target)
    local pw, ph = panel:GetSize()
    local sw, sh = UIParent:GetSize()
    local GAP = 12

    local tLeft  = target:GetLeft()  or 0
    local tRight = target:GetRight() or sw
    local tTop   = target:GetTop()   or sh

    local rightSpace = sw - tRight - GAP
    local leftSpace  = tLeft - GAP
    local placeRight = rightSpace >= pw or rightSpace >= leftSpace

    local x = placeRight and (tRight + GAP) or (tLeft - GAP - pw)
    local y = tTop

    if x < 0 then x = 0 end
    if x + pw > sw then x = sw - pw end
    if y > sh then y = sh end
    if y - ph < 0 then y = ph end

    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

function Options:Open(anchorFrame)
    self:Build()
    self:Refresh()
    self.panel:ClearAllPoints()
    if anchorFrame then
        smartAnchor(self.panel, anchorFrame)
    else
        self.panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    self.panel:SetClampedToScreen(true)
    self.panel:Show()
end

function Options:Close()
    if self.panel then self.panel:Hide() end
end
