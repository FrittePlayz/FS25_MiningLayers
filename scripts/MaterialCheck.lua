--
-- Materialpruefung.
--
-- FS25 erlaubt nur 63 Gelaende-Materialien (6 Bit Kanaltiefe der Hoehen-Density-Map).
-- Sind die Plaetze voll, werden weitere abgelehnt - die fillTypes selbst bleiben aber
-- registriert. TerraFarm bietet sie dann im Materialdialog an, und beim Abladen kommt
-- "Die Aktion kann hier nicht ausgefuehrt werden", was auf den Ort statt auf das
-- Material zeigt.
--
-- Ursache in TerraFarm: ModSettings:setDefaultMaterials() baut die Liste aus der
-- fillType-Kategorie SHOVEL und prueft den Gelaende-Typ nicht.
--
-- Diese Pruefung meldet die betroffenen Materialien. Sie entfernt nichts.
--

---@diagnostic disable: lowercase-global, undefined-global

--------------------------------------------------------------------------------
-- Material-Pool der laufenden Karte (1.4.3)
--------------------------------------------------------------------------------
--
-- Frueher bot die Schichten-Auswahl immer dieselben acht Materialien an, egal ob
-- die Karte sie kennt. Wer auf einer Karte ohne PAYDIRT eine Grube baute, bekam
-- ein Floez, das es nicht gibt - im Spiel sichtbar erst beim Graben. Genauso
-- unangenehm der Fall aus der 63er-Grenze: Material sitzt in der Schaufel und
-- laesst sich nirgends abkippen (GitHub #3, TacticalOreo).
--
-- Deshalb wird beim Kartenstart einmal geprueft, was diese Karte wirklich
-- hergibt. Die Auswahl zeigt danach nur noch das - was fehlt, steht als Hinweis
-- darunter statt als tote Zeile in der Liste.
--
-- Drei Klassen:
--   ok      registriert und auf den Boden ablegbar
--   noTip   registriert, aber ohne Gelaende-Typ: graben und verkaufen geht,
--           abkippen nicht (63-Material-Grenze)
--   missing auf dieser Karte gar nicht registriert
--

MiningLayers.MATERIAL_OK = 'ok'
MiningLayers.MATERIAL_NO_TIP = 'noTip'
MiningLayers.MATERIAL_MISSING = 'missing'

---Materialien, die der Mod ueberhaupt anbietet (Abraum + Nutzschicht). Die
---Reihenfolge ist fest verdrahtet, damit die Auswahl bei jedem Start gleich
---aussieht - `pairs()` gibt in Lua keine Reihenfolge zu.
MiningLayers.POOL_CANDIDATES = {
    'DIRT', 'SOIL', 'GRAVEL', 'SAND', 'STONE', 'COAL', 'LIMESTONE', 'PAYDIRT',
}

---@type table? { status = {name=klasse}, ok = string[], noTip = string[], missing = string[] }
MiningLayers.materialPool = nil

---Prueft einmal je Kartenstart, welche Materialien diese Karte kennt und welche
---sich ablegen lassen. Laeuft am Ende von loadMap: erst dann stehen die
---fillTypes aller Mods fest.
---@return table pool
function MiningLayers:buildMaterialPool()
    local pool = { status = {}, ok = {}, noTip = {}, missing = {} }

    for _, name in ipairs(MiningLayers.POOL_CANDIDATES) do
        local fillType = nil

        if g_fillTypeManager ~= nil then
            local found, result = pcall(g_fillTypeManager.getFillTypeByName, g_fillTypeManager, name)
            fillType = found and result or nil
        end

        local status

        if fillType == nil then
            status = MiningLayers.MATERIAL_MISSING
        else
            -- nil heisst "nicht feststellbar" (fremde Spielfassung). Dann als
            -- nutzbar behandeln: eine leere Auswahl waere schlimmer als eine
            -- Warnung, die ausbleibt.
            local tippable = self:getIsFillTypeTippable(fillType.index)

            status = (tippable == false) and MiningLayers.MATERIAL_NO_TIP or MiningLayers.MATERIAL_OK
        end

        pool.status[name] = status

        if status == MiningLayers.MATERIAL_MISSING then
            table.insert(pool.missing, name)
        elseif status == MiningLayers.MATERIAL_NO_TIP then
            table.insert(pool.noTip, name)
        else
            table.insert(pool.ok, name)
        end
    end

    self.materialPool = pool

    MiningLayers.log('Material-Pool dieser Karte: %d nutzbar, %d ohne Abkippen, %d fehlen.',
        #pool.ok, #pool.noTip, #pool.missing)

    if #pool.noTip > 0 then
        MiningLayers.log('  Nur graben/verkaufen (kein Gelaende-Typ): %s', table.concat(pool.noTip, ', '))
    end

    if #pool.missing > 0 then
        MiningLayers.log('  Kennt diese Karte nicht: %s', table.concat(pool.missing, ', '))
    end

    return pool
end

---@param fillTypeName string?
---@return string klasse  ok | noTip | missing
function MiningLayers:getMaterialStatus(fillTypeName)
    if fillTypeName == nil then
        return MiningLayers.MATERIAL_OK
    end

    local pool = self.materialPool

    -- Ohne Pool (Aufruf vor loadMap) gilt alles als nutzbar - die Auswahl
    -- verhaelt sich dann wie vor 1.4.3.
    if pool == nil or pool.status[fillTypeName] == nil then
        return MiningLayers.MATERIAL_OK
    end

    return pool.status[fillTypeName]
end

---@param fillTypeName string?
---@return boolean
function MiningLayers:getIsMaterialAvailable(fillTypeName)
    return self:getMaterialStatus(fillTypeName) ~= MiningLayers.MATERIAL_MISSING
end

---Ersatz-Nutzschicht, wenn die Karte das gewuenschte Material nicht kennt.
---Bis 1.4.2 fiel alles auf PAYDIRT zurueck - kennt die Karte auch das nicht
---(Standardkarten!), entstand eine Grube voellig ohne Nutzschicht, ohne dass
---jemand etwas merkte. Reihenfolge: die gewohnten Bergbau-Materialien zuerst.
---@return string?
function MiningLayers:getFallbackSeamMaterial()
    for _, name in ipairs({ 'PAYDIRT', 'COAL', 'LIMESTONE', 'GRAVEL', 'STONE', 'SAND', 'DIRT' }) do
        if self:getIsMaterialAvailable(name) then
            return name
        end
    end

    return nil
end

---Kann dieses Material auf den Boden abgelegt werden?
---@param fillTypeIndex number
---@return boolean? tippable  nil = nicht feststellbar
function MiningLayers:getIsFillTypeTippable(fillTypeIndex)
    local manager = g_densityMapHeightManager

    if manager == nil then
        return nil
    end

    if MiningLayers.isCallable(manager.getDensityMapHeightTypeByFillTypeIndex) then
        local ok, heightType = pcall(manager.getDensityMapHeightTypeByFillTypeIndex, manager, fillTypeIndex)

        if ok then
            return heightType ~= nil
        end
    end

    if MiningLayers.isCallable(manager.getMinValidLiterValue) then
        local ok, value = pcall(manager.getMinValidLiterValue, manager, fillTypeIndex)

        if ok then
            return value ~= nil
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- Kartenbericht (1.4.3)
--------------------------------------------------------------------------------
--
-- Tommys Auftrag vom 11.08.: "was die Karte kann, am Anfang" - und bei Karten wie
-- der 243 Quarry die klare Ansage, dass sie zu viele Materialien mitbringt.
--
-- Bewertet wird ausschliesslich, was messbar ist: wie viele Materialien auf
-- DIESER Karte einen Gelaende-Typ bekommen haben. Alt-Reste einer Portierung
-- (FS19/FS22-Pfade im Zip) kann der Mod zur Laufzeit NICHT sehen - deshalb steht
-- im Text "typisch fuer Portierungen" als Erklaerung, nicht als Behauptung.

-- ★ Ingame wird NICHT geurteilt (Percy-Einwand 19:25): eine Wertung ueber fremde
-- Kartenarbeit gehoert nicht in unser Menue. Der Bericht nennt die Wirkung
-- ("X Materialien lassen sich hier nicht abkippen") und ueberlaesst das Urteil
-- dem Spieler. Klartext steht im Log, das liest kein Kartenbauer zufaellig mit.
MiningLayers.MAP_RATING_GOOD = 'good'
MiningLayers.MAP_RATING_LIMITED = 'limited'
MiningLayers.MAP_RATING_STRONG = 'strong'

---@type table? { rating, blockedCount, checkedCount, pool }
MiningLayers.mapReport = nil

---Baut den Bericht. Wird direkt nach der Materialpruefung aufgerufen, damit
---deren Zahlen (geprueft / ohne Gelaende-Typ) mit einfliessen.
---@param checkedCount number geprueft
---@param blockedCount number davon ohne Gelaende-Typ
function MiningLayers:buildMapReport(checkedCount, blockedCount)
    local pool = self.materialPool or { ok = {}, noTip = {}, missing = {} }
    local affected = #pool.noTip + #pool.missing
    local rating

    -- Schwelle an der ANZAHL betroffener Schicht-Materialien, nicht an einem
    -- Verhaeltnis (Percy 19:25): 0 = still, 1-2 = eingeschraenkt, ab 3 deutlich.
    -- Tommys 243er lag bei 3 (SOIL/LIMESTONE/PAYDIRT), die RGC-Karte bei 0.
    if affected == 0 then
        rating = MiningLayers.MAP_RATING_GOOD
    elseif affected >= 3 then
        rating = MiningLayers.MAP_RATING_STRONG
    else
        rating = MiningLayers.MAP_RATING_LIMITED
    end

    self.mapReport = {
        rating = rating,
        checkedCount = checkedCount,
        blockedCount = blockedCount,
    }

    MiningLayers.log('Kartenbericht: %d von %d Bergbau-Materialien ohne Gelaende-Typ; Schichten-Materialien %d nutzbar / %d nur graben / %d fehlen.',
        blockedCount, checkedCount, #pool.ok, #pool.noTip, #pool.missing)

    -- Im LOG darf es deutlich stehen - hier liest niemand zufaellig mit.
    if rating == MiningLayers.MAP_RATING_GOOD then
        MiningLayers.log('  -> Voll geeignet: alle Schicht-Materialien lassen sich hier auch abkippen.')
    elseif rating == MiningLayers.MAP_RATING_LIMITED then
        MiningLayers.log('  -> Eingeschraenkt: Karte und Mods zusammen belegen mehr Bodenmaterialien, als das Spiel zulaesst (63 Plaetze, davon 48 vom Basisspiel).')
    else
        MiningLayers.log('  -> Deutlich eingeschraenkt: diese Karte bringt sehr viele eigene Bodenmaterialien mit.')
        MiningLayers.log('     Typisch fuer Portierungen aus FS19/FS22. Weniger Mods = mehr freie Plaetze.')
    end
end

---Der Bericht als Text fuer die Menueseite. Mehrzeilig, in der Sprache des Spielers.
---@return string
function MiningLayers:getMapReportText()
    local report = self.mapReport
    local pool = self.materialPool

    if report == nil or pool == nil then
        return MiningLayers.getText('ml_mapNoData', '')
    end

    local lines = {}

    -- ★ Zuerst, was GEHT (Percy 19:25): sonst liest sich jede zweite Karte wie
    -- kaputt, obwohl das Wesentliche laeuft.
    local usable = MiningLayers.getText('ml_mapUsable', '')
    local okU, usableText = pcall(string.format, usable, table.concat(pool.ok, ', '))
    table.insert(lines, okU and usableText or usable)

    -- Ist alles in Ordnung, bleibt es bei dieser einen Zeile. Kein Kasten,
    -- keine Belehrung.
    if report.rating == MiningLayers.MAP_RATING_GOOD then
        return table.concat(lines, '\n')
    end

    if #pool.noTip > 0 then
        local t = MiningLayers.getText('ml_mapNoTipList', '')
        local okL, text = pcall(string.format, t, table.concat(pool.noTip, ', '))
        table.insert(lines, okL and text or t)
    end

    if #pool.missing > 0 then
        local t = MiningLayers.getText('ml_mapMissingList', '')
        local okL, text = pcall(string.format, t, table.concat(pool.missing, ', '))
        table.insert(lines, okL and text or t)
    end

    -- Erklaerung + Merksatz. Bei vielen Betroffenen zusaetzlich der Hinweis auf
    -- die Herkunft - als Erklaerung formuliert, nicht als Urteil ueber die Karte.
    table.insert(lines, MiningLayers.getText('ml_mapAdvice', ''))

    if report.rating == MiningLayers.MAP_RATING_STRONG then
        table.insert(lines, MiningLayers.getText('ml_mapManyOwn', ''))
    end

    return table.concat(lines, '\n')
end

function MiningLayers:runMaterialCheck()
    if not self.checkMaterials then
        return
    end

    local modSettings = MiningLayers.tf('g_modSettings')

    if type(modSettings) ~= 'table' or type(modSettings.materials) ~= 'table' then
        MiningLayers.log('Materialcheck: TerraFarms Materialliste nicht lesbar - uebersprungen.')
        return
    end

    local blocked = {}
    local checked = 0
    local undetermined = false

    for _, fillTypeName in ipairs(modSettings.materials) do
        local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

        if fillType ~= nil then
            local tippable = self:getIsFillTypeTippable(fillType.index)

            if tippable == nil then
                undetermined = true
            else
                checked = checked + 1

                if not tippable then
                    table.insert(blocked, fillTypeName)
                end
            end
        end
    end

    if undetermined then
        MiningLayers.log('Materialcheck: Pruefung auf dieser Spielfassung nicht moeglich - uebersprungen.')
        return
    end

    MiningLayers.log('Materialcheck: %d Materialien geprueft, %d ohne Gelaende-Typ.', checked, #blocked)

    if #blocked > 0 then
        MiningLayers.log('  Diese lassen sich auf dieser Karte NICHT auf den Boden ablegen:')
        MiningLayers.log('  %s', table.concat(blocked, ', '))
        MiningLayers.log('  Sie funktionieren weiterhin in Anhaenger, Silo und Brecher.')
        MiningLayers.log('  Ursache ist meist die Grenze von 63 Gelaende-Materialien.')
        MiningLayers.log('  Pruefen mit: grep addDensityMapHeightType log.txt')
    end

    self:checkConfiguredMaterials(blocked)
    self:buildMapReport(checked, #blocked)
end

---Warnt, wenn ein Schichtmaterial gar nicht abgelegt werden kann. Sonst sitzt man
---mit vollem Loeffel da und wird ihn nirgends los.
---@param blocked string[]
function MiningLayers:checkConfiguredMaterials(blocked)
    if #blocked == 0 then
        return
    end

    local isBlocked = {}

    for _, name in ipairs(blocked) do
        isBlocked[name] = true
    end

    local function inspect(zone, label)
        -- ⚠️ Eine abgeschaltete Zone ist eine Marker-Tabelle OHNE layers-Feld.
        -- Ohne diese Pruefung lief ipairs(nil) in den protectedCall von loadMap
        -- und die gesamte Materialpruefung fiel still aus.
        if zone == nil or type(zone.layers) ~= 'table' then
            return
        end

        for _, layer in ipairs(zone.layers) do
            if isBlocked[layer.fillTypeName] then
                MiningLayers.log('WARNUNG %s: Schichtmaterial "%s" laesst sich nicht ablegen.',
                    label, layer.fillTypeName)
            end
        end
    end

    inspect(self.defaultZone, 'defaultZone')
    inspect(self.globalZone, 'globalZone')

    for key, zone in pairs(self.zonesByKey) do
        inspect(zone, string.format('Zone %s', key))
    end
end
