--dofile("../data/addon_d/persistentcamcon/persistentcamcon.lua");

--アドオン名（大文字）
local addonName = "persistentcamcon";
--作者名
local author = "SUZUMEIKO";
-- modified by meldavy

--アドオン内で使用する領域を作成。以下、ファイル内のスコープではグローバル変数gでアクセス可
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][author] = _G["ADDONS"][author] or {};
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {};
local g = _G["ADDONS"][author][addonName];

--設定ファイル保存先
g.settingsFileLoc = string.format("../addons/%s/settings.json", addonName);

--設定値
g.settings = {
    enable = true,
    window = 1,
    position = {
        x = 500,
        y = 500
    },
    campos = {
        x = 45,
        y = 38,
        z = 236
    },
    maps = {

    }
};
g.master = {
    max = {
        x = 360,
        y = 90,
        z = 700
    },
    default = {
        x = 45,
        y = 38,
        z = 236
    }
};

--ライブラリ読み込み
local acutil = require('acutil');

--lua読み込み時のメッセージ
--CHAT_SYSTEM("[ADDON] persistentcamcon loaded");

--マップ読み込み時処理（1度だけ）
function PERSISTENTCAMCON_ON_INIT(addon, frame)
    g.addon = addon;
    g.frame = frame;

    frame:ShowWindow(0);
    acutil.slashCommand("/camcon", PERSISTENTCAMCON_TOGGLE_FRAME);
    if not g.loaded then
        local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
        if err then
            --設定ファイル読み込み失敗時処理
            --CHAT_SYSTEM("[persistentcamcon] 設定ファイルのロードに失敗");
        else
            --設定ファイル読み込み成功時処理
            --CHAT_SYSTEM("[persistentcamcon] 設定ファイルのロードに成功");
            g.settings = t;
            g.loaded = true;
        end
    end
    if g.settings.enable then
        frame:ShowWindow(1);
    end


    -- v1.0.1 ウィンドウサイズ配列追加
    if not g.settings.window then
        g.settings.window = 1;
        PERSISTENTCAMCON_SAVE_SETTINGS();
    end


    --ドラッグ
    frame:EnableMove(1);
    frame:EnableHitTest(1);
    frame:SetEventScript(ui.LBUTTONUP, "PERSISTENTCAMCON_END_DRAG");

    frame:Move(g.settings.position.x, g.settings.position.y);
    frame:SetOffset(g.settings.position.x, g.settings.position.y);

    --フレーム初期化処理
    PERSISTENTCAMCON_INIT_FRAME(frame);

    -- ウィンドウサイズ再定義
    PERSISTENTCAMCON_WINDOW_INIT();

    addon:RegisterMsg('GAME_START', 'PERSISTENTCAMCON_GAME_START');
end

-- 맵 이동시
function PERSISTENTCAMCON_GAME_START(frame)
    local mapId = session.GetMapID();
    local mapZoomValue = g.settings.maps[tostring(mapId)];
    if (mapZoomValue ~= nil) then
        local scrZ = frame:CreateOrGetControl("slidebar", "n_scrZ", 120, 94, 180, 30);
        tolua.cast(scrZ, 'ui::CSlideBar');
        scrZ:SetLevel(tonumber(mapZoomValue));
        ReserveScript("PERSISTENTCAMCON_CAMERA_UPDATE_Z()", 0.5)
    end
end

function PERSISTENTCAMCON_SAVE_SETTINGS(z)
    if (z ~= nil) then
        local frame = ui.GetFrame("persistentcamcon");
        if (frame ~= nil and frame:IsVisible() == 1) then
            local scrZ = frame:GetChild("n_scrZ");
            tolua.cast(scrZ, 'ui::CSlideBar');
            curZ = scrZ:GetLevel();
            if (curZ ~= z) then
                return;
            end
        end
    end
    acutil.saveJSON(g.settingsFileLoc, g.settings);
end



--あとで削除
--PERSISTENTCAMCON_INIT_FRAME(g.frame);

function PERSISTENTCAMCON_INIT_FRAME(frame)
    --フレーム初期化処理
    local frame = ui.GetFrame("persistentcamcon");
    frame:SetSkinName("box_glass");

    local titleText = frame:CreateOrGetControl("richtext", "n_titleText", 0, 0, 0, 0);
    titleText:SetOffset(10,10);
    titleText:SetFontName("white_16_ol");
    titleText:SetText("/camcon");

    local tipText = frame:CreateOrGetControl("richtext", "n_tip", 0, 0, 0, 0);
    tipText:SetOffset(10,120);
    tipText:SetFontName("white_12_ol");
    tipText:SetText("XY축 변경할때 Z값이 초기화되는건 킹쩔수없어요");

    local btnReset = frame:CreateOrGetControl("button", "n_resize", 236, 4, 30, 30);
    btnReset:SetText("{@sti7}{s16}W");
    btnReset:SetEventScript(ui.LBUTTONUP, "PERSISTENTCAMCON_WINDOW_RESIZE");

    local btnReset = frame:CreateOrGetControl("button", "n_reset", 266, 4, 30, 30);
    btnReset:SetText("{@sti7}{s16}R");
    btnReset:SetEventScript(ui.LBUTTONUP, "PERSISTENTCAMCON_RESET");

    local labelX = frame:CreateOrGetControl("richtext", "n_labelX", 0, 0, 0, 0);
    labelX:SetOffset(20,40);
    labelX:SetFontName("white_14_ol");
    labelX:SetText("X값("..(g.settings.campos.x).."):");

    local labelY = frame:CreateOrGetControl("richtext", "n_labelY", 0, 0, 0, 0);
    labelY:SetOffset(20,70);
    labelY:SetFontName("white_14_ol");
    labelY:SetText("Y값("..(g.settings.campos.y).."):");

    local labelZ = frame:CreateOrGetControl("richtext", "n_labelZ", 0, 0, 0, 0);
    labelZ:SetOffset(20,100);
    labelZ:SetFontName("white_14_ol");
    labelZ:SetText("Z값("..(g.settings.campos.z).."):");

    local scrX = frame:CreateOrGetControl("slidebar", "n_scrX", 120, 34, 180, 30);
    tolua.cast(scrX, 'ui::CSlideBar');
    scrX:SetMinSlideLevel(0);
    scrX:SetMaxSlideLevel(g.master.max.x-1);
    scrX:SetLevel(g.master.default.x);

    local scrY = frame:CreateOrGetControl("slidebar", "n_scrY", 120, 64, 180, 30);
    tolua.cast(scrY, 'ui::CSlideBar');
    scrY:SetMinSlideLevel(-89);
    scrY:SetMaxSlideLevel(g.master.max.y-1);
    scrY:SetLevel(g.master.default.y);

    local scrZ = frame:CreateOrGetControl("slidebar", "n_scrZ", 120, 94, 180, 30);
    tolua.cast(scrZ, 'ui::CSlideBar');
    scrZ:SetMinSlideLevel(50);
    scrZ:SetMaxSlideLevel(g.master.max.z);
    scrZ:SetLevel(g.master.default.z);

    --カメラの仕様によりプリセット機能が使えないことを思い出した跡地
    -- 設定保存 (v1.0.1+)
    --local prisetTitle = frame:CreateOrGetControl("richtext", "n_prisetTitle", 0, 0, 0, 0);
    --prisetTitle:SetOffset(10,150);
    --prisetTitle:SetFontName("white_16_ol");
    --prisetTitle:SetText("プリセット");
    --
    --local prisetSelect = frame:CreateOrGetControl("droplist", "n_prisetSelect", 10, 164, 220, 40);
    --tolua.cast(prisetSelect, 'ui::CDropList');
    --prisetSelect:AddItem(0,"test0",0,"NONE");
    --prisetSelect:AddItem(1,"test1",0,"NONE");
    --prisetSelect:AddItem(2,"test2",0,"NONE");
    --prisetSelect:AddItem(3,"test3",0,"NONE");
    --prisetSelect:AddItem(4,"test4",0,"NONE");

end

--カメラ座標リセット
function PERSISTENTCAMCON_RESET()
    local frame = ui.GetFrame("persistentcamcon");
    local scrX = frame:GetChild("n_scrX");
    local scrY = frame:GetChild("n_scrY");
    local scrZ = frame:GetChild("n_scrZ");
    tolua.cast(scrX, 'ui::CSlideBar');
    tolua.cast(scrY, 'ui::CSlideBar');
    tolua.cast(scrZ, 'ui::CSlideBar');

    g.settings.campos.x=g.master.default.x;
    g.settings.campos.y=g.master.default.y;
    g.settings.campos.z=g.master.default.z;
    scrX:SetLevel(g.master.default.x);
    scrY:SetLevel(g.master.default.y);
    scrZ:SetLevel(g.master.default.z);

    -- UPDATE
    PERSISTENTCAMCON_CAMERA_UPDATE_Z();
    PERSISTENTCAMCON_CAMERA_UPDATE_XY();
    local mapId = session.GetMapID();
    g.settings.maps[tostring(mapId)] = nil;
    PERSISTENTCAMCON_SAVE_SETTINGS();
end

--ウィンドウサイズ変更
function PERSISTENTCAMCON_WINDOW_INIT()
    local frame = ui.GetFrame("persistentcamcon");
    if g.settings.window == 1 then
        frame:Resize(300,40);
    else
        frame:Resize(300,140);
    end
end
function PERSISTENTCAMCON_WINDOW_RESIZE()
    local frame = ui.GetFrame("persistentcamcon");
    if g.settings.window == 0 then
        g.settings.window = 1;
        frame:Resize(300,40);
    else
        g.settings.window = 0;
        frame:Resize(300,140);
    end
    PERSISTENTCAMCON_SAVE_SETTINGS();
end

--カメラ座標切り替え
function PERSISTENTCAMCON_CAMERA_UPDATE_XY()
    local frame = ui.GetFrame("persistentcamcon");
    local labelX = frame:GetChild("n_labelX");
    local scrX = frame:GetChild("n_scrX");
    local labelY = frame:GetChild("n_labelY");
    local scrY = frame:GetChild("n_scrY");
    tolua.cast(scrX, 'ui::CSlideBar');
    tolua.cast(scrY, 'ui::CSlideBar');

    g.settings.campos.x = scrX:GetLevel();
    g.settings.campos.y = scrY:GetLevel();

    labelX:SetText("X값("..(g.settings.campos.x).."):");
    labelY:SetText("Y값("..(g.settings.campos.y).."):");

    -- UPDATE
    camera.CamRotate(g.settings.campos.y, g.settings.campos.x);

end

--カメラ座標切り替え
function PERSISTENTCAMCON_CAMERA_UPDATE_Z()
    local frame = ui.GetFrame("persistentcamcon");
    local labelZ = frame:GetChild("n_labelZ");
    local scrZ = frame:GetChild("n_scrZ");
    tolua.cast(scrZ, 'ui::CSlideBar');

    g.settings.campos.z = scrZ:GetLevel();

    labelZ:SetText("Z값("..(g.settings.campos.z).."):");

    -- UPDATE
    camera.CustomZoom(g.settings.campos.z, 0);

    -- 맵 저장
    local mapId = session.GetMapID();
    g.settings.maps[tostring(mapId)] = scrZ:GetLevel();
    ReserveScript(string.format("PERSISTENTCAMCON_SAVE_SETTINGS(%d)", scrZ:GetLevel()), 1.0);
end


--フレーム場所保存処理
function PERSISTENTCAMCON_END_DRAG()
    g.settings.position.x = g.frame:GetX();
    g.settings.position.y = g.frame:GetY();
    PERSISTENTCAMCON_SAVE_SETTINGS();
end

--フレームの表示切り替え
function PERSISTENTCAMCON_TOGGLE_FRAME()
    local frame = ui.GetFrame("persistentcamcon");
    if g.settings.enable == true then
        frame:ShowWindow(0);
        g.settings.enable=false;
    else
        frame:ShowWindow(1);
        g.settings.enable=true;
    end
end
