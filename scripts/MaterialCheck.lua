--
-- Materialpruefung.
--
-- Wie viele Gelaende-Materialien moeglich sind, legt die KARTE fest - ueber die
-- Kanalbreite ihrer Hoehen-Density-Map. Die Zahl folgt 2^n-1: 6 Bit = 63, 7 Bit = 127,
-- 8 Bit = 255. Gemessen sind die 63 (Engine-Fehlermeldung) und 83 belegte Plaetze auf
-- einer 7-Bit-Karte ohne Ablehnung; die 127 und 255 sind gerechnet.
-- Das Basisspiel belegt davon schon 48. Von aussen kann kein Mod die Zahl anheben.
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
-- unangenehm der Fall ausgegangener Bodenplaetze: Material sitzt in der Schaufel und
-- laesst sich nirgends abkippen (GitHub #3, TacticalOreo).
--
-- Deshalb wird beim Kartenstart einmal geprueft, was diese Karte wirklich
-- hergibt. Die Auswahl zeigt danach nur noch das - was fehlt, steht als Hinweis
-- darunter statt als tote Zeile in der Liste.
--
-- Drei Klassen:
--   ok      registriert und auf den Boden ablegbar
--   noTip   registriert, aber ohne Gelaende-Typ: graben und verkaufen geht,
--           abkippen nicht (dieser Karte sind die Bodenplaetze ausgegangen)
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

    MiningLayers.log('Material pool of this map: %d usable, %d not dumpable, %d missing.',
        #pool.ok, #pool.noTip, #pool.missing)

    if #pool.noTip > 0 then
        MiningLayers.log('  Dig and sell only (no terrain type): %s', table.concat(pool.noTip, ', '))
    end

    if #pool.missing > 0 then
        MiningLayers.log('  This map does not know: %s', table.concat(pool.missing, ', '))
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
    local rating

    -- ⚠️ NUR noTip zaehlt fuer die Bewertung, NICHT missing (Oreos Server-Log,
    -- 13.08.): dort war noTip = 0 und missing = 1 (SOIL), und der Mod behauptete
    -- trotzdem, die Bodenplaetze seien voll. Zwei verschiedene Ursachen:
    --   noTip   = Material da, aber kein Bodenplatz mehr frei -> Platzproblem
    --   missing = niemand liefert das Material -> hat mit Plaetzen nichts zu tun
    -- Schwelle an der ANZAHL (Percy 19:25): 0 = still, 1-2 = eingeschraenkt,
    -- ab 3 deutlich. Tommys 243er lag bei 3, die RGC-Karte bei 0.
    local slotAffected = #pool.noTip

    if slotAffected == 0 then
        rating = MiningLayers.MAP_RATING_GOOD
    elseif slotAffected >= 3 then
        rating = MiningLayers.MAP_RATING_STRONG
    else
        rating = MiningLayers.MAP_RATING_LIMITED
    end

    self.mapReport = {
        rating = rating,
        checkedCount = checkedCount,
        blockedCount = blockedCount,
        missingCount = #pool.missing,
    }

    MiningLayers.log('Map report: %d of %d mining materials without a terrain type; layer materials %d usable / %d dig-only / %d missing.',
        blockedCount, checkedCount, #pool.ok, #pool.noTip, #pool.missing)

    -- Im LOG darf es deutlich stehen - hier liest niemand zufaellig mit.
    if rating == MiningLayers.MAP_RATING_GOOD and #pool.missing > 0 then
        MiningLayers.log('  -> No slot problem: everything this map knows can be dumped as well.')
        MiningLayers.log('     Missing is only what neither the map nor the mods provide (%s) - that has nothing to do with ground slots.',
            table.concat(pool.missing, ', '))
    elseif rating == MiningLayers.MAP_RATING_GOOD then
        MiningLayers.log('  -> Fully suitable: every layer material can be dumped here as well.')
    elseif rating == MiningLayers.MAP_RATING_LIMITED then
        MiningLayers.log('  -> Limited: map and mods together want more ground materials than this map has slots (48 of them taken by the base game).')
    else
        MiningLayers.log('  -> Severely limited: this map brings a great many ground materials of its own.')
        MiningLayers.log('     Typical for maps carried over from FS19/FS22. Fewer mods frees slots - a map built with more channels has more to begin with.')
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

    -- Die Slot-Zeile gehoert in BEIDE Pfade, auch in den kurzen: auf einer guten
    -- Karte ist die Zahl kein Problembericht, sondern die interessanteste
    -- Auskunft der Seite.
    local slots = self.slotReport

    if slots ~= nil and slots.fillTypeCount ~= nil then
        local t = MiningLayers.getText('ml_slotReport', '')
        local okS, text = pcall(string.format, t, slots.withHeightType, slots.fillTypeCount)
        table.insert(lines, okS and text or t)

        -- ⚠️ Die zweite Decke (255 Fill-Types) steht hier NICHT mehr. Die Formel
        -- aus der Community-LUADOC (2^SEND_NUM_BITS - 1) ergibt auf Tommys
        -- Installation 1023, waehrend die Engine auf Oreos Server woertlich
        -- "Only 255 fill types are supported" gemeldet hat - und Tommy hat 328.
        -- Zwei Messungen, die sich widersprechen, also behaupten wir nichts.
        -- Was messbar IST, sind die Bodenplaetze dieser Karte:
        if slots.mapSlots ~= nil then
            local c = MiningLayers.getText('ml_slotMap', '')
            -- ⚠️ Reihenfolge muss zum Text passen: Plaetze, Kanaele, belegt.
            -- Lua kennt KEINE Positionsargumente (%1$d) - die Uebersetzungen
            -- muessen dieselbe Reihenfolge einhalten.
            local okC, ctext = pcall(string.format, c, slots.mapSlots,
                slots.mapChannels or 0, slots.slotsUsed or 0)
            table.insert(lines, okC and ctext or c)
        end
    end

    -- Ist alles in Ordnung, bleibt es bei dieser einen Zeile. Kein Kasten,
    -- keine Belehrung.
    -- Ist alles nutzbar UND nichts fehlt, bleibt es bei dieser einen Zeile.
    if report.rating == MiningLayers.MAP_RATING_GOOD and #pool.missing == 0 then
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
    -- ⚠️ Die Platz-Erklaerung NUR, wenn es wirklich ein Platzproblem gibt. Fehlt ein
    -- Material bloss, weil es niemand liefert, waere sie ein Fehlalarm.
    if #pool.noTip > 0 then
        table.insert(lines, MiningLayers.getText('ml_mapAdvice', ''))
    end

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
        MiningLayers.log('Material check: the TerraFarm material list is not readable - skipped.')
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
        MiningLayers.log('Material check: not possible on this game version - skipped.')
        return
    end

    MiningLayers.log('Material check: %d materials checked, %d without a terrain type.', checked, #blocked)

    if #blocked > 0 then
        MiningLayers.log('  These CANNOT be placed on the ground on this map:')
        MiningLayers.log('  %s', table.concat(blocked, ', '))
        MiningLayers.log('  They still work in trailers, silos and crushers.')
        MiningLayers.log('  Cause: this map has run out of slots for terrain materials.')
        MiningLayers.log('  Check with: grep addDensityMapHeightType log.txt')
    end

    self:buildSlotReport()
    self:checkConfiguredMaterials(blocked)
    self:buildMapReport(checked, #blocked)
end

---Zaehlt zur Laufzeit, was DIESE Installation an Materialien und Bodenplaetzen hat.
---
---Der Unterschied zum Materialcheck darueber, damit sich die beiden Zahlen im Log
---nicht zu widersprechen scheinen:
---  Materialcheck  redet ueber die BERGBAU-Materialien (eine feste Liste)
---  Slot-Bericht   redet ueber die ganze INSTALLATION (alle Fill-Types)
---Beide zaehlen ausserdem verschieden: hier zaehlt nur ein hartes `true`, ein
---"nicht feststellbar" faellt raus. buildMaterialPool behandelt genau das als
---nutzbar, weil eine leere Auswahl schlimmer waere als eine fehlende Warnung.
---
---Die Platzzahl der Karte wird NICHT gerechnet, sondern aus dem Manager gelesen
---(`numHeightTypes`, `heightTypeNumChannels`) - am 15.08. gemessen. Die frueher
---geplante Formel `2 ^ SEND_NUM_BITS - 1` fuer die Fill-Type-Decke ist raus: sie
---ergab 1023, die Engine meldete auf einem anderen Rechner 255, und diese
---Installation hat 328. Widerspruechliche Messungen behauptet der Mod nicht.
function MiningLayers:buildSlotReport()
    self.slotReport = nil

    if g_fillTypeManager == nil or type(g_fillTypeManager.fillTypes) ~= 'table' then
        MiningLayers.log('Ground slots: fill type list not readable - skipped.')
        return
    end

    local report = { withHeightType = 0 }

    report.fillTypeCount = #g_fillTypeManager.fillTypes

    -- ★ Gemessen am 15.08. auf zwei Karten, nicht abgeschrieben. Der Manager traegt
    -- die Kanalbreite der KARTE selbst: `heightTypeNumChannels`.
    --
    -- ⚠️ `numHeightTypes` ist NICHT die Kapazitaet, sondern die Zahl der BELEGTEN
    -- Plaetze - der Name legt das Gegenteil nahe. Auf einer randvollen 6-Bit-Karte
    -- fallen beide Zahlen zusammen (63 = 63) und die Verwechslung faellt nicht auf;
    -- auf Keno City (7 Kanaele) stehen 83 belegte gegen 127 moegliche. Waere die
    -- Annahme durchgerutscht, haette der Mod dort "voll" gemeldet - ausgerechnet
    -- auf der Karte mit dem meisten Platz.
    --
    -- Kapazitaet also aus der Kanalbreite: 2^n - 1. Fuer 6 Bit ist die 63 durch die
    -- Engine-Fehlermeldung selbst belegt ("maximum number (63) of height types");
    -- fuer 7 Bit ist die 127 gerechnet, passt aber zu den 83 belegten ohne eine
    -- einzige Ablehnung.
    local manager = g_densityMapHeightManager

    if manager ~= nil then
        if type(manager.heightTypeNumChannels) == 'number' then
            report.mapChannels = manager.heightTypeNumChannels
            report.mapSlots = 2 ^ report.mapChannels - 1
        end

        if type(manager.numHeightTypes) == 'number' then
            report.slotsUsed = manager.numHeightTypes
        elseif type(manager.heightTypes) == 'table' then
            report.slotsUsed = #manager.heightTypes
        end
    end

    for index = 1, report.fillTypeCount do
        if self:getIsFillTypeTippable(index) == true then
            report.withHeightType = report.withHeightType + 1
        end
    end

    -- Voll heisst voll: ab hier lehnt die Engine jedes weitere Material ab, und
    -- genau das war Oreos GRAVEL-Fall.
    report.slotsFull = report.mapSlots ~= nil and report.slotsUsed ~= nil
        and report.slotsUsed >= report.mapSlots

    self.slotReport = report

    MiningLayers.log('Ground slots: %d of %d materials on this installation have a terrain type.',
        report.withHeightType, report.fillTypeCount)

    if report.mapSlots ~= nil then
        MiningLayers.log('  This map has %d slots (%d channels) - %s in use.',
            report.mapSlots, report.mapChannels or 0,
            report.slotsUsed ~= nil and tostring(report.slotsUsed) or '?')

        if report.slotsFull then
            MiningLayers.log('  They are full. Further materials get no slot at all:')
            MiningLayers.log('  digging and selling works, dumping does not. Fewer mods with their own')
            MiningLayers.log('  ground materials frees slots, a map built with more channels has more.')
        end
    end
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
                MiningLayers.log('WARNING %s: layer material "%s" cannot be placed on the ground.',
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
