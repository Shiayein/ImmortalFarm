-- ui_mobile_example.lua
-- Minimal example that loads the user's mobile GUI source directly from GitHub.
-- No business logic inside; only hooks to your own functions.

local LIB_URL = "https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/source_gui_mobile.lua"

-- Load the mobile GUI library from GitHub
local library = loadstring(game:HttpGet(LIB_URL))()
library:init()

-- Build a compact window
local Window = library.NewWindow({
    title = "ImmortalFarm",
    size = UDim2.new(0, 420, 0, 280),
    position = UDim2.new(0, 80, 0, 120),
})

local Tab = Window:AddTab("Main")
local Section = Tab:AddSection("Farm Controls", 1)

-- Toggle: Farm (connect your own logic inside the callback)
Section:AddToggle({
    text = "Immortal Farm",
    state = false,
    callback = function(state)
        -- if state then StartFarm() else StopFarm() end
    end
})

-- Toggle: POV (connect your own logic inside the callback)
Section:AddToggle({
    text = "Hack POV",
    state = false,
    callback = function(state)
        -- SetPOV(state)
    end
})

-- Indicator "Gains"
local gainsIndicator = library.NewIndicator({
    title = "Immortal",
    enabled = true,
    position = UDim2.new(0, 12, 0, 240),
})
local gainsValue = gainsIndicator:AddValue({ key = "Gains", value = "0" })

-- From your logic, update this value as needed:
-- gainsValue:SetValue("1234")
