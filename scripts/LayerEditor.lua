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
---Bergbauprodukte (Tommys Vorgabe). PAYDIRT ist bewusst NICHT dabei: das ist das
---Geld-Material, wer es frei einstellen koennte, macht sich die Karte zur
---Goldgrube. Das Floez vergibt der Mod selbst (siehe finishLayerWizard).
---Die XML von Hand bleibt der Ausweg fuer Leute, die es anders wollen.
MiningLayers.EDITOR_MATERIALS = {
    DIRT = true,
    SOIL = true,
    GRAVEL = true,
    SAND = true,
    STONE = true,
    COAL = true,
    LIMESTONE = true,
}

---Dicke des PAYDIRT-Floezes, das der Editor unter den Abraum setzt (Meter).
MiningLayers.PAYDIRT_SEAM_THICKNESS = 6

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
    MiningLayers.log('Schichten-Editor eingehaengt: Knopf "Schichten" im TerraFarm-Maschinen-Menue.')
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
        MiningLayers.log('Schichten-Editor: Dialoge nicht verfuegbar - Abbruch.')
        return
    end

    self.wizardLayers = {}

    local intro = string.format(
        MiningLayers.getText('ml_uiIntro',
            'Abraum-Schichten neu festlegen?\n\nAktuell: %s\n\nDer Editor fragt je Schicht Material und Untergrenze in Metern ab. Darunter setzt der Mod automatisch das PAYDIRT-Floez und Fels (STONE) - fuer echtes Bergbau-Gameplay, Cheaten unterstuetzen wir nicht.'),
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
            'PAYDIRT vergibt der Mod selbst - das Floez liegt unter dem Abraum.\n\nWir wollen echtes Bergbau-Gameplay erzeugen; Cheaten unterstuetzen wir nicht. Wer es anders will, kann die miningLayers.xml von Hand anpassen.'))
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

    -- Untergrenzen muessen wachsen: Minimum = vorige Grenze + 0,5 m,
    -- der Dialog klemmt Eingaben selbst auf [min, max].
    local prevDepth = 0

    if slot > 1 and self.wizardLayers[slot - 1].depth ~= nil then
        prevDepth = self.wizardLayers[slot - 1].depth
    end

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
    numberDialog:show(suggestion, prevDepth + 0.5, 100, 1, title)
end

---@param value number?
function MiningLayers:onWizardDepth(value)
    if value == nil then
        -- Abbruch im Zahlen-Dialog: Assistent endet, nichts wird gespeichert.
        return
    end

    self.wizardLayers[#self.wizardLayers].depth = value

    if #self.wizardLayers >= 6 then
        -- Sechs Abraum-Schichten reichen jedem - darunter kommt ohnehin das Floez.
        MiningLayers.protectedCall('wizardFinish', function()
            MiningLayers:finishLayerWizard()
        end)

        return
    end

    YesNoDialog.show(self.onWizardMore, self,
        MiningLayers.getText('ml_uiMore',
            'Noch eine Abraum-Schicht darunter?\n\nNein = fertig: PAYDIRT-Floez und Fels setzt der Mod automatisch darunter.'))
end

---@param yes boolean
function MiningLayers:onWizardMore(yes)
    if yes then
        MiningLayers.protectedCall('wizardMaterial', function()
            MiningLayers:askWizardMaterial()
        end)
    else
        MiningLayers.protectedCall('wizardFinish', function()
            MiningLayers:finishLayerWizard()
        end)
    end
end

---Uebernimmt die neuen Schichten: Floez + Fels anhaengen, defaultZone ersetzen,
---Caches leeren, speichern.
function MiningLayers:finishLayerWizard()
    if #self.wizardLayers == 0 then
        return
    end

    -- Das PAYDIRT-Floez und den Fels darunter vergibt der Mod - nicht der Spieler.
    -- Echtes Bergbau-Gameplay: durch den Abraum zum Floez, am Fels ist Schluss.
    local lastDepth = self.wizardLayers[#self.wizardLayers].depth or 0
    local paydirt = g_fillTypeManager:getFillTypeByName('PAYDIRT')
    local stone = g_fillTypeManager:getFillTypeByName('STONE')

    if paydirt ~= nil then
        table.insert(self.wizardLayers, {
            fillTypeName = 'PAYDIRT',
            fillTypeIndex = paydirt.index,
            depth = lastDepth + MiningLayers.PAYDIRT_SEAM_THICKNESS
        })
    end

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

    MiningLayers.log('Schichten-Editor: neue Standard-Schichten: %s (gespeichert: %s)',
        summary, ok and 'ja' or 'NEIN - nur fuer diese Sitzung')

    if InfoDialog ~= nil and MiningLayers.isCallable(InfoDialog.show) then
        InfoDialog.show(string.format(
            MiningLayers.getText('ml_uiDone', 'Neue Schichten:\n\n%s\n\nGilt sofort fuer alle Bereiche ohne eigene Zone.'),
            summary))
    end
end

--------------------------------------------------------------------------------
-- Konfiguration schreiben
--------------------------------------------------------------------------------

---@param xmlId number
---@param zoneKey string
---@param zone table
local function writeZone(xmlId, zoneKey, zone)
    if zone.area ~= nil then
        setXMLString(xmlId, zoneKey .. '#area', tostring(zone.area))
    end

    if zone.disabled then
        setXMLString(xmlId, zoneKey .. '#enabled', 'false')
        return
    end

    if zone.surfaceY ~= nil then
        setXMLString(xmlId, zoneKey .. '#surfaceY', string.format('%.2f', zone.surfaceY))
    end

    for i, layer in ipairs(zone.layers or {}) do
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
    setXMLString(xmlId, 'miningLayers#showHeightDisplay', bool(self.showHeightDisplay))
    setXMLString(xmlId, 'miningLayers#checkMaterials', bool(self.checkMaterials))
    setXMLString(xmlId, 'miningLayers#matchOutputTexture', bool(self.matchOutputTexture))
    setXMLString(xmlId, 'miningLayers#autoTargetHeight', bool(self.autoTargetHeight))
    setXMLString(xmlId, 'miningLayers#showDepthLines', bool(self.showDepthLines))
    setXMLString(xmlId, 'miningLayers#syncVehicleMaterial', bool(self.syncVehicleMaterial))
    setXMLString(xmlId, 'miningLayers#sponsorSign', bool(self.sponsorSign))
    setXMLString(xmlId, 'miningLayers#displayPosX', string.format('%.4f', self.displayPosX))
    setXMLString(xmlId, 'miningLayers#displayPosY', string.format('%.4f', self.displayPosY))

    if self.defaultZone ~= nil then
        writeZone(xmlId, 'miningLayers.defaultZone', self.defaultZone)
    end

    local i = 0

    for _, zone in pairs(self.zonesByKey) do
        writeZone(xmlId, string.format('miningLayers.zone(%d)', i), zone)
        i = i + 1
    end

    if self.globalZone ~= nil then
        writeZone(xmlId, 'miningLayers.globalZone', self.globalZone)
    end

    saveXMLFile(xmlId)
    delete(xmlId)

    MiningLayers.log('Konfiguration gespeichert: %s', path)
end
