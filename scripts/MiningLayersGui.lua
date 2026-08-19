--
-- Haengt die eigene Seite ins ESC-Ingame-Menue.
--
-- Registriert wird lazy aus draw(), nicht aus loadMap: das Ingame-Menue und
-- TerraFarms Texturkatalog stehen zu diesem Zeitpunkt noch nicht sicher.
-- Denselben Weg geht bereits ensureGuiButton() im LayerEditor - er hat sich
-- bewaehrt, weil er nicht von der Ladereihenfolge der Mods abhaengt.
--

---@diagnostic disable: lowercase-global, undefined-global

---Die Frame-Klasse leitet auf Modulebene von TabbedMenuFrameElement ab. Diese
---Basisspiel-Klasse steht beim Sourcen der Mod-Skripte noch nicht zwingend
---bereit, deshalb wird die Datei erst beim Einhaengen geladen - nicht hier.
MiningLayers.frameSourced = false

---Ist die Seite schon eingehaengt?
MiningLayers.menuPageInstalled = false

---Nach so vielen vergeblichen Versuchen geben wir auf und sagen es im Log.
---Bei 60 Bildern je Sekunde sind das rund zehn Sekunden.
MiningLayers.MENU_PAGE_MAX_ATTEMPTS = 600
MiningLayers.menuPageAttempts = 0
MiningLayers.menuPageGaveUp = false

---Sind alle Voraussetzungen zum Einhaengen da?
---@return boolean ready
---@return string reason
local function menuPageDependenciesReady()
    if g_client == nil then
        return false, 'no client (dedicated server)'
    end

    if g_gui == nil or not MiningLayers.isCallable(g_gui.loadGui) then
        return false, 'g_gui fehlt'
    end

    if g_inGameMenu == nil or g_inGameMenu.pagingElement == nil then
        return false, 'g_inGameMenu not built yet'
    end

    if not MiningLayers.isCallable(g_inGameMenu.registerPage)
        or not MiningLayers.isCallable(g_inGameMenu.addPageTab) then
        return false, 'g_inGameMenu cannot take pages'
    end

    -- Das Reiter-Symbol kommt aus TerraFarms Texturkatalog. Ohne ihn zeichnet
    -- der Reiter ein leeres Feld, deshalb warten wir darauf.
    if g_overlayManager == nil
        or g_overlayManager.textureConfigs == nil
        or g_overlayManager.textureConfigs['terraFarm'] == nil then
        return false, 'TerraFarm texture catalogue not registered yet'
    end

    if TabbedMenuFrameElement == nil then
        return false, 'TabbedMenuFrameElement fehlt'
    end

    return true, ''
end

---Eigener Texturkatalog fuer das Reiter-Symbol. Ohne ihn saehe unser Reiter aus
---wie TerraFarms Bagger; mit ihm zeigt er ein Bodenprofil.
MiningLayers.TEXTURE_CONFIG_NAME = 'miningLayers'
MiningLayers.ICON_SLICE_OWN = 'miningLayers.icon_layers'
MiningLayers.ICON_SLICE_FALLBACK = 'terraFarm.icon_excavator'

---Registriert den Katalog. Schlaegt das fehl, faellt alles auf TerraFarms
---Symbol zurueck - ein leerer Reiter waere schlimmer als ein geliehenes Bild.
---@return string sliceId
local function ensureIconTexture()
    if g_overlayManager == nil or g_overlayManager.textureConfigs == nil then
        return MiningLayers.ICON_SLICE_FALLBACK
    end

    if g_overlayManager.textureConfigs[MiningLayers.TEXTURE_CONFIG_NAME] == nil then
        MiningLayers.protectedCall('addTextureConfigFile', function()
            g_overlayManager:addTextureConfigFile(
                MiningLayers.MOD_DIRECTORY .. 'data/textures/ui_elements.xml',
                MiningLayers.TEXTURE_CONFIG_NAME
            )
        end)
    end

    if g_overlayManager.textureConfigs[MiningLayers.TEXTURE_CONFIG_NAME] ~= nil then
        return MiningLayers.ICON_SLICE_OWN
    end

    MiningLayers.log('Own tab icon not loaded, using the TerraFarm icon.')

    return MiningLayers.ICON_SLICE_FALLBACK
end

---Laedt die Frame-Klasse nach, sobald ihre Basisklasse existiert.
---@return boolean ok
local function sourceFrameClass()
    if MiningLayers.frameSourced then
        return InGameMenuMiningLayersFrame ~= nil
    end

    MiningLayers.frameSourced = true

    local ok = MiningLayers.protectedCall('sourceFrameClass', function()
        source(MiningLayers.MOD_DIRECTORY .. 'scripts/gui/InGameMenuMiningLayersFrame.lua')
    end)

    return ok and InGameMenuMiningLayersFrame ~= nil
end

---Haengt die Seite ein. Wird aus draw() aufgerufen und laeuft genau einmal durch.
function MiningLayers:ensureMenuPage()
    if MiningLayers.menuPageInstalled or MiningLayers.menuPageGaveUp then
        return
    end

    local ready, reason = menuPageDependenciesReady()

    if not ready then
        MiningLayers.menuPageAttempts = MiningLayers.menuPageAttempts + 1

        if MiningLayers.menuPageAttempts >= MiningLayers.MENU_PAGE_MAX_ATTEMPTS then
            MiningLayers.menuPageGaveUp = true
            MiningLayers.log('Menu page not hooked in (%s) - the documentation stays reachable through the mod description.', reason)
        end

        return
    end

    if not sourceFrameClass() then
        MiningLayers.menuPageGaveUp = true
        MiningLayers.log('Menu page not hooked in: the frame class could not be loaded.')
        return
    end

    local pageName = InGameMenuMiningLayersFrame.MENU_PAGE_NAME

    if g_inGameMenu[pageName] ~= nil then
        -- Schon vorhanden, etwa nach einem Kartenwechsel. Den Verweis mit
        -- uebernehmen: ohne ihn haelt removeMenuPage die Seite spaeter fuer
        -- entfernt und steigt aus, ohne sie anzufassen.
        MiningLayers.menuPage = g_inGameMenu[pageName]
        MiningLayers.menuPageInstalled = true
        return
    end

    -- Muss vor loadGui laufen: das Reiter-Symbol steckt in einem GUI-Profil,
    -- und das wird beim Laden der Seite einmal aufgeloest.
    local sliceId = ensureIconTexture()

    local pageController = InGameMenuMiningLayersFrame.new()

    pageController.title = MiningLayers.getText('ml_pageTitle', 'Mining Layers')

    local wasReloading = g_gui.currentlyReloading
    g_gui.currentlyReloading = true

    g_gui:loadGui(
        InGameMenuMiningLayersFrame.XML_FILENAME,
        pageName,
        pageController,
        true
    )

    g_inGameMenu[pageName] = pageController
    g_inGameMenu.pagingElement:addElement(pageController)
    g_inGameMenu.pagingElement:updateAbsolutePosition()
    g_inGameMenu.pagingElement:updatePageMapping()

    g_inGameMenu:registerPage(pageController, nil, function()
        return true
    end)

    g_inGameMenu:addPageTab(pageController, nil, nil, sliceId)

    pageController:updateAbsolutePosition()
    g_inGameMenu:rebuildTabList()

    g_gui.currentlyReloading = wasReloading

    MiningLayers.menuPage = pageController
    MiningLayers.menuPageInstalled = true

    MiningLayers.log('Menu page hooked in.')
end

---Nimmt die Seite wieder heraus.
---
---⚠️ **Wird bewusst NICHT beim Verlassen der Karte gerufen.** Genau das hat beim
---Beenden des Spiels eine Fehlerflut ausgeloest
---(`PagingElement.lua:249: attempt to index nil with 'disabled'`, danach in jedem
---Frame `mouseEvent`/`update`/`draw`), weil die Seitenzuordnung des Menues nach
---dem Entfernen nicht mehr stimmte. TerraFarm raeumt seine Seite ebenfalls nicht
---beim Kartenende ab - das Menue wird ohnehin mit abgebaut.
---Bleibt fuer den Fall, dass die Seite doch einmal von Hand weg muss; die
---Reihenfolge folgt jetzt exakt TerraFarms `deleteMenuFrame`/`deleteFrames`.
function MiningLayers:removeMenuPage()
    if not MiningLayers.menuPageInstalled then
        return
    end

    local pageName = InGameMenuMiningLayersFrame.MENU_PAGE_NAME
    local pageController = MiningLayers.menuPage

    MiningLayers.menuPageInstalled = false
    MiningLayers.menuPage = nil
    MiningLayers.menuPageAttempts = 0
    MiningLayers.menuPageGaveUp = false

    if pageController == nil or g_inGameMenu == nil then
        return
    end

    if MiningLayers.isCallable(g_inGameMenu.setPageEnabled) then
        pcall(g_inGameMenu.setPageEnabled, g_inGameMenu, pageController, false)
    end

    if MiningLayers.isCallable(g_inGameMenu.unregisterPage) then
        local _, _, pageRoot = g_inGameMenu:unregisterPage(pageController)

        if pageRoot ~= nil and g_inGameMenu.pagingElement ~= nil then
            g_inGameMenu.pagingElement:removeElement(pageRoot)

            if MiningLayers.isCallable(pageRoot.delete) then
                pageRoot:delete()
            end
        end
    end

    if MiningLayers.isCallable(pageController.delete) then
        pageController:delete()
    end

    if FocusManager ~= nil and MiningLayers.isCallable(FocusManager.deleteGuiFocusData) then
        -- Die Fokusdaten liegen unter dem GUI-Namen aus loadGui, nicht unter
        -- dem Klassennamen. Mit CLASS_NAME war der Aufruf wirkungslos.
        FocusManager:deleteGuiFocusData(InGameMenuMiningLayersFrame.MENU_PAGE_NAME)
    end

    g_inGameMenu[pageName] = nil

    if MiningLayers.isCallable(g_inGameMenu.rebuildTabList) then
        g_inGameMenu:rebuildTabList()
    end

    -- ★ Der vergessene Aufruf. Ohne ihn behaelt das Paging-Element einen
    -- Eintrag auf die entfernte Seite und faellt bei jedem Frame ueber nil.
    if g_inGameMenu.pagingElement ~= nil
        and MiningLayers.isCallable(g_inGameMenu.pagingElement.updatePageMapping) then
        g_inGameMenu.pagingElement:updatePageMapping()
    end
end
