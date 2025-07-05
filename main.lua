if not _G.VerificationPassed then
    error("Main.lua doit être lancé via verification.lua")
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local toolName = "Combat"
local autofarmOn = false
local hackPOVOn = false
local aimingATM = false
local isFarmingDHC = false
local currentRouteIndex = 0
local startCash = 0

local route = {
    CFrame.new(583.81, 49.00, -276.92),
    CFrame.new(517.03, 48.00, -302.60),
    CFrame.new(577.56, 51.06, -468.30),
    CFrame.new(596.33, 51.06, -468.40),
    CFrame.new(94.64, 21.76, -521.39),
    CFrame.new(-219.89, 21.90, -787.59),
    CFrame.new(-401.05, 21.76, -589.96),
    CFrame.new(-252.39, 21.85, -409.80),
    CFrame.new(-450.92, 21.75, -332.39),
    CFrame.new(-477.04, 23.08, -291.44),
    CFrame.new(-476.88, 24.30, -283.40),
    CFrame.new(-476.42, 23.08, -275.40),
    CFrame.new(-621.39, 23.25, -288.20),
    CFrame.new(-630.13, 23.25, -282.76),
    CFrame.new(-796.76, 21.88, -657.81),
    CFrame.new(-856.37, 22.01, -660.45),
    CFrame.new(-939.68, 22.01, -663.71),
    CFrame.new(-939.39, 22.51, -656.50),
    CFrame.new(-806.90, 21.75, -287.09),
    CFrame.new(-951.59, 21.75, -164.95),
    CFrame.new(-941.35, 21.75, -165.24),
    CFrame.new(-870.75, 21.80, -87.96),
    CFrame.new(-861.74, 21.80, -87.96),
}

-- === Fonctions de base (idem précédent) ===
local function getNextRoutePosition()
    currentRouteIndex += 1
    if currentRouteIndex > #route then
        currentRouteIndex = 1
    end
    return route[currentRouteIndex]
end

local moneyDropName = "MoneyDrop"

local function getClosestDrop()
    local closest, minDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == moneyDropName then
            local dist = (rootPart.Position - obj.Position).Magnitude
            if dist < 22 and dist < minDist then
                minDist = dist
                closest = obj
            end
        end
    end
    return closest
end

local function teleportAndClick(target)
    if target then
        rootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
        local click = target:FindFirstChildOfClass("ClickDetector")
        if click then
            pcall(function()
                fireclickdetector(click)
            end)
        end
    end
end

local function punchUntilDHCDetected()
    local tool = backpack:FindFirstChild(toolName) or character:FindFirstChild(toolName)
    if tool and not tool.Parent:IsA("Model") then
        tool.Parent = character
        wait(0.1)
    end
    if not tool or not tool:IsA("Tool") then return end

    local detected = false
    local maxTries = 30
    local tries = 0

    while not detected and autofarmOn and tries < maxTries do
        tool:Activate()
        wait(0.3)
        tool:Activate()
        wait(0.4)
        if getClosestDrop() then
            detected = true
        end
        tries += 1
    end
    tool.Parent = backpack
end

local function findClosestATM()
    local closest, minDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "CA$HIER" and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
            local dist = (pos - rootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = obj
            end
        end
    end
    return closest
end

-- Gestion du regard vers l’ATM (1 fois / seconde)
local LOOK_INTERVAL = 1.0
local timeSinceLastLook = 0
RunService.Heartbeat:Connect(function(dt)
    timeSinceLastLook += dt
    if timeSinceLastLook < LOOK_INTERVAL then return end
    timeSinceLastLook = 0

    if autofarmOn and aimingATM and not isFarmingDHC then
        local atm = findClosestATM()
        if atm then
            local targetPos = atm:IsA("Model")
                and (atm.PrimaryPart and atm.PrimaryPart.Position or atm:GetModelCFrame().Position)
                or atm.Position

            local dir = (targetPos - rootPart.Position).Unit
            local lookDir = Vector3.new(dir.X, 0, dir.Z)

            if (rootPart.CFrame.LookVector - lookDir).Magnitude > 0.02 then
                rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookDir)
            end
        end
    end
end)

-- === Création GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "ATM_AutoFarm_GUI"
gui.Parent = player:WaitForChild("PlayerGui")

-- Frame principale (le panneau)
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 220, 0, 140)
panel.Position = UDim2.new(0, -200, 0.1, 0) -- caché à gauche initialement
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
panel.BorderSizePixel = 0
panel.Parent = gui

-- Bouton flèche (ouvrir/fermer panneau)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 30, 0, 60)
toggleBtn.Position = UDim2.new(1, 0, 0.5, -30)
toggleBtn.Text = "▶"
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 25
toggleBtn.Parent = panel

-- Bouton Immortal Farm
local farmBtn = Instance.new("TextButton")
farmBtn.Size = UDim2.new(0, 180, 0, 40)
farmBtn.Position = UDim2.new(0, 20, 0, 20)
farmBtn.Text = "Immortal Farm"
farmBtn.BackgroundColor3 = Color3.fromRGB(15, 80, 15) -- vert sombre
farmBtn.TextColor3 = Color3.new(1,1,1)
farmBtn.Font = Enum.Font.SourceSansBold
farmBtn.TextSize = 22
farmBtn.Parent = panel

-- Label compteur gains (initialement invisible)
local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(0, 180, 0, 30)
counterLabel.Position = UDim2.new(0, 20, 0, 70)
counterLabel.Text = "💵 Gagné : 0"
counterLabel.BackgroundTransparency = 1
counterLabel.TextColor3 = Color3.fromRGB(255, 210, 50)
counterLabel.Font = Enum.Font.SourceSansBold
counterLabel.TextSize = 20
counterLabel.Visible = false
counterLabel.Parent = panel

-- Bouton Hack POV
local hackBtn = Instance.new("TextButton")
hackBtn.Size = UDim2.new(0, 180, 0, 40)
hackBtn.Position = UDim2.new(0, 20, 0, 105)
hackBtn.Text = "Hack POV"
hackBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hackBtn.TextColor3 = Color3.new(1,1,1)
hackBtn.Font = Enum.Font.SourceSansBold
hackBtn.TextSize = 22
hackBtn.Parent = panel

-- Variables pour animation panneau
local panelOpen = false
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Fonction toggle panneau
local function togglePanel()
    if panelOpen then
        local tween = TweenService:Create(panel, tweenInfo, {Position = UDim2.new(0, -200, 0.1, 0)})
        tween:Play()
        toggleBtn.Text = "▶"
    else
        local tween = TweenService:Create(panel, tweenInfo, {Position = UDim2.new(0, 0, 0.1, 0)})
        tween:Play()
        toggleBtn.Text = "◀"
    end
    panelOpen = not panelOpen
end

toggleBtn.MouseButton1Click:Connect(togglePanel)

-- Gestion gains
local dataFolder = player:WaitForChild("DataFolder", 5)
local currentCashValue

if dataFolder then
    for _, v in pairs(dataFolder:GetChildren()) do
        if v:IsA("ValueBase") and v.Name:lower():find("curr") then
            currentCashValue = v
            v.Changed:Connect(function()
                local gain = currentCashValue.Value - startCash
                counterLabel.Text = "💵 Gagné : " .. tostring(gain)
            end)
        end
    end
else
    warn("DataFolder introuvable.")
end

-- Fonction toggle farm
farmBtn.MouseButton1Click:Connect(function()
    autofarmOn = not autofarmOn
    aimingATM = autofarmOn
    farmBtn.BackgroundColor3 = autofarmOn and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(15, 80, 15)
    counterLabel.Visible = autofarmOn

    if autofarmOn and currentCashValue then
        startCash = currentCashValue.Value
        counterLabel.Text = "💵 Gagné : 0"
    end

    -- Si farm désactivé, aussi désactiver Hack POV
    if not autofarmOn and hackPOVOn then
        hackPOVOn = false
        hackBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        -- Remove blur et reset caméra
        workspace.CurrentCamera.BlurEffect.Enabled = false
        workspace.CurrentCamera.CameraSubject = character.Humanoid
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
end)

-- Setup blur effect (disabled by default)
local blur = Instance.new("BlurEffect")
blur.Size = 20
blur.Enabled = false
blur.Parent = game:GetService("Lighting")

-- Fonction toggle hack POV
hackBtn.MouseButton1Click:Connect(function()
    if not autofarmOn then
        -- N'autorise pas si farm off
        return
    end

    hackPOVOn = not hackPOVOn
    hackBtn.BackgroundColor3 = hackPOVOn and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(50, 50, 50)
    blur.Enabled = hackPOVOn

    local cam = workspace.CurrentCamera

    if hackPOVOn then
        -- Téléportation caméra exemple (à changer selon besoin)
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = CFrame.new(100, 60, -500) * CFrame.Angles(0, math.rad(45), 0)
    else
        -- Revenir caméra joueur
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = character.Humanoid
    end
end)

-- Boucle principale farm
task.spawn(function()
    while true do
        if autofarmOn then
            local targetPos = getNextRoutePosition()
            rootPart.CFrame = targetPos
            wait(0.5)

            punchUntilDHCDetected()

            local noDropTime = 0
            while noDropTime < 1 do
                local drop = getClosestDrop()
                if drop then
                    isFarmingDHC = true
                    aimingATM = false
                    teleportAndClick(drop)
                    wait(0.5)
                    noDropTime = 0
                else
                    wait(0.5)
                    noDropTime += 0.5
                end
            end

            isFarmingDHC = false
            aimingATM = true
        end
        wait(0.5)
    end
end)
