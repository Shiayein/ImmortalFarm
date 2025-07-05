--[[=========================================================
  Main.lua – version optimisée (ATM autofarm + GUI + Hack POV)
===========================================================]]
if not _G.VerificationPassed then
    error("Main.lua doit être lancé via verification.lua")
end

-------------------------------------------------------------
-- 1. SERVICES & VARIABLES JEU
-------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")
local Lighting     = game:GetService("Lighting")

local player     = Players.LocalPlayer
local character  = player.Character or player.CharacterAdded:Wait()
local rootPart   = character:WaitForChild("HumanoidRootPart")
local backpack   = player:WaitForChild("Backpack")

-------------------------------------------------------------
-- 2. PARAMÈTRES FARM
-------------------------------------------------------------
local toolName            = "Combat"
local PICKUP_RADIUS       = 22
local ATM_LOOK_INTERVAL   = 1      -- sec
local MONEY_TIMEOUT       = 1      -- sec sans billet -> prochain spot
local WALK_DELAY          = 0.5    -- pausette entre 2 TP

local route = {                   -- mêmes positions qu’avant
    CFrame.new(583.81, 49, -276.92),  CFrame.new(517.03, 48, -302.60),
    CFrame.new(577.56, 51.06, -468.30), CFrame.new(596.33, 51.06, -468.40),
    CFrame.new(94.64, 21.76, -521.39),  CFrame.new(-219.89, 21.9, -787.59),
    CFrame.new(-401.05, 21.76, -589.96), CFrame.new(-252.39, 21.85, -409.80),
    CFrame.new(-450.92, 21.75, -332.39), CFrame.new(-477.04, 23.08, -291.44),
    CFrame.new(-476.88, 24.3, -283.40),  CFrame.new(-476.42, 23.08, -275.40),
    CFrame.new(-621.39, 23.25, -288.20), CFrame.new(-630.13, 23.25, -282.76),
    CFrame.new(-796.76, 21.88, -657.81), CFrame.new(-856.37, 22.01, -660.45),
    CFrame.new(-939.68, 22.01, -663.71), CFrame.new(-939.39, 22.51, -656.50),
    CFrame.new(-806.90, 21.75, -287.09), CFrame.new(-951.59, 21.75, -164.95),
    CFrame.new(-941.35, 21.75, -165.24), CFrame.new(-870.75, 21.8, -87.96),
    CFrame.new(-861.74, 21.8, -87.96),
}

-------------------------------------------------------------
-- 3. ÉTAT RUNTIME
-------------------------------------------------------------
local autofarmOn      = false
local hackPOVOn       = false
local aimingATM       = false
local isFarmingMoney  = false
local routeIndex      = 0
local startCash       = 0

-------------------------------------------------------------
-- 4. INDEX DYNAMIQUE DES OBJETS (ATM / MoneyDrop)
-------------------------------------------------------------
local ATMs, Drops = {}, {}

local function indexObject(obj, add)
    if obj:IsA("BasePart") or obj:IsA("Model") then
        if obj.Name == "CA$HIER" then
            ATMs[obj] = add and true or nil
        elseif obj.Name == "MoneyDrop" and obj:IsA("BasePart") then
            Drops[obj] = add and true or nil
        end
    end
end

-- index initial
for _, d in ipairs(Workspace:GetDescendants()) do indexObject(d, true) end
-- écoute des ajouts / suppressions
Workspace.DescendantAdded:Connect(function(d)  indexObject(d, true)  end)
Workspace.DescendantRemoving:Connect(function(d) indexObject(d) end)

-------------------------------------------------------------
-- 5. UTILITAIRES
-------------------------------------------------------------
local function getClosest(tbl, range)
    local best, dist2 = nil, math.huge
    for obj in pairs(tbl) do
        if obj.Parent then
            local d = (rootPart.Position - (obj.Position or obj:GetPivot().Position)).Magnitude
            if d < dist2 and d <= range then
                dist2, best = d, obj
            end
        end
    end
    return best
end

local function equipTool()
    local t = backpack:FindFirstChild(toolName) or character:FindFirstChild(toolName)
    if t and t:IsA("Tool") then t.Parent = character end
    return t
end

local function lookAt(pos)
    local lookDir = (pos - rootPart.Position).Unit
    rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(lookDir.X, 0, lookDir.Z))
end

-------------------------------------------------------------
-- 6. GUI (identique visuellement)
-------------------------------------------------------------
local gui = Instance.new("ScreenGui", player.PlayerGui); gui.Name = "ATM_AutoFarm_GUI"

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromOffset(220,140)
panel.Position = UDim2.new(0,-200,0.1,0)
panel.BackgroundColor3 = Color3.fromRGB(30,30,30)

local toggleBtn = Instance.new("TextButton", panel)
toggleBtn.Size = UDim2.new(0,30,0,60)
toggleBtn.Position = UDim2.new(1,0,0.5,-30)
toggleBtn.Text = "▶"

local function tweenPanel(open)
    local x = open and 0 or -200
    TweenService:Create(panel, TweenInfo.new(0.3), {Position = UDim2.new(0,x,0.1,0)}):Play()
    toggleBtn.Text = open and "◀" or "▶"
end
local panelOpen = false
toggleBtn.MouseButton1Click:Connect(function() panelOpen = not panelOpen; tweenPanel(panelOpen) end)

local farmBtn = Instance.new("TextButton", panel)
farmBtn.Size = UDim2.new(0,180,0,40); farmBtn.Position = UDim2.new(0,20,0,20)
farmBtn.Text = "Immortal Farm"

local counter = Instance.new("TextLabel", panel)
counter.Size = UDim2.new(0,180,0,30); counter.Position = UDim2.new(0,20,0,70)
counter.TextColor3 = Color3.fromRGB(255,210,50); counter.Visible = false

local hackBtn = Instance.new("TextButton", panel)
hackBtn.Size = UDim2.new(0,180,0,40); hackBtn.Position = UDim2.new(0,20,0,105)
hackBtn.Text = "Hack POV"

-- blur unique
local blur = Instance.new("BlurEffect", Lighting); blur.Size = 20; blur.Enabled = false

-------------------------------------------------------------
-- 7. EVENEMENTS GUI
-------------------------------------------------------------
farmBtn.MouseButton1Click:Connect(function()
    autofarmOn  = not autofarmOn
    aimingATM   = autofarmOn
    farmBtn.BackgroundColor3 = autofarmOn and Color3.fromRGB(180,30,30) or Color3.fromRGB(15,80,15)
    counter.Visible = autofarmOn
    if autofarmOn then
        startCash = (currentCashValue and currentCashValue.Value) or 0
        counter.Text = "💵 Gagné : 0"
    end
    if not autofarmOn and hackPOVOn then
        hackPOVOn, blur.Enabled = false, false
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
end)

hackBtn.MouseButton1Click:Connect(function()
    if not autofarmOn then return end
    hackPOVOn = not hackPOVOn
    hackBtn.BackgroundColor3 = hackPOVOn and Color3.fromRGB(180,30,30) or Color3.fromRGB(50,50,50)
    blur.Enabled = hackPOVOn
    local cam = workspace.CurrentCamera
    if hackPOVOn then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = CFrame.new(100,60,-500)*CFrame.Angles(0,math.rad(45),0)
    else
        cam.CameraType = Enum.CameraType.Custom
    end
end)

-- suivi cash
local dataFolder = player:FindFirstChild("DataFolder")
local currentCashValue = dataFolder and dataFolder:FindFirstChildWhichIsA("ValueBase", true)
if currentCashValue then
    currentCashValue.Changed:Connect(function()
        counter.Text = "💵 Gagné : ".. (currentCashValue.Value - startCash)
    end)
end

-------------------------------------------------------------
-- 8. BOUCLE PRINCIPALE
-------------------------------------------------------------
local atmTimer, moneyTimer = 0, 0
RunService.Heartbeat:Connect(function(dt)
    if not autofarmOn then return end

    -- rester face à l’ATM tant qu’on n’a pas fini
    atmTimer += dt; moneyTimer += dt

    if aimingATM and atmTimer >= ATM_LOOK_INTERVAL then
        atmTimer = 0
        local atm = getClosest(ATMs, 35)
        if atm then lookAt((atm.Position or atm:GetPivot().Position)) end
    end

    -- ramasser en boucle tant qu’il y a des billets
    local drop = getClosest(Drops, PICKUP_RADIUS)
    if drop then
        isFarmingMoney, aimingATM, moneyTimer = true, false, 0
        teleportAndClick(drop)
    elseif isFarmingMoney and moneyTimer >= MONEY_TIMEOUT then
        -- plus de billet depuis 1 s : reprendre la route
        isFarmingMoney, aimingATM = false, true
    end
end)

-- tâche route / punch séparée pour garder FPS
task.spawn(function()
    while true do
        if autofarmOn and not isFarmingMoney then
            rootPart.CFrame = getNextRoutePosition()
            task.wait(WALK_DELAY)
            punchUntilDHCDetected()
        end
        task.wait(0.05)
    end
end)
