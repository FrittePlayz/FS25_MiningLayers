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
    blockt nicht. Zwei Dinge sind am lebenden Spiel unbewiesen und werden hier
    zuerst gemessen, statt sie zu raten (Regel vom 11.08.):
      1. ob die Engine io.open im Mod-Sandbox erlaubt (Weg 1) — sonst traegt
         nur der XML-Weg (Weg 2) und Percys Key-Download muss als .xml kommen;
      2. ob getFiles/copyFile sich wie im Korpus belegt verhalten.
    Das Log beantwortet beides ('Key file read via ...'). Erst danach wird der
    oeffentliche Build auf 'enforce' gestellt (ohne gueltigen Key Mod inaktiv).
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

---Dateiinhalt lesen - zwei Wege, weil unbewiesen ist, was die Engine erlaubt.
---@param path string
---@return string? content
---@return string? how 'io' | 'xml'
function MiningLayersGate.readFile(path)
    -- Weg 1: io.open. Standard-Lua, aber ob der Mod-Sandbox es durchlaesst,
    -- ist am Korpus NICHT belegt (605 Zips: kein einziger Treffer, was Fehlen
    -- ODER Nichtgebrauch heissen kann). pcall, damit ein fehlendes io kein
    -- Fehler mitten im Ladepfad ist.
    local okIo, content = pcall(function()
        local handle = io.open(path, 'rb')

        if handle == nil then
            return nil
        end

        local data = handle:read('*a')
        handle:close()

        return data
    end)

    if okIo and type(content) == 'string' and content ~= '' then
        return content, 'io'
    end

    -- Weg 2: XML. Traegt nur, wenn die Key-Datei ein XML mit <downloadKey>
    -- ist - der Marker-Text darf dabei im Element stehen, extractToken
    -- findet ihn in jedem String.
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
            local target = settingsDir .. 'fsmodworks-download-key.txt'
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
