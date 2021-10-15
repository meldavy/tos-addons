--dofile("../data/addon_d/bountyhud/bountyhud.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'bountyhud'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local BountyHud = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

BountyHud.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

BountyHud.Settings = {
    Position = {
        X = 400,
        Y = 400
    }
};

BountyHud.Default = {
    Height = 330,
    Width = 300,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
};

local loadedNearbyPath = false

function BOUNTYHUD_ON_INIT(addon, frame)
    BountyHud.addon = addon;
    BountyHud.frame = frame;
    -- load settings
    if not BountyHud.Loaded then
        local t, err = acutil.loadJSON(BountyHud.SettingsFileLoc, BountyHud.Settings);
        if err then
        else
            BountyHud.Settings = t;
            BountyHud.Loaded = true;
        end
    end

    addon:RegisterMsg('GAME_START', 'BOUNTYHUD_GAME_START');
    addon:RegisterMsg('MAP_CHARACTER_UPDATE', 'BOUNTYHUD_CHARACTER_UPDATE');
    addon:RegisterMsg('BOUNTYHUNT_MILESTONE_OPEN', 'BOUNTYHUD_BOUNTY_START');
    addon:RegisterMsg('BOUNTYHUNT_MILESTONE_CLOSE', 'BOUNTYHUD_BOUNTY_END');
    BountyHud.SetupHook(BOUNTYHUD_BOUNTYHUNT_MON_MARK, "UPDATE_BOUNTYHUNT_MON_MARK");
    -- initialize frame
    BOUNTYHUD_ON_FRAME_INIT(frame)
    loadedNearbyPath = false
end

function BOUNTYHUD_BOUNTYHUNT_MON_MARK(monhandle, x, y, z, isAlive, MonRank)
    BountyHud.ProcessBountyMonMark(monhandle, x, y, z, isAlive, MonRank)
end

function BountyHud.ProcessBountyMonMark(monhandle, x, y, z, isAlive, MonRank)
    base["UPDATE_BOUNTYHUNT_MON_MARK"](monhandle, x, y, z, isAlive, MonRank)
    local curMapID = session.GetMapID()
    local mapCls = GetClassByType("Map", curMapID);
    local mapName = mapCls.ClassName
    local frame = ui.GetFrame("bountyhud")
    local mapbox = frame:GetChild("mapbox");
    if isAlive == 1 and MonRank == 'Normal' then
        local icon = mapbox:GetChild("icon_" .. monhandle)
        if (icon == nil) then
            icon = mapbox:CreateOrGetControl("picture", "icon_" .. monhandle, 20, 20, ui.LEFT, ui.TOP, 0, 0, 0, 0);
            AUTO_CAST(icon)
            icon:SetImage("Acient_party")
            icon:SetEnableStretch(1)
        end
        local mapprop = geMapTable.GetMapProp(mapName);
        local mappos = mapprop:WorldPosToMinimapPos(x, z, mapbox:GetWidth(), mapbox:GetHeight());
        icon:SetOffset(mappos.x - 10, mappos.y - 10)
    elseif isAlive == 1 and MonRank == 'Boss' then
        local icon = mapbox:GetChild("icon_" .. monhandle)
        if (icon == nil) then
            icon = mapbox:CreateOrGetControl("picture", "icon_" .. monhandle, 20, 20, ui.LEFT, ui.TOP, 0, 0, 0, 0);
            AUTO_CAST(icon)
            icon:SetImage("Acient_party")
            icon:SetEnableStretch(1)
        end
        local mapprop = geMapTable.GetMapProp(mapName);
        local mappos = mapprop:WorldPosToMinimapPos(x, z, mapbox:GetWidth(), mapbox:GetHeight());

        icon:SetOffset(mappos.x - 10, mappos.y - 10)
    else
        local icon = mapbox:GetChild("icon_" .. monhandle)
        if (icon ~= nil) then
            icon:ShowWindow(0)
        end
    end
end

function BOUNTYHUD_BOUNTY_START(frame, msg, strarg, numarg)
    -- 바운티 시작할때 처음에 numarg == 0 로 시작이 되고, 그 이후로 대상맵이 정해짐.
    -- 그래서 처음에 0일땐 스킵 하고 그 이후에 id가 정해졌을때부터 실행 시작
    if(numarg ~= 0) then
        if (loadedNearbyPath == false) then
            frame:ShowWindow(1)
            BOUNTYHUD_HIGHLIGHT_NEAREST_PATH(tonumber(numarg))
        end
    end
end

function BOUNTYHUD_BOUNTY_END(frame)
    frame:ShowWindow(0)
    ui.DestroyFrame("compass");
    loadedNearbyPath = false
end

function BOUNTYHUD_CHARACTER_UPDATE(frame, msg, argStr, argNum)
    local myHandle = session.GetMyHandle()
    local map = frame:GetChildRecursively("map");
    local pos = info.GetPositionInMap(session.GetMyHandle(), map:GetWidth(), map:GetHeight());
    local my = frame:GetChildRecursively("my");
    AUTO_CAST(my)
    my:SetOffset(pos.x - my:GetWidth() / 2, pos.y - my:GetHeight() / 2);
    local mapprop = session.GetCurrentMapProp();
    local angle = info.GetAngle(myHandle) - mapprop.RotateAngle;
    my:SetAngle(angle);
    map:Invalidate()

    local compass = ui.GetFrame("compass")
    if (compass ~= nil) then
        local pointer = compass:GetChildRecursively("bountyPointer")
        if (pointer ~= nil) then
            AUTO_CAST(pointer)
            local x = pointer:GetUserIValue("x")
            local y = pointer:GetUserIValue("y")
            local z = pointer:GetUserIValue("z")
            local angle = info.GetDestPosAngle(x, y, z, session.GetMyHandle()) - mapprop.RotateAngle;
            pointer:SetAngle(angle)
        end

    end
end

function BOUNTYHUD_TEST_ADJACENT()
    local curMapID = session.GetMapID()
    local mapCls = GetClassByType("Map", curMapID);
    local mapName = mapCls.ClassName
    local adjacentMaps = BountyHud:GetAdjacentMaps(mapName)
    for k, v in pairs(adjacentMaps) do
        print(k)
    end
end

function BountyHud.GetAdjacentMaps(self, mapName)
    local mapCls = GetClass("Map", mapName);
    if (mapCls == nil) then
        return {}
    end
    local adjacentMaps = {}

    -- PhysicalLinkZone은 안쓰여서 업데이트가 안된듯. 정확하지가 않음.
    --local linkedZone = TryGetProp(mapCls, "PhysicalLinkZone");
    --for match in linkedZone:gmatch("([^/]+)") do
    --    adjacentMaps[match] = 1
    --end

    local mapName = mapCls.ClassName
    local mapprop = geMapTable.GetMapProp(mapName);
    local mongens = mapprop.mongens;
    local cnt = mongens:Count();
    for i = 0 , cnt - 1 do
        local MonProp = mongens:Element(i);
        local iconName = MonProp:GetMinimapIcon()
        if (iconName == 'minimap_portal' or iconName == 'minimap_erosion') then
            local warpCls = GetClass("Warp", MonProp:GetDialog());
            if (warpCls == nil) then
                for match in MonProp:GetDialog():gmatch("[a-zA-Z]+_(.*)") do
                    warpCls = GetClass("Warp", match);
                end
            end
            if (warpCls ~= nil) then
                local targetZone = TryGetProp(warpCls, "TargetZone", "None");
                if (targetZone ~= "None") then
                    adjacentMaps[targetZone] = 1
                end
            end
        end
    end
    return adjacentMaps
end


local search = 15

function BOUNTYHUD_HIGHLIGHT_NEAREST_PATH(destID)
    -- reset search state
    search = 15
    local mapprop = session.GetCurrentMapProp();

    local frame = ui.GetFrame("bountyhud")
    if (destID == 0) then
        return;
    end

    local curMapID = session.GetMapID()
    if (curMapID == destID) then
        return;
    end
    local mapCls = GetClassByType("Map", curMapID);
    local mapName = mapCls.ClassName

    local destMapCls = GetClassByType("Map", destID);
    local destMapName = destMapCls.ClassName

    local min = 99
    local icon = nil
    local adjacentMaps = BountyHud:GetAdjacentMaps(mapName)
    local mapmapname = ""
    local nextMapCls
    for k, v in pairs(adjacentMaps) do
        local pathLength = BOUNTYHUD_RECURSIVE_SHORTEST_PATH(k, 0, destMapName)
        if (pathLength ~= nil and pathLength < min) then
            icon = frame:GetChildRecursively("icon_" .. k)
            if (icon ~= nil) then
                min = pathLength
                frame:SetUserValue("destination", k)
                nextMapCls = GetClass("Map", k)
                mapmapname = k
            end
        end
    end

    if (icon ~= nil) then
        AUTO_CAST(icon)
        icon:SetBlink(0.0, 1.0, "FFFF5555");
        icon:Resize(30, 30);
        local x = icon:GetUserIValue("x")
        local y = icon:GetUserIValue("y")
        icon:SetOffset(x - 15, y - 15)
        icon:SetImage("minimap_2_PERIOD")
        local compass = ui.GetFrame("compass")
        if (compass == nil) then
            compass = ui.CreateNewFrame("bountyhud", "compass");
            compass:Resize(200, 70)
            compass:SetSkinName("None")
            compass:SetLayerLevel(22); -- 콜리니 hud 위에 표시

            local bountyIcon = compass:CreateOrGetControl("picture", "bountyIcon", 30, 30, ui.CENTER_HORZ, ui.TOP, 0, 10, 0, 0);
            AUTO_CAST(bountyIcon)
            bountyIcon:SetImage("minimap_2_PERIOD");
            bountyIcon:SetEnableStretch(1)

            local worldx = icon:GetUserIValue("worldpos_x")
            local worldy = icon:GetUserIValue("worldpos_y")
            local worldz = icon:GetUserIValue("worldpos_z")

            local angle = info.GetDestPosAngle(worldx, worldy, worldz, session.GetMyHandle()) - mapprop.RotateAngle;

            local bountyPointer = compass:CreateOrGetControl("picture", "bountyPointer", 50, 50, ui.CENTER_HORZ, ui.TOP, 0, 0, 0, 0);
            AUTO_CAST(bountyPointer)
            bountyPointer:SetImage("npc_guide_arrow_x2");
            bountyPointer:SetAngle(angle)
            bountyPointer:SetEnableStretch(1)
            bountyPointer:SetUserValue("x", icon:GetUserIValue("worldpos_x"))
            bountyPointer:SetUserValue("y", icon:GetUserIValue("worldpos_y"))
            bountyPointer:SetUserValue("z", icon:GetUserIValue("worldpos_z"))

            local destination = compass:CreateOrGetControl("richtext", "destination", 100, 20, ui.CENTER_HORZ, ui.BOTTOM, 0, 0, 0, 0);
            destination:SetFontName("white_16_ol")
            destination:SetText(nextMapCls.Name .. " (" .. (min + 1) .. ")")
            destination:EnableHitTest(0)

            local offsetY = -20;
            compass:ShowWindow(1)
            FRAME_AUTO_POS_TO_OBJ(compass, session.GetMyHandle(), -compass:GetWidth() / 2, offsetY, 3);
        end
    else
        ui.SysMsg("경로를 찾을수 없습니다.")
    end
    loadedNearbyPath = true
end

function BOUNTYHUD_RECURSIVE_SHORTEST_PATH(currentNode, currentDepth, destinationNode, alreadySeen)
    if (alreadySeen == nil) then
        alreadySeen = {}
    end
    -- clone
    local seen = {}
    for k, v in pairs(alreadySeen) do
        seen[k] = 1
    end
    seen[currentNode] = 1

    local depth = tonumber(currentDepth)
    -- if this is what we're looking for, return
    if (currentNode == destinationNode) then
        search = depth
        return depth
    end

    -- don't go too deep. Just return nil if we're getting too deep
    if (depth >= search) then
        return nil
    end

    -- recursively call all unseen adjacent maps and find the shortest path
    local min = 99
    local adjacentMaps = BountyHud:GetAdjacentMaps(currentNode)
    for k, v in pairs(adjacentMaps) do
        if (seen[k] ~= 1) then
            local pathLength = BOUNTYHUD_RECURSIVE_SHORTEST_PATH(k, depth + 1, destinationNode, seen)
            if (pathLength ~= nil and pathLength < min) then
                min = pathLength
            end
        end
    end
    return min
end

function BOUNTYHUD_GAME_START(frame)
    local curMapID = session.GetMapID()
    local mapCls = GetClassByType("Map", curMapID);
    local mapName = mapCls.ClassName
    local map = frame:GetChildRecursively("map")
    local my = frame:GetChildRecursively("my");
    my:ShowWindow(0);
    AUTO_CAST(map)
    map:SetImage(mapName)
    local mapprop = geMapTable.GetMapProp(mapName);
    local mongens = mapprop.mongens;
    local cnt = mongens:Count();
    for i = 0 , cnt - 1 do
        local MonProp = mongens:Element(i);
        local iconName = MonProp:GetMinimapIcon()
        if (iconName == 'minimap_portal' or iconName == 'minimap_erosion') then
            local GenList = MonProp.GenList;
            local GenCnt = GenList:Count();
            for j = 0 , GenCnt - 1 do
                local dialog = MonProp:GetDialog()
                local warpCls = GetClass("Warp", MonProp:GetDialog());
                if (warpCls == nil) then
                    for match in MonProp:GetDialog():gmatch("[a-zA-Z]+_(.*)") do
                        warpCls = GetClass("Warp", match);
                    end
                end
                if (warpCls ~= nil) then
                    local clsName = TryGetProp(warpCls, "TargetZone", "None");
                    local pos = GenList:Element(j);
                    local mapbox = frame:GetChild("mapbox");
                    local mappos = mapprop:WorldPosToMinimapPos(pos.x, pos.z, mapbox:GetWidth(), mapbox:GetHeight());
                    local icon = mapbox:CreateOrGetControl("picture", "icon_" .. clsName, 20, 20, ui.LEFT, ui.TOP, 0, 0, 0, 0);
                    AUTO_CAST(icon)
                    icon:SetImage(MonProp:GetMinimapIcon())
                    icon:SetUserValue("x", mappos.x)
                    icon:SetUserValue("y", mappos.y)
                    icon:SetUserValue("worldpos_x", pos.x)
                    icon:SetUserValue("worldpos_y", pos.y)
                    icon:SetUserValue("worldpos_z", pos.z)
                    icon:SetOffset(mappos.x - 10, mappos.y - 10)
                    icon:SetEnableStretch(1)
                end
            end
        end
    end
    my:ShowWindow(1);
    -- nearest path
end

function BOUNTYHUD_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(BountyHud.Default.Movable);
    frame:EnableHitTest(BountyHud.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "BOUNTYHUD_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window');

    -- set default position of frame
    frame:Move(BountyHud.Settings.Position.X, BountyHud.Settings.Position.Y);
    frame:SetOffset(BountyHud.Settings.Position.X, BountyHud.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(BountyHud.Default.Width, BountyHud.Default.Height);
    frame:ShowWindow(BountyHud.Default.IsVisible);

    local title = frame:CreateOrGetControl("richtext", "title", 300, 20, ui.LEFT, ui.TOP, 10, 10, 0, 0);
    title:SetFontName("white_16_ol")
    title:SetText("Bounty HUD")
    title:EnableHitTest(0)

    local mapbox = frame:CreateOrGetControl("groupbox", "mapbox", 300, 300, ui.LEFT, ui.BOTTOM, 0, 30, 0, 0);
    local map = mapbox:CreateOrGetControl("picture", "map", 300, 300, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(map)
    map:SetEnableStretch(1)
    map:EnableHitTest(0);

    local my = mapbox:CreateOrGetControl("picture", "my", 50, 50, ui.LEFT, ui.TOP, 0, 0, 0, 0);
    AUTO_CAST(my)
    my:SetImage("minimap_leader")
    my:SetEnableStretch(1)
end

function BOUNTYHUD_END_DRAG(frame, ctrl)
    BountyHud.Settings.Position.X = BountyHud.frame:GetX();
    BountyHud.Settings.Position.Y = BountyHud.frame:GetY();
    BOUNTYHUD_SAVE_SETTINGS();
end

function BOUNTYHUD_SAVE_SETTINGS()
    acutil.saveJSON(BountyHud.SettingsFileLoc, BountyHud.Settings);
end

-- general utilities

BountyHud.Strings = {
    ["string_name"] = {
        ['kr'] = "안녕 세상아",
        ['en'] = "Hello World"
    }
}

function BountyHud.GetTranslatedString(self, strName)
    local countrycode = option.GetCurrentCountry()
    local language = 'kr'
    if countrycode == 'kr' then
        language = 'kr'
    else
        language = 'en'
    end

    if (self.Strings[strName] == nil) then
        return nil
    else
        return self.Strings[strName][language]
    end
end

function BountyHud.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end