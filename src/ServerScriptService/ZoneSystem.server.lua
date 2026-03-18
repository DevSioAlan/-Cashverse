--[[
    ZoneSystem.server.lua
    Gère le déblocage des zones par les joueurs.

    RemoteFunction exposée :
      - UnlockZone : Le client demande à débloquer une zone → retourne true/false + message
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneData    = require(ReplicatedStorage.Modules.ZoneData)
local GameManager = require(script.Parent.GameManager)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local function makeRemoteFunction(name)
    local rf = Instance.new("RemoteFunction")
    rf.Name   = name
    rf.Parent = remotesFolder
    return rf
end

local UnlockZoneFunc = makeRemoteFunction("UnlockZone")

-- ─── Handler ─────────────────────────────────────────────────────────────────

UnlockZoneFunc.OnServerInvoke = function(player, zoneId)
    if type(zoneId) ~= "string" then
        return false, "Identifiant de zone invalide."
    end

    local zone = ZoneData.getZoneById(zoneId)
    if not zone then
        return false, "Zone inconnue."
    end

    local data = GameManager.getData(player)
    if not data then
        return false, "Données introuvables."
    end

    if data.unlockedZones[zoneId] then
        return false, "Zone déjà débloquée !"
    end

    if data.money < zone.cost then
        return false,
            string.format(
                "Il te faut %d 💰 pour débloquer %s. Tu en as %d.",
                zone.cost, zone.name, math.floor(data.money)
            )
    end

    if not GameManager.spendMoney(player, zone.cost) then
        return false, "Transaction échouée."
    end

    data.unlockedZones[zoneId] = true
    GameManager.syncZones(player)

    GameManager.notify(
        player,
        "🌍 Nouvelle zone débloquée : " .. zone.name .. " (x" .. zone.multiplier .. " gains) !"
    )

    return true, zone
end
