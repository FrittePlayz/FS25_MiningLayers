--
-- FS25_MiningLayers
--
-- Inoffizielles Addon fuer TerraFarm von scfmod.
-- https://github.com/scfmod/FS25_TerraFarm
--
-- Aendert beim Graben das gefoerderte Material abhaengig von der Tiefe unter der
-- Gelaendeoberkante. Reiner Laufzeit-Hook: es wird keine Datei von TerraFarm
-- veraendert und keine Zeile fremden Codes mitgeliefert.
--
-- Autor: Tommy Honold (FrittePlayz)
--

---@diagnostic disable: lowercase-global, undefined-global

MiningLayers = {}

MiningLayers.VERSION = '1.3.5.0'
MiningLayers.LOG_PREFIX = '[MiningLayers] '

MiningLayers.MOD_NAME = g_currentModName
MiningLayers.MOD_DIRECTORY = g_currentModDirectory
MiningLayers.SETTINGS_DIRECTORY = g_currentModSettingsDirectory

-- Wird auf false gesetzt, wenn TerraFarm fehlt. Dann bleibt der Mod komplett still.
MiningLayers.active = false

---FS25 kapselt jeden Script-Mod in eine eigene Lua-Umgebung. TerraFarms Globals
---(g_modSettings, g_machineManager, die Landscaping-Klassen) stehen deshalb NICHT
---in unserem _G, sondern nur in _G['FS25_0_TerraFarm'].
---TerraFarm selbst greift genauso auf fremde Mods zu, siehe
---scripts/extensions/InteractiveControlExtension.lua:26-32.
---@type table? Umgebung von TerraFarm
MiningLayers.TF = nil

---Namen, unter denen TerraFarm ueblicherweise installiert ist.
MiningLayers.TERRAFARM_MOD_NAMES = {
    'FS25_0_TerraFarm',
    'FS25_TerraFarm'
}

---Schreibt eine Zeile ins log.txt. Bewusst ohne Logging.* und ohne Umlaute:
---print() ist immer vorhanden, und Umlaute kommen im FS-Log nicht zuverlaessig an.
---@param str string
function MiningLayers.log(str, ...)
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        print(MiningLayers.LOG_PREFIX .. (ok and formatted or str))
    else
        print(MiningLayers.LOG_PREFIX .. tostring(str))
    end
end

---Ruft fn geschuetzt auf. Ein Fehler darf niemals das Spiel reissen.
---@param context string Bezeichnung fuer die Fehlermeldung
---@param fn function
---@return boolean ok
---@return any result
function MiningLayers.protectedCall(context, fn, ...)
    local ok, result = pcall(fn, ...)

    if not ok then
        MiningLayers.log('FEHLER in %s: %s', context, tostring(result))
    end

    return ok, result
end

---Prueft, ob eine Funktion wirklich aufrufbar ist.
---@param value any
---@return boolean
function MiningLayers.isCallable(value)
    return type(value) == 'function'
end

---Holt etwas aus TerraFarms Lua-Umgebung. Nie direkt auf g_modSettings & Co.
---zugreifen - die stehen nicht in unserem Namensraum.
---@param name string
---@return any
function MiningLayers.tf(name)
    if MiningLayers.TF == nil then
        return nil
    end

    return MiningLayers.TF[name]
end

---Taugt diese Mod-Umgebung als TerraFarm?
---@param env any
---@return boolean
local function isTerraFarmEnv(env)
    return type(env) == 'table'
        and type(env.g_modSettings) == 'table'
        and type(env.LandscapingInputFlatten) == 'table'
end

---Sucht TerraFarms Lua-Umgebung. Erst unter den bekannten Namen, sonst ueber alle
---geladenen Mods - dann ist auch ein umbenannter Ordner kein Problem.
---@return boolean available
---@return string reason
function MiningLayers.getTerraFarmAvailable()
    for _, modName in ipairs(MiningLayers.TERRAFARM_MOD_NAMES) do
        if g_modIsLoaded ~= nil and g_modIsLoaded[modName] then
            local env = _G[modName]

            if isTerraFarmEnv(env) then
                MiningLayers.TF = env
                MiningLayers.log('TerraFarm gefunden als "%s".', modName)
                return true, ''
            end
        end
    end

    -- Zweiter Versuch: unter anderem Namen installiert.
    if type(g_modIsLoaded) == 'table' then
        for modName, loaded in pairs(g_modIsLoaded) do
            if loaded and isTerraFarmEnv(_G[modName]) then
                MiningLayers.TF = _G[modName]
                MiningLayers.log('TerraFarm gefunden als "%s" (abweichender Ordnername).', modName)
                return true, ''
            end
        end
    end

    if g_modIsLoaded == nil then
        return false, 'g_modIsLoaded nicht verfuegbar'
    end

    return false, 'keine Mod-Umgebung mit g_modSettings und LandscapingInputFlatten'
end

source(g_currentModDirectory .. 'scripts/MiningLayersConfig.lua')
source(g_currentModDirectory .. 'scripts/LayerHooks.lua')
source(g_currentModDirectory .. 'scripts/MaterialCheck.lua')
source(g_currentModDirectory .. 'scripts/HeightDisplay.lua')
source(g_currentModDirectory .. 'scripts/LayerEditor.lua')
source(g_currentModDirectory .. 'scripts/MiningLayersGui.lua')
source(g_currentModDirectory .. 'scripts/SponsorSign.lua')

---Wird vom Basisspiel aufgerufen, nachdem die Karte geladen ist.
---@param filename string
function MiningLayers:loadMap(filename)
    local available, reason = MiningLayers.getTerraFarmAvailable()

    if not available then
        MiningLayers.log('TerraFarm nicht gefunden (%s) - Addon bleibt inaktiv.', reason)
        return
    end

    MiningLayers.active = true
    MiningLayers.log('%s geladen - TerraFarm erkannt.', MiningLayers.VERSION)

    MiningLayers.protectedCall('loadConfig', function()
        MiningLayers:loadConfig()
    end)

    MiningLayers.protectedCall('loadMoundMemory', function()
        MiningLayers:loadMoundMemory()
    end)

    -- Hooks erst nach der Konfiguration setzen: liegen keine Zonen vor,
    -- verhaelt sich das Graben exakt wie ohne Addon.
    MiningLayers.protectedCall('installHooks', function()
        MiningLayers:installHooks()
    end)

    MiningLayers.protectedCall('runMaterialCheck', function()
        MiningLayers:runMaterialCheck()
    end)

    MiningLayers.protectedCall('resolveAllAreas', function()
        MiningLayers:resolveAllAreas()
    end)

    MiningLayers.protectedCall('subscribeAreaUpdates', function()
        MiningLayers:subscribeAreaUpdates()
    end)

    MiningLayers.protectedCall('spawnSignsForAllAreas', function()
        MiningLayers:spawnSignsForAllAreas()
    end)
end

-- Die Anzeige-Taste (Numpad *) ist raus - sie reagierte wegen der Input-Kontexte
-- nicht zuverlaessig, und Tommy hat sie 2026-08-08 gestrichen. Anzeige aus geht
-- weiterhin per showHeightDisplay="false" in der miningLayers.xml.

function MiningLayers:deleteMap()
    -- Halden-Gedaechtnis wegschreiben, bevor die Welt abgebaut wird.
    pcall(function()
        MiningLayers:saveMoundMemory()
    end)

    if g_messageCenter ~= nil then
        pcall(function()
            g_messageCenter:unsubscribeAll(MiningLayers)
        end)
    end

    -- ⚠️ Hier wird die Menueseite NICHT mehr entfernt. Das hat beim Beenden des
    -- Spiels eine Fehlerflut ausgeloest (PagingElement lief ueber einen
    -- nil-Eintrag, danach schlug jeder Frame fehl und das Beenden zog sich).
    -- Das Ingame-Menue wird ohnehin mit abgebaut; TerraFarm laesst seine Seite
    -- aus demselben Grund stehen. Beim naechsten loadMap erkennt
    -- ensureMenuPage die vorhandene Seite und laesst sie in Ruhe.
    --
    -- Schilder ebenso: die Szenenknoten gehoeren zur Karte und werden mit ihr
    -- abgeraeumt. Ein delete() auf einen schon zerstoerten Knoten waere ein
    -- Risiko ohne Gegenwert - wir vergessen sie nur.
    MiningLayers.signNodes = {}

    MiningLayers.active = false
end

---Wird vom Basisspiel jeden Frame aufgerufen.
function MiningLayers:draw()
    if not MiningLayers.active then
        return
    end

    -- Der Schichten-Knopf in TerraFarms Maschinenmenue ist raus: die Schichten
    -- baut man seit 1.2.0.0 auf unserem eigenen Reiter zusammen. In fremden
    -- Menues haben wir nichts verloren. ensureGuiButton bleibt ungenutzt im
    -- LayerEditor stehen, saveConfigFile() von dort brauchen wir weiterhin.
    pcall(MiningLayers.ensureMenuPage, MiningLayers)

    MiningLayers:drawHeightDisplay()
    MiningLayers:drawDepthLinesSafe()
end

addModEventListener(MiningLayers)
