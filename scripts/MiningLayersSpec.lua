--
-- Minimale Fahrzeug-Spezialisierung - einziger Zweck: die Anzeige-Taste.
--
-- Bei jedem Input-Kontext-Rebuild ruft der Spielkern onRegisterActionEvents;
-- von dort geht es in MiningLayers.registerToggleActionEvent, das ueber die
-- FAHRZEUG-API registriert (vehicle:addActionEvent nach TerraFarms Muster,
-- Machine.lua:1561-1571): erst clearActionEventsTable auf der fahrzeug-eigenen
-- Event-Tabelle, dann - wenn das Fahrzeug aktiv fuer Eingaben ist - das
-- frische Event mit dem FAHRZEUG als Target. Daneben existieren noch die
-- globale Registrierung (HudMover.lua) und der Direkt-Fallback (main.lua).
-- Historie der Fehlversuche: HeightDisplay.lua.
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

    -- Param 2 zaehlt MIT: waehlt der Spieler ein ANBAUGERAET in der Kette,
    -- erlischt Param 1 am Wurzelfahrzeug und der Action-Pfad waere tot,
    -- obwohl die Anzeige weiterlaufen soll (Review-Punkt B4).
    pcall(MiningLayers.registerToggleActionEvent, MiningLayers, self,
        isActiveForInput or isActiveForInputIgnoreSelection)
end
