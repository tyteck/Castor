local _, Castor = ...
local Visibility = Castor.Visibility

local function db()
    return Castor.Config.db
end

function Visibility:Init()
    self.inCombat = InCombatLockdown() or false

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self.inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.inCombat = false
        end
        self:Reevaluate()
    end)

    self.frame = f
end

function Visibility:Reevaluate()
    if Castor.editing then
        Castor.Display:SetVisible(true)
        return
    end
    local mode = db().visibilityMode
    local show
    if mode == "in_combat" then
        show = self.inCombat
    elseif mode == "out_of_combat" then
        show = not self.inCombat
    else
        show = true
    end
    Castor.Display:SetVisible(show)
end
