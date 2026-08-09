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

---Schild des Basisspiels. $data wird von der Engine aufgeloest, die Datei wird
---NICHT mitgeliefert - das waere weder erlaubt noch noetig.
MiningLayers.SIGN_I3D = '$data/maps/mapUS/textures/props/signCompany01.i3d'

---Name des Shapes, der die austauschbare Logotafel traegt.
MiningLayers.SIGN_LOGO_NODE = 'decalLogo'

---Unsere Tafel. Format 1024x256 (4:1) - exakt das Seitenverhaeltnis der
---Vorlage, die das Schild von Haus aus traegt. Eine 2:1-Grafik wuerde gestaucht.
---DDS zuerst (Mipmaps, kleiner), PNG als Rueckfall.
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
        MiningLayers.log('Schild: Knoten "%s" nicht gefunden.', MiningLayers.SIGN_LOGO_NODE)
        return false
    end

    if not MiningLayers.isCallable(getMaterial)
        or not MiningLayers.isCallable(setMaterial)
        or not MiningLayers.isCallable(setMaterialDiffuseMapFromFile) then
        MiningLayers.log('Schild: Engine bietet keinen Texturtausch an.')
        return false
    end

    local path = findSignTexture()

    if path == nil then
        MiningLayers.log('Schild: Tafel-Textur fehlt.')
        return false
    end

    local index = findLogoMaterialIndex(target)

    if index == nil then
        MiningLayers.log('Schild: kein Material mit "%s" gefunden.', MiningLayers.SIGN_STOCK_LOGO)
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

    for _, p in ipairs(points) do
        -- Bereichspunkte sind Weltkoordinaten: [1] = X, [3] = Z.
        local x, z = p[1], p[3]

        sumX, sumZ = sumX + x, sumZ + z
        minX, maxX = math.min(minX, x), math.max(maxX, x)
        minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
    end

    local count = #points

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
    if not MiningLayers.sponsorSign or g_client == nil or MiningLayers.signLoadFailed then
        return false
    end

    local id = area ~= nil and area.uniqueId or nil

    if id == nil or MiningLayers.signNodes[id] ~= nil then
        return false
    end

    local centerX, centerZ, size = areaCenter(area)

    if centerX == nil or size < MiningLayers.SIGN_MIN_AREA_SIZE then
        return false
    end

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

    local loaded = MiningLayers.protectedCall('loadSignI3D', function()
        local root = g_i3DManager:loadSharedI3DFile(MiningLayers.SIGN_I3D, false, false)

        if root == nil or root == 0 then
            return
        end

        node = getChildAt(root, 0)

        if node ~= nil and node ~= 0 then
            link(getRootNode(), node)
        end

        delete(root)
    end)

    if not loaded or node == nil or node == 0 then
        MiningLayers.signLoadFailed = true
        MiningLayers.log('Schild: %s liess sich nicht laden - Feature bleibt aus.', MiningLayers.SIGN_I3D)
        return false
    end

    -- Lieber kein Schild als eins mit dem fremden Logo der Vorlage.
    if not applyLogoTexture(node) then
        pcall(delete, node)
        MiningLayers.signLoadFailed = true
        MiningLayers.log('Schild: Logo liess sich nicht setzen - Feature bleibt aus.')
        return false
    end

    local y = 0

    if g_currentMission ~= nil and MiningLayers.isCallable(getTerrainHeightAtWorldPos) then
        y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
    end

    setTranslation(node, x, y, z)

    -- Blick zurueck zur Grubenmitte.
    setRotation(node, 0, math.atan2(-dx, -dz), 0)

    MiningLayers.signNodes[id] = node

    return true
end

---@param id string|number
function MiningLayers:removeSign(id)
    local node = MiningLayers.signNodes[id]

    if node == nil then
        return
    end

    MiningLayers.signNodes[id] = nil

    pcall(delete, node)
end

function MiningLayers:removeAllSigns()
    for id in pairs(MiningLayers.signNodes) do
        MiningLayers:removeSign(id)
    end

    MiningLayers.signNodes = {}
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
