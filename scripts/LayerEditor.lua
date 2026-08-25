--
-- Schichten-Editor: klickbar statt XML (Tommys Anforderung 2026-08-08 - "in der
-- XML editieren macht keiner").
--
-- UX: Button "Schichten" unten in TerraFarms Maschinen-Menue (MachineScreen) -
-- dort stellen die Spieler ohnehin alles ein. Der Button startet einen gefuehrten
-- Assistenten, der die Standard-Schichten (defaultZone) neu aufbaut:
--   je Schicht: TerraFarms Material-Dialog (mit Icons) -> Untergrenze in Metern
--   (SetNumberDialog). Untergrenze 0 = unterste Schicht, endlos - Assistent fertig.
-- Ergebnis wird in die miningLayers.xml geschrieben (mit .bak-Sicherung) und gilt
-- sofort - alle Bereichs-Caches werden verworfen, kein Neustart noetig.
--
-- Eingehaengt wird zur Laufzeit an der lebenden g_machineScreen-Instanz - kein
-- scfmod-Code wird veraendert, gleiche Philosophie wie die Landscaping-Hooks.
--

---@diagnostic disable: lowercase-global, undefined-global

MiningLayers.guiButtonInstalled = false
MiningLayers.configBackupDone = false
---@type table[] Schichten, die der Assistent gerade einsammelt
MiningLayers.wizardLayers = {}

---Materialien, die der Editor als Abraum-Schicht zulaesst - die wichtigsten
---Bergbauprodukte (Tommys Vorgabe). PAYDIRT gehoert hier bewusst nicht hin: das
---Geld-Material sitzt am Ende der Grube, nicht im Abraum darueber. Was als
---Nutzschicht taugt, steht in SEAM_MATERIALS.
MiningLayers.EDITOR_MATERIALS = {
    DIRT = true,
    SOIL = true,
    GRAVEL = true,
    SAND = true,
    STONE = true,
    COAL = true,
    LIMESTONE = true,
}

---Materialien fuer die NUTZSCHICHT, also das Floez unter dem Abraum. Seit v1.4.0
---waehlbar (Anstoss: Tazweb auf itch.io) - wer eine Kiesgrube oder eine Kohlegrube
---bauen will, ist kein Cheater. PAYDIRT bleibt die Vorgabe.
---
---Der Cheat-Schutz haengt nicht am Material, sondern an der Lage: das Floez kommt
---immer UNTER den Abraum, und mindestens eine Abraum-Schicht ist Pflicht. An der
---Grasnarbe liegt also weiterhin nie ein Geld-Material.
---Eine Whitelist bleibt es trotzdem: sonst legt jemand das wertvollste Material
---eines fremden Mods ins Floez. Der Fels darunter ist ohnehin fest.
MiningLayers.SEAM_MATERIALS = {
    PAYDIRT = true,
    DIRT = true,
    SOIL = true,
    GRAVEL = true,
    SAND = true,
    STONE = true,
    COAL = true,
    LIMESTONE = true,
}

---Dicke des Floezes, das der Editor unter den Abraum setzt (Meter).
MiningLayers.PAYDIRT_SEAM_THICKNESS = 6

---Material, das der Assistent gerade als Floez vorgesehen hat (Vorgabe PAYDIRT).
MiningLayers.wizardSeamFillTypeName = 'PAYDIRT'

---Kurzbeschreibung einer Zone fuer Dialoge, z. B. "DIRT 0-2 m, GRAVEL 2-6 m, PAYDIRT ab 6 m".
---@param zone table?
---@return string
function MiningLayers:describeZone(zone)
    if zone == nil or zone.layers == nil or #zone.layers == 0 then
        return MiningLayers.getText('ml_uiNoLayers', 'keine Schichten')
    end

    local parts = {}
    local lastDepth = 0

    for _, layer in ipairs(zone.layers) do
        if layer.depth ~= nil then
            table.insert(parts, string.format('%s %s-%s m', layer.fillTypeName,
                MiningLayers.formatNumber(lastDepth), MiningLayers.formatNumber(layer.depth)))
            lastDepth = layer.depth
        elseif layer.aboveY ~= nil then
            table.insert(parts, string.format('%s (aboveY %s)', layer.fillTypeName,
                MiningLayers.formatNumber(layer.aboveY)))
        else
            table.insert(parts, string.format('%s %s %s m', layer.fillTypeName,
                MiningLayers.getText('ml_uiBelow', 'ab'), MiningLayers.formatNumber(lastDepth)))
        end
    end

    return table.concat(parts, ', ')
end

--------------------------------------------------------------------------------
-- Button im TerraFarm-Maschinen-Menue
--------------------------------------------------------------------------------

---Haengt den "Schichten"-Knopf in die Button-Leiste des MachineScreen.
---Lazy aus draw() aufgerufen: TerraFarm baut seine GUI erst bei onMapLoaded,
---das kann NACH unserem loadMap liegen - deshalb probieren, bis die Instanz da ist.
function MiningLayers:ensureGuiButton()
    if self.guiButtonInstalled or not self.enabled then
        return
    end

    local screen = MiningLayers.tf('g_machineScreen')

    if type(screen) ~= 'table' or not MiningLayers.isCallable(screen.assignMenuButtonInfo)
        or InputAction == nil or InputAction.MENU_EXTRA_1 == nil then
        return
    end

    local buttonInfo = {
        inputAction = InputAction.MENU_EXTRA_1,
        text = MiningLayers.getText('ml_uiLayers', 'Schichten'),
        callback = function()
            MiningLayers.protectedCall('layerWizard', function()
                MiningLayers:startLayerWizard()
            end)
        end,
        isMiningLayersButton = true
    }

    -- Standard-Leiste der lebenden Instanz (greift, wenn eine Seite keine eigene
    -- Button-Liste mitbringt).
    if type(screen.defaultMenuButtonInfo) == 'table' then
        table.insert(screen.defaultMenuButtonInfo, buttonInfo)

        if type(screen.defaultMenuButtonInfoByActions) == 'table' then
            screen.defaultMenuButtonInfoByActions[InputAction.MENU_EXTRA_1] = buttonInfo
        end

        if type(screen.defaultButtonActionCallbacks) == 'table' then
            screen.defaultButtonActionCallbacks[InputAction.MENU_EXTRA_1] = buttonInfo.callback
        end
    end

    -- Jede zugewiesene Button-Leiste: Instanz-Override (faengt auch Seiten mit
    -- eigener Liste). Die uebergebene Liste wird kopiert, nie veraendert.
    local original = screen.assignMenuButtonInfo

    screen.assignMenuButtonInfo = function(scr, info, ...)
        if type(info) == 'table' then
            local hasOurs = false
            local extra1Taken = false

            for _, entry in ipairs(info) do
                if type(entry) == 'table' then
                    if entry.isMiningLayersButton then
                        hasOurs = true
                    elseif entry.inputAction == InputAction.MENU_EXTRA_1 then
                        extra1Taken = true
                    end
                end
            end

            if not hasOurs and not extra1Taken then
                local copy = {}

                for i = 1, #info do
                    copy[i] = info[i]
                end

                table.insert(copy, buttonInfo)
                info = copy
            end
        end

        return original(scr, info, ...)
    end

    self.guiButtonInstalled = true
    MiningLayers.log('Layer editor hooked in: button "Layers" in the TerraFarm machine menu.')
end

--------------------------------------------------------------------------------
-- Der Assistent
--------------------------------------------------------------------------------

---Startet den Assistenten. Baut die defaultZone von oben nach unten neu auf.
function MiningLayers:startLayerWizard()
    local selectDialog = MiningLayers.tf('g_selectMaterialDialog')
    local numberDialog = MiningLayers.tf('g_setNumberDialog')

    if type(selectDialog) ~= 'table' or type(numberDialog) ~= 'table'
        or YesNoDialog == nil or not MiningLayers.isCallable(YesNoDialog.show) then
        MiningLayers.log('Layer editor: dialogs not available - aborting.')
        return
    end

    self.wizardLayers = {}
    self.wizardSeamFillTypeName = 'PAYDIRT'

    local intro = string.format(
        MiningLayers.getText('ml_uiIntro',
            'Schichten neu festlegen?\n\nAktuell: %s\n\nDer Editor fragt je Abraum-Schicht Material und Untergrenze in Metern ab, zum Schluss die Nutzschicht darunter (Vorgabe PAYDIRT, auch Kohle oder Kalkstein moeglich). Der Fels ganz unten bleibt fest - dort ist Schluss.'),
        self:describeZone(self.defaultZone))

    YesNoDialog.show(self.onWizardIntro, self, intro)
end

---@param yes boolean
function MiningLayers:onWizardIntro(yes)
    if yes then
        MiningLayers.protectedCall('wizardMaterial', function()
            MiningLayers:askWizardMaterial()
        end)
    end
end

---Fragt das Material der naechsten Schicht ueber TerraFarms Material-Dialog ab.
function MiningLayers:askWizardMaterial()
    local selectDialog = MiningLayers.tf('g_selectMaterialDialog')
    local slot = #self.wizardLayers + 1

    -- Vorauswahl: bisheriges Material an dieser Stelle, falls vorhanden.
    local preselect = nil

    if self.defaultZone ~= nil and self.defaultZone.layers ~= nil
        and self.defaultZone.layers[slot] ~= nil then
        preselect = self.defaultZone.layers[slot].fillTypeIndex
    end

    selectDialog:setSelectCallback(self.onWizardMaterial, self)
    selectDialog:show(preselect)
end

---@param fillTypeIndex number?
---@param clickOk boolean
function MiningLayers:onWizardMaterial(fillTypeIndex, clickOk)
    if not clickOk or fillTypeIndex == nil then
        -- Abbruch: nichts speichern, nichts aendern.
        return
    end

    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    if fillType == nil or fillType.name == nil then
        return
    end

    -- TerraFarms Material-Dialog zeigt ALLE Materialien (die Liste kommt aus
    -- dessen globalen Einstellungen und laesst sich ohne Patch nicht filtern).
    -- Deshalb Pruefung NACH der Auswahl - mit Begruendung, nicht nur "nein".
    if fillType.name == 'PAYDIRT' then
        self:rejectWizardMaterial(MiningLayers.getText('ml_uiNoPaydirt',
            'PAYDIRT gehoert nicht in den Abraum - das Floez liegt darunter.\n\nDie Nutzschicht kommt als letzter Schritt, dort kannst du sie waehlen.'))
        return
    end

    if not MiningLayers.EDITOR_MATERIALS[fillType.name] then
        self:rejectWizardMaterial(string.format(MiningLayers.getText('ml_uiNotAllowed',
            '%s ist kein Abraum-Material.\n\nZur Wahl stehen die Bergbau-Materialien: DIRT, SOIL, GRAVEL, SAND, STONE, COAL, LIMESTONE.'),
            fillType.name))
        return
    end

    table.insert(self.wizardLayers, {
        fillTypeName = fillType.name,
        fillTypeIndex = fillTypeIndex
    })

    MiningLayers.protectedCall('wizardDepth', function()
        MiningLayers:askWizardDepth()
    end)
end

---Hinweis zeigen und danach die Material-Auswahl erneut oeffnen.
---@param message string
function MiningLayers:rejectWizardMaterial(message)
    local reopen = function()
        MiningLayers.protectedCall('wizardMaterial', function()
            MiningLayers:askWizardMaterial()
        end)
    end

    if InfoDialog ~= nil and MiningLayers.isCallable(InfoDialog.show) then
        InfoDialog.show(message, reopen)
    else
        reopen()
    end
end

---Fragt die Untergrenze der gerade gewaehlten Abraum-Schicht ab.
function MiningLayers:askWizardDepth()
    local numberDialog = MiningLayers.tf('g_setNumberDialog')
    local slot = #self.wizardLayers
    local layer = self.wizardLayers[slot]

    -- Untergrenzen muessen wachsen. Mindestdicke je Schicht: oberste 1,0 m,
    -- jede weitere 1,5 m (duennere brechen das Halden-Abtragen); der Dialog
    -- klemmt Eingaben selbst auf [min, max].
    local prevDepth = 0

    if slot > 1 and self.wizardLayers[slot - 1].depth ~= nil then
        prevDepth = self.wizardLayers[slot - 1].depth
    end

    local minStep = slot <= 1 and 1.0 or 1.5

    -- Vorbelegung: bisherige Tiefe an dieser Stelle, sonst vorige Grenze + 2 m.
    local suggestion = prevDepth + 2

    if self.defaultZone ~= nil and self.defaultZone.layers ~= nil
        and self.defaultZone.layers[slot] ~= nil
        and self.defaultZone.layers[slot].depth ~= nil
        and self.defaultZone.layers[slot].depth > prevDepth then
        suggestion = self.defaultZone.layers[slot].depth
    end

    local title = string.format(
        MiningLayers.getText('ml_uiDepthTitle',
            '%s: Untergrenze in m unter der Oberflaeche'),
        layer.fillTypeName)

    numberDialog:setCallback(self.onWizardDepth, self)
    numberDialog:show(suggestion, prevDepth + minStep, 100, 1, title)
end

---@param value number?
function MiningLayers:onWizardDepth(value)
    if value == nil then
        -- Abbruch im Zahlen-Dialog: Assistent endet, nichts wird gespeichert.
        return
    end

    self.wizardLayers[#self.wizardLayers].depth = value

    if #self.wizardLayers >= 6 then
        -- Sechs Abraum-Schichten reichen jedem - jetzt noch die Nutzschicht.
        -- Hier fehlt der "Noch eine?"-Dialog, der sonst ankuendigt was kommt,
        -- deshalb ein kurzer Hinweis vor der Material-Auswahl.
        local toSeam = function()
            MiningLayers.protectedCall('wizardSeam', function()
                MiningLayers:askSeamMaterial()
            end)
        end

        local hint = MiningLayers.getText('ml_uiSeamNext',
            'Sechs Abraum-Schichten sind genug.\n\nJetzt noch die Nutzschicht darunter waehlen - der Fels darunter ist fest.')

        if InfoDialog ~= nil and MiningLayers.isCallable(InfoDialog.show) then
            InfoDialog.show(hint, toSeam)
        else
            toSeam()
        end

        return
    end

    YesNoDialog.show(self.onWizardMore, self,
        MiningLayers.getText('ml_uiMore',
            'Noch eine Abraum-Schicht darunter?\n\nNein = weiter zur Nutzschicht. Den Fels darunter setzt der Mod selbst.'))
end

---@param yes boolean
function MiningLayers:onWizardMore(yes)
    if yes then
        MiningLayers.protectedCall('wizardMaterial', function()
            MiningLayers:askWizardMaterial()
        end)
    else
        MiningLayers.protectedCall('wizardSeam', function()
            MiningLayers:askSeamMaterial()
        end)
    end
end

--------------------------------------------------------------------------------
-- Die Nutzschicht (Floez)
--------------------------------------------------------------------------------

---Fragt das Material des Floezes ab - der letzte Schritt vor dem Speichern.
---Vorausgewaehlt ist das bisherige Floez der defaultZone, sonst PAYDIRT.
function MiningLayers:askSeamMaterial()
    local selectDialog = MiningLayers.tf('g_selectMaterialDialog')

    if type(selectDialog) ~= 'table' then
        -- Ohne Dialog nicht abbrechen: mit der Vorgabe weitermachen ist besser,
        -- als den fertig eingesammelten Abraum wegzuwerfen.
        self.wizardSeamFillTypeName = 'PAYDIRT'

        MiningLayers.protectedCall('wizardFinish', function()
            MiningLayers:finishLayerWizard()
        end)

        return
    end

    local preselect = nil
    local previous = self:getCurrentSeamLayer()

    if previous ~= nil then
        preselect = previous.fillTypeIndex
        self.wizardSeamFillTypeName = previous.fillTypeName
    else
        self.wizardSeamFillTypeName = 'PAYDIRT'

        local paydirt = g_fillTypeManager:getFillTypeByName('PAYDIRT')

        if paydirt ~= nil then
            preselect = paydirt.index
        end
    end

    selectDialog:setSelectCallback(self.onSeamMaterial, self)
    selectDialog:show(preselect)
end

---Das Floez der aktuellen defaultZone: die unterste Schicht MIT Tiefe, denn die
---letzte ohne Tiefe ist der endlose Fels darunter.
---@return table?
function MiningLayers:getCurrentSeamLayer()
    if self.defaultZone == nil or self.defaultZone.layers == nil then
        return nil
    end

    local found = nil

    for _, layer in ipairs(self.defaultZone.layers) do
        if layer.depth ~= nil then
            found = layer
        end
    end

    return found
end

---@param fillTypeIndex number?
---@param clickOk boolean
function MiningLayers:onSeamMaterial(fillTypeIndex, clickOk)
    if not clickOk or fillTypeIndex == nil then
        -- Abbruch: nichts speichern, nichts aendern - wie in jedem anderen Schritt.
        self.wizardLayers = {}

        return
    end

    local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    if fillType == nil or fillType.name == nil then
        return
    end

    -- Wie beim Abraum zeigt TerraFarms Dialog ALLE Materialien - pruefen laesst
    -- sich erst danach.
    if not MiningLayers.SEAM_MATERIALS[fillType.name] then
        local reopen = function()
            MiningLayers.protectedCall('wizardSeam', function()
                MiningLayers:askSeamMaterial()
            end)
        end

        local message = string.format(MiningLayers.getText('ml_uiSeamNotAllowed',
            '%s taugt nicht als Nutzschicht.\n\nZur Wahl stehen: PAYDIRT, COAL, LIMESTONE, STONE, GRAVEL, SAND, DIRT, SOIL.'),
            fillType.name)

        if InfoDialog ~= nil and MiningLayers.isCallable(InfoDialog.show) then
            InfoDialog.show(message, reopen)
        else
            reopen()
        end

        return
    end

    self.wizardSeamFillTypeName = fillType.name

    MiningLayers.protectedCall('wizardFinish', function()
        MiningLayers:finishLayerWizard()
    end)
end

---Uebernimmt die neuen Schichten: Floez + Fels anhaengen, defaultZone ersetzen,
---Caches leeren, speichern.
function MiningLayers:finishLayerWizard()
    if #self.wizardLayers == 0 then
        return
    end

    -- Das Floez waehlt der Spieler (Vorgabe PAYDIRT), den Fels darunter vergibt
    -- der Mod: durch den Abraum zur Nutzschicht, am Fels ist Schluss.
    local lastDepth = self.wizardLayers[#self.wizardLayers].depth or 0
    local seamName = self.wizardSeamFillTypeName or 'PAYDIRT'
    local seam = g_fillTypeManager:getFillTypeByName(seamName)

    -- Kennt die Karte das gewaehlte Material nicht (COAL und LIMESTONE bringt
    -- nicht jede mit), sucht der Mod das naechstbeste aus dem Material-Pool
    -- dieser Karte. Eine Grube ganz ohne Nutzschicht waere ein stiller
    -- Totalausfall.
    if seam == nil then
        -- Seit 1.4.3 ueber den Material-Pool statt stur PAYDIRT (siehe
        -- getFallbackSeamMaterial): auf Karten ohne PAYDIRT entstand sonst
        -- eine Grube ganz ohne Nutzschicht.
        local fallback = MiningLayers:getFallbackSeamMaterial()

        if fallback ~= nil then
            MiningLayers.log('Layer editor: this map does not know fill type "%s" - the pay seam becomes %s.',
                seamName, fallback)

            seamName = fallback
            seam = g_fillTypeManager:getFillTypeByName(seamName)
        end
    end

    if seam ~= nil then
        table.insert(self.wizardLayers, {
            fillTypeName = seamName,
            fillTypeIndex = seam.index,
            depth = lastDepth + MiningLayers.PAYDIRT_SEAM_THICKNESS,
            -- Markiert das Floez in der XML (seam="true"), damit Editor und
            -- Assistent es beim Wiedereinlesen sicher erkennen - auch wenn es
            -- nicht PAYDIRT heisst. STONE als Floez bekommt trotzdem die
            -- normale Fels-Sohle darunter: gleiche Struktur, kein Sonderfall.
            seam = true
        })
    end

    local stone = g_fillTypeManager:getFillTypeByName('STONE')

    if stone ~= nil then
        table.insert(self.wizardLayers, {
            fillTypeName = 'STONE',
            fillTypeIndex = stone.index
        })
    end

    local zone = {
        kind = 'default',
        enabled = true,
        layers = self.wizardLayers
    }

    self.wizardLayers = {}
    self.defaultZone = zone

    -- Alle Bereiche neu aufloesen lassen - die Aenderung gilt sofort.
    self.resolvedByArea = {}

    local ok = MiningLayers.protectedCall('saveConfigFile', function()
        MiningLayers:saveConfigFile()
    end)

    local summary = self:describeZone(zone)

    MiningLayers.log('Layer editor: new default layers: %s (saved: %s)',
        summary, ok and 'yes' or 'NO - for this session only')

    if InfoDialog ~= nil and MiningLayers.isCallable(InfoDialog.show) then
        InfoDialog.show(string.format(
            MiningLayers.getText('ml_uiDone', 'Neue Schichten:\n\n%s\n\nGilt sofort fuer alle Bereiche ohne eigene Zone.'),
            summary))
    end
end

--------------------------------------------------------------------------------
-- Konfiguration schreiben
--------------------------------------------------------------------------------

---Die Schichten einer Zone in Schreibreihenfolge - inklusive der Eintraege,
---deren Material diese Karte nicht kennt (die ruhen nur, siehe
---keepUnavailableLayer). Sortiert nach Tiefe; die Sohle ohne depth bleibt
---unten. Ohne diese Merkliste raeumt ein Speichern auf der falschen Karte die
---Konfiguration aus - dieselbe Klasse Fehler wie der verlorene paintLayer.
---@param zone table
---@return table[]
local function layersForWriting(zone)
    local list = {}

    for _, layer in ipairs(zone.layers or {}) do
        table.insert(list, layer)
    end

    local kept = type(MiningLayers.keptLayers) == 'table'
        and MiningLayers.keptLayers[MiningLayers.getZoneKey(zone) or ''] or nil

    if kept == nil or #kept.layers == 0 then
        return list
    end

    local hasSeam = false

    for _, layer in ipairs(list) do
        if layer.seam then
            hasSeam = true
            break
        end
    end

    for _, layer in ipairs(kept.layers) do
        table.insert(list, {
            fillTypeName = layer.fillTypeName,
            depth = layer.depth,
            aboveY = layer.aboveY,
            paintLayerName = layer.paintLayerName,
            -- Zwei Nutzschichten waeren ein Widerspruch: liegt schon eine im
            -- Stapel, kommt die ruhende als normale Schicht zurueck.
            seam = layer.seam and not hasSeam or nil,
        })
    end

    -- Ohne depth = endlose Sohle, gehoert immer nach unten.
    table.sort(list, function(a, b)
        return (a.depth or math.huge) < (b.depth or math.huge)
    end)

    return list
end

---@param xmlId number
---@param zoneKey string
---@param zone table
local function writeZone(xmlId, zoneKey, zone)
    if zone.area ~= nil then
        setXMLString(xmlId, zoneKey .. '#area', tostring(zone.area))
    end

    if zone.disabled then
        setXMLString(xmlId, zoneKey .. '#enabled', 'false')

        -- Abgeschaltet, aber MIT Schichten: sie werden mitgeschrieben, damit der
        -- Schalter sie unveraendert wieder einschalten kann. Gilt seit 1.6 fuer
        -- benannte Bereiche genauso wie fuer die globalZone - vorher verlor der
        -- Nutzer beim Ausschalten eines Bereichs seine Konfiguration.
        -- Nur der Alt-Marker aus 1.5.0 (<zone area="..." enabled="false"/>, keine
        -- Schichten im Speicher) endet hier.
        if type(zone.layers) ~= 'table' or #zone.layers == 0 then
            return
        end
    end

    if zone.surfaceY ~= nil then
        setXMLString(xmlId, zoneKey .. '#surfaceY', string.format('%.2f', zone.surfaceY))
    end

    for i, layer in ipairs(layersForWriting(zone)) do
        local layerKey = string.format('%s.layer(%d)', zoneKey, i - 1)

        setXMLString(xmlId, layerKey .. '#fillType', layer.fillTypeName)

        if layer.depth ~= nil then
            setXMLString(xmlId, layerKey .. '#depth', string.format('%.1f', layer.depth))
        elseif layer.aboveY ~= nil then
            setXMLString(xmlId, layerKey .. '#aboveY', string.format('%.2f', layer.aboveY))
        end

        if layer.paintLayerName ~= nil then
            setXMLString(xmlId, layerKey .. '#paintLayer', tostring(layer.paintLayerName))
        end

        if layer.seam then
            setXMLString(xmlId, layerKey .. '#seam', 'true')
        end
    end
end

---Schreibt die komplette Konfiguration zurueck in die miningLayers.xml.
---Die Kommentare der Vorlage gehen dabei verloren - dafuer gibt es einmal je
---Session eine .bak-Kopie des vorherigen Stands direkt daneben.
function MiningLayers:saveConfigFile()
    if self.SETTINGS_DIRECTORY == nil or not MiningLayers.isCallable(createXMLFile) then
        return
    end

    local path = self.SETTINGS_DIRECTORY .. MiningLayers.CONFIG_FILENAME

    if not self.configBackupDone and MiningLayers.isCallable(copyFile)
        and MiningLayers.isCallable(fileExists) and fileExists(path) then
        pcall(copyFile, path, path .. '.bak', true)
        self.configBackupDone = true
    end

    local xmlId = createXMLFile('miningLayersConfigSave', path, 'miningLayers')

    if xmlId == nil or xmlId == 0 then
        return
    end

    local function bool(value)
        return value and 'true' or 'false'
    end

    setXMLString(xmlId, 'miningLayers#enabled', bool(self.enabled))
    -- T14 Abraum-Modus: Schalter + Material ueberleben den Neustart.
    setXMLString(xmlId, 'miningLayers#spoilMode', bool(self.spoilMode))
    -- 1.6.2 Grade-Sperre: gleicher Vertrag wie der Spoil-Schalter.
    setXMLString(xmlId, 'miningLayers#holdGrade', bool(self.holdGrade))
    setXMLString(xmlId, 'miningLayers#spoilMaterial', tostring(self.spoilMaterial or 'DIRT'))
    setXMLString(xmlId, 'miningLayers#showHeightDisplay', bool(self.showHeightDisplay))
    setXMLString(xmlId, 'miningLayers#checkMaterials', bool(self.checkMaterials))
    setXMLString(xmlId, 'miningLayers#matchOutputTexture', bool(self.matchOutputTexture))
    setXMLString(xmlId, 'miningLayers#autoTargetHeight', bool(self.autoTargetHeight))
    -- Marke der einmaligen 1.6-Korrektur (siehe loadConfig): ohne sie wuerde der
    -- Schalter bei jedem Start erneut auf false gezogen, auch wenn ihn jemand
    -- bewusst eingeschaltet hat.
    setXMLString(xmlId, 'miningLayers#autoTargetHeightReviewed', bool(self.autoTargetHeightReviewed))
    -- Marke der 1.6.1-Rueckkehr: ohne sie wuerde die Automatik bei jedem Start erneut
    -- eingeschaltet, auch wenn sie jemand bewusst abgeschaltet hat.
    setXMLString(xmlId, 'miningLayers#autoTargetHeightRestored', bool(self.autoTargetHeightRestored))
    setXMLString(xmlId, 'miningLayers#showDepthLines', bool(self.showDepthLines))
    setXMLString(xmlId, 'miningLayers#syncVehicleMaterial', bool(self.syncVehicleMaterial))
    setXMLString(xmlId, 'miningLayers#freeDumpHeight', bool(self.freeDumpHeight))
    setXMLString(xmlId, 'miningLayers#dumpDiagnostics', bool(self.dumpDiagnostics))
    setXMLString(xmlId, 'miningLayers#displayPosX', string.format('%.4f', self.displayPosX))
    setXMLString(xmlId, 'miningLayers#displayPosY', string.format('%.4f', self.displayPosY))

    local written = {}

    if self.defaultZone ~= nil then
        writeZone(xmlId, 'miningLayers.defaultZone', self.defaultZone)
        written['default'] = true
    end

    local i = 0

    for _, zone in pairs(self.zonesByKey) do
        writeZone(xmlId, string.format('miningLayers.zone(%d)', i), zone)
        written[MiningLayers.getZoneKey(zone) or ''] = true
        i = i + 1
    end

    -- ⚠️ Auch die ABGESCHALTETE globalZone gehoert hierher. Bis 1.5.0 lag sie gar
    -- nicht im Speicher (loadConfig verwarf sie), also verschwand sie beim ersten
    -- Speichern still aus der Datei - der Nutzer hatte den Block danach nicht mehr,
    -- ohne dass ihm jemand etwas gesagt haette.
    local globalZone = self.globalZone or self.globalZoneOff

    if globalZone ~= nil then
        writeZone(xmlId, 'miningLayers.globalZone', globalZone)
        written['global'] = true
    end

    -- Zonen, von denen diese Karte KEIN einziges Material kennt, existieren zur
    -- Laufzeit gar nicht - ihre Schichten liegen nur in der Merkliste. Ohne
    -- diesen Durchgang waeren sie nach dem ersten Speichern weg.
    if type(self.keptLayers) == 'table' then
        for key, kept in pairs(self.keptLayers) do
            if not written[key] and #kept.layers > 0 then
                local zone = { kind = kept.kind, area = kept.area, layers = {} }
                local zoneKey

                if kept.kind == 'default' then
                    zoneKey = 'miningLayers.defaultZone'
                elseif kept.kind == 'global' then
                    zoneKey = 'miningLayers.globalZone'
                else
                    zoneKey = string.format('miningLayers.zone(%d)', i)
                    i = i + 1
                end

                writeZone(xmlId, zoneKey, zone)
                written[key] = true
            end
        end
    end

    saveXMLFile(xmlId)
    delete(xmlId)

    MiningLayers.log('Configuration saved: %s', path)
end
