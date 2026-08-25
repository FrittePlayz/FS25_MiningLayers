-- FsmwCrypto.lua — pure-Lua-5.1-Krypto fuer die FSMW-Aktivierung (M1, interop-
-- bewiesen gegen den fsmodworks-Server am 25.08.: 3 echt signierte Muster-Tokens
-- true, Negativ-Paar false, Fingerabdruck cd81f4f425184280 beidseitig gleich).
-- Wird per source() geladen und stellt sich als FsmwCrypto in die Mod-Umgebung.
-- TODO M3: SHA-256/XTEA auf native Engine-Bitops (bitXOR/bitShiftLeft) umstellen
-- (Faktor ~110); fuer die einmalige Aktivierung (<150 ms) reicht pure Lua.
-- Nur Fließkomma-Arithmetik (Werte < 2^53), keine nativen Bitops, keine // -Division.
-- Enthält: SHA-256, Bignum (24-Bit-Limbs) mit Montgomery-Modexp, RSA-PKCS#1-v1.5-Verify.
local M = {}

local floor = math.floor

--------------------------------------------------------------------------------
-- SHA-256 (arithmetisch, 32-Bit-Wörter als Zahlen 0..2^32-1)
--------------------------------------------------------------------------------
local function u32(x) return x % 4294967296 end

-- bitweise Ops über Arithmetik
local function band(a, b)
    local r, p = 0, 1
    for _ = 1, 32 do
        local ra, rb = a % 2, b % 2
        if ra == 1 and rb == 1 then r = r + p end
        a = (a - ra) / 2; b = (b - rb) / 2; p = p * 2
    end
    return r
end
local function bxor(a, b)
    local r, p = 0, 1
    for _ = 1, 32 do
        local ra, rb = a % 2, b % 2
        if ra ~= rb then r = r + p end
        a = (a - ra) / 2; b = (b - rb) / 2; p = p * 2
    end
    return r
end
local function bnot(a) return 4294967295 - a end
local function rrot(x, n)
    local lo = x % (2 ^ n)
    return floor(x / (2 ^ n)) + lo * (2 ^ (32 - n))
end
local function shr(x, n) return floor(x / (2 ^ n)) end

local K = {
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}

function M.sha256(msg)
    local h0,h1,h2,h3 = 0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a
    local h4,h5,h6,h7 = 0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19
    local len = #msg
    local bitlen = len * 8
    msg = msg .. string.char(0x80)
    while (#msg % 64) ~= 56 do msg = msg .. string.char(0) end
    -- 64-Bit-Länge (obere 32 Bit hier 0 für unsere kurzen Payloads)
    local hi = floor(bitlen / 4294967296)
    local lo = bitlen % 4294967296
    local function be32(x) return string.char(band(shr(x,24),255),band(shr(x,16),255),band(shr(x,8),255),band(x,255)) end
    msg = msg .. be32(hi) .. be32(lo)

    local w = {}
    for i = 1, #msg, 64 do
        for t = 0, 15 do
            local o = i + t*4
            w[t] = string.byte(msg,o)*16777216 + string.byte(msg,o+1)*65536 + string.byte(msg,o+2)*256 + string.byte(msg,o+3)
        end
        for t = 16, 63 do
            local s0 = bxor(bxor(rrot(w[t-15],7), rrot(w[t-15],18)), shr(w[t-15],3))
            local s1 = bxor(bxor(rrot(w[t-2],17), rrot(w[t-2],19)), shr(w[t-2],10))
            w[t] = u32(w[t-16] + s0 + w[t-7] + s1)
        end
        local a,b,c,d,e,f,g,h = h0,h1,h2,h3,h4,h5,h6,h7
        for t = 0, 63 do
            local S1 = bxor(bxor(rrot(e,6), rrot(e,11)), rrot(e,25))
            local ch = bxor(band(e,f), band(bnot(e),g))
            local t1 = u32(h + S1 + ch + K[t+1] + w[t])
            local S0 = bxor(bxor(rrot(a,2), rrot(a,13)), rrot(a,22))
            local maj = bxor(bxor(band(a,b), band(a,c)), band(b,c))
            local t2 = u32(S0 + maj)
            h=g; g=f; f=e; e=u32(d+t1); d=c; c=b; b=a; a=u32(t1+t2)
        end
        h0=u32(h0+a); h1=u32(h1+b); h2=u32(h2+c); h3=u32(h3+d)
        h4=u32(h4+e); h5=u32(h5+f); h6=u32(h6+g); h7=u32(h7+h)
    end
    local function hx(x) return string.format("%08x", x) end
    return hx(h0)..hx(h1)..hx(h2)..hx(h3)..hx(h4)..hx(h5)..hx(h6)..hx(h7)
end

--------------------------------------------------------------------------------
-- Bignum: Little-Endian-Array von 24-Bit-Limbs. Montgomery-Modexp.
--------------------------------------------------------------------------------
local BASE = 16777216          -- 2^24
local LIMB_BITS = 24

local function hex2bn(hex)
    hex = hex:gsub("%s", "")
    if #hex % 2 == 1 then hex = "0"..hex end
    -- Bytes big-endian -> Limbs little-endian, 3 Bytes = 1 Limb (24 Bit)
    local bytes = {}
    for i = #hex-1, 1, -2 do
        bytes[#bytes+1] = tonumber(hex:sub(i,i+1), 16)
    end
    local bn = {}
    local i = 1
    while i <= #bytes do
        local b0 = bytes[i] or 0
        local b1 = bytes[i+1] or 0
        local b2 = bytes[i+2] or 0
        bn[#bn+1] = b0 + b1*256 + b2*65536
        i = i + 3
    end
    while #bn > 1 and bn[#bn] == 0 do bn[#bn] = nil end
    return bn
end

local function bnlen(a) return #a end

-- a und b gleiche Länge n; klassische Montgomery CIOS. Rückgabe a*b*R^-1 mod m.
local function mont_mul(a, b, m, n, mp)
    local t = {}
    for i = 1, n+2 do t[i] = 0 end
    for i = 1, n do
        local ai = a[i] or 0
        -- t = t + ai*b
        local carry = 0
        for j = 1, n do
            local s = t[j] + ai * (b[j] or 0) + carry
            local lo = s % BASE
            carry = (s - lo) / BASE
            t[j] = lo
        end
        local s = t[n+1] + carry
        t[n+1] = s % BASE
        t[n+2] = t[n+2] + (s - (s % BASE)) / BASE
        -- u = (t[1] * mp) mod BASE
        local u = (t[1] * mp) % BASE
        -- t = t + u*m, dann durch BASE teilen (Shift)
        carry = 0
        local s0 = t[1] + u * (m[1] or 0)
        carry = (s0 - (s0 % BASE)) / BASE
        for j = 2, n do
            local ss = t[j] + u * (m[j] or 0) + carry
            local lo = ss % BASE
            carry = (ss - lo) / BASE
            t[j-1] = lo
        end
        local ss = t[n+1] + carry
        t[n] = ss % BASE
        carry = (ss - (ss % BASE)) / BASE
        t[n+1] = t[n+2] + carry
        t[n+2] = 0
    end
    -- Ergebnis in t[1..n+1]; finale Subtraktion falls t >= m
    local ge = false
    if (t[n+1] or 0) > 0 then ge = true else
        for i = n, 1, -1 do
            local ti, mi = t[i] or 0, m[i] or 0
            if ti ~= mi then ge = ti > mi; break end
        end
    end
    local r = {}
    if ge then
        local borrow = 0
        for i = 1, n do
            local d = (t[i] or 0) - (m[i] or 0) - borrow
            if d < 0 then d = d + BASE; borrow = 1 else borrow = 0 end
            r[i] = d
        end
    else
        for i = 1, n do r[i] = t[i] or 0 end
    end
    return r
end

-- mp = -m^-1 mod 2^24  (nur unterstes Limb nötig)
local function mont_np(m0)
    -- inverse von m0 mod 2^24 via Newton, dann negieren
    local inv = 1
    for _ = 1, 5 do          -- 2^1,2^2,... reicht für 24 Bit in wenigen Schritten
        inv = (inv * (2 - (m0 * inv) % BASE)) % BASE
    end
    return (BASE - inv) % BASE
end

-- 2^bits mod m  per Verdopplung (einmalig, kein Division-Bignum nötig)
local function mod_pow2(m, n, bits)
    local a = {}
    for i = 1, n do a[i] = 0 end
    a[1] = 1
    local function dbl_mod()
        local carry = 0
        for i = 1, n do
            local s = a[i]*2 + carry
            local lo = s % BASE; carry = (s - lo)/BASE; a[i] = lo
        end
        -- reduce falls a >= m
        local ge = carry > 0
        if not ge then
            for i = n, 1, -1 do
                if a[i] ~= (m[i] or 0) then ge = a[i] > (m[i] or 0); break end
            end
        end
        if ge then
            local borrow = 0
            for i = 1, n do
                local d = a[i] - (m[i] or 0) - borrow
                if d < 0 then d = d + BASE; borrow = 1 else borrow = 0 end
                a[i] = d
            end
        end
    end
    for _ = 1, bits do dbl_mod() end
    return a
end

-- RSA-Verify-Kern: s^e mod m mit e = 65537. Rückgabe als big-endian hex, n*3 Bytes.
function M.rsa_powmod_65537(s_hex, m_hex)
    local m = hex2bn(m_hex)
    local n = bnlen(m)
    local s = hex2bn(s_hex)
    for i = 1, n do s[i] = s[i] or 0 end
    local mp = mont_np(m[1])
    -- R2 = 2^(2*24*n) mod m  (direkt per Verdopplung, keine Division)
    local R2 = mod_pow2(m, n, 2 * LIMB_BITS * n)

    -- s in Montgomery-Form: sm = s * R2 * R^-1 = s * R mod m
    local sm = mont_mul(s, R2, m, n, mp)
    -- e = 65537 = 2^16 + 1 -> 16 Quadrate + 1 Mult mit sm
    local acc = sm
    for _ = 1, 16 do acc = mont_mul(acc, acc, m, n, mp) end
    acc = mont_mul(acc, sm, m, n, mp)
    -- aus Montgomery zurück: mont(acc, 1)
    local one = {}; for i=1,n do one[i]=0 end; one[1]=1
    local res = mont_mul(acc, one, m, n, mp)
    -- als big-endian hex (n Limbs a 3 Byte)
    local bytes = {}
    for i = n, 1, -1 do
        local v = res[i] or 0
        local b2 = floor(v/65536) % 256
        local b1 = floor(v/256) % 256
        local b0 = v % 256
        bytes[#bytes+1] = string.format("%02x%02x%02x", b2, b1, b0)
    end
    return table.concat(bytes)
end

--------------------------------------------------------------------------------
-- PKCS#1 v1.5 SHA-256 Verify: em = s^e mod n; prüfe 00 01 FF..FF 00 DigestInfo(SHA256) H
--------------------------------------------------------------------------------
local SHA256_DIGESTINFO = "3031300d060960864801650304020105000420"  -- 19 Bytes hex

function M.rsa_verify_sha256(payload, sig_hex, n_hex)
    local em = M.rsa_powmod_65537(sig_hex, n_hex)   -- hex, führende 00 wird zu "0000.."
    -- em hat n*3 Bytes; echte EM ist 256 Byte. Nimm die letzten 256 Byte (512 hex).
    em = em:sub(#em - 511)
    -- erwartete Struktur: 0001 FF..FF 00 <digestinfo><hash>
    local hash = M.sha256(payload)
    local tail = "00" .. SHA256_DIGESTINFO .. hash        -- 1 + 19 + 32 = 52 Byte -> 104 hex
    if em:sub(1,4) ~= "0001" then return false, "prefix", em:sub(1,8) end
    if em:sub(#em - #tail + 1) ~= tail then return false, "digest", em:sub(#em-103) end
    -- dazwischen nur FF
    local pad = em:sub(5, #em - #tail)
    if pad:find("[^Ff]") then return false, "padding" end
    if #pad < 16 then return false, "padtooshort" end
    return true, "ok"
end

--------------------------------------------------------------------------------
-- base64url-Dekodierung (pure Lua) + Token-Verify im Percy-Format
--   token = base64url(payloadJSON) .. "." .. base64url(signatur256)
--------------------------------------------------------------------------------
local B64_URL = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local B64_DEC = nil
local function b64url_decode(s)
    if B64_DEC == nil then
        B64_DEC = {}
        for i = 1, #B64_URL do B64_DEC[B64_URL:sub(i,i)] = i - 1 end
    end
    s = s:gsub("[^A-Za-z0-9%-_]", "")   -- Padding/Whitespace weg (base64url hat kein '=')
    local out = {}
    local acc, bits = 0, 0
    for i = 1, #s do
        local v = B64_DEC[s:sub(i,i)]
        if v ~= nil then
            acc = acc * 64 + v
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                local byte = floor(acc / (2 ^ bits)) % 256
                out[#out+1] = string.char(byte)
                acc = acc % (2 ^ bits)          -- verbrauchte High-Bits kappen (sonst Double-Overflow)
            end
        end
    end
    return table.concat(out)
end

---Fingerabdruck des Modulus: sha256(hex-string)[:16] — muss zum eingebauten Wert passen.
function M.key_fingerprint(modulus_hex)
    return M.sha256(modulus_hex):sub(1, 16)
end

---Verifiziert einen Token gegen den Modulus. Rückgabe: ok(bool), payloadString|reason.
function M.verify_token(token, modulus_hex)
    local dot = token:find(".", 1, true)
    if dot == nil then return false, "noDot" end
    local payload = b64url_decode(token:sub(1, dot - 1))
    local sigbin  = b64url_decode(token:sub(dot + 1))
    if #sigbin ~= 256 then return false, "sigLen=" .. #sigbin end
    -- sig-bytes -> hex
    local hx = {}
    for i = 1, #sigbin do hx[i] = string.format("%02x", string.byte(sigbin, i)) end
    local sig_hex = table.concat(hx)
    local ok = M.rsa_verify_sha256(payload, sig_hex, modulus_hex)
    if not ok then return false, "badSig" end
    return true, payload
end

---Zieht Felder aus dem kanonischen Payload (kein voller JSON-Parser nötig).
function M.parse_payload(payload)
    local t = {}
    t.memberId = payload:match('"memberId":"(.-)"')
    t.product  = payload:match('"product":"(.-)"')
    t.issued   = tonumber(payload:match('"issued":(%d+)'))
    t.rkey     = payload:match('"rkey":"(%x+)"')
    t.wm       = payload:match('"wm":"(%x+)"')
    return t
end

--------------------------------------------------------------------------------
-- XTEA im CTR-Modus (Blob-Chiffre). Schlüssel = 4x 32-Bit-Wörter.
-- Ent- und Verschlüsseln identisch (Keystream-XOR). 32 Runden.
--------------------------------------------------------------------------------
local function shl(x, n) return u32(x * (2 ^ n)) end
local function add32(a, b) return u32(a + b) end

local function xtea_encrypt_block(v0, v1, key)
    local sum = 0
    local delta = 0x9E3779B9
    for _ = 1, 32 do
        v0 = add32(v0, bxor(bxor(add32(shl(v1,4), key[(sum % 4)+1]),
                                 add32(v1, sum)),
                            add32(shr(v1,5), key[(band(shr(sum,11),3))+1])))
        sum = add32(sum, delta)
        v1 = add32(v1, bxor(bxor(add32(shl(v0,4), key[(band(sum,3))+1]),
                                 add32(v0, sum)),
                            add32(shr(v0,5), key[(band(shr(sum,11),3))+1])))
    end
    return v0, v1
end

-- data: binärer String; key: 4-Element-Array 32-Bit; nonce: 2 Wörter (Startzähler)
function M.xtea_ctr(data, key, n0, n1)
    local out = {}
    local blocks = math.ceil(#data / 8)
    local c0, c1 = n0 or 0, n1 or 0
    local pos = 1
    for _ = 1, blocks do
        local k0, k1 = xtea_encrypt_block(c0, c1, key)
        local ks = { band(shr(k0,24),255),band(shr(k0,16),255),band(shr(k0,8),255),band(k0,255),
                     band(shr(k1,24),255),band(shr(k1,16),255),band(shr(k1,8),255),band(k1,255) }
        for j = 1, 8 do
            local b = string.byte(data, pos)
            if b == nil then break end
            out[#out+1] = string.char(bxor(b, ks[j]))
            pos = pos + 1
        end
        c1 = add32(c1, 1)
        if c1 == 0 then c0 = add32(c0, 1) end
    end
    return table.concat(out)
end

-- KDF: aus verifiziertem Payload-Feld (rkey hex) + Release-Salt -> 128-Bit XTEA-Key (4 Wörter).
-- Bindet an SHA-256(rkey .. "|" .. salt); nimmt die ersten 16 Byte.
function M.derive_key(rkey_hex, salt)
    local h = M.sha256(rkey_hex .. "|" .. salt)   -- 64 hex
    local key = {}
    for i = 0, 3 do
        key[i+1] = tonumber(h:sub(i*8+1, i*8+8), 16)
    end
    return key
end

FsmwCrypto = M

return M
