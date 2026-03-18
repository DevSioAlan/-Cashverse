--[[
    GameManager.server.lua
    Script serveur principal de Cashverse.

    Responsabilités :
      - Initialise les données de chaque joueur (argent, rebirths, pets, zones)
      - Gère la sauvegarde et le chargement via DataStoreService
      - Expose les RemoteFunction / RemoteEvent utilisés par les autres systèmes
--]]

local Players            = game:GetService("Players")
local DataStoreService   = game:GetService("DataStoreService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local ZoneData   = require(ReplicatedStorage.Modules.ZoneData)

-- DataStore pour la persistance des données joueur
local playerDataStore = DataStoreService:GetDataStore("CashversePlayerData_v1")

-- ─── Données en mémoire ───────────────────────────────────────────────────────

-- playerData[userId] = { money, totalMoney, rebirths, pets, unlockedZones }
local playerData = {}

-- ─── Valeurs par défaut ───────────────────────────────────────────────────────

local function getDefaultData()
    return {
        money         = 0,
        totalMoney    = 0,   -- Argent total gagné (pour le leaderboard)
        rebirths      = 0,
        pets          = {},  -- Liste d'ids de pets possédés
        equippedPets  = {},  -- Liste d'ids de pets actuellement équipés (max 3)
        unlockedZones = { starter_zone = true },
    }
end

-- ─── Chargement / Sauvegarde ──────────────────────────────────────────────────

local function loadPlayerData(player)
    local userId = tostring(player.UserId)
    local success, data = pcall(function()
        return playerDataStore:GetAsync(userId)
    end)

    if success and data then
        -- Fusion pour ajouter les nouvelles clés sans écraser les données existantes
        local defaults = getDefaultData()
        for key, value in pairs(defaults) do
            if data[key] == nil then
                data[key] = value
            end
        end
        playerData[userId] = data
    else
        playerData[userId] = getDefaultData()
        if not success then
            warn("[GameManager] Erreur chargement données de " .. player.Name .. ": " .. tostring(data))
        end
    end
end

local function savePlayerData(player)
    local userId = tostring(player.UserId)
    local data = playerData[userId]
    if not data then return end

    local success, err = pcall(function()
        playerDataStore:SetAsync(userId, data)
    end)
    if not success then
        warn("[GameManager] Erreur sauvegarde données de " .. player.Name .. ": " .. tostring(err))
    end
end

-- ─── Leaderstats (affichage Roblox intégré) ───────────────────────────────────

local function setupLeaderstats(player)
    local userId = tostring(player.UserId)
    local data = playerData[userId]

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local moneyVal = Instance.new("NumberValue")
    moneyVal.Name  = "💰 Argent"
    moneyVal.Value = data.money
    moneyVal.Parent = leaderstats

    local rebirthVal = Instance.new("NumberValue")
    rebirthVal.Name  = "⚡ Rebirths"
    rebirthVal.Value = data.rebirths
    rebirthVal.Parent = leaderstats
end

-- Met à jour les leaderstats d'un joueur depuis ses données en mémoire
local function updateLeaderstats(player)
    local userId = tostring(player.UserId)
    local data = playerData[userId]
    if not data then return end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local moneyVal  = leaderstats:FindFirstChild("💰 Argent")
    local rebirthVal = leaderstats:FindFirstChild("⚡ Rebirths")

    if moneyVal  then moneyVal.Value  = data.money    end
    if rebirthVal then rebirthVal.Value = data.rebirths end
end

-- ─── RemoteEvents / RemoteFunctions ──────────────────────────────────────────

-- Création d'un dossier dédié dans ReplicatedStorage pour les remotes
local remotesFolder = Instance.new("Folder")
remotesFolder.Name   = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function makeRemoteEvent(name)
    local re = Instance.new("RemoteEvent")
    re.Name   = name
    re.Parent = remotesFolder
    return re
end

local function makeRemoteFunction(name)
    local rf = Instance.new("RemoteFunction")
    rf.Name   = name
    rf.Parent = remotesFolder
    return rf
end

-- Événements émis vers les clients
local UpdateMoneyEvent   = makeRemoteEvent("UpdateMoney")
local UpdateRebirthEvent = makeRemoteEvent("UpdateRebirth")
local UpdateZonesEvent   = makeRemoteEvent("UpdateZones")
local UpdatePetsEvent    = makeRemoteEvent("UpdatePets")
local NotifyEvent        = makeRemoteEvent("Notify")

-- Fonctions appelées par les clients
local GetPlayerDataFunc  = makeRemoteFunction("GetPlayerData")

-- ─── API publique (utilisée par les autres scripts serveur) ───────────────────

local GameManager = {}

--- Retourne les données d'un joueur (table directe, pas de copie).
function GameManager.getData(player)
    return playerData[tostring(player.UserId)]
end

--- Ajoute de l'argent à un joueur et met à jour ses statistiques.
-- @param player  Instance joueur
-- @param amount  Montant à ajouter (peut être fractionnaire)
function GameManager.addMoney(player, amount)
    local userId = tostring(player.UserId)
    local data = playerData[userId]
    if not data then return end

    data.money      = data.money      + amount
    data.totalMoney = data.totalMoney + amount
    updateLeaderstats(player)
    UpdateMoneyEvent:FireClient(player, data.money)
end

--- Dépense de l'argent d'un joueur. Retourne true si la transaction réussit.
function GameManager.spendMoney(player, amount)
    local userId = tostring(player.UserId)
    local data = playerData[userId]
    if not data then return false end
    if data.money < amount then return false end

    data.money = data.money - amount
    updateLeaderstats(player)
    UpdateMoneyEvent:FireClient(player, data.money)
    return true
end

--- Notifie le client d'un joueur avec un message.
function GameManager.notify(player, message)
    NotifyEvent:FireClient(player, message)
end

--- Force la synchronisation des données pets vers le client.
function GameManager.syncPets(player)
    local data = GameManager.getData(player)
    if data then
        UpdatePetsEvent:FireClient(player, data.pets, data.equippedPets)
    end
end

--- Force la synchronisation des zones vers le client.
function GameManager.syncZones(player)
    local data = GameManager.getData(player)
    if data then
        UpdateZonesEvent:FireClient(player, data.unlockedZones)
    end
end

-- ─── Gestion connexion / déconnexion ─────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    loadPlayerData(player)
    setupLeaderstats(player)

    -- Synchronise toutes les données avec le nouveau client une fois l'UI chargée
    player.CharacterAdded:Connect(function()
        task.wait(1) -- laisser l'UI cliente s'initialiser
        local data = playerData[tostring(player.UserId)]
        if data then
            UpdateMoneyEvent:FireClient(player, data.money)
            UpdateRebirthEvent:FireClient(player, data.rebirths)
            UpdateZonesEvent:FireClient(player, data.unlockedZones)
            UpdatePetsEvent:FireClient(player, data.pets, data.equippedPets)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerData[tostring(player.UserId)] = nil
end)

-- ─── Sauvegarde automatique ───────────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(GameConfig.SAVE_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

-- ─── RemoteFunction : récupérer ses propres données ──────────────────────────

GetPlayerDataFunc.OnServerInvoke = function(player)
    local data = playerData[tostring(player.UserId)]
    if not data then return nil end
    -- Retourne une copie sécurisée (sans référence directe)
    return {
        money         = data.money,
        totalMoney    = data.totalMoney,
        rebirths      = data.rebirths,
        pets          = data.pets,
        equippedPets  = data.equippedPets,
        unlockedZones = data.unlockedZones,
    }
end

-- Fermeture propre du serveur
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
end)

return GameManager
