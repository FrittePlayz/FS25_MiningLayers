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
