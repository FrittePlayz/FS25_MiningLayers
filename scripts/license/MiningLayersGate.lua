--[[
    MiningLayersGate.lua — Aktivierung fuer Mining Layers (1.6.4, enforce).

    Mining Layers bleibt GRATIS. Der Download Key kostet nichts (fsmodworks.com,
    Konto + Selbst-Abholen) und dient Herkunftsnachweis/Wasserzeichen gegen
    Re-Uploads — keine Zahlungskopplung, der Mod kennt frei/bezahlt nicht
    (das entscheidet allein die Website; GIANTS-ToS-Einordnung im Vault).

    Ablauf: Key-Datei finden (modSettings/FSMW/ zuerst, dann mods-Ordner),
    Token zwischen den DOWNLOAD-KEY-Markern lesen, Signatur offline pruefen
    (RSA-2048, Public Key eingebaut, Fingerabdruck-Selbstcheck), Produkt +
    Sperrliste pruefen. Gueltige Datei aus dem mods-Ordner wird ueber die
    XML-API nach modSettings/FSMW/ NEU GESCHRIEBEN (DWA-0.3.6-Muster;
    copyFile blieb am lebenden Spiel unbewiesen und ist raus).

    MODE 'enforce' (seit 1.6.4, Tommys Regel 28.08.: jedes FSMW-Release
    mit Gate): ohne gueltigen Key bleibt der Mod inaktiv — mit klarer
    Meldung im Log, kein stilles Nichtstun. Key-Pfad end-to-end bewiesen
    25.08. (1.6.2.1, echter Key: `read via xml` -> VALID, ~115 ms).

    ⚠️ io.open ist TABU: die Engine LEERT damit Dateien statt sie zu lesen
    (Messung 25.08., 1104 -> 0 Bytes). Key-Dateien sind deshalb XML
    (<downloadKey>Marker-Block</downloadKey>), gelesen/geschrieben ueber
    die korpus-bewiesene XML-API.
]]

---@diagnostic disable: lowercase-global, undefined-global

MiningLayersGate = {}

---Produkt-Slug wie auf fsmodworks (Percys LICENSED_PRODUCTS; DWA-Muster
---'dig-with-anything'). Mit Percy im Kanal abgeglichen, bevor 'enforce' kommt.
MiningLayersGate.PRODUCT = 'mining-layers'

---'report' = pruefen + melden, nicht blocken (Testbuild).
---'enforce' = ohne gueltigen Key bleibt der Mod inaktiv (oeffentlicher Build).
MiningLayersGate.MODE = 'enforce'

---Sperrliste, je Build aus /admin/licenses eingebacken
---(Zeilen "<wm> <memberId> [<product>] [<issued>]").
---⚠️ Die drei MUSTER-Tokens (M1-Interop, 25.08.) sind mit dem ECHTEN
---Produktionsschluessel signiert — ohne diese Kontosperren wuerde jeder
---mit einem Muster-Token aktivieren. Bleiben in jedem Build drin.
MiningLayersGate.REVOKED_TEXT = [[
deadbeefcafe0000 MUSTER-A
deadbeefcafe0001 MUSTER-BB
deadbeefcafe0002 MUSTER-CCC
]]

---@type table? Ergebnis von FsmwLicense.check() nach run()
MiningLayersGate.result = nil
---@type string? Pfad der Datei, die das Ergebnis geliefert hat
MiningLayersGate.sourcePath = nil

---Ablageort, den Mod-Updates ueberleben. createFolder ist idempotent.
---@return string? dir
function MiningLayersGate.getSettingsDir()
    if not MiningLayers.isCallable(getUserProfileAppPath) then
        return nil
    end

    local dir = getUserProfileAppPath() .. 'modSettings/FSMW/'

    if MiningLayers.isCallable(createFolder) then
        pcall(createFolder, dir)
    end

    return dir
end

---Dateiinhalt lesen - NUR ueber die XML-API.
---
---⚠️ KEIN io.open. Gemessen am 25.08. (Tommys erster 1.6.2.0-Start): die
---Engine STELLT ein io.open bereit, aber der Aufruf hat die Key-Datei auf
---0 Bytes GELEERT (mtime exakt der loadMap-Zeitstempel, Datei vorher 1104
---Bytes; einziger Code an der Datei war unser io.open(path, 'rb')). Die
---Mode-Semantik ist also nicht Standard-Lua - Lesen ist dort Schreiben.
---loadXMLFile dagegen ist korpus-bewiesen und read-only. Deshalb ist die
---Download-Key-Datei ab jetzt ein XML mit Wurzelelement <downloadKey>,
---dessen Text der bekannte Marker-Block ist (Marker/Token unveraendert).
---@param path string
---@return string? content
---@return string? how 'xml'
function MiningLayersGate.readFile(path)
    if path:lower():sub(-4) == '.xml' and MiningLayers.isCallable(loadXMLFile) then
        local okXml, xmlContent = pcall(function()
            local xmlId = loadXMLFile('fsmwKey', path)

            if xmlId == nil or xmlId == 0 then
                return nil
            end

            local value = getXMLString(xmlId, 'downloadKey')
            delete(xmlId)

            return value
        end)

        if okXml and type(xmlContent) == 'string' and xmlContent ~= '' then
            return xmlContent, 'xml'
        end
    end

    return nil
end

---Sammelt Key-Kandidaten: alles aus modSettings/FSMW/, dazu Dateien mit
---'key' im Namen aus dem mods-Ordner (dort liegen sonst nur Zips).
---@return table paths
function MiningLayersGate.collectCandidates()
    local paths = {}

    local function collectFrom(dir, needle)
        if dir == nil or not MiningLayers.isCallable(getFiles) then
            return
        end

        local collector = {}

        function collector:onFile(filename, isDirectory)
            if isDirectory then
                return
            end

            local name = tostring(filename)

            if name:lower():sub(-4) == '.zip' then
                return
            end

            if needle ~= nil and name:lower():find(needle, 1, true) == nil then
                return
            end

            paths[#paths + 1] = dir .. name
        end

        pcall(getFiles, dir, 'onFile', collector)
    end

    collectFrom(MiningLayersGate.getSettingsDir(), nil)

    if MiningLayers.isCallable(getUserProfileAppPath) then
        collectFrom(getUserProfileAppPath() .. 'mods/', 'key')
    end

    return paths
end

---@return boolean
function MiningLayersGate.isLicensed()
    return MiningLayersGate.result ~= nil and MiningLayersGate.result.ok == true
end

---Meldungstext in Spielersprache (DE/EN aus dem Modul, Rueckfall EN).
---@return string
function MiningLayersGate.getMessage()
    local reason = MiningLayersGate.result ~= nil and MiningLayersGate.result.reason or 'noToken'
    local lang = (g_languageShort == 'de') and 'de' or 'en'

    return FsmwLicense.message(reason, lang)
end

---Gueltigen Marker-Block als Key-Datei nach modSettings/FSMW/ schreiben
---(XML-API — DWA-0.3.6-Muster; copyFile ist am lebenden Spiel unbewiesen).
---⚠️ produktspezifischer Name: der generische 'fsmodworks-download-key.xml'
---wuerde mit anderen FSMW-Mods im selben Ordner kollidieren (DWA-Learning).
---@param content string
---@return boolean ok
function MiningLayersGate.writeKeyFile(content)
    local dir = MiningLayersGate.getSettingsDir()

    if dir == nil or not MiningLayers.isCallable(createXMLFile) then
        return false
    end

    local target = dir .. 'fsmodworks-download-key-' .. MiningLayersGate.PRODUCT .. '.xml'
    local ok = pcall(function()
        local xmlId = createXMLFile('fsmwKeyOut', target, 'downloadKey')
        setXMLString(xmlId, 'downloadKey', content)
        saveXMLFile(xmlId)
        delete(xmlId)
    end)

    if ok then
        MiningLayers.log('Download Key: written to %s', target)
    end

    return ok
end

---Hauptlauf, einmal beim Kartenstart (protectedCall in main.lua).
function MiningLayersGate.run()
    if FsmwLicense == nil or FsmwLicense.crypto == nil then
        MiningLayersGate.result = { ok = false, reason = 'noCrypto' }
        MiningLayers.log('Download Key: crypto module missing - gate stays in report mode.')

        return
    end

    FsmwLicense.loadRevoked(MiningLayersGate.REVOKED_TEXT)

    local candidates = MiningLayersGate.collectCandidates()
    local best = nil
    local bestPath = nil

    for _, path in ipairs(candidates) do
        local content, how = MiningLayersGate.readFile(path)

        -- Text-Key gefunden, aber nur XML ist lesbar (io.open leert Dateien,
        -- siehe readFile): dem Spieler den Ausweg nennen statt still noToken.
        if content == nil and path:lower():sub(-4) ~= '.xml'
            and not MiningLayersGate.textHintLogged then
            MiningLayersGate.textHintLogged = true
            MiningLayers.log('Download Key: found %s, but the engine can only read the .xml key file safely.', path)
            MiningLayers.log('  Please download the key as .xml from fsmodworks.com and use that file instead.')
        end

        if content ~= nil and FsmwLicense.extractToken(content) ~= nil then
            MiningLayers.log('Download Key: candidate %s (read via %s).', path, tostring(how))

            local result = FsmwLicense.check(content, MiningLayersGate.PRODUCT)

            -- Erster gueltiger gewinnt; sonst das sprechendste Nein behalten
            -- (wrongProduct/revoked erklaeren mehr als noToken).
            if result.ok then
                best = result
                bestPath = path
                break
            end

            if best == nil or best.reason == 'noToken' then
                best = result
                bestPath = path
            end
        end
    end

    MiningLayersGate.result = best or { ok = false, reason = 'noToken' }
    MiningLayersGate.sourcePath = bestPath

    if MiningLayersGate.isLicensed() then
        local p = MiningLayersGate.result.payload

        MiningLayers.log('Download Key: VALID (member %s, watermark %s).',
            tostring(p ~= nil and p.memberId or '?'), tostring(p ~= nil and p.wm or '?'))

        -- Gueltige Datei aus dem mods-Ordner nach modSettings/FSMW/ uebernehmen:
        -- dort ueberlebt sie Mod-Updates (Neuschreiben ueber die XML-API).
        local settingsDir = MiningLayersGate.getSettingsDir()

        if settingsDir ~= nil and bestPath ~= nil
            and bestPath:sub(1, #settingsDir) ~= settingsDir then
            local content = MiningLayersGate.readFile(bestPath)
            if content ~= nil then
                MiningLayersGate.writeKeyFile(content)
            end
        end
    else
        MiningLayers.log('Download Key: NOT valid (%s) - %s',
            tostring(MiningLayersGate.result.reason), MiningLayersGate.getMessage())

        if MiningLayersGate.MODE == 'report' then
            MiningLayers.log('  Gate mode "report": the mod keeps working, this build only measures the key path.')
        elseif MiningLayersGate.MODE == 'enforce' then
            MiningLayers.log('  Gate mode "enforce": Mining Layers stays inactive until a valid Download Key is provided.')
            MiningLayers.log('  Get your free key at fsmodworks.com (account required), save the .xml into the mods folder, then restart the game.')
        end
    end
end

return MiningLayersGate
