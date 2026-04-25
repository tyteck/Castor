local _, Castor = ...

local L = setmetatable({}, { __index = function(_, k) return k end })
Castor.L = L

local locale = GetLocale()

if locale == "frFR" then
    L["Number of icons"]       = "Nombre d'icônes"
    L["Icon size"]             = "Taille des icônes"
    L["Spacing"]               = "Espacement"
    L["Opacity"]               = "Opacité"
    L["Hide after (sec)"]      = "Masquer après (sec)"
    L["Direction"]             = "Direction"
    L["Rows / columns"]        = "Lignes / colonnes"
    L["Visibility"]            = "Visibilité"
    L["Track spells"]          = "Suivre les sorts"
    L["Track items"]           = "Suivre les objets"
    L["Only successful casts"] = "Sorts réussis uniquement"
    L["Lock frame"]            = "Verrouiller la fenêtre"
    L["Reset position"]        = "Réinitialiser la position"

    L["Horizontal: left to right"] = "Horizontal : gauche à droite"
    L["Horizontal: right to left"] = "Horizontal : droite à gauche"
    L["Vertical: top to bottom"]   = "Vertical : haut en bas"
    L["Vertical: bottom to top"]   = "Vertical : bas en haut"
    L["1 line"]                    = "1 ligne"
    L["2 lines"]                   = "2 lignes"
    L["Always visible"]            = "Toujours visible"
    L["In combat only"]            = "En combat uniquement"
    L["Out of combat"]             = "Hors combat"

    L["frame locked"]                 = "fenêtre verrouillée"
    L["frame unlocked, drag to move"] = "fenêtre déverrouillée, glisse-la pour la déplacer"
    L["position reset"]               = "position réinitialisée"
end
