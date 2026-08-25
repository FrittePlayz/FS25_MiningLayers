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

MiningLayers.VERSION = '1.6.2.0'
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
        MiningLayers.log('ERROR in %s: %s', context, tostring(result))
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
                MiningLayers.log('TerraFarm found as "%s".', modName)
                return true, ''
            end
        end
    end

    -- Zweiter Versuch: unter anderem Namen installiert.
    if type(g_modIsLoaded) == 'table' then
        for modName, loaded in pairs(g_modIsLoaded) do
            if loaded and isTerraFarmEnv(_G[modName]) then
                MiningLayers.TF = _G[modName]
                MiningLayers.log('TerraFarm found as "%s" (different folder name).', modName)
                return true, ''
            end
        end
    end

    if g_modIsLoaded == nil then
        return false, 'g_modIsLoaded not available'
    end

    return false, 'no mod environment with g_modSettings and LandscapingInputFlatten'
end

source(g_currentModDirectory .. 'scripts/MiningLayersConfig.lua')
source(g_currentModDirectory .. 'scripts/LayerHooks.lua')
source(g_currentModDirectory .. 'scripts/MaterialCheck.lua')
source(g_currentModDirectory .. 'scripts/HeightDisplay.lua')
source(g_currentModDirectory .. 'scripts/LayerEditor.lua')
source(g_currentModDirectory .. 'scripts/MiningLayersGui.lua')
source(g_currentModDirectory .. 'scripts/MiningLayersSpec.lua')
source(g_currentModDirectory .. 'scripts/HudMover.lua')
-- 1.6.2 Aktivierung (Download Key, fsmodworks): Reihenfolge ist Vertrag -
-- FsmwLicense liest FsmwCrypto beim Laden, das Gate braucht beide.
source(g_currentModDirectory .. 'scripts/license/FsmwCrypto.lua')
source(g_currentModDirectory .. 'scripts/license/FsmwLicense.lua')
source(g_currentModDirectory .. 'scripts/license/MiningLayersGate.lua')

---Anzahl Fahrzeugtypen mit unserer Eingabe-Spezialisierung (fuer das Log).
MiningLayers.inputSpecCount = 0

---Haengt die Eingabe-Spezialisierung (Anzeige-Taste) an alle fahrbaren Typen.
---⚠️ Muss beim DATEI-LADEN eingehakt werden: validateTypes laeuft vor loadMap.
---Muster 1:1 von EnhancedVehicle/AutoDrive (TypeManager.validateTypes prepend).
local function installInputSpecialization(typeManager)
    if typeManager == nil or typeManager.typeName ~= 'vehicle' then
        return
    end

    local ok, err = pcall(function()
        g_specializationManager:addSpecialization('miningLayersInput', 'MiningLayersSpec',
            MiningLayers.MOD_DIRECTORY .. 'scripts/MiningLayersSpec.lua', nil)

        if g_specializationManager:getSpecializationByName('miningLayersInput') == nil then
            MiningLayers.log('WARNING: input specialization not accepted - the display key stays off.')
            return
        end

        local count = 0

        for typeName, typeDef in pairs(g_vehicleTypeManager.types) do
            if typeDef ~= nil and typeDef.specializations ~= nil
                and SpecializationUtil.hasSpecialization(Enterable, typeDef.specializations)
                and SpecializationUtil.hasSpecialization(Motorized, typeDef.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, MiningLayers.MOD_NAME .. '.miningLayersInput')
                count = count + 1
            end
        end

        MiningLayers.inputSpecCount = count
    end)

    if not ok then
        MiningLayers.log('ERROR in the input specialization: %s', tostring(err))
        MiningLayers.log('  The display key stays off, everything else keeps running normally.')
    end
end

if TypeManager ~= nil and Utils ~= nil and type(Utils.prependedFunction) == 'function' then
    TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, installInputSpecialization)
else
    print(MiningLayers.LOG_PREFIX .. 'WARNING: TypeManager/Utils missing at load time - the display key stays off.')
end

---Wird vom Basisspiel aufgerufen, nachdem die Karte geladen ist.
---@param filename string
function MiningLayers:loadMap(filename)
    local available, reason = MiningLayers.getTerraFarmAvailable()

    if not available then
        MiningLayers.log('TerraFarm not found (%s) - the add-on stays inactive.', reason)
        return
    end

    MiningLayers.active = true
    MiningLayers.log('%s loaded - TerraFarm detected.', MiningLayers.VERSION)

    MiningLayers.protectedCall('loadConfig', function()
        MiningLayers:loadConfig()
    end)

    -- 1.6.2 Aktivierung: Download Key suchen und pruefen. Im 'report'-Modus
    -- (Testbuild) faellt hier nur die Messung an; 'enforce' schaltet den Mod
    -- ohne gueltigen Key ab, BEVOR Hooks und Menueseite installiert werden.
    MiningLayers.protectedCall('licenseCheck', function()
        MiningLayersGate.run()
    end)

    if MiningLayersGate ~= nil and MiningLayersGate.MODE == 'enforce'
        and not MiningLayersGate.isLicensed() then
        MiningLayers.log('Download Key missing or invalid - Mining Layers stays INACTIVE (gate mode "enforce").')
        MiningLayers.log('  %s', MiningLayersGate.getMessage())
        MiningLayers.active = false

        return
    end

    -- HUD-Position aus modSettings/hud.xml (falls der Spieler die Anzeige
    -- schon einmal verschoben hat) - NACH loadConfig, damit der Stand aus der
    -- miningLayers.xml als Standard fuer den Rechtsklick-Reset gemerkt wird.
    MiningLayers.protectedCall('loadHudSettings', function()
        MiningLayers:loadHudSettings()
    end)

    MiningLayers.protectedCall('loadMoundMemory', function()
        MiningLayers:loadMoundMemory()
    end)

    -- Muss VOR installHooks stehen: sonst liefe der erste Grabvorgang gegen ein
    -- leeres Raster und wuerde bereits abgesenktes Gelaende als gewachsen einfrieren.
    MiningLayers.protectedCall('loadSurfaceMemory', function()
        MiningLayers:loadSurfaceMemory()
    end)

    -- Hooks erst nach der Konfiguration setzen: liegen keine Zonen vor,
    -- verhaelt sich das Graben exakt wie ohne Addon.
    MiningLayers.protectedCall('installHooks', function()
        MiningLayers:installHooks()
    end)

    -- Beobachtet den Bereichseditor: welche Zielhoehe hat der SPIELER gesetzt?
    -- Muss stehen, bevor der erste Bereich bearbeitet werden kann - danach richtet
    -- sich, ob der Mod den Grubenboden nachzieht oder die Finger davon laesst.
    MiningLayers.protectedCall('installTargetHeightWatch', function()
        MiningLayers:installTargetHeightWatch()
    end)

    -- Material-Pool VOR der Materialpruefung: die Schichten-Auswahl baut darauf
    -- auf, und die Pruefung darunter darf ihn nicht mitreissen, wenn sie
    -- ausfaellt (eigener protectedCall).
    MiningLayers.protectedCall('buildMaterialPool', function()
        MiningLayers:buildMaterialPool()
    end)

    MiningLayers.protectedCall('runMaterialCheck', function()
        MiningLayers:runMaterialCheck()
    end)

    -- Der Kartenbericht entsteht normalerweise am Ende der Materialpruefung.
    -- Ist die abgeschaltet (checkMaterials="false") oder bricht sie ab, bauen
    -- wir ihn hier aus dem Pool allein - die Menueseite soll nie leer bleiben.
    if MiningLayers.mapReport == nil then
        MiningLayers.protectedCall('buildMapReport', function()
            MiningLayers:buildMapReport(0, 0)
        end)
    end

    MiningLayers.protectedCall('resolveAllAreas', function()
        MiningLayers:resolveAllAreas()
    end)

    MiningLayers.protectedCall('subscribeAreaUpdates', function()
        MiningLayers:subscribeAreaUpdates()
    end)

    -- Anzeige-Taste (Standard Num /): registriert sich ueber die eigene
    -- Fahrzeug-Spezialisierung (MiningLayersSpec) und zusaetzlich global via
    -- PlayerInputComponent (HudMover.lua). Greift beides nicht, toggelt der
    -- Direkt-Fallback in update(). installToggleKey meldet nur den Status;
    -- Historie der Fehlversuche in HeightDisplay.lua.
    MiningLayers.protectedCall('installToggleKey', function()
        MiningLayers:installToggleKey()
    end)
end

function MiningLayers:deleteMap()
    -- Halden-Gedaechtnis wegschreiben, bevor die Welt abgebaut wird.
    pcall(function()
        MiningLayers:saveMoundMemory()
    end)

    pcall(function()
        MiningLayers:saveSurfaceMemory()
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

    -- Eingabe-/Fallback-Zustand komplett zuruecksetzen: sonst kann beim
    -- naechsten Kartenstart ein Geister-Zustand aus dem alten Spielstand
    -- weiterleben (haengende down-Flanke, stale Taste, alter Zeitstempel).
    MiningLayers.setHudMoveMode(false)
    MiningLayers.kp5WasDown = false
    MiningLayers.moveKeyWasDown = false
    MiningLayers.lastActionToggleTime = nil
    MiningLayers.lastMoveActionTime = nil
    MiningLayers.fallbackDownTime = nil
    MiningLayers.moveDownTime = nil
    MiningLayers.fallbackKey = nil
    MiningLayers.moveFallbackKey = nil
    MiningLayers.fallbackResolved = false
    MiningLayers.fallbackCapable = nil
    MiningLayers.guiWasOpen = false

    -- Auch alle Einmal-Log-Flags: beim zweiten Kartenstart sollen genau die
    -- Diagnose-Zeilen (Pfad-Forschung, Fallback-Status) wieder kommen (R6/D1).
    MiningLayers.fallbackToggleLogged = false
    MiningLayers.fallbackDisarmedLogged = false
    MiningLayers.moveFallbackLogged = false
    MiningLayers.moveFallbackDisarmedLogged = false
    MiningLayers.toggleLogCount = 0
    MiningLayers.toggleSourceLogged = {}
    MiningLayers.toggleDupLogged = false
    MiningLayers.spoilSourceLogged = {}
    MiningLayers.lastActionSpoilTime = nil
    MiningLayers.spoilKeyWasDown = false
    MiningLayers.spoilDownTime = nil
    MiningLayers.spoilFallbackKey = nil
    MiningLayers.spoilFallbackLogged = false
    MiningLayers.spoilFallbackDisarmedLogged = false
    MiningLayers.toggleVehicleApiMissingLogged = false
    MiningLayers.globalRegisterLogged = false
    MiningLayers.hudMoveHintLogged = false
    MiningLayers.freeDumpLogged = false
    MiningLayers.freeHeightLogged = false
    -- Hinweis "Zielhoehe schneidet die unterste Schicht ab", einmal je Bereich.
    MiningLayers.floorHintByArea = {}
    MiningLayers.freeHeightInGroundLogged = false
    MiningLayers.freeHeightBlockedLogged = {}
    MiningLayers.sideLogged = false
    MiningLayers.diagLastTimes = {}
    MiningLayers.mapReport = nil
    -- Sonst schweigt die "keine Schicht"-Diagnose beim zweiten Kartenstart derselben
    -- Sitzung, obwohl sie greifen muesste (Percys Review 1.5.0).
    MiningLayers.loggedNoLayerReasons = {}

    -- ⚠️ Kartenbezogene Daten muessen hier mit weg: bleibt der Material-Pool der
    -- vorigen Karte stehen und schlaegt der neue Aufbau fehl (protectedCall),
    -- filtert die Schichten-Auswahl beim naechsten Spielstand nach der ALTEN
    -- Karte. Gleiche Regel wie bei den Log-Flags (Percys Review 1.4.3).
    MiningLayers.materialPool = nil
    MiningLayers.keptLayers = {}

    MiningLayers.active = false
end

---Direkt-Fallback fuer die Anzeige-Taste (seit 1.4.1.6). Hintergrund: Auf
---grossen Modlisten (Tommys 334er-Installation, Diagnose 10.08.) bekommt unsere
---Action trotz erfolgreicher Registrierung (success=true, Kontext=VEHICLE,
---Binding im Profil) NIE einen Callback - die Binding-Aufloesung des Spiels
---greift nicht. Bewiesen hat die Diagnose aber auch: Input.isKeyPressed sieht
---jeden Druck. Also toggeln wir notfalls direkt. Selbstkalibrierend: feuert
---das Action-System (normale Modlisten), stempelt der Action-Callback
---lastActionToggleTime und der Fallback bleibt stumm.
---
---Handshake seit 1.4.2 pro DRUCK-ZYKLUS statt 1-Sekunden-Fenster: die
---down-Flanke merkt sich downTime, behandelt ist ein Druck nur, wenn der
---Action-Callback NACH dieser Flanke gestempelt hat. Damit sind beide Kanten
---aus Percys Review weg (Halten > 1 s hob den eigenen Toggle auf, Doppel-Tipp
---< 1 s wurde im Fallback verschluckt). Stempeln duerfen NUR die
---Action-Callbacks - der Fallback selbst nicht.
---
---Umbelegen funktioniert auch im Fallback: Die Taste wird aus dem Input-System
---gelesen und nach jedem Menue-Schliessen neu aufgeloest (dort wird umbelegt).
---Modifier-Tasten (Shift/Ctrl/Alt) werden dabei uebersprungen, und ohne
---Tastatur-Belegung (Gamepad-/Maus-Umbelegung) wird der Fallback DISARMT statt
---still die alte Default-Taste weiterzupollen. Default: Num / (bis 1.4.3 Num 5).
---Die Move-Taste des HUD-Verschiebens (HudMover.lua, Default Num *) nutzt
---denselben Mechanismus mit eigenem Zustand.
MiningLayers.kp5WasDown = false
MiningLayers.fallbackToggleLogged = false
MiningLayers.fallbackDisarmedLogged = false
MiningLayers.fallbackKey = nil
MiningLayers.fallbackKeyName = 'KEY_KP_divide'
MiningLayers.fallbackArmed = false
MiningLayers.fallbackResolved = false
MiningLayers.fallbackDownTime = nil
MiningLayers.guiWasOpen = false
MiningLayers.fallbackCapable = nil

MiningLayers.moveKeyWasDown = false
MiningLayers.moveFallbackLogged = false
MiningLayers.moveFallbackDisarmedLogged = false
MiningLayers.moveFallbackKey = nil
MiningLayers.moveFallbackKeyName = 'KEY_KP_multiply'
MiningLayers.moveFallbackArmed = false
MiningLayers.moveDownTime = nil

-- T14 Spoil-Toggle: dritte Taste, gleiche Zustandsmaschine.
MiningLayers.spoilKeyWasDown = false
MiningLayers.spoilFallbackLogged = false
MiningLayers.spoilFallbackDisarmedLogged = false
MiningLayers.spoilFallbackKey = nil
MiningLayers.spoilFallbackKeyName = 'KEY_KP_5'
MiningLayers.spoilFallbackArmed = false
MiningLayers.spoilDownTime = nil

---Modifier duerfen nie die Fallback-Taste werden: bei einer Kombi wie LCtrl+X
---stuende sonst der MODIFIER als Taste im Fallback (Review-Punkt B5).
MiningLayers.MODIFIER_KEY_NAMES = {
    KEY_lshift = true, KEY_rshift = true,
    KEY_lctrl = true, KEY_rctrl = true,
    KEY_lalt = true, KEY_ralt = true,
}

---Liest die aktuell belegte Tastatur-Taste einer Action aus g_inputBinding.
---Fallback-tauglich sind nur reine Tasten-Belegungen: Kombis mit Modifier
---(LShift+F5) wuerden im Fallback zur blanken Basistaste degradieren, also
---disarmen sie ihn (Percys Review R4). Ebenso eine bewusst GELEERTE Belegung:
---die Action existiert, hat aber nichts - dann gilt nur das Action-System,
---nicht der alte Default (R3).
---@param actionName string
---@param defaultKeyName string
---@return number? key nil = disarmen
---@return string keyName
function MiningLayers.resolveActionKey(actionName, defaultKeyName)
    local key = nil
    local keyName = nil
    local sawAction = false

    MiningLayers.protectedCall('resolveActionKey(' .. actionName .. ')', function()
        local action = g_inputBinding:getActionByName(actionName)

        if action == nil or action.bindings == nil then
            return
        end

        sawAction = true

        for _, binding in ipairs(action.bindings) do
            local hasModifier = false
            local candidate = nil
            local candidateName = nil

            for _, axisName in ipairs(binding.axisNames or {}) do
                if type(axisName) == 'string' and MiningLayers.MODIFIER_KEY_NAMES[axisName] then
                    hasModifier = true
                elseif candidate == nil and type(axisName) == 'string' and axisName:sub(1, 4) == 'KEY_'
                    and type(Input[axisName]) == 'number' then
                    candidate = Input[axisName]
                    candidateName = axisName
                end
            end

            if key == nil and not hasModifier and candidate ~= nil then
                key = candidate
                keyName = candidateName
            end
        end
    end)

    if key ~= nil then
        return key, keyName
    end

    if sawAction then
        -- Action gefunden, aber keine fallback-taugliche Tastatur-Taste
        -- (geleert, Kombi oder Gamepad/Maus): NICHT die Default-Taste pollen.
        return nil, defaultKeyName
    end

    -- Action nicht auffindbar (Input-System nicht greifbar): Default behalten,
    -- das war seit 1.4.1.6 der rettende Pfad.
    return Input[defaultKeyName], defaultKeyName
end

---Loest beide Fallback-Tasten neu auf (Anzeige-Toggle + HUD-Verschieben).
function MiningLayers.resolveFallbackKeys()
    local key, keyName = MiningLayers.resolveActionKey('ML_TOGGLE_HUD', 'KEY_KP_divide')

    MiningLayers.fallbackKey = key
    MiningLayers.fallbackKeyName = keyName
    MiningLayers.fallbackArmed = key ~= nil

    if key == nil and not MiningLayers.fallbackDisarmedLogged then
        MiningLayers.fallbackDisarmedLogged = true
        MiningLayers.log('Display key: no keyboard binding found (gamepad/mouse?) - direct fallback off, only the action system counts.')
    end

    local moveKey, moveKeyName = MiningLayers.resolveActionKey('ML_HUD_MOVE', 'KEY_KP_multiply')

    MiningLayers.moveFallbackKey = moveKey
    MiningLayers.moveFallbackKeyName = moveKeyName
    MiningLayers.moveFallbackArmed = moveKey ~= nil

    if moveKey == nil and not MiningLayers.moveFallbackDisarmedLogged then
        MiningLayers.moveFallbackDisarmedLogged = true
        MiningLayers.log('Move key: no keyboard binding found - direct fallback off, only the action system counts.')
    end

    local spoilKey, spoilKeyName = MiningLayers.resolveActionKey('ML_SPOIL_MODE', 'KEY_KP_5')

    MiningLayers.spoilFallbackKey = spoilKey
    MiningLayers.spoilFallbackKeyName = spoilKeyName
    MiningLayers.spoilFallbackArmed = spoilKey ~= nil

    if spoilKey == nil and not MiningLayers.spoilFallbackDisarmedLogged then
        MiningLayers.spoilFallbackDisarmedLogged = true
        MiningLayers.log('Spoil key: no keyboard binding found - direct fallback off, only the action system counts.')
    end

    local holdGradeKey, holdGradeKeyName = MiningLayers.resolveActionKey('ML_HOLD_GRADE', 'KEY_KP_2')

    MiningLayers.holdGradeFallbackKey = holdGradeKey
    MiningLayers.holdGradeFallbackKeyName = holdGradeKeyName
    MiningLayers.holdGradeFallbackArmed = holdGradeKey ~= nil

    if holdGradeKey == nil and not MiningLayers.holdGradeFallbackDisarmedLogged then
        MiningLayers.holdGradeFallbackDisarmedLogged = true
        MiningLayers.log('Grade-lock key: no keyboard binding found - direct fallback off, only the action system counts.')
    end

    MiningLayers.fallbackResolved = true
end

---Direkt-Fallback der Anzeige-Taste (Zustandsmaschine, siehe Blockkommentar oben).
---@param guiOpen boolean
function MiningLayers.updateToggleFallback(guiOpen)
    if not MiningLayers.fallbackArmed then
        return
    end

    local down = Input.isKeyPressed(MiningLayers.fallbackKey) == true

    if down and not MiningLayers.kp5WasDown then
        -- down-Flanke. Beginnt der Druck im Menue (Num-Eingabe im Dialog!),
        -- zaehlt der ganze Zyklus nicht - auch wenn draussen losgelassen wird.
        MiningLayers.fallbackDownTime = (not guiOpen) and (g_time or 0) or nil
    end

    if not down and MiningLayers.kp5WasDown then
        local downTime = MiningLayers.fallbackDownTime
        MiningLayers.fallbackDownTime = nil

        -- Behandelt = der Action-Callback hat in DIESEM Druck-Zyklus gestempelt.
        local handled = downTime == nil
            or (MiningLayers.lastActionToggleTime ~= nil
                and MiningLayers.lastActionToggleTime >= downTime)

        if not handled and not guiOpen then
            if not MiningLayers.fallbackToggleLogged then
                MiningLayers.fallbackToggleLogged = true
                MiningLayers.log('Display key runs through the direct fallback (the action binding did not take, key: %s).',
                    MiningLayers.fallbackKeyName)
            end

            MiningLayers.actionToggleHud()
        end
    end

    MiningLayers.kp5WasDown = down
end

---Direkt-Fallback der Spoil-Taste (T14 Abraum-Modus) - gleiche Zustandsmaschine.
---@param guiOpen boolean
function MiningLayers.updateSpoilFallback(guiOpen)
    if not MiningLayers.spoilFallbackArmed then
        return
    end

    local down = Input.isKeyPressed(MiningLayers.spoilFallbackKey) == true

    if down and not MiningLayers.spoilKeyWasDown then
        MiningLayers.spoilDownTime = (not guiOpen) and (g_time or 0) or nil
    end

    if not down and MiningLayers.spoilKeyWasDown then
        local downTime = MiningLayers.spoilDownTime
        MiningLayers.spoilDownTime = nil

        local handled = downTime == nil
            or (MiningLayers.lastActionSpoilTime ~= nil
                and MiningLayers.lastActionSpoilTime >= downTime)

        if not handled and not guiOpen then
            if not MiningLayers.spoilFallbackLogged then
                MiningLayers.spoilFallbackLogged = true
                MiningLayers.log('Spoil key runs through the direct fallback (the action binding did not take, key: %s).',
                    MiningLayers.spoilFallbackKeyName)
            end

            MiningLayers.actionToggleSpoilMode()
        end
    end

    MiningLayers.spoilKeyWasDown = down
end

---Direkt-Fallback der Grade-Sperren-Taste (1.6.2) - gleiche Zustandsmaschine.
---@param guiOpen boolean
function MiningLayers.updateHoldGradeFallback(guiOpen)
    if not MiningLayers.holdGradeFallbackArmed then
        return
    end

    local down = Input.isKeyPressed(MiningLayers.holdGradeFallbackKey) == true

    if down and not MiningLayers.holdGradeKeyWasDown then
        MiningLayers.holdGradeDownTime = (not guiOpen) and (g_time or 0) or nil
    end

    if not down and MiningLayers.holdGradeKeyWasDown then
        local downTime = MiningLayers.holdGradeDownTime
        MiningLayers.holdGradeDownTime = nil

        local handled = downTime == nil
            or (MiningLayers.lastActionHoldGradeTime ~= nil
                and MiningLayers.lastActionHoldGradeTime >= downTime)

        if not handled and not guiOpen then
            if not MiningLayers.holdGradeFallbackLogged then
                MiningLayers.holdGradeFallbackLogged = true
                MiningLayers.log('Grade-lock key runs through the direct fallback (the action binding did not take, key: %s).',
                    MiningLayers.holdGradeFallbackKeyName)
            end

            MiningLayers.actionToggleHoldGrade()
        end
    end

    MiningLayers.holdGradeKeyWasDown = down
end

---Direkt-Fallback der Move-Taste (HUD verschieben) - gleiche Zustandsmaschine.
---@param guiOpen boolean
function MiningLayers.updateMoveFallback(guiOpen)
    if not MiningLayers.moveFallbackArmed then
        return
    end

    local down = Input.isKeyPressed(MiningLayers.moveFallbackKey) == true

    if down and not MiningLayers.moveKeyWasDown then
        MiningLayers.moveDownTime = (not guiOpen) and (g_time or 0) or nil
    end

    if not down and MiningLayers.moveKeyWasDown then
        local downTime = MiningLayers.moveDownTime
        MiningLayers.moveDownTime = nil

        local handled = downTime == nil
            or (MiningLayers.lastMoveActionTime ~= nil
                and MiningLayers.lastMoveActionTime >= downTime)

        if not handled and not guiOpen then
            if not MiningLayers.moveFallbackLogged then
                MiningLayers.moveFallbackLogged = true
                MiningLayers.log('Move key runs through the direct fallback (key: %s).',
                    MiningLayers.moveFallbackKeyName)
            end

            MiningLayers.toggleHudMoveMode()
        end
    end

    MiningLayers.moveKeyWasDown = down
end

function MiningLayers:update(dt)
    if not MiningLayers.active then
        return
    end

    -- Im Verschiebe-Modus den Mauszeiger jeden Frame behaupten (HL-Muster:
    -- Kontextwechsel schalten ihn sonst wieder aus). VOR dem Capability-Return:
    -- der Move-Modus laeuft auch ueber die Action, ganz ohne Fallback (R5).
    if MiningLayers.hudMoveMode and g_inputBinding ~= nil
        and MiningLayers.isCallable(g_inputBinding.setShowMouseCursor) then
        g_inputBinding:setShowMouseCursor(true)
    end

    -- Faehigkeiten EINMAL pruefen statt jeden Frame (Review-Punkt C11).
    -- Auf dem Dedicated Server gibt es keine Tastatur und kein HUD.
    if MiningLayers.fallbackCapable == nil and Input ~= nil then
        MiningLayers.fallbackCapable = g_dedicatedServer == nil
            and Input.KEY_KP_divide ~= nil
            and MiningLayers.isCallable(Input.isKeyPressed)

        if not MiningLayers.fallbackCapable then
            MiningLayers.log('Direct fallback off: input API not usable (dedicated server, or an engine without isKeyPressed).')
        end
    end

    if MiningLayers.fallbackCapable ~= true then
        return
    end

    -- Tasten beim ersten Durchlauf aufloesen und nach jedem Menue-Schliessen
    -- neu (dort wird umbelegt).
    local guiOpen = g_gui ~= nil and g_gui.currentGui ~= nil

    if not MiningLayers.fallbackResolved or (MiningLayers.guiWasOpen and not guiOpen) then
        MiningLayers.resolveFallbackKeys()
    end

    MiningLayers.guiWasOpen = guiOpen

    MiningLayers.updateToggleFallback(guiOpen)
    MiningLayers.updateMoveFallback(guiOpen)
    MiningLayers.updateSpoilFallback(guiOpen)
    MiningLayers.updateHoldGradeFallback(guiOpen)
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
