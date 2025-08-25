-- TokyoLib_Slim.lua
-- Wrapper pour "Tokyo Lib Source.lua"
-- Objectif : n'exposer QU'UN SEUL thème (Immortal) avec Accent #0000FF, et init propre.
-- Usage :
--   local library = loadstring(readfile("TokyoLib_Slim.lua"))({ cheatname="ImmortalFarm", gamename="Da Hood" })
--   library:init()
--   -- puis utilisez la lib normalement (NewWindow, AddTab, AddSection, AddToggle, NewIndicator, etc.)

assert(readfile, "[TokyoLib_Slim] Votre exécuteur doit supporter readfile().")
local raw = readfile("Tokyo Lib Source.lua")
local base_loader = assert(loadstring(raw), "[TokyoLib_Slim] Impossible de charger 'Tokyo Lib Source.lua'")

return function(opts)
    opts = opts or {}
    local library = base_loader({
        cheatname = opts.cheatname or "ImmortalFarm",
        gamename  = opts.gamename  or "Da Hood",
        fileext   = opts.fileext   or ".json",
    })

    -- Forcer un unique thème "Immortal" + Accent bleu #0000FF
    local Color3 = Color3
    local fromRGB = Color3.fromRGB

    -- Thème compact, neutre, accent bleu
    local IMMORTAL_THEME = {
        ['Main Background'] = fromRGB(22,22,26),
        ['Secondary Background'] = fromRGB(16,16,20),
        ['Tertiary Background'] = fromRGB(12,12,16),
        ['Stroke'] = fromRGB(60,60,70),
        ['Text'] = fromRGB(235,235,240),
        ['Sub Text'] = fromRGB(170,170,180),
        ['Accent'] = fromRGB(0,0,255), -- #0000FF
        ['Positive'] = fromRGB(60,200,120),
        ['Warning']  = fromRGB(240,160,60),
        ['Error']    = fromRGB(235,80,80),
        ['Shadow']   = fromRGB(0,0,0),
        ['Element Background'] = fromRGB(28,28,34),
        ['Slider Fill'] = fromRGB(0,0,255),
        ['Toggle On'] = fromRGB(0,0,255),
    }

    -- Écrase la table des thèmes pour n'en laisser qu'un
    if library and type(library) == "table" then
        library.themes = { Immortal = IMMORTAL_THEME }
        library.activeTheme = "Immortal"
        -- Applique immédiatement le thème bleu
        if library.SetTheme then
            library:SetTheme(IMMORTAL_THEME)
        elseif library.UpdateThemeColors then
            library:UpdateThemeColors(IMMORTAL_THEME)
        end
    end

    -- Réduit quelques éléments visuels si la lib expose ces flags
    pcall(function()
        library.flags = library.flags or {}
        library.flags.DisableWatermark = true      -- masque watermark si supporté
        library.flags.CompactTabs      = true      -- onglets compacts si supporté
        library.flags.NoCreditsButton  = true      -- pas de bouton crédits si supporté
        library.flags.NoKeybindTips    = true
    end)

    return library
end
