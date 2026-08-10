--
-- Hoehen- und Tiefenanzeige.
--
-- Die Hoehe braucht man zum Einrichten, die Tiefe beim Spielen. Ohne diese Anzeige
-- muesste man die Schichtgrenzen raten.
--
-- Gezeichnet wird ueber den ModEventListener (MiningLayers:draw in main.lua).
-- Rueckfallebene ist logFirstReading() weiter unten - sie haengt am Hook und damit
-- an einem anderen Codepfad, siehe Begruendung dort.
--

---@diagnostic disable: lowercase-global, undefined-global

MiningLayers.displayErrorReported = false
MiningLayers.firstReadingLogged = false

---Zahl mit dem Trennzeichen der eingestellten Sprache.
---@param value number
---@return string
function MiningLayers.formatNumber(value)
    local text = string.format('%.1f', value)
    local separator = g_i18n ~= nil and g_i18n:getText('ml_decimalSeparator') or '.'

    if separator == ',' then
        text = text:gsub('%.', ',')
    end

    return text
end

---@param key string
---@param fallback string
---@return string
function MiningLayers.getText(key, fallback)
    if g_i18n == nil then
        return fallback
    end

    local text = g_i18n:getText(key)

    -- getText liefert bei unbekanntem Schluessel den Schluessel selbst zurueck.
    if text == nil or text == key then
        return fallback
    end

    return text
end

---Das News-Band: die wichtigen Regeln rotieren langsam als letzte Zeile durch,
---damit niemand die Anleitung lesen muss (Tommys Idee). Reihenfolge = Lernkurve.
MiningLayers.TIPS = {
    { key = 'ml_tip1', fallback = 'Bereich ziehen, Felder leer lassen - den Grubenboden setzt der Mod' },
    { key = 'ml_tip2', fallback = 'Material im Bereich eintragen = normales TerraFarm ohne Schichten (Baustellen)' },
    { key = 'ml_tip3', fallback = 'Loeffel vor dem Schichtwechsel leeren - ein Loeffel, ein Material' },
    { key = 'ml_tip4', fallback = 'Halden merkt sich der Mod - aufgenommen wird, was abgekippt wurde' },
    { key = 'ml_tip5', fallback = 'Linienfarbe = Material, das ab dort beginnt; rot = Grubenboden' },
    { key = 'ml_tip6', fallback = 'Anzeige links zeigt, wie weit es noch bis zur naechsten Schicht ist' },
}

---Sekunden pro Tipp im News-Band.
MiningLayers.TIP_SECONDS = 12

---Haengt den aktuellen Tipp ans Zeilenende. Ohne Zeitquelle bleibt der erste stehen.
---@param lines string[]
function MiningLayers:appendTip(lines)
    local tips = MiningLayers.TIPS

    if #tips == 0 then
        return
    end

    local timeMs = nil

    if type(g_time) == 'number' then
        timeMs = g_time
    elseif g_currentMission ~= nil and type(g_currentMission.time) == 'number' then
        timeMs = g_currentMission.time
    end

    local index = 1

    if timeMs ~= nil then
        index = (math.floor(timeMs / (MiningLayers.TIP_SECONDS * 1000)) % #tips) + 1
    end

    local tip = tips[index]

    -- Leerzeile davor (Tommys Wunsch): sonst klebt das News-Band an den Messwerten
    -- und alles wirkt aufeinander gequetscht.
    table.insert(lines, '')
    table.insert(lines, '» ' .. MiningLayers.getText(tip.key, tip.fallback))

    -- Kein Tasten-Hinweis im News-Band: die F1-Hilfe zeigt die Toggle-Taste
    -- mit der ECHTEN Belegung an (setActionEventText) - hier stuende sonst
    -- "Num 5", obwohl der Spieler laengst umbelegt hat.
end

---Sammelt die Zeilen fuer die Anzeige.
---@return string[]? lines
function MiningLayers:buildDisplayLines()
    local machineManager = MiningLayers.tf('g_machineManager')

    if type(machineManager) ~= 'table' then
        return nil
    end

    local vehicle = machineManager.activeVehicle

    if vehicle == nil then
        return nil
    end

    local modSettings = MiningLayers.tf('g_modSettings')

    if type(modSettings) == 'table' and MiningLayers.isCallable(modSettings.getIsEnabled) and not modSettings:getIsEnabled() then
        return nil
    end

    if MiningLayers.isCallable(vehicle.getMachineEnabled) and not vehicle:getMachineEnabled() then
        return nil
    end

    if not MiningLayers.isCallable(vehicle.getMachineWorkArea) then
        return nil
    end

    local workArea = vehicle:getMachineWorkArea()

    if workArea == nil or workArea.rootNode == nil then
        return nil
    end

    local worldPosX, _, worldPosZ = getWorldTranslation(workArea.rootNode)
    local entry, terrainY, surfaceY, zoneName, reason = self:getLayerAt(vehicle, worldPosX, worldPosZ)

    local lines = {
        -- Ueberschrift: die erste Zeile wird fett gezeichnet (drawHeightDisplay).
        'Mining Layers',
        string.format('%s: %s m',
            MiningLayers.getText('ml_heightHere', 'Hoehe hier'),
            MiningLayers.formatNumber(terrainY))
    }

    if entry == nil then
        -- Sagen, in welchem Modus der Bereich ist - sonst wirkt "keine Schichten"
        -- wie ein Fehler, obwohl der Spieler den Handbetrieb selbst gewaehlt hat.
        -- '!'-Praefix: das sind die Tooltips des Mods (Tommys Wunsch - Hinweise
        -- laufen in unserer Anzeige, nicht in scfmods GUI).
        if reason == 'manual' then
            table.insert(lines, '! ' .. MiningLayers.getText('ml_manualArea',
                'Material im Bereich gesetzt = normales TerraFarm, dieser Bereich hat KEINE Schichten'))
        elseif reason == 'off' then
            table.insert(lines, '! ' .. MiningLayers.getText('ml_zoneOff',
                'Schichten fuer diesen Bereich abgeschaltet'))
        elseif reason == 'spoil' then
            -- Unbekannte Halde: das Gedaechtnis kennt sie nicht (z. B. vor der
            -- Installation gebaut) - nur dann gilt die TerraFarm-Auswahl.
            table.insert(lines, '! ' .. MiningLayers.getText('ml_spoil',
                'aufgeschuettet (ueber Bezugshoehe) - TerraFarm-Auswahl gilt'))
        elseif reason == 'path' then
            table.insert(lines, '! ' .. MiningLayers.getText('ml_pathArea',
                'Pfad-Bereich = normales TerraFarm, Schichten gibt es nur in Polygon-Bereichen'))
        else
            table.insert(lines, MiningLayers.getText('ml_noLayers', 'keine Schichten an dieser Stelle'))
        end

        self:appendTip(lines)

        return lines
    end

    table.insert(lines, string.format('%s: %s   %s: %s',
        MiningLayers.getText('ml_zone', 'Zone'),
        tostring(zoneName),
        MiningLayers.getText('ml_layer', 'Schicht'),
        entry.fillTypeName))

    -- Erkannte Halde: das Gedaechtnis weiss, was hier liegt.
    if entry.isMound then
        table.insert(lines, '! ' .. MiningLayers.getText('ml_moundKnown',
            'Halde erkannt - es kommt das abgekippte Material'))
    end

    -- Weicht die TerraFarm-Auswahl (HUD rechts) von der Schicht ab, sagen wir es hier.
    -- Sonst steht rechts STONE, in die Schaufel kommt DIRT, und keiner versteht warum.
    -- Umstellen rechts ist ungefaehrlich: die Hooks laufen nach TerraFarms Konstruktor
    -- und setzen sich durch - die Auswahl ist in der Zone schlicht wirkungslos.
    if MiningLayers.isCallable(vehicle.getMachineFillTypeIndex) then
        local selectedIndex = vehicle:getMachineFillTypeIndex()

        if selectedIndex ~= nil and selectedIndex ~= entry.fillTypeIndex then
            local selected = g_fillTypeManager:getFillTypeByIndex(selectedIndex)

            if selected ~= nil and selected.name ~= nil then
                local hint = MiningLayers.getText('ml_overrideHint',
                    'TerraFarm-Material %s gilt hier nicht - die Schicht bestimmt')
                local ok, formatted = pcall(string.format, hint, selected.name)

                table.insert(lines, '! ' .. (ok and formatted or hint))
            end
        end
    end

    local line

    if surfaceY ~= nil then
        local depth = surfaceY - terrainY

        if depth < -0.05 then
            -- Ueber der Bezugshoehe. Ehrlich benennen statt auf 0 zu klemmen -
            -- sonst sucht man den Fehler in den Schichten statt in surfaceY.
            line = string.format('%s %s m %s',
                MiningLayers.getText('ml_above', 'liegt'),
                MiningLayers.formatNumber(-depth),
                MiningLayers.getText('ml_aboveRef', 'ueber der Bezugshoehe'))
        else
            line = string.format('%s: %s m',
                MiningLayers.getText('ml_depth', 'Tiefe'),
                MiningLayers.formatNumber(math.max(0, depth)))
        end
    else
        line = ''
    end

    -- Wie weit noch bis zur naechsten Schicht darunter?
    local nextEntry, boundary = self:getNextLayerBelow(vehicle, terrainY, zoneName, worldPosX, worldPosZ)

    if nextEntry ~= nil and boundary ~= nil then
        local remaining = string.format('%s %s m %s %s',
            MiningLayers.getText('ml_stillNeeded', 'noch'),
            MiningLayers.formatNumber(terrainY - boundary),
            MiningLayers.getText('ml_until', 'bis'),
            nextEntry.fillTypeName)

        line = (line ~= '') and string.format('%s   (%s)', line, remaining) or remaining
    end

    if line ~= '' then
        table.insert(lines, line)
    end

    self:appendTip(lines)

    return lines
end

---Liefert die Schicht **unterhalb** der aktuell greifenden, plus deren Grenzhöhe.
---
---⚠️ Nicht den ersten passenden Eintrag zurueckgeben - das waere die aktuelle Schicht.
---`resolved[i].boundary` ist die Hoehe, AB der Schicht i gilt; darunter kommt i+1.
---@param vehicle table
---@param terrainY number
---@param zoneName string?
---@param worldPosX number?
---@param worldPosZ number?
---@return table? nextEntry
---@return number? boundary
function MiningLayers:getNextLayerBelow(vehicle, terrainY, zoneName, worldPosX, worldPosZ)
    local resolved = nil
    local surfacePointY = nil

    if zoneName == 'globalZone' then
        resolved = self.resolvedGlobal
        surfacePointY = self.globalZone ~= nil and self.globalZone.surfaceY or nil
    else
        local area = nil

        if MiningLayers.isCallable(vehicle.getMachineInputArea) then
            local foundArea, isEnabled = vehicle:getMachineInputArea()

            if foundArea ~= nil and isEnabled then
                area = foundArea
            end
        end

        if area ~= nil then
            local surfaceY, _, plane
            resolved, surfaceY, _, plane = self:getResolvedForArea(area)
            surfacePointY = surfaceY

            -- Am Hang folgen die Grenzen der geneigten Bezugsflaeche - die Anzeige
            -- muss dieselbe Rechnung machen wie das Graben (getLayerAt).
            if plane ~= nil and worldPosX ~= nil and worldPosZ ~= nil then
                surfacePointY = MiningLayers.planeAt(plane, worldPosX, worldPosZ)
            end
        end
    end

    if type(resolved) ~= 'table' then
        return nil
    end

    for i, entry in ipairs(resolved) do
        local boundary = MiningLayers.entryBoundaryAt(entry, surfacePointY)

        -- Erster Treffer = die Schicht, in der wir gerade stehen.
        if boundary == nil or terrainY > boundary then
            local nextEntry = resolved[i + 1]

            if nextEntry ~= nil and boundary ~= nil then
                return nextEntry, boundary
            end

            -- Unterste Schicht erreicht, darunter kommt nichts mehr.
            return nil
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- Toggle-Taste (Standard Num 5, im Spiel umbelegbar)
--
-- Geschichte, damit der naechste Anlauf nicht wieder dieselben Graeber findet:
-- 1. Num * (vor 1.2.2.0): einmalige Registrierung beim Kartenstart - beim ersten
--    Kontext-Rebuild war das Event weg, Taste tot (Tommy 2026-08-08).
-- 2. 1.4.1.0: Append an TerraFarms Machine.onRegisterActionEvents - Taste tot
--    in Tommys Live-Test (keine Diagnose-Zeile, Ursache unbewiesen).
-- 3. 1.4.1.1: Append an FSBaseMission.registerActionEvents - Dredds Log 21:21
--    beweist: DIE FUNKTION EXISTIERT IN FS25 NICHT (FS22-Wissen, mein Fehler).
-- 4. Jetzt: eigene Fahrzeug-Spezialisierung (MiningLayersSpec.lua, Bootstrap in
--    main.lua) - onRegisterActionEvents kommt vom Spielkern, exakt das Muster
--    von EnhancedVehicle/AutoDrive/Courseplay. Folge: Taste wirkt IM FAHRZEUG
--    (zu Fuss gibt es keine Anzeige, also auch keine Taste noetig).
-- Jeder Schritt schreibt ins Log - ein Blick in die log.txt sagt, OB und
-- WARUM (nicht) registriert wurde.
--------------------------------------------------------------------------------

MiningLayers.toggleRegisterLogged = false
MiningLayers.toggleActionMissingLogged = false

---Callback der Toggle-Taste.
function MiningLayers:actionToggleHud()
    self.showHeightDisplay = not self.showHeightDisplay

    -- Bewusster Neuversuch: hat sich die Anzeige nach einem Fehler selbst
    -- abgeschaltet, darf die Taste sie wieder aktivieren (Fehler loggt erneut
    -- genau einmal, falls er noch besteht).
    if self.showHeightDisplay then
        MiningLayers.displayErrorReported = false
    end
end

---Registriert das Action-Event im aktuellen Input-Kontext.
---Laeuft bei jedem Rebuild erneut, deshalb vorher immer aufraeumen - sonst
---stapeln sich die Events (TerraFarm macht es in Editor.lua:624 genauso).
function MiningLayers:registerToggleActionEvent()
    if g_inputBinding == nil or not MiningLayers.active then
        return
    end

    g_inputBinding:removeActionEventsByTarget(MiningLayers)

    if InputAction == nil or InputAction.ML_TOGGLE_HUD == nil then
        -- Action fehlt = das Spiel hat <actions>/<inputBinding> aus der modDesc
        -- nicht uebernommen. Einmal klar ins Log statt still zu schweigen.
        if not MiningLayers.toggleActionMissingLogged then
            MiningLayers.toggleActionMissingLogged = true
            MiningLayers.log('WARNUNG: Action ML_TOGGLE_HUD ist im Spiel nicht angekommen - Taste ohne Funktion.')
            MiningLayers.log('  Anzeige bleibt per showHeightDisplay="false" in der miningLayers.xml schaltbar.')
        end

        return
    end

    local _, eventId = g_inputBinding:registerActionEvent(InputAction.ML_TOGGLE_HUD,
        MiningLayers, MiningLayers.actionToggleHud, false, true, false, true)

    if eventId ~= nil then
        g_inputBinding:setActionEventText(eventId,
            MiningLayers.getText('input_ML_TOGGLE_HUD', 'Mining Layers: toggle display'))

        if GS_PRIO_LOW ~= nil then
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        if not MiningLayers.toggleRegisterLogged then
            MiningLayers.toggleRegisterLogged = true
            MiningLayers.log('Anzeige-Taste registriert - Num 5 (oder deine Belegung) schaltet die Anzeige.')
        end
    elseif not MiningLayers.toggleRegisterLogged then
        MiningLayers.toggleRegisterLogged = true
        MiningLayers.log('WARNUNG: registerActionEvent lieferte kein Event - Taste vermutlich ohne Funktion.')
    end
end

---Meldet den Status der Eingabe-Spezialisierung (installiert wird sie beim
---Datei-Laden in main.lua - hier ist nur noch der Log-Report).
function MiningLayers:installToggleKey()
    if type(MiningLayers.inputSpecCount) == 'number' and MiningLayers.inputSpecCount > 0 then
        MiningLayers.log('Anzeige-Taste bereit: Eingabe-Spez auf %d Fahrzeugtypen (Standard Num 5, im Fahrzeug, umbelegbar).',
            MiningLayers.inputSpecCount)
    else
        MiningLayers.log('WARNUNG: Eingabe-Spezialisierung nicht installiert - Anzeige-Taste ohne Funktion.')
        MiningLayers.log('  Anzeige weiterhin per showHeightDisplay="false" in der miningLayers.xml schaltbar.')
    end
end

function MiningLayers:drawHeightDisplay()
    if not self.showHeightDisplay then
        return
    end

    if g_gui ~= nil and g_gui.currentGui ~= nil then
        return
    end

    local ok, lines = pcall(MiningLayers.buildDisplayLines, self)

    if not ok then
        if not MiningLayers.displayErrorReported then
            MiningLayers.displayErrorReported = true
            MiningLayers.log('FEHLER in der Anzeige: %s', tostring(lines))
            MiningLayers.log('  Anzeige wird abgeschaltet, die Schichten laufen weiter.')
            self.showHeightDisplay = false
        end

        return
    end

    if lines == nil or #lines == 0 then
        return
    end

    pcall(function()
        local size = getCorrectTextSize(0.014)

        if RenderText ~= nil and RenderText.ALIGN_LEFT ~= nil then
            setTextAlignment(RenderText.ALIGN_LEFT)
        end

        -- Balken-Hintergrund wie bei TerraFarms HUD, defensiv: fehlt eine der
        -- Engine-Funktionen, bleibt es beim reinen Text mit Schatten.
        if MiningLayers.isCallable(drawFilledRect) and MiningLayers.isCallable(getTextWidth) then
            local maxWidth = 0

            for i = 1, #lines do
                local w = getTextWidth(size, lines[i])

                if w ~= nil and w > maxWidth then
                    maxWidth = w
                end
            end

            -- renderText setzt die Grundlinie: Zeile 1 liegt bei displayPosY, jede
            -- weitere lineStep tiefer. Box von unterster Grundlinie - pad bis
            -- Oberkante der Titelzeile + pad.
            local pad = size * 0.4
            local lineStep = size * 1.25
            local bottom = self.displayPosY - (#lines - 1) * lineStep - pad
            local height = (#lines - 1) * lineStep + size + pad * 2

            drawFilledRect(self.displayPosX - pad, bottom, maxWidth + pad * 2, height, 0, 0, 0, 0.45)
        end

        local posY = self.displayPosY

        for i = 1, #lines do
            -- Erste Zeile ist die Ueberschrift: fett.
            setTextBold(i == 1)

            -- Schatten fuer Lesbarkeit auf hellem Gelaende
            setTextColor(0, 0, 0, 0.75)
            renderText(self.displayPosX + 0.0015, posY - 0.0015, size, lines[i])

            setTextColor(1, 1, 1, 1)
            renderText(self.displayPosX, posY, size, lines[i])

            posY = posY - size * 1.25
        end

        setTextBold(false)
        setTextColor(1, 1, 1, 1)
    end)
end

---Farben der Tiefenlinien je Material (RGB 0-1). DEFAULT fuer Unbekanntes.
MiningLayers.DEPTH_LINE_COLORS = {
    DIRT    = { 0.45, 0.30, 0.15 },
    SOIL    = { 0.45, 0.30, 0.15 },
    GRAVEL  = { 0.70, 0.70, 0.70 },
    PAYDIRT = { 0.95, 0.75, 0.20 },
    SAND    = { 0.90, 0.85, 0.50 },
    STONE   = { 0.50, 0.50, 0.55 },
    COAL    = { 0.10, 0.10, 0.10 },
    DEFAULT = { 1.00, 1.00, 1.00 },
}

MiningLayers.depthLinesErrorReported = false

---Zeichnet die Schichtgrenzen als farbige Linien entlang der Bereichs-Umrandung,
---dazu den Grubenboden in Rot. So sieht man IM GELAENDE, ab wo Gravel und Paydirt
---liegen, statt nur eine Zahl abzulesen (Tommys Wunsch vom Testtag).
---
---Jede Grenzlinie traegt die Farbe der Schicht, die DARUNTER beginnt - die Linie
---beantwortet "was kommt ab hier".
function MiningLayers:drawDepthLines()
    if not self.showDepthLines or not MiningLayers.isCallable(drawDebugLine) then
        return
    end

    local machineManager = MiningLayers.tf('g_machineManager')

    if type(machineManager) ~= 'table' or machineManager.activeVehicle == nil then
        return
    end

    local vehicle = machineManager.activeVehicle

    if not MiningLayers.isCallable(vehicle.getMachineInputArea) then
        return
    end

    local area, isEnabled = vehicle:getMachineInputArea()

    -- Nur fuer Polygon-Schicht-Bereiche: Pfade und Handbetrieb bleiben linienfrei.
    if area == nil or not isEnabled or area.width ~= nil or area.forceFillTypeIndex ~= nil then
        return
    end

    if area.points == nil or #area.points < 3 then
        return
    end

    local resolved, surfaceY, _, plane = self:getResolvedForArea(area)

    if type(resolved) ~= 'table' then
        return
    end

    local points = area.points
    local numPoints = #points

    -- getY bekommt den Punkt und liefert die Ringhoehe DORT: am Hang folgen die
    -- Ringe der geneigten Bezugsflaeche, statt waagerecht im Berg zu verschwinden.
    local function drawRing(getY, color)
        for i = 1, numPoints do
            local p1 = points[i]
            local p2 = points[i % numPoints + 1]

            if type(p1) == 'table' and type(p2) == 'table'
                and p1[1] ~= nil and p1[3] ~= nil and p2[1] ~= nil and p2[3] ~= nil then
                drawDebugLine(p1[1], getY(p1), p1[3], color[1], color[2], color[3],
                              p2[1], getY(p2), p2[3], color[1], color[2], color[3])
            end
        end
    end

    local function surfaceAt(p)
        if plane ~= nil then
            return MiningLayers.planeAt(plane, p[1], p[3])
        end

        return surfaceY
    end

    for i, entry in ipairs(resolved) do
        local nextEntry = resolved[i + 1]

        if nextEntry ~= nil and (entry.aboveY ~= nil or entry.depth ~= nil or entry.boundary ~= nil) then
            local color = MiningLayers.DEPTH_LINE_COLORS[nextEntry.fillTypeName]
                or MiningLayers.DEPTH_LINE_COLORS.DEFAULT

            drawRing(function(p)
                return MiningLayers.entryBoundaryAt(entry, surfaceAt(p)) or 0
            end, color)
        end
    end

    -- Grubenboden in Rot - dort stoppt das Absenken. Der Boden ist wirklich
    -- waagerecht (eine Zahl im Bereich), der Ring bleibt es deshalb auch.
    if type(area.targetY) == 'number' then
        local targetY = area.targetY

        drawRing(function() return targetY end, { 1.0, 0.2, 0.2 })
    end
end

---Wrapper mit Selbstabschaltung: ein Fehler in den Linien darf weder das Spiel
---reissen noch das Log fluten.
function MiningLayers:drawDepthLinesSafe()
    if not self.showDepthLines then
        return
    end

    local ok, err = pcall(MiningLayers.drawDepthLines, MiningLayers)

    if not ok and not MiningLayers.depthLinesErrorReported then
        MiningLayers.depthLinesErrorReported = true
        MiningLayers.log('FEHLER in den Tiefenlinien: %s', tostring(err))
        MiningLayers.log('  Tiefenlinien werden abgeschaltet, alles andere laeuft weiter.')
        self.showDepthLines = false
    end
end

---Rueckfallebene fuer den Fall, dass gar nichts gezeichnet wird.
---
---Ein Fallback ueber addDrawable haette hier nichts genutzt: kommt draw() vom
---ModEventListener nicht an, kommt auch keine Erkennung dafuer an. Deshalb haengt
---die Rueckfallebene am Hook - einem voellig anderen Codepfad. Beim ersten
---Grabvorgang wird einmal geschrieben, was der Mod an dieser Stelle ermittelt hat.
---Damit ist die Hoehenermittlung auch dann pruefbar, wenn die Anzeige klemmt.
---@param entry table?
---@param terrainY number
---@param surfaceY number?
---@param zoneName string?
function MiningLayers:logFirstReading(entry, terrainY, surfaceY, zoneName)
    if MiningLayers.firstReadingLogged then
        return
    end

    MiningLayers.firstReadingLogged = true

    if entry == nil then
        MiningLayers.log('Erster Grabvorgang: Hoehe %.1f m, keine Schicht zustaendig (Material unveraendert).', terrainY)
        return
    end

    if surfaceY ~= nil then
        MiningLayers.log('Erster Grabvorgang: Hoehe %.1f m, Tiefe %.1f m, Zone %s -> %s',
            terrainY, surfaceY - terrainY, tostring(zoneName), entry.fillTypeName)
    else
        MiningLayers.log('Erster Grabvorgang: Hoehe %.1f m, Zone %s -> %s',
            terrainY, tostring(zoneName), entry.fillTypeName)
    end
end
