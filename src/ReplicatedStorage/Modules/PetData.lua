--[[
    PetData.lua
    Données de tous les Pets disponibles dans Cashverse.

    Chaque Pet a :
      - name        : Nom affiché
      - rarity      : "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
      - chance      : Probabilité d'éclosion (0-1, doit être cohérent avec la rareté)
      - multiplier  : Multiplicateur de gains appliqué lorsque le Pet est équipé
      - description : Description affichée dans l'UI
--]]

local PetData = {}

-- ─── Probabilités de rareté par défaut ───────────────────────────────────────

PetData.RarityChance = {
    Common    = 0.50,   -- 50 %
    Uncommon  = 0.30,   -- 30 %
    Rare      = 0.12,   -- 12 %
    Epic      = 0.06,   --  6 %
    Legendary = 0.02,   --  2 %
}

-- ─── Couleurs associées aux raretés ──────────────────────────────────────────

PetData.RarityColor = {
    Common    = Color3.fromRGB(180, 180, 180), -- Gris
    Uncommon  = Color3.fromRGB(30,  200,  30), -- Vert
    Rare      = Color3.fromRGB(50,  100, 255), -- Bleu
    Epic      = Color3.fromRGB(160,  50, 255), -- Violet
    Legendary = Color3.fromRGB(255, 165,   0), -- Or
}

-- ─── Liste des Pets ──────────────────────────────────────────────────────────

PetData.Pets = {
    {
        id          = "coin_mouse",
        name        = "Souris Monnaie",
        rarity      = "Common",
        chance      = PetData.RarityChance.Common,
        multiplier  = 1.10,
        description = "Un petit rongeur qui renifle les pièces.",
    },
    {
        id          = "lucky_cat",
        name        = "Chat Chanceux",
        rarity      = "Common",
        chance      = PetData.RarityChance.Common,
        multiplier  = 1.15,
        description = "Sa patte levée attire la fortune.",
    },
    {
        id          = "golden_frog",
        name        = "Grenouille Dorée",
        rarity      = "Uncommon",
        chance      = PetData.RarityChance.Uncommon,
        multiplier  = 1.30,
        description = "Croasse de l'or à chaque bond.",
    },
    {
        id          = "money_bee",
        name        = "Abeille Argentée",
        rarity      = "Uncommon",
        chance      = PetData.RarityChance.Uncommon,
        multiplier  = 1.35,
        description = "Butine les billets dans les airs.",
    },
    {
        id          = "diamond_wolf",
        name        = "Loup Diamant",
        rarity      = "Rare",
        chance      = PetData.RarityChance.Rare,
        multiplier  = 1.60,
        description = "Ses crocs brillent comme des diamants.",
    },
    {
        id          = "thunder_eagle",
        name        = "Aigle Tonnerre",
        rarity      = "Rare",
        chance      = PetData.RarityChance.Rare,
        multiplier  = 1.70,
        description = "Fond sur les pièces à la vitesse de l'éclair.",
    },
    {
        id          = "cosmic_dragon",
        name        = "Dragon Cosmique",
        rarity      = "Epic",
        chance      = PetData.RarityChance.Epic,
        multiplier  = 2.20,
        description = "Crache des pièces en feu cosmique.",
    },
    {
        id          = "void_phoenix",
        name        = "Phénix du Néant",
        rarity      = "Epic",
        chance      = PetData.RarityChance.Epic,
        multiplier  = 2.50,
        description = "Renaît de ses cendres en doublant votre fortune.",
    },
    {
        id          = "galaxy_titan",
        name        = "Titan Galactique",
        rarity      = "Legendary",
        chance      = PetData.RarityChance.Legendary,
        multiplier  = 5.00,
        description = "Le maître ultime de la richesse galactique.",
    },
}

-- ─── Utilitaires ─────────────────────────────────────────────────────────────

--- Retourne un Pet aléatoire selon les probabilités définies.
-- @return table  La définition du Pet tiré au sort.
function PetData.rollPet()
    local roll = math.random()
    local cumulative = 0
    -- On parcourt du plus rare au plus commun pour un tirage précis
    local order = {"Legendary", "Epic", "Rare", "Uncommon", "Common"}
    for _, rarity in ipairs(order) do
        cumulative = cumulative + PetData.RarityChance[rarity]
        if roll <= cumulative then
            -- Collecte tous les pets de cette rareté
            local candidates = {}
            for _, pet in ipairs(PetData.Pets) do
                if pet.rarity == rarity then
                    table.insert(candidates, pet)
                end
            end
            if #candidates > 0 then
                return candidates[math.random(1, #candidates)]
            end
        end
    end
    -- Fallback : premier pet commun
    return PetData.Pets[1]
end

--- Retourne la définition d'un Pet par son id.
-- @param id string  L'identifiant du Pet.
-- @return table|nil
function PetData.getPetById(id)
    for _, pet in ipairs(PetData.Pets) do
        if pet.id == id then
            return pet
        end
    end
    return nil
end

return PetData
