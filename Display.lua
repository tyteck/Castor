local _, Castor = ...
local Display = Castor.Display

local function db()
    return Castor.Config.db
end

local function createIcon(parent)
    local f = CreateFrame("Frame", nil, parent)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.bg:SetColorTexture(0, 0, 0, 0.6)

    f.texture = f:CreateTexture(nil, "ARTWORK")
    f.texture:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.texture:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    f.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.targetName = f:CreateFontString(nil, "OVERLAY")
    f.targetName:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    f.targetName:SetTextColor(1, 1, 1, 1)
    f.targetName:SetWordWrap(false)
    f.targetName:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)

    f:EnableMouse(true)

    f:SetScript("OnEnter", function(self)
        if not self.action then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.action.kind == "item" and self.action.itemID then
            GameTooltip:SetItemByID(self.action.itemID)
        elseif self.action.spellID then
            GameTooltip:SetSpellByID(self.action.spellID)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f:Hide()
    return f
end

function Display:Init()
    local frame = CreateFrame("Frame", "CastorFrame", UIParent)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if Display._editing or not db().locked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local px, py = UIParent:GetCenter()
        if cx and px then
            Castor.Config.db.posX = cx - px
            Castor.Config.db.posY = cy - py
        end
    end)

    frame.editBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.editBg:SetAllPoints(frame)
    frame.editBg:SetColorTexture(0.1, 0.5, 1.0, 0.25)
    frame.editBg:Hide()

    frame.editBorder = {}
    local function addEdge(setPoints)
        local t = frame:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0.3, 0.7, 1.0, 0.9)
        setPoints(t)
        t:Hide()
        table.insert(frame.editBorder, t)
    end
    local THICK = 2
    addEdge(function(t)
        t:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -THICK, THICK)
        t:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT",     THICK, 0)
    end)
    addEdge(function(t)
        t:SetPoint("TOPLEFT",     frame, "BOTTOMLEFT",  -THICK, 0)
        t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  THICK, -THICK)
    end)
    addEdge(function(t)
        t:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -THICK, 0)
        t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT",   0,     0)
    end)
    addEdge(function(t)
        t:SetPoint("TOPLEFT",     frame, "TOPRIGHT",     0,     0)
        t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  THICK, 0)
    end)

    frame.editLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.editLabel:SetPoint("BOTTOM", frame, "TOP", 0, 4)
    frame.editLabel:SetText("Castor")
    frame.editLabel:Hide()

    self.frame   = frame
    self.icons   = {}
    self.actions = {}
    self._hideThrottle = 0
    self._editing = false

    frame:SetScript("OnUpdate", function(_, elapsed)
        self._hideThrottle = self._hideThrottle + elapsed
        if self._hideThrottle < 0.1 then return end
        self._hideThrottle = 0
        self:UpdateFades()
    end)

    self:RebuildIconPool()
    self:Relayout()
    self:ApplyPosition()
    self:ApplyLocked()
    self:ApplyAppearance()
end

function Display:RebuildIconPool()
    local n = db().maxIcons
    for i = 1, n do
        if not self.icons[i] then
            self.icons[i] = createIcon(self.frame)
        end
    end
    for i = n + 1, #self.icons do
        self.icons[i]:Hide()
        self.icons[i].action = nil
    end
    for i = n + 1, #self.actions do
        self.actions[i] = nil
    end
end

function Display:Relayout()
    if self._editing then self:PopulatePreview() end
    local d           = db()
    local n           = d.maxIcons
    local lines       = d.lines
    local primary     = math.ceil(n / lines)
    local size        = d.iconSize
    local sp          = d.spacing
    local horizontal  = (d.direction == "horizontal_lr" or d.direction == "horizontal_rl")
    local reverse     = (d.direction == "horizontal_rl" or d.direction == "vertical_bu")

    for i = 1, n do
        local icon = self.icons[i]
        local idx0 = i - 1
        local x, y
        if horizontal then
            local col = idx0 % primary
            local row = math.floor(idx0 / primary)
            if reverse then col = primary - 1 - col end
            x =  col * (size + sp)
            y = -row * (size + sp)
        else
            local row = idx0 % primary
            local col = math.floor(idx0 / primary)
            if reverse then row = primary - 1 - row end
            x =  col * (size + sp)
            y = -row * (size + sp)
        end
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, y)
        icon:SetSize(size, size)
    end

    local cols = horizontal and primary or lines
    local rows = horizontal and lines   or primary
    self.frame:SetSize(cols * (size + sp) - sp, rows * (size + sp) - sp)

    self:RenderAll()
end

function Display:ApplyPosition()
    local d = db()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", d.posX, d.posY)
end

function Display:ApplyLocked()
    if self._editing then
        self.frame:EnableMouse(true)
    else
        self.frame:EnableMouse(not db().locked)
    end
end

function Display:SetEditMode(active)
    self._editing = active and true or false
    for _, icon in ipairs(self.icons) do
        icon:EnableMouse(not active)
    end
    if active then
        self.frame.editBg:Show()
        self.frame.editLabel:Show()
        for _, edge in ipairs(self.frame.editBorder) do edge:Show() end
        self.frame:Show()
        self.frame:EnableMouse(true)
        self:PopulatePreview()
    else
        self.frame.editBg:Hide()
        self.frame.editLabel:Hide()
        for _, edge in ipairs(self.frame.editBorder) do edge:Hide() end
        self:RenderAll()
        self:ApplyLocked()
        Castor.Visibility:Reevaluate()
    end
end

function Display:PopulatePreview()
    local samples = {
        { spellID = 6673,   name = "Battle Shout",  icon = 132333 },
        { spellID = 1715,   name = "Hamstring",     icon = 132316 },
        { spellID = 845,    name = "Cleave",        icon = 132338 },
        { spellID = 12294,  name = "Mortal Strike", icon = 132355 },
        { spellID = 1464,   name = "Slam",          icon = 132340 },
        { spellID = 23922,  name = "Shield Slam",   icon = 132357 },
    }
    local n = db().maxIcons
    local now = GetTime()
    for i = 1, n do
        local s = samples[((i - 1) % #samples) + 1]
        self.actions[i] = {
            spellID = s.spellID, name = s.name, icon = s.icon,
            target = "", time = now, kind = "spell",
        }
    end
    self:RenderAll()
end

function Display:ApplyAppearance()
    self:UpdateFades()
end

function Display:SetVisible(visible)
    if visible then self.frame:Show() else self.frame:Hide() end
end

function Display:Push(action)
    local n = db().maxIcons
    for i = n, 2, -1 do
        self.actions[i] = self.actions[i - 1]
    end
    self.actions[1] = action
    self:RenderAll()
end

function Display:RenderAll()
    local n = db().maxIcons
    local d = db()
    local showTarget = (d.direction == "vertical_td" or d.direction == "vertical_bu")
    for i = 1, n do
        local icon   = self.icons[i]
        local action = self.actions[i]
        if action then
            icon.action  = action
            icon.texture:SetTexture(action.icon)
            icon.targetName:SetText(showTarget and (action.target or "") or "")
            icon:Show()
        else
            icon.action = nil
            icon:Hide()
        end
    end
    self:UpdateFades()
end

function Display:UpdateFades()
    local d = db()
    local hideAfter = d.hideAfter or 0
    local alpha = d.iconAlpha or 1.0
    local now = GetTime()
    for i = 1, d.maxIcons do
        local icon = self.icons[i]
        if icon and icon:IsShown() and icon.action then
            if not self._editing and hideAfter > 0
                and (now - icon.action.time) > hideAfter then
                icon:SetAlpha(0)
            else
                icon:SetAlpha(alpha)
            end
        end
    end
end
