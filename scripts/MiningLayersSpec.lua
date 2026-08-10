--
-- Minimale Fahrzeug-Spezialisierung - einziger Zweck: die Anzeige-Taste.
--
-- Das ist der in FS25 nachweislich funktionierende Weg fuer Mod-Hotkeys im
-- Fahrzeug (EnhancedVehicle, AutoDrive, Courseplay machen es exakt so):
-- eine eigene Spec auf den fahrbaren Typen, und onRegisterActionEvents kommt
-- vom Spielkern selbst - bei jedem Input-Kontext-Rebuild, ohne dass wir
-- fremde Funktionen patchen. Historie der Fehlversuche: HeightDisplay.lua.
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
---@param isSelected boolean
---@param isOnActiveVehicle boolean
function MiningLayersSpec:onRegisterActionEvents(isSelected, isOnActiveVehicle)
    if not self.isClient or MiningLayers == nil then
        return
    end

    -- Nur fuer das Gespann, in dem der Spieler sitzt. Die Registrierung selbst
    -- raeumt vorher auf (removeActionEventsByTarget) und ist damit idempotent,
    -- auch wenn mehrere Fahrzeuge des Gespanns nacheinander feuern.
    if isOnActiveVehicle or isSelected then
        pcall(MiningLayers.registerToggleActionEvent, MiningLayers)
    end
end
