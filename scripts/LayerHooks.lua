--
-- Die Hooks.
--
-- Gehaengt wird an die drei TerraFarm-Klassen, die beim Graben Material in die
-- Schaufel liefern: LandscapingInputFlatten, LandscapingInputSlope und
-- LandscapingInputSmooth. LandscapingInputPaint malt nur und bleibt aussen vor,
-- die Output-Klassen ebenfalls: beim Abladen kommt das Material aus der Schaufel.
--
-- Der Wrapper laesst das Original zuerst laufen. Danach stehen fillType,
-- terrainLayerId und ein eventuelles Map-Resources-Ergebnis bereits fest -
-- unsere Schicht setzt sich also gegen beides durch. Das ist gewollt: Schichten
-- sind pro Bereich definiert und damit spezifischer.
--

---@diagnostic disable: lowercase-global, undefined-global

MiningLayers.HOOK_CLASSES = {
    'LandscapingInputFlatten',
    'LandscapingInputSlope',
    'LandscapingInputSmooth'
}

---Ausgabe-Seite: hier wird KEIN Material geaendert - was abgeladen wird, kommt aus der
---Schaufel. Gesetzt wird nur die Bodentextur, damit ein Abraumhaufen anders aussieht
---als eine Paydirt-Halde. Ohne das sind die Halden optisch nicht zu unterscheiden.
---
---Bei allen drei Klassen ist fillTypeIndex der 3. Parameter:
---  OutputFlatten.new(workArea, terrainLayerId, fillTypeIndex, litersToDrop, targetY)
---  OutputSlope.new  (workArea, terrainLayerId, fillTypeIndex, litersToDrop, minY, ...)
---  OutputSmooth.new (workArea, terrainLayerId, fillTypeIndex, litersToDrop)
MiningLayers.OUTPUT_HOOK_CLASSES = {
    'LandscapingOutputFlatten',
    'LandscapingOutputSlope',
    'LandscapingOutputSmooth'
}

---Millisekunden, die ein Sync-Wert stabil anliegen muss, bevor das HUD umschaltet.
MiningLayers.SYNC_DEBOUNCE_MS = 750
---@type table<string, table> laufende Sync-Kandidaten je Feld
MiningLayers.syncCandidates = {}

---Schaltet einen HUD-Wert erst um, wenn er kurz stabil war.
---
---Grund (Tommys Befund): am Haldenrand feuern die Grab-Operationen abwechselnd in
---die Halde und in den gewachsenen Boden - ohne Daempfung springt das HUD rechts
---im Sekundentakt zwischen den Materialien hin und her.
---@param kind string 'fill' | 'inputLayer' | 'outputLayer'
---@param value number
---@param apply function bekommt den Wert, wenn er stabil ist
function MiningLayers:syncStable(kind, value, apply)
    local now = type(g_time) == 'number' and g_time or nil

    if now == nil then
        -- Keine Zeitquelle: lieber sofort schalten als gar nicht.
        apply(value)
        return
    end

    local candidate = self.syncCandidates[kind]

    if candidate == nil or candidate.value ~= value then
        self.syncCandidates[kind] = { value = value, since = now }
        return
    end

    if now - candidate.since >= MiningLayers.SYNC_DEBOUNCE_MS then
        apply(value)
    end
end

---Setzt das Schichtmaterial an einer laufenden Grab-Operation.
---@param op table LandscapingInput*-Instanz
function MiningLayers:applyLayer(op)
    if not self.enabled or op == nil then
        return
    end

    local workArea = op.workArea

    if workArea == nil or workArea.rootNode == nil then
        return
    end

    local worldPosX, _, worldPosZ = getWorldTranslation(workArea.rootNode)
    local entry, terrainY, surfaceY, zoneName = self:getLayerAt(op.vehicle, worldPosX, worldPosZ)

    -- Einmalig festhalten, was hier ermittelt wurde. Das ist die Rueckfallebene der
    -- Anzeige: sie haengt an einem anderen Codepfad und traegt auch dann, wenn im
    -- Bild nichts erscheint.
    self:logFirstReading(entry, terrainY, surfaceY, zoneName)

    if entry == nil then
        return
    end

    local fillType = g_fillTypeManager:getFillTypeByIndex(entry.fillTypeIndex)

    if fillType ~= nil then
        op.fillType = fillType

        -- TerraFarms HUD rechts folgt der Schicht: die Fahrzeug-Auswahl springt auf
        -- das Material um, das tatsaechlich in die Schaufel kommt. Offizieller Setter
        -- inkl. MP-Event (Machine.lua:955). Nur bei Aenderung - kein Event-Spam.
        -- Im Handbetrieb und auf Halden ('spoil') kommt dieser Code nie an, dort
        -- bleibt die Auswahl des Spielers unangetastet.
        if self.syncVehicleMaterial then
            local machineVehicle = op.vehicle

            if machineVehicle ~= nil
                and MiningLayers.isCallable(machineVehicle.getMachineFillTypeIndex)
                and MiningLayers.isCallable(machineVehicle.setMachineFillTypeIndex)
                and machineVehicle:getMachineFillTypeIndex() ~= entry.fillTypeIndex then
                self:syncStable('fill', entry.fillTypeIndex, function(value)
                    pcall(machineVehicle.setMachineFillTypeIndex, machineVehicle, value)
                end)
            end
        end
    end

    -- Bodentextur mitziehen, sonst sehen alle Schichten aus wie die Fahrzeugeinstellung
    -- und man sieht beim Graben keinen Unterschied. TerraFarm macht es bei
    -- Map-Resources genauso (LandscapingInput:applyMapResources).
    -- Ausnahme: eine ausdruecklich im Bereich gesetzte Grabtextur ist Nutzerwille und
    -- bleibt stehen - dieselbe Regel wie forceOutputLayer beim Abladen.
    local forcedInputLayer = nil
    local vehicle = op.vehicle

    if vehicle ~= nil and MiningLayers.isCallable(vehicle.getMachineInputArea) then
        local inputArea, inputAreaEnabled = vehicle:getMachineInputArea()

        if inputArea ~= nil and inputAreaEnabled then
            forcedInputLayer = inputArea.forceInputLayer
        end
    end

    if forcedInputLayer == nil then
        local terrainLayerId = self:getTerrainLayerFor(entry)

        if terrainLayerId ~= nil then
            op.terrainLayerId = terrainLayerId

            -- TerraFarms HUD rechts: die Grabtextur-Anzeige folgt der Schicht -
            -- sonst steht da eine Textur, die beim Graben laengst ueberschrieben wird.
            if self.syncVehicleMaterial and vehicle ~= nil
                and MiningLayers.isCallable(vehicle.getMachineInputLayerId)
                and MiningLayers.isCallable(vehicle.setMachineInputLayerId)
                and vehicle:getMachineInputLayerId() ~= terrainLayerId then
                self:syncStable('inputLayer', terrainLayerId, function(value)
                    pcall(vehicle.setMachineInputLayerId, vehicle, value)
                end)
            end
        end
    end
end

---Setzt beim Abladen die Bodentextur passend zum Material aus der Schaufel.
---@param op table LandscapingOutput*-Instanz
---@param forcedLayerId number? vom Bereich erzwungene Textur (Parameter 2)
---@param fillTypeIndex number? Material aus der Schaufel (Parameter 3)
function MiningLayers:applyOutputTexture(op, forcedLayerId, fillTypeIndex)
    if op == nil or fillTypeIndex == nil then
        return
    end

    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    if fillType == nil or fillType.name == nil then
        return
    end

    -- Handbetrieb auch beim Abladen: hat der Ziel-Bereich ein eigenes Material
    -- gesetzt (= normale TerraFarm-Baustelle), fasst der Mod dort nichts an -
    -- auch das Halden-Gedaechtnis nicht.
    local vehicle = op.vehicle

    if vehicle ~= nil and MiningLayers.isCallable(vehicle.getMachineOutputArea) then
        local outputArea, outputAreaEnabled = vehicle:getMachineOutputArea()

        if outputArea ~= nil and outputAreaEnabled and outputArea.forceFillTypeIndex ~= nil then
            return
        end
    end

    -- Halden-Gedaechtnis fuellen: was hier abgekippt wird, wird hier auch wieder
    -- aufgenommen. Unabhaengig vom Texturabgleich - das Gedaechtnis schuetzt vor
    -- Material-Zauberei, die Textur ist nur Optik.
    local workArea = op.workArea

    if workArea ~= nil and workArea.rootNode ~= nil then
        local x, _, z = getWorldTranslation(workArea.rootNode)

        self:recordMound(x, z, fillType.name)
    end

    if not self.matchOutputTexture then
        return
    end

    -- Ein Bereich mit forceOutputLayer hat Vorrang: das ist ausdruecklicher Nutzerwille.
    if forcedLayerId ~= nil then
        return
    end

    local terrainLayerId = self:getTerrainLayerForFillType(fillType.name)

    if terrainLayerId ~= nil then
        op.terrainLayerId = terrainLayerId

        -- TerraFarms HUD rechts: die Abladetextur-Anzeige folgt dem, was wirklich
        -- gemalt wird - sonst steht da eine Textur, die laengst ueberschrieben ist.
        if self.syncVehicleMaterial and vehicle ~= nil
            and MiningLayers.isCallable(vehicle.getMachineOutputLayerId)
            and MiningLayers.isCallable(vehicle.setMachineOutputLayerId)
            and vehicle:getMachineOutputLayerId() ~= terrainLayerId then
            self:syncStable('outputLayer', terrainLayerId, function(value)
                pcall(vehicle.setMachineOutputLayerId, vehicle, value)
            end)
        end
    end
end

---Haengt sich an eine Ausgabe-Klasse.
---@param className string
---@return boolean installed
function MiningLayers:installOutputHook(className)
    local class = MiningLayers.tf(className)

    if type(class) ~= 'table' or not MiningLayers.isCallable(class.new) then
        return false
    end

    local original = class.new

    class.new = function(...)
        local op = original(...)

        if MiningLayers.active and op ~= nil then
            local forcedLayerId = select(2, ...)
            local fillTypeIndex = select(3, ...)

            local ok, err = pcall(MiningLayers.applyOutputTexture, MiningLayers, op, forcedLayerId, fillTypeIndex)

            if not ok and not MiningLayers.outputHookErrorReported then
                MiningLayers.outputHookErrorReported = true
                MiningLayers.log('FEHLER beim Setzen der Abladetextur: %s', tostring(err))
                MiningLayers.log('  Weitere gleiche Meldungen werden unterdrueckt.')
            end
        end

        return op
    end

    return true
end

---Haengt sich an eine Klasse. Fehlt sie, passiert nichts.
---@param className string
---@return boolean installed
function MiningLayers:installHook(className)
    -- Die Klasse liegt in TerraFarms Umgebung, nicht in unserer.
    local class = MiningLayers.tf(className)

    if type(class) ~= 'table' or not MiningLayers.isCallable(class.new) then
        return false
    end

    local original = class.new

    class.new = function(...)
        local op = original(...)

        if MiningLayers.active and op ~= nil then
            local ok, err = pcall(MiningLayers.applyLayer, MiningLayers, op)

            if not ok and not MiningLayers.hookErrorReported then
                MiningLayers.hookErrorReported = true
                MiningLayers.log('FEHLER beim Setzen der Schicht: %s', tostring(err))
                MiningLayers.log('  Weitere gleiche Meldungen werden unterdrueckt.')
            end
        end

        return op
    end

    return true
end

function MiningLayers:installHooks()
    local installed = {}
    local missing = {}

    for _, className in ipairs(MiningLayers.HOOK_CLASSES) do
        if self:installHook(className) then
            table.insert(installed, className)
        else
            table.insert(missing, className)
        end
    end

    if #installed > 0 then
        MiningLayers.log('Hooks gesetzt: %s', table.concat(installed, ', '))
    end

    if #missing > 0 then
        MiningLayers.log('WARNUNG: nicht gefunden: %s', table.concat(missing, ', '))
        MiningLayers.log('  Vermutlich hat sich TerraFarm geaendert. Diese Grabarten bleiben unveraendert.')
    end

    if #installed == 0 then
        MiningLayers.log('Kein einziger Hook gesetzt - Schichten koennen nicht wirken.')
        MiningLayers.active = false
        return
    end

    if self.matchOutputTexture then
        local outputInstalled = {}

        for _, className in ipairs(MiningLayers.OUTPUT_HOOK_CLASSES) do
            if self:installOutputHook(className) then
                table.insert(outputInstalled, className)
            end
        end

        if #outputInstalled > 0 then
            MiningLayers.log('Abladetextur aktiv fuer: %s', table.concat(outputInstalled, ', '))
        else
            MiningLayers.log('WARNUNG: Ausgabe-Klassen nicht gefunden - Abladetextur bleibt aus.')
        end
    end
end
