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
    -- Wichtigster Tipp fuer neue Spieler (1.4.3): Materialien haengen an Karte
    -- + Modliste, nicht am Mod. Steht auch ganz vorn im Schnellstart.
    { key = 'ml_tip7', fallback = 'Welche Materialien es gibt, entscheidet deine Karte samt Modliste - (!) heisst: graben ja, abkippen nein' },
}

---Sekunden pro Tipp im News-Band. Bewusst EINE Konstante und leicht zu finden:
---Tommy kalibriert das Tempo im Test (12 war zu hektisch, M8 aus dem 1.4.2-Paket).
MiningLayers.TIP_SECONDS = 20

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
    -- "Num /", obwohl der Spieler laengst umbelegt hat.
end

---Sammelt die Zeilen fuer die Anzeige.
---@return string[]? lines
function MiningLayers:buildDisplayLines()
    -- T13: pro Zeile eine optionale Materialfarbe (Index = Zeilen-Index). Bei
    -- jedem Aufruf zuruecksetzen, damit kein Stand vom Vorframe haengen bleibt.
    self.displayLineColors = {}

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
        elseif reason == 'noSurface' then
            -- ⚠️ Muss VOR dem else stehen: sonst landet der Fall in der
            -- Eingabe-Bereich-Diagnose und die Anzeige raet dem Spieler, einen
            -- Bereich zuzuweisen - obwohl er gerade ohne Bereich unterwegs ist
            -- und nur noch keine Schaufel im Boden hatte.
            --
            -- Erst die Zone, dann der Hinweis (Tommys Befund 16.08. am eigenen
            -- Screenshot): ohne die Zone-Zeile sieht der Spieler beim Herumfahren nur
            -- eine Meldung und nicht, DASS hier ueberhaupt Schichten gelten. Mit ihr
            -- liest es sich als "gleich geht's los" statt "hier ist nichts eingestellt".
            -- Bewusst dieselbe Beschriftung wie unten im Normalfall.
            local zoneLabel

            if zoneName == nil or zoneName == 'globalZone' then
                zoneLabel = MiningLayers.getText('ml_zoneEverywhere', 'Ueberall')
            else
                zoneLabel = tostring(zoneName)
            end

            table.insert(lines, string.format('%s: %s',
                MiningLayers.getText('ml_zone', 'Zone'), zoneLabel))

            table.insert(lines, '! ' .. MiningLayers.getText('ml_noSurfaceYet',
                'Bezugshoehe noch nicht gesetzt - sie entsteht beim ersten Grabkontakt hier'))
        else
            -- raver-Supportfall 10.08.: haeufigste Ursache fuer "keine Schichten"
            -- ist eine Maschine OHNE zugewiesenen Eingabe-Bereich - das sagen wir
            -- woertlich, samt Weg dahin (Maschinen-Menue, Standard Y).
            local hasInputArea = false

            if MiningLayers.isCallable(vehicle.getMachineInputArea) then
                local foundArea, isEnabled = vehicle:getMachineInputArea()

                -- truthy wie an den anderen getMachineInputArea-Stellen
                if foundArea ~= nil and isEnabled then
                    hasInputArea = true
                end
            end

            if not hasInputArea then
                table.insert(lines, '! ' .. MiningLayers.getText('ml_noInputArea',
                    'kein Eingabe-Bereich gewaehlt - Maschinen-Menue (Y): Bereich als Eingabe zuweisen'))
            else
                table.insert(lines, MiningLayers.getText('ml_noLayers', 'keine Schichten an dieser Stelle'))
            end
        end

        -- Was STATTDESSEN passiert. Ohne diesen Satz sucht der Spieler den Fehler bei
        -- uns ("der Mod uebernimmt nicht") - dann entscheidet TerraFarm. Normalfall ist das
        -- Material der MASCHINE (LandscapingBase.lua:69). Nur wenn die Karte Ressourcen
        -- mitbringt und beide Schalter an sind - global und an der Maschine
        -- (LandscapingBase.lua:72) - greift applyMapResources und nimmt das Material, das
        -- der KARTENERSTELLER der Bodentextur zugeordnet hat (LandscapingInput.lua:75,
        -- getResourceLayerAtWorldPos kennt nur X und Z, also in JEDER Tiefe dasselbe -
        -- der Befund vom 11.08., Tommy: Beton aus jeder Tiefe / Oreo: Kokskohle nach Erde).
        -- Ausnahme 'manual': dort gilt das ausdruecklich im Bereich gesetzte Material.
        --
        -- ⚠️ Ausnahme 'noSurface' (Tommys Befund 16.08., Nachtest): dort ist der Satz
        -- schlicht falsch. applyLayer friert die Bezugshoehe VOR der Abfrage ein
        -- (LayerHooks.lua:272, dann :275) - wer hier graebt, bekommt im selben Moment
        -- seine Schicht. Der Satz beschriebe einen Fall, der beim Graben nie eintritt,
        -- und liest sich wie "der Mod ist hier nicht zustaendig" - genau die Sorge, die
        -- der globale Modus ausraeumen soll. Es bleibt die Zeile darueber, die richtig
        -- sagt, dass die Hoehe beim ersten Grabkontakt entsteht.
        if reason ~= 'manual' and reason ~= 'noSurface' then
            table.insert(lines, '! ' .. MiningLayers.getText('ml_mapResourceTakesOver',
                'TerraFarm entscheidet: Material deiner Maschine - oder das der Karte, wenn Kartenressourcen eingeschaltet sind'))
        end

        self:appendTip(lines)

        return lines
    end

    -- ⚠️ 'globalZone' ist unser XML-Begriff, kein Wort fuer den Spieler - und in keiner
    -- Sprachdatei uebersetzbar, weil er aus dem Code kommt (MiningLayersConfig:2007).
    -- Gefunden im Sprachdurchgang 16.08. (Tommy, franzoesische Sitzung).
    --
    -- Angezeigt wird stattdessen dasselbe Wort, das im Editor als Ziel steht: "Ueberall".
    -- Tommys Entscheid - gar nichts anzuzeigen waere die stillere Loesung gewesen, aber dann
    -- sieht der Spieler nicht, DASS der globale Modus greift. Genau diese Rueckmeldung fehlt
    -- bei "warum passiert nichts?". Menue und HUD benutzen jetzt dasselbe Wort.
    if zoneName == nil or zoneName == 'globalZone' then
        table.insert(lines, string.format('%s: %s   %s: %s',
            MiningLayers.getText('ml_zone', 'Zone'),
            MiningLayers.getText('ml_zoneEverywhere', 'Ueberall'),
            MiningLayers.getText('ml_layer', 'Schicht'),
            entry.fillTypeName))
    else
        table.insert(lines, string.format('%s: %s   %s: %s',
            MiningLayers.getText('ml_zone', 'Zone'),
            tostring(zoneName),
            MiningLayers.getText('ml_layer', 'Schicht'),
            entry.fillTypeName))
    end

    -- T13: die aktuelle Schicht-Zeile in ihrer Materialfarbe faerben.
    self.displayLineColors[#lines] = MiningLayers.hudMaterialColor(entry.fillTypeName)

    -- T14: Abraum-Modus sichtbar machen. Sonst steht hier GRAVEL, in die Schaufel
    -- kommt DIRT, und der Modus wirkt wie ein Fehler. Halden sind ausgenommen
    -- (isMound), dort gilt weiter das Gedaechtnis - das sagt die Halden-Zeile unten.
    if self.spoilMode then
        local spoilEntry = self:getSpoilModeEntry()

        if spoilEntry ~= nil then
            local template = MiningLayers.getText('ml_spoilModeOn',
                'Abraum-Modus AN - Abraum wird als %s gegraben, nur die unterste Schicht bleibt echt')
            local ok, text = pcall(string.format, template, spoilEntry.fillTypeName)

            table.insert(lines, '! ' .. (ok and text or template))
        end
    end

    -- 1.6.2: Grade-Sperre sichtbar machen - sonst stoppt der Loeffel scheinbar
    -- grundlos an der Grenze und der Modus wirkt wie ein Grab-Bug.
    if self.holdGrade then
        table.insert(lines, '! ' .. MiningLayers.getText('ml_holdGradeOn',
            'Grade-Sperre AN - der Grabzug stoppt an der Schichtgrenze'))
    end

    -- 1.6.2 Aktivierung: Key-Status sichtbar machen. Im 'report'-Testbuild ist
    -- diese Zeile das Messergebnis; im 'enforce'-Build kommt man ohne Key gar
    -- nicht bis hierher (Mod inaktiv). Der Text kommt aus dem Lizenzmodul
    -- (DE/EN), nicht aus l10n - eine Quelle fuer alle FSMW-Mods.
    if MiningLayersGate ~= nil and MiningLayersGate.result ~= nil
        and not MiningLayersGate.isLicensed() then
        table.insert(lines, '! ' .. MiningLayersGate.getMessage())
    end

    -- ★ Zielhoehe des Bereichs - die Auskunft, die bis 1.6.0 nur im Log stand.
    --
    -- Ohne sie merkt niemand, dass ein frisch gezeichneter Bereich seine Zielhoehe vom
    -- Editor auf Gelaendehoehe bekommt (PolygonEditor:createPoint) und die Grube damit
    -- sofort wieder aufhoert. Wer vorher ohne Bereich gegraben hat - dort gibt es gar
    -- keine Untergrenze -, sieht sonst nur, dass es "ploetzlich nicht mehr geht".
    -- Tommy, 18.08., am eigenen Testbereich.
    local status = zoneName ~= nil and MiningLayers.targetStatusByZone ~= nil
        and MiningLayers.targetStatusByZone[tostring(zoneName)] or nil

    if status ~= nil and status.y ~= nil then
        local origin = status.manual
            and MiningLayers.getText('ml_targetManual', 'von dir')
            or MiningLayers.getText('ml_targetAuto', 'automatisch')

        table.insert(lines, string.format('%s: %s m (%s)',
            MiningLayers.getText('ml_targetHeight', 'Zielhoehe'),
            MiningLayers.formatNumber(status.y),
            origin))

        -- Nur wenn die Hoehe wirklich etwas abschneidet. Sonst waere die Zeile Rauschen.
        if status.cut and status.deepest ~= nil then
            local template = MiningLayers.getText('ml_targetCut',
                'Grube endet ueber der tiefsten Schicht (%s m) - Zielhoehe im Bereichseditor tiefer setzen')
            local ok, text = pcall(string.format, template, MiningLayers.formatNumber(status.deepest))

            table.insert(lines, '! ' .. (ok and text or template))
        end
    end

    -- ★ Abgelehnter Gelaendeeingriff in den letzten 3 Sekunden: DAS ist die Antwort
    -- auf "warum passiert nichts?", wenn die Karte eine Zone sperrt. TerraFarm
    -- verschluckt den Fehlzustand stumm (Befund 18.08., alter Riverspot); die
    -- Diagnose-Hook in LayerHooks merkt sich den Zeitpunkt.
    if MiningLayers.deformBlockedAt ~= nil and type(g_time) == 'number'
        and g_time - MiningLayers.deformBlockedAt < 3000 then
        table.insert(lines, '! ' .. MiningLayers.getText('ml_digBlocked',
            'Karte blockiert Gelaendeaenderung an dieser Stelle - kein Mod-Stopp'))
    elseif MiningLayers.deformZeroAt ~= nil and type(g_time) == 'number'
        and g_time - MiningLayers.deformZeroAt < 3000 then
        -- Engine meldet Erfolg, bewegt aber nichts (Serie): Kartensperre nach
        -- TerraFarm-Bauart (max. Verschiebung 0) oder Boden schon auf Zielhoehe.
        table.insert(lines, '! ' .. MiningLayers.getText('ml_digNoEffect',
            'Graben bewegt hier nichts - Kartensperre oder Zielhoehe erreicht'))
    end

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

        -- T13 + Grenzwarnung: die "noch X m bis GRAVEL"-Zeile traegt die Farbe
        -- der naechsten Schicht (Wiedererkennung) und faerbt sich mit sinkendem
        -- Abstand zur Warnfarbe - der Wechsel springt ins Auge, BEVOR die Schaufel
        -- im neuen Material steckt.
        if nextEntry ~= nil then
            local remaining = (boundary ~= nil) and (terrainY - boundary) or nil
            self.displayLineColors[#lines] = MiningLayers.hudBoundaryColor(nextEntry.fillTypeName, remaining)
        end
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

        -- ⚠️ Dieselbe Falle wie beim Bereichs-Zweig unten, nur eine Version spaeter:
        -- hier stand `= self.globalZone.surfaceY`, also der feste Wert aus der XML.
        -- Seit die globale Zone ohne festen Wert laufen darf, ist der im Normalfall
        -- nil - die Anzeige haette geschwiegen, waehrend das Graben laeuft. Also
        -- derselbe Weg wie in getLayerAt: erst das Raster, dann der feste Wert.
        -- Keine geneigte Ebene, weil es ohne Bereich keine Umrandung zum Fitten gibt.
        local globalSurfaceY = self.globalZone ~= nil and self.globalZone.surfaceY or nil

        if worldPosX ~= nil and worldPosZ ~= nil then
            surfacePointY = self:getSurfacePointY(worldPosX, worldPosZ, nil, globalSurfaceY)
        else
            surfacePointY = globalSurfaceY
        end
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

            -- Die Anzeige MUSS dieselbe Rechnung machen wie das Graben. Seit dem
            -- Bezugshoehen-Raster heisst das: erst das Raster, dann die geneigte
            -- Ebene, dann der Median - also derselbe Weg wie in getLayerAt.
            -- ⚠️ Diese Stelle stand nicht in der Task-4-Liste und rechnete
            -- weiter auf der Ebene: die Schicht kam aus dem Raster, die Tiefe
            -- und "noch X m bis" aus der Ebene. Gemessen bei Tommys Terrassen-
            -- test 13.08. - 2,0 m oben gegen 1,2 m unten, obwohl beide dieselbe
            -- defaultZone benutzen.
            if worldPosX ~= nil and worldPosZ ~= nil then
                surfacePointY = self:getSurfacePointY(worldPosX, worldPosZ, plane, surfaceY)
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
-- Toggle-Taste (Standard Num /, im Spiel umbelegbar)
--
-- Geschichte, damit der naechste Anlauf nicht wieder dieselben Graeber findet:
-- 1. Num * (vor 1.2.2.0): einmalige Registrierung beim Kartenstart - beim ersten
--    Kontext-Rebuild war das Event weg, Taste tot (Tommy 2026-08-08).
-- 2. 1.4.1.0: Append an TerraFarms Machine.onRegisterActionEvents - Taste tot
--    in Tommys Live-Test (keine Diagnose-Zeile, Ursache unbewiesen).
-- 3. 1.4.1.1: Append an FSBaseMission.registerActionEvents - Dredds Log 21:21
--    beweist: DIE FUNKTION EXISTIERT IN FS25 NICHT (FS22-Wissen, mein Fehler).
-- 4. 1.4.1.2: eigene Fahrzeug-Spezialisierung (Bootstrap in main.lua) - Spec
--    lief, eventId kam zurueck, Taste TROTZDEM tot, F1-Eintrag fehlte (Dredd
--    ~21:45). Abweichungen zum EV-Vorbild: eigenes removeActionEventsByTarget
--    im Rebuild-Fenster (loescht mutmasslich das frische Event), Target war
--    der Mod statt des Fahrzeugs, Guard ohne getIsControlled.
-- 5. 1.4.1.3/1.4.1.4: Registrierung 1:1 wie FS25_EnhancedVehicle - lief auf
--    Tommys 334er-Modliste TROTZDEM leer: success=true, korrekter Kontext,
--    nie ein Callback. Die Binding-Aufloesung des Spiels liefert dort schlicht
--    nicht (Ursache offen, Verdacht: actionEventId-Recycling im Rebuild).
-- 6. Seit 1.4.1.5/6: Registrierung ueber die FAHRZEUG-API
--    (vehicle:addActionEvent, TerraFarm-Muster Machine.lua:1561-1571) PLUS
--    Direkt-Fallback in main.lua (pollt die Taste selbst, wenn kein
--    Action-Callback stempelt). 1.4.2 dazu: dritter Registrierungspfad global
--    via PlayerInputComponent.registerGlobalPlayerActionEvents (HL-Muster,
--    HudMover.lua) - der Hook laeuft bei JEDEM Kontextwechsel, die
--    Registrierung ist damit nie stale. Welcher Pfad Callbacks liefert,
--    schreibt onToggleActionInput einmal je Pfad ins Log.
-- Jeder Schritt schreibt ins Log - ein Blick in die log.txt sagt, OB und
-- WARUM (nicht) registriert wurde; jede Registrierung wird mitgezaehlt.
--------------------------------------------------------------------------------

MiningLayers.toggleRegisterCount = 0
MiningLayers.toggleLogCount = 0
MiningLayers.toggleActionMissingLogged = false
MiningLayers.toggleVehicleApiMissingLogged = false
MiningLayers.toggleSourceLogged = {}
MiningLayers.toggleDupLogged = false

-- T14 Spoil-Toggle: eigene Pfad-Forschung + Dedupe-Stempel.
MiningLayers.spoilSourceLogged = {}
MiningLayers.lastActionSpoilTime = nil

-- 1.6.2 Grade-Sperre: gleiche Struktur.
MiningLayers.holdGradeSourceLogged = {}
MiningLayers.lastActionHoldGradeTime = nil

---Maximal so viele Registrierungs-Zeilen ins Log (Diagnose ja, Flut nein).
MiningLayers.TOGGLE_LOG_LIMIT = 25

---Schaltet die Anzeige um. Kern-Funktion OHNE Zeitstempel: den setzen nur die
---Action-Callbacks (onToggleActionInput). Der Direkt-Fallback ruft hier direkt
---an und darf sich nicht selbst als "vom Action-System behandelt" stempeln -
---sonst verschluckt er den zweiten Tipp eines Doppel-Tipps (Review-Punkt A2).
function MiningLayers.actionToggleHud()
    MiningLayers.showHeightDisplay = not MiningLayers.showHeightDisplay

    -- Cap wie beim Registrierungs-Log: Diagnose ja, Flut nein (Review-Punkt C9).
    MiningLayers.toggleLogCount = MiningLayers.toggleLogCount + 1

    if MiningLayers.toggleLogCount <= MiningLayers.TOGGLE_LOG_LIMIT then
        MiningLayers.log('Display key pressed - display is now %s.',
            MiningLayers.showHeightDisplay and 'ON' or 'OFF')

        if MiningLayers.toggleLogCount == MiningLayers.TOGGLE_LOG_LIMIT then
            MiningLayers.log('  (further toggle lines are suppressed)')
        end
    end

    -- Bewusster Neuversuch: hat sich die Anzeige nach einem Fehler selbst
    -- abgeschaltet, darf die Taste sie wieder aktivieren (Fehler loggt erneut
    -- genau einmal, falls er noch besteht).
    if MiningLayers.showHeightDisplay then
        MiningLayers.displayErrorReported = false
    end
end

---Gemeinsamer Action-Callback beider Registrierungspfade. Stempelt
---lastActionToggleTime fuer den Handshake mit dem Direkt-Fallback (main.lua)
---und dedupliziert Doppel-Callbacks: melden Fahrzeug-Spez UND globaler Pfad
---denselben Tastendruck, ist der zweite Callback binnen 50 ms ein Duplikat,
---kein neuer Druck (ein Mensch tippt nicht schneller).
---@param sourceName string 'Fahrzeug-Spez' oder 'global'
function MiningLayers.onToggleActionInput(sourceName)
    local now = g_time or 0

    if MiningLayers.lastActionToggleTime ~= nil
        and (now - MiningLayers.lastActionToggleTime) < 50 then
        -- Diagnose fuer die Pfad-3-Forschung: einmal festhalten, dass die
        -- Deduplizierung real exerziert wird (Percys Review, Testfrage 1).
        if not MiningLayers.toggleDupLogged then
            MiningLayers.toggleDupLogged = true
            MiningLayers.log('Display key: duplicate callback via path "%s" (%d ms after the first) - deduplicated.',
                sourceName, now - MiningLayers.lastActionToggleTime)
        end

        MiningLayers.lastActionToggleTime = now
        return
    end

    MiningLayers.lastActionToggleTime = now

    -- Forschung Binding-Aufloesung (Percys Recycling-Hypothese): einmal je
    -- Pfad festhalten, WELCHER Weg auf dieser Modliste Callbacks liefert.
    if not MiningLayers.toggleSourceLogged[sourceName] then
        MiningLayers.toggleSourceLogged[sourceName] = true
        MiningLayers.log('Display key: callback through path "%s".', sourceName)
    end

    MiningLayers.actionToggleHud()
end

---Callback der Fahrzeug-Spez-Registrierung. ⚠️ Target ist das FAHRZEUG,
---also KEIN self benutzen - self waere das Fahrzeug, nicht der Mod.
function MiningLayers.actionToggleHudVehicle()
    MiningLayers.onToggleActionInput('Fahrzeug-Spez')
end

---Callback der globalen Registrierung (HudMover.lua).
function MiningLayers.actionToggleHudGlobal()
    MiningLayers.onToggleActionInput('global')
end

---T14: Abraum-Modus umschalten - gemeinsamer Kern beider Action-Pfade und des
---Direkt-Fallbacks. Schaltet, sagt es im Log und schreibt die Config sofort:
---der Schalter soll den Neustart auch dann ueberleben, wenn danach nie das
---Menue gespeichert wird.
function MiningLayers.actionToggleSpoilMode()
    MiningLayers.spoilMode = not MiningLayers.spoilMode

    local spoilEntry = MiningLayers.spoilMode and MiningLayers:getSpoilModeEntry() or nil

    -- Seltene, bewusste Aktion - kein Flut-Risiko, deshalb ohne Log-Cap.
    MiningLayers.log('Spoil mode: %s%s.',
        MiningLayers.spoilMode and 'ON' or 'OFF',
        spoilEntry ~= nil and (' - overburden digs as ' .. tostring(spoilEntry.fillTypeName)) or '')

    -- Das Einmal-Log im Grabpfad darf nach jedem Umschalten wieder sprechen.
    MiningLayers.spoilModeLogged = false

    pcall(MiningLayers.saveConfigFile, MiningLayers)
end

---Dedupe wie onToggleActionInput: Fahrzeug-Spez UND globaler Pfad koennen
---denselben Druck melden; der zweite Callback binnen 50 ms ist ein Duplikat.
---Stempelt lastActionSpoilTime fuer den Handshake mit dem Direkt-Fallback.
---@param sourceName string 'Fahrzeug-Spez' oder 'global'
function MiningLayers.onSpoilActionInput(sourceName)
    local now = g_time or 0

    if MiningLayers.lastActionSpoilTime ~= nil
        and (now - MiningLayers.lastActionSpoilTime) < 50 then
        MiningLayers.lastActionSpoilTime = now
        return
    end

    MiningLayers.lastActionSpoilTime = now

    if not MiningLayers.spoilSourceLogged[sourceName] then
        MiningLayers.spoilSourceLogged[sourceName] = true
        MiningLayers.log('Spoil key: callback through path "%s".', sourceName)
    end

    MiningLayers.actionToggleSpoilMode()
end

---Fahrzeug-Spez-Callback (Target ist das Fahrzeug, kein self).
function MiningLayers.actionSpoilVehicle()
    MiningLayers.onSpoilActionInput('Fahrzeug-Spez')
end

---Globaler Callback (HudMover.lua).
function MiningLayers.actionSpoilGlobal()
    MiningLayers.onSpoilActionInput('global')
end

---1.6.2: Grade-Sperre umschalten - gemeinsamer Kern beider Action-Pfade und des
---Direkt-Fallbacks, gleicher Vertrag wie actionToggleSpoilMode (Log + Config
---sofort schreiben, damit der Schalter den Neustart ueberlebt).
function MiningLayers.actionToggleHoldGrade()
    MiningLayers.holdGrade = not MiningLayers.holdGrade

    -- Seltene, bewusste Aktion - kein Flut-Risiko, deshalb ohne Log-Cap.
    MiningLayers.log('Grade lock: %s%s.',
        MiningLayers.holdGrade and 'ON' or 'OFF',
        MiningLayers.holdGrade and ' - the dig stops at the layer boundary' or '')

    -- Das Einmal-Log im Grabpfad darf nach jedem Umschalten wieder sprechen.
    MiningLayers.holdGradeLogged = false

    pcall(MiningLayers.saveConfigFile, MiningLayers)
end

---Dedupe wie onSpoilActionInput: der zweite Callback binnen 50 ms ist ein Duplikat.
---@param sourceName string 'Fahrzeug-Spez' oder 'global'
function MiningLayers.onHoldGradeActionInput(sourceName)
    local now = g_time or 0

    if MiningLayers.lastActionHoldGradeTime ~= nil
        and (now - MiningLayers.lastActionHoldGradeTime) < 50 then
        MiningLayers.lastActionHoldGradeTime = now
        return
    end

    MiningLayers.lastActionHoldGradeTime = now

    if not MiningLayers.holdGradeSourceLogged[sourceName] then
        MiningLayers.holdGradeSourceLogged[sourceName] = true
        MiningLayers.log('Grade-lock key: callback through path "%s".', sourceName)
    end

    MiningLayers.actionToggleHoldGrade()
end

---Fahrzeug-Spez-Callback (Target ist das Fahrzeug, kein self).
function MiningLayers.actionHoldGradeVehicle()
    MiningLayers.onHoldGradeActionInput('Fahrzeug-Spez')
end

---Globaler Callback (HudMover.lua).
function MiningLayers.actionHoldGradeGlobal()
    MiningLayers.onHoldGradeActionInput('global')
end

---Registriert das Action-Event ueber die FAHRZEUG-API (TerraFarm-Muster,
---Machine.lua:1561-1571). Wird von der Spezialisierung (MiningLayersSpec) bei
---jedem Input-Kontext-Rebuild aufgerufen: clearActionEventsTable leert die
---fahrzeug-eigene Event-Tabelle des Vorlaufs, danach wird - nur wenn das
---Fahrzeug aktiv fuer Eingaben ist - frisch registriert, mit dem FAHRZEUG als
---Target. Zusaetzlich laeuft eine GLOBALE Registrierung derselben Action ueber
---PlayerInputComponent (HudMover.lua) und als letzte Absicherung der
---Direkt-Fallback in main.lua.
---@param vehicle table Fahrzeug, dient als Event-Target
---@param isActiveForInput boolean Param 1 ODER Param 2 des Ereignisses (siehe MiningLayersSpec)
function MiningLayers:registerToggleActionEvent(vehicle, isActiveForInput)
    if g_inputBinding == nil or not MiningLayers.active or vehicle == nil then
        return
    end

    if InputAction == nil or InputAction.ML_TOGGLE_HUD == nil then
        -- Action fehlt = das Spiel hat <actions>/<inputBinding> aus der modDesc
        -- nicht uebernommen. Einmal klar ins Log statt still zu schweigen.
        if not MiningLayers.toggleActionMissingLogged then
            MiningLayers.toggleActionMissingLogged = true
            MiningLayers.log('WARNING: action ML_TOGGLE_HUD never arrived in the game - the key does nothing.')
            MiningLayers.log('  The display can still be switched with showHeightDisplay="false" in miningLayers.xml.')
        end

        return
    end

    -- 1.4.1.5: Registrierung ueber die FAHRZEUG-API (TerraFarm Machine.lua:1561-1571,
    -- lokal bewiesen funktionierend) statt direkt ueber g_inputBinding. Der direkte
    -- Weg lieferte success=true im richtigen Kontext, aber das Fahrzeug-Input-System
    -- hat das Event nie aktiviert - Taste tot bei JEDER Belegung (Diagnose 1.4.1.4).
    -- Eigenes Flag (nicht toggleActionMissingLogged): sonst unterdrueckt die
    -- zuerst feuernde Warnung die jeweils andere (Review-Punkt C8).
    if not MiningLayers.isCallable(vehicle.addActionEvent)
        or not MiningLayers.isCallable(vehicle.clearActionEventsTable) then
        if not MiningLayers.toggleVehicleApiMissingLogged then
            MiningLayers.toggleVehicleApiMissingLogged = true
            MiningLayers.log('WARNING: vehicle without addActionEvent/clearActionEventsTable - the display key stays off.')
        end

        return
    end

    vehicle.miningLayersActionEvents = vehicle.miningLayersActionEvents or {}
    vehicle:clearActionEventsTable(vehicle.miningLayersActionEvents)

    -- Guard nach TerraFarm-Vorbild, seit 1.4.2 mit Param 2 kombiniert (siehe
    -- MiningLayersSpec): registriert wird, solange das Fahrzeug aktiv fuer
    -- Eingaben ist - auch wenn gerade ein Anbaugeraet selektiert ist.
    if not isActiveForInput then
        return
    end

    local success, eventId = vehicle:addActionEvent(vehicle.miningLayersActionEvents,
        InputAction.ML_TOGGLE_HUD, vehicle, MiningLayers.actionToggleHudVehicle, false, true, false, true)

    -- Dredds Anforderung fuer 1.4.1.3: JEDE Registrierung protokollieren
    -- (Zaehler + success + eventId), damit das Log den Rebuild-Takt zeigt.
    MiningLayers.toggleRegisterCount = MiningLayers.toggleRegisterCount + 1

    if MiningLayers.toggleRegisterCount <= MiningLayers.TOGGLE_LOG_LIMIT then
        -- Diagnose (Dredd): Kontextname zeigt, WO das Event gelandet ist.
        local contextName = 'unknown'

        if MiningLayers.isCallable(g_inputBinding.getContextName) then
            local okCtx, ctx = pcall(g_inputBinding.getContextName, g_inputBinding)

            if okCtx and ctx ~= nil then
                contextName = tostring(ctx)
            end
        end

        MiningLayers.log('Display key: registration #%d, success=%s, eventId=%s, context=%s',
            MiningLayers.toggleRegisterCount, tostring(success), tostring(eventId), contextName)

        if MiningLayers.toggleRegisterCount == MiningLayers.TOGGLE_LOG_LIMIT then
            MiningLayers.log('  (further registration lines are suppressed)')
        end
    end

    if eventId ~= nil then
        g_inputBinding:setActionEventText(eventId,
            MiningLayers.getText('input_ML_TOGGLE_HUD', 'Mining Layers: toggle display'))

        if GS_PRIO_LOW ~= nil then
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        end

        g_inputBinding:setActionEventTextVisibility(eventId, true)
    end

    -- T14 Spoil-Taste: gleiche Fahrzeug-Registrierung, gleicher Rebuild-Takt.
    -- Kein eigener Registrierungs-Zaehler - die Diagnose oben zeigt den Takt
    -- bereits, eine zweite Zaehlspur waere Log-Rauschen.
    if InputAction.ML_SPOIL_MODE ~= nil then
        local _, spoilEventId = vehicle:addActionEvent(vehicle.miningLayersActionEvents,
            InputAction.ML_SPOIL_MODE, vehicle, MiningLayers.actionSpoilVehicle, false, true, false, true)

        if spoilEventId ~= nil then
            g_inputBinding:setActionEventText(spoilEventId,
                MiningLayers.getText('input_ML_SPOIL_MODE', 'Mining Layers: spoil mode on/off'))

            if GS_PRIO_LOW ~= nil then
                g_inputBinding:setActionEventTextPriority(spoilEventId, GS_PRIO_LOW)
            end

            g_inputBinding:setActionEventTextVisibility(spoilEventId, true)
        end
    end

    -- 1.6.2 Grade-Sperre: gleiche Fahrzeug-Registrierung, gleicher Rebuild-Takt.
    if InputAction.ML_HOLD_GRADE ~= nil then
        local _, holdGradeEventId = vehicle:addActionEvent(vehicle.miningLayersActionEvents,
            InputAction.ML_HOLD_GRADE, vehicle, MiningLayers.actionHoldGradeVehicle, false, true, false, true)

        if holdGradeEventId ~= nil then
            g_inputBinding:setActionEventText(holdGradeEventId,
                MiningLayers.getText('input_ML_HOLD_GRADE', 'Mining Layers: grade lock on/off'))

            if GS_PRIO_LOW ~= nil then
                g_inputBinding:setActionEventTextPriority(holdGradeEventId, GS_PRIO_LOW)
            end

            g_inputBinding:setActionEventTextVisibility(holdGradeEventId, true)
        end
    end
end

---Meldet den Status der Eingabe-Spezialisierung (installiert wird sie beim
---Datei-Laden in main.lua - hier ist nur noch der Log-Report).
function MiningLayers:installToggleKey()
    if type(MiningLayers.inputSpecCount) == 'number' and MiningLayers.inputSpecCount > 0 then
        MiningLayers.log('Display key ready: input specialization on %d vehicle types (default Num /, inside a vehicle, rebindable).',
            MiningLayers.inputSpecCount)
    else
        MiningLayers.log('WARNING: input specialization not installed - the display key does nothing.')
        MiningLayers.log('  The display remains switchable with showHeightDisplay="false" in miningLayers.xml.')
    end
end

function MiningLayers:drawHeightDisplay()
    -- Im Verschiebe-Modus (HudMover.lua) wird IMMER gezeichnet - auch bei
    -- abgeschalteter Anzeige oder ohne aktive Maschine, sonst gaebe es nichts
    -- zu greifen.
    local moveMode = MiningLayers.hudMoveMode == true

    if not self.showHeightDisplay and not moveMode then
        return
    end

    if g_gui ~= nil and g_gui.currentGui ~= nil then
        return
    end

    local ok, lines = pcall(MiningLayers.buildDisplayLines, self)

    if not ok then
        if not MiningLayers.displayErrorReported then
            MiningLayers.displayErrorReported = true
            MiningLayers.log('ERROR in the display: %s', tostring(lines))
            MiningLayers.log('  The display is switched off, the layers keep running.')
            self.showHeightDisplay = false
        end

        return
    end

    if lines == nil or #lines == 0 then
        if not moveMode then
            return
        end

        -- Platzhalter, damit die Box beim Verschieben sichtbar und greifbar ist.
        lines = {
            'Mining Layers',
            MiningLayers.getText('ml_hudMoveSample', 'Beispielanzeige - im Spiel stehen hier die Schicht-Infos'),
        }
    end

    if moveMode then
        table.insert(lines, '')
        table.insert(lines, '» ' .. MiningLayers.getText('ml_hudMoveHint',
            'Linksklick: greifen/ablegen - Rechtsklick: Standardposition - Taste erneut: fertig'))
    end

    pcall(function()
        local size = getCorrectTextSize(0.014)

        if RenderText ~= nil and RenderText.ALIGN_LEFT ~= nil then
            setTextAlignment(RenderText.ALIGN_LEFT)
        end

        local canMeasure = MiningLayers.isCallable(drawFilledRect) and MiningLayers.isCallable(getTextWidth)

        -- M7: Der Kasten waechst NICHT mehr mit dem laengsten Tipp mit -
        -- Referenzbreite ist das F1-Hilfe-Menue, lange Zeilen werden umbrochen.
        local pad = size * 0.6
        local maxTextWidth = nil

        -- T13: Materialfarben je Zeile (aus buildDisplayLines). Beim Umbruch
        -- muss die Farbe mitwandern, sonst faerbt sie nach dem Wrap die falsche Zeile.
        local lineColors = self.displayLineColors

        if canMeasure then
            maxTextWidth = MiningLayers.getHudMaxWidth() - pad * 2
            lines, lineColors = MiningLayers.wrapLines(lines, size, maxTextWidth, self.displayLineColors)
        end

        -- Balken-Hintergrund wie bei TerraFarms HUD, defensiv: fehlt eine der
        -- Engine-Funktionen, bleibt es beim reinen Text mit Schatten.
        if canMeasure then
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
            local lineStep = size * 1.25
            local bottom = self.displayPosY - (#lines - 1) * lineStep - pad
            local height = (#lines - 1) * lineStep + size + pad * 2
            local left = self.displayPosX - pad
            local width = maxWidth + pad * 2
            local top = bottom + height

            drawFilledRect(left, bottom, width, height, 0, 0, 0, 0.45)

            -- M6: klare Titelzeile - eigenes, etwas dunkleres Band oben plus
            -- feine Trennlinie darunter (Alphas addieren sich mit der Box).
            local titleBandBottom = self.displayPosY - size * 0.4
            drawFilledRect(left, titleBandBottom, width, top - titleBandBottom, 0, 0, 0, 0.2)
            drawFilledRect(left, titleBandBottom, width, 0.0012, 1, 1, 1, 0.25)

            -- M6 (Tommy ~01:50): das News-Band unten bekommt einen dunkleren
            -- Hintergrund als die Schichten-Daten (eigenes Band, ca. 0.45->0.6).
            local tipStart = nil

            for i = 2, #lines do
                if lines[i]:sub(1, 2) == '\194\187' then -- '»'
                    tipStart = i
                    break
                end
            end

            if tipStart ~= nil then
                local tipBandTop = self.displayPosY - (tipStart - 1) * lineStep + size * 1.0
                drawFilledRect(left, bottom, width, math.max(0, tipBandTop - bottom), 0, 0, 0, 0.25)
            end

            -- Box-Rechteck fuer den Maus-Treffer-Test beim Verschieben merken,
            -- dazu den Abstand Grundlinie->Boxunterkante fuer den Y-Clamp
            -- (clampHudPosition, Percys Review R2).
            MiningLayers.lastHudRect = { x = left, y = bottom, w = width, h = height }
            MiningLayers.lastHudBaselineToBottom = (#lines - 1) * lineStep + pad

            if moveMode then
                MiningLayers.drawHudMoveFrame(left, bottom, width, height)
            end
        end

        local posY = self.displayPosY

        for i = 1, #lines do
            -- Erste Zeile ist die Ueberschrift: fett.
            setTextBold(i == 1)

            -- Schatten fuer Lesbarkeit auf hellem Gelaende (bleibt schwarz,
            -- traegt zusaetzlich die aufgehellten Materialfarben auf dunklem Grund).
            setTextColor(0, 0, 0, 0.75)
            renderText(self.displayPosX + 0.0015, posY - 0.0015, size, lines[i])

            -- T13: Materialfarbe der Zeile, sonst Weiss.
            local col = (lineColors ~= nil) and lineColors[i] or nil

            if col ~= nil then
                setTextColor(col[1], col[2], col[3], 1)
            else
                setTextColor(1, 1, 1, 1)
            end

            renderText(self.displayPosX, posY, size, lines[i])

            posY = posY - size * 1.25
        end

        setTextBold(false)
        setTextColor(1, 1, 1, 1)
    end)
end

---M7: Referenzbreite des Kastens = F1-Hilfe-Menue. Defensiv gelesen, mit
---festem Rueckfallwert - die HUD-Interna sind kein stabiles API.
---@return number
function MiningLayers.getHudMaxWidth()
    local width = 0.24

    local hud = g_currentMission ~= nil and g_currentMission.hud or nil
    local inputHelp = hud ~= nil and hud.inputHelp or nil

    if inputHelp ~= nil then
        if MiningLayers.isCallable(inputHelp.getWidth) then
            local ok, w = pcall(inputHelp.getWidth, inputHelp)

            if ok and type(w) == 'number' and w > 0.05 then
                return w
            end
        end

        if type(inputHelp.overlay) == 'table' and type(inputHelp.overlay.width) == 'number'
            and inputHelp.overlay.width > 0.05 then
            return inputHelp.overlay.width
        end
    end

    return width
end

---M7: bricht Zeilen an Wortgrenzen um, damit nichts breiter wird als das
---F1-Menue. Folgezeilen eines Tipps ruecken leicht ein.
---@param lines string[]
---@param size number
---@param maxWidth number
---@return string[]
---@param lines string[]
---@param size number
---@param maxWidth number
---@param colors table[]? T13: optionale Farbe je Zeile (Index = lines-Index)
---@return string[] wrapped
---@return table[] wrappedColors jede Umbruch-Zeile erbt die Farbe ihrer Quellzeile
function MiningLayers.wrapLines(lines, size, maxWidth, colors)
    local wrapped = {}
    local wrappedColors = {}

    for idx, line in ipairs(lines) do
        local col = (colors ~= nil) and colors[idx] or nil
        local w = getTextWidth(size, line)

        if line == '' or w == nil or w <= maxWidth then
            table.insert(wrapped, line)
            wrappedColors[#wrapped] = col
        else
            local current = ''
            local isTip = line:sub(1, 2) == '\194\187' -- '»'

            for word in line:gmatch('%S+') do
                local candidate = (current == '') and word or (current .. ' ' .. word)

                if current ~= '' and getTextWidth(size, candidate) > maxWidth then
                    table.insert(wrapped, current)
                    wrappedColors[#wrapped] = col
                    current = (isTip and '   ' or '') .. word
                else
                    current = candidate
                end
            end

            if current ~= '' then
                table.insert(wrapped, current)
                wrappedColors[#wrapped] = col
            end
        end
    end

    return wrapped, wrappedColors
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

---T13: Materialfarbe fuer eine HUD-Zeile. Quelle sind die EDITOR-Farben
---(`InGameMenuMiningLayersFrame.MATERIAL_COLORS`) - dieselben, die der Spieler
---im Schichten-Editor sieht, damit die Farbe im HUD wiedererkannt wird. Fehlt
---die GUI-Klasse (Ladereihenfolge), faellt es auf die Tiefenlinien-Farben zurueck.
---
---⚠️ Dunkle Materialien (COAL 0.12, STONE, SOIL) verschwinden sonst auf dem
---dunklen HUD-Kasten. Deshalb eine Helligkeits-Untergrenze: liegt die
---wahrgenommene Helligkeit (Rec. 601) unter MIN, wird die Farbe zum Weiss hin
---aufgehellt, bis sie lesbar ist - der Farbton bleibt erhalten, nur heller.
---@param fillTypeName string?
---@return table? rgb {r,g,b} 0-1, oder nil fuer Standard (weiss)
MiningLayers.HUD_MATERIAL_MIN_LUMA = 0.55

function MiningLayers.hudMaterialColor(fillTypeName)
    if fillTypeName == nil then
        return nil
    end

    local map = (InGameMenuMiningLayersFrame ~= nil and InGameMenuMiningLayersFrame.MATERIAL_COLORS)
        or MiningLayers.DEPTH_LINE_COLORS
    local c = map[fillTypeName]

    if type(c) ~= 'table' then
        return nil -- unbekanntes Material -> Standard (weiss) im Render
    end

    local r, g, b = c[1], c[2], c[3]
    local luma = 0.299 * r + 0.587 * g + 0.114 * b

    if luma < MiningLayers.HUD_MATERIAL_MIN_LUMA then
        -- zum Weiss mischen, bis die Untergrenze erreicht ist:
        -- neu = c + (1-c)*t  =>  Luma(neu) = luma + (1-luma)*t = MIN
        local t = (MiningLayers.HUD_MATERIAL_MIN_LUMA - luma) / (1 - luma)
        r = r + (1 - r) * t
        g = g + (1 - g) * t
        b = b + (1 - b) * t
    end

    return { r, g, b }
end

---Grenzwarnung (1.6.1): Farbe der "noch X m bis <Material>"-Zeile. Weit von der
---Kante = reine Materialfarbe (Wiedererkennung, T13); je naeher die Schaufel der
---naechsten Schichtgrenze kommt, desto mehr faerbt sie sich zur Warnfarbe. Reine
---Anzeige - aendert nichts am Graben, macht die Grenze nur SICHTBAR, bevor das
---falsche Material im Kipper landet.
---@param fillTypeName string?
---@param remaining number? Meter bis zur naechsten Schicht darunter (nil = keine Warnung)
---@return table rgb
MiningLayers.HUD_WARN_NEAR = 0.5   -- m: ab hier volle Warnfarbe
MiningLayers.HUD_WARN_FAR = 2.0    -- m: ab hier reine Materialfarbe
MiningLayers.HUD_WARN_COLOR = { 1.0, 0.30, 0.22 }

function MiningLayers.hudBoundaryColor(fillTypeName, remaining)
    local base = MiningLayers.hudMaterialColor(fillTypeName) or { 1, 1, 1 }

    if type(remaining) ~= 'number' then
        return base
    end

    local near = MiningLayers.HUD_WARN_NEAR
    local far = MiningLayers.HUD_WARN_FAR
    local t = 0

    if remaining <= near then
        t = 1
    elseif remaining < far then
        t = (far - remaining) / (far - near)
    end

    if t <= 0 then
        return base
    end

    local warn = MiningLayers.HUD_WARN_COLOR

    return {
        base[1] + (warn[1] - base[1]) * t,
        base[2] + (warn[2] - base[2]) * t,
        base[3] + (warn[3] - base[3]) * t,
    }
end

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

    -- Auch die Tiefenlinien folgen dem Raster, sonst zeichnet die Anzeige andere
    -- Grenzen, als das Graben anwendet. An unberuehrten Randpunkten liefert
    -- getSurfacePointY ohnehin die Ebene zurueck - dort aendert sich nichts.
    local function surfaceAt(p)
        return MiningLayers:getSurfacePointY(p[1], p[3], plane, surfaceY)
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
        MiningLayers.log('ERROR in the depth lines: %s', tostring(err))
        MiningLayers.log('  The depth lines are switched off, everything else keeps running.')
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
        MiningLayers.log('First dig: height %.1f m, no layer applies (material unchanged).', terrainY)
        return
    end

    if surfaceY ~= nil then
        MiningLayers.log('First dig: height %.1f m, depth %.1f m, zone %s -> %s',
            terrainY, surfaceY - terrainY, tostring(zoneName), entry.fillTypeName)
    else
        MiningLayers.log('First dig: height %.1f m, zone %s -> %s',
            terrainY, tostring(zoneName), entry.fillTypeName)
    end
end
