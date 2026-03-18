--[[
    MainUI.lua  (StarterGui > CashverseUI)
    Crée et configure l'interface utilisateur principale de Cashverse.

    Hiérarchie créée :
      CashverseUI (ScreenGui)
        ├── TopBar          – Barre du haut (argent, rebirths)
        │   ├── MoneyLabel
        │   └── RebirthLabel
        ├── ActionPanel     – Panneau d'actions (boutons principaux)
        │   ├── HatchButton
        │   ├── RebirthButton
        │   └── UnlockZoneButton
        ├── NotifLabel      – Notification flottante (bas de l'écran)
        └── LeaderboardFrame – Cadre du classement (droite)
--]]

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Utilitaires ─────────────────────────────────────────────────────────────

local function newInstance(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    return inst
end

local function newLabel(properties)
    return newInstance("TextLabel", properties)
end

local function newButton(properties)
    return newInstance("TextButton", properties)
end

local function newFrame(properties)
    return newInstance("Frame", properties)
end

-- Couleurs de la charte graphique
local COLOR_GOLD       = Color3.fromRGB(255, 215,   0)
local COLOR_DARK       = Color3.fromRGB( 20,  20,  35)
local COLOR_DARK_PANEL = Color3.fromRGB( 30,  30,  50)
local COLOR_BTN_GREEN  = Color3.fromRGB( 50, 180,  80)
local COLOR_BTN_PURPLE = Color3.fromRGB(130,  60, 220)
local COLOR_BTN_BLUE   = Color3.fromRGB( 50, 130, 220)
local COLOR_WHITE      = Color3.fromRGB(255, 255, 255)

-- ─── ScreenGui ────────────────────────────────────────────────────────────────

local screenGui = newInstance("ScreenGui", {
    Name             = "CashverseUI",
    ResetOnSpawn     = false,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    Parent           = playerGui,
})

-- ─── TopBar ──────────────────────────────────────────────────────────────────

local topBar = newFrame({
    Name              = "TopBar",
    Size              = UDim2.new(1, 0, 0, 60),
    Position          = UDim2.new(0, 0, 0, 0),
    BackgroundColor3  = COLOR_DARK,
    BackgroundTransparency = 0.2,
    BorderSizePixel   = 0,
    Parent            = screenGui,
})

newInstance("UIGradient", {
    Color  = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLOR_DARK),
        ColorSequenceKeypoint.new(1, COLOR_DARK_PANEL),
    }),
    Rotation = 90,
    Parent   = topBar,
})

local moneyLabel = newLabel({
    Name              = "MoneyLabel",
    Size              = UDim2.new(0.5, 0, 1, 0),
    Position          = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text              = "💰 0",
    TextColor3        = COLOR_GOLD,
    TextScaled        = true,
    Font              = Enum.Font.GothamBold,
    TextXAlignment    = Enum.TextXAlignment.Left,
    Parent            = topBar,
})

local rebirthLabel = newLabel({
    Name              = "RebirthLabel",
    Size              = UDim2.new(0.4, 0, 1, 0),
    Position          = UDim2.new(0.55, 0, 0, 0),
    BackgroundTransparency = 1,
    Text              = "⚡ Rebirths : 0",
    TextColor3        = Color3.fromRGB(180, 150, 255),
    TextScaled        = true,
    Font              = Enum.Font.GothamBold,
    TextXAlignment    = Enum.TextXAlignment.Right,
    Parent            = topBar,
})

-- ─── ActionPanel ─────────────────────────────────────────────────────────────

local actionPanel = newFrame({
    Name              = "ActionPanel",
    Size              = UDim2.new(0, 200, 0, 170),
    Position          = UDim2.new(0, 10, 0.5, -85),
    BackgroundColor3  = COLOR_DARK_PANEL,
    BackgroundTransparency = 0.3,
    BorderSizePixel   = 0,
    Parent            = screenGui,
})

newInstance("UICorner",    { CornerRadius = UDim.new(0, 12), Parent = actionPanel })
newInstance("UIPadding",   { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8),
                              PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8), Parent = actionPanel })
newInstance("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder,
                               Padding = UDim.new(0, 8), Parent = actionPanel })

local function createActionButton(name, text, color, layoutOrder)
    local btn = newButton({
        Name              = name,
        Size              = UDim2.new(1, 0, 0, 44),
        BackgroundColor3  = color,
        Text              = text,
        TextColor3        = COLOR_WHITE,
        TextScaled        = true,
        Font              = Enum.Font.GothamBold,
        LayoutOrder       = layoutOrder,
        AutoButtonColor   = false,
        Parent            = actionPanel,
    })
    newInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

    -- Animation hover
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = color:Lerp(COLOR_WHITE, 0.15)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = color
        }):Play()
    end)

    return btn
end

createActionButton("HatchButton",      "🥚 Éclore un Œuf",          COLOR_BTN_GREEN,  1)
createActionButton("RebirthButton",    "⚡ Rebirth",                  COLOR_BTN_PURPLE, 2)
createActionButton("UnlockZoneButton", "🌍 Débloquer une Zone",       COLOR_BTN_BLUE,   3)

-- ─── Notification flottante ───────────────────────────────────────────────────

local notifLabel = newLabel({
    Name              = "NotifLabel",
    Size              = UDim2.new(0.5, 0, 0, 48),
    Position          = UDim2.new(0.25, 0, 0.85, 0),
    BackgroundColor3  = COLOR_DARK,
    BackgroundTransparency = 0.3,
    Text              = "",
    TextColor3        = COLOR_WHITE,
    TextScaled        = true,
    Font              = Enum.Font.GothamBold,
    Visible           = false,
    Parent            = screenGui,
})
newInstance("UICorner",  { CornerRadius = UDim.new(0, 10), Parent = notifLabel })

-- ─── Leaderboard (panneau droite) ────────────────────────────────────────────

local lbFrame = newFrame({
    Name              = "LeaderboardFrame",
    Size              = UDim2.new(0, 220, 0, 320),
    Position          = UDim2.new(1, -230, 0, 70),
    BackgroundColor3  = COLOR_DARK_PANEL,
    BackgroundTransparency = 0.3,
    BorderSizePixel   = 0,
    Parent            = screenGui,
})
newInstance("UICorner", { CornerRadius = UDim.new(0, 12), Parent = lbFrame })

newLabel({
    Name              = "LeaderboardTitle",
    Size              = UDim2.new(1, 0, 0, 36),
    Position          = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Text              = "🏆 Classement",
    TextColor3        = COLOR_GOLD,
    TextScaled        = true,
    Font              = Enum.Font.GothamBold,
    Parent            = lbFrame,
})

local lbScrollFrame = newInstance("ScrollingFrame", {
    Name              = "LBScroll",
    Size              = UDim2.new(1, -10, 1, -44),
    Position          = UDim2.new(0, 5, 0, 40),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    CanvasSize        = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent            = lbFrame,
})
newInstance("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder,
                               Padding = UDim.new(0, 2), Parent = lbScrollFrame })

-- Mise à jour périodique du leaderboard depuis ReplicatedStorage.LeaderboardData
local leaderboardData = game:GetService("ReplicatedStorage"):FindFirstChild("LeaderboardData")

local function refreshLeaderboard()
    if not leaderboardData then return end

    -- Efface les lignes existantes
    for _, child in ipairs(lbScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local entries = leaderboardData:GetChildren()
    table.sort(entries, function(a, b)
        local ra = a:FindFirstChild("Rank")
        local rb = b:FindFirstChild("Rank")
        return (ra and ra.Value or 999) < (rb and rb.Value or 999)
    end)

    for _, entry in ipairs(entries) do
        local rank     = entry:FindFirstChild("Rank")
        local username = entry:FindFirstChild("Username")
        local score    = entry:FindFirstChild("Score")
        if rank and username and score then
            local suffix = ""
            if rank.Value == 1 then suffix = " 🥇"
            elseif rank.Value == 2 then suffix = " 🥈"
            elseif rank.Value == 3 then suffix = " 🥉"
            end

            local scoreFormatted = tostring(math.floor(score.Value))
            if score.Value >= 1e6 then
                scoreFormatted = string.format("%.1fM", score.Value / 1e6)
            elseif score.Value >= 1000 then
                scoreFormatted = string.format("%.1fK", score.Value / 1000)
            end

            newLabel({
                Name              = "LBEntry" .. rank.Value,
                Size              = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                Text              = string.format("#%d %s — %s💰%s",
                    rank.Value, username.Value, scoreFormatted, suffix),
                TextColor3        = COLOR_WHITE,
                TextScaled        = true,
                Font              = Enum.Font.Gotham,
                LayoutOrder       = rank.Value,
                Parent            = lbScrollFrame,
            })
        end
    end
end

-- Rafraîchissement toutes les 30 secondes côté client
if leaderboardData then
    leaderboardData.ChildAdded:Connect(refreshLeaderboard)
    leaderboardData.ChildRemoved:Connect(refreshLeaderboard)
    refreshLeaderboard()
end

task.spawn(function()
    while true do
        task.wait(30)
        refreshLeaderboard()
    end
end)
