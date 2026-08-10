--
-- Minimale Fahrzeug-Spezialisierung - einziger Zweck: die Anzeige-Taste.
--
-- Muster 1:1 von FS25_EnhancedVehicle (nachweislich funktionierende Tasten):
-- Guard isClient -> isOnActiveVehicle + getIsControlled -> registerActionEvent
-- mit dem FAHRZEUG als Target, OHNE eigenes Aufraeumen (der Rebuild beginnt
-- leer, das System raeumt selbst). Historie der Fehlversuche: HeightDisplay.lua.
--
-- ⚠️ Diese Datei muss eigenstaendig bleiben (kein Zustand beim Laden): der
-- Spezialisierungs-Manager kann sie zusaetzlich zu main.lua ein zweites Mal
-- sourcen. MiningLayers wird deshalb erst zur AUFRUFZEIT angefasst.
--

---@diagnostic disable: lowercase-global, undefined-global

MiningLayersSpec = {}

function MiningLayersSpec.prerequisitesPresent(specializations)
    return true
end

function MiningLayersSpec.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onRegisterActionEvents', MiningLayersSpec)
end

---Vom Spielkern bei jedem Input-Kontext-Rebuild aufgerufen. self = Fahrzeug.
---Parameter-Namen wie in TerraFarms Machine.lua:1554 (das ist die lokal
---BEWIESENE Referenz: dessen Tasten funktionieren im selben Spielstand).
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function MiningLayersSpec:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if not self.isClient or MiningLayers == nil then
        return
    end

    pcall(MiningLayers.registerToggleActionEvent, MiningLayers, self, isActiveForInput)
end
