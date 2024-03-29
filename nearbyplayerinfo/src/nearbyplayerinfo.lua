--dofile("../data/addon_d/nearbyplayerinfo/nearbyplayerinfo.lua");

-- areas defined
local author = 'meldavy'
local addonName = 'nearbyplayerinfo'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- get a pointer to the area
local NearbyPlayerInfo = _G['ADDONS'][author][addonName]
local acutil = require('acutil')
local base = {}

local seenMembers = {}
local playerDetails = {}
local kda = {}
local visiblePlayers = {}

NearbyPlayerInfo.SettingsFileLoc = string.format('../addons/%s/settings.json', addonName)

NearbyPlayerInfo.Settings = {
    Visible = 1,
    Position = {
        X = 400,
        Y = 400
    },
    ExtraRows = 0,
    WarMode = 0
};

NearbyPlayerInfo.Default = {
    MaxRows = 10,
    RowHeight = 26,
    Width = 350,
    Height = 250,
    IsVisible = 1,
    Movable = 1,
    Enabled = 1, -- Hittest
};

function NEARBYPLAYERINFO_ON_INIT(addon, frame)
    NearbyPlayerInfo.addon = addon;
    NearbyPlayerInfo.frame = frame;
    -- load settings
    if not NearbyPlayerInfo.Loaded then
        local t, err = acutil.loadJSON(NearbyPlayerInfo.SettingsFileLoc, NearbyPlayerInfo.Settings);
        if err then
        else
            NearbyPlayerInfo.Settings = t;
            NearbyPlayerInfo.Loaded = true;
        end
    end
    if (NearbyPlayerInfo.Settings.ExtraRows == nil) then
        NearbyPlayerInfo.Settings.ExtraRows = 0
    end
    if (NearbyPlayerInfo.Settings.WarMode == nil) then
        NearbyPlayerInfo.Settings.WarMode = 0
    end

    seenMembers = {}
    playerDetails = {}
    acutil.slashCommand('/nearbyplayers', NEARBYPLAYERINFO_PROCESS_COMMAND)
    acutil.slashCommand('/np', NEARBYPLAYERINFO_PROCESS_COMMAND)
    NearbyPlayerInfo.SetupHook(NEARBYPLAYERINFO_ON_PC_COMPARE, "SHOW_PC_COMPARE")
    addon:RegisterMsg('COLONYWAR_GUILD_KILL_MSG', 'NEARBYPLAYERINFO_ON_SEND_KILL_DEAD_MESSAGE')
    addon:RegisterMsg('GAME_START_3SEC', 'NEARBYPLAYERINFO_GAME_START');
    -- initialize frame
    NEARBYPLAYERINFO_ON_FRAME_INIT(frame)
end

function NEARBYPLAYERINFO_GAME_START(frame)
end

function NEARBYPLAYERINFO_ON_SEND_KILL_DEAD_MESSAGE(frame, msg, argstr, argnum)
    NearbyPlayerInfo.ProcessSendKillDeadMessage(frame, msg, argstr, argnum)
end

function NearbyPlayerInfo.ProcessSendKillDeadMessage(frame, msg, argstr, argnum)
    if (NearbyPlayerInfo.Settings.WarMode == 1) then
        --local killerName = GetHandle(killer)
        --local deadName = GetHandle(Deader)
        --local killerObj = session.otherPC.GetByFamilyName(killerName);
        --local deaderObj = session.otherPC.GetByFamilyName(deadName);
        local splitedString = StringSplit(argstr, "#");
        local killerIcon = splitedString[1];
        local selfIcon = splitedString[2];
        local killerName = splitedString[3];
        local selfName = splitedString[4];
        local targetGuildName = splitedString[5];
        local isKilled = splitedString[6];
        local isMyGuildKilled  = isKilled == "KILL"
        if (killerName ~= nil) then
            if (kda[killerName] == nil) then
                kda[killerName] = { k = 1, d = 0 }
            else
                kda[killerName].k = kda[killerName].k + 1
            end
            NearbyPlayerInfo:UpdateWarmodeInfo(killerName)
        end
        if (selfName ~= nil) then
            if (kda[selfName] == nil) then
                kda[selfName] = { k = 0, d = 1 }
            else
                kda[selfName].d = kda[selfName].d + 1
            end
            NearbyPlayerInfo:UpdateWarmodeInfo(selfName)
        end
    end
end

function NearbyPlayerInfo.UpdateWarmodeInfo(self, teamName)
    local frame = ui.GetFrame('nearbyplayerinfo')
    local groupbox = frame:GetChildRecursively('pclist')

    -- check to see if we already have an entry for this player
    local warmode = groupbox:GetChildRecursively("warmode_" .. teamName)
    if (warmode ~= nil) then
        warmode:SetText(NearbyPlayerInfo:GetKDAString(teamName))
    end
end

function NearbyPlayerInfo.GetKDAString(self, teamname)
    if (kda[teamname] == nil) then
        kda[teamname] = { k = 0, d = 0 }
    end
    local killIcon = "icon_" .. GetClassByType('Buff', 2993).Icon
    local deathIcon = "icon_" .. GetClassByType('Buff', 2991).Icon
    local format = "{img %s 24 24} %d {img %s 24 24} %d"
    local msg = string.format(format, killIcon, kda[teamname].k, deathIcon, kda[teamname].d)
    return msg
end

function NEARBYPLAYERINFO_WARMODE_TOGGLE(frame)
    if (NearbyPlayerInfo.Settings.WarMode == 0) then
        NearbyPlayerInfo.Settings.WarMode = 1
        frame:StopUpdateScript("NEARBYPLAYERINFO_ON_TICK")
        ReserveScript("NEARBYPLAYERINFO_ON_TICK()", 0)
        frame:RunUpdateScript("NEARBYPLAYERINFO_ON_TICK", 1)
    else
        NearbyPlayerInfo.Settings.WarMode = 0
        frame:StopUpdateScript("NEARBYPLAYERINFO_ON_TICK")
        ReserveScript("NEARBYPLAYERINFO_ON_TICK()", 0)
        frame:RunUpdateScript("NEARBYPLAYERINFO_ON_TICK", 3)
    end
    NEARBYPLAYERINFO_SAVE_SETTINGS()
    frame:Resize(NearbyPlayerInfo.Default.Width + (NearbyPlayerInfo.Settings.WarMode * 150), frame:GetHeight());
    local pclist = frame:GetChild("pclist")
    pclist:Resize(NearbyPlayerInfo.Default.Width - 15 + (NearbyPlayerInfo.Settings.WarMode * 150), pclist:GetHeight());
end

function NEARBYPLAYERINFO_EXPAND_ROW(frame)
    if (NearbyPlayerInfo.Settings.ExtraRows < NearbyPlayerInfo.Default.MaxRows) then
        NearbyPlayerInfo.Settings.ExtraRows = NearbyPlayerInfo.Settings.ExtraRows + 1
        frame:Resize(NearbyPlayerInfo.Default.Width + (NearbyPlayerInfo.Settings.WarMode * 150), NearbyPlayerInfo.Default.Height + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        local pclist = frame:GetChild("pclist")
        pclist:Resize(NearbyPlayerInfo.Default.Width - 15 + (NearbyPlayerInfo.Settings.WarMode * 150), (NearbyPlayerInfo.Default.Height - 50) + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        NEARBYPLAYERINFO_SAVE_SETTINGS()
    end
end

function NEARBYPLAYERINFO_CONTRACT_ROW(frame)
    if (NearbyPlayerInfo.Settings.ExtraRows > -5) then
        NearbyPlayerInfo.Settings.ExtraRows = NearbyPlayerInfo.Settings.ExtraRows - 1
        frame:Resize(NearbyPlayerInfo.Default.Width + (NearbyPlayerInfo.Settings.WarMode * 150), NearbyPlayerInfo.Default.Height + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        local pclist = frame:GetChild("pclist")
        pclist:Resize(NearbyPlayerInfo.Default.Width - 15 + (NearbyPlayerInfo.Settings.WarMode * 150), (NearbyPlayerInfo.Default.Height - 50) + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
        NEARBYPLAYERINFO_SAVE_SETTINGS()
    end
end


function NEARBYPLAYERINFO_ON_TICK(frame)
    NearbyPlayerInfo:FindNearbyObjects()
    return 1
end

function NearbyPlayerInfo.FindNearbyObjects(self)
    --local pc = GetMyPCObject();
    --local layer = GetLayer(pc)
    --local zone = GetZoneInstID(pc)
    --local list, cnt = GetLayerPCList(GetZoneInstID(pc))
    --if cnt >= 1 then
    --    print(cnt)
    --    for i = 1, cnt do
    --        if list[i].ClassName == 'PC' then
    --        end
    --    end
    --end

    local guildMembers = {}
    local partyMemberList = session.party.GetPartyMemberList(PARTY_GUILD)
    if partyMemberList ~= nil then
        local count = partyMemberList:Count()
        for i = 0 , count - 1 do
            local info = partyMemberList:Element(i)
            local name = info:GetName()
            guildMembers[name] = 1
        end
    end

    local myHandle = session.GetMyHandle()
    local frame = ui.GetFrame('nearbyplayerinfo')
    local groupbox = frame:GetChildRecursively('pclist')
    groupbox:RemoveAllChild()
    local objList, objCount = SelectObject(GetMyActor(), 10000, 'ALL')
    local handles = {}
    local perGuildCount = {}
    local playerGuild = {}
    for i = 1, objCount do
        local targetHandle = GetHandle(objList[i])
        if (objList[i].ClassName == 'PC') then
            local pchud = ui.GetFrame('charbaseinfo1_' .. targetHandle);
            if (pchud ~= nil) then
                if (targetHandle ~= myHandle) then
                    visiblePlayers[targetHandle] = 1
                    local guildName = pchud:GetChildRecursively('guildName')
                    if (guildName ~= nil) then
                        local guildNameText = guildName:GetText()
                        playerGuild[targetHandle] = guildNameText
                        if (perGuildCount[guildNameText] == nil) then
                            perGuildCount[guildNameText] = 0
                        end
                        perGuildCount[guildNameText] = perGuildCount[guildNameText] + 1
                    end
                    table.insert(handles, targetHandle)
                end
            end
        end
    end

    table.sort(handles, function(a, b)
        local hud_a = ui.GetFrame('charbaseinfo1_' .. a);
        local hud_b = ui.GetFrame('charbaseinfo1_' .. b);
        if (hud_a ~= nil and hud_b ~= nil) then
            local name_a_control = hud_a:GetChildRecursively('guildName')
            local name_b_control = hud_b:GetChildRecursively('guildName')
            if (name_a_control ~= nil and name_b_control ~= nil) then
                local name_a = name_a_control:GetText()
                local name_b = name_b_control:GetText()
                if (name_a == 'None') then
                    name_a = ""
                end
                if (name_b == 'None') then
                    name_b = ""
                end
                local familyNameA = info.GetFamilyName(a);
                local familyNameB = info.GetFamilyName(b);
                if (name_a == name_b) then
                    if (kda[familyNameA] ~= nil and kda[familyNameB] ~= nil) then
                        return kda[familyNameA].k > kda[familyNameB].k
                    end
                end
                return name_a > name_b
            end
        end
        return true
    end)

    local prevGuildName = ""
    local topIndex = 0
    for k, targetHandle in pairs(handles) do

        -- getting highest killcount players
        if (prevGuildName ~= playerGuild[targetHandle]) then
            prevGuildName = playerGuild[targetHandle]
            topIndex = 0
        end
        topIndex = topIndex + 1

        NearbyPlayerInfo:DrawUserInfo(targetHandle)
        -- create frame for this handle if it doesn't already exist
        -- warmode
        if (NearbyPlayerInfo.Settings.WarMode == 1) then
            --
            local familyName = info.GetFamilyName(targetHandle);
            if (guildMembers[familyName] == nil) then
                -- if not ally
                if (topIndex <= 2) then
                    local pcframe = ui.GetFrame("follow_" .. targetHandle)
                    if (pcframe == nil) then
                        pcframe = ui.CreateNewFrame("nearbyplayerinfo", "follow_" .. targetHandle);
                        pcframe:Resize(50, 50)
                        pcframe:SetSkinName("None")
                        pcframe:SetLayerLevel(22); -- 콜리니 hud 위에 표시
                        pcframe:EnableHitTest(0);
                        local targetEmblem = pcframe:CreateOrGetControl("picture", "targetEmblem", 50, 50, ui.LEFT, ui.TOP, 0, 0, 0, 0);
                        AUTO_CAST(targetEmblem)
                        targetEmblem:SetImage("trasuremapmark");
                        targetEmblem:SetEnableStretch(1)
                        targetEmblem:SetBlink(0.0, 1.0, "FFFF5555");
                        local offsetY = -20;
                        pcframe:ShowWindow(1)
                        FRAME_AUTO_POS_TO_OBJ(pcframe, targetHandle, -pcframe:GetWidth() / 2, offsetY, 3);
                    end
                else
                    ui.DestroyFrame("follow_" .. targetHandle);
                end
            end
        else
            ui.DestroyFrame("follow_" .. targetHandle);
        end
        if (playerDetails[targetHandle] == nil) then
            -- only make network call if we haven't already memberinfo'd this player
            local cid = info.GetCID(targetHandle);
            seenMembers[targetHandle] = 1
            ui.PropertyCompare(targetHandle, 1);
        end
    end

    local evaluatedMembers = {}
    -- cleanup, first do a xor
    for handle, value in pairs(visiblePlayers) do
        if (value == 1) then
            evaluatedMembers[handle] = 1
        end
    end
    for k, handle in pairs(handles) do
        evaluatedMembers[handle] = 0
    end
    -- find all seen but invisible handles and cleanup
    for handle, value in pairs(evaluatedMembers) do
        if (value == 1) then
            local familyName = info.GetFamilyName(handle);
            ui.DestroyFrame("follow_" .. handle);
            visiblePlayers[handle] = nil
        end
    end
end

function NEARBYPLAYERINFO_ON_PC_COMPARE(cid)
    NearbyPlayerInfo.ProcessPCCompare(cid)
end

function NearbyPlayerInfo.ProcessPCCompare(cid)
    local otherpcinfo = session.otherPC.GetByStrCID(cid);
    local targetHandle = otherpcinfo:GetHandleVal();
    if (seenMembers[targetHandle] == nil) then
        base["SHOW_PC_COMPARE"](cid)
        return
    end
    seenMembers[targetHandle] = nil
    NearbyPlayerInfo:DrawAdditionalInfo(otherpcinfo)
end

function NearbyPlayerInfo.DrawUserInfo(self, handle)
    local emblemFolderPath = filefind.GetBinPath("GuildEmblem"):c_str()

    local frame = ui.GetFrame('nearbyplayerinfo')
    local groupbox = frame:GetChildRecursively('pclist')
    -- local targetName = info.GetFamilyName(targetHandle);

    local actor = world.GetActor(handle)
    local targetName = info.GetFamilyName(handle);
    local targetInfo = info.GetTargetInfo(handle);

    -- get the hud of PC to get guild data
    local pchud = ui.GetFrame('charbaseinfo1_' .. handle);
    -- check to see if we already have an entry for this player
    local pcinfo = groupbox:CreateOrGetControl("groupbox", "pcinfo_" .. handle, NearbyPlayerInfo.Default.Width + 200, NearbyPlayerInfo.Default.RowHeight, ui.LEFT, ui.TOP, 0, ((groupbox:GetChildCount() - 1) * 22), 0, 0);
    if (pchud ~= nil) then
        AUTO_CAST(pcinfo)
        pcinfo:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_MEMBERINFO");
        pcinfo:SetEventScriptArgNumber(ui.LBUTTONUP, handle);
        pcinfo:EnableScrollBar(0)
        pcinfo:SetTextTooltip("클릭하여 {#fad014}" .. targetName .. "{/} 인포 보기");

        -- set name
        local pcname = pcinfo:CreateOrGetControl("richtext", "pcname",  145, 20, ui.LEFT, ui.TOP, 25, 3, 0, 0);
        pcname:EnableHitTest(0)
        pcname:SetFontName("white_16_ol");
        pcname:SetText(targetName)

        -- joblist control
        local joblist = pcinfo:CreateOrGetControl("richtext", "joblist",  100, 20, ui.LEFT, ui.TOP, 180, 0, 0, 0);
        joblist:EnableHitTest(0)
        joblist:SetFontName("white_16_ol")
        if (playerDetails[handle] ~= nil) then
            joblist:SetText(tostring(playerDetails[handle].Job))
        end

        -- warmode control
        local warmode = pcinfo:CreateOrGetControl("richtext", "warmode_" .. targetName,  100, 20, ui.LEFT, ui.TOP, 350, 0, 0, 0);
        warmode:EnableHitTest(0)
        warmode:SetFontName("white_16_ol")
        warmode:SetText(NearbyPlayerInfo:GetKDAString(targetName))

        -- create or update guild emblem
        local emblem = pcinfo:CreateOrGetControl("picture", "guildemblem",  23, 23, ui.LEFT, ui.TOP, 0, 0, 0, 0);
        AUTO_CAST(emblem)
        local guildName = pchud:GetChildRecursively('guildName'):GetText()
        emblem:SetTextTooltip(guildName)
        if (guildName ~= 'None') then
            local guildImage = pchud:GetChildRecursively('guildEmblem')
            AUTO_CAST(guildImage)
            local imageName = guildImage:GetImageName()
            local emblemFileName = emblemFolderPath .. "\\" .. imageName
            emblem:SetEnableStretch(1);
            emblem:SetFileName(emblemFileName)
        end
    end
end

function NearbyPlayerInfo.DrawAdditionalInfo(self, otherinfo)
    local targetHandle = otherinfo:GetHandleVal();
    local frame = ui.GetFrame('nearbyplayerinfo')
    local groupbox = frame:GetChildRecursively('pclist')

    -- get the hud of PC to get guild data
    local pchud = ui.GetFrame('charbaseinfo1_' .. targetHandle);
    local jobStr = NearbyPlayerInfo:GenerateJobStr(otherinfo)
    if (playerDetails[targetHandle] == nil) then
        playerDetails[targetHandle] = {}
    end
    playerDetails[targetHandle].Job = jobStr

    -- check to see if we already have an entry for this player
    local pcinfo = groupbox:GetChild("pcinfo_" .. targetHandle)
    if (pchud ~= nil and pcinfo ~= nil) then
        local joblist = pcinfo:GetChild("joblist");
        joblist:SetText(jobStr)
    end
end

function NearbyPlayerInfo.GenerateJobStr(self, otherpcinfo)
    local handle = otherpcinfo:GetHandleVal()
    local namestr = ""
    for i = 0, otherpcinfo:GetJobCount()-1 do
        local jobinfo = otherpcinfo:GetJobInfoByIndex(i);
        local iconName = GET_JOB_ICON(jobinfo.jobID)
        namestr = namestr .. "{img " .. iconName .. " 28 28}"
    end
    return namestr
end

function NEARBYPLAYERINFO_PROCESS_COMMAND(command)
    local isVisible = ui.GetFrame('nearbyplayerinfo'):IsVisible()
    ui.ToggleFrame('nearbyplayerinfo')
    if (isVisible == 1) then
        NearbyPlayerInfo.Settings.Visible = 0
    else
        NearbyPlayerInfo.Settings.Visible = 1
    end
    NEARBYPLAYERINFO_SAVE_SETTINGS()
end

function NEARBYPLAYERINFO_MEMBERINFO(frame, ctrl, argStr, handle)
    ui.PropertyCompare(handle, 1);
end

function NEARBYPLAYERINFO_ON_FRAME_INIT(frame)
    -- enable frame reposition through drag and move
    frame:EnableMove(NearbyPlayerInfo.Default.Movable);
    frame:EnableHitTest(NearbyPlayerInfo.Default.Enabled);
    frame:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_END_DRAG");

    -- draw the frame
    frame:SetSkinName('chat_window_2');

    -- set default position of frame
    frame:Move(NearbyPlayerInfo.Settings.Position.X, NearbyPlayerInfo.Settings.Position.Y);
    frame:SetOffset(NearbyPlayerInfo.Settings.Position.X, NearbyPlayerInfo.Settings.Position.Y);

    -- set default size and visibility
    frame:Resize(NearbyPlayerInfo.Default.Width + (NearbyPlayerInfo.Settings.WarMode * 150),
            NearbyPlayerInfo.Default.Height + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight));
    frame:ShowWindow(NearbyPlayerInfo.Settings.Visible);

    -- controls
    local title = frame:CreateOrGetControl("richtext", "title", NearbyPlayerInfo.Default.Width - 20, 20, ui.LEFT, ui.TOP, 10, 10, 0, 0);
    title:SetFontName("white_16_ol")
    title:SetText("/nearbyplayers")
    title:EnableHitTest(0)
    local expandButton = frame:CreateOrGetControl("button", "expandBtn", 30, 30, ui.RIGHT, ui.TOP, 0, 5, 40, 0);
    expandButton:SetFontName("white_16_ol")
    expandButton:SetText("+")
    expandButton:EnableHitTest(1)
    expandButton:SetTextTooltip("크기 증가")
    expandButton:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_EXPAND_ROW");
    local contractButton = frame:CreateOrGetControl("button", "contractBtn", 30, 30, ui.RIGHT, ui.TOP, 0, 5, 5, 0);
    contractButton:SetFontName("white_16_ol")
    contractButton:SetText("-")
    contractButton:EnableHitTest(1)
    contractButton:SetTextTooltip("크기 축소")
    contractButton:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_CONTRACT_ROW");
    local warmodeButton = frame:CreateOrGetControl("button", "warmodeBtn", 60, 30, ui.RIGHT, ui.TOP, 0, 5, 75, 0);
    warmodeButton:SetFontName("white_16_ol")
    warmodeButton:SetText("전쟁 모드")
    warmodeButton:EnableHitTest(1)
    warmodeButton:SetTextTooltip("전쟁 모드")
    warmodeButton:SetEventScript(ui.LBUTTONUP, "NEARBYPLAYERINFO_WARMODE_TOGGLE");

    local pclist = frame:CreateOrGetControl("groupbox", "pclist", NearbyPlayerInfo.Default.Width - 15 + (NearbyPlayerInfo.Settings.WarMode * 150),
            (NearbyPlayerInfo.Default.Height - 50) + (NearbyPlayerInfo.Settings.ExtraRows * NearbyPlayerInfo.Default.RowHeight), ui.LEFT, ui.TOP, 10, 40, 0, 0);
    AUTO_CAST(pclist)
    pclist:EnableScrollBar(1);
    -- pclist:EnableHitTest(1);
    ReserveScript("NEARBYPLAYERINFO_ON_TICK()", 1)
    frame:RunUpdateScript("NEARBYPLAYERINFO_ON_TICK", 3)
end

function NEARBYPLAYERINFO_END_DRAG(frame, ctrl)
    NearbyPlayerInfo.Settings.Position.X = NearbyPlayerInfo.frame:GetX();
    NearbyPlayerInfo.Settings.Position.Y = NearbyPlayerInfo.frame:GetY();
    NEARBYPLAYERINFO_SAVE_SETTINGS();
end

function NEARBYPLAYERINFO_SAVE_SETTINGS()
    acutil.saveJSON(NearbyPlayerInfo.SettingsFileLoc, NearbyPlayerInfo.Settings);
end

function NearbyPlayerInfo.SetupHook(func, baseFuncName)
    local addonUpper = string.upper(addonName)
    local replacementName = addonUpper .. "_BASE_" .. baseFuncName
    if (_G[replacementName] == nil) then
        _G[replacementName] = _G[baseFuncName];
        _G[baseFuncName] = func
    end
    base[baseFuncName] = _G[replacementName]
end