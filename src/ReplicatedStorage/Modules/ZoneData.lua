--[[
    ZoneData.lua
    Données de toutes les zones débloquables dans Cashverse.

    Chaque zone a :
      - id          : Identifiant unique
      - name        : Nom affiché
      - cost        : Argent requis pour débloquer la zone
      - multiplier  : Multiplicateur de gains supplémentaire dans cette zone
      - description : Description affichée dans l'UI
      - color       : Couleur thématique (Color3)
--]]

local ZoneData = {}

ZoneData.Zones = {
    {
        id          = "starter_zone",
        name        = "Place du Marché",
        cost        = 0,         -- Zone de départ, gratuite
        multiplier  = 1.00,
        description = "L'endroit où tout commence. Des pièces jonchent le sol.",
        color       = Color3.fromRGB(100, 200, 100),
    },
    {
        id          = "coin_alley",
        name        = "Ruelle des Pièces",
        cost        = 500,
        multiplier  = 1.50,
        description = "Une ruelle pavée de pièces d'or.",
        color       = Color3.fromRGB(220, 180, 50),
    },
    {
        id          = "silver_district",
        name        = "District Argenté",
        cost        = 5000,
        multiplier  = 2.00,
        description = "Des bâtiments en argent massif brillent sous le soleil.",
        color       = Color3.fromRGB(180, 180, 220),
    },
    {
        id          = "golden_valley",
        name        = "Vallée Dorée",
        cost        = 25000,
        multiplier  = 3.50,
        description = "Une vallée où coulent des rivières d'or liquide.",
        color       = Color3.fromRGB(255, 215, 0),
    },
    {
        id          = "diamond_peaks",
        name        = "Sommets de Diamant",
        cost        = 150000,
        multiplier  = 6.00,
        description = "Des montagnes de diamants étincelants t'attendent.",
        color       = Color3.fromRGB(100, 220, 255),
    },
    {
        id          = "cosmic_realm",
        name        = "Royaume Cosmique",
        cost        = 1000000,
        multiplier  = 12.00,
        description = "Une dimension galactique remplie de trésors infinis.",
        color       = Color3.fromRGB(160, 50, 255),
    },
    {
        id          = "void_nexus",
        name        = "Nexus du Néant",
        cost        = 10000000,
        multiplier  = 25.00,
        description = "Le cœur du néant cache les richesses les plus obscures.",
        color       = Color3.fromRGB(20, 10, 40),
    },
}

-- ─── Utilitaires ─────────────────────────────────────────────────────────────

--- Retourne la définition d'une zone par son id.
-- @param id string
-- @return table|nil
function ZoneData.getZoneById(id)
    for _, zone in ipairs(ZoneData.Zones) do
        if zone.id == id then
            return zone
        end
    end
    return nil
end

--- Retourne la prochaine zone non débloquée pour un joueur.
-- @param unlockedZones table  Table de type {zoneId = true}
-- @return table|nil  La prochaine zone à débloquer, ou nil si tout est débloqué
function ZoneData.getNextZone(unlockedZones)
    for _, zone in ipairs(ZoneData.Zones) do
        if not unlockedZones[zone.id] then
            return zone
        end
    end
    return nil
end

--- Calcule le multiplicateur total d'un joueur selon ses zones débloquées.
-- Renvoie le multiplicateur de la zone la plus avancée débloquée.
-- @param unlockedZones table  Table de type {zoneId = true}
-- @return number
function ZoneData.getBestMultiplier(unlockedZones)
    local best = 1.00
    for _, zone in ipairs(ZoneData.Zones) do
        if unlockedZones[zone.id] and zone.multiplier > best then
            best = zone.multiplier
        end
    end
    return best
end

return ZoneData
