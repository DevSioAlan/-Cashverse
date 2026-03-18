--[[
    LeaderboardSystem.server.lua
    Gère le classement global (OrderedDataStore) de Cashverse.

    Fonctionnement :
      - Met à jour l'OrderedDataStore "TotalMoney" à chaque mise à jour périodique
      - Publie le top N dans ReplicatedStorage.LeaderboardData pour l'affichage client
--]]

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage.Modules.GameConfig)
local GameManager = require(script.Parent.GameManager)

-- OrderedDataStore pour le classement global (argent total gagné)
local leaderboardStore = DataStoreService:GetOrderedDataStore("CashverseTotalMoney_v1")

-- Dossier pour transmettre le classement aux clients
local leaderboardData = Instance.new("Folder")
leaderboardData.Name   = "LeaderboardData"
leaderboardData.Parent = ReplicatedStorage

-- ─── Mise à jour du classement ───────────────────────────────────────────────

local function updateLeaderboard()
    -- 1. Met à jour les scores des joueurs présents
    for _, player in ipairs(Players:GetPlayers()) do
        local data = GameManager.getData(player)
        if data then
            local success, err = pcall(function()
                leaderboardStore:SetAsync(tostring(player.UserId), math.floor(data.totalMoney))
            end)
            if not success then
                warn("[Leaderboard] Erreur mise à jour score de " .. player.Name .. ": " .. tostring(err))
            end
        end
    end

    -- 2. Récupère le top N
    local success, pages = pcall(function()
        return leaderboardStore:GetSortedAsync(false, GameConfig.LEADERBOARD_SIZE)
    end)
    if not success then
        warn("[Leaderboard] Erreur récupération classement: " .. tostring(pages))
        return
    end

    -- 3. Publie dans ReplicatedStorage (efface les anciennes entrées)
    for _, child in ipairs(leaderboardData:GetChildren()) do
        child:Destroy()
    end

    local rank = 1
    local currentPage = pages:GetCurrentPage()
    for _, entry in ipairs(currentPage) do
        local entryFolder = Instance.new("Folder")
        entryFolder.Name   = tostring(rank)
        entryFolder.Parent = leaderboardData

        local rankVal = Instance.new("NumberValue")
        rankVal.Name   = "Rank"
        rankVal.Value  = rank
        rankVal.Parent = entryFolder

        local userIdVal = Instance.new("NumberValue")
        userIdVal.Name   = "UserId"
        userIdVal.Value  = tonumber(entry.key) or 0
        userIdVal.Parent = entryFolder

        local scoreVal = Instance.new("NumberValue")
        scoreVal.Name   = "Score"
        scoreVal.Value  = entry.value
        scoreVal.Parent = entryFolder

        -- Tente de résoudre le nom d'utilisateur
        local nameVal = Instance.new("StringValue")
        nameVal.Name   = "Username"
        nameVal.Value  = "[joueur]"
        nameVal.Parent = entryFolder

        local ok, name = pcall(function()
            return Players:GetNameFromUserIdAsync(entry.key)
        end)
        if ok then
            nameVal.Value = name
        end

        rank = rank + 1
    end
end

-- ─── Boucle de mise à jour ────────────────────────────────────────────────────

task.spawn(function()
    -- Première mise à jour après une courte attente (laisser GameManager s'initialiser)
    task.wait(10)
    updateLeaderboard()

    while true do
        task.wait(GameConfig.LEADERBOARD_UPDATE_INTERVAL)
        updateLeaderboard()
    end
end)
