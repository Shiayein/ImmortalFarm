-- ImmortalFarm_Tokyo_Min.lua
-- Exemple minimal utilisant TokyoLib_Slim.lua
-- GUI réduit : 1 fenêtre, 1 onglet, 1 section, 2 toggles, 1 indicateur "💵 Gagné".

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Chargement de la lib slim (assure-toi d'avoir TokyoLib_Slim.lua + Tokyo Lib Source.lua à côté)
local lib_src = readfile("TokyoLib_Slim.lua")
local load_slim = loadstring(lib_src)
local library = load_slim({ cheatname = "ImmortalFarm", gamename = "Da Hood" })

library:init() -- init obligatoire

-- === Variables d'état côté farm (adapte avec tes vraies variables/liaisons) ===
getgenv().autofarmOn = false
getgenv().hackPOVOn  = false

local startCash = 0
local currentCashValue = nil -- remplace par ta référence (leaderstats / Stat Value / etc.)

-- Essaie d'accrocher une stat "Cash" classique (à adapter si besoin)
pcall(function()
    local ls = LocalPlayer:WaitForChild("leaderstats", 3)
    if ls then
        currentCashValue = ls:FindFirstChild("Cash") or ls:FindFirstChild("Money") or ls:GetChildren()[1]
    end
end)

-- === Fenêtre compacte ===
local Window = library.NewWindow({
    title    = "ImmortalFarm",
    size     = UDim2.new(0, 420, 0, 280),
    position = UDim2.new(0, 80, 0, 120),
    no_shadow = true,      -- si supporté par la lib
    compact  = true,       -- si supporté par la lib
})

local Tab = Window:AddTab("Main")
local Section = Tab:AddSection("Farm Controls", 1)

-- --- Indicator (overlay) : "💵 Gagné"
local gainsIndicator = library.NewIndicator({
    title = "Immortal",
    enabled = true,
    position = UDim2.new(0, 12, 0, 240),
})
local gainsValue = gainsIndicator:AddValue({ key = "💵 Gagné", value = "0", order = 1 })

-- Hook de mise à jour du compteur
local function updateGains()
    if currentCashValue and startCash then
        local gain = (tonumber(currentCashValue.Value) or 0) - (tonumber(startCash) or 0)
        gainsValue:SetValue(tostring(gain))
    end
end

if currentCashValue then
    startCash = tonumber(currentCashValue.Value) or 0
    currentCashValue.Changed:Connect(updateGains)
end

-- === TOGGLE: Immortal Farm ===
Section:AddToggle({
    text = "Immortal Farm",
    state = false,
    callback = function(state)
        getgenv().autofarmOn = state
        if state then
            -- démarre tes routines (TP boucle, ATM loop, punch, etc.)
            if currentCashValue then
                startCash = tonumber(currentCashValue.Value) or 0
                gainsValue:SetValue("0")
            end
            library:SendNotification("Farm ON", 2)
        else
            -- stop tes routines
            getgenv().hackPOVOn = false
            pcall(function()
                local cam = workspace.CurrentCamera
                cam.CameraType = Enum.CameraType.Custom
                local blur = game:GetService("Lighting"):FindFirstChildOfClass("BlurEffect")
                if blur then blur.Enabled = false end
            end)
            library:SendNotification("Farm OFF", 2)
        end
    end
})

-- === TOGGLE: Hack POV ===
Section:AddToggle({
    text = "Hack POV",
    state = false,
    callback = function(state)
        if not getgenv().autofarmOn then
            -- bloquer POV si farm pas actif
            library:SendNotification("Active d'abord le Farm.", 3)
            -- si la lib expose la gestion d'état par flag/option, essaie de refléter OFF (optionnel)
            return
        end

        getgenv().hackPOVOn = state
        local Lighting = game:GetService("Lighting")
        local cam = workspace.CurrentCamera

        if state then
            local blur = Lighting:FindFirstChildOfClass("BlurEffect") or Instance.new("BlurEffect", Lighting)
            blur.Size = 16
            blur.Enabled = true
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.new(100, 60, -500) * CFrame.Angles(0, math.rad(35), 0)
        else
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local blur = Lighting:FindFirstChildOfClass("BlurEffect")
            if blur then blur.Enabled = false end
        end
    end
})

-- (Optionnel) Onglet Settings — supprimé pour réduire le GUI
-- Si tu veux le remettre : library:CreateSettingsTab(Window)

-- Petite notification de bienvenu
library:SendNotification("UI chargé (Accent #0000FF).", 3)
