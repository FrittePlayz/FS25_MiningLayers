--
-- Verschiebbares HUD (1.4.2): die Anzeige mit der Maus greifen und ablegen.
--
-- Mechanik nach dem Vorbild von HappyLoosers HL Hud System (offen zur
-- Verwendung angeboten; Referenz: FS25_ProductionInfoHud) - eigene, schlanke
-- Implementierung, kein uebernommener Code:
--   * Die Maus braucht KEIN Action-Event: die Engine ruft mouseEvent() am
--     ModEventListener (main.lua haengt MiningLayers ein) mit normalisierten
--     0..1-Koordinaten, Ursprung unten links.
--   * EINE Taste (ML_HUD_MOVE, Standard Num *) schaltet den Verschiebe-Modus:
--     Mauszeiger an, Rahmen um die Box. Registriert wird sie global ueber
--     PlayerInputComponent.registerGlobalPlayerActionEvents (HL-Muster,
--     Parameter 1:1) - der Hook laeuft bei JEDEM Kontextwechsel, die
--     Registrierung ist damit nie stale. Absicherung: Direkt-Fallback in
--     main.lua, gleiches Muster wie die Anzeige-Taste.
--   * Pickup/Drop statt Halten: Linksklick in die Box = greifen (mit Offset,
--     damit sie nicht zum Cursor springt), zweiter Linksklick = ablegen und
--     AUTOMATISCH speichern. Rechtsklick = zurueck auf die Standardposition.
--   * Position liegt normalisiert (= aufloesungsunabhaengig) in
--     modSettings/FS25_MiningLayers/hud.xml und gilt profilweit. Beim Laden
--     wird auf den Bildschirm geklemmt (Schutz nach Aufloesungswechsel).
--
-- Ueber denselben Registrierungs-Hook laeuft seit 1.4.2 ZUSAETZLICH die
-- Anzeige-Taste (Num /) - Forschungspfad 3 fuer die offene Frage, warum die
-- Binding-Aufloesung auf grossen Modlisten keine Callbacks liefert (Historie
-- in HeightDisplay.lua).
--

---@diagnostic disable: lowercase-global, undefined-global

MiningLayers.HUD_SETTINGS_FILE = 'hud.xml'

MiningLayers.hudMoveMode = false
MiningLayers.hudDragging = false
MiningLayers.hudDragOffsetX = 0
MiningLayers.hudDragOffsetY = 0
MiningLayers.hudMoveHintLogged = false
MiningLayers.lastHudRect = nil
MiningLayers.lastMoveActionTime = nil
MiningLayers.displayDefaultPosX = nil
MiningLayers.displayDefaultPosY = nil
MiningLayers.globalRegisterLogged = false

---Position auf den Bildschirm klemmen. displayPosY ist die GRUNDLINIE der
---Titelzeile - die Box waechst nach UNTEN. Untergrenze deshalb aus der zuletzt
---gezeichneten Boxhoehe (lastHudBaselineToBottom, von drawHeightDisplay
---gemerkt): sonst haengen bei tiefer Position genau Tipp-Band und
---Bedien-Anleitung unter dem Bildschirmrand (Percys Review R2).
function MiningLayers:clampHudPosition()
    local minY = (MiningLayers.lastHudBaselineToBottom or 0.05) + 0.005

    self.displayPosX = math.max(0.0, math.min(0.95, self.displayPosX or 0.012))
    self.displayPosY = math.max(minY, math.min(0.95, self.displayPosY or 0.55))
end

---Laedt die gespeicherte HUD-Position. Vorher wird der aktuelle Stand (aus
---miningLayers.xml bzw. Code) als Standard fuer den Rechtsklick-Reset gemerkt.
function MiningLayers:loadHudSettings()
    MiningLayers.displayDefaultPosX = self.displayPosX
    MiningLayers.displayDefaultPosY = self.displayPosY

    if self.SETTINGS_DIRECTORY == nil or not MiningLayers.isCallable(loadXMLFile) then
        return
    end

    local path = self.SETTINGS_DIRECTORY .. MiningLayers.HUD_SETTINGS_FILE

    if MiningLayers.isCallable(fileExists) and not fileExists(path) then
        return
    end

    local xmlId = loadXMLFile('miningLayersHud', path)

    if xmlId == nil or xmlId == 0 then
        return
    end

    local posX = getXMLFloat(xmlId, 'miningLayersHud#posX')
    local posY = getXMLFloat(xmlId, 'miningLayersHud#posY')

    delete(xmlId)

    if posX ~= nil and posY ~= nil then
        self.displayPosX = posX
        self.displayPosY = posY
        self:clampHudPosition()
    end
end

---Schreibt die HUD-Position. Wird bei jedem Ablegen aufgerufen (Auto-Save,
---bewusst ohne Save-Symbol wie bei HL - ein Klick weniger).
function MiningLayers:saveHudSettings()
    if self.SETTINGS_DIRECTORY == nil or not MiningLayers.isCallable(createXMLFile) then
        return
    end

    if MiningLayers.isCallable(createFolder) then
        pcall(createFolder, self.SETTINGS_DIRECTORY)
    end

    local path = self.SETTINGS_DIRECTORY .. MiningLayers.HUD_SETTINGS_FILE
    local xmlId = createXMLFile('miningLayersHud', path, 'miningLayersHud')

    if xmlId == nil or xmlId == 0 then
        return
    end

    setXMLFloat(xmlId, 'miningLayersHud#posX', self.displayPosX)
    setXMLFloat(xmlId, 'miningLayersHud#posY', self.displayPosY)
    saveXMLFile(xmlId)
    delete(xmlId)
end

---Kern-Umschalter OHNE Zeitstempel (Stempeln ist Sache der Action-Callbacks,
---gleiche Trennung wie bei der Anzeige-Taste).
function MiningLayers.toggleHudMoveMode()
    MiningLayers.setHudMoveMode(not MiningLayers.hudMoveMode)
end

---@param on boolean
function MiningLayers.setHudMoveMode(on)
    on = on == true

    if MiningLayers.hudMoveMode == on then
        return
    end

    MiningLayers.hudMoveMode = on
    MiningLayers.hudDragging = false

    if g_inputBinding ~= nil and MiningLayers.isCallable(g_inputBinding.setShowMouseCursor) then
        pcall(g_inputBinding.setShowMouseCursor, g_inputBinding, on)
    end

    if on then
        if not MiningLayers.hudMoveHintLogged then
            MiningLayers.hudMoveHintLogged = true
            MiningLayers.log('Move display on: left-click to grab/drop, right-click for the default position, key again = done.')
        end
    else
        -- Beim Verlassen immer sichern - auch wenn die Box noch gegriffen war.
        MiningLayers:clampHudPosition()
        MiningLayers.protectedCall('saveHudSettings', function()
            MiningLayers:saveHudSettings()
        end)
    end
end

---Action-Callback der Move-Taste (globale Registrierung). Stempelt fuer den
---Handshake mit dem Direkt-Fallback in main.lua.
function MiningLayers.actionHudMoveGlobal()
    MiningLayers.lastMoveActionTime = g_time or 0
    MiningLayers.toggleHudMoveMode()
end

---Trifft der Punkt die zuletzt gezeichnete HUD-Box?
---@param x number
---@param y number
---@return boolean
function MiningLayers.hudRectContains(x, y)
    local r = MiningLayers.lastHudRect

    if r == nil then
        return false
    end

    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

---Rahmen um die Box im Verschiebe-Modus: gegriffen = gelb, sonst weiss.
---Die horizontale Dicke wird ueber das Seitenverhaeltnis korrigiert, damit
---der Rahmen auf dem Schirm ueberall gleich dick aussieht.
---@param x number
---@param y number
---@param w number
---@param h number
function MiningLayers.drawHudMoveFrame(x, y, w, h)
    local t = 0.002
    local aspect = 9 / 16

    if type(g_screenWidth) == 'number' and type(g_screenHeight) == 'number' and g_screenWidth > 0 then
        aspect = g_screenHeight / g_screenWidth
    end

    local tx = t * aspect
    local r, g, b, a = 1, 1, 1, 0.9

    if MiningLayers.hudDragging then
        r, g, b = 1.0, 0.85, 0.2
    end

    drawFilledRect(x, y, w, t, r, g, b, a)
    drawFilledRect(x, y + h - t, w, t, r, g, b, a)
    drawFilledRect(x, y, tx, h, r, g, b, a)
    drawFilledRect(x + w - tx, y, tx, h, r, g, b, a)
end

---Engine-Callback am ModEventListener: posX/posY normalisiert 0..1, Ursprung
---unten links. Nur im Verschiebe-Modus aktiv - im normalen Spiel kostet die
---Maus hier nichts und es gibt keine versehentlichen Klicks (HL-Muster
---"Setting-Modus").
function MiningLayers:mouseEvent(posX, posY, isDown, isUp, button)
    if not MiningLayers.active or not MiningLayers.hudMoveMode then
        return
    end

    if g_gui ~= nil and g_gui.currentGui ~= nil then
        return
    end

    if MiningLayers.hudDragging then
        MiningLayers.displayPosX = posX + MiningLayers.hudDragOffsetX
        MiningLayers.displayPosY = posY + MiningLayers.hudDragOffsetY
    end

    if not isDown then
        return
    end

    local leftButton = (Input ~= nil and Input.MOUSE_BUTTON_LEFT) or 1
    local rightButton = (Input ~= nil and Input.MOUSE_BUTTON_RIGHT) or 2

    if button == leftButton then
        if MiningLayers.hudDragging then
            -- Zweiter Linksklick = ablegen + speichern.
            MiningLayers.hudDragging = false
            MiningLayers:clampHudPosition()
            MiningLayers.protectedCall('saveHudSettings', function()
                MiningLayers:saveHudSettings()
            end)
        elseif MiningLayers.hudRectContains(posX, posY) then
            -- Greifen: Offset merken, damit die Box nicht zum Cursor springt.
            MiningLayers.hudDragging = true
            MiningLayers.hudDragOffsetX = MiningLayers.displayPosX - posX
            MiningLayers.hudDragOffsetY = MiningLayers.displayPosY - posY
        end
    elseif button == rightButton then
        if MiningLayers.hudDragging or MiningLayers.hudRectContains(posX, posY) then
            MiningLayers.hudDragging = false

            if MiningLayers.displayDefaultPosX ~= nil then
                MiningLayers.displayPosX = MiningLayers.displayDefaultPosX
                MiningLayers.displayPosY = MiningLayers.displayDefaultPosY
            end

            MiningLayers.protectedCall('saveHudSettings', function()
                MiningLayers:saveHudSettings()
            end)
        end
    end
end

---Registriert beide Actions im globalen Spieler-Input (HL-Muster). Laeuft
---ueber den Hook unten bei jedem Kontextwechsel neu - kein eigenes Aufraeumen
---noetig, der Kontext beginnt leer.
function MiningLayers.registerGlobalActionEvents()
    if not MiningLayers.active or g_inputBinding == nil or InputAction == nil then
        return
    end

    -- 1) Anzeige-Taste zusaetzlich global (Forschungspfad 3). Doppel-Callbacks
    --    mit der Fahrzeug-Spez dedupliziert onToggleActionInput. Bewusst OHNE
    --    disableConflictingBindings: wir wollen anderen Mods auf Num / nichts
    --    wegnehmen, solange nicht bewiesen ist, dass dieser Pfad der Traeger ist.
    if InputAction.ML_TOGGLE_HUD ~= nil then
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.ML_TOGGLE_HUD,
            MiningLayers, MiningLayers.actionToggleHudGlobal, false, true, false, true)

        if eventId ~= nil then
            -- Den F1-Text liefert schon die Fahrzeug-Spez - hier unsichtbar.
            g_inputBinding:setActionEventTextVisibility(eventId, false)
        end
    end

    -- 2) Move-Taste. ⚠️ BEWUSST OHNE disableConflictingBindings (HL setzt es,
    --    wir nicht): der 9. Parameter gilt ab Registrierung fuer die GANZE
    --    Session, nicht nur im Move-Modus - er wuerde anderen Mods Num * still
    --    wegnehmen (Percys Review R1). Gleiches Muster wie ML_TOGGLE_HUD oben.
    if InputAction.ML_HUD_MOVE ~= nil then
        local _, eventId = g_inputBinding:registerActionEvent(InputAction.ML_HUD_MOVE,
            MiningLayers, MiningLayers.actionHudMoveGlobal, false, true, false, true)

        if eventId ~= nil then
            g_inputBinding:setActionEventText(eventId,
                MiningLayers.getText('input_ML_HUD_MOVE', 'Mining Layers: move display'))

            if GS_PRIO_LOW ~= nil then
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
            end

            g_inputBinding:setActionEventTextVisibility(eventId, true)
        end
    end

    if not MiningLayers.globalRegisterLogged then
        MiningLayers.globalRegisterLogged = true
        MiningLayers.log('Global key registration active (display + move display, HL pattern).')
    end
end

-- Hook EINMAL beim Datei-Laden setzen (wie der TypeManager-Hook in main.lua):
-- der Spielkern ruft registerGlobalPlayerActionEvents bei jedem Kontextwechsel,
-- unser Append registriert dann frisch.
if PlayerInputComponent ~= nil and Utils ~= nil
    and type(Utils.appendedFunction) == 'function'
    and type(PlayerInputComponent.registerGlobalPlayerActionEvents) == 'function' then
    PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(
        PlayerInputComponent.registerGlobalPlayerActionEvents,
        function()
            MiningLayers.protectedCall('registerGlobalActionEvents',
                MiningLayers.registerGlobalActionEvents)
        end)
else
    print((MiningLayers.LOG_PREFIX or '[MiningLayers] ')
        .. 'WARNING: PlayerInputComponent not available - the move key runs through the direct fallback only.')
end
