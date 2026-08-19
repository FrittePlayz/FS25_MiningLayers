--
-- Sponsorschild am Grubenrand.
--
-- Kein eigenes Modell: geladen wird ein Schild des Basisspiels ueber seinen
-- $data-Pfad, ueberschrieben wird nur die Logo-Textur. Das Schild bringt dafuer
-- alles mit, was wir brauchen - eigener Shape 'decalLogo' mit separater Textur,
-- zwei Detailstufen und eine Kollision.
--
-- Rein sichtbares Objekt, jeder Client baut es sich aus den Zonen selbst auf.
-- Deshalb kein Netzwerk-Abgleich noetig; auf einem dedizierten Server ohne
-- Client wird gar nichts gespawnt.
--

---@diagnostic disable: lowercase-global, undefined-global

---Schild des Basisspiels. Die Datei wird NICHT mitgeliefert - das waere weder
---erlaubt noch noetig. $data versteht nur der XML-Lader; vor loadSharedI3DFile
---muss der Pfad durch Utils.getFilename (TerraFarm uebergibt aus demselben
---Grund fertige Pfade).
MiningLayers.SIGN_I3D = '$data/maps/mapUS/textures/props/signCompany01.i3d'

---Name des Shapes, der die austauschbare Logotafel traegt.
MiningLayers.SIGN_LOGO_NODE = 'decalLogo'

---Unsere Tafel. 1024x256 wie die Vorlage, aber die Vorlage ist ein ATLAS:
---die Tafel am Schild zeigt nur x 0-540 (~2:1), ab x 583 liegt eine zweite
---Variante fuer andere Shapes. Vollflaechige Grafik wird deshalb rechts
---abgeschnitten (Fund 2026-08-09, Tommys Sichttest) - Inhalt muss in die
---Fenster des Werkslogos (farmHouse01Logo_diffuse) gesetzt werden.
---DDS zuerst (Mipmaps, kleiner), PNG als Rueckfall. Aktuell nur PNG an Bord:
---kein DDS-Packer auf dem Rechner, Neubau steht aus.
MiningLayers.SIGN_TEXTURES = {
    'data/textures/farmersingles_logo_1024x256.dds',
    'data/textures/farmersingles_logo_1024x256.png',
}

---Dateiname der Logotafel, die das Basisspiel-Schild ab Werk traegt. Damit
---finden wir den richtigen Material-Index, statt ihn zu raten.
MiningLayers.SIGN_STOCK_LOGO = 'farmHouse01Logo'

---Abstand nach aussen vom Eckpunkt, damit das Schild nie im Abbaubereich steht
---und nach dem Graben nicht in der Luft haengt.
MiningLayers.SIGN_OUTSET = 3.0

---Unter dieser Kantenlaenge lohnt sich kein Schild.
MiningLayers.SIGN_MIN_AREA_SIZE = 10.0

---Ein Schild pro Bereich: uniqueId -> Szenenknoten.
MiningLayers.signNodes = {}

---Dazu die Anforderungs-Nummer aus loadSharedI3DFile. Ohne sie laesst sich der
---Eintrag im I3D-Manager nicht freigeben; delete() raeumt nur den Szenenknoten.
MiningLayers.signRequests = {}

---Schalter aus der miningLayers.xml.
MiningLayers.sponsorSign = true

---Nur einmal meckern, wenn das Basisspiel-Schild fehlt.
MiningLayers.signLoadFailed = false

---Sucht rekursiv einen Kindknoten anhand seines Namens.
---@param node number
---@param name string
---@return number?
local function findChildByName(node, name)
    if node == nil or node == 0 then
        return nil
    end

    if getName(node) == name then
        return node
    end

    for i = 0, getNumOfChildren(node) - 1 do
        local found = findChildByName(getChildAt(node, i), name)

        if found ~= nil then
            return found
        end
    end

    return nil
end

---Erste vorhandene Tafel-Datei (DDS vor PNG).
---@return string?
local function findSignTexture()
    for _, relative in ipairs(MiningLayers.SIGN_TEXTURES) do
        local path = MiningLayers.MOD_DIRECTORY .. relative

        if not MiningLayers.isCallable(fileExists) or fileExists(path) then
            return path
        end
    end

    return nil
end

---Sucht den Material-Index, der die Werks-Logotafel traegt. Raten waere hier
---falsch: der Shape hat mehrere Materialien, und wir wollen genau das eine.
---@param shape number
---@return number?
local function findLogoMaterialIndex(shape)
    if not MiningLayers.isCallable(getMaterialDiffuseMapFilename) then
        -- Ohne Namensabgleich bleibt nur der erste Slot.
        return 0
    end

    for index = 0, 7 do
        local ok, material = pcall(getMaterial, shape, index)

        if not ok or material == nil or material == 0 then
            break
        end

        local okName, name = pcall(getMaterialDiffuseMapFilename, material)

        if okName and type(name) == 'string' and name:find(MiningLayers.SIGN_STOCK_LOGO, 1, true) then
            return index
        end
    end

    return nil
end

---Tauscht die Logotafel gegen unsere Textur.
---
---★ sharedEdit MUSS false sein. Das Schild kommt aus einem geteilten i3d; mit
---true wuerde das Material an Ort und Stelle geaendert und JEDES
---signCompany01 der Karte traegt unser Logo. Mit false kommt eine neue
---Material-ID zurueck, die nur auf unseren Shape gesetzt wird.
---Muster wie im Basisspiel (VehicleMaterial.lua), Signatur von Percy gegen die
---GDN-Doku verifiziert:
---setMaterialDiffuseMapFromFile(materialId, filename, textueWrap, isSRGB, sharedEdit)
---@param node number Wurzel des geladenen Schilds
---@return boolean ok
local function applyLogoTexture(node)
    local target = findChildByName(node, MiningLayers.SIGN_LOGO_NODE)

    if target == nil then
        MiningLayers.log('Sign: node "%s" not found.', MiningLayers.SIGN_LOGO_NODE)
        return false
    end

    if not MiningLayers.isCallable(getMaterial)
        or not MiningLayers.isCallable(setMaterial)
        or not MiningLayers.isCallable(setMaterialDiffuseMapFromFile) then
        MiningLayers.log('Sign: the engine offers no texture swap.')
        return false
    end

    local path = findSignTexture()

    if path == nil then
        MiningLayers.log('Sign: board texture missing.')
        return false
    end

    local index = findLogoMaterialIndex(target)

    if index == nil then
        MiningLayers.log('Sign: no material containing "%s" found.', MiningLayers.SIGN_STOCK_LOGO)
        return false
    end

    local applied = false

    MiningLayers.protectedCall('applyLogoTexture', function()
        local material = getMaterial(target, index)

        if material == nil or material == 0 then
            return
        end

        local newMaterial = setMaterialDiffuseMapFromFile(material, path, false, true, false)

        if newMaterial == nil or newMaterial == 0 then
            return
        end

        if newMaterial ~= material then
            setMaterial(target, newMaterial, index)
        end

        applied = true
    end)

    return applied
end

---Mittelpunkt und groesste Kantenlaenge eines Bereichs.
---@param area table
---@return number? cx
---@return number? cz
---@return number size
local function areaCenter(area)
    local points = area ~= nil and area.points or nil

    if type(points) ~= 'table' or #points < 3 then
        return nil, nil, 0
    end

    local sumX, sumZ = 0, 0
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge

    local count = 0

    for _, p in ipairs(points) do
        -- Bereichspunkte sind Weltkoordinaten: [1] = X, [3] = Z.
        -- Geprueft wird wie ueberall sonst im Mod (computeSurfaceY & Co.) -
        -- ohne die Pruefung wirft ein unvollstaendiger Punkt mitten heraus.
        if type(p) == 'table' and type(p[1]) == 'number' and type(p[3]) == 'number' then
            local x, z = p[1], p[3]

            count = count + 1
            sumX, sumZ = sumX + x, sumZ + z
            minX, maxX = math.min(minX, x), math.max(maxX, x)
            minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
        end
    end

    if count < 3 then
        return nil, nil, 0
    end

    return sumX / count, sumZ / count, math.max(maxX - minX, maxZ - minZ)
end

---Alle Landscaping-Bereiche von TerraFarm.
---⚠️ Der Manager heisst g_landscapingManager, nicht g_landscapingAreaManager -
---mit dem falschen Namen kam beim Kartenstart still gar kein Schild.
---@return table
function MiningLayers.getLandscapingAreas()
    local manager = MiningLayers.tf('g_landscapingManager')

    if manager == nil then
        return {}
    end

    if MiningLayers.isCallable(manager.getAreas) then
        local ok, areas = pcall(manager.getAreas, manager)

        if ok and type(areas) == 'table' then
            return areas
        end
    end

    return type(manager.areas) == 'table' and manager.areas or {}
end

---Setzt ein Schild an den ersten Eckpunkt eines Bereichs, nach aussen versetzt
---und zur Grube gedreht.
---@param area table
---@return boolean
function MiningLayers:spawnSign(area)
    -- ⚠️ Jeder Ausstieg wird geloggt. Beim ersten Testlauf stand im log.txt zum
    -- Schild GAR NICHTS - weder Erfolg noch Fehler -, weil alle Abbruchpfade
    -- stumm waren. Ein stiller Abbruch ist beim Suchen wertlos.
    if not MiningLayers.sponsorSign then
        MiningLayers.log('Sign: skipped, sponsorSign is set to false.')
        return false
    end

    if g_client == nil then
        return false
    end

    if MiningLayers.signLoadFailed then
        return false
    end

    local id = area ~= nil and area.uniqueId or nil

    if id == nil then
        MiningLayers.log('Sign: area without a uniqueId, skipped.')
        return false
    end

    if MiningLayers.signNodes[id] ~= nil then
        return false
    end

    local centerX, centerZ, size = areaCenter(area)

    if centerX == nil then
        -- Beim Anlegen meldet TerraFarm den Bereich, bevor der Spieler die Ecken
        -- gezogen hat. Das ist normal und kein Fehler: das UPDATE danach bringt
        -- uns wieder her, dann stehen die Punkte.
        local count = type(area.points) == 'table' and #area.points or 0

        if count > 0 then
            MiningLayers.log('Sign: area %s has %d points but no usable coordinates.',
                tostring(id), count)
        end

        return false
    end

    if size < MiningLayers.SIGN_MIN_AREA_SIZE then
        MiningLayers.log('Sign: area %s is too small at %.1f m (minimum %.1f m).',
            tostring(id), size, MiningLayers.SIGN_MIN_AREA_SIZE)
        return false
    end

    MiningLayers.log('Sign: building for area %s (edge length %.1f m).', tostring(id), size)

    local corner = area.points[1]
    local cornerX, cornerZ = corner[1], corner[3]

    -- Richtung Mitte -> Ecke, normiert, dann ueber die Ecke hinaus versetzen.
    local dx, dz = cornerX - centerX, cornerZ - centerZ
    local length = math.sqrt(dx * dx + dz * dz)

    if length < 0.01 then
        return false
    end

    dx, dz = dx / length, dz / length

    local x = cornerX + dx * MiningLayers.SIGN_OUTSET
    local z = cornerZ + dz * MiningLayers.SIGN_OUTSET

    if not MiningLayers.isCallable(g_i3DManager and g_i3DManager.loadSharedI3DFile) then
        MiningLayers.signLoadFailed = true
        return false
    end

    local node

    -- Bodenhoehe VOR dem Laden bestimmen: ohne sie brauchen wir gar nicht erst
    -- ein Modell in die Szene zu haengen. y=0 waere Meereshoehe und damit auf
    -- den meisten Karten tief im Berg.
    local terrainNode = g_terrainNode

    if terrainNode == nil and g_currentMission ~= nil then
        terrainNode = g_currentMission.terrainRootNode
    end

    if terrainNode == nil or not MiningLayers.isCallable(getTerrainHeightAtWorldPos) then
        MiningLayers.log('Sign: no terrain node available, area %s skipped.', tostring(id))
        return false
    end

    local y = getTerrainHeightAtWorldPos(terrainNode, x, 0, z)

    if type(y) ~= 'number' then
        MiningLayers.log('Sign: no terrain height at x=%.1f z=%.1f, area %s skipped.', x, z, tostring(id))
        return false
    end

    ---★ Alles ab hier in EINEM geschuetzten Block, und der Knoten wird sofort
    ---nach dem Verlinken in signNodes eingetragen. Vorher stand er zwischen
    ---link() und der Registrierung fuer einen Moment "herrenlos" in der Welt:
    ---brach etwas dazwischen ab, blieb ein unsichtbar gewordenes Schild stehen,
    ---die Duplikatsperre kannte es nicht, und der naechste Versuch stellte ein
    ---zweites an dieselbe Stelle.
    local node
    local requestId

    local ok = MiningLayers.protectedCall('loadSignI3D', function()
        local filename = MiningLayers.SIGN_I3D

        if Utils ~= nil and MiningLayers.isCallable(Utils.getFilename) then
            filename = Utils.getFilename(filename)
        else
            filename = filename:gsub('^%$', '')
        end

        local root, request = g_i3DManager:loadSharedI3DFile(filename, false, false)

        requestId = request

        if root == nil or root == 0 then
            return
        end

        local child = getChildAt(root, 0)

        if child ~= nil and child ~= 0 then
            link(getRootNode(), child)

            -- Ab jetzt kennt removeSign den Knoten, egal was danach schiefgeht.
            node = child
            MiningLayers.signNodes[id] = child
            MiningLayers.signRequests[id] = requestId
        end

        delete(root)
    end)

    local function abort(reason, hard)
        MiningLayers:removeSign(id)

        if requestId ~= nil and node == nil and MiningLayers.isCallable(releaseSharedI3D) then
            pcall(releaseSharedI3D, requestId)
        end

        if hard then
            MiningLayers.signLoadFailed = true
        end

        MiningLayers.log('Sign: %s', reason)

        return false
    end

    if not ok or node == nil then
        -- Dateibezogener Fehler: das trifft jeden Bereich gleich, also einmal
        -- merken und Ruhe geben.
        return abort(string.format('%s could not be loaded - the feature stays off.',
            MiningLayers.SIGN_I3D), true)
    end

    -- Lieber kein Schild als eins mit dem fremden Logo der Vorlage.
    if not applyLogoTexture(node) then
        return abort('the logo could not be set - the feature stays off.', true)
    end

    local placed = MiningLayers.protectedCall('placeSign', function()
        setTranslation(node, x, y, z)
        -- Blick zurueck zur Grubenmitte.
        setRotation(node, 0, math.atan2(-dx, -dz), 0)
    end)

    if not placed then
        -- Nur dieser Bereich ist betroffen, nicht das Feature.
        return abort(string.format('area %s could not be placed.', tostring(id)), false)
    end

    MiningLayers.log('Sign: placed at x=%.1f z=%.1f (area %s).', x, z, tostring(id))

    return true
end

---@param id string|number
function MiningLayers:removeSign(id)
    local node = MiningLayers.signNodes[id]
    local request = MiningLayers.signRequests[id]

    MiningLayers.signNodes[id] = nil
    MiningLayers.signRequests[id] = nil

    if node ~= nil then
        pcall(delete, node)
    end

    -- Das geteilte i3d im Manager mit freigeben, sonst sammelt sich bei jedem
    -- Neusetzen eine weitere Referenz an.
    if request ~= nil and MiningLayers.isCallable(releaseSharedI3D) then
        pcall(releaseSharedI3D, request)
    end
end

function MiningLayers:removeAllSigns()
    for id in pairs(MiningLayers.signNodes) do
        MiningLayers:removeSign(id)
    end

    MiningLayers.signNodes = {}
    MiningLayers.signRequests = {}
end

---Setzt Schilder fuer alle bekannten Bereiche - fuer den Fall, dass der
---Schalter im laufenden Spiel eingeschaltet wird.
function MiningLayers:spawnSignsForAllAreas()
    if not MiningLayers.sponsorSign or g_client == nil then
        return
    end

    local areas = MiningLayers.getLandscapingAreas()

    for _, area in pairs(areas) do
        MiningLayers.protectedCall('spawnSign', function()
            MiningLayers:spawnSign(area)
        end)
    end
end

---Schalter umlegen. Wirkt sofort, ohne Neustart: aus heisst weg, ein heisst da.
---@param enabled boolean
function MiningLayers:setSponsorSignEnabled(enabled)
    enabled = enabled == true

    if MiningLayers.sponsorSign == enabled then
        return
    end

    MiningLayers.sponsorSign = enabled

    if enabled then
        MiningLayers.signLoadFailed = false
        MiningLayers:spawnSignsForAllAreas()
    else
        MiningLayers:removeAllSigns()
    end
end
