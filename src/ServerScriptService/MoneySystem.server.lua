--[[
    MoneySystem.server.lua
    Gère le spawn et la collecte des pièces d'argent dans chaque zone.

    Fonctionnement :
      - Spawn périodique de pièces dans le Workspace (dossier "Coins")
      - Détection de collision joueur ↔ pièce via Touched
      - Calcul du gain en tenant compte des multiplicateurs (zone, pets, rebirth)
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local GameConfig  = require(ReplicatedStorage.Modules.GameConfig)
local PetData     = require(ReplicatedStorage.Modules.PetData)
local ZoneData    = require(ReplicatedStorage.Modules.ZoneData)

-- Attendre que GameManager soit disponible (chargé avant ce script grâce à l'ordre Roblox)
local GameManager = require(script.Parent.GameManager)

-- ─── Dossier des pièces dans le Workspace ────────────────────────────────────

local coinsFolder = Workspace:FindFirstChild("Coins")
if not coinsFolder then
    coinsFolder = Instance.new("Folder")
    coinsFolder.Name   = "Coins"
    coinsFolder.Parent = Workspace
end

-- ─── Utilitaire : multiplicateur total d'un joueur ───────────────────────────

--- Calcule le multiplicateur de gain total pour un joueur.
-- Prend en compte : zone actuelle, pets équipés, rebirths.
-- @param player  Instance joueur
-- @return number  Multiplicateur global
local function getTotalMultiplier(player)
    local data = GameManager.getData(player)
    if not data then return 1 end

    -- 1. Multiplicateur de zone (meilleure zone débloquée)
    local zoneMult = ZoneData.getBestMultiplier(data.unlockedZones)

    -- 2. Multiplicateur des pets équipés
    local petMult = 1
    for _, petId in ipairs(data.equippedPets) do
        local pet = PetData.getPetById(petId)
        if pet then
            petMult = petMult * pet.multiplier
        end
    end

    -- 3. Multiplicateur de rebirth
    local rebirthMult = GameConfig.REBIRTH_EARN_MULTIPLIER ^ data.rebirths

    return zoneMult * petMult * rebirthMult
end

-- ─── Spawn d'une pièce ────────────────────────────────────────────────────────

--- Crée une pièce à la position indiquée.
-- @param position  Vector3
local function spawnCoin(position)
    local coin = Instance.new("Part")
    coin.Name          = "Coin"
    coin.Shape         = Enum.PartType.Cylinder
    coin.Size          = Vector3.new(0.2, 0.8, 0.8)
    coin.BrickColor    = BrickColor.new("Bright yellow")
    coin.Material      = Enum.Material.SmoothPlastic
    coin.CastShadow    = false
    coin.CFrame        = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
    coin.CanCollide    = false
    coin.Parent        = coinsFolder

    -- Suppression automatique après 15 secondes pour éviter l'accumulation
    game:GetService("Debris"):AddItem(coin, 15)

    -- Touché par un joueur → collecte
    coin.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end
        if not coin.Parent then return end  -- déjà collectée

        -- Détache la pièce du monde immédiatement pour éviter les doubles collectes
        coin.Parent = nil

        local gain = math.floor(GameConfig.BASE_MONEY_VALUE * getTotalMultiplier(player))
        if gain < 1 then gain = 1 end
        GameManager.addMoney(player, gain)
    end)

    return coin
end

-- ─── Boucle de spawn ─────────────────────────────────────────────────────────

--- Retourne les positions de spawn d'une zone (cherche dans Workspace.Zones.<zoneId>)
-- Si la zone n'existe pas encore dans le Workspace, retourne des positions par défaut.
local function getZoneSpawnPositions(zoneId)
    local zonesFolder = Workspace:FindFirstChild("Zones")
    if zonesFolder then
        local zoneModel = zonesFolder:FindFirstChild(zoneId)
        if zoneModel then
            local spawnPart = zoneModel:FindFirstChild("CoinSpawns")
            if spawnPart then
                local positions = {}
                for _, part in ipairs(spawnPart:GetChildren()) do
                    if part:IsA("BasePart") then
                        table.insert(positions, part.Position)
                    end
                end
                if #positions > 0 then return positions end
            end
        end
    end
    -- Position par défaut basée sur l'index de la zone
    local index = 1
    for i, zone in ipairs(ZoneData.Zones) do
        if zone.id == zoneId then index = i break end
    end
    local offsetX = (index - 1) * 80
    return {
        Vector3.new(offsetX,      1, 0),
        Vector3.new(offsetX + 10, 1, 0),
        Vector3.new(offsetX - 10, 1, 0),
        Vector3.new(offsetX,      1, 10),
        Vector3.new(offsetX,      1, -10),
    }
end

--- Compte le nombre de pièces actuellement présentes dans le dossier.
local function countCoins()
    return #coinsFolder:GetChildren()
end

task.spawn(function()
    while true do
        task.wait(GameConfig.MONEY_SPAWN_INTERVAL)

        if countCoins() >= GameConfig.MAX_COINS_PER_ZONE then
            continue
        end

        -- Spawn dans chaque zone débloquée par au moins un joueur présent
        local activeZones = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local data = GameManager.getData(player)
            if data then
                for zoneId in pairs(data.unlockedZones) do
                    activeZones[zoneId] = true
                end
            end
        end

        for zoneId in pairs(activeZones) do
            local positions = getZoneSpawnPositions(zoneId)
            local pos = positions[math.random(1, #positions)]
            -- Légère variation aléatoire pour éviter la superposition
            local jitter = Vector3.new(
                math.random(-5, 5),
                0,
                math.random(-5, 5)
            )
            spawnCoin(pos + jitter)
        end
    end
end)
