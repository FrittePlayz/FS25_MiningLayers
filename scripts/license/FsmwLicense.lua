--[[
    FsmwLicense.lua — FS Modworks Aktivierung (M2)

    Ein Modul für alle geschützten FSMW-Mods (DWA, Director's Cut, ML gated).
    Der Mod kennt frei/bezahlt NICHT — er prüft nur: gültige Signatur, richtiges
    Produkt, nicht gesperrt. Frei vs. bezahlt entscheidet allein die Website
    (wer einen Download Key erzeugen darf).

    Ablauf im Spiel (M2b/M5, hier abstrahiert über liest-Callback):
      1. Discovery: Download-Key-Datei im mods-Ordner ODER modSettings/FSMW/ finden.
      2. Token zwischen den Markern lesen, Signatur offline prüfen (Public Key eingebaut).
      3. Produkt + Sperrliste prüfen. Gültig -> Datei nach modSettings/FSMW/ kopieren.
      4. Ohne gültige Lizenz: Mod inaktiv + klare Meldung (kein stilles Nichtstun).

    Krypto kommt aus crypto51 (M1, interop-bewiesen gegen Percys Server).
    Im echten Mod: SHA-256/XTEA auf native Engine-Bitops umstellen (Faktor ~110).
]]

-- Im Spiel stellt scripts/license/FsmwCrypto.lua (per source() VOR dieser Datei
-- geladen) FsmwCrypto in die Mod-Umgebung; im Standalone-Test wird es injiziert.
local C = FsmwCrypto

-- Global in der Mod-Umgebung (FS25 kapselt Mod-Globals je Mod), wie MiningLayers.
FsmwLicense = {}
FsmwLicense.crypto = C

FsmwLicense.MARK_BEGIN = "--- DOWNLOAD KEY BEGINN ---"
FsmwLicense.MARK_END   = "--- DOWNLOAD KEY ENDE ---"

-- Eingebauter Public Key (RSA-2048, Percys echter Schlüssel). Fingerabdruck als Selbstschutz:
-- stimmt der Modulus nicht zum erwarteten Fingerabdruck, wird NICHT verifiziert (Key getauscht?).
FsmwLicense.PUBKEY_MODULUS = "dad6f4d5ccb573e71119aedefad687fe9262968a051a07f47d8bf1c56cf67b665b393096c81ac83d14f8bdd0da30637fa1958ad51ed635290e0b945b43c41ebcbe9d7370e9675ec66fc42596a97cfe4b972cc02ea9f12d70ced2e82ad143a2b45ca1daa9e06d93a8feeeb44041dc0561ae68a6ff42a21867d40ac179663bc8c583203c0d4f865c9922d6cfab40cb6da6f720a103472cff03b2d73eb229c6a2bb55841313fb60a0ada26a1cf48943248084ee74e0061047904e540e54a986b836ba637c1f5f1296c47e7e5a35e0f5a1fc6e063d9eff068304d7972927f654be3485a324329e6a3c508bf8a450c8eda0c9bbc73f2d13887d2526a50ce7922712d3"
FsmwLicense.PUBKEY_FINGERPRINT = "cd81f4f425184280"

-- Sperrliste: je Zeile "<wm>  <memberId>  [<product>]  [<issued>]" (aus
-- /admin/licenses in den Build gebacken).
--
-- ⚠️ Konstruktionsfehler-Fix (Percys Fund, 25.08.): wm UND memberId sind pro
-- Konto KONSTANT (wm ist absichtlich deterministisch aus der Konto-ID, damit
-- dieselbe Person bei Neuausstellung ihr Zeichen behaelt). Ein Match nur auf
-- wm/memberId sperrt darum bei jedem "Key neu ausstellen" (das den alten Key
-- widerruft) den RECHTMAESSIGEN Besitzer dauerhaft aus - auch jeden neuen Key.
-- Deshalb unterscheidet die Liste jetzt zwei Faelle ueber `issued` (steht
-- bereits im Payload und ist pro Ausstellung verschieden, Token-Format bleibt):
--   Zeile MIT issued  -> sperrt genau DIESE Ausstellung (Normalfall: alter
--                        Key nach Neuausstellung).
--   Zeile OHNE issued -> bewusste KONTOSPERRE (echter Missbrauch), trifft
--                        jeden Key des Kontos.
-- `product` (Spalte 3) wird mitgeprueft, wenn vorhanden: eine Sperre fuer ein
-- anderes Produkt trifft diesen Mod nicht.
FsmwLicense.REVOKED = {}   -- wird per FsmwLicense.loadRevoked(text) gefüllt

---Sperrliste aus dem Build-Textblock laden.
function FsmwLicense.loadRevoked(text)
    FsmwLicense.REVOKED = {}
    if type(text) ~= "string" then return end
    for line in (text .. "\n"):gmatch("(.-)\n") do
        local wm, member, product, issued = line:match("^%s*(%x+)%s+(%S+)%s*(%S*)%s*(%S*)")
        if wm ~= nil then
            FsmwLicense.REVOKED[#FsmwLicense.REVOKED + 1] = {
                wm = wm,
                memberId = member,
                product = (product ~= nil and product ~= "") and product or nil,
                issued = (issued ~= nil and issued ~= "") and issued or nil,
            }
        end
    end
end

---Token zwischen den Markern aus einem Dateiinhalt ziehen.
---@param content string
---@return string? token
function FsmwLicense.extractToken(content)
    if type(content) ~= "string" then return nil end
    local b = content:find(FsmwLicense.MARK_BEGIN, 1, true)
    local e = content:find(FsmwLicense.MARK_END, 1, true)
    if b == nil or e == nil or e <= b then return nil end
    local inner = content:sub(b + #FsmwLicense.MARK_BEGIN, e - 1)
    -- Token ist ein zusammenhängender base64url.base64url-String; Whitespace/Zeilen weg.
    inner = inner:gsub("%s+", "")
    if inner == "" then return nil end
    return inner
end

---Hauptprüfung. content = Inhalt der Download-Key-Datei, expectedProduct = z. B. "dig-with-anything".
---@return table result { ok=boolean, reason=string, payload=table? }
function FsmwLicense.check(content, expectedProduct)
    local C = FsmwLicense.crypto
    if C == nil then return { ok = false, reason = "noCrypto" } end

    -- Selbstschutz: eingebauter Public Key muss zum Fingerabdruck passen.
    if C.key_fingerprint(FsmwLicense.PUBKEY_MODULUS) ~= FsmwLicense.PUBKEY_FINGERPRINT then
        return { ok = false, reason = "keyTampered" }
    end

    local token = FsmwLicense.extractToken(content)
    if token == nil then return { ok = false, reason = "noToken" } end

    local ok, payloadOrReason = C.verify_token(token, FsmwLicense.PUBKEY_MODULUS)
    if not ok then return { ok = false, reason = "badSig" } end

    local p = C.parse_payload(payloadOrReason)
    if p.memberId == nil or p.product == nil then
        return { ok = false, reason = "badPayload" }
    end
    if expectedProduct ~= nil and p.product ~= expectedProduct then
        return { ok = false, reason = "wrongProduct", payload = p }
    end
    -- Sperrliste. Kontotreffer allein reicht NICHT: eine Zeile mit `issued`
    -- sperrt nur genau diese Ausstellung (siehe Blockkommentar bei REVOKED).
    for _, r in ipairs(FsmwLicense.REVOKED) do
        local accountHit = (p.wm ~= nil and r.wm == p.wm) or (r.memberId == p.memberId)
        local productHit = r.product == nil or r.product == p.product
        local issuedHit = r.issued == nil or tostring(r.issued) == tostring(p.issued)

        if accountHit and productHit and issuedHit then
            return { ok = false, reason = "revoked", payload = p }
        end
    end
    return { ok = true, reason = "ok", payload = p }
end

---Nutzer-Meldungen (DE/EN), wenig Text. Key = reason aus check().
FsmwLicense.MSG = {
    de = {
        noToken     = "Kein Download Key gefunden. Lege die Key-Datei in den mods-Ordner (fsmodworks.com).",
        badSig      = "Download Key ungueltig oder beschaedigt. Bitte neu von fsmodworks.com laden.",
        wrongProduct= "Dieser Download Key gehoert zu einem anderen Mod.",
        revoked     = "Dieser Download Key wurde gesperrt. Kontakt: fsmodworks.com.",
        keyTampered = "Mod beschaedigt (Signaturschluessel). Bitte sauber neu laden.",
        badPayload  = "Download Key unlesbar. Bitte neu von fsmodworks.com laden.",
        ok          = "Aktiviert.",
    },
    en = {
        noToken     = "No Download Key found. Put the key file in your mods folder (fsmodworks.com).",
        badSig      = "Download Key invalid or corrupted. Please re-download from fsmodworks.com.",
        wrongProduct= "This Download Key belongs to a different mod.",
        revoked     = "This Download Key has been revoked. Contact fsmodworks.com.",
        keyTampered = "Mod corrupted (signing key). Please reinstall cleanly.",
        badPayload  = "Download Key unreadable. Please re-download from fsmodworks.com.",
        ok          = "Activated.",
    },
}

function FsmwLicense.message(reason, lang)
    local t = FsmwLicense.MSG[lang] or FsmwLicense.MSG.en
    return t[reason] or FsmwLicense.MSG.en[reason] or reason
end

return FsmwLicense
