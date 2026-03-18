-- --- EXTRAIT : Système de Récompenses Journalières & Cooldowns Temps Réel ---
-- Utilisation de os.time() et des DataStores pour des timers persistants
local tempsActuel = os.time()
local attenteDaily = 86400 -- 24 Heures en secondes

-- Vérification du pass VIP pour réduire le délai d'attente
if gamepasses:FindFirstChild("FastChests") and gamepasses.FastChests.Value then
    attenteDaily = attenteDaily / 2
end

if cooldownsDaily[userId] then
    -- Calcul du temps écoulé même si le joueur a quitté le jeu
    local tempsRestantDaily = attenteDaily - (tempsActuel - cooldownsDaily[userId])

    -- Validation de la distance (magnitude) et du temps
    if tempsRestantDaily <= 0 and (rootPart.Position - ZoneDaily.Position).Magnitude <= 10 then
        cooldownsDaily[userId] = tempsActuel -- Reset du timer
        
        -- Récupération dynamique du multiplicateur selon la zone actuelle du joueur
        local saZone = playerStats.HighestZone.Value
        local multiplicateur = ZoneModule.MapValues[saZone].Common
        
        local gainFinal = Config.Daily.BaseRecompense * multiplicateur
        leaderstats.Money.Value += gainFinal
    end
end
