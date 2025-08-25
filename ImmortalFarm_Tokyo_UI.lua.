-- ImmortalFarm_Tokyo_UI.lua
-- GUI minimal basé sur TokyoLib_Slim
-- ⚠️ Ne contient AUCUNE logique de farm → tu ajoutes ton code dans les callbacks

-- Charger la lib slim directement depuis GitHub
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/TokyoLib_Slim.lua"))({
    cheatname = "ImmortalFarm",
    gamename  = "Da Hood"
})

library:init()

-- === Fenêtre réduite ===
local Window = library.NewWindow({
    title    = "ImmortalFarm",
    size     = UDim2.new(0, 400, 0, 250),
    position = UDim2.new(0, 80, 0, 120),
})

local Tab = Window:AddTab("Main")
local Section = Tab:AddSection("Farm Controls", 1)

-- === Indicator 💵 ===
local gainsIndicator = library.NewIndicator({
    title = "Immortal",
    enabled = true,
    position = UDim2.new(0, 12, 0, 220),
})
local gainsValue = gainsIndicator:AddValue({ key = "💵 Gagné", value = "0", order = 1 })

-- Fonction pour mettre à jour l'indicateur (tu appelles cette fonction dans ta logique)
getgenv().UpdateGains = function(val)
    gainsValue:SetValue(tostring(val))
end

-- === Toggle Farm ===
Section:AddToggle({
    text = "Immortal Farm",
    state = false,
    callback = function(state)
        getgenv().autofarmOn = state
        -- 👉 Ici tu appelles TA logique
        -- Exemple: if state then StartFarm() else StopFarm() end
    end
})

-- === Toggle Hack POV ===
Section:AddToggle({
    text = "Hack POV",
    state = false,
    callback = function(state)
        getgenv().hackPOVOn = state
        -- 👉 Ici tu appelles TA logique pour la POV
    end
})

library:SendNotification("ImmortalFarm UI chargé.", 3)
