--[[
    GameConfig.lua
    Configuration globale du jeu Cashverse.
    Modifie ces valeurs pour équilibrer le jeu.
--]]

local GameConfig = {}

-- ─── Argent ──────────────────────────────────────────────────────────────────

-- Valeur de base d'une pièce au sol (avant multiplicateurs)
GameConfig.BASE_MONEY_VALUE = 1

-- Intervalle (en secondes) entre deux spawns de pièces dans une zone
GameConfig.MONEY_SPAWN_INTERVAL = 0.5

-- Nombre maximum de pièces présentes dans une zone au même moment
GameConfig.MAX_COINS_PER_ZONE = 50

-- ─── Rebirth ─────────────────────────────────────────────────────────────────

-- Argent requis pour effectuer le premier Rebirth
GameConfig.BASE_REBIRTH_COST = 1000

-- Multiplicateur appliqué au coût de chaque Rebirth suivant
GameConfig.REBIRTH_COST_MULTIPLIER = 2.5

-- Bonus de gains accordé par chaque Rebirth (multiplicateur cumulatif)
GameConfig.REBIRTH_EARN_MULTIPLIER = 1.5

-- ─── Pets ────────────────────────────────────────────────────────────────────

-- Coût en argent pour tenter d'éclore un œuf commun
GameConfig.BASE_EGG_COST = 100

-- ─── Classement ──────────────────────────────────────────────────────────────

-- Nombre de joueurs affichés dans le leaderboard global
GameConfig.LEADERBOARD_SIZE = 100

-- Intervalle (en secondes) entre deux mises à jour du leaderboard
GameConfig.LEADERBOARD_UPDATE_INTERVAL = 60

-- ─── Sauvegarde ──────────────────────────────────────────────────────────────

-- Intervalle (en secondes) entre deux sauvegardes automatiques
GameConfig.SAVE_INTERVAL = 60

-- ─── Interface ───────────────────────────────────────────────────────────────

-- Couleur principale de l'UI (BrickColor string)
GameConfig.UI_PRIMARY_COLOR = Color3.fromRGB(255, 215, 0)   -- Or
GameConfig.UI_SECONDARY_COLOR = Color3.fromRGB(30, 30, 45)  -- Fond sombre

return GameConfig
