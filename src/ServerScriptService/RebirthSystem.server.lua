--[[
    RebirthSystem.server.lua
    Gère les Rebirths des joueurs.

    Un Rebirth :
      - Réinitialise l'argent du joueur à 0
      - Conserve les Pets et les Zones débloquées
      - Incrémente le compteur de Rebirths
      - Applique un multiplicateur de gains permanent (GameConfig.REBIRTH_EARN_MULTIPLIER ^ rebirths)

    RemoteFunction exposée :
      - RequestRebirth : Le client demande un Rebirth → retourne true/false + message
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage.Modules.GameConfig)
local GameManager = require(script.Parent.GameManager)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local function makeRemoteFunction(name)
    local rf = Instance.new("RemoteFunction")
    rf.Name   = name
    rf.Parent = remotesFolder
    return rf
end

local RequestRebirthFunc = makeRemoteFunction("RequestRebirth")

-- ─── Coût du prochain Rebirth ─────────────────────────────────────────────────

--- Calcule le coût en argent du prochain Rebirth.
-- @param rebirths number  Nombre de Rebirths déjà effectués
-- @return number
local function rebirthCost(rebirths)
    return math.floor(
        GameConfig.BASE_REBIRTH_COST * (GameConfig.REBIRTH_COST_MULTIPLIER ^ rebirths)
    )
end

-- ─── Handler ─────────────────────────────────────────────────────────────────

RequestRebirthFunc.OnServerInvoke = function(player)
    local data = GameManager.getData(player)
    if not data then
        return false, "Données introuvables."
    end

    local cost = rebirthCost(data.rebirths)

    if data.money < cost then
        return false, "Il te faut " .. cost .. " 💰 pour Rebirth. Tu en as " .. math.floor(data.money) .. "."
    end

    -- ─ Effectuer le Rebirth ─
    data.money    = 0
    data.rebirths = data.rebirths + 1

    -- Synchronise les statistiques
    local remoteMoney   = ReplicatedStorage.Remotes:FindFirstChild("UpdateMoney")
    local remoteRebirth = ReplicatedStorage.Remotes:FindFirstChild("UpdateRebirth")

    if remoteMoney   then remoteMoney:FireClient(player, 0)              end
    if remoteRebirth then remoteRebirth:FireClient(player, data.rebirths) end

    -- Met à jour les leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local moneyVal   = leaderstats:FindFirstChild("💰 Argent")
        local rebirthVal = leaderstats:FindFirstChild("⚡ Rebirths")
        if moneyVal   then moneyVal.Value   = 0              end
        if rebirthVal then rebirthVal.Value = data.rebirths  end
    end

    local nextCost = rebirthCost(data.rebirths)
    local newMult  = GameConfig.REBIRTH_EARN_MULTIPLIER ^ data.rebirths

    GameManager.notify(
        player,
        string.format(
            "⚡ Rebirth #%d effectué ! Multiplicateur de gains : x%.2f. Prochain Rebirth : %d 💰.",
            data.rebirths, newMult, nextCost
        )
    )

    return true, data.rebirths
end
