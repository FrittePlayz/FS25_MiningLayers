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

---Protokolliert EINMAL je Grund, warum an dieser Stelle keine Schicht greift - und was
---stattdessen passiert. Bis 1.4.3 kehrte applyLayer stumm zurueck; der Spieler sah nur
---"der Mod uebernimmt nicht" und wir hatten im Log nichts zum Nachsehen. Genau das hat
---am 11.08. zwei Fehldiagnosen gekostet (Percy: Fallback-Bug, ich: Halden-Gedaechtnis).
---
---⚠️ Drosselung je MELDUNGSART, nicht gegen die zuletzt geschriebene Zeile: zwei
---abwechselnde Gruende heben eine solche Sperre gegenseitig auf (Diagnose-Vorfall vom
---11.08., 18.308 Zeilen in 12 Minuten).
---@param reason string? 'manual' | 'off' | 'spoil' | 'path' | nil
---@param vehicle table?
function MiningLayers:logNoLayerReason(reason, vehicle)
    if type(self.loggedNoLayerReasons) ~= 'table' then
        self.loggedNoLayerReasons = {}
    end

    local key = reason or 'none'

    -- Ohne Grund UND ohne Eingabe-Bereich ist es der haeufigste Supportfall
    -- (raver 10.08.) - den trennen wir vom allgemeinen "keine Schicht hier".
    if reason == nil and vehicle ~= nil and MiningLayers.isCallable(vehicle.getMachineInputArea) then
        local area, isEnabled = vehicle:getMachineInputArea()

        if area == nil or not isEnabled then
            key = 'noInputArea'
        end
    end

    if self.loggedNoLayerReasons[key] then
        return
    end

    self.loggedNoLayerReasons[key] = true

    local texts = {
        manual      = 'Material im Bereich gesetzt (Handbetrieb) - der Bereich hat keine Schichten.',
        off         = 'Schichten fuer diesen Bereich abgeschaltet.',
        spoil       = 'ueber der Bezugshoehe (Aufschuettung) - dort gilt kein gewachsener Boden.',
        path        = 'Pfad-Bereich - Schichten gibt es nur in Polygon-Bereichen.',
        noInputArea = 'die Maschine hat KEINEN Eingabe-Bereich zugewiesen (Maschinen-Menue, Standard Y).',
        none        = 'an dieser Stelle greift keine Schicht.'
    }

    MiningLayers.log('Keine Schicht: %s', texts[key] or texts.none)

    -- Der zweite Satz ist der wichtigere: was JETZT das Material bestimmt.
    if key ~= 'manual' then
        MiningLayers.log('  -> TerraFarm entscheidet (applyMapResources): Material der Karte an')
        MiningLayers.log('     dieser Stelle. Die Abfrage kennt nur X/Z - in jeder Tiefe dasselbe.')
    end
end

---Friert die Bezugshoehe rund um den Grabvorgang ein - VOR der Deformation.
---
---Gefroren wird die Bounding-Box ueber ALLE aktiven Grabknoten, je Knoten
---[p +/- (radius + Marge)]. Achsenparallele Box statt Umkreis: beim Quadrat-
---Pinsel liegt die Ecke bei radius * Wurzel(2), ein Umkreis liesse sie aus.
---Die Box umschliesst Kreis- und Quadrat-Pinsel gleichermassen, die
---Fallunterscheidung entfaellt.
---
---Die Marge ist der eigentliche Trick: Nachbarzellen werden mit eingefroren,
---SOLANGE sie unberuehrt sind. Ohne sie bekaeme der Grubenrand seine
---Bezugshoehe erst beim eigenen Erstkontakt - dann ist er durch die Zuege
---daneben laengst abgesenkt, und die Geologie wandert nach unten mit.
---@param op table
---Friert alle Rasterzellen einer achsenparallelen Box um einen Punkt ein.
---Achsenparallel statt Umkreis: beim Quadrat-Pinsel liegt die Ecke bei
---radius * Wurzel(2), ein Umkreis liesse sie aus.
---@param x number
---@param z number
---@param reach number Radius plus Marge, in Metern
---@return number written
function MiningLayers:freezeSurfaceBox(x, z, reach)
    local written = 0

    for cellX = math.floor((x - reach) / 2), math.floor((x + reach) / 2) do
        for cellZ = math.floor((z - reach) / 2), math.floor((z + reach) / 2) do
            if self:freezeSurfaceCell(cellX, cellZ) then
                written = written + 1
            end
        end
    end

    return written
end

function MiningLayers:freezeSurfaceAround(op)
    local workArea = op ~= nil and op.workArea or nil

    if workArea == nil then
        return
    end

    local radius = type(op.radius) == 'number' and op.radius or 0
    local reach = radius + MiningLayers.SURFACE_FREEZE_MARGIN
    local written = 0
    local nodes = 0
    local source = 'keine'

    local positions = workArea.areaNodePosition

    if positions ~= nil then
        for node, position in pairs(positions) do
            local active = workArea.areaNodeActive == nil or workArea.areaNodeActive[node]

            if active and position ~= nil and position[1] ~= nil and position[3] ~= nil then
                nodes = nodes + 1
                written = written + self:freezeSurfaceBox(position[1], position[3], reach)
            end
        end

        if nodes > 0 then
            source = 'Knotensatz'
        end
    end

    -- ⚠️ Rueckfall, gemessen noetig (Tommys Test 13.08., Keno City): beim Hook auf
    -- class.new ist workArea.areaNodePosition noch NICHT aufgebaut - der Pinsel
    -- fuellt ihn erst in apply(). Ohne diesen Zweig friert das Raster nie eine
    -- Zelle ein, und die Bezugshoehe bleibt stumm auf der gemittelten Ebene.
    -- Der Rootnode deckt weniger ab als der volle Knotensatz, aber die Marge
    -- faengt einen guten Teil der Schaufelbreite mit.
    if nodes == 0 and workArea.rootNode ~= nil then
        local x, _, z = getWorldTranslation(workArea.rootNode)

        if type(x) == 'number' and type(z) == 'number' then
            source = 'Rootnode'
            written = written + self:freezeSurfaceBox(x, z, reach)
        end
    end

    if written > 0 then
        self.surfaceMemoryWrites = self.surfaceMemoryWrites + written

        -- Gelegentlich wegschreiben, damit ein Absturz nicht die Session kostet.
        -- ⚠️ NICHT auf "% 25 == 0" pruefen: die Zellen kommen im Block (Tommys
        -- Test: 30 auf einmal), der Zaehler springt ueber das Vielfache hinweg
        -- und die Bedingung trifft nie zu. Gemessen am 13.08. - 30 Zellen im
        -- Speicher, keine Datei auf der Platte bis zum Beenden.
        local block = math.floor(self.surfaceMemoryWrites / 25)

        if block > (self.surfaceMemorySavedBlock or 0) then
            self.surfaceMemorySavedBlock = block
            pcall(MiningLayers.saveSurfaceMemory, MiningLayers)
        end
    end

    -- Einmal je Sitzung, AUCH bei 0 Zellen: sonst ist im Spiel nicht zu sehen,
    -- ob das Raster laeuft oder stumm aussteigt.
    if not self.surfaceFrozenLogged then
        self.surfaceFrozenLogged = true
        MiningLayers.log('Bezugshoehen-Raster: %d Zelle(n) beim ersten Grabkontakt eingefroren (Quelle %s, %d Knoten, Radius %.1f m).',
            written, source, nodes, radius)
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

    -- Bezugshoehe einfrieren, bevor irgendetwas gefragt oder verformt wird.
    self:freezeSurfaceAround(op)

    local worldPosX, _, worldPosZ = getWorldTranslation(workArea.rootNode)
    local entry, terrainY, surfaceY, zoneName, reason = self:getLayerAt(op.vehicle, worldPosX, worldPosZ)

    -- Einmalig festhalten, was hier ermittelt wurde. Das ist die Rueckfallebene der
    -- Anzeige: sie haengt an einem anderen Codepfad und traegt auch dann, wenn im
    -- Bild nichts erscheint.
    self:logFirstReading(entry, terrainY, surfaceY, zoneName)

    if entry == nil then
        -- Nicht mehr stumm: sagen, warum nichts greift und was stattdessen zaehlt.
        self:logNoLayerReason(reason, op.vehicle)

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

---Ist fuer diese Ausgabe der Bereich zu ignorieren? Ja, wenn der AUSGABE-
---Bereich der Maschine eine Schicht-Zone ist: TerraFarm kippt mit Bereich nur
---INNERHALB und nur bis zu dessen Zielhoehe ab (MachineWorkArea:outputRaise) -
---und unsere Zielhoehe ist der automatisch gesetzte GRUBENBODEN, der unter dem
---Gelaende liegt. Ergebnis waere: Schaufel leert sich nirgends, ohne Meldung
---(243er-Befund Tommy 2026-08-11). Schicht-Zonen sind Abbau-Ziele - fuer die
---Ausgabe verhalten wir uns wie ohne Bereich (frei kippen, das Halden-
---Gedaechtnis zeichnet weiter auf). Pfad-/Handbetriebs-Bereiche und
---abgeschaltete Zonen bleiben unangetastet: dort gilt TerraFarm pur.
---@param workArea table
---@return boolean bypass
---@return string? areaName
function MiningLayers:shouldBypassOutputArea(workArea)
    local vehicle = workArea ~= nil and workArea.vehicle or nil

    if vehicle == nil or not MiningLayers.isCallable(vehicle.getMachineOutputArea) then
        return false
    end

    local area, enabled = vehicle:getMachineOutputArea()

    if area == nil or not enabled then
        return false
    end

    -- Pfad-Bereich (width) oder Handbetrieb (Material gesetzt): normales TerraFarm.
    if area.width ~= nil or area.forceFillTypeIndex ~= nil then
        return false
    end

    local resolved, _, isOff = self:getResolvedForArea(area)

    if type(resolved) ~= 'table' or isOff then
        return false
    end

    return true, area.name
end

MiningLayers.freeDumpLogged = false
MiningLayers.freeDumpHookInstalled = false

-- ⚠️ Beim Laden setzen, nicht erst in deleteMap: beim ERSTEN Kartenstart hat
-- deleteMap noch nie gelaufen, und ein nil-Zugriff auf die Tabelle waere ein
-- Fehler mitten im Abkipp-Pfad.
MiningLayers.freeHeightLogged = false
MiningLayers.freeHeightHookInstalled = false
---@type table<string, boolean> je Material einmal melden, nicht je Frame
MiningLayers.freeHeightBlockedLogged = {}

--------------------------------------------------------------------------------
-- Abkipp-Diagnose (1.4.3-TEST)
--------------------------------------------------------------------------------
--
-- Warum: Am 11.08. blieb offen, WARUM Abkippen auf ebenem Boden nichts tut,
-- waehrend es in einer Grube laeuft. Es gibt drei voneinander unabhaengige
-- Pruefpunkte, und im Spiel sehen alle gleich aus (nichts passiert oder
-- "Aktion kann hier nicht ausgefuehrt werden"):
--   1. das Basisspiel (Abwurfstrahl muss den Boden erreichen),
--   2. TerraFarms Hoehenpruefung (getCanOutputToTerrain, seit 1.4.3 von uns
--      uebersteuert),
--   3. die Ausgabe-Operation selbst: LandscapingOutputFlatten:apply() laeuft nur,
--      wenn ein Arbeitsknoten UNTER der Zielhoehe liegt - sonst kehrt sie
--      wortlos um. Mit einem Ausgabe-Bereich ist diese Zielhoehe der Grubenboden.
--
-- Statt weiter zu raten, schreibt dieser Build je Versuch eine Zeile mit
-- Betriebsart, Litern rein/raus und Zustand der Pruefpunkte. Gedrosselt: gleiche
-- Meldung hoechstens alle 2 Sekunden, sonst laeuft das Log voll.
--
-- ⚠️ VOR DEM RELEASE: dumpDiagnostics standardmaessig auf false stellen.
--

---@type table<string, number> Zeitstempel je Meldungsart
MiningLayers.diagLastTimes = {}
MiningLayers.diagHooksInstalled = false

---@param message string
function MiningLayers.diag(message)
    if not MiningLayers.dumpDiagnostics then
        return
    end

    local now = (type(g_time) == 'number') and g_time or 0

    -- ⚠️ Je Meldungsart drosseln, nicht gegen die zuletzt geschriebene Zeile:
    -- zwei abwechselnde Meldungen heben eine solche Sperre gegenseitig auf.
    -- Genau das ist am 11.08. passiert - 18.000 Zeilen in 12 Minuten.
    local key = message:match('^[^:(]+') or message

    if MiningLayers.diagLastTimes[key] ~= nil
        and (now - MiningLayers.diagLastTimes[key]) < 2000 then
        return
    end

    MiningLayers.diagLastTimes[key] = now

    MiningLayers.log('DIAG %s', message)
end

---Klartextname der Betriebsart (RAISE/FLATTEN/SMOOTH/PAINT/MATERIAL/LOWER).
---Die Zahl allein sagt beim Lesen des Logs niemandem etwas.
---@param vehicle table?
---@return string
function MiningLayers.diagOutputMode(vehicle)
    if type(vehicle) ~= 'table' or not MiningLayers.isCallable(vehicle.getOutputMode) then
        return '?'
    end

    local ok, mode = pcall(vehicle.getOutputMode, vehicle)

    if not ok then
        return '?'
    end

    local machineClass = MiningLayers.tf('Machine')

    if type(machineClass) == 'table' and type(machineClass.MODE) == 'table' then
        for name, value in pairs(machineClass.MODE) do
            if value == mode then
                return tostring(name)
            end
        end
    end

    return tostring(mode)
end

---Haengt sich an die Ausgabe-Funktionen von MachineWorkArea (RAISE/FLATTEN/
---SMOOTH). Greift der Bypass, wird getMachineOutputArea am Fahrzeug fuer die
---Dauer des Original-Aufrufs durch "kein Bereich" ersetzt - der Original-Code
---laeuft dann selbst in seinen freien Zweig (kein kopiertes Internals-Wissen).
---@return boolean installed
function MiningLayers:installFreeDumpHook()
    -- Nur einmal pro Spielsitzung wrappen: ein zweiter Kartenstart wuerde
    -- sonst den Wrapper um den Wrapper wickeln (Percys Delta-Review D2).
    if MiningLayers.freeDumpHookInstalled then
        return true
    end

    local workAreaClass = MiningLayers.tf('MachineWorkArea')

    if type(workAreaClass) ~= 'table' then
        return false
    end

    local hooked = false

    for _, fnName in ipairs({ 'outputRaise', 'outputGrade', 'outputSmooth' }) do
        local original = workAreaClass[fnName]

        if MiningLayers.isCallable(original) then
            workAreaClass[fnName] = function(workArea, liters, fillTypeIndex)
                if MiningLayers.active then
                    local ok, bypass, areaName = pcall(MiningLayers.shouldBypassOutputArea, MiningLayers, workArea)

                    if ok and bypass and workArea.vehicle ~= nil then
                        if not MiningLayers.freeDumpLogged then
                            MiningLayers.freeDumpLogged = true
                            MiningLayers.log('Abkippen: Ausgabe-Bereich "%s" ist eine Schicht-Zone - dessen Zielhoehe (Grubenboden) wuerde jedes Kippen blockieren. Ausgabe laeuft frei, Halden-Gedaechtnis uebernimmt.',
                                tostring(areaName))
                        end

                        local vehicle = workArea.vehicle
                        local originalGetArea = vehicle.getMachineOutputArea

                        vehicle.getMachineOutputArea = function()
                            return nil, false
                        end

                        local okCall, result = pcall(original, workArea, liters, fillTypeIndex)

                        vehicle.getMachineOutputArea = originalGetArea

                        if okCall then
                            MiningLayers.diag(string.format(
                                '%s (Bereich umgangen, "%s"): Modus %s, angefragt %.0f l, abgelegt %.0f l',
                                fnName, tostring(areaName), MiningLayers.diagOutputMode(vehicle),
                                tonumber(liters) or -1, tonumber(result) or -1))

                            return result
                        end

                        -- Fehler im Original nicht schlucken - Original nochmal
                        -- normal laufen lassen waere doppelte Ausgabe, also melden.
                        MiningLayers.log('FEHLER beim freien Abkippen: %s', tostring(result))
                        return 0
                    end
                end

                local plain = original(workArea, liters, fillTypeIndex)

                -- Ohne Bypass: genau hier entscheidet sich, ob die Ausgabe-
                -- Operation wortlos umkehrt (0 l trotz voller Schaufel).
                MiningLayers.diag(string.format(
                    '%s (kein Bypass): Modus %s, angefragt %.0f l, abgelegt %.0f l',
                    fnName, MiningLayers.diagOutputMode(workArea.vehicle),
                    tonumber(liters) or -1, tonumber(plain) or -1))

                return plain
            end

            hooked = true
        end
    end

    MiningLayers.freeDumpHookInstalled = hooked

    return hooked
end

---Hebt TerraFarms Hoehensperre fuers Abkippen auf (1.4.3, Tommys Vorgabe:
---"muss auf jeder Hoehe auf jeder Karte gehen").
---
---Mechanik im Original (`MachineWorkArea:getCanOutputToTerrain`, gegen den
---Quelltext von TerraFarm 1.6.3.0 gelesen) - ZWEI Sperren, beide reine
---Hoehenfragen:
---  1. `isAreaNodeActive` / `outputNodeActive`: wahr, sobald das Gelaende AN
---     ODER UEBER einem Arbeitsknoten liegt (Schaufel steckt im Boden).
---  2. Ein Strahl senkrecht unter dem Ausgabeknoten: trifft er innerhalb von
---     `raycastDistance` (Vorgabe 0,5 m) Gelaende, ist Abkippen gesperrt.
---Sperre 2 ist die, ueber die jeder stolpert: auf ebenem Boden liegt das
---Gelaende naeher als einen halben Meter unter der Schaufelkante, also
---verweigert das Spiel mit "Aktion kann hier nicht ausgefuehrt werden" - und
---der Text zeigt auf den ORT, obwohl es die Hoehe ist. Ueber einer Grube geht
---es, zwei Meter daneben nicht (Tommys Live-Gegenprobe 11.08.).
---
---Wir schalten beide ab statt nur die Distanz zu senken: eine kleinere Distanz
---waere wieder eine willkuerliche Grenze, an der Nutzer haengenbleiben.
---Abschaltbar ueber `freeDumpHeight="false"` in der miningLayers.xml - falls
---sich im Betrieb doch ein Nachteil zeigt, ohne neuen Build.
---Das Material, das gerade in der Schaufel liegt - aber nur, wenn es sich auf
---dieser Karte NICHT ablegen laesst. Sonst nil.
---@param workArea table
---@return string? fillTypeName
function MiningLayers.getUntippableLoad(workArea)
    local vehicle = type(workArea) == 'table' and workArea.vehicle or nil
    local spec = type(vehicle) == 'table' and vehicle.spec_machine or nil

    if type(spec) ~= 'table' or not MiningLayers.isCallable(vehicle.getFillUnitFillType) then
        return nil
    end

    -- TerraFarm merkt sich den Index beim Laden (Machine.lua:375); der
    -- dischargeNode ist der Rueckfall, falls das mal umgebaut wird.
    local unitIndex = spec.fillUnitIndex
        or (type(spec.dischargeNode) == 'table' and spec.dischargeNode.fillUnitIndex or nil)

    if unitIndex == nil then
        return nil
    end

    local ok, fillTypeIndex = pcall(vehicle.getFillUnitFillType, vehicle, unitIndex)

    if not ok or type(fillTypeIndex) ~= 'number' or fillTypeIndex <= 0 then
        return nil
    end

    -- ⚠️ FillType.UNKNOWN ist NICHT 0, sondern 1 - eine leere Schaufel meldet
    -- also einen gueltigen Index, und die Ablegbarkeits-Pruefung sagt darauf
    -- "nein". Ohne diese Zeile blockiert der Schutz genau dann, wenn gar kein
    -- Material im Weg ist (live im Log: 'UNKNOWN hat keinen Gelaende-Typ').
    local unknown = (FillType ~= nil and FillType.UNKNOWN) or 1

    if fillTypeIndex == unknown then
        return nil
    end

    if MiningLayers:getIsFillTypeTippable(fillTypeIndex) ~= false then
        return nil
    end

    local fillType = g_fillTypeManager ~= nil
        and g_fillTypeManager:getFillTypeByIndex(fillTypeIndex) or nil
    local name = fillType ~= nil and fillType.name or tostring(fillTypeIndex)

    -- Zweiter Gurt: manche Fassungen melden den Namen statt des Index.
    if name == 'UNKNOWN' then
        return nil
    end

    return name
end

---@return boolean
function MiningLayers:installFreeHeightHook()
    if MiningLayers.freeHeightHookInstalled then
        return true
    end

    local workAreaClass = MiningLayers.tf('MachineWorkArea')

    if type(workAreaClass) ~= 'table' then
        return false
    end

    local original = workAreaClass.getCanOutputToTerrain

    if not MiningLayers.isCallable(original) then
        return false
    end

    workAreaClass.getCanOutputToTerrain = function(workArea, ...)
        if MiningLayers.active and MiningLayers.freeDumpHeight then
            -- ⚠️ NICHT uebersteuern, wenn das Material gar keinen Gelaende-Typ
            -- hat, weil der Karte die Bodenplaetze ausgingen. Sonst sagt TerraFarm
            -- "du darfst kippen", die
            -- Engine kann es aber nirgends hinlegen: 0 Liter, keine Meldung -
            -- genau die stille Falle, die wir beim Ausgabe-Bereich gerade
            -- beseitigt haben. Mit false kommt die ehrliche Absage des Spiels
            -- zurueck, passend zur (!)-Marke in der Schichten-Auswahl.
            local blockedName = MiningLayers.getUntippableLoad(workArea)

            if blockedName ~= nil then
                if MiningLayers.freeHeightBlockedLogged[blockedName] == nil then
                    MiningLayers.freeHeightBlockedLogged[blockedName] = true
                    MiningLayers.log('Abkipp-Hoehe: "%s" hat auf dieser Karte keinen Gelaende-Typ - Abkippen bleibt gesperrt (Hoehe ist nicht die Ursache).',
                        blockedName)
                end

                return false
            end

            if not MiningLayers.freeHeightLogged then
                MiningLayers.freeHeightLogged = true
                MiningLayers.log('Abkipp-Hoehe frei: TerraFarms Hoehenpruefung (0,5 m unter der Schaufel) ist aufgehoben - Abkippen geht auf jeder Hoehe.')
            end

            -- Nur im Diagnosebetrieb das Original zusaetzlich fragen: es
            -- raycastet, das kostet. Dafuer steht dann im Log, ob unsere
            -- Uebersteuerung ueberhaupt etwas geaendert haette.
            if MiningLayers.dumpDiagnostics then
                local okOrig, origResult = pcall(original, workArea, ...)

                MiningLayers.diag(string.format(
                    'Hoehenpruefung: Original haette %s gesagt (Knoten im Boden: %s / Ausgabeknoten im Boden: %s) - wir sagen ja',
                    okOrig and tostring(origResult) or 'FEHLER',
                    tostring(workArea.isAreaNodeActive), tostring(workArea.outputNodeActive)))
            end

            return true
        end

        return original(workArea, ...)
    end

    MiningLayers.freeHeightHookInstalled = true

    return true
end

---Legt sich um TerraFarms Entscheidung "darf diese Maschine auf den Boden
---abladen" und schreibt ihr Ergebnis ins Log. Das ist die Stelle, an der die
---Meldung "Aktion kann hier nicht ausgefuehrt werden" entsteht - hier trennt
---sich Basisspiel (superFunc) von TerraFarm.
---
---⚠️ Wirkt nur, wenn diese Datei laeuft, BEVOR die Fahrzeuge ihre
---Spezialisierung binden (TerraFarm haengt die Funktion je Fahrzeug in onLoad
---an). Bleibt das Log leer, ist genau das die Erkenntnis - dann muessen wir am
---Fahrzeug statt an der Klasse ansetzen.
---@return boolean
function MiningLayers:installDumpDiagnostics()
    if MiningLayers.diagHooksInstalled or not MiningLayers.dumpDiagnostics then
        return MiningLayers.diagHooksInstalled
    end

    local machineClass = MiningLayers.tf('Machine')

    if type(machineClass) ~= 'table' or not MiningLayers.isCallable(machineClass.getCanDischargeToGround) then
        return false
    end

    local original = machineClass.getCanDischargeToGround

    -- Signatur wie im Original: (self, superFunc, dischargeNode) - TerraFarm
    -- haengt sie ueber Utils.overwrittenFunction ein.
    machineClass.getCanDischargeToGround = function(vehicle, superFunc, dischargeNode)
        local okCall, result = pcall(original, vehicle, superFunc, dischargeNode)

        if okCall then
            MiningLayers.diag(string.format(
                'Abladen erlaubt? %s (Modus %s, Strahl trifft Boden: %s)',
                tostring(result), MiningLayers.diagOutputMode(vehicle),
                tostring(dischargeNode ~= nil and dischargeNode.dischargeHitTerrain)))

            return result
        end

        MiningLayers.log('DIAG FEHLER in getCanDischargeToGround: %s', tostring(result))

        return superFunc(vehicle, dischargeNode)
    end

    MiningLayers.diagHooksInstalled = true

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

    if self:installFreeDumpHook() then
        MiningLayers.log('Abkipp-Schutz aktiv: Schicht-Zone als Ausgabe-Bereich blockiert das Kippen nicht mehr.')
    else
        MiningLayers.log('WARNUNG: MachineWorkArea nicht gefunden - Abkipp-Schutz bleibt aus.')
    end

    if self.freeDumpHeight then
        if self:installFreeHeightHook() then
            MiningLayers.log('Abkipp-Hoehe: TerraFarms Hoehenpruefung wird aufgehoben (freeDumpHeight="true").')
        else
            MiningLayers.log('WARNUNG: MachineWorkArea nicht gefunden - Hoehenpruefung bleibt wie im Original.')
        end
    else
        MiningLayers.log('Abkipp-Hoehe: TerraFarms Hoehenpruefung bleibt aktiv (freeDumpHeight="false").')
    end

    if self.dumpDiagnostics then
        MiningLayers.log('*** ABKIPP-DIAGNOSE AKTIV (dumpDiagnostics="true") - schreibt DIAG-Zeilen ins Log.')
        MiningLayers.log('    Nur fuer die Fehlersuche gedacht; zum Abschalten in der miningLayers.xml auf "false".')

        if not self:installDumpDiagnostics() then
            MiningLayers.log('    Hinweis: Machine.getCanDischargeToGround nicht greifbar - die Zeile "Abladen erlaubt?" fehlt dann.')
        end
    end
end
