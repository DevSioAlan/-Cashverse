--[[
    PetSystem.server.lua
    Gère l'éclosion des œufs et l'équipement des Pets.

    RemoteFunction exposés (dans ReplicatedStorage.Remotes) :
      - HatchEgg  : Le client demande à faire éclore un œuf → retourne le Pet obtenu
      - EquipPet  : Le client équipe / déséquipe un Pet
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local PetData    = require(ReplicatedStorage.Modules.PetData)
local GameManager = require(script.Parent.GameManager)

-- Nombre maximum de pets équipés simultanément
local MAX_EQUIPPED_PETS = 3

-- ─── Attente des Remotes créés par GameManager ───────────────────────────────

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local function makeRemoteFunction(name)
    local rf = Instance.new("RemoteFunction")
    rf.Name   = name
    rf.Parent = remotesFolder
    return rf
end

local HatchEggFunc  = makeRemoteFunction("HatchEgg")
local EquipPetFunc  = makeRemoteFunction("EquipPet")

-- ─── Logique d'éclosion ───────────────────────────────────────────────────────

--- Tente de faire éclore un œuf pour le joueur.
-- Coûte GameConfig.BASE_EGG_COST * (1 + nombre de pets possédés * 0.1).
-- @return table|string  Données du Pet obtenu, ou message d'erreur
HatchEggFunc.OnServerInvoke = function(player)
    local data = GameManager.getData(player)
    if not data then
        return nil, "Données introuvables."
    end

    local cost = math.floor(
        GameConfig.BASE_EGG_COST * (1 + #data.pets * 0.1)
    )

    if not GameManager.spendMoney(player, cost) then
        return nil, "Pas assez d'argent ! Il te faut " .. cost .. " 💰."
    end

    local pet = PetData.rollPet()

    -- Ajoute le pet à la liste de l'inventaire du joueur
    table.insert(data.pets, pet.id)

    GameManager.notify(player, "🥚 Tu as obtenu : " .. pet.name .. " [" .. pet.rarity .. "] !")
    GameManager.syncPets(player)

    return pet
end

-- ─── Équipement / déséquipement ───────────────────────────────────────────────

--- Équipe ou déséquipe un Pet pour le joueur.
-- @param player   Instance joueur
-- @param petIndex number  Index dans data.pets (1-based)
-- @return boolean, string  Succès + message
EquipPetFunc.OnServerInvoke = function(player, petIndex)
    local data = GameManager.getData(player)
    if not data then return false, "Données introuvables." end

    if type(petIndex) ~= "number" then
        return false, "Index invalide."
    end

    petIndex = math.floor(petIndex)
    if petIndex < 1 or petIndex > #data.pets then
        return false, "Pet introuvable."
    end

    local petId = data.pets[petIndex]

    -- Vérifie si déjà équipé → déséquiper
    for i, equippedId in ipairs(data.equippedPets) do
        if equippedId == petId then
            table.remove(data.equippedPets, i)
            GameManager.syncPets(player)
            return true, "Pet déséquipé."
        end
    end

    -- Vérifie la limite
    if #data.equippedPets >= MAX_EQUIPPED_PETS then
        return false, "Tu ne peux équiper que " .. MAX_EQUIPPED_PETS .. " Pets à la fois."
    end

    table.insert(data.equippedPets, petId)
    GameManager.syncPets(player)
    return true, "Pet équipé !"
end
