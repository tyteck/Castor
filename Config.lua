local _, Castor = ...
local Config = Castor.Config

Config.defaults = {
    posX        = 0,
    posY        = -200,
    locked      = false,

    maxIcons    = 6,
    iconSize    = 40,
    spacing     = 2,
    iconAlpha   = 1.0,
    hideAfter   = 0,

    direction   = "horizontal_lr",
    lines       = 1,

    trackSpells = true,
    trackItems  = true,
    onlySuccess = true,

    visibilityMode = "in_combat",
}

local clamp = {
    maxIcons   = { min = 1,   max = 20  },
    iconSize   = { min = 16,  max = 96  },
    spacing    = { min = 0,   max = 20  },
    iconAlpha  = { min = 0.1, max = 1.0 },
    hideAfter  = { min = 0,   max = 60  },
    lines      = { min = 1,   max = 2   },
    posX       = { min = -2000, max = 2000 },
    posY       = { min = -2000, max = 2000 },
}

local validDirections = {
    horizontal_lr = true, horizontal_rl = true,
    vertical_td   = true, vertical_bu   = true,
}

local validVisibility = {
    always = true, in_combat = true, out_of_combat = true,
}

function Config:Init()
    CastorDB = CastorDB or {}
    self.db = CastorDB
    for k, v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end
end

function Config:Get(key)
    return self.db[key]
end

function Config:Set(key, value)
    local c = clamp[key]
    if c and type(value) == "number" then
        if value < c.min then value = c.min end
        if value > c.max then value = c.max end
    end
    if key == "direction" and not validDirections[value] then return end
    if key == "visibilityMode" and not validVisibility[value] then return end

    local old = self.db[key]
    if old == value then return end
    self.db[key] = value

    if key == "posX" or key == "posY" then
        Castor.Display:ApplyPosition()
    elseif key == "locked" then
        Castor.Display:ApplyLocked()
    elseif key == "maxIcons" then
        Castor.Display:RebuildIconPool()
        Castor.Display:Relayout()
    elseif key == "iconSize" or key == "spacing"
        or key == "direction" or key == "lines" then
        Castor.Display:Relayout()
    elseif key == "iconAlpha" or key == "hideAfter" then
        Castor.Display:ApplyAppearance()
    elseif key == "visibilityMode" then
        Castor.Visibility:Reevaluate()
    end
end
