-- Chargement direct de ta version Slim sur GitHub
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/TokyoLib_Slim.lua"))({
    cheatname = "ImmortalFarm",
    gamename  = "Da Hood",
    fileext   = ".json"
})

library:init()

-- === Fenêtre réduite ===
local Window = library.NewWindow({
    title    = "ImmortalFarm",
    size     = UDim2.new(0, 420, 0, 280),
    position = UDim2.new(0, 80, 0, 120),
})

local Tab = Window:AddTab("Main")
local Section = Tab:AddSection("Farm Controls", 1)

-- Variables globales (adapte-les à ton main)
getgenv().autofarmOn = false
getgenv().hackPOVOn  = false
local startCash = 0
local currentCashValue = nil

-- Détection du leaderstats Cash (adapte si besoin)
pcall(function()
    local ls = game.Players.LocalPlayer:WaitForChild("leaderstats", 3)
    if ls then
        currentCashValue = ls:FindFirstChild("Cash") or ls:FindFirstChild("Money")
    end
end)

-- === Indicateur 💵 Gagné ===
local gainsIndicator = library.NewIndicator({
    title = "Immortal",
    enabled = true,
    position = UDim2.new(0, 12, 0, 240),
})
local gainsValue = gainsIndicator:AddValue({ key = "💵 Gagné", value = "0", order = 1 })

if currentCashValue then
    startCash = tonumber(currentCashValue.Value) or 0
    currentCashValue.Changed:Connect(function()
        local gain = (tonumber(currentCashValue.Value) or 0) - startCash
        gainsValue:SetValue(tostring(gain))
    end)
end

-- === Toggle Farm ===
Section:AddToggle({
    text = "Immortal Farm",
    state = false,
    callback = function(state)
        getgenv().autofarmOn = state
        if state then
            if currentCashValue then
                startCash = tonumber(currentCashValue.Value) or 0
                gainsValue:SetValue("0")
            end
            library:SendNotification("Farm ON", 2)
        else
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

-- === Toggle Hack POV ===
Section:AddToggle({
    text = "Hack POV",
    state = false,
    callback = function(state)
        if not getgenv().autofarmOn then
            library:SendNotification("Active d'abord le Farm.", 3)
            return
        end
        getgenv().hackPOVOn = state
        local cam = workspace.CurrentCamera
        local Lighting = game:GetService("Lighting")
        if state then
            local blur = Lighting:FindFirstChildOfClass("BlurEffect") or Instance.new("BlurEffect", Lighting)
            blur.Size = 16
            blur.Enabled = true
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.new(100, 60, -500) * CFrame.Angles(0, math.rad(35), 0)
        else
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local blur = Lighting:FindFirstChildOfClass("BlurEffect")
            if blur then blur.Enabled = false end
        end
    end
})

library:SendNotification("UI chargé depuis GitHub (Accent #0000FF).", 3)
