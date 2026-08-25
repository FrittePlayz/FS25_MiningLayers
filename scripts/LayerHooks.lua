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
        manual      = 'a material is set on the area (manual mode) - the area has no layers.',
        off         = 'layers are switched off for this area.',
        spoil       = 'above the reference height (dumped material) - no grown ground applies there.',
        path        = 'path area - layers only exist in polygon areas.',
        noInputArea = 'the machine has NO input area assigned (machine menu, default Y).',
        noSurface   = 'reference height not set yet - it is created on the first bucket contact at this spot.',
        none        = 'no layer applies at this spot.'
    }

    MiningLayers.log('No layer: %s', texts[key] or texts.none)

    -- Der zweite Satz ist der wichtigere: was JETZT das Material bestimmt.
    --
    -- ⚠️ Bis 1.5.0 stand hier "Material der Karte" als einziger Fall. Falsch, und am
    -- TerraFarm-Quelltext belegt (FS25_0_TerraFarm 1.6.3.0):
    --   LandscapingBase.lua:69  self.fillType = ... vehicle:getMachineFillTypeIndex()
    --   LandscapingBase.lua:72  if g_resourceManager:getIsActive()
    --                              and vehicle.spec_machine.resourcesEnabled then applyMapResources()
    -- Der Normalfall ist also die MASCHINENEINSTELLUNG; applyMapResources
    -- (LandscapingInput.lua:75, kennt nur X/Z) ueberschreibt sie nur, wenn die Karte
    -- Ressourcen mitbringt UND beide Schalter an sind - global in den TerraFarm-
    -- Einstellungen und an der Maschine. Tommys Gegenprobe am 16.08.: Maschine auf
    -- COAL -> COAL in der Schaufel, auf Boden -> Boden.
    if key ~= 'manual' then
        MiningLayers.log('  -> TerraFarm decides: the material set on your machine.')
        MiningLayers.log('     Only if the map ships resources and map resources are switched on (globally')
        MiningLayers.log('     and on the machine) does applyMapResources take over instead: the material')
        MiningLayers.log('     the map carries at this spot, which only knows X/Z - the same at every depth.')
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
    local source = 'none'

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
        MiningLayers.log('Surface grid: %d cell(s) frozen on first bucket contact (source %s, %d nodes, radius %.1f m).',
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

    -- Einmal je Sitzung festhalten, WELCHE Seite den Grabpfad ausfuehrt. Der Mod
    -- hat keinerlei Mehrspieler-Code, also ist unbekannt, ob im Netzwerkspiel der
    -- Server oder der Client hier landet - und genau davon haengt ab, ob spaeter
    -- ueberhaupt etwas synchronisiert werden muss. Vier Zeilen ohne Spielwirkung:
    -- die Antwort steht dann im naechsten Serverlog, das uns ohnehin erreicht,
    -- statt eine eigene Testrunde zu kosten.
    if not self.sideLogged then
        self.sideLogged = true

        local mission = g_currentMission

        MiningLayers.log('Seite: dedicatedServer=%s, mission=%s, savegameIndex=%s',
            tostring(g_dedicatedServer ~= nil),
            tostring(mission ~= nil),
            tostring(mission ~= nil and mission.missionInfo ~= nil
                and mission.missionInfo.savegameIndex or nil))
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

    -- T14 Abraum-Modus: liegt unter der getroffenen Schicht noch eine weitere,
    -- ist sie Abraum und graebt als spoilMaterial (Standard DIRT); nur die
    -- unterste Schicht (das Floez) bleibt echt - Fels darunter ist kein Layer
    -- und liefert nil. Erkannte Halden (isMound) sind ausgenommen: das
    -- Gedaechtnis verspricht, dass zurueckkommt, was abgekippt wurde.
    -- NIE entry mutieren (geteilter Config-Eintrag) - deshalb effEntry.
    local effEntry = entry

    if self.spoilMode and entry.isMound ~= true then
        local below = self:getNextLayerBelow(op.vehicle, terrainY, zoneName, worldPosX, worldPosZ)

        if below ~= nil then
            local spoilEntry = self:getSpoilModeEntry()

            if spoilEntry ~= nil then
                effEntry = spoilEntry

                if not self.spoilModeLogged then
                    self.spoilModeLogged = true
                    MiningLayers.log('Spoil mode ON: overburden digs as %s, only the deepest layer stays real.',
                        tostring(spoilEntry.fillTypeName))
                end
            end
        end
    end

    -- 1.6.2 Grade-Sperre: targetY der laufenden Operation auf die Unterkante der
    -- getroffenen Schicht klemmen - der Zug stoppt an der Grenze, statt in einem
    -- Zug durch zwei Materialien zu gehen. Steht das Gelaende auf der Grenze,
    -- liefert findLayer beim naechsten Zug die naechste Schicht samt Material.
    --
    -- Drei bewusste Einschraenkungen:
    --   1. NUR anheben (boundary > op.targetY): eine von Hand flacher gesetzte
    --      Zielhoehe ist Nutzerwille und bleibt stehen.
    --   2. NUR wenn op.targetY eine Zahl ist: das ist der Flatten-Pfad (LOWER).
    --      Slope kennt minY, Smooth gar keine Zielhoehe - dort keine Wirkung
    --      erzwingen, die wir nicht am Quelltext belegt haben.
    --   3. NUR am op, NIE an area.targetY: die Bereichs-Zielhoehe schlaegt in die
    --      AUSGABE durch (Befund 2026-08-11, Ebnen wurde Absenken).
    -- Halden sind ausgenommen (Gedaechtnis-Vertrag), das Floez hat keine Grenze
    -- darunter (getNextLayerBelow liefert nil) und graebt frei wie bisher.
    if self.holdGrade and entry.isMound ~= true and type(op.targetY) == 'number' then
        local _, layerFloor = self:getNextLayerBelow(op.vehicle, terrainY, zoneName, worldPosX, worldPosZ)

        if layerFloor ~= nil and layerFloor > op.targetY then
            op.targetY = layerFloor

            if not self.holdGradeLogged then
                self.holdGradeLogged = true
                MiningLayers.log('Grade lock ON: the dig stops at the layer boundary (%.2f m) - one pass, one material.',
                    layerFloor)
            end
        end
    end

    local fillType = g_fillTypeManager:getFillTypeByIndex(effEntry.fillTypeIndex)

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
                and machineVehicle:getMachineFillTypeIndex() ~= effEntry.fillTypeIndex then
                self:syncStable('fill', effEntry.fillTypeIndex, function(value)
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
        local terrainLayerId = self:getTerrainLayerFor(effEntry)

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
                MiningLayers.log('ERROR while setting the discharge texture: %s', tostring(err))
                MiningLayers.log('  Further identical messages are suppressed.')
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
                MiningLayers.log('ERROR while setting the layer: %s', tostring(err))
                MiningLayers.log('  Further identical messages are suppressed.')
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
---Schaufel-im-Gelaende-Sperre einmal je Sitzung melden, nicht je Frame
MiningLayers.freeHeightInGroundLogged = false
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
                            MiningLayers.log('Dumping: output area "%s" is a layered zone - its target height (pit floor) would block every dump. Output runs free, the pile memory takes over.',
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
                                '%s (area bypassed, "%s"): mode %s, requested %.0f l, placed %.0f l',
                                fnName, tostring(areaName), MiningLayers.diagOutputMode(vehicle),
                                tonumber(liters) or -1, tonumber(result) or -1))

                            return result
                        end

                        -- Fehler im Original nicht schlucken - Original nochmal
                        -- normal laufen lassen waere doppelte Ausgabe, also melden.
                        MiningLayers.log('ERROR during free dumping: %s', tostring(result))
                        return 0
                    end
                end

                local plain = original(workArea, liters, fillTypeIndex)

                -- Ohne Bypass: genau hier entscheidet sich, ob die Ausgabe-
                -- Operation wortlos umkehrt (0 l trotz voller Schaufel).
                MiningLayers.diag(string.format(
                    '%s (no bypass): mode %s, requested %.0f l, placed %.0f l',
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

    return name, fillTypeIndex
end

---Meldet eine Abkipp-Sperre - und stellt sie sofort dem Startbefund gegenueber.
---
---Oreos Fall vom 14.08.: der Startbericht sagte "0 ohne Abkippen", Stunden
---spaeter meldete die Laufzeit "GRAVEL hat keinen Gelaende-Typ". Beide Aussagen
---kommen aus DERSELBEN Funktion (`getIsFillTypeTippable`), koennen sich in einer
---Sitzung also gar nicht widersprechen - nur lagen sie zehntausend Logzeilen
---auseinander, und niemand hat sie nebeneinandergelegt. Zwei Logs, zwei
---Sitzungen, keine Entscheidung.
---Ab jetzt bringt die Sperrmeldung ihren eigenen Gegenbeweis mit: eine Zeile
---genuegt, um Kartenproblem und Modfehler auseinanderzuhalten.
---@param name string
---@param fillTypeIndex number?
function MiningLayers.logDumpBlock(name, fillTypeIndex)
    local pool = MiningLayers.materialPool
    local status = (type(pool) == 'table' and type(pool.status) == 'table')
        and pool.status[name] or nil
    local atStart
    local contradiction = false

    if status == nil then
        -- Fremdes Bergbau-Material, das gar nicht im Schichten-Pool steht -
        -- darueber hat der Start nie eine Aussage getroffen.
        atStart = 'not checked (it is not in the layer selection)'
    elseif status == MiningLayers.MATERIAL_NO_TIP then
        atStart = 'already reported as dig-and-sell-only'
    elseif status == MiningLayers.MATERIAL_MISSING then
        atStart = 'reported as unknown to the map'
    else
        atStart = 'als nutzbar gemeldet'
        contradiction = true
    end

    MiningLayers.log('Dump blocked: "%s" (index %s) cannot be placed on the ground on this map.',
        name, tostring(fillTypeIndex or '?'))
    MiningLayers.log('  Height is NOT the cause - freeDumpHeight changes nothing about it.')
    MiningLayers.log('  Digging, trailers, silos and crushers keep working with this material.')
    MiningLayers.log('  At map start this material was %s.', atStart)

    if contradiction then
        MiningLayers.log('  !! CONTRADICTION: start-up and runtime disagree. That is a bug')
        MiningLayers.log('     in Mining Layers, not in the map. Please send this complete log to')
        MiningLayers.log('     the mod author - that documents the case.')
    else
        MiningLayers.log('  Start-up and runtime agree: it is down to the map and the mod list,')
        MiningLayers.log('     not to the mod. Fewer mods with their own ground materials frees slots.')
    end

    -- Die zweite Decke gleich mit, wenn sie greift: wer beides zugleich hat, soll
    -- nicht zwei Erklaerungen an zwei Stellen zusammensuchen muessen. Sie hat eine
    -- andere Ursache (255 Materialien insgesamt) und eine andere Wirkung
    -- (Material fehlt komplett statt nur seinen Bodenplatz zu verlieren).
    local slots = MiningLayers.slotReport

    if slots ~= nil and slots.slotsFull and slots.mapSlots ~= nil then
        MiningLayers.log('  The number behind it: this map has %d ground slots and every one is taken.',
            slots.mapSlots)
        MiningLayers.log('     That is the cause - not the place, and not the height.')
    end
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
            local blockedName, blockedIndex = MiningLayers.getUntippableLoad(workArea)

            if blockedName ~= nil then
                if MiningLayers.freeHeightBlockedLogged[blockedName] == nil then
                    MiningLayers.freeHeightBlockedLogged[blockedName] = true
                    MiningLayers.logDumpBlock(blockedName, blockedIndex)
                end

                return false
            end

            if not MiningLayers.freeHeightLogged then
                MiningLayers.freeHeightLogged = true
                MiningLayers.log('Dump height free: the TerraFarm height check (0.5 m below the bucket) is lifted - dumping works at any height.')
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

            -- ★ Sperre 1 bleibt stehen (Befund Tommy 16.08. nachts).
            --
            -- TerraFarms Original hat ZWEI Sperren (MachineWorkArea.lua:554):
            --   1. `isAreaNodeActive or outputNodeActive` - die Schaufel steckt im Boden
            --   2. Strahlen nach unten innerhalb `raycastDistance` (Vorgabe 0,5 m)
            --
            -- Bis 1.6.0.0 hoben wir BEIDE auf. Sperre 2 zu Recht: die 0,5 m sind eine
            -- willkuerliche Grenze, an der jeder auf ebenem Boden haengenblieb. Sperre 1
            -- dagegen ist keine Grenze, sondern eine Plausibilitaetspruefung - und sie
            -- ist beim Aufraeumen mit rausgeflogen.
            --
            -- Folge: mit der Schaufel im Gelaende laesst sich abkippen, und die
            -- Effekt-Ebene des Basisspiels rechnet sich fest:
            --   dataS/scripts/effects/ShaderPlaneEffect.lua:128
            --   invalid argument #3 to 'clamp' (max must be greater than or equal to min)
            -- Ein Fehler PRO FRAME, ~10.000 Log-Zeilen/s, Spiel unbedienbar, nur noch
            -- von aussen abzuschiessen. Bewiesen ueber vier Durchgaenge aus/an/aus/an
            -- (0 Treffer bei false, 3740 bzw. 1751 bei true) - siehe FIXES-Backlog T5.
            --
            -- Der Fehler steht im Basisspiel, ausgeloest wird er von uns. Wir koennen
            -- ihn nicht reparieren, also fahren wir das Spiel nicht mehr dorthin.
            --
            -- ⚠️ Das holt den Fall vom 11.08. NICHT zurueck: auf ebenem Boden mit der
            -- Schaufel UEBER dem Gelaende sind beide Flags falsch - dort blockierte
            -- Sperre 2, und die bleibt aufgehoben.
            if workArea.isAreaNodeActive or workArea.outputNodeActive then
                if not MiningLayers.freeHeightInGroundLogged then
                    MiningLayers.freeHeightInGroundLogged = true
                    MiningLayers.log('Dump height: the bucket is stuck in the terrain - dumping stays blocked (guard against the effect error flood of the base game).')
                end

                return false
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

        MiningLayers.log('DIAG ERROR in getCanDischargeToGround: %s', tostring(result))

        return superFunc(vehicle, dischargeNode)
    end

    MiningLayers.diagHooksInstalled = true

    return true
end

---Macht verschluckte Gelaende-Fehlschlaege sichtbar (Tommys Frage 18.08.: "der
---Blocker muss doch irgendwo auftauchen?" - tut er im Original nicht).
---
---TerraFarms LandscapingBase:onDeformationCallback behandelt nur STATE_SUCCESS;
---jeder andere Zustand wird kommentarlos verworfen (cancel + delete, Quelltext
---1.6.3.0, Zeile 79). Zusammen mit setBlockedAreaMaxDisplacement(0) beim Graben
---heisst das: in einer kartengesperrten Zone bewegt sich nichts, und NIEMAND sagt
---warum. Der Wrapper haengt am Klassen-Eintrag; die Engine ruft den Callback ueber
---den Objektnamen auf, also durch die Metatable - im Gegensatz zur GUI greift das.
---@return boolean
function MiningLayers:installDeformationDiagnostics()
    local base = MiningLayers.tf('LandscapingBase')

    if base == nil or not MiningLayers.isCallable(base.onDeformationCallback)
        or Utils == nil or not MiningLayers.isCallable(Utils.overwrittenFunction) then
        return false
    end

    MiningLayers.deformFailLoggedAt = {}

    base.onDeformationCallback = Utils.overwrittenFunction(base.onDeformationCallback,
        function(target, superFunc, code, volume, ...)
            local successState = (TerrainDeformation ~= nil and TerrainDeformation.STATE_SUCCESS) or 0

            -- ⚠️ Zweiter Fall (Befund 19:09, alter Riverspot): die Engine meldet eine
            -- kartengesperrte Zone NICHT als Fehler, sondern als SUCCESS mit 0 bewegtem
            -- Volumen - setBlockedAreaMaxDisplacement(0) laesst den Eingriff "gelingen",
            -- nur bewegt sich nichts. Ein einzelnes 0-Volumen ist harmlos (Boden schon
            -- auf Zielhoehe); erst eine SERIE ist das Signal.
            if code ~= nil and code == successState then
                MiningLayers.protectedCall('deformZeroDiagnostics', function()
                    if volume ~= nil and volume <= 0 then
                        MiningLayers.deformZeroStreak = (MiningLayers.deformZeroStreak or 0) + 1

                        if MiningLayers.deformZeroStreak >= 3 then
                            local now = (g_time ~= nil and g_time) or 0

                            MiningLayers.deformZeroAt = now

                            local last = MiningLayers.deformFailLoggedAt['zero']

                            if last == nil or now - last > 10000 then
                                MiningLayers.deformFailLoggedAt['zero'] = now
                                MiningLayers.log('Terrain change succeeded but moved ZERO volume %d times in a row.',
                                    MiningLayers.deformZeroStreak)
                                MiningLayers.log('  Typical causes: the map blocks this zone (blocked-area map, moved 0 by')
                                MiningLayers.log('  TerraFarm design), or the terrain already sits at the target height.')
                            end
                        end
                    else
                        MiningLayers.deformZeroStreak = 0
                    end
                end)
            end

            if code ~= nil and code ~= successState then
                MiningLayers.protectedCall('deformDiagnostics', function()
                    local now = (g_time ~= nil and g_time) or 0

                    -- Fuer die Anzeige: eben ist ein Eingriff abgelehnt worden.
                    MiningLayers.deformBlockedAt = now
                    MiningLayers.deformBlockedCode = code

                    -- Fuers Log: einmal je Zustand alle 10 s, sonst flutet der
                    -- Frame-Takt des Grabens das Log.
                    local last = MiningLayers.deformFailLoggedAt[code]

                    if last == nil or now - last > 10000 then
                        MiningLayers.deformFailLoggedAt[code] = now

                        -- Klartext-Namen aus der Engine-Tabelle suchen (STATE_*).
                        local codeName = tostring(code)

                        if TerrainDeformation ~= nil then
                            for key, value in pairs(TerrainDeformation) do
                                if value == code and type(key) == 'string' and key:sub(1, 6) == 'STATE_' then
                                    codeName = key
                                    break
                                end
                            end
                        end

                        MiningLayers.log('Terrain change REJECTED by the engine: %s (volume %s).',
                            codeName, tostring(volume))
                        MiningLayers.log('  TerraFarm drops this silently. Typical cause: the map blocks this zone')
                        MiningLayers.log('  (river corridor, map edge, placeables) - no mod setting changes that.')
                    end
                end)
            end

            return superFunc(target, code, volume, ...)
        end)

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
        MiningLayers.log('Hooks installed: %s', table.concat(installed, ', '))
    end

    if #missing > 0 then
        MiningLayers.log('WARNING: not found: %s', table.concat(missing, ', '))
        MiningLayers.log('  TerraFarm has probably changed. These digging modes stay untouched.')
    end

    if #installed == 0 then
        MiningLayers.log('Not a single hook installed - layers cannot take effect.')
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
            MiningLayers.log('Discharge texture active for: %s', table.concat(outputInstalled, ', '))
        else
            MiningLayers.log('WARNING: output classes not found - the discharge texture stays off.')
        end
    end

    if self:installFreeDumpHook() then
        MiningLayers.log('Dump guard active: a layered zone as output area no longer blocks dumping.')
    else
        MiningLayers.log('WARNING: MachineWorkArea not found - the dump guard stays off.')
    end

    if self.freeDumpHeight then
        if self:installFreeHeightHook() then
            MiningLayers.log('Dump height: the TerraFarm height check is lifted (freeDumpHeight="true").')
        else
            MiningLayers.log('WARNING: MachineWorkArea not found - the height check stays as in the original.')
        end
    else
        MiningLayers.log('Dump height: the TerraFarm height check stays active (freeDumpHeight="false").')
    end

    if self:installDeformationDiagnostics() then
        MiningLayers.log('Deformation diagnostics installed - rejected terrain changes now show up in log and display.')
    end

    if self.dumpDiagnostics then
        MiningLayers.log('*** DUMP DIAGNOSTICS ACTIVE (dumpDiagnostics="true") - writes DIAG lines to the log.')
        MiningLayers.log('    Meant for troubleshooting only; set it to "false" in miningLayers.xml to switch it off.')

        if not self:installDumpDiagnostics() then
            MiningLayers.log('    Note: Machine.getCanDischargeToGround not reachable - the "discharge allowed?" line will be missing.')
        end
    end
end
