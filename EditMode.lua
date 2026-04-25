local _, Castor = ...
local EditMode = {}
Castor.EditMode = EditMode

function EditMode:Enter()
    if Castor.editing then return end
    Castor.editing = true
    Castor.Display:SetEditMode(true)
    Castor.Options:Open(Castor.Display.frame)
end

function EditMode:Exit()
    if not Castor.editing then return end
    Castor.editing = false
    Castor.Display:SetEditMode(false)
    Castor.Options:Close()
end

function EditMode:Toggle()
    if Castor.editing then self:Exit() else self:Enter() end
end

local function enter() EditMode:Enter() end
local function exit()  EditMode:Exit()  end

local function isEditModeActive()
    if EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive then
        return EditModeManagerFrame:IsEditModeActive()
    end
    if EditModeManagerFrame then
        return EditModeManagerFrame.editModeActive == true
            or EditModeManagerFrame:IsShown()
    end
    return false
end

function EditMode:Init()
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Enter", enter)
        EventRegistry:RegisterCallback("EditMode.Exit",  exit)
    end

    if EditModeManagerFrame then
        EditModeManagerFrame:HookScript("OnShow", enter)
        EditModeManagerFrame:HookScript("OnHide", exit)
    end

    if isEditModeActive() then enter() end
end
