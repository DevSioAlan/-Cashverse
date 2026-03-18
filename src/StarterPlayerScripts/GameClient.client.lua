--[[
    GameClient.client.lua
    Script client principal de Cashverse.

    Responsabilités :
      - Écoute les RemoteEvents du serveur pour mettre à jour l'état local
      - Gère les appuis sur les boutons de l'UI (HatchEgg, Rebirth, UnlockZone, EquipPet)
      - Affiche les notifications flottantes
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

-- ─── Remotes ─────────────────────────────────────────────────────────────────

local remotesFolder    = ReplicatedStorage:WaitForChild("Remotes")

local UpdateMoneyEvent   = remotesFolder:WaitForChild("UpdateMoney")
local UpdateRebirthEvent = remotesFolder:WaitForChild("UpdateRebirth")
local UpdateZonesEvent   = remotesFolder:WaitForChild("UpdateZones")
local UpdatePetsEvent    = remotesFolder:WaitForChild("UpdatePets")
local NotifyEvent        = remotesFolder:WaitForChild("Notify")

local GetPlayerDataFunc  = remotesFolder:WaitForChild("GetPlayerData")
local HatchEggFunc       = remotesFolder:WaitForChild("HatchEgg")
local EquipPetFunc       = remotesFolder:WaitForChild("EquipPet")
local RequestRebirthFunc = remotesFolder:WaitForChild("RequestRebirth")
local UnlockZoneFunc     = remotesFolder:WaitForChild("UnlockZone")

-- ─── État local ──────────────────────────────────────────────────────────────

local localMoney    = 0
local localRebirths = 0
local localPets     = {}
local localEquipped = {}
local localZones    = {}

-- ─── Référence à l'UI ────────────────────────────────────────────────────────

-- L'UI est définie dans StarterGui/ScreenGui/MainUI
local screenGui = playerGui:WaitForChild("CashverseUI", 10)

-- Fonctions de mise à jour de l'UI (définies après création de l'UI si présente)
local function getLabel(name)
    if not screenGui then return nil end
    return screenGui:FindFirstChild(name, true)
end

-- ─── Formatage de l'argent ───────────────────────────────────────────────────

local suffixes = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"}

local function formatMoney(amount)
    if amount < 1000 then
        return tostring(math.floor(amount))
    end
    local tier = math.floor(math.log(amount, 1000))
    tier = math.min(tier, #suffixes)
    local scaled = amount / (1000 ^ tier)
    return string.format("%.2f%s", scaled, suffixes[tier])
end

-- ─── Mise à jour de l'UI ─────────────────────────────────────────────────────

local function refreshMoneyLabel()
    local label = getLabel("MoneyLabel")
    if label then
        label.Text = "💰 " .. formatMoney(localMoney)
    end
end

local function refreshRebirthLabel()
    local label = getLabel("RebirthLabel")
    if label then
        label.Text = "⚡ Rebirths : " .. localRebirths
    end
end

-- ─── Notifications flottantes ─────────────────────────────────────────────────

local notificationQueue = {}
local isShowingNotification = false

local function showNextNotification()
    if isShowingNotification or #notificationQueue == 0 then return end
    isShowingNotification = true

    local message = table.remove(notificationQueue, 1)

    local notifLabel = getLabel("NotifLabel")
    if not notifLabel then
        isShowingNotification = false
        return
    end

    notifLabel.Text    = message
    notifLabel.Visible = true
    notifLabel.TextTransparency = 0

    local fadeOut = TweenService:Create(
        notifLabel,
        TweenInfo.new(0.5, Enum.EasingStyle.Linear),
        {TextTransparency = 1}
    )

    task.delay(2.5, function()
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            notifLabel.Visible = false
            isShowingNotification = false
            showNextNotification()
        end)
    end)
end

local function queueNotification(message)
    table.insert(notificationQueue, message)
    showNextNotification()
end

-- ─── Écoute des RemoteEvents ─────────────────────────────────────────────────

UpdateMoneyEvent.OnClientEvent:Connect(function(money)
    localMoney = money
    refreshMoneyLabel()
end)

UpdateRebirthEvent.OnClientEvent:Connect(function(rebirths)
    localRebirths = rebirths
    refreshRebirthLabel()
end)

UpdateZonesEvent.OnClientEvent:Connect(function(zones)
    localZones = zones
end)

UpdatePetsEvent.OnClientEvent:Connect(function(pets, equipped)
    localPets    = pets    or {}
    localEquipped = equipped or {}
end)

NotifyEvent.OnClientEvent:Connect(function(message)
    queueNotification(message)
end)

-- ─── Initialisation depuis le serveur ────────────────────────────────────────

task.spawn(function()
    local data = GetPlayerDataFunc:InvokeServer()
    if data then
        localMoney    = data.money    or 0
        localRebirths = data.rebirths or 0
        localPets     = data.pets     or {}
        localEquipped = data.equippedPets or {}
        localZones    = data.unlockedZones or {}
        refreshMoneyLabel()
        refreshRebirthLabel()
    end
end)

-- ─── Connexion des boutons ────────────────────────────────────────────────────

-- Ces connexions sont optionnelles : elles s'établissent si les boutons existent dans l'UI.

local function connectButton(buttonName, callback)
    local btn = getLabel(buttonName)
    if btn and btn:IsA("GuiButton") then
        btn.Activated:Connect(callback)
    end
end

-- Bouton "Éclore un œuf"
connectButton("HatchButton", function()
    local pet, err = HatchEggFunc:InvokeServer()
    if not pet then
        queueNotification("❌ " .. (err or "Erreur inconnue"))
    end
end)

-- Bouton "Rebirth"
connectButton("RebirthButton", function()
    local success, result = RequestRebirthFunc:InvokeServer()
    if not success then
        queueNotification("❌ " .. (result or "Rebirth impossible."))
    end
end)

-- Bouton "Débloquer la prochaine zone"
connectButton("UnlockZoneButton", function()
    -- Trouve la première zone non débloquée
    local ZoneData = require(ReplicatedStorage.Modules.ZoneData)
    local nextZone = ZoneData.getNextZone(localZones)
    if not nextZone then
        queueNotification("🌍 Toutes les zones sont débloquées !")
        return
    end
    local success, result = UnlockZoneFunc:InvokeServer(nextZone.id)
    if not success then
        queueNotification("❌ " .. (result or "Impossible de débloquer la zone."))
    end
end)
