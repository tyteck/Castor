local addonName, Castor = ...

Castor.version = "0.1"
Castor.editing = false
Castor.Config = {}
Castor.Display = {}
Castor.Tracker = {}
Castor.Visibility = {}
Castor.Options = {}

_G.Castor = Castor

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Castor.Config:Init()
        Castor.Display:Init()
        Castor.Tracker:Init()
        Castor.Visibility:Init()
        Castor.Options:Init()
        Castor.EditMode:Init()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        Castor.Visibility:Reevaluate()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

SLASH_CASTOR1 = "/castor"
SLASH_CASTOR2 = "/cas"
SlashCmdList["CASTOR"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local L = Castor.L
    if msg == "lock" then
        Castor.Config:Set("locked", true)
        print("|cff7fbfffCastor|r: " .. L["frame locked"])
    elseif msg == "unlock" then
        Castor.Config:Set("locked", false)
        print("|cff7fbfffCastor|r: " .. L["frame unlocked, drag to move"])
    elseif msg == "reset" then
        Castor.Config:Set("posX", 0)
        Castor.Config:Set("posY", -200)
        Castor.Display:ApplyPosition()
        print("|cff7fbfffCastor|r: " .. L["position reset"])
    else
        Castor.EditMode:Toggle()
    end
end
