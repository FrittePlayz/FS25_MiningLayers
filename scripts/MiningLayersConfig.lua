--
-- Konfiguration, Zonen und Schichtermittlung.
--
-- Eine Zone haelt nur die Schichtdicken. Die Bezugshoehe kommt pro Bereich dazu und
-- wird aus dessen Umrandung ermittelt, sofern sie nicht fest eingetragen ist.
--

---@diagnostic disable: lowercase-global, undefined-global

MiningLayers.CONFIG_FILENAME = 'miningLayers.xml'

MiningLayers.enabled = true
MiningLayers.showHeightDisplay = true
MiningLayers.checkMaterials = true
-- T14 Abraum-Modus: alles OBERHALB des Floezes (= unterste Schicht) graebt als EIN
-- Material (spoilMaterial, Standard DIRT) - nur das Floez bleibt echt. Loest das
-- Kipper-Problem (eine Fracht pro Mulde; Oreo/RGC 19.08.). Erkannte Halden sind
-- ausgenommen: das Halden-Gedaechtnis verspricht, dass zurueckkommt, was abgekippt
-- wurde. Phase 1 = reiner Config-Schalter (kein Keybind, bewusst - erst Verhalten
-- testen, dann Ergonomie).
MiningLayers.spoilMode = false
MiningLayers.spoilMaterial = 'DIRT'
-- Beim Abladen die Bodentextur zum Material aus der Schaufel setzen.
MiningLayers.matchOutputTexture = true
-- Grubenboden (targetY) automatisch tief genug setzen. ⚠️ VORGABE SEIT 1.6: AUS.
-- Grund: eine bewusst gesetzte Zielhoehe ist von einer beilaeufigen nicht zu
-- unterscheiden (Beleg in maybeSetPitFloor an LandscapingAreaPolygon). Wer eine
-- ebene Flaeche planiert, bekam sonst ungefragt ein Loch - Oreo (RGC), 16.08.
-- Ist der Schalter aus, sagt der Mod nur Bescheid, wenn die Zielhoehe die unterste
-- Schicht abschneidet.
MiningLayers.autoTargetHeight = true
-- Oberhalb von Bezugshoehe + Toleranz gilt das Gelaende als aufgeschuettet (Halde).
-- Dort entscheidet die TerraFarm-Auswahl, nicht die oberste Schicht - sonst wird
-- aus jeder GRAVEL-Halde beim Wiederaufnehmen DIRT. Die Toleranz faengt natuerliche
-- Bodenwellen im Bereich ab (der Median glaettet nicht alles).
-- Nur noch Rueckfall fuer UNBEKANNTE Halden: bekannte laufen ueber das Gedaechtnis,
-- das an der Ursprungshoehe der Zelle haengt, nicht an der Bezugshoehe.
MiningLayers.SPOIL_TOLERANCE = 0.5
-- Eine gemerkte Halde gilt als aufgebraucht, sobald das Gelaende ihrer Zelle bis auf
-- diese Toleranz auf die Ursprungshoehe (baseY) zurueckgegraben ist. Dann fliegt die
-- Zelle aus dem Gedaechtnis und darunter gelten wieder die Schichten.
MiningLayers.MOUND_DEPLETE_TOLERANCE = 0.1
-- Schonfrist nach dem letzten Abwurf in eine Zelle: solange wird sie nicht auf
-- "aufgebraucht" geprueft. Waehrend des Kippens ist der Haufen noch flach und die
-- Pruefung wuerde die frische Zelle loeschen (Live-Log 2026-08-08 21:41: dieselbe
-- Zelle 19x pro Sekunde geloescht und mit steigender Basis neu angelegt).
MiningLayers.MOUND_DELETE_GRACE_MS = 20000
-- Haldenmaterial gibt es nur, solange der GRABPUNKT ueber der Haldenbasis liegt -
-- mit dieser Gnade nach unten, damit duenne Raender nicht die Schaufel mit
-- Schichtmaterial vergiften. Klar UNTER der Basis kommt sofort die Geologie.
-- Ohne diese Regel: Krater-Cheat (Tommys Befund 2026-08-09 01:1x, unter Wasser) -
-- mitten in der Zelle tiefer graben liess die Zellwaende "leben" und lieferte
-- endlos GRAVEL aus einer einzigen abgekippten Schaufel.
MiningLayers.MOUND_BELOW_BASE_TOLERANCE = 0.15
-- Schichtgrenzen als Linien entlang der Bereichs-Umrandung zeichnen.
MiningLayers.showDepthLines = true
-- TerraFarms Fahrzeug-Auswahl (HUD rechts) springt beim Graben auf die Schicht um.
MiningLayers.syncVehicleMaterial = true
---Hebt TerraFarms Hoehenpruefung fuers Abkippen auf (1.4.3). Vorgabe an; wer
---das Originalverhalten will, setzt es in der miningLayers.xml auf false.
MiningLayers.freeDumpHeight = true
---Schreibt bei jedem Abkippversuch eine DIAG-Zeile ins Log. Reines Werkzeug fuer
---die Fehlersuche, deshalb aus: der Abkipp-Pfad laeuft mehrmals pro Sekunde.
MiningLayers.dumpDiagnostics = false

MiningLayers.displayPosX = 0.012
MiningLayers.displayPosY = 0.55

---@type table<string, table> Zonen mit ausdruecklichem Bereichsbezug, Schluessel kleingeschrieben
MiningLayers.zonesByKey = {}
---@type table? Vorgabe fuer jeden Bereich ohne eigene Zone
MiningLayers.defaultZone = nil
---@type table? Gilt ueberall, wo keine Maschine einen Bereich zugewiesen hat
MiningLayers.globalZone = nil
---@type table? Dieselbe Zone, aber abgeschaltet - nur aufgehoben, damit sie beim
--- Speichern nicht aus der Datei faellt und der Schalter sie umlegen kann.
MiningLayers.globalZoneOff = nil

---@type table<string, table> Cache der aufgeloesten Schichten je Bereich (uniqueId)
MiningLayers.resolvedByArea = {}
---Zuletzt automatisch gesetzter Grubenboden je Bereich (uniqueId -> targetY).
---Damit erkennt der Mod nach einer Bereichs-Aenderung seinen EIGENEN Wert wieder
---und zieht den Boden zu den neuen Schichten nach - ein Handwert saehe genauso
---"tief unter der Bezugsflaeche" aus und bliebe sonst faelschlich stehen.
---Nur fuer die laufende Session: nach einem Neuladen ist der gespeicherte targetY
---nicht mehr von einem Handwert zu unterscheiden und bleibt dann stehen.
---@type table<string, number>
MiningLayers.autoFloorByArea = {}
---@type table? Aufgeloeste Schichten der Testzone
MiningLayers.resolvedGlobal = nil

---Halden-Gedaechtnis: 2-m-Rasterzelle -> { f = Materialname, b = Ursprungshoehe }.
---Beim Abkippen gefuellt, beim Graben VOR allem anderen abgefragt - damit aus einer
---GRAVEL-Halde nie per Auswahl PAYDIRT wird. Die Ursprungshoehe (baseY) wird beim
---ERSTEN Abwurf in eine Zelle festgehalten, bevor der Abwurf das Gelaende anhebt:
---die Halde gilt von ihrer Basis bis zur Spitze, egal ob sie ueber oder unter der
---Bezugshoehe des Bereichs steht (Halde am Hang, Verfuellung in der Grube).
---Zurueckgegraben bis baseY -> Zelle wird geloescht, darunter gelten die Schichten.
---Gespeichert pro Spielstand unter modSettings.
---@type table<string, table>
MiningLayers.moundMemory = {}
MiningLayers.moundMemoryDirty = false
MiningLayers.moundMemoryWrites = 0
---Bezugshoehen-Raster: 2-m-Zelle -> Hoehe des GEWACHSENEN Bodens.
---Gefuellt beim Grabkontakt, VOR der Deformation (LayerHooks), fuer die ganze
---Bounding-Box des Pinsels plus Marge. Einmal geschrieben, nie ueberschrieben:
---sonst wandert die Geologie am Grubenrand mit nach unten.
---Ersetzt die Ebene aus computeSurfaceY dort, wo Werte vorliegen; wo keine
---vorliegen, bleibt die Ebene der Rueckfall (identisches Verhalten wie 1.4.x).
---Gespeichert pro Spielstand unter modSettings.
---@type table<string, number>
MiningLayers.surfaceMemory = {}
MiningLayers.surfaceMemoryDirty = false
MiningLayers.surfaceMemoryWrites = 0
---Letzter bereits weggeschriebener 25er-Block (Schwelle ohne Modulo-Falle).
MiningLayers.surfaceMemorySavedBlock = 0
---Einmal je Sitzung: meldet, dass das Raster ueberhaupt laeuft.
MiningLayers.surfaceFrozenLogged = false
---Marge um den Pinsel herum, in Metern. Der Quadrat-Pinsel deckt +/- radius in
---X und Z ab (LandscapingInput.lua:50: addSoftSquareBrush mit radius * 2 als
---Kantenlaenge), der Kreis ebenso. Zwei Meter Zuschlag = eine Rasterzelle
---Sicherheit, damit der Rand nicht beim naechsten Zug abgesenkt eingefroren wird.
MiningLayers.SURFACE_FREEZE_MARGIN = 2.0
---Gemeinsame Eintraege fuer erkannte Halden (ein Eintrag je Material, damit die
---Texturaufloesung gecacht bleibt).
---@type table<string, table>
MiningLayers.spoilEntries = {}

-- Verhindert, dass ein wiederkehrender Fehler das Log flutet.
MiningLayers.hookErrorReported = false
MiningLayers.outputHookErrorReported = false

-- Die Texturliste der Karte wird nur einmal protokolliert.
MiningLayers.terrainLayersLogged = false

--------------------------------------------------------------------------------
-- XML-Zugriff
--
-- Bewusst nur ueber getString und hasProperty: beide sind belegt auch ohne
-- XML-Schema nutzbar (TerraFarm liest seine userSettings.xml genauso).
-- getFloat/getValue leiten den Typ sonst aus einem Schema ab, das wir nicht haben.
--------------------------------------------------------------------------------

---@param xmlFile table
---@param key string
---@return number?
function MiningLayers.getXmlNumber(xmlFile, key)
    local raw = xmlFile:getString(key)

    if raw == nil then
        return nil
    end

    -- Dezimalkomma verzeihen: "2,5" wird auch akzeptiert.
    return tonumber((raw:gsub(',', '.')))
end

---@param xmlFile table
---@param key string
---@param default boolean
---@return boolean
function MiningLayers.getXmlBool(xmlFile, key, default)
    local raw = xmlFile:getString(key)

    if raw == nil then
        return default
    end

    raw = raw:lower()

    if raw == 'true' or raw == '1' or raw == 'yes' then
        return true
    elseif raw == 'false' or raw == '0' or raw == 'no' then
        return false
    end

    return default
end

--------------------------------------------------------------------------------
-- Laden
--------------------------------------------------------------------------------

---Legt beim ersten Start eine bearbeitbare Kopie der Vorlage unter modSettings an.
---@return string? path
function MiningLayers:prepareConfigFile()
    local templatePath = MiningLayers.MOD_DIRECTORY .. 'xml/' .. MiningLayers.CONFIG_FILENAME
    local settingsDir = MiningLayers.SETTINGS_DIRECTORY

    if settingsDir == nil then
        MiningLayers.log('modSettings directory unknown - using the template inside the mod.')
        return templatePath
    end

    local targetPath = settingsDir .. MiningLayers.CONFIG_FILENAME

    if MiningLayers.isCallable(fileExists) and fileExists(targetPath) then
        return targetPath
    end

    if MiningLayers.isCallable(createFolder) then
        pcall(createFolder, settingsDir)
    end

    if MiningLayers.isCallable(copyFile) then
        local ok = pcall(copyFile, templatePath, targetPath, true)

        if ok and MiningLayers.isCallable(fileExists) and fileExists(targetPath) then
            MiningLayers.log('Template copied to modSettings: %s', targetPath)
            return targetPath
        end
    end

    MiningLayers.log('Could not create a copy under modSettings - using the template inside the mod.')
    return templatePath
end

---Schluessel einer Zone fuer die Merkliste unten. Muss ohne das Zonen-Objekt
---auskommen koennen, deshalb aus kind + area statt aus der Tabellenadresse.
---@param zone table?
---@return string?
function MiningLayers.getZoneKey(zone)
    if type(zone) ~= 'table' then
        return nil
    end

    if zone.kind == 'default' then
        return 'default'
    end

    if zone.kind == 'global' then
        return 'global'
    end

    if type(zone.area) == 'string' then
        return zone.area:lower()
    end

    return nil
end

---Hebt eine Schicht auf, deren Material diese Karte nicht kennt. Sie laeuft
---nicht mit (kein fillTypeIndex), wird beim Speichern aber wieder in die Datei
---geschrieben. Liegt bewusst NEBEN dem Zonen-Objekt: faellt eine Zone ganz weg,
---weil kein einziges Material verfuegbar ist, ueberlebt die Merkliste trotzdem.
---@param zone table
---@param entry table
function MiningLayers:keepUnavailableLayer(zone, entry)
    local key = MiningLayers.getZoneKey(zone)

    if key == nil then
        return
    end

    if type(self.keptLayers) ~= 'table' then
        self.keptLayers = {}
    end

    local kept = self.keptLayers[key]

    if kept == nil then
        kept = { kind = zone.kind, area = zone.area, layers = {} }
        self.keptLayers[key] = kept
    end

    table.insert(kept.layers, entry)
end

---@param xmlFile table
---@param key string
---@param kind string
---@return table? zone
function MiningLayers:loadZone(xmlFile, key, kind)
    local zone = {
        kind = kind,
        area = xmlFile:getString(key .. '#area'),
        enabled = MiningLayers.getXmlBool(xmlFile, key .. '#enabled', true),
        surfaceY = MiningLayers.getXmlNumber(xmlFile, key .. '#surfaceY'),
        layers = {}
    }

    local i = 0

    while true do
        local layerKey = string.format('%s.layer(%d)', key, i)

        if not xmlFile:hasProperty(layerKey) then
            break
        end

        local fillTypeName = xmlFile:getString(layerKey .. '#fillType')
        local depth = MiningLayers.getXmlNumber(xmlFile, layerKey .. '#depth')
        local aboveY = MiningLayers.getXmlNumber(xmlFile, layerKey .. '#aboveY')

        if fillTypeName == nil then
            MiningLayers.log('WARNING %s: entry without a fillType - skipped.', layerKey)
        else
            fillTypeName = fillTypeName:upper()

            local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

            if fillType == nil then
                -- Uebersprungen heisst NUR: laeuft auf dieser Karte nicht mit.
                -- Der Eintrag wird trotzdem aufgehoben und beim naechsten
                -- Speichern zurueckgeschrieben - sonst raeumt ein Ausflug auf
                -- eine Karte ohne PAYDIRT die Konfiguration dauerhaft aus (1.4.3).
                MiningLayers.log('WARNING %s: fill type "%s" is unknown on this map - the layer rests (it is kept).',
                    layerKey, fillTypeName)

                MiningLayers:keepUnavailableLayer(zone, {
                    fillTypeName = fillTypeName,
                    depth = depth,
                    aboveY = aboveY,
                    paintLayerName = xmlFile:getString(layerKey .. '#paintLayer'),
                    seam = MiningLayers.getXmlBool(xmlFile, layerKey .. '#seam', false),
                })
            else
                table.insert(zone.layers, {
                    fillTypeName = fillTypeName,
                    fillTypeIndex = fillType.index,
                    depth = depth,
                    aboveY = aboveY,
                    -- Bodentextur: ausdruecklich gesetzt, sonst spaeter automatisch
                    -- aus dem fillType-Namen abgeleitet.
                    paintLayerName = xmlFile:getString(layerKey .. '#paintLayer'),
                    -- Markiert die Nutzschicht (das Floez). Setzt der Editor beim
                    -- Speichern; in Hand-XMLs optional. Ohne Marker gilt weiter
                    -- die alte Regel: PAYDIRT ueber der Sohle = Floez.
                    seam = MiningLayers.getXmlBool(xmlFile, layerKey .. '#seam', false)
                })
            end
        end

        i = i + 1
    end

    if #zone.layers == 0 then
        return nil
    end

    -- ⚠️ Schicht-Stapel ohne unbegrenzte Bodenschicht: Wer TIEFER graebt als die unterste
    -- Grenze, faellt aus den Schichten heraus - findLayer liefert dann nil und TerraFarm
    -- uebernimmt (Material der Karten-Bodentextur, in jeder Tiefe gleich). Der Editor legt
    -- die Bodenschicht immer an (LayerEditor.lua:409, "der endlose Fels darunter"),
    -- handgeschriebene XML kann sie vergessen. Nur warnen, nicht stillschweigend
    -- ergaenzen - welches Material dort gelten soll, koennen wir nicht raten.
    local hasBottomLayer = false

    for _, layer in ipairs(zone.layers) do
        if layer.depth == nil and layer.aboveY == nil then
            hasBottomLayer = true
            break
        end
    end

    if not hasBottomLayer then
        MiningLayers.log('WARNING %s: no unlimited bottom layer. Below the last', key)
        MiningLayers.log('  boundary NO layer applies any more - TerraFarm takes over there.')
        MiningLayers.log('  Remedy: add a <layer fillType="..."/> WITHOUT depth/aboveY.')
    end

    return zone
end

function MiningLayers:loadConfig()
    self.zonesByKey = {}
    self.defaultZone = nil
    self.globalZone = nil
    self.globalZoneOff = nil
    self.resolvedByArea = {}
    self.resolvedGlobal = nil
    -- Schichten, deren Material diese Karte nicht kennt: ruhen, gehen aber
    -- nicht verloren (siehe keepUnavailableLayer).
    self.keptLayers = {}

    local path = self:prepareConfigFile()
    local xmlFile = XMLFile.loadIfExists('miningLayersConfig', path)

    if xmlFile == nil then
        MiningLayers.log('No configuration found (%s) - layers stay off.', tostring(path))
        return
    end

    self.enabled = MiningLayers.getXmlBool(xmlFile, 'miningLayers#enabled', true)
    self.spoilMode = MiningLayers.getXmlBool(xmlFile, 'miningLayers#spoilMode', false)

    -- Abraum-Material: Name muss aufloesbar sein, sonst Rueckfall DIRT. Der Cache-
    -- Eintrag (getSpoilModeEntry) haengt am Namen und wird hier mit entwertet.
    local spoilMaterial = xmlFile:getString('miningLayers#spoilMaterial')

    if spoilMaterial ~= nil and spoilMaterial ~= '' then
        self.spoilMaterial = spoilMaterial:upper()
    else
        self.spoilMaterial = 'DIRT'
    end

    self.spoilModeEntry = nil

    self.showHeightDisplay = MiningLayers.getXmlBool(xmlFile, 'miningLayers#showHeightDisplay', true)
    self.checkMaterials = MiningLayers.getXmlBool(xmlFile, 'miningLayers#checkMaterials', true)
    self.matchOutputTexture = MiningLayers.getXmlBool(xmlFile, 'miningLayers#matchOutputTexture', true)
    self.autoTargetHeight = MiningLayers.getXmlBool(xmlFile, 'miningLayers#autoTargetHeight', true)

    -- Marke der 1.6-Abschaltung. Bleibt gelesen, damit wir eine damals erzeugte Datei
    -- erkennen - sie ist der Ausloeser der Rueckkehr unten.
    self.autoTargetHeightReviewed = MiningLayers.getXmlBool(xmlFile, 'miningLayers#autoTargetHeightReviewed', false)

    -- ★ Einmalige Rueckkehr der Automatik (1.6.1).
    --
    -- 1.6 hat sie abgeschaltet, weil der Mod eine bewusst gesetzte Zielhoehe nicht von
    -- der erkennen konnte, die ein Bereich beim Zeichnen ohnehin bekommt (Oreo, RGC,
    -- 16.08.). Der Preis dafuer war hoch: seither muss JEDER die Zielhoehe von Hand
    -- setzen, ohne dass der Mod das irgendwo sagt - und wer vorher ohne Bereich
    -- gegraben hat, wo es keine Untergrenze gibt, sieht nur, dass es ploetzlich
    -- nicht mehr geht (Tommy, 18.08.).
    --
    -- Die Unterscheidung geht inzwischen (siehe MiningLayers.manualTargetByArea): nicht
    -- am Wert, sondern am Handgriff im TerraFarm-Editor. Damit ist der Grund der
    -- Abschaltung weg, und die Bestandsdateien von 1.6 bekommen die Automatik zurueck.
    -- Die neue Marke sorgt dafuer, dass wir nie ein zweites Mal eingreifen: wer sie
    -- danach bewusst abschaltet, behaelt das.
    self.autoTargetHeightRestored = MiningLayers.getXmlBool(xmlFile, 'miningLayers#autoTargetHeightRestored', false)

    if not self.autoTargetHeight and self.autoTargetHeightReviewed and not self.autoTargetHeightRestored then
        self.autoTargetHeight = true
        self.autoTargetHeightRestored = true
        self.configNeedsSave = true

        MiningLayers.log('autoTargetHeight is on again, and here is why:')
        MiningLayers.log('  1.6 switched it off because the mod could not tell a target height you set')
        MiningLayers.log('  on purpose from the one an area gets while you draw it. It can now: it')
        MiningLayers.log('  watches the editor instead of guessing from the value.')
        MiningLayers.log('  A height you set yourself is never touched again. Everything else gets a')
        MiningLayers.log('  pit floor below the deepest layer, as it did up to 1.5.0.')
        MiningLayers.log('  Want it off? Set autoTargetHeight="false" - it stays off from then on.')
    end
    self.showDepthLines = MiningLayers.getXmlBool(xmlFile, 'miningLayers#showDepthLines', true)
    self.syncVehicleMaterial = MiningLayers.getXmlBool(xmlFile, 'miningLayers#syncVehicleMaterial', true)
    self.freeDumpHeight = MiningLayers.getXmlBool(xmlFile, 'miningLayers#freeDumpHeight', true)
    self.dumpDiagnostics = MiningLayers.getXmlBool(xmlFile, 'miningLayers#dumpDiagnostics', false)
    self.displayPosX = MiningLayers.getXmlNumber(xmlFile, 'miningLayers#displayPosX') or self.displayPosX
    self.displayPosY = MiningLayers.getXmlNumber(xmlFile, 'miningLayers#displayPosY') or self.displayPosY

    if xmlFile:hasProperty('miningLayers.defaultZone') then
        local zone = self:loadZone(xmlFile, 'miningLayers.defaultZone', 'default')

        if zone ~= nil and zone.enabled then
            self.defaultZone = zone
        end
    end

    if xmlFile:hasProperty('miningLayers.globalZone') then
        local zone = self:loadZone(xmlFile, 'miningLayers.globalZone', 'global')

        if zone ~= nil and zone.enabled then
            self.globalZone = zone
            self.resolvedGlobal = self:resolveZone(zone, zone.surfaceY, 'globalZone')

            if zone.surfaceY == nil then
                MiningLayers.log('globalZone active without a fixed reference height - it is taken on the first')
                MiningLayers.log('  bucket contact from the surface grid. Applies everywhere that no area covers.')
            else
                MiningLayers.log('globalZone active with a fixed reference height of %.1f m - applies across the whole map.', zone.surfaceY)
                MiningLayers.log('  ⚠ A fixed reference height only fits flat terrain. Without surfaceY the layers')
                MiningLayers.log('    follow the ground, which is almost always what you want.')
            end
        elseif zone ~= nil then
            -- ⚠️ Bis 1.5.0 fiel eine abgeschaltete globalZone hier hinten runter, und
            -- saveConfigFile schreibt nur, was im Speicher liegt: nach dem ersten
            -- Speichern im Editor war der Block still aus der Datei verschwunden.
            -- Wir heben sie MIT ihren Schichten auf - anders als bei abgeschalteten
            -- Bereichen (:422), wo ein Marker reicht. Sonst verliert der Nutzer seine
            -- Schichten genau dann, wenn er den Schalter wieder umlegt.
            zone.disabled = true
            self.globalZoneOff = zone
        end
    end

    local i = 0
    local namedCount = 0

    while true do
        local key = string.format('miningLayers.zone(%d)', i)

        if not xmlFile:hasProperty(key) then
            break
        end

        local areaName = xmlFile:getString(key .. '#area')
        local zoneEnabled = MiningLayers.getXmlBool(xmlFile, key .. '#enabled', true)

        if areaName ~= nil and not zoneEnabled then
            -- Ausdruecklich abgeschaltet: der Bereich faellt NICHT auf die defaultZone
            -- zurueck. So nimmt man Baustellen und Rohrgraeben dauerhaft von den
            -- Schichten aus.
            --
            -- ⚠️ Bis 1.5.0 stand hier eine reine Marker-Tabelle OHNE Schichten. Die
            -- Schreibseite (LayerEditor.lua:616) haette Schichten mitgeschrieben - sie
            -- lagen nach dem Laden aber gar nicht mehr im Speicher. Ergebnis: Ausschalten
            -- eines benannten Bereichs kostete die Konfiguration, waehrend dieselbe Aktion
            -- an der globalZone (:415) sie behielt. Derselbe Schalter im selben Menue mit
            -- zwei Ausgaengen - deshalb hier dieselbe Behandlung.
            -- Gefahrlos, weil getResolvedForArea (:942) am disabled-Flag aussteigt,
            -- bevor irgendeine Schicht gelesen wird.
            local disabledZone = self:loadZone(xmlFile, key, 'area')

            if disabledZone ~= nil then
                disabledZone.disabled = true
                self.zonesByKey[areaName:lower()] = disabledZone
            else
                -- Kein einziger layer-Eintrag: loadZone liefert dafuer nil (:325).
                -- Das ist der Alt-Marker aus 1.5.0 und bleibt, was er war.
                self.zonesByKey[areaName:lower()] = { kind = 'area', area = areaName, disabled = true }
            end

            namedCount = namedCount + 1
        else
            local zone = self:loadZone(xmlFile, key, 'area')

            if zone ~= nil and zone.enabled then
                if zone.area == nil then
                    MiningLayers.log('WARNING %s: no area attribute - skipped.', key)
                else
                    self.zonesByKey[zone.area:lower()] = zone
                    namedCount = namedCount + 1
                end
            end
        end

        i = i + 1
    end

    xmlFile:delete()

    MiningLayers.log('Configuration: %d named zone(s), defaultZone %s, globalZone %s.',
        namedCount,
        self.defaultZone ~= nil and 'active' or 'off',
        self.resolvedGlobal ~= nil and 'ACTIVE' or 'off')

    if not self.enabled then
        MiningLayers.log('Layers are switched off in the configuration (enabled="false").')
    elseif namedCount == 0 and self.defaultZone == nil and self.resolvedGlobal == nil then
        MiningLayers.log('No active zone - digging behaves as if the add-on were not installed.')
    end

    -- Die einmalige autoTargetHeight-Korrektur muss in die Datei, sonst greift sie beim
    -- naechsten Start wieder - und wuerde dann auch einen Schalter ueberschreiben, den
    -- jemand bewusst wieder eingeschaltet hat.
    -- ⚠️ saveConfigFile schreibt die Datei neu; die Kommentare der Vorlage gehen dabei
    -- verloren. Daneben liegt die .bak-Kopie dieser Sitzung, und derselbe Verlust tritt
    -- ohnehin beim ersten Speichern im Editor ein.
    if self.configNeedsSave then
        self.configNeedsSave = false

        MiningLayers.protectedCall('saveConfigAfterReview', function()
            self:saveConfigFile()
        end)
    end
end

--------------------------------------------------------------------------------
-- Bezugshoehe aus der Bereichsumrandung
--------------------------------------------------------------------------------

---Maximale Neigung der Bezugsflaeche (tan 45 Grad). Steiler ist kein Hang mehr,
---sondern ein kaputter Fit - dann Rueckfall auf den Median.
MiningLayers.MAX_PLANE_SLOPE = 1.0

---Hoehe der Bezugsflaeche an einem Punkt.
---@param plane table { x0, z0, y0, sx, sz }
---@param x number
---@param z number
---@return number
function MiningLayers.planeAt(plane, x, z)
    return plane.y0 + plane.sx * (x - plane.x0) + plane.sz * (z - plane.z0)
end

---Bezugsflaeche aus den Eckpunkten des Bereichs.
---
---Ebene durch die Randpunkte (kleinste Quadrate) statt einer einzigen Zahl: am Hang
---folgen Schichtgrenzen und Spoil-Schwelle damit dem Gelaende. Mit nur einem Wert
---(Median) gilt die Bergseite als "aufgeschuettet" und die Talseite bekommt die
---Schichten zu hoch (Tommys Ansage 2026-08-08: Berg muss auch gehen).
---Auf ebenem Boden degeneriert der Fit zur Konstanten und ist mit dem Median
---identisch. Rueckfall auf den Median, wenn der Fit nicht traegt: unter 3 Punkte,
---kollineare Punkte, Neigung ueber 45 Grad.
---
---Der Median wird weiter mitgeliefert - als Rueckfall und fuer Log/Vergleiche.
---Die Streuung ist bei tragendem Fit der RESTFEHLER zur Ebene (gekruemmter Hang
---ist keine Ebene), sonst wie bisher die rohe Hoehenspanne.
---@param area table
---@return number? median
---@return number? spread
---@return number count
---@return table? plane  nil, wenn der Fit nicht traegt
function MiningLayers:computeSurfaceY(area)
    if area == nil or area.points == nil then
        return nil, nil, 0, nil
    end

    local samples = {}
    local heights = {}

    for i = 1, #area.points do
        local point = area.points[i]

        if type(point) == 'table' and point[1] ~= nil and point[3] ~= nil then
            local y = getTerrainHeightAtWorldPos(g_terrainNode, point[1], 0, point[3])

            if y ~= nil then
                table.insert(samples, { x = point[1], z = point[3], y = y })
                table.insert(heights, y)
            end
        end
    end

    local count = #heights

    if count == 0 then
        return nil, nil, 0, nil
    end

    table.sort(heights)

    local median

    if count % 2 == 1 then
        median = heights[(count + 1) / 2]
    else
        median = (heights[count / 2] + heights[count / 2 + 1]) * 0.5
    end

    local rawSpread = heights[count] - heights[1]

    if count < 3 then
        return median, rawSpread, count, nil
    end

    -- Kleinste Quadrate um den Schwerpunkt: y = ym + sx*(x-xm) + sz*(z-zm).
    -- Zentriert, damit die Normalgleichungen bei Weltkoordinaten im Kilometerbereich
    -- nicht an Ausloeschung sterben.
    local xm, zm, ym = 0, 0, 0

    for _, s in ipairs(samples) do
        xm = xm + s.x
        zm = zm + s.z
        ym = ym + s.y
    end

    xm = xm / count
    zm = zm / count
    ym = ym / count

    local sxx, szz, sxz, sxy, szy = 0, 0, 0, 0, 0

    for _, s in ipairs(samples) do
        local dx = s.x - xm
        local dz = s.z - zm
        local dy = s.y - ym

        sxx = sxx + dx * dx
        szz = szz + dz * dz
        sxz = sxz + dx * dz
        sxy = sxy + dx * dy
        szy = szy + dz * dy
    end

    local det = sxx * szz - sxz * sxz

    -- Kollinear (alle Punkte auf einer Linie): det verschwindet gegen die Streuung
    -- der Koordinaten. Relativer Test, absolute Schwellen taugen bei Metern nicht.
    if det <= 1e-6 * math.max(sxx * szz, 1) then
        return median, rawSpread, count, nil
    end

    local slopeX = (sxy * szz - szy * sxz) / det
    local slopeZ = (szy * sxx - sxy * sxz) / det

    if math.sqrt(slopeX * slopeX + slopeZ * slopeZ) > MiningLayers.MAX_PLANE_SLOPE then
        return median, rawSpread, count, nil
    end

    local plane = { x0 = xm, z0 = zm, y0 = ym, sx = slopeX, sz = slopeZ }

    -- Restfehler: was die Ebene NICHT erklaert. Nur der zaehlt fuer die Warnung -
    -- ein sauberer Hang ist kein Grund zu warnen.
    local minResidual, maxResidual = nil, nil

    for _, s in ipairs(samples) do
        local residual = s.y - MiningLayers.planeAt(plane, s.x, s.z)

        if minResidual == nil or residual < minResidual then
            minResidual = residual
        end

        if maxResidual == nil or residual > maxResidual then
            maxResidual = residual
        end
    end

    return median, maxResidual - minResidual, count, plane
end

---Rechnet die Schichtdicken in absolute Hoehen um und sortiert absteigend.
---Die Schicht ohne depth/aboveY ist die Bodenschicht und landet immer zuletzt.
---Vorschlaege fuer die Bodentextur je Material, in der Reihenfolge des Vorzugs.
---
---Karten benennen ihre Terrain-Layer fast nie wie die fillTypes: Yukon Back Country
---hat weder "DIRT" noch "PAYDIRT", sondern mudDark, mudGravel, gravelSmall, rock …
---Das sind GIANTS-Standardnamen und kommen auf den meisten Karten vor, deshalb trifft
---diese Tabelle in der Regel. Wer es anders will, setzt paintLayer="…" an der Schicht.
---⚠️ Die Namen werden SCHREIBUNGSUNABHAENGIG verglichen. TerraFarm liefert sie ueber
---getTerrainLayerName() gross und mit Unterstrichen (MUD, DIRT_GRAVEL, MOUNTAINROCK),
---waehrend sie in der map.i3d klein und anders heissen (mudDark, gravel01). Wer sich
---auf die i3d verlaesst, sucht Namen, die es zur Laufzeit nicht gibt.
MiningLayers.PAINT_LAYER_CANDIDATES = {
    DIRT             = { 'DIRT', 'MUD', 'MUDLIGHT', 'MUD_TRACKS', 'DIRT_GRAVEL' },
    PAYDIRT          = { 'PAYDIRT', 'DIRT_GRAVEL', 'GRAVELSMALL', 'MUD_PEBBLES', 'RGC_RIVER_BOTTOM', 'GRAVEL' },
    SOIL             = { 'SOIL', 'MUD', 'MUDLIGHT' },
    TOPSOIL          = { 'TOPSOIL', 'MUD', 'MUDLIGHT' },
    GRAVEL           = { 'GRAVEL', 'GRAVELSMALL', 'DIRT_GRAVEL', 'MUD_PEBBLES' },
    SAND             = { 'SAND', 'CONCRETE_GRAVEL', 'GRAVELSMALL' },
    STONE            = { 'STONE', 'MOSS_STONES', 'FOREST_STONES', 'MOUNTAINROCK', 'ROCK', 'FOREST_ROCK', 'MOSS_ROCKS' },
    LIMESTONE        = { 'LIMESTONE', 'MOUNTAINROCK', 'ROCK', 'GRAVEL' },
    IRON             = { 'IRON', 'MOUNTAINROCK', 'ROCK', 'DIRT_GRAVEL' },
    COAL             = { 'COAL', 'RGC_COAL', 'MUD' },
    COKINGCOAL       = { 'COAL', 'RGC_COAL', 'MUD' },
    CONCRETE         = { 'CONCRETE', 'CONCRETE_DIRT' },
    LIME             = { 'LIME', 'SAND', 'GRAVELSMALL' },
    SNOW             = { 'SNOW' },
    COMPOST          = { 'COMPOST', 'MUD', 'MUD_LEAVES' },
    ORGANICWASTE     = { 'MUD', 'MUD_LEAVES' },
    COARSETAILINGS   = { 'GRAVELSMALL', 'DIRT_GRAVEL', 'MUD_PEBBLES' },
    FINETAILINGS     = { 'SAND', 'MUDLIGHT_PEBBLES', 'MUDLIGHT' },
    REFINEDWOODCHIPS = { 'FOREST_LEAVES', 'MUD_LEAVES' },
}

---Sucht die Bodentextur zu einer Schicht.
---
---Ohne eigene Textur sehen alle Schichten gleich aus - man graebt sich durch drei
---Materialien und sieht nur die Textur, die am Fahrzeug eingestellt ist.
---
---Reihenfolge: ausdrueckliches paintLayer, dann der fillType-Name selbst, dann die
---Vorschlagsliste oben. Greift nichts, bleibt die Fahrzeugeinstellung unangetastet.
---@param layer table
---@return number? terrainLayerId
---@return string? name
function MiningLayers:resolvePaintLayer(layer)
    local landscapingManager = MiningLayers.tf('g_landscapingManager')

    if type(landscapingManager) ~= 'table' or not MiningLayers.isCallable(landscapingManager.getTerrainLayerByName) then
        return nil, nil
    end

    local candidates = {}

    if layer.paintLayerName ~= nil then
        table.insert(candidates, layer.paintLayerName)
    end

    table.insert(candidates, layer.fillTypeName)

    for _, name in ipairs(MiningLayers.PAINT_LAYER_CANDIDATES[layer.fillTypeName] or {}) do
        table.insert(candidates, name)
    end

    -- Alle Layer der Karte einmal in Grossschreibung indizieren. getTerrainLayerByName
    -- vergleicht exakt, und die Schreibweise unterscheidet sich je Karte.
    local byUpperName = {}

    if MiningLayers.isCallable(landscapingManager.getTerrainLayers) then
        for _, terrainLayer in ipairs(landscapingManager:getTerrainLayers()) do
            if terrainLayer.name ~= nil then
                byUpperName[terrainLayer.name:upper()] = terrainLayer
            end
        end
    end

    local function lookup(name)
        local terrainLayer = byUpperName[name:upper()]

        if terrainLayer == nil and MiningLayers.isCallable(landscapingManager.getTerrainLayerByName) then
            terrainLayer = landscapingManager:getTerrainLayerByName(name)
        end

        if terrainLayer ~= nil and terrainLayer.id ~= nil then
            return terrainLayer
        end
    end

    for _, name in ipairs(candidates) do
        local terrainLayer = lookup(name)

        if terrainLayer ~= nil then
            return terrainLayer.id, terrainLayer.name
        end
    end

    -- Letzter Versuch: ein Layer, der den Materialnamen enthaelt (GRAVEL -> GRAVELSMALL).
    -- pairs() hat in Lua keine feste Reihenfolge - deshalb alle Treffer sammeln und
    -- deterministisch waehlen: kuerzester Name zuerst (naechster an der Grundform),
    -- bei Gleichstand alphabetisch. Sonst wechselt das Ergebnis von Start zu Start.
    local needle = layer.fillTypeName:upper()
    local matches = {}

    for upperName, terrainLayer in pairs(byUpperName) do
        if upperName:find(needle, 1, true) ~= nil then
            table.insert(matches, { name = upperName, terrainLayer = terrainLayer })
        end
    end

    if #matches > 0 then
        table.sort(matches, function(a, b)
            if #a.name ~= #b.name then
                return #a.name < #b.name
            end

            return a.name < b.name
        end)

        return matches[1].terrainLayer.id, matches[1].terrainLayer.name
    end

    if layer.paintLayerName ~= nil then
        MiningLayers.log('WARNING: ground texture "%s" does not exist on this map.', tostring(layer.paintLayerName))
    end

    MiningLayers.log('No matching ground texture found for "%s" - the texture stays unchanged.', layer.fillTypeName)
    MiningLayers.log('  Pick a matching name from the list above and enter it as paintLayer="...".')

    return nil, nil
end

---@type table<string, number|false> Textur je Material, fuer den Ausgabe-Pfad
MiningLayers.outputLayerCache = {}

---Liefert die Bodentextur zu einem Material (fuer das Abladen).
---Gleiche Suche wie bei den Schichten, nur ueber den Materialnamen statt ueber eine
---Schicht - beim Abladen gibt es keine Schicht, das Material kommt aus der Schaufel.
---@param fillTypeName string
---@return number? terrainLayerId
function MiningLayers:getTerrainLayerForFillType(fillTypeName)
    local cached = self.outputLayerCache[fillTypeName]

    if cached ~= nil then
        return cached or nil
    end

    if not MiningLayers.terrainLayersLogged then
        MiningLayers.terrainLayersLogged = true
        self:logTerrainLayers()
    end

    local id, name = self:resolvePaintLayer({ fillTypeName = fillTypeName })

    self.outputLayerCache[fillTypeName] = id or false

    if id ~= nil then
        MiningLayers.log('Dumping %s -> ground texture "%s".', fillTypeName, tostring(name))
    end

    return id
end

---Liefert die Textur-ID einer Schicht und merkt sie sich.
---
---Lazy, weil TerraFarms Terrain-Layer erst bei onTerrainInit befuellt werden - zum
---Zeitpunkt von loadMap ist die Liste noch leer.
---@param entry table
---@return number? terrainLayerId
function MiningLayers:getTerrainLayerFor(entry)
    if entry.terrainLayerResolved then
        return entry.terrainLayerId
    end

    -- Beim allerersten Auflösen einmal die Texturen der Karte protokollieren.
    if not MiningLayers.terrainLayersLogged then
        MiningLayers.terrainLayersLogged = true
        self:logTerrainLayers()
    end

    local id, name = self:resolvePaintLayer(entry)

    entry.terrainLayerId = id
    entry.terrainLayerName = name
    entry.terrainLayerResolved = true

    if id ~= nil then
        MiningLayers.log('Layer %s -> ground texture "%s".', entry.fillTypeName, tostring(name))
    end

    return id
end

---@param zone table
---@param surfaceY number? nil = Bezugshoehe kommt erst zur Laufzeit aus dem Raster
---@param label string
---@return table resolved
function MiningLayers:resolveZone(zone, surfaceY, label)
    local resolved = {}

    for _, layer in ipairs(zone.layers) do
        local boundary
        local sortKey
        local skip = false

        if layer.aboveY ~= nil then
            -- aboveY ist absolut, depth ist relativ. Ohne gemeinsame Bezugshoehe
            -- sind die beiden nicht gegeneinander sortierbar - das ist keine
            -- Implementierungsluecke, das geht nicht. Also ablehnen mit Ansage
            -- statt still in die falsche Reihenfolge zu setzen.
            if surfaceY == nil then
                skip = true

                MiningLayers.log('WARNING %s: layer "%s" uses aboveY - it cannot be sorted without a fixed reference height, skipped.',
                    label, tostring(layer.fillTypeName))
            else
                boundary = layer.aboveY
                sortKey = layer.aboveY
            end
        elseif layer.depth ~= nil then
            if surfaceY ~= nil then
                boundary = surfaceY - layer.depth
                sortKey = boundary
            else
                -- Ohne feste Bezugshoehe gibt es keine absolute Grenze. Die
                -- Reihenfolge ergibt sich trotzdem eindeutig aus der Tiefe: flach
                -- zuerst - genau die Ordnung, die surfaceY - depth erzeugt haette.
                -- Die Grenze am Punkt rechnet entryBoundaryAt spaeter aus dem Raster.
                sortKey = -layer.depth
            end
        end

        -- Textur hier NICHT aufloesen: TerraFarms Terrain-Layer werden erst bei
        -- onTerrainInit befuellt, und das kommt nach loadMap. Passiert lazy beim
        -- ersten Grabvorgang (getTerrainLayerFor).
        -- boundary ist die Grenze an der BEZUGSHOEHE (Median) - fuers Sortieren und
        -- Log. Am Punkt selbst wird die Grenze ueber depth/aboveY gegen die geneigte
        -- Bezugsflaeche ausgewertet (entryBoundaryAt), sonst laegen die Schichten
        -- am Hang waagerecht.
        if not skip then
            table.insert(resolved, {
                boundary = boundary,
                sortKey = sortKey,
                fillTypeName = layer.fillTypeName,
                fillTypeIndex = layer.fillTypeIndex,
                depth = layer.depth,
                aboveY = layer.aboveY,
                paintLayerName = layer.paintLayerName,
                terrainLayerId = nil,
                terrainLayerResolved = false
            })
        end
    end

    -- Sortiert wird auf sortKey, nicht auf boundary: ohne feste Bezugshoehe gibt es
    -- keine boundary, die Ordnung steht trotzdem fest. Eintraege ohne sortKey sind
    -- die unterste Schicht (kein depth, kein aboveY) und gehoeren ans Ende.
    --
    -- ★ REGEL FUER JEDE SORTIERUNG IN DIESEM MOD (15.08., nachdem zwei Vergleicher
    -- an einem Tag denselben Fehler hatten): fehlende Werte auf einen Ersatzwert
    -- abbilden, statt sie im Vergleicher zu behandeln - `(a.depth or math.huge)`
    -- ist die sichere Bauart. Wer einen Sonderfall im Vergleicher abfaengt, muss
    -- ihn in BEIDEN Richtungen gleich beantworten: liefert comparator(a,b) und
    -- comparator(b,a) beide `true`, ist die Ordnung widerspruechlich und
    -- table.sort darf mit "invalid order function" abbrechen - laufzeit- und
    -- datenabhaengig, also genau die Sorte Fehler, die im Test nicht auftaucht.
    -- Hier ist es korrekt: sind beide sortKey nil, sagen beide Richtungen `false`
    -- = gleichwertig.
    table.sort(resolved, function(a, b)
        if a.sortKey == nil then
            return false
        elseif b.sortKey == nil then
            return true
        end

        return a.sortKey > b.sortKey
    end)

    local parts = {}

    for _, entry in ipairs(resolved) do
        if entry.boundary ~= nil then
            table.insert(parts, string.format('%s ab %.1f m', entry.fillTypeName, entry.boundary))
        elseif entry.depth ~= nil then
            table.insert(parts, string.format('%s ab %.1f m unter der Oberflaeche', entry.fillTypeName, entry.depth))
        else
            table.insert(parts, string.format('%s darunter', entry.fillTypeName))
        end
    end

    if surfaceY ~= nil then
        MiningLayers.log('%s: surfaceY %.1f m -> %s', label, surfaceY, table.concat(parts, ', '))
    else
        MiningLayers.log('%s: reference height comes from the grid -> %s', label, table.concat(parts, ', '))
    end

    return resolved
end

---Liefert die aufgeloesten Schichten fuer einen Bereich, berechnet sie bei Bedarf.
---@param area table
---@return table|false|nil resolved
---@return number? surfaceY  Bezugshoehe (Median) - Punktwerte ueber die Ebene holen
---@return boolean? isOff  true = Bereich ist ausdruecklich von den Schichten ausgenommen
---@return table? plane  geneigte Bezugsflaeche, nil = eben/Fit traegt nicht
function MiningLayers:getResolvedForArea(area)
    if area == nil or area.uniqueId == nil then
        return nil, nil, nil, nil
    end

    -- Pfad-Bereiche bekommen keine Schichten und vor allem keinen automatischen
    -- Grubenboden - ihr targetY gehoert der Pfad-Geometrie.
    if area.width ~= nil then
        return nil, nil, nil, nil
    end

    local cached = self.resolvedByArea[area.uniqueId]

    if cached ~= nil then
        return cached.resolved, cached.surfaceY, cached.off, cached.plane
    end

    local zone = nil

    if area.name ~= nil then
        zone = self.zonesByKey[area.name:lower()]
    end

    if zone == nil then
        zone = self.zonesByKey[area.uniqueId:lower()]
    end

    if zone ~= nil and zone.disabled then
        -- Per XML abgeschaltet: kein Rueckfall auf die defaultZone.
        self.resolvedByArea[area.uniqueId] = { resolved = false, surfaceY = nil, off = true }
        return nil, nil, true
    end

    if zone == nil then
        zone = self.defaultZone
    end

    if zone == nil then
        self.resolvedByArea[area.uniqueId] = { resolved = false, surfaceY = nil }
        return nil, nil, nil
    end

    local label = string.format('Zone %s', tostring(area.name or area.uniqueId))
    local surfaceY = zone.surfaceY
    local spread, count, plane

    if surfaceY == nil then
        surfaceY, spread, count, plane = self:computeSurfaceY(area)

        if surfaceY == nil then
            MiningLayers.log('WARNING %s: reference height cannot be determined (no points) - skipped.', label)
            self.resolvedByArea[area.uniqueId] = { resolved = false, surfaceY = nil }
            return nil, nil
        end

        MiningLayers.log('%s: surfaceY %.1f m (median of %d edge points)', label, surfaceY, count)

        if plane ~= nil then
            local slope = math.sqrt(plane.sx * plane.sx + plane.sz * plane.sz)

            -- Nur melden, wenn wirklich Neigung im Spiel ist - auf ebenem Boden
            -- waere die Zeile Rauschen.
            if slope > 0.02 then
                MiningLayers.log('%s: tilted reference plane, slope %.0f %% - layers follow the hillside.',
                    label, slope * 100)
            end
        end

        -- Streuung melden: bei stark schwankendem Rand liegen die Schichten schief.
        local topThickness = nil

        for _, layer in ipairs(zone.layers) do
            if layer.depth ~= nil and (topThickness == nil or layer.depth < topThickness) then
                topThickness = layer.depth
            end
        end

        if spread ~= nil and topThickness ~= nil and spread > topThickness then
            MiningLayers.log('WARNING %s: edge heights vary by %.1f m, the top layer is only %.1f m thick.',
                label, spread, topThickness)
            MiningLayers.log('  Layers will come out uneven. Draw a smaller area or set surfaceY explicitly.')
        end
    end

    local resolved = self:resolveZone(zone, surfaceY, label)

    self.resolvedByArea[area.uniqueId] = { resolved = resolved, surfaceY = surfaceY, plane = plane }

    MiningLayers.protectedCall('maybeSetPitFloor', function()
        MiningLayers:maybeSetPitFloor(area, resolved, surfaceY, label, plane)
    end)

    return resolved, surfaceY, nil, plane
end

---Setzt den Grubenboden (targetY) des Bereichs, wenn er noch auf dem Auto-Wert des
---Editors steht. Der Editor fuellt targetY mit der Gelaendehoehe - das bedeutet
---"grab nichts", und tiefer stellen ist im Editor kaum moeglich (Zahlenfeld verliert
---gegen die Polygon-Geometrie, Punkte nur horizontal beweglich).
---
---Ersetzt wird NUR der Auto-Wert (targetY etwa auf Bezugshoehe). Ein bewusst
---gesetzter Boden - mehr als 1 m daneben - bleibt unangetastet. Bereiche im
---Handbetrieb (Material gesetzt) kommen hier nie an, die steigen frueher aus.
---Wasserspiegel defensiv lesen. Die Kandidaten unterscheiden sich je Karte/Version,
---deshalb alle der Reihe nach und alles per pcall/Typpruefung abgesichert.
---Werte unter -100 m sind "kein Wasser hier"-Sentinels der Engine.
---@param x number
---@param z number
---@return number? waterY
function MiningLayers.getWaterYAt(x, z)
    local candidates = {}

    if g_currentMission ~= nil then
        if type(g_currentMission.waterY) == 'number' then
            table.insert(candidates, g_currentMission.waterY)
        end

        if MiningLayers.isCallable(g_currentMission.getWaterYAtWorldPosition) then
            local ok, result = pcall(g_currentMission.getWaterYAtWorldPosition, g_currentMission, x, 0, z)

            if ok and type(result) == 'number' then
                table.insert(candidates, result)
            end
        end
    end

    if MiningLayers.isCallable(getWaterYAtWorldPosition) then
        local ok, result = pcall(getWaterYAtWorldPosition, x, 0, z)

        if ok and type(result) == 'number' then
            table.insert(candidates, result)
        end

        -- Zweite Sonde auf Gelaendehoehe: am Riverspot (18.08.) lieferte die Abfrage
        -- bei y=0 an allen vier Ecken nichts, obwohl der Fluss direkt daneben liegt.
        -- Welche Abfragehoehe die Engine erwartet, ist nicht dokumentiert - zwei
        -- Kandidaten kosten nichts, der Filter unten sortiert Unsinn aus.
        if MiningLayers.isCallable(getTerrainHeightAtWorldPos) and g_currentMission ~= nil
            and g_currentMission.terrainRootNode ~= nil then
            local okT, terrainY = pcall(getTerrainHeightAtWorldPos, g_currentMission.terrainRootNode, x, 0, z)

            if okT and type(terrainY) == 'number' then
                local okW, result2 = pcall(getWaterYAtWorldPosition, x, terrainY + 1, z)

                if okW and type(result2) == 'number' then
                    table.insert(candidates, result2)
                end
            end
        end
    end

    for _, waterY in ipairs(candidates) do
        if waterY > -100 then
            return waterY
        end
    end

    return nil
end

---Hoechster Wasserstand ueber ALLEN Eckpunkten eines Bereichs.
---
---⚠️ Ein einzelner Punkt reicht nicht (Befund Riverspot, 18.08.): Punkt 1 lag an
---Land, die Wasserklemme blieb stumm, und der automatische Boden landete bei
--- -7,2 m - unter der Wasserlinie. Ein Bereich beruehrt Wasser, sobald IRGENDEIN
---Eckpunkt Wasser sieht, und dann zaehlt der hoechste Stand.
---@param area table
---@return number?
function MiningLayers.getAreaWaterY(area)
    if type(area) ~= 'table' or type(area.points) ~= 'table' then
        return nil
    end

    local best = nil

    for i = 1, #area.points do
        local point = area.points[i]

        if type(point) == 'table' and point[1] ~= nil and point[3] ~= nil then
            local waterY = MiningLayers.getWaterYAt(point[1], point[3])

            if waterY ~= nil and (best == nil or waterY > best) then
                best = waterY
            end
        end
    end

    return best
end

---Bereiche, deren Zielhoehe der SPIELER selbst eingestellt hat (uniqueId -> Hoehe).
---
---★ Die 1.5.0-Automatik ist an der Frage "war das Absicht?" gescheitert, weil sie am
---WERT entschieden hat - und der Startwert eines Bereichs ist nicht von einer
---bewussten Eingabe zu unterscheiden (Beleg unten in maybeSetPitFloor).
---
---Am HANDGRIFF ist es sehr wohl zu unterscheiden. TerraFarm setzt targetY an vier
---Stellen (FS25_0_TerraFarm 1.6.3.0, scripts/gui/editor/PolygonEditor.lua):
---   :197 createPoint()               -> beilaeufig, auf die Hoehe des gesetzten Punktes
---   :556 onInputEventPrimary()       -> dito
---   :575/577 onInputEventUpDownAxis() -> der Spieler stellt die Hoehe ein
---   :612 onTextInputPressed()        -> der Spieler tippt die Hoehe ein
---Nur die unteren beiden sind eine Absicht. Genau auf die haengt sich der Mod
---(siehe TargetHeightWatch), alles andere gilt als "noch nicht eingestellt".
MiningLayers.manualTargetByArea = {}

---Welche Zielhoehe gilt in welchem Bereich, und woher kommt sie? Fuer die Anzeige.
---Schluessel ist der Bereichsname, weil die Anzeige nur den kennt.
MiningLayers.targetStatusByZone = {}

---@param area table
---@param targetY number
---@param deepest number
---@param manual boolean
function MiningLayers.setTargetStatus(area, targetY, deepest, manual)
    if type(area) ~= 'table' or targetY == nil or targetY == math.huge then
        return
    end

    MiningLayers.targetStatusByZone[tostring(area.name or area.uniqueId)] = {
        y = targetY,
        deepest = deepest,
        manual = manual == true,
        -- "Schneidet ab" heisst: die Grube endet ueber der tiefsten Schichtgrenze.
        cut = deepest ~= nil and targetY > deepest,
    }
end

---Haengt sich an die zwei Stellen im TerraFarm-Bereichseditor, an denen der SPIELER
---die Zielhoehe einstellt (Belege oben an MiningLayers.manualTargetByArea).
---
---⚠️ Beide Male ueber den WERT-Vergleich vor/nach dem Aufruf statt blind zu markieren:
---onInputEventUpDownAxis bewegt je nach Auswahl auch nur einen Punkt, und dann ist die
---Zielhoehe nicht gemeint. Die Texteingabe zaehlt dagegen immer, auch wenn jemand
---denselben Wert noch einmal eintippt - das ist eine Bestaetigung, keine Nulloperation.
function MiningLayers:installTargetHeightWatch()
    if Utils == nil or not MiningLayers.isCallable(Utils.overwrittenFunction) then
        return
    end

    -- Die GUI-Hooks sind nur noch Beifang: die GIANTS-GUI merkt sich ihre Callbacks
    -- beim Laden, ein spaeter ersetzter Klassen-Eintrag wird dort nicht sicher
    -- aufgerufen (Befund 18.08.). Fehlen sie, traegt der Manager-Hook unten allein.
    local editor = MiningLayers.tf('PolygonEditor')

    if editor ~= nil and MiningLayers.isCallable(editor.onTextInputPressed) then
        editor.onTextInputPressed = Utils.overwrittenFunction(editor.onTextInputPressed,
            function(self, superFunc, element, ...)
                local result = superFunc(self, element, ...)

                -- Nur das Zielhoehen-Feld, nicht jedes Textfeld des Editors.
                if self ~= nil and element ~= nil and element == self.targetInputElement then
                    MiningLayers.protectedCall('markManualTargetHeight', function()
                        MiningLayers.markManualTargetHeight(self.area)
                    end)
                end

                return result
            end)
    end

    if editor ~= nil and MiningLayers.isCallable(editor.onInputEventUpDownAxis) then
        editor.onInputEventUpDownAxis = Utils.overwrittenFunction(editor.onInputEventUpDownAxis,
            function(self, superFunc, ...)
                local before = nil

                if self ~= nil and self.area ~= nil then
                    before = self.area.targetY
                end

                local result = superFunc(self, ...)

                if before ~= nil and self.area ~= nil and self.area.targetY ~= nil
                    and self.area.targetY ~= math.huge and before ~= math.huge
                    and math.abs(self.area.targetY - before) > 0.001 then
                    MiningLayers.protectedCall('markManualTargetHeight', function()
                        MiningLayers.markManualTargetHeight(self.area)
                    end)
                end

                return result
            end)
    end

    -- ★ Der eigentliche Waechter sitzt am SPEICHERN, nicht an der GUI (Befund 18.08.,
    -- Riverspot: Tommys eingetippte 3 m wurde in derselben Sekunde ueberschrieben).
    -- Die GUI merkt sich ihre Callback-Funktionen beim Laden - ein spaeter ersetzter
    -- Klassen-Eintrag wird dort nie aufgerufen. AreaEditor:onClickSave uebergibt aber
    -- IMMER einen Klon an LandscapingManager:updateArea, und der laeuft ueber die
    -- Metatable, also durch diesen Wrapper. Beleg fuer die Sauberkeit des Signals:
    -- PolygonEditor:createPoint fasst targetY nur an, solange es math.huge ist -
    -- eine GEAENDERTE Zielhoehe eines bestehenden Bereichs kann nur vom Spieler kommen.
    local manager = MiningLayers.tf('LandscapingManager')

    if manager ~= nil and MiningLayers.isCallable(manager.updateArea) then
        manager.updateArea = Utils.overwrittenFunction(manager.updateArea,
            function(self, superFunc, area, ...)
                if type(area) == 'table' and area.uniqueId ~= nil and type(self.areas) == 'table' then
                    local previous = self.areas[area.uniqueId]

                    if previous ~= nil and type(previous.targetY) == 'number' and type(area.targetY) == 'number'
                        and previous.targetY ~= math.huge and area.targetY ~= math.huge
                        and math.abs(area.targetY - previous.targetY) > 0.001 then
                        MiningLayers.protectedCall('markManualTargetHeight', function()
                            MiningLayers.markManualTargetHeight(area)
                        end)
                    end
                end

                return superFunc(self, area, ...)
            end)

        MiningLayers.log('Target height watch installed - a height you set yourself is never changed by the mod.')
    else
        MiningLayers.log('Target height watch NOT installed - LandscapingManager not found in TerraFarm.')
    end
end

---Merkt sich, dass der Spieler die Zielhoehe dieses Bereichs selbst gesetzt hat.
---@param area table
function MiningLayers.markManualTargetHeight(area)
    if type(area) ~= 'table' or area.uniqueId == nil or area.targetY == nil then
        return
    end

    if area.targetY == math.huge then
        return
    end

    local previous = MiningLayers.manualTargetByArea[area.uniqueId]

    MiningLayers.manualTargetByArea[area.uniqueId] = area.targetY
    MiningLayers.surfaceMemoryDirty = true

    if previous == nil then
        MiningLayers.log('Target height %.1f m set by hand - this area is yours from now on, the mod leaves it alone.',
            area.targetY)
    end
end

---@param area table
---@return boolean
function MiningLayers.isManualTargetHeight(area)
    if type(area) ~= 'table' or area.uniqueId == nil then
        return false
    end

    local stored = MiningLayers.manualTargetByArea[area.uniqueId]

    if stored == nil then
        return false
    end

    -- ⚠️ Nur solange die Hoehe auch noch die ist, die von Hand gesetzt wurde. Wird der
    -- Bereich spaeter geloescht und unter derselben Id neu gezeichnet, faellt die Marke
    -- damit von selbst weg, statt den neuen Bereich stumm zu blockieren.
    return area.targetY ~= nil and math.abs(area.targetY - stored) < 0.05
end

---@param area table
---@param resolved table
---@param surfaceY number
---@param label string
---@param plane table?
function MiningLayers:maybeSetPitFloor(area, resolved, surfaceY, label, plane)
    if area == nil or type(area.targetY) ~= 'number' then
        return
    end

    -- ⚠️ Der Schalter wird ERST WEITER UNTEN geprueft. Gerechnet wird immer, denn auch
    -- wenn wir nichts aendern duerfen, wollen wir sagen koennen, dass die Zielhoehe die
    -- unterste Schicht abschneidet. Ohne diesen Hinweis steht der Spieler vor einer
    -- Grube, die zu frueh aufhoert, und sucht den Fehler beim Mod.
    local minSurface, maxSurface = surfaceY, surfaceY

    if plane ~= nil and area.points ~= nil then
        minSurface, maxSurface = nil, nil

        for i = 1, #area.points do
            local point = area.points[i]

            if type(point) == 'table' and point[1] ~= nil and point[3] ~= nil then
                local y = MiningLayers.planeAt(plane, point[1], point[3])

                if minSurface == nil or y < minSurface then
                    minSurface = y
                end

                if maxSurface == nil or y > maxSurface then
                    maxSurface = y
                end
            end
        end

        if minSurface == nil then
            minSurface, maxSurface = surfaceY, surfaceY
        end
    end

    -- "Unser Wert": targetY ist exakt der Boden, den DIESER Mod in dieser Sitzung selbst
    -- gesetzt hat - dann darf er nach einer Bereichs-Aenderung nachgezogen werden
    -- (Tommys Frage: Nutzer vergroessern das Feld nachtraeglich).
    --
    -- ⚠️ ENTFERNT am 16.08.: die frueher hier stehende "Auto-Wert-Erkennung" (targetY
    -- liege innerhalb der Gelaendehoehen +/- 1 m, also sei es der Wegwerfwert des
    -- Editors). Diese Annahme ist am TerraFarm-Quelltext widerlegt:
    --   LandscapingAreaPolygon.lua:27  self.targetY = math.huge   (beim Anlegen)
    --   LandscapingAreaPolygon.lua:49  getIsValid verlangt targetY ~= math.huge
    -- Ein Bereich wird also erst GUELTIG, wenn eine Zielhoehe gesetzt wurde - es gibt
    -- keinen Wegwerfwert, den man von einer Absicht unterscheiden koennte. Wer eine
    -- ebene Flaeche auf Gelaendeniveau plant, landet zwangslaeufig im selben Fenster.
    -- Genau das ist Oreo (RGC) am 16.08. passiert: "it was digging to china when i set
    -- the height. I was making a pad but it was not paying attention to the target height."
    local storedAuto = self.autoFloorByArea[area.uniqueId]
    local isReauto = storedAuto ~= nil and math.abs(area.targetY - storedAuto) < 0.05

    -- Tiefste Schichtgrenze: depth zaehlt ab der Bezugsflaeche - am Hang ab deren
    -- TIEFSTEM Punkt, damit die unterste Schicht auch talseitig erreichbar ist.
    -- aboveY ist absolut und geht unveraendert ein.
    local deepestBoundary = nil

    for _, entry in ipairs(resolved) do
        local boundary = nil

        if entry.aboveY ~= nil then
            boundary = entry.aboveY
        elseif entry.depth ~= nil then
            boundary = minSurface - entry.depth
        end

        if boundary ~= nil and (deepestBoundary == nil or boundary < deepestBoundary) then
            deepestBoundary = boundary
        end
    end

    if deepestBoundary == nil then
        return
    end

    local oldY = area.targetY
    local newY = deepestBoundary - 2.0

    -- ★ Stand fuer die ANZEIGE merken (Tommys Frage 18.08.: "woher wissen die Leute
    -- beim ersten Mal, was sie einstellen sollen?"). Im Log liest das niemand, also
    -- gehoert es dorthin, wo der Spieler ohnehin hinsieht - siehe HeightDisplay.
    MiningLayers.setTargetStatus(area, oldY, deepestBoundary, MiningLayers.isManualTargetHeight(area))

    -- Wasserlinien-Klemme (Tommys Ansage: Wasser muss auch gehen): der AUTOMATISCHE
    -- Grubenboden bleibt knapp ueber dem Wasserspiegel, sonst flutet die Grube von
    -- selbst. Ein von Hand gesetzter Boden kommt hier nie an - bewusstes Fluten
    -- bleibt erlaubt.
    local waterY = MiningLayers.getAreaWaterY(area)

    local waterNote = nil

    if waterY ~= nil and newY < waterY + 0.2 then
        newY = waterY + 0.2
        -- Erst ausgeben, wenn wir den Boden wirklich setzen - beim blossen Hinweis
        -- unten waere die Zeile irrefuehrend.
        waterNote = string.format('%s: pit floor limited to %.1f m - water line (%.1f m).',
            label, newY, waterY)
    end

    local raisedFromWater = false

    if isReauto then
        -- Eigener Wert: in beide Richtungen nachziehen (der Boden folgt den
        -- Schichten), aber nicht wegen Rundungsrauschen loggen.
        if math.abs(newY - oldY) < 0.05 then
            return
        end
    elseif MiningLayers.isManualTargetHeight(area) then
        -- ★ Der Spieler hat die Hoehe SELBST eingestellt (Texteingabe oder Hoch/Runter
        -- im Bereichseditor). Ab hier gehoert sie ihm - genau darauf zielt das Planieren,
        -- die Berme und die Rampe. Wir aendern nichts, sagen aber einmal je Bereich, was
        -- diese Hoehe kostet, damit "die Grube hoert zu frueh auf" nicht beim Mod landet.
        if type(self.floorHintByArea) ~= 'table' then
            self.floorHintByArea = {}
        end

        -- Der Zuschnitt-Hinweis nur, wenn die Hoehe wirklich etwas abschneidet - eine
        -- bewusst UNTER die Schichten gelegte Hoehe (Teich) schneidet nichts ab.
        if oldY > deepestBoundary and not self.floorHintByArea[area.uniqueId] then
            self.floorHintByArea[area.uniqueId] = true

            MiningLayers.log('%s: target height %.1f m was set by hand and stays untouched.',
                label, oldY)
            MiningLayers.log('  It ends above the deepest layer boundary (%.1f m), so the lowest layers',
                deepestBoundary)
            MiningLayers.log('  stay out of reach. Lower it in the TerraFarm area editor to reach them.')
        end

        return
    elseif newY >= oldY then
        -- Die Zielhoehe reicht bereits tief genug - nichts zu tun, nichts zu melden.
        --
        -- ⚠️ Ausnahme: liegt der alte Boden UNTER der Wasserlinie und hat ihn niemand
        -- von Hand gesetzt, ist das der Altbestand des Ein-Punkt-Fehlers (Riverspot,
        -- 18.08.: -7,2 m im Spielstand). Stehen lassen hiesse: die Falle ueberlebt
        -- jeden Neustart. Der Zweig steht bewusst NACH dem manuellen - ein Boden, den
        -- der Spieler selbst unter Wasser gelegt hat (Teich, Fluten), bleibt seiner.
        if waterY == nil or oldY >= waterY or not self.autoTargetHeight then
            return
        end

        raisedFromWater = true
        MiningLayers.log('%s: pit floor %.1f m lies below the water line (%.1f m) and was not set by hand.',
            label, oldY, waterY)
        MiningLayers.log('  Raising it - an automatic floor must not flood the pit. Set it yourself to keep one below water.')
    elseif not self.autoTargetHeight then
        -- ★ Vorgabe seit 1.6 ist AUS, und hier ist der Grund (Oreo, RGC, 16.08.):
        -- Wir koennen eine bewusst gesetzte Zielhoehe nicht von einer beilaeufigen
        -- unterscheiden (Beleg oben an LandscapingAreaPolygon). Wer eine Flaeche
        -- planiert, bekam bis 1.5.0 ungefragt ein Loch statt einer Ebene.
        -- Also: nichts anfassen - aber einmal je Bereich sagen, was Sache ist.
        -- Ohne diesen Satz endet die Grube kommentarlos zu frueh und der Spieler
        -- sucht den Fehler beim Mod.
        if type(self.floorHintByArea) ~= 'table' then
            self.floorHintByArea = {}
        end

        if not self.floorHintByArea[area.uniqueId] then
            self.floorHintByArea[area.uniqueId] = true

            MiningLayers.log('%s: target height %.1f m ends above the deepest layer boundary (%.1f m).',
                label, oldY, deepestBoundary)
            MiningLayers.log('  Digging stops there, so the lowest layers stay out of reach. Either set the')
            MiningLayers.log('  pit floor lower in the TerraFarm area editor, or set autoTargetHeight="true"')
            MiningLayers.log('  in miningLayers.xml and the mod does it for you.')
        end

        return
    end

    if waterNote ~= nil then
        MiningLayers.log(waterNote)
    end

    area.targetY = newY
    self.autoFloorByArea[area.uniqueId] = newY
    self.surfaceMemoryDirty = true

    -- Der Boden ist jetzt gesetzt: Anzeige nachziehen, sonst zeigte sie weiter die
    -- alte Hoehe und behauptete, die Grube ende zu frueh.
    MiningLayers.setTargetStatus(area, newY, deepestBoundary, false)

    if isReauto then
        MiningLayers.log('%s: area changed - pit floor adjusted to %.1f m (was %.1f m).',
            label, newY, oldY)
    elseif raisedFromWater then
        MiningLayers.log('%s: pit floor raised to %.1f m - just above the water line.', label, newY)
    else
        MiningLayers.log('%s: pit floor set automatically to %.1f m (was %.1f m - the height the area came with).',
            label, area.targetY, oldY)

        -- "Deep enough" nur, wenn es stimmt: die Wasserklemme kann den Boden OBERHALB
        -- der tiefsten Grenze festhalten - dann ist die Zeile eine Falschauskunft.
        if newY <= deepestBoundary then
            MiningLayers.log('  Deep enough for every layer. Switch it off with autoTargetHeight="false".')
        else
            MiningLayers.log('  NOT deep enough for the lowest layers - the water line wins here.')
            MiningLayers.log('  Want to dig below the water on purpose? Set the target height yourself.')
        end
    end
end

---Schreibt die Bodentexturen dieser Karte ins Log.
---Ohne diese Liste muesste man die Namen fuer paintLayer raten - sie sind je Karte anders.
function MiningLayers:logTerrainLayers()
    local landscapingManager = MiningLayers.tf('g_landscapingManager')

    if type(landscapingManager) ~= 'table' or not MiningLayers.isCallable(landscapingManager.getTerrainLayers) then
        return
    end

    local layers = landscapingManager:getTerrainLayers()
    local names = {}

    for _, layer in ipairs(layers) do
        if layer.name ~= nil then
            table.insert(names, layer.name)
        end
    end

    if #names == 0 then
        return
    end

    MiningLayers.log('Ground textures on this map (%d) - names for paintLayer:', #names)

    -- In Bloecken ausgeben, sonst wird die Zeile im Log unlesbar lang.
    for i = 1, #names, 8 do
        MiningLayers.log('  %s', table.concat(names, ', ', i, math.min(i + 7, #names)))
    end
end

---Meldet beim Kartenstart nur den Bereichs-Bestand.
---
---Bewusst KEINE Vorab-Aufloesung mehr: beim Kartenstart sind TerraFarms Bereiche
---oft noch gar nicht geladen (belegt 2026-08-08: getAreas() leer, die Bereiche kamen
---erst nach loadMap), und Gelaendehoehen sind zu diesem Zeitpunkt nicht verlaesslich -
---ein hier gecachtes surfaceY waere Muell. Aufgeloest wird lazy beim ersten Zugriff,
---zur Grabzeit stimmen die Hoehen.
function MiningLayers:resolveAllAreas()
    if not self.enabled then
        return
    end

    local landscapingManager = MiningLayers.tf('g_landscapingManager')

    if type(landscapingManager) ~= 'table' or not MiningLayers.isCallable(landscapingManager.getAreas) then
        return
    end

    local areas = landscapingManager:getAreas()

    if #areas == 0 then
        MiningLayers.log('No area present (or not loaded yet). Draw a TerraFarm area')
        MiningLayers.log('  around the pit, then the defaultZone applies there automatically.')
    else
        MiningLayers.log('%d area(s) present - layers are resolved on the first dig.', #areas)
    end
end

---Alle Landscaping-Bereiche von TerraFarm (fuer die Ziel-Liste im Editor).
---⚠️ Der Manager heisst g_landscapingManager, nicht g_landscapingAreaManager -
---mit dem falschen Namen kam beim Kartenstart still eine leere Liste.
---@return table
function MiningLayers.getLandscapingAreas()
    local manager = MiningLayers.tf('g_landscapingManager')

    if manager == nil then
        return {}
    end

    if MiningLayers.isCallable(manager.getAreas) then
        local ok, areas = pcall(manager.getAreas, manager)

        if ok and type(areas) == 'table' then
            return areas
        end
    end

    return type(manager.areas) == 'table' and manager.areas or {}
end

---Verwirft den Cache eines Bereichs, wenn er im Editor geaendert wurde.
function MiningLayers:subscribeAreaUpdates()
    local ModMessageType = MiningLayers.tf('ModMessageType')

    if g_messageCenter == nil or type(ModMessageType) ~= 'table' then
        return
    end

    ---★★ g_messageCenter ruft den Empfaenger als callback(target, ...) auf.
    ---Mit MiningLayers als target kam bisher die Mod-Tabelle als erstes Argument
    ---an, nicht der Bereich - die Cache-Invalidierung lief also nie.
    ---TerraFarm uebergibt darum ueberall
    ---Methode + self (z.B. MachineSettingsAreaFrame.lua:90).
    ---Wir nehmen den Bereich aus den Argumenten heraus, egal an welcher Stelle
    ---er steht - das haelt auch, falls sich die Aufrufform je aendert.
    ---@return table? area
    ---@return any id
    local function pickArea(...)
        for i = 1, select('#', ...) do
            local value = select(i, ...)

            if type(value) == 'table' and value.uniqueId ~= nil then
                return value, value.uniqueId
            end

            if type(value) == 'string' or type(value) == 'number' then
                return nil, value
            end
        end

        return nil, nil
    end

    local function invalidate(...)
        local _, id = pickArea(...)

        if id ~= nil then
            MiningLayers.resolvedByArea[id] = nil
        end
    end

    -- Bereich neu angelegt oder verschoben: Cache des Bereichs verwerfen.
    local function onAreaChanged(...)
        local _, id = pickArea(...)

        if id ~= nil then
            MiningLayers.resolvedByArea[id] = nil
        end
    end

    if ModMessageType.LANDSCAPING_AREA_REGISTER ~= nil then
        g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_REGISTER, onAreaChanged, MiningLayers)
    end

    if ModMessageType.LANDSCAPING_AREA_UPDATE ~= nil then
        g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_UPDATE, onAreaChanged, MiningLayers)
    end

    -- Bereich geloescht: Cache des Bereichs verwerfen.
    local function onAreaDeleted(...)
        local _, id = pickArea(...)

        if id == nil then
            return
        end

        MiningLayers.resolvedByArea[id] = nil
    end

    if ModMessageType.LANDSCAPING_AREA_DELETE ~= nil then
        g_messageCenter:subscribe(ModMessageType.LANDSCAPING_AREA_DELETE, onAreaDeleted, MiningLayers)
    end

    MiningLayers.log('Area events subscribed (register=%s, update=%s, delete=%s).',
        tostring(ModMessageType.LANDSCAPING_AREA_REGISTER ~= nil),
        tostring(ModMessageType.LANDSCAPING_AREA_UPDATE ~= nil),
        tostring(ModMessageType.LANDSCAPING_AREA_DELETE ~= nil))
end

--------------------------------------------------------------------------------
-- Schicht an einer Stelle
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Halden-Gedaechtnis
--------------------------------------------------------------------------------

---@param x number
---@param z number
---@return string
function MiningLayers.moundCellKey(x, z)
    return math.floor(x / 2) .. '_' .. math.floor(z / 2)
end

---Niedrigster Gelaendepunkt einer Zelle (Mitte + vier Viertelpunkte + optional
---ein Zusatzpunkt). Das ist die ehrlichste Ursprungshoehe: waehrend eines laufenden
---Abwurfs ist ein Teil der Zelle schon angehoben - der tiefste Punkt ist der Boden.
---@param cellX number
---@param cellZ number
---@param extraX number? Zusatzpunkt (z. B. exakte Abwurfstelle)
---@param extraZ number?
---@return number? minY
function MiningLayers.getMoundCellFloor(cellX, cellZ, extraX, extraZ)
    local x0 = cellX * 2
    local z0 = cellZ * 2

    local offsets = {
        { 1.0, 1.0 },
        { 0.5, 0.5 }, { 0.5, 1.5 }, { 1.5, 0.5 }, { 1.5, 1.5 }
    }

    local minY = nil

    for _, offset in ipairs(offsets) do
        local y = getTerrainHeightAtWorldPos(g_terrainNode, x0 + offset[1], 0, z0 + offset[2])

        if type(y) == 'number' and (minY == nil or y < minY) then
            minY = y
        end
    end

    if extraX ~= nil and extraZ ~= nil then
        local y = getTerrainHeightAtWorldPos(g_terrainNode, extraX, 0, extraZ)

        if type(y) == 'number' and (minY == nil or y < minY) then
            minY = y
        end
    end

    return minY
end

---Friert die Bezugshoehe einer Rasterzelle ein, falls noch nicht geschehen.
---Gemessen wird die MITTE der Zelle: das Gelaende ist hier noch unberuehrt, und
---der Mittelwert ist stabiler als ein Minimum ueber Bodenwellen (anders als beim
---Halden-Gedaechtnis, wo unter dem wachsenden Haufen der tiefste Punkt zaehlt).
---@param cellX number Zellindex X (floor(welt/2))
---@param cellZ number Zellindex Z
---@return boolean written
function MiningLayers:freezeSurfaceCell(cellX, cellZ)
    local key = cellX .. '_' .. cellZ

    if self.surfaceMemory[key] ~= nil then
        return false
    end

    local y = getTerrainHeightAtWorldPos(g_terrainNode, cellX * 2 + 1, 0, cellZ * 2 + 1)

    if type(y) ~= 'number' then
        return false
    end

    self.surfaceMemory[key] = y
    self.surfaceMemoryDirty = true

    return true
end

---Bezugshoehe an einem Weltpunkt: erst das Raster, sonst die Bereichs-Ebene,
---sonst der Median. Der Rueckfall haelt das Verhalten von 1.4.x aufrecht, solange
---eine Stelle noch nie begraben wurde - und traegt alte Spielstaende ohne Raster.
---@param x number
---@param z number
---@param plane table? Ebene aus computeSurfaceY
---@param fallbackY number? Median des Bereichs
---@return number? surfacePointY
function MiningLayers:getSurfacePointY(x, z, plane, fallbackY)
    local cached = self.surfaceMemory[MiningLayers.moundCellKey(x, z)]

    if cached ~= nil then
        return cached
    end

    if plane ~= nil then
        return MiningLayers.planeAt(plane, x, z)
    end

    return fallbackY
end

---Merkt sich, welches Material an dieser Stelle abgekippt wurde.
---
---Ursprungshoehe (baseY) beim Anlegen der Zelle = NIEDRIGSTER Punkt der Zelle,
---NICHT die Hoehe an der Abwurfstelle: beim Abladen sitzt der Messpunkt oben auf
---der wachsenden Halde. Die Vorversion nahm diese Hoehe als Basis - die Basis
---kletterte mit dem Haufen (Live-Log 2026-08-08 21:41: Basis 17,0 -> 18,3 m in
---einer Sekunde) und lag am Ende UEBER der Spitze -> Zelle galt sofort als
---aufgebraucht. Weitere Abwuerfe behalten baseY, der letzte Abwurf stellt das
---Material; jeder Abwurf stempelt die Zelle frisch (Schonfrist, siehe
---getMoundFillTypeAt).
---@param x number
---@param z number
---@param fillTypeName string
function MiningLayers:recordMound(x, z, fillTypeName)
    local key = MiningLayers.moundCellKey(x, z)
    local cell = self.moundMemory[key]
    local now = type(g_time) == 'number' and g_time or nil

    if cell == nil then
        local baseY = MiningLayers.getMoundCellFloor(math.floor(x / 2), math.floor(z / 2), x, z)

        if baseY == nil then
            -- Ohne Ursprungshoehe ist die Zelle wertlos (siehe getMoundFillTypeAt).
            return
        end

        cell = { f = fillTypeName, b = baseY, t = now }
        self.moundMemory[key] = cell
        self.moundMemoryDirty = true
    elseif cell.f ~= fillTypeName then
        cell.f = fillTypeName
        cell.t = now
        self.moundMemoryDirty = true
    else
        -- Nur den Frische-Stempel erneuern: solange gekippt wird, bleibt die
        -- Zelle in der Schonfrist. Kein dirty - auf Platte aendert sich nichts.
        cell.t = now
        return
    end

    self.moundMemoryWrites = self.moundMemoryWrites + 1

    -- Gelegentlich wegschreiben, damit ein Absturz nicht die ganze Session kostet.
    if self.moundMemoryWrites % 25 == 0 then
        pcall(MiningLayers.saveMoundMemory, MiningLayers)
    end
end

---Lebt diese Halden-Zelle noch? Massgeblich ist der HOECHSTE Gelaendepunkt der
---Zelle (Mitte + vier Viertelpunkte), nicht ein zufaelliger Abfragepunkt.
---
---Grund (Tommys Befund 2026-08-08 spaetabends, per moundMemory1.xml belegt): die
---Vorversion verglich am Abfragepunkt - der liegt beim Heranfahren zwangslaeufig
---irgendwann am Haldenrand, wo das Gelaende naturgemaess auf Ursprungshoehe ist.
---Ein einziger solcher Frame (die Anzeige fragt jeden Frame!) loeschte die Zelle,
---und eine grosse Halde steckt oft in genau EINER Zelle -> GRAVEL- und
---PAYDIRT-Zellen verschwanden, uebrig blieb DIRT aus Schicht/Auswahl.
---Loeschen ist unumkehrbar - im Zweifel muss die Zelle leben: zu lange Halde
---heilt sich beim Abtragen selbst, eine geloeschte Halde nie.
---Viertelpunkte statt Ecken, damit kein Nachbar-Haufen die Messung anhebt.
---@param cellX number Zellindex X (floor(welt/2))
---@param cellZ number Zellindex Z
---@param baseY number Ursprungshoehe der Zelle
---@return boolean
function MiningLayers.isMoundCellAlive(cellX, cellZ, baseY)
    local x0 = cellX * 2
    local z0 = cellZ * 2

    local offsets = {
        { 1.0, 1.0 },
        { 0.5, 0.5 }, { 0.5, 1.5 }, { 1.5, 0.5 }, { 1.5, 1.5 }
    }

    for _, offset in ipairs(offsets) do
        local y = getTerrainHeightAtWorldPos(g_terrainNode, x0 + offset[1], 0, z0 + offset[2])

        if type(y) == 'number' and y > baseY + MiningLayers.MOUND_DEPLETE_TOLERANCE then
            return true
        end
    end

    return false
end

---Welches Material liegt hier aufgeschuettet? Prueft die Zelle und ihre Nachbarn
---(deckt 6 x 6 m ab - eine Halde ist breiter als eine Rasterzelle), naechstliegende
---zuerst. Tote Zellen (ganze Zelle zurueck auf Ursprungshoehe) werden dabei
---geloescht - darunter gelten wieder die Schichten.
---
---Zwei getrennte Fragen, zwei getrennte Antworten:
---1. "Lebt die Zelle noch?" - hoechster Punkt der Zelle (isMoundCellAlive).
---   Entscheidet NUR ueber das Loeschen. Grosszuegig, weil Loeschen unumkehrbar ist.
---2. "Ist der Grabpunkt Haldenkoerper?" - terrainY gegen die Basis der Zelle.
---   Entscheidet ueber das MATERIAL. Unter der Basis ist die Halde durchstochen:
---   Geologie, auch wenn am Zellrand noch Reste aufragen. Ohne diese Trennung
---   liefert ein Krater durch die Halde endlos Haldenmaterial (Krater-Cheat).
---@param x number
---@param z number
---@param terrainY number? Gelaendehoehe am Grabpunkt; nil = nur Bestandsfrage
---@return string? fillTypeName
function MiningLayers:getMoundFillTypeAt(x, z, terrainY)
    local cx = math.floor(x / 2)
    local cz = math.floor(z / 2)

    local candidates = {}

    for dx = -1, 1 do
        for dz = -1, 1 do
            local key = (cx + dx) .. '_' .. (cz + dz)
            local cell = self.moundMemory[key]

            if cell ~= nil then
                local mx = (cx + dx) * 2 + 1 - x
                local mz = (cz + dz) * 2 + 1 - z

                table.insert(candidates, {
                    key = key, cell = cell,
                    cellX = cx + dx, cellZ = cz + dz,
                    dist = mx * mx + mz * mz
                })
            end
        end
    end

    if #candidates == 0 then
        return nil
    end

    table.sort(candidates, function(a, b)
        return a.dist < b.dist
    end)

    local now = type(g_time) == 'number' and g_time or nil

    for _, candidate in ipairs(candidates) do
        local cell = candidate.cell

        -- Schonfrist: In eine Zelle, in die gerade (noch) gekippt wird, wird nicht
        -- hineingeloescht - der Haufen ist waehrend des Abladens erst wenige
        -- Zentimeter hoch und saehe sonst wie "aufgebraucht" aus.
        local isFresh = now ~= nil and type(cell.t) == 'number'
            and (now - cell.t) < MiningLayers.MOUND_DELETE_GRACE_MS

        if isFresh or cell.b == nil
            or MiningLayers.isMoundCellAlive(candidate.cellX, candidate.cellZ, cell.b) then
            -- Zelle lebt. Material gibt es aber nur, wenn der Grabpunkt selbst noch
            -- im Haldenkoerper liegt - unterhalb der Basis ist die Halde hier
            -- durchstochen und es gilt die Geologie (Krater-Cheat-Sperre).
            if terrainY == nil or cell.b == nil
                or terrainY > cell.b - MiningLayers.MOUND_BELOW_BASE_TOLERANCE then
                return cell.f
            end

            return nil
        end

        -- Ganze Zelle zurueck auf Ursprungshoehe: aufgebraucht, vergessen.
        -- Die Logzeile ist Absicht (selten genug): so ist ein falsches Loeschen
        -- im Log sofort sichtbar, statt muehsam rekonstruiert zu werden.
        self.moundMemory[candidate.key] = nil
        self.moundMemoryDirty = true
        MiningLayers.log('Pile cell %s (%s, base %.1f m) used up - deleted, layers apply below it again.',
            candidate.key, tostring(cell.f), cell.b or 0)
    end

    return nil
end

---Gemeinsamer Schicht-Eintrag fuer eine erkannte Halde.
---@param fillTypeName string
---@return table? entry
function MiningLayers:getSpoilEntry(fillTypeName)
    local entry = self.spoilEntries[fillTypeName]

    if entry == nil then
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

        if fillType == nil then
            return nil
        end

        entry = {
            fillTypeName = fillTypeName,
            fillTypeIndex = fillType.index,
            boundary = nil,
            terrainLayerResolved = false,
            -- Kennzeichnung fuer die Anzeige: das ist eine erkannte Halde, keine Schicht.
            isMound = true
        }
        self.spoilEntries[fillTypeName] = entry
    end

    return entry
end

---T14: Ueberschreib-Eintrag fuer den Abraum-Modus - EIN gecachtes Objekt, damit
---getTerrainLayerFor seine Texturaufloesung daran cachen kann (ein frisches Table
---je Grabvorgang wuerde die Aufloesung jeden Tick neu bezahlen). Kein isMound:
---dieser Eintrag IST eine Schichtentscheidung, keine Halde. Der Cache haengt am
---Materialnamen und wird in loadConfig entwertet (spoilModeEntry = nil).
---@return table? entry
function MiningLayers:getSpoilModeEntry()
    local entry = self.spoilModeEntry

    if entry ~= nil and entry.fillTypeName == self.spoilMaterial then
        return entry
    end

    local fillType = g_fillTypeManager:getFillTypeByName(self.spoilMaterial)

    if fillType == nil and self.spoilMaterial ~= 'DIRT' then
        -- Unbekanntes Material aus der XML: einmal melden, dann DIRT.
        if not self.spoilMaterialWarned then
            self.spoilMaterialWarned = true
            MiningLayers.log('Spoil mode: material "%s" unknown on this map - falling back to DIRT.',
                tostring(self.spoilMaterial))
        end

        fillType = g_fillTypeManager:getFillTypeByName('DIRT')
    end

    if fillType == nil then
        return nil
    end

    entry = {
        fillTypeName = fillType.name,
        fillTypeIndex = fillType.index,
        boundary = nil,
        terrainLayerResolved = false
    }
    self.spoilModeEntry = entry

    return entry
end

---@return string? path
function MiningLayers:getMoundMemoryPath()
    if self.SETTINGS_DIRECTORY == nil then
        return nil
    end

    local index = ''

    if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil
        and g_currentMission.missionInfo.savegameIndex ~= nil then
        index = tostring(g_currentMission.missionInfo.savegameIndex)
    end

    return self.SETTINGS_DIRECTORY .. 'moundMemory' .. index .. '.xml'
end

---Schreibt das Halden-Gedaechtnis auf Platte (klassische XML-API, schema-frei).
function MiningLayers:saveMoundMemory()
    if not self.moundMemoryDirty then
        return
    end

    local path = self:getMoundMemoryPath()

    if path == nil or not MiningLayers.isCallable(createXMLFile)
        or not MiningLayers.isCallable(setXMLString) or not MiningLayers.isCallable(saveXMLFile) then
        return
    end

    local xmlId = createXMLFile('miningLayersMounds', path, 'mounds')

    if xmlId == nil or xmlId == 0 then
        return
    end

    local i = 0

    for key, cell in pairs(self.moundMemory) do
        local base = string.format('mounds.m(%d)', i)
        setXMLString(xmlId, base .. '#k', key)
        setXMLString(xmlId, base .. '#f', cell.f)
        -- Ursprungshoehe als String: die klassische XML-API ist schema-frei,
        -- getString/setString sind die einzigen belegt sicheren Zugriffe.
        setXMLString(xmlId, base .. '#b', string.format('%.2f', cell.b))
        i = i + 1
    end

    saveXMLFile(xmlId)
    delete(xmlId)
    self.moundMemoryDirty = false
end

---Pfad des Bezugshoehen-Rasters, je Spielstand getrennt wie beim Halden-Gedaechtnis.
---@return string?
function MiningLayers:getSurfaceMemoryPath()
    if self.SETTINGS_DIRECTORY == nil then
        return nil
    end

    local index = ''

    if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil
        and g_currentMission.missionInfo.savegameIndex ~= nil then
        index = tostring(g_currentMission.missionInfo.savegameIndex)
    end

    return self.SETTINGS_DIRECTORY .. 'surfaceMemory' .. index .. '.xml'
end

---Schreibt das Bezugshoehen-Raster auf Platte.
function MiningLayers:saveSurfaceMemory()
    if not self.surfaceMemoryDirty then
        return
    end

    local path = self:getSurfaceMemoryPath()

    if path == nil or not MiningLayers.isCallable(createXMLFile)
        or not MiningLayers.isCallable(setXMLString) or not MiningLayers.isCallable(saveXMLFile) then
        return
    end

    local xmlId = createXMLFile('miningLayersSurface', path, 'surface')

    if xmlId == nil or xmlId == 0 then
        return
    end

    local i = 0

    for key, y in pairs(self.surfaceMemory) do
        local base = string.format('surface.s(%d)', i)
        setXMLString(xmlId, base .. '#k', key)
        setXMLString(xmlId, base .. '#y', string.format('%.2f', y))
        i = i + 1
    end

    -- Von Hand gesetzte Zielhoehen gehoeren zum Spielstand, nicht in die globale
    -- Konfiguration: Bereiche gibt es nur dort. Ohne diese Zeilen waere nach dem
    -- Neuladen wieder unbekannt, welche Hoehe jemand selbst eingestellt hat - und die
    -- Automatik wuerde sie ueberschreiben. Genau das war Oreos Fehlerbild.
    local t = 0

    for areaId, y in pairs(MiningLayers.manualTargetByArea) do
        local base = string.format('surface.t(%d)', t)
        setXMLString(xmlId, base .. '#a', tostring(areaId))
        setXMLString(xmlId, base .. '#y', string.format('%.2f', y))
        t = t + 1
    end

    -- Auch die AUTOMATISCH gesetzten Boeden merken. Ohne sie weiss der Mod nach dem
    -- Neuladen nicht mehr, dass ein targetY im Spielstand seins war - und kann einen
    -- falsch gesetzten Boden (Riverspot: -7,2 m vor dem Wasserklemmen-Fix) nie wieder
    -- korrigieren, weil "reicht tief genug" ihn fuer immer stehen liesse.
    local f = 0

    for areaId, y in pairs(MiningLayers.autoFloorByArea) do
        local base = string.format('surface.f(%d)', f)
        setXMLString(xmlId, base .. '#a', tostring(areaId))
        setXMLString(xmlId, base .. '#y', string.format('%.2f', y))
        f = f + 1
    end

    saveXMLFile(xmlId)
    delete(xmlId)
    self.surfaceMemoryDirty = false
end

---Laedt das Bezugshoehen-Raster dieses Spielstands.
function MiningLayers:loadSurfaceMemory()
    self.surfaceMemory = {}

    local path = self:getSurfaceMemoryPath()

    if path == nil or not MiningLayers.isCallable(loadXMLFile)
        or not MiningLayers.isCallable(fileExists) or not fileExists(path)
        or not MiningLayers.isCallable(getXMLString) then
        return
    end

    local xmlId = loadXMLFile('miningLayersSurface', path)

    if xmlId == nil or xmlId == 0 then
        return
    end

    local i = 0
    local count = 0

    while true do
        local base = string.format('surface.s(%d)', i)
        local key = getXMLString(xmlId, base .. '#k')

        if key == nil then
            break
        end

        local y = tonumber(getXMLString(xmlId, base .. '#y') or '')

        if y ~= nil then
            self.surfaceMemory[key] = y
            count = count + 1
        end

        i = i + 1
    end

    -- Von Hand gesetzte Zielhoehen zurueckholen (siehe saveSurfaceMemory).
    MiningLayers.manualTargetByArea = {}

    local t = 0
    local manualCount = 0

    while true do
        local base = string.format('surface.t(%d)', t)
        local areaId = getXMLString(xmlId, base .. '#a')

        if areaId == nil then
            break
        end

        local y = tonumber(getXMLString(xmlId, base .. '#y') or '')

        if y ~= nil then
            MiningLayers.manualTargetByArea[areaId] = y
            manualCount = manualCount + 1
        end

        t = t + 1
    end

    MiningLayers.autoFloorByArea = {}

    local f = 0

    while true do
        local base = string.format('surface.f(%d)', f)
        local areaId = getXMLString(xmlId, base .. '#a')

        if areaId == nil then
            break
        end

        local y = tonumber(getXMLString(xmlId, base .. '#y') or '')

        if y ~= nil then
            MiningLayers.autoFloorByArea[areaId] = y
        end

        f = f + 1
    end

    delete(xmlId)

    if count > 0 then
        MiningLayers.log('Surface grid loaded: %d cell(s).', count)
    end

    if manualCount > 0 then
        MiningLayers.log('Target heights set by hand: %d area(s) - the mod leaves those alone.', manualCount)
    end
end

---Laedt das Halden-Gedaechtnis dieses Spielstands.
function MiningLayers:loadMoundMemory()
    self.moundMemory = {}

    local path = self:getMoundMemoryPath()

    if path == nil or not MiningLayers.isCallable(loadXMLFile)
        or not MiningLayers.isCallable(fileExists) or not fileExists(path)
        or not MiningLayers.isCallable(getXMLString) then
        return
    end

    local xmlId = loadXMLFile('miningLayersMounds', path)

    if xmlId == nil or xmlId == 0 then
        return
    end

    local i = 0
    local count = 0
    local discarded = 0

    while true do
        local base = string.format('mounds.m(%d)', i)
        local key = getXMLString(xmlId, base .. '#k')

        if key == nil then
            break
        end

        local name = getXMLString(xmlId, base .. '#f')
        local baseY = tonumber(getXMLString(xmlId, base .. '#b') or '')

        if name ~= nil and baseY ~= nil then
            self.moundMemory[key] = { f = name, b = baseY }
            count = count + 1
        elseif name ~= nil then
            -- Alter Eintrag ohne Ursprungshoehe (Format vor dem baseY-Fix):
            -- verwerfen. Neuanfang ist billiger als ein Migrationsfehler.
            discarded = discarded + 1
        end

        i = i + 1
    end

    delete(xmlId)

    if count > 0 or discarded > 0 then
        MiningLayers.log('Pile memory loaded: %d cell(s).', count)
    end

    if discarded > 0 then
        MiningLayers.log('  %d old cell(s) without an origin height discarded - dump those piles again.', discarded)
        -- Bereinigten Stand beim naechsten Speichern festschreiben.
        self.moundMemoryDirty = true
    end
end

---Grenzhoehe eines Schicht-Eintrags an einem Punkt: depth zaehlt ab der (ggf.
---geneigten) Bezugsflaeche, aboveY bleibt absolut. Ohne Punktwert bleibt die an
---der Bezugshoehe vorgerechnete Grenze - identisches Verhalten auf ebenem Boden.
---@param entry table
---@param surfacePointY number?
---@return number? boundary
function MiningLayers.entryBoundaryAt(entry, surfacePointY)
    if entry.aboveY ~= nil then
        return entry.aboveY
    end

    if entry.depth ~= nil and surfacePointY ~= nil then
        return surfacePointY - entry.depth
    end

    return entry.boundary
end

---@param resolved table
---@param terrainY number
---@param surfacePointY number? Bezugsflaechen-Hoehe an diesem Punkt
---@return table? entry
function MiningLayers:findLayer(resolved, terrainY, surfacePointY)
    for _, entry in ipairs(resolved) do
        local boundary = MiningLayers.entryBoundaryAt(entry, surfacePointY)

        if boundary == nil or terrainY > boundary then
            return entry
        end
    end

    return nil
end

---Ermittelt Zone, Bezugshoehe und greifende Schicht fuer ein Fahrzeug.
---Wird sowohl beim Graben als auch von der Anzeige benutzt.
---@param vehicle table
---@param worldPosX number
---@param worldPosZ number
---@return table? entry
---@return number terrainY
---@return number? surfaceY
---@return string? zoneName
---@return string? reason  'manual' = Material im Bereich gesetzt, 'off' = per XML ausgenommen
function MiningLayers:getLayerAt(vehicle, worldPosX, worldPosZ)
    local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, worldPosX, 0, worldPosZ)

    if not self.enabled then
        return nil, terrainY, nil, nil, nil
    end

    local area = nil

    if vehicle ~= nil and MiningLayers.isCallable(vehicle.getMachineInputArea) then
        local foundArea, isEnabled = vehicle:getMachineInputArea()

        if foundArea ~= nil and isEnabled then
            area = foundArea
        end
    end

    local resolved, surfaceY, plane

    if area ~= nil then
        -- Pfad-Bereiche (Strassen, Rohrgraeben) haben keine Grubenflaeche - Bezugshoehe
        -- und Grubenboden ergeben dort keinen Sinn. Schichten gibt es nur in
        -- Polygon-Bereichen; der Pfad bleibt reines TerraFarm. Erkennung am width-Feld,
        -- das nur LandscapingAreaPath hat (LandscapingAreaPath.lua:28).
        if area.width ~= nil then
            return nil, terrainY, nil, nil, 'path'
        end

        -- Umschalt-Sicherung: Wer im Bereich ein Material eintraegt, will Handbetrieb -
        -- Baustelle, Rohrgraben, Aufschuetten. Dann laesst der Mod den Bereich komplett
        -- in Ruhe: kein Material, keine Textur, kein Rueckfall auf die globalZone,
        -- auch kein Halden-Gedaechtnis (das dort auch nicht gefuellt wird).
        -- Leeres Feld ist nil (belegt AreaEditor.lua:268), und TerraFarms HUD zeigt ein
        -- gesetztes Bereichs-Material von selbst an - die Anzeige rechts stimmt dann.
        if area.forceFillTypeIndex ~= nil then
            return nil, terrainY, nil, nil, 'manual'
        end

        local isOff

        resolved, surfaceY, isOff, plane = self:getResolvedForArea(area)

        if isOff then
            return nil, terrainY, nil, nil, 'off'
        end
    end

    -- Halden-Gedaechtnis ZUERST - und AUCH OHNE BEREICH: eine Halde ist eine Halde,
    -- egal ob sie im Polygon steht oder daneben (dahin kippt man sie ja). Sie gilt
    -- von ihrer Ursprungshoehe (baseY) bis zur Spitze, unabhaengig von jeder
    -- Bezugshoehe - Flanken, Reste, Verfuelltes in der Grube. Bis zur Basis
    -- zurueckgegraben loescht die Abfrage die Zelle selbst - darunter Schichten
    -- bzw. ohne Bereich wieder normales TerraFarm.
    -- (Befund Tommy 2026-08-08 abends: PAYDIRT-Halde lieferte DIRT - das Gedaechtnis
    -- wurde nur INNERHALB des Bereichs befragt, die Halde stand daneben.)
    local moundFill = self:getMoundFillTypeAt(worldPosX, worldPosZ, terrainY)
    local moundEntry = moundFill ~= nil and self:getSpoilEntry(moundFill) or nil

    if moundEntry ~= nil then
        local surfacePointY = self:getSurfacePointY(worldPosX, worldPosZ, plane, surfaceY)

        local zoneName = 'Halde'

        if area ~= nil then
            zoneName = area.name or area.uniqueId
        end

        return moundEntry, terrainY, surfacePointY, zoneName
    end

    if area ~= nil and resolved ~= nil and resolved ~= false then
        -- Bezugsflaeche an DIESEM Punkt: erst das eingefrorene Raster, sonst die
        -- geneigte Ebene, sonst der Median. Das Raster kennt die Kuppe, die Ebene
        -- mittelt sie weg - deshalb hat es Vorrang.
        local surfacePointY = self:getSurfacePointY(worldPosX, worldPosZ, plane, surfaceY)

        -- Ueber der Bezugsflaeche liegt kein gewachsener Boden, sondern Abraum.
        -- Nur noch Rueckfall fuer UNBEKANNTE Halden (vor der Installation
        -- gebaut / Gedaechtnis weg): dort gilt die TerraFarm-Auswahl.
        if surfacePointY ~= nil and terrainY > surfacePointY + MiningLayers.SPOIL_TOLERANCE then
            return nil, terrainY, surfacePointY, area.name or area.uniqueId, 'spoil'
        end

        return self:findLayer(resolved, terrainY, surfacePointY), terrainY, surfacePointY,
            area.name or area.uniqueId
    end

    if self.resolvedGlobal ~= nil then
        local globalSurfaceY = self.globalZone ~= nil and self.globalZone.surfaceY or nil
        -- Ohne Bereich gibt es keine Ebene: entweder das Raster oder der feste Wert.
        local surfacePointY = self:getSurfacePointY(worldPosX, worldPosZ, nil, globalSurfaceY)

        -- Ohne Bezugshoehe KEINE Schicht. Sonst liefert findLayer den obersten
        -- Eintrag, weil ohne surfacePointY keine Grenze zu rechnen ist - und das
        -- waere geraten: beim Nachgraben in einer Halde oder an einer fremden
        -- Grubenkante grob falsch. Beim echten Graben tritt der Fall praktisch nie
        -- ein, weil freezeSurfaceAround VOR getLayerAt laeuft (LayerHooks :240 vor
        -- :243) - er trifft die Anzeige, wenn man nur danebensteht.
        if surfacePointY == nil then
            return nil, terrainY, nil, 'globalZone', 'noSurface'
        end

        if terrainY > surfacePointY + MiningLayers.SPOIL_TOLERANCE then
            return nil, terrainY, surfacePointY, 'globalZone', 'spoil'
        end

        return self:findLayer(self.resolvedGlobal, terrainY, surfacePointY), terrainY, surfacePointY, 'globalZone'
    end

    return nil, terrainY, nil, nil
end
