--
-- Eigene Seite im ESC-Ingame-Menue: Schnellstart, Anleitung, Tipps.
--
-- Aufbau nach dem Muster von TerraFarms InGameMenuTerraFarmFrame. Der Inhalt
-- steht als Tabelle in CONTENT und wird beim ersten Oeffnen in die drei
-- ScrollingLayouts geklont. Das haelt das GUI-XML klein und erlaubt es,
-- Bilder zu ueberspringen, solange keine Datei vorliegt.
--

---@diagnostic disable: lowercase-global, undefined-global

InGameMenuMiningLayersFrame = {}

InGameMenuMiningLayersFrame.CLASS_NAME = 'InGameMenuMiningLayersFrame'
InGameMenuMiningLayersFrame.MENU_PAGE_NAME = 'ingameMenuMiningLayers'
InGameMenuMiningLayersFrame.MENU_ICON_SLICE_ID = 'miningLayers.icon_layers'
InGameMenuMiningLayersFrame.XML_FILENAME = MiningLayers.MOD_DIRECTORY .. 'data/gui/InGameMenuMiningLayersFrame.xml'

---Unterordner fuer die Doku-Screenshots. Fehlt eine Datei, faellt der Bildplatz
---stillschweigend weg - der Text steht auch ohne Bild.
InGameMenuMiningLayersFrame.IMAGE_DIRECTORY = MiningLayers.MOD_DIRECTORY .. 'data/help/'
InGameMenuMiningLayersFrame.IMAGE_EXTENSIONS = { '.dds', '.png' }

---Inhalt der drei Reiter. type steuert, welche Vorlage geklont wird:
---section (Ueberschrift), paragraph (Fliesstext), bullet (eingerueckt),
---warning (gelb), image (Screenshot), spacer (Abstand).
---
---Der alte Dialog-Assistent ist seit 1.2.3.0 raus; Schichten baut man auf dem
---Reiter "Schichten" zusammen. Knoepfe gehoeren generell in die Menueleiste
---unten, nicht als Klon in den Fliesstext - ein geklonter Knopf muesste seinen
---Klick-Empfaenger selbst verdrahten.
InGameMenuMiningLayersFrame.CONTENT = {
    -- ------------------------------------------------------------------
    -- Reiter 1: Schnellstart
    -- ------------------------------------------------------------------
    {
        { type = 'paragraph', text = 'ml_credits' },
        { type = 'section',   text = 'ml_helpQsSetupTitle' },
        { type = 'paragraph', text = 'ml_helpQsSetup1' },
        { type = 'paragraph', text = 'ml_helpQsStockNote' },
        { type = 'image',     file = 'ml_help_01_area' },
        { type = 'paragraph', text = 'ml_helpQsSetup2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpQsBothWaysTitle' },
        { type = 'paragraph', text = 'ml_helpQsBothWays1' },
        { type = 'paragraph', text = 'ml_helpQsBothWays2' },
        { type = 'paragraph', text = 'ml_helpQsBothWays3' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpQsDisplayTitle' },
        { type = 'paragraph', text = 'ml_helpQsDisplay1' },
        { type = 'image',     file = 'ml_help_02_display' },
        { type = 'bullet',    text = 'ml_helpQsDisplayB1' },
        { type = 'bullet',    text = 'ml_helpQsDisplayB2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpQsLayersTitle' },
        { type = 'paragraph', text = 'ml_helpQsLayers1' },
        { type = 'image',     file = 'ml_help_09_layers' },
        { type = 'paragraph', text = 'ml_helpQsWizardHint' },
        { type = 'paragraph', text = 'ml_helpQsLayersScope' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpQsMistakesTitle' },
        { type = 'warning',   text = 'ml_helpQsWarnWater' },
        { type = 'warning',   text = 'ml_helpQsWarnRidge' },
        { type = 'image',     file = 'ml_help_06_mountain' },
        { type = 'paragraph', text = 'ml_helpQsRidgeCaption' },
        { type = 'warning',   text = 'ml_helpQsWarnRiver' },
    },

    -- ------------------------------------------------------------------
    -- Reiter 2: Anleitung
    -- ------------------------------------------------------------------
    {
        { type = 'section',   text = 'ml_helpManWhatTitle' },
        { type = 'paragraph', text = 'ml_helpManWhat1' },
        { type = 'paragraph', text = 'ml_helpManWhat2' },
        { type = 'paragraph', text = 'ml_helpQsBothWays1' },
        { type = 'paragraph', text = 'ml_helpQsBothWays2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpManLayersTitle' },
        { type = 'paragraph', text = 'ml_helpManLayers1' },
        { type = 'paragraph', text = 'ml_helpQsStockNote' },
        { type = 'image',     file = 'ml_help_03_wall' },
        { type = 'bullet',    text = 'ml_helpManLayersB1' },
        { type = 'bullet',    text = 'ml_helpManLayersB2' },
        { type = 'bullet',    text = 'ml_helpManLayersB3' },
        { type = 'paragraph', text = 'ml_helpManLayers2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpManMoundTitle' },
        { type = 'paragraph', text = 'ml_helpManMound1' },
        { type = 'image',     file = 'ml_help_04_mounds' },
        { type = 'bullet',    text = 'ml_helpManMoundB1' },
        { type = 'bullet',    text = 'ml_helpManMoundB2' },
        { type = 'bullet',    text = 'ml_helpManMoundB3' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpManEditorTitle' },
        { type = 'paragraph', text = 'ml_helpManEditor1' },
        { type = 'paragraph', text = 'ml_helpManEditor4' },
        { type = 'paragraph', text = 'ml_helpManEditor3' },
        { type = 'paragraph', text = 'ml_helpManEditor2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpManFloorTitle' },
        { type = 'paragraph', text = 'ml_helpManFloor1' },
        { type = 'image',     file = 'ml_help_07_water' },
        { type = 'paragraph', text = 'ml_helpManFloor2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpManConfigTitle' },
        { type = 'paragraph', text = 'ml_helpManConfig1' },
        { type = 'paragraph', text = 'ml_helpManConfig2' },
    },

    -- ------------------------------------------------------------------
    -- Reiter 3: Tipps und Fahrzeuge
    -- ------------------------------------------------------------------
    {
        { type = 'section',   text = 'ml_helpTipsTfTitle' },
        { type = 'bullet',    text = 'ml_helpTipsTfB1' },
        { type = 'bullet',    text = 'ml_helpTipsTfB2' },
        { type = 'bullet',    text = 'ml_helpTipsTfB3' },
        { type = 'bullet',    text = 'ml_helpTipsTfB4' },
        { type = 'bullet',    text = 'ml_helpTipsTfB5' },
        { type = 'image',     file = 'ml_help_05_ramp' },
        { type = 'bullet',    text = 'ml_helpTipsTfB6' },
        { type = 'image',     file = 'ml_help_10_dozer' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpTipsVehTitle' },
        { type = 'paragraph', text = 'ml_helpTipsVeh1' },
        { type = 'bullet',    text = 'ml_helpTipsVehB1' },
        { type = 'bullet',    text = 'ml_helpTipsVehB2' },
        { type = 'bullet',    text = 'ml_helpTipsVehB3' },
        { type = 'paragraph', text = 'ml_helpTipsVeh2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpTipsMapTitle' },
        { type = 'bullet',    text = 'ml_helpTipsMapB1' },
        { type = 'bullet',    text = 'ml_helpTipsMapB2' },
        { type = 'bullet',    text = 'ml_helpTipsMapB4' },
        { type = 'bullet',    text = 'ml_helpTipsMapB3' },
        { type = 'image',     file = 'ml_help_08_riverbed' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpSponsorTitle' },
        { type = 'paragraph', text = 'ml_helpSponsor1' },
        { type = 'paragraph', text = 'ml_helpSponsor2' },
        { type = 'spacer' },

        { type = 'section',   text = 'ml_helpTipsAboutTitle' },
        { type = 'paragraph', text = 'ml_helpTipsAbout1' },
        { type = 'paragraph', text = 'ml_credits' },
        { type = 'paragraph', text = 'ml_helpTipsAbout2' },
    },
}

local InGameMenuMiningLayersFrame_mt = Class(InGameMenuMiningLayersFrame, TabbedMenuFrameElement)

---@return table
function InGameMenuMiningLayersFrame.new()
    local self = TabbedMenuFrameElement.new(nil, InGameMenuMiningLayersFrame_mt)

    self.isOpen = false
    self.contentBuilt = false
    self.hasCustomMenuButtons = true

    return self
end

function InGameMenuMiningLayersFrame:delete()
    self:superClass().delete(self)

    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end

    FocusManager.guiFocusData[InGameMenuMiningLayersFrame.MENU_PAGE_NAME] = {
        idToElementMapping = {}
    }
end

function InGameMenuMiningLayersFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self:initialize()
end

function InGameMenuMiningLayersFrame:initialize()
    self:superClass().initialize(self)

    -- Reiter-Knoepfe zeigen ihren Zustand ueber das Paging-Element an,
    -- exakt wie in TerraFarms Frame.
    for index, button in pairs(self.subCategoryTabs) do
        local background = button:getDescendantByName('background')

        if background ~= nil then
            background.getIsSelected = function()
                return index == self.subCategoryPaging:getState()
            end
        end

        function button.getIsSelected()
            return index == self.subCategoryPaging:getState()
        end
    end

    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }

    self.nextPageButtonInfo = {
        inputAction = InputAction.MENU_PAGE_NEXT,
        text = g_i18n:getText('ui_ingameMenuNext'),
        callback = self.onPageNext
    }

    self.prevPageButtonInfo = {
        inputAction = InputAction.MENU_PAGE_PREV,
        text = g_i18n:getText('ui_ingameMenuPrev'),
        callback = self.onPagePrevious
    }

    self.saveLayersButtonInfo = {
        inputAction = InputAction.MENU_ACCEPT,
        text = MiningLayers.getText('ml_edSave', 'Save'),
        callback = function()
            self:onClickSaveLayers()
        end
    }

    self.addLayerButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_1,
        text = MiningLayers.getText('ml_edAdd', 'Add layer'),
        callback = function()
            self:onClickAddLayer()
        end
    }

    self.removeLayerButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_2,
        text = MiningLayers.getText('ml_edRemove', 'Remove layer'),
        callback = function()
            self:onClickRemoveLayer()
        end
    }

    -- Auf den Doku-Reitern liegt der Assistent auf EXTRA_1, im Editor brauchen
    -- wir denselben Platz fuer "Schicht hinzufuegen". Deshalb wird die Leiste
    -- beim Reiterwechsel umgehaengt statt fest verdrahtet.
    -- Auf den Doku-Reitern nur Zurueck. Der alte Dialog-Assistent ist raus,
    -- Schichten baut man auf dem Reiter "Schichten" zusammen.
    self.docMenuButtonInfo = {
        self.backButtonInfo,
    }

    self.editorMenuButtonInfo = {
        self.backButtonInfo,
        self.saveLayersButtonInfo,
        self.addLayerButtonInfo,
        self.removeLayerButtonInfo,
    }

    -- Die Blaetter-Knoepfe waren gebaut, hingen aber in keiner Leiste: ohne sie
    -- kommt man mit den Schultertasten nicht durch die vier Reiter.
    table.insert(self.docMenuButtonInfo, self.prevPageButtonInfo)
    table.insert(self.docMenuButtonInfo, self.nextPageButtonInfo)
    table.insert(self.editorMenuButtonInfo, self.prevPageButtonInfo)
    table.insert(self.editorMenuButtonInfo, self.nextPageButtonInfo)

    self.menuButtonInfo = self.docMenuButtonInfo

    self.subCategoryPaging:setState(1)
end

---Sammelt die Vorlagen ein und haengt den Halter aus, damit er nicht mitlayoutet.
function InGameMenuMiningLayersFrame:collectTemplates()
    if self.templates ~= nil then
        return
    end

    self.templates = {}

    if self.templateBox == nil then
        return
    end

    local names = {
        section   = 'tplSection',
        paragraph = 'tplParagraph',
        bullet    = 'tplBullet',
        warning   = 'tplWarning',
        image     = 'tplImage',
        spacer    = 'tplSpacer',
    }

    for kind, elementName in pairs(names) do
        self.templates[kind] = self.templateBox:getDescendantByName(elementName)
    end
end

---Sucht die erste vorhandene Bilddatei zu einem Namen (dds vor png).
---@param baseName string
---@return string?
function InGameMenuMiningLayersFrame.findImageFile(baseName)
    if not MiningLayers.isCallable(fileExists) then
        return nil
    end

    for _, extension in ipairs(InGameMenuMiningLayersFrame.IMAGE_EXTENSIONS) do
        local path = InGameMenuMiningLayersFrame.IMAGE_DIRECTORY .. baseName .. extension

        if fileExists(path) then
            return path
        end
    end

    return nil
end

---Baut einen einzelnen Eintrag in ein Layout.
---@param layout table
---@param entry table
function InGameMenuMiningLayersFrame:buildEntry(layout, entry)
    local template = self.templates[entry.type]

    if template == nil then
        return
    end

    -- Bilder nur einbauen, wenn die Datei wirklich vorliegt.
    local imagePath

    if entry.type == 'image' then
        imagePath = InGameMenuMiningLayersFrame.findImageFile(entry.file)

        if imagePath == nil then
            return
        end
    end

    local element = template:clone(layout)

    if element == nil then
        return
    end

    element:setVisible(true)

    if entry.type == 'image' then
        if MiningLayers.isCallable(element.setImageFilename) then
            element:setImageFilename(imagePath)
        end
    elseif entry.type == 'spacer' then
        -- nur Abstand, kein Inhalt
    else
        element:setText(MiningLayers.getText(entry.text, entry.text))
    end
end

---Fuellt die drei Layouts. Laeuft genau einmal.
function InGameMenuMiningLayersFrame:buildContent()
    if self.contentBuilt then
        return
    end

    self:collectTemplates()

    if self.templates == nil or self.contentLayout == nil then
        return
    end

    for pageIndex, entries in ipairs(InGameMenuMiningLayersFrame.CONTENT) do
        local layout = self.contentLayout[pageIndex]

        if layout ~= nil then
            for _, entry in ipairs(entries) do
                MiningLayers.protectedCall('buildEntry', function()
                    self:buildEntry(layout, entry)
                end)
            end

            layout:invalidateLayout()
        end
    end

    -- Der Halter darf nach dem Klonen weg, sonst reserviert er Platz.
    if self.templateBox ~= nil then
        self.templateBox:setVisible(false)
    end

    self.contentBuilt = true
end

function InGameMenuMiningLayersFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self.isOpen = true

    MiningLayers.protectedCall('buildContent', function()
        self:buildContent()
    end)

    MiningLayers.protectedCall('loadEditorFromConfig', function()
        self:loadEditorFromConfig()
        self:updateEditorOptions()
    end)

    self.subCategoryBox:invalidateLayout()
    self.subCategoryPaging:setTexts({ '1', '2', '3', '4' })
    self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)

    self:updateSubCategoryPages(self.subCategoryPaging:getState())
end

function InGameMenuMiningLayersFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    self.isOpen = false
end

function InGameMenuMiningLayersFrame:updateSubCategoryPages(subCategoryIndex)
    for index, page in pairs(self.subCategoryPages) do
        page:setVisible(index == subCategoryIndex)
    end

    local layout = self.contentLayout ~= nil and self.contentLayout[subCategoryIndex] or nil
    local isEditor = subCategoryIndex == InGameMenuMiningLayersFrame.EDITOR_PAGE

    -- ⚠️ Auf dem Editor-Reiter gibt es kein Layout zum Scrollen. Ohne das
    -- Ausblenden blieb der Schieber sichtbar und weiter an Reiter 3 gebunden.
    if self.listSlider ~= nil then
        if layout ~= nil then
            self.listSlider:setDataElement(layout)
        end

        local box = self.listSlider.parent ~= nil and self.listSlider.parent.parent or nil

        if box ~= nil and MiningLayers.isCallable(box.setVisible) then
            box:setVisible(not isEditor)
        end
    end

    self.menuButtonInfo = isEditor and self.editorMenuButtonInfo or self.docMenuButtonInfo

    FocusManager:setFocus(self.subCategoryPaging)

    -- ⚠️ updateMenuButtons() gibt es auf TabbedMenuFrameElement nicht - der
    -- Aufruf hat bei jedem Reiterwechsel eine Fehlerzeile ins Log geschrieben.
    -- Die Leiste erneuert das Ingame-Menue selbst; wir stossen es nur an,
    -- falls es dafuer eine Methode gibt.
    if MiningLayers.isCallable(self.setMenuButtonInfoDirty) then
        self:setMenuButtonInfoDirty()
    elseif g_inGameMenu ~= nil and MiningLayers.isCallable(g_inGameMenu.updateButtonsPanel) then
        g_inGameMenu:updateButtonsPanel(self)
    end
end

function InGameMenuMiningLayersFrame:onClickTabQuickstart()
    self.subCategoryPaging:setState(1, true)
end

function InGameMenuMiningLayersFrame:onClickTabManual()
    self.subCategoryPaging:setState(2, true)
end

function InGameMenuMiningLayersFrame:onClickTabTips()
    self.subCategoryPaging:setState(3, true)
end

function InGameMenuMiningLayersFrame:onClickTabEditor()
    self.subCategoryPaging:setState(InGameMenuMiningLayersFrame.EDITOR_PAGE, true)
end

function InGameMenuMiningLayersFrame:getMenuButtonInfo()
    return self.menuButtonInfo
end

-- ======================================================================
-- Reiter 4: grafischer Schichten-Editor
--
-- Ersetzt die Dialog-Kette des alten Assistenten. Links ein Querschnitt,
-- der sich bei jeder Aenderung sofort neu zeichnet, rechts drei Auswahlen.
-- Gezeichnet wird mit drawFilledRect/renderText - dieselbe Technik wie bei
-- der Hoehenanzeige im Spiel, also ohne neues GUI-Element.
-- ======================================================================

InGameMenuMiningLayersFrame.EDITOR_PAGE = 4

---Reihenfolge bewusst fest verdrahtet: `pairs()` ueber EDITOR_MATERIALS haette
---in Lua keine festgelegte Reihenfolge, die Auswahl saehe je Start anders aus.
InGameMenuMiningLayersFrame.MATERIALS = {
    'DIRT', 'SOIL', 'GRAVEL', 'SAND', 'STONE', 'COAL', 'LIMESTONE',
}

---Materialien fuer die Nutzschicht (das Floez) - seit 1.4.0 waehlbar, Anstoss
---war Tazwebs Wunsch nach Kies- und Kohlegruben (itch.io, 10.08.). PAYDIRT
---bleibt die Vorgabe und steht deshalb vorn. Der Cheat-Schutz haengt an der
---Lage, nicht am Material: das Floez liegt immer UNTER dem Abraum, und der
---Fels darunter bleibt fest.
InGameMenuMiningLayersFrame.SEAM_MATERIALS = {
    'PAYDIRT', 'COAL', 'LIMESTONE', 'STONE', 'GRAVEL', 'SAND', 'DIRT', 'SOIL',
}

---Farben fuer den Querschnitt. PAYDIRT und STONE hoeren zum Unterbau, den der
---Mod selbst setzt; sie stehen mit drin, damit man das Ganze sieht.
InGameMenuMiningLayersFrame.MATERIAL_COLORS = {
    DIRT      = { 0.42, 0.29, 0.16 },
    SOIL      = { 0.30, 0.21, 0.12 },
    GRAVEL    = { 0.55, 0.55, 0.56 },
    SAND      = { 0.80, 0.72, 0.48 },
    STONE     = { 0.32, 0.33, 0.35 },
    COAL      = { 0.12, 0.12, 0.13 },
    LIMESTONE = { 0.72, 0.72, 0.68 },
    PAYDIRT   = { 0.85, 0.68, 0.20 },
}

InGameMenuMiningLayersFrame.MIN_THICKNESS = 0.5
InGameMenuMiningLayersFrame.MAX_THICKNESS = 20.0
InGameMenuMiningLayersFrame.THICKNESS_STEP = 0.5
InGameMenuMiningLayersFrame.MAX_LAYERS = 6

---Mindestdicken (Tommy, 10.08.2026): duennere Schichten brechen das Halden-
---Abtragen. Oberste Schicht 1,0 m, jede weitere 1,5 m; im Handbuch steht
---zusaetzlich die Empfehlung, bei grossen Maschinen eher 2 m zu nehmen.
InGameMenuMiningLayersFrame.MIN_THICKNESS_FIRST = 1.0
InGameMenuMiningLayersFrame.MIN_THICKNESS_BELOW = 1.5

---@param index number Abraum-Schicht (1 = oberste)
---@return number
function InGameMenuMiningLayersFrame:minThicknessFor(index)
    if index <= 1 then
        return InGameMenuMiningLayersFrame.MIN_THICKNESS_FIRST
    end

    return InGameMenuMiningLayersFrame.MIN_THICKNESS_BELOW
end

---@return number
local function paydirtThickness()
    return MiningLayers.PAYDIRT_SEAM_THICKNESS or 6
end

---Die Nutzschicht haengt als feste letzte Zeile in der Schicht-Auswahl:
---waehlbar wie eine Abraum-Schicht, aber nicht entfernbar und mit fester Dicke.
---@return boolean
function InGameMenuMiningLayersFrame:isSeamSelected()
    return self.editLayers ~= nil and self.editIndex == #self.editLayers + 1
end

---Liest die aktuelle Standardzone in eine Arbeitskopie aus Abraum-Schichten.
---Floez und STONE-Sohle werden dabei weggelassen: die haengt der Mod beim
---Speichern selbst wieder an - das Floez-Material landet in seamName.
---Baut die Liste der Ziele: Standard plus jeder Polygon-Bereich der Karte.
function InGameMenuMiningLayersFrame:buildTargetList()
    self.targets = {
        { key = nil, label = MiningLayers.getText('ml_edTargetDefault', 'All areas (default)') },
    }

    for _, area in pairs(MiningLayers.getLandscapingAreas()) do
        -- Pfad-Bereiche haben eine Breite und bekommen nie Schichten.
        if area ~= nil and area.width == nil and area.name ~= nil then
            table.insert(self.targets, { key = area.name:lower(), label = area.name })
        end
    end

    table.sort(self.targets, function(a, b)
        if a.key == nil then return true end
        if b.key == nil then return false end
        return a.label < b.label
    end)

    self.targetIndex = math.max(1, math.min(self.targetIndex or 1, #self.targets))
end

---@return table? zone
function InGameMenuMiningLayersFrame:getTargetZone()
    local target = self.targets and self.targets[self.targetIndex] or nil

    if target == nil or target.key == nil then
        return MiningLayers.defaultZone
    end

    return MiningLayers.zonesByKey[target.key]
end

function InGameMenuMiningLayersFrame:loadEditorFromConfig()
    self.editLayers = {}

    self:buildTargetList()

    -- Hat der Bereich keine eigene Zone, dient der Standard als Vorlage. Eine
    -- eigene Zone entsteht erst beim Speichern.
    local ownZone = self:getTargetZone()

    -- Ein Bereich kann komplett ohne Schichten laufen (normales TerraFarm).
    -- Dafuer gibt es in der Konfiguration die disabled-Zone.
    self.editActive = not (ownZone ~= nil and ownZone.disabled == true)

    local zone = ownZone or MiningLayers.defaultZone
    local layers = zone ~= nil and type(zone.layers) == 'table' and zone.layers or {}

    -- ★ Floez und Sohle werden an der STRUKTUR erkannt, nicht am Materialnamen.
    -- Vorher wurde jede Schicht namens STONE weggefiltert - und STONE ist ein
    -- gueltiges Abraum-Material und sogar die Vorgabe fuer neue Schichten.
    -- Folge: Wer eine Schicht anlegte und speicherte, fand sie beim naechsten
    -- Oeffnen nicht mehr vor, und das Floez rutschte jedes Mal hoeher.
    --
    -- Der Mod schreibt immer: Abraum..., Floez (mit depth), Sohle (ohne depth).
    -- Also: letzte Schicht ohne depth = Sohle. Das Floez davor traegt seit 1.4.0
    -- den seam-Marker; aeltere Configs haben keinen, dort gilt weiter: PAYDIRT
    -- ueber der Sohle = Floez.
    local lastIndex = #layers

    if lastIndex > 0 and layers[lastIndex].depth == nil then
        lastIndex = lastIndex - 1
    end

    -- Passt die Zone nicht in unser Schema, wird das Speichern sie umschreiben.
    -- Das sagen wir, statt es still zu tun.
    self.editorForeign = false
    self.seamName = 'PAYDIRT'

    if lastIndex > 0 and (layers[lastIndex].seam == true
        or layers[lastIndex].fillTypeName == 'PAYDIRT') then
        local seamLayer = layers[lastIndex]
        lastIndex = lastIndex - 1

        -- Nur was die Auswahl kennt, kann sie auch anzeigen. Ein Floez aus
        -- einem fremden Material (Hand-XML) bleibt beim Speichern nicht
        -- erhalten - das faellt unter die editorForeign-Warnung.
        local known = false

        for _, name in ipairs(InGameMenuMiningLayersFrame.SEAM_MATERIALS) do
            if name == seamLayer.fillTypeName then
                known = true
                break
            end
        end

        if known then
            self.seamName = seamLayer.fillTypeName
        else
            self.editorForeign = true
        end
    end

    local previousDepth = 0

    for i = 1, lastIndex do
        local layer = layers[i]
        local name = layer ~= nil and layer.fillTypeName or nil

        if name == nil or layer.depth == nil then
            -- Absolute Hoehen (aboveY) oder Luecken kann der Editor nicht
            -- abbilden. Nicht anfassen, aber warnen.
            self.editorForeign = true
        else
            local thickness = layer.depth - previousDepth
            previousDepth = layer.depth

            local minHere = self:minThicknessFor(#self.editLayers + 1)

            if thickness < minHere then
                -- Zu duenn fuer die Auswahl: auf das Mindestmass heben, statt
                -- die Schicht verschwinden zu lassen.
                thickness = minHere
                self.editorForeign = true
            elseif thickness > InGameMenuMiningLayersFrame.MAX_THICKNESS then
                thickness = InGameMenuMiningLayersFrame.MAX_THICKNESS
                self.editorForeign = true
            end

            table.insert(self.editLayers, {
                fillTypeName = name,
                thickness = thickness,
            })
        end
    end

    -- Mehr Schichten als der Editor anlegen laesst: die Obergrenze gilt auch
    -- fuer von Hand gebaute Zonen, sonst waere sie umgehbar.
    while #self.editLayers > InGameMenuMiningLayersFrame.MAX_LAYERS do
        table.remove(self.editLayers)
        self.editorForeign = true
    end

    -- Etwas anderes als Abraum/Floez/Sohle in der Zone? Dann ist sie von Hand
    -- gebaut und Speichern wuerde sie vereinheitlichen.
    if zone ~= nil and (zone.surfaceY ~= nil) then
        self.editorForeign = true
    end

    for _, layer in ipairs(layers) do
        if layer.paintLayerName ~= nil or layer.aboveY ~= nil then
            self.editorForeign = true
            break
        end
    end

    -- Nichts brauchbares gefunden? Dann mit dem Auslieferungszustand starten.
    if #self.editLayers == 0 then
        self.editLayers = {
            { fillTypeName = 'DIRT',   thickness = 2 },
            { fillTypeName = 'GRAVEL', thickness = 4 },
        }
    end

    self.editIndex = 1
    self.editorDirty = false
end

---Baut die Auswahlliste der Dicken einmalig auf.
function InGameMenuMiningLayersFrame:buildThicknessTexts()
    if self.thicknessTexts ~= nil then
        return
    end

    self.thicknessTexts = {}
    self.thicknessValues = {}

    local value = InGameMenuMiningLayersFrame.MIN_THICKNESS

    while value <= InGameMenuMiningLayersFrame.MAX_THICKNESS + 0.001 do
        table.insert(self.thicknessValues, value)
        table.insert(self.thicknessTexts, string.format('%s m', MiningLayers.formatNumber(value)))
        value = value + InGameMenuMiningLayersFrame.THICKNESS_STEP
    end
end

---@param thickness number
---@return number index
function InGameMenuMiningLayersFrame:thicknessToIndex(thickness)
    local best, bestDiff = 1, math.huge

    for index, value in ipairs(self.thicknessValues) do
        local diff = math.abs(value - thickness)

        if diff < bestDiff then
            best, bestDiff = index, diff
        end
    end

    return best
end

---Schreibt den Zustand der Arbeitskopie in die drei Auswahlfelder.
function InGameMenuMiningLayersFrame:updateEditorOptions()
    if self.layerOption == nil or self.editLayers == nil then
        return
    end

    self:buildThicknessTexts()

    -- Der Nutzer soll nicht raten muessen, welche Zeile welche ist: die
    -- Auswahl zeigt Nummer und Material zusammen.
    local layerTexts = {}

    for index, layer in ipairs(self.editLayers) do
        table.insert(layerTexts, string.format('%d. %s', index, layer.fillTypeName))
    end

    -- Die Nutzschicht ist die feste letzte Zeile: Material waehlbar, Dicke und
    -- Position nicht. Der Fels darunter taucht hier gar nicht erst auf.
    local seamTemplate = MiningLayers.getText('ml_edSeamEntry', 'Nutzschicht: %s')
    local okSeam, seamText = pcall(string.format, seamTemplate, self.seamName or 'PAYDIRT')
    table.insert(layerTexts, okSeam and seamText or seamTemplate)

    self.editIndex = math.max(1, math.min(self.editIndex or 1, #self.editLayers + 1))

    self.updatingEditor = true

    if self.targetOption ~= nil and self.targets ~= nil then
        local targetTexts = {}

        for _, t in ipairs(self.targets) do
            table.insert(targetTexts, t.label)
        end

        self.targetOption:setTexts(targetTexts)
        self.targetOption:setState(self.targetIndex, false)
    end

    if self.activeOption ~= nil then
        self.activeOption:setTexts({
            MiningLayers.getText('ml_edActiveOn', 'Mining Layers'),
            MiningLayers.getText('ml_edActiveOff', 'plain TerraFarm'),
        })
        self.activeOption:setState(self.editActive and 1 or 2, false)

        -- Fuer alle Bereiche laesst sich das nicht abschalten; dafuer gibt es
        -- den globalen Schalter enabled in der miningLayers.xml.
        local target = self.targets and self.targets[self.targetIndex] or nil

        if MiningLayers.isCallable(self.activeOption.setDisabled) then
            self.activeOption:setDisabled(target == nil or target.key == nil)
        end
    end

    self.layerOption:setTexts(layerTexts)
    self.layerOption:setState(self.editIndex, false)

    if self:isSeamSelected() then
        -- Nutzschicht: eigene Materialliste, Dicke fest verdrahtet.
        self.materialOption:setTexts(InGameMenuMiningLayersFrame.SEAM_MATERIALS)

        local materialIndex = 1

        for index, name in ipairs(InGameMenuMiningLayersFrame.SEAM_MATERIALS) do
            if name == self.seamName then
                materialIndex = index
                break
            end
        end

        self.materialOption:setState(materialIndex, false)

        self.thicknessOption:setTexts(self.thicknessTexts)
        self.thicknessOption:setState(self:thicknessToIndex(paydirtThickness()), false)

        if MiningLayers.isCallable(self.thicknessOption.setDisabled) then
            self.thicknessOption:setDisabled(true)
        end

        self.updatingEditor = false

        self:updateEditorSummary()
        return
    end

    if MiningLayers.isCallable(self.thicknessOption.setDisabled) then
        self.thicknessOption:setDisabled(false)
    end

    self.materialOption:setTexts(InGameMenuMiningLayersFrame.MATERIALS)

    local current = self.editLayers[self.editIndex]

    -- Ohne Schicht gibt es nichts einzustellen. Kann nur ueber einen kuenftigen
    -- Pfad passieren, waere dann aber ein nil-Zugriff mitten in der GUI.
    if current == nil then
        self.updatingEditor = false
        return
    end

    local materialIndex = 1

    for index, name in ipairs(InGameMenuMiningLayersFrame.MATERIALS) do
        if name == current.fillTypeName then
            materialIndex = index
            break
        end
    end

    self.materialOption:setState(materialIndex, false)

    self.thicknessOption:setTexts(self.thicknessTexts)
    self.thicknessOption:setState(self:thicknessToIndex(current.thickness), false)

    self.updatingEditor = false

    self:updateEditorSummary()
end

---Textzusammenfassung unter den Auswahlfeldern.
function InGameMenuMiningLayersFrame:updateEditorSummary()
    if self.editorSummary == nil then
        return
    end

    local parts = {}
    local depth = 0

    for _, layer in ipairs(self.editLayers) do
        local from = depth
        depth = depth + layer.thickness
        table.insert(parts, string.format('%s %s-%s m',
            layer.fillTypeName,
            MiningLayers.formatNumber(from),
            MiningLayers.formatNumber(depth)))
    end

    local seamEnd = depth + paydirtThickness()

    table.insert(parts, string.format('%s %s-%s m',
        self.seamName or 'PAYDIRT',
        MiningLayers.formatNumber(depth),
        MiningLayers.formatNumber(seamEnd)))
    table.insert(parts, string.format('STONE %s %s m',
        MiningLayers.getText('ml_uiBelow', 'below'),
        MiningLayers.formatNumber(seamEnd)))

    self.editorSummary:setText(table.concat(parts, '\n'))

    if self.editorHint ~= nil then
        self.editorHint:setText(MiningLayers.getText('ml_edHint', ''))
    end

    if self.editorScope ~= nil then
        local target = self.targets and self.targets[self.targetIndex] or nil
        local key = target ~= nil and target.key or nil

        local text

        if key == nil then
            text = MiningLayers.getText('ml_edScope', '')
        else
            local template = MiningLayers.getText('ml_edScopeArea', '')
            local ok, formatted = pcall(string.format, template, target.label)
            text = ok and formatted or template
        end

        -- Zonen, die von Hand gebaut wurden, kann der Editor nur vereinfacht
        -- abbilden. Das sagen wir, bevor jemand ahnungslos speichert.
        if self.editorForeign then
            text = text .. '\n\n' .. MiningLayers.getText('ml_edForeign', '')
        end

        self.editorScope:setText(text)
    end
end

---Ziel gewechselt: Schichten des neuen Ziels laden. Ungespeichertes am alten
---Ziel ist damit weg - genau wie beim Verlassen der Seite.
function InGameMenuMiningLayersFrame:onTargetChanged(state)
    if self.updatingEditor then
        return
    end

    self.targetIndex = state

    MiningLayers.protectedCall('loadEditorForTarget', function()
        local keep = self.targetIndex
        self:loadEditorFromConfig()
        self.targetIndex = math.max(1, math.min(keep, #self.targets))
        self:updateEditorOptions()
    end)
end

function InGameMenuMiningLayersFrame:onActiveChanged(state)
    if self.updatingEditor then
        return
    end

    self.editActive = state == 1
    self.editorDirty = true

    self:updateEditorSummary()
end

function InGameMenuMiningLayersFrame:onLayerChanged(state)
    if self.updatingEditor then
        return
    end

    self.editIndex = state
    self:updateEditorOptions()
end

function InGameMenuMiningLayersFrame:onMaterialChanged(state)
    if self.updatingEditor or self.editLayers == nil then
        return
    end

    if self:isSeamSelected() then
        local name = InGameMenuMiningLayersFrame.SEAM_MATERIALS[state]

        if name ~= nil then
            self.seamName = name
            self.editorDirty = true
            self:updateEditorOptions()
        end

        return
    end

    local name = InGameMenuMiningLayersFrame.MATERIALS[state]

    if name ~= nil and self.editLayers[self.editIndex] ~= nil then
        self.editLayers[self.editIndex].fillTypeName = name
        self.editorDirty = true
        self:updateEditorOptions()
    end
end

function InGameMenuMiningLayersFrame:onThicknessChanged(state)
    if self.updatingEditor or self.editLayers == nil then
        return
    end

    -- Die Dicke der Nutzschicht ist fest - falls das Element trotz
    -- setDisabled ein Event durchlaesst, die Anzeige einfach zuruecksetzen.
    if self:isSeamSelected() then
        self:updateEditorOptions()
        return
    end

    local value = self.thicknessValues[state]

    if value ~= nil and self.editLayers[self.editIndex] ~= nil then
        -- Unter das Mindestmass laesst sich nichts stellen - zu duenne
        -- Schichten brechen das Halden-Abtragen.
        local minHere = self:minThicknessFor(self.editIndex)
        local clamped = math.max(value, minHere)

        self.editLayers[self.editIndex].thickness = clamped
        self.editorDirty = true

        if clamped ~= value then
            -- Anzeige auf den geklemmten Wert zurueckholen.
            self:updateEditorOptions()
        else
            self:updateEditorSummary()
        end
    end
end

function InGameMenuMiningLayersFrame:onClickAddLayer()
    if self.editLayers == nil then
        return
    end

    if #self.editLayers >= InGameMenuMiningLayersFrame.MAX_LAYERS then
        return
    end

    table.insert(self.editLayers, { fillTypeName = 'STONE', thickness = 2 })

    -- Neue Schicht kommt ans Ende des Abraums - direkt ueber die Nutzschicht.
    self.editIndex = #self.editLayers
    self.editorDirty = true

    self:updateEditorOptions()
end

function InGameMenuMiningLayersFrame:onClickRemoveLayer()
    if self.editLayers == nil or #self.editLayers <= 1 then
        return
    end

    -- Die Nutzschicht laesst sich nicht entfernen - ohne sie gaebe es nichts
    -- zu holen, und der Cheat-Schutz haengt an genau dieser Struktur.
    if self:isSeamSelected() then
        return
    end

    table.remove(self.editLayers, self.editIndex)

    self.editIndex = math.max(1, self.editIndex - 1)
    self.editorDirty = true

    self:updateEditorOptions()
end

---Uebernimmt die Arbeitskopie: Floez und Fels anhaengen, Standardzone ersetzen,
---Cache leeren, Datei schreiben. Reihenfolge wie in finishLayerWizard.
function InGameMenuMiningLayersFrame:onClickSaveLayers()
    if self.editLayers == nil or g_fillTypeManager == nil then
        return
    end

    local layers = {}
    local depth = 0

    local skipped = {}

    for _, layer in ipairs(self.editLayers) do
        local fillType = g_fillTypeManager:getFillTypeByName(layer.fillTypeName)

        if fillType ~= nil then
            depth = depth + math.max(layer.thickness, self:minThicknessFor(#layers + 1))

            table.insert(layers, {
                fillTypeName = layer.fillTypeName,
                fillTypeIndex = fillType.index,
                depth = depth,
            })
        else
            -- Material auf dieser Karte nicht registriert. Frueher fiel die
            -- Schicht lautlos raus und das Floez rutschte nach oben.
            table.insert(skipped, layer.fillTypeName)
        end
    end

    if #skipped > 0 then
        MiningLayers.log('Editor: %d Schicht(en) nicht gespeichert, Material unbekannt: %s',
            #skipped, table.concat(skipped, ', '))
    end

    if #layers == 0 then
        return
    end

    local seamName = self.seamName or 'PAYDIRT'
    local seam = g_fillTypeManager:getFillTypeByName(seamName)
    local stone = g_fillTypeManager:getFillTypeByName('STONE')

    -- Kennt die Karte das gewaehlte Material nicht (COAL und LIMESTONE bringt
    -- nicht jede mit), faellt das Floez auf PAYDIRT zurueck - eine Grube ohne
    -- Nutzschicht waere ein stiller Totalausfall.
    if seam == nil and seamName ~= 'PAYDIRT' then
        MiningLayers.log('Editor: fillType "%s" kennt diese Karte nicht - Floez wird PAYDIRT.',
            seamName)

        seamName = 'PAYDIRT'
        seam = g_fillTypeManager:getFillTypeByName(seamName)
    end

    if seam ~= nil then
        depth = depth + paydirtThickness()

        table.insert(layers, {
            fillTypeName = seamName,
            fillTypeIndex = seam.index,
            depth = depth,
            seam = true,
        })
    end

    if stone ~= nil then
        -- Ohne depth: Bodenschicht, reicht endlos nach unten.
        table.insert(layers, {
            fillTypeName = 'STONE',
            fillTypeIndex = stone.index,
        })
    end

    -- In die gewaehlte Zone schreiben: entweder den Standard fuer alle, oder
    -- eine eigene Zone fuer genau diesen Bereich. Der Schluessel ist der
    -- kleingeschriebene Bereichsname - so schlaegt getResolvedForArea nach.
    local target = self.targets and self.targets[self.targetIndex] or nil
    local key = target ~= nil and target.key or nil

    if key == nil then
        MiningLayers.defaultZone = {
            kind = 'default',
            enabled = true,
            layers = layers,
        }
    elseif not self.editActive then
        -- Bereich ausdruecklich ohne Schichten: dieselbe Marker-Zone, die auch
        -- die Konfigurationsdatei kennt. Sie hat bewusst KEIN layers-Feld.
        MiningLayers.zonesByKey[key] = {
            kind = 'area',
            area = target.label,
            disabled = true,
        }
    else
        MiningLayers.zonesByKey[key] = {
            kind = 'area',
            area = target.label,
            enabled = true,
            layers = layers,
        }
    end

    -- Aufgeloeste Bereiche verwerfen, sonst greift die Aenderung erst nach
    -- einem Neustart.
    MiningLayers.resolvedByArea = {}

    MiningLayers.protectedCall('saveConfigFile', function()
        MiningLayers:saveConfigFile()
    end)

    self.editorDirty = false

    if InfoDialog ~= nil and MiningLayers.isCallable(InfoDialog.show) then
        local message

        if key == nil then
            message = MiningLayers.getText('ml_edSaved', 'Layers saved.')
        elseif not self.editActive then
            local template = MiningLayers.getText('ml_edSavedOff', 'Layers are off for %s.')
            local ok, formatted = pcall(string.format, template, target.label)
            message = ok and formatted or template
        else
            local template = MiningLayers.getText('ml_edSavedArea', 'Layers saved for %s.')
            local ok, formatted = pcall(string.format, template, target.label)
            message = ok and formatted or template
        end

        InfoDialog.show(message)
    end

    self:updateEditorSummary()
end

---Malt den Querschnitt in die Flaeche von editorCanvas.
function InGameMenuMiningLayersFrame:drawLayerGraph()
    local canvas = self.editorCanvas

    if canvas == nil or self.editLayers == nil then
        return
    end

    if not MiningLayers.isCallable(drawFilledRect) or not MiningLayers.isCallable(renderText) then
        return
    end

    local x, y = canvas.absPosition[1], canvas.absPosition[2]
    local width, height = canvas.absSize[1], canvas.absSize[2]

    if width <= 0 or height <= 0 then
        return
    end

    -- Gesamttiefe: Abraum, Floez, und ein Stueck Fels als Sockel, damit man
    -- sieht, dass darunter Schluss ist.
    local overburden = 0

    for _, layer in ipairs(self.editLayers) do
        overburden = overburden + layer.thickness
    end

    local seam = paydirtThickness()
    local stoneShown = math.max(2, (overburden + seam) * 0.2)
    local total = overburden + seam + stoneShown

    if total <= 0 then
        return
    end

    local padding = width * 0.03
    local barLeft = x + padding
    local barWidth = width * 0.42
    local textLeft = barLeft + barWidth + padding
    local top = y + height

    -- Reihenfolge von oben nach unten: Abraum, dann Floez, dann Fels.
    local drawList = {}

    for index, layer in ipairs(self.editLayers) do
        table.insert(drawList, {
            name = layer.fillTypeName,
            thickness = layer.thickness,
            active = index == self.editIndex,
        })
    end

    table.insert(drawList, {
        name = self.seamName or 'PAYDIRT',
        thickness = seam,
        active = self:isSeamSelected(),
    })
    table.insert(drawList, { name = 'STONE', thickness = stoneShown, fixed = true, openEnded = true })

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)

    local depth = 0
    local textSize = height * 0.038

    for _, entry in ipairs(drawList) do
        local barHeight = height * (entry.thickness / total)
        local barTop = top - height * (depth / total)
        local barBottom = barTop - barHeight

        local color = InGameMenuMiningLayersFrame.MATERIAL_COLORS[entry.name] or { 0.5, 0.5, 0.5 }
        local alpha = entry.fixed and 0.75 or 1

        drawFilledRect(barLeft, barBottom, barWidth, barHeight, color[1], color[2], color[3], alpha)

        -- Die gewaehlte Schicht bekommt einen hellen Rand.
        if entry.active then
            local edge = math.max(height * 0.004, 0.0015)

            drawFilledRect(barLeft, barBottom, barWidth, edge, 1, 1, 1, 0.9)
            drawFilledRect(barLeft, barTop - edge, barWidth, edge, 1, 1, 1, 0.9)
            drawFilledRect(barLeft, barBottom, edge * 0.5, barHeight, 1, 1, 1, 0.9)
            drawFilledRect(barLeft + barWidth - edge * 0.5, barBottom, edge * 0.5, barHeight, 1, 1, 1, 0.9)
        end

        local from = depth
        depth = depth + entry.thickness

        local label

        if entry.openEnded then
            label = string.format('%s  %s %s m', entry.name,
                MiningLayers.getText('ml_uiBelow', 'below'),
                MiningLayers.formatNumber(from))
        else
            label = string.format('%s  %s-%s m', entry.name,
                MiningLayers.formatNumber(from),
                MiningLayers.formatNumber(depth))
        end

        local textY = barTop - barHeight * 0.5 - textSize * 0.35

        setTextBold(entry.active == true)
        setTextColor(0, 0, 0, 0.7)
        renderText(textLeft + 0.0012, textY - 0.0012, textSize, label)
        setTextColor(1, 1, 1, entry.fixed and 0.8 or 1)
        renderText(textLeft, textY, textSize, label)
    end

    setTextBold(false)
    setTextColor(1, 1, 1, 1)
end

function InGameMenuMiningLayersFrame:draw()
    self:superClass().draw(self)

    if self.subCategoryPaging ~= nil
        and self.subCategoryPaging:getState() == InGameMenuMiningLayersFrame.EDITOR_PAGE then
        MiningLayers.protectedCall('drawLayerGraph', function()
            self:drawLayerGraph()
        end)
    end
end
