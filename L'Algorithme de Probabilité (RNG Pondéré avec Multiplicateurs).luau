-- --- EXTRAIT : Système d'Éclosion (Hatching) & RNG Pondéré ---
-- Calcule le familier obtenu en fonction de sa rareté et de la chance du joueur
function RandomPet(Player, Pets)
    local luckMulti = 1

    -- Vérification dynamique des multiplicateurs de chance (Gamepasses)
    if Player and Player:FindFirstChild("Gamepasses") then
        local gp = Player.Gamepasses
        if gp:FindFirstChild("Lucky") and gp.Lucky.Value then luckMulti = luckMulti * 2 end
        if gp:FindFirstChild("SuperLucky") and gp.SuperLucky.Value then luckMulti = luckMulti * 3 end
        if gp:FindFirstChild("UltraLucky") and gp.UltraLucky.Value then luckMulti = luckMulti * 5 end
    end

    local Weight = 0
    local tempWeights = {}

    -- Calcul du poids total (Weight) en altérant les raretés selon la chance
    for Name, Pet in pairs(Pets) do
        local petWeight = Pet.Rarity
        if petWeight < 50 then 
            petWeight = petWeight * luckMulti -- Boost uniquement les pets rares
        end
        Weight += petWeight
        tempWeights[Name] = petWeight
    end

    -- Algorithme de tirage au sort pondéré
    local Chance = math.random(1, Weight)
    local Counter = 0
    for Name, weight in pairs(tempWeights) do
        Counter += weight
        if Counter >= Chance then
            return Pets[Name], Name
        end
    end
end
