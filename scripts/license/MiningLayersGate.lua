--[[
    MiningLayersGate.lua — Aktivierung fuer Mining Layers (1.6.2).

    Mining Layers bleibt GRATIS. Der Download Key kostet nichts (fsmodworks.com,
    Konto + Selbst-Abholen) und dient Herkunftsnachweis/Wasserzeichen gegen
    Re-Uploads — keine Zahlungskopplung, der Mod kennt frei/bezahlt nicht
    (das entscheidet allein die Website; GIANTS-ToS-Einordnung im Vault).

    Ablauf: Key-Datei finden (modSettings/FSMW/ zuerst, dann mods-Ordner),
    Token zwischen den DOWNLOAD-KEY-Markern lesen, Signatur offline pruefen
    (RSA-2048, Public Key eingebaut, Fingerabdruck-Selbstcheck), Produkt +
    Sperrliste pruefen. Gueltige Datei aus dem mods-Ordner wird nach
    modSettings/FSMW/ uebernommen (ueberlebt dort Mod-Updates).

    ⚠️ MODE 'report' (Testbuild): prueft und MELDET nur (Log + HUD-Zeile),
    blockt nicht. Messstand 25.08. (Tommys erster Start, 1.6.2.0):
      - getUserProfileAppPath + createFolder + getFiles laufen (FSMW-Ordner
        wurde angelegt, Discovery lief).
      - io.open LEERT die Datei statt sie zu lesen -> entfernt, siehe readFile.
        Die Key-Datei ist deshalb ein XML (<downloadKey>), gelesen ueber die
        korpus-bewiesene XML-API.
    Offen bleibt copyFile (Uebernahme nach FSMW/) - erst wenn auch das am
    lebenden Spiel bewiesen ist, wird der oeffentliche Build auf 'enforce'
    gestellt (ohne gueltigen Key Mod inaktiv).
]]

---@diagnostic disable: lowercase-global, undefined-global

MiningLayersGate = {}

---Produkt-Slug wie auf fsmodworks (Percys LICENSED_PRODUCTS; DWA-Muster
---'dig-with-anything'). Mit Percy im Kanal abgeglichen, bevor 'enforce' kommt.
MiningLayersGate.PRODUCT = 'mining-layers'

---'report' = pruefen + melden, nicht blocken (Testbuild).
---'enforce' = ohne gueltigen Key bleibt der Mod inaktiv (oeffentlicher Build).
MiningLayersGate.MODE = 'report'

---Sperrliste, je Build aus /admin/licenses eingebacken (Zeilen "<wm> <memberId>").
MiningLayersGate.REVOKED_TEXT = ''

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
        -- dort ueberlebt sie Mod-Updates und liegt fuer alle FSMW-Mods bereit.
        local settingsDir = MiningLayersGate.getSettingsDir()

        if settingsDir ~= nil and bestPath ~= nil
            and bestPath:sub(1, #settingsDir) ~= settingsDir
            and MiningLayers.isCallable(copyFile) then
            local target = settingsDir .. 'fsmodworks-download-key.xml'
            local okCopy = pcall(copyFile, bestPath, target, true)

            MiningLayers.log('Download Key: copied to %s (%s).', target, okCopy and 'ok' or 'copy failed')
        end
    else
        MiningLayers.log('Download Key: NOT valid (%s) - %s',
            tostring(MiningLayersGate.result.reason), MiningLayersGate.getMessage())

        if MiningLayersGate.MODE == 'report' then
            MiningLayers.log('  Gate mode "report": the mod keeps working, this build only measures the key path.')
        end
    end
end

return MiningLayersGate
