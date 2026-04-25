local _, Castor = ...
local Tracker = Castor.Tracker

local function db()
    return Castor.Config.db
end

local pendingCasts  = {}
local lastItemUseAt = 0
local ITEM_WINDOW   = 0.4

local function getSpellInfo(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then return info.name, info.iconID end
    end
    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon
    end
    return nil, nil
end

local function buildAction(spellID, target, kind, itemID)
    local name, icon = getSpellInfo(spellID)
    if not icon then return nil end
    return {
        spellID = spellID,
        itemID  = itemID,
        name    = name,
        icon    = icon,
        target  = target or "",
        time    = GetTime(),
        kind    = kind,
    }
end

local function shouldRecord(action)
    local d = db()
    if action.kind == "item"  and not d.trackItems  then return false end
    if action.kind == "spell" and not d.trackSpells then return false end
    return true
end

local function classifyAndPush(spellID, target)
    local kind = "spell"
    if (GetTime() - lastItemUseAt) <= ITEM_WINDOW then
        kind = "item"
    end
    local action = buildAction(spellID, target, kind)
    if action and shouldRecord(action) then
        Castor.Display:Push(action)
    end
end

function Tracker:Init()
    local f = CreateFrame("Frame")
    f:RegisterUnitEvent("UNIT_SPELLCAST_SENT",      "player")
    f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    f:SetScript("OnEvent", function(_, event, ...)
        local unit = ...
        if unit ~= "player" then return end

        if event == "UNIT_SPELLCAST_SENT" then
            local _, target, castGUID, spellID = ...
            pendingCasts[castGUID] = target or ""
            if not db().onlySuccess then
                classifyAndPush(spellID, target)
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local _, castGUID, spellID = ...
            local target = pendingCasts[castGUID]
            pendingCasts[castGUID] = nil
            if db().onlySuccess then
                classifyAndPush(spellID, target)
            end
        end
    end)

    local function markItem() lastItemUseAt = GetTime() end

    if type(UseInventoryItem) == "function" then
        hooksecurefunc("UseInventoryItem", markItem)
    end
    if C_Container and type(C_Container.UseContainerItem) == "function" then
        hooksecurefunc(C_Container, "UseContainerItem", markItem)
    elseif type(UseContainerItem) == "function" then
        hooksecurefunc("UseContainerItem", markItem)
    end
    if type(UseAction) == "function" then
        hooksecurefunc("UseAction", function(slot)
            local actionType = GetActionInfo(slot)
            if actionType == "item" then markItem() end
        end)
    end

    self.frame = f
end
