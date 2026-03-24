# 🌌 Cashverse Simulator - Core Backend Systems

> **Note :** Ce dépôt contient les extraits des scripts serveurs (Backend) d'un jeu de type "Simulator" développé sur Roblox Studio par Alan. L'objectif est de mettre en avant l'architecture logicielle, la sécurité et la logique algorithmique derrière les mécaniques du jeu.

## 🚀 À propos du projet
**Cashverse Simulator** est une expérience Roblox immersive gérée par une architecture serveur robuste en **Luau**. Contrairement à une simple vitrine, ce projet démontre ma capacité à gérer des flux de données complexes, à concevoir des algorithmes mathématiques (probabilités) et à sécuriser un environnement multijoueur contre les failles courantes.

---

## ✨ Fonctionnalités Backend Clés

* 📦 **Persistance des Données (DataStoreService) :** Sauvegarde et chargement asynchrone de tables complexes (inventaires, statistiques, paramètres) avec gestion des erreurs (`pcall`) pour éviter les pertes de données.
* 🎲 **Algorithmique & Probabilités (Gacha/Eggs) :** Système d'éclosion d'œufs basé sur un **RNG pondéré**, altéré dynamiquement en temps réel par les multiplicateurs de "Chance" du joueur.
* 🛡️ **Anti-Cheat Serveur (Watchdog) :** Système de sécurité personnalisé écoutant les altérations de physique côté client (ex: *WalkSpeed exploits*) et appliquant une correction autoritaire depuis le serveur.
* ⏳ **Économie Asynchrone :** Gestion de coffres de récompenses avec des temps de recharge basés sur le temps universel (`os.time()`), garantissant que les chronomètres continuent de tourner même hors-ligne.
* 💳 **Monétisation (MarketplaceService) :** Intégration sécurisée et vérification côté serveur des achats de *Gamepasses* et de *Developer Products*.

---

## 💻 Code Highlights (Extraits Choisis)

### 1. Sécurité : Garde du Corps Anti-Exploit (WalkSpeed)
Les tricheurs modifient souvent leur vitesse côté client. Ce script attribue une vitesse légitime au joueur et écoute toute modification non autorisée pour appliquer une riposte immédiate.

```lua
local function UpdateWalkspeed(player)
    local char = player.Character
    local hum = char and char:WaitForChild("Humanoid", 5)
    if not hum then return end

    -- Calcul de la vitesse légitime (Base + Upgrades + Gamepasses)
    local finalSpeed = 16 + (player.Upgrades.WalkspeedValue.Value * 2)
    if player.Gamepasses.DoubleSpeed.Value then finalSpeed = finalSpeed * 2 end

    -- Mémorisation sécurisée de la vitesse autorisée
    hum:SetAttribute("VitesseVoulue", finalSpeed)
    hum.WalkSpeed = finalSpeed

    -- Watchdog : Annule toute modification non autorisée (Exploits)
    if not hum:GetAttribute("GardeDuCorpsActif") then
        hum:SetAttribute("GardeDuCorpsActif", true)

        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            local vitesseVoulue = hum:GetAttribute("VitesseVoulue")
            
            -- Bypass autorisé uniquement pour les commandes Admin
            if char:GetAttribute("AdminSpeed") then return end

            -- Riposte immédiate si le client a forcé une nouvelle vitesse
            if vitesseVoulue and hum.WalkSpeed ~= vitesseVoulue then
                warn("⚠️ INTRUSION DÉTECTÉE : Retour forcé à la vitesse serveur.")
                hum.WalkSpeed = vitesseVoulue
            end
        end)
    end
end
