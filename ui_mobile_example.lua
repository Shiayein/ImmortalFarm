-- ui_mobile_example.lua
-- ImmortalFarm — UI only (square, mobile-friendly). No logic here.
-- Uses source_gui_mobile.lua and calls the logic via getgenv().IF

local IF = getgenv().IF or {}
getgenv().IF = IF

local LIB_URL = "https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/source_gui_mobile.lua"
local ok, libOrErr = pcall(function() return loadstring(game:HttpGet(LIB_URL))() end)
if not ok then
	warn("[ImmortalFarm UI] Failed to load source_gui_mobile.lua: ", tostring(libOrErr))
	return
end
local library = libOrErr
library:init()

local Window = library.NewWindow({ title = "ImmortalFarm", subtitle = "Da Hood" })
local Tab = Window:AddTab("main")
local Section = Tab:AddSection("Farm Controls", 1)

-- Left indicator (tap to reopen the GUI; no duplicates)
local gainsIndicator = library.NewIndicator({
	title = "Immortal",
	enabled = true,
	position = UDim2.new(0, 12, 0, 240),
	clickToOpen = true
})
local gainsValue = gainsIndicator:AddValue({ key = "Gains", value = "0" })

-- Allow the logic to push gains to the UI
IF.SetGains = function(text)
	gainsValue:SetValue(tostring(text or "0"))
end

-- UI -> Logic
Section:AddToggle({
	text = "Immortal Farm",
	state = false,
	callback = function(on)
		if IF.StartFarm then IF.StartFarm(on) end
	end
})

Section:AddToggle({
	text = "Hack POV",
	state = false,
	callback = function(on)
		if IF.SetPOV then IF.SetPOV(on) end
	end
})

Section:AddKeybind({
	text = "Toggle UI Key",
	default = Enum.KeyCode.RightShift,
	onChanged = function(key)
		library:SetToggleKey(key)
		library:SendNotification("UI key set to: ".. key.Name, 2)
	end
})
