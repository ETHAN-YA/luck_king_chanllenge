--[[
Author: Ethan
Date: 2023-01-30 14:39:30
LastEditTime: 2023-02-18 20:50:03
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\modworldgenmain.lua
description:  
--]]
--[[
Author: Ethan
Date: 2023-01-30 14:39:30
LastEditTime: 2023-02-02 20:32:29
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\modworldgenmain.lua
description:  
--]]
local _G = GLOBAL
local require = _G.require
local package = _G.package
local STRINGS = _G.STRINGS
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
local Layouts =  require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")
require("constants")
require("map/tasks")
require("map/level") 

--新加static_layout 注意这个里面必须有大门否则地图无法生成
Layouts["MyStaticLayout"] = StaticLayout.Get("map/static_layouts/my_default_start",{
            start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
            fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
            layout_position = LAYOUT_POSITION.CENTER,
            disable_transform = true,           
			defs={
			welcomitem = {"spear"} --三矛开局哈哈哈
			},
        })	
	
AddStartLocation("MyNewStart", {
    name = STRINGS.UI.SANDBOXMENU.DEFAULTSTART,
    location = "forest",
    start_setpeice = "MyStaticLayout",
    start_node = "Blank",
})

AddTask("Make a NewPick", {
		locks={},
		keys_given={},
		room_choices={
			--["Forest"] = function() return 1 + math.random(SIZE_VARIATION) end, 
			--["BarePlain"] = 1, 
			--["Plain"] = function() return 1 + math.random(SIZE_VARIATION) end, 
			--["Clearing"] = 1,
			["Blank"] = 1,
		}, 
		room_bg=GROUND.GRASS,
		--background_room="BGGrass",
		background_room = "Blank",
		colour={r=0,g=1,b=0,a=1}
	})

--预设
AddLevel("LAVAARENA", {
	id = "CS_ZDY_YS1",
	name = "默认预设",
	desc = "默认【海岛】，默认修改出生点",
	location = "forest",
	version = 4,
	overrides={
		start_location = "MyNewStart",
		season_start = "default",
		world_size = "default",
		layout_mode = "LinkNodesByKeys",
		wormhole_prefab = "wormhole",
		roads = "never",
		birds = "never",
		keep_disconnected_tiles = true,
		no_wormholes_to_disconnected_tiles = true,
		no_joining_islands = true,
		has_ocean = true,
	},
	background_node_range = {0,1},
})
	
AddLevelPreInitAny(function(level)
	if level.location ~= "forest" then
		return
	end
	level.ocean_population = nil --海洋生态 礁石 海带之类的
	level.ocean_prefill_setpieces = nil --海洋奇遇 特指奶奶岛之类的
	level.tasks = {"Make a NewPick"}
	level.numoptionaltasks = 0
	level.optionaltasks = {}
	level.valid_start_tasks = nil
	level.set_pieces = {}

	level.random_set_pieces = {}
	level.ordered_story_setpieces = {}
	level.numrandom_set_pieces = 0
	


	level.overrides.start_location = "MyNewStart"
	level.overrides.keep_disconnected_tiles = true
	level.overrides.roads = "never"
	level.overrides.birds = "never" --没鸟
	level.overrides.has_ocean = false	--没海
	level.required_prefabs = {} --温蒂更新后的修复
end)


mods = _G.rawget(_G,"mods")
if not mods then
	mods = {}
	_G.rawset(_G, "mods", mods)
end

local IsTheFrontEnd = rawget(_G, "TheFrontEnd")

local ModsTab = require("widgets/redux/modstab")
local WorldSettingsTab = require("widgets/redux/worldsettings/worldsettingstab")
local _OnConfirmEnable = ModsTab.OnConfirmEnable
local _Cancel = ModsTab.Cancel
local _Refresh = WorldSettingsTab.Refresh

local function Reset(screen, modname)
    if screen and screen.server_settings_tab then
        local fancy_name = modname and KnownModIndex:GetModFancyName(modname) or nil        
        --如果有人禁用了我们的mod或卸载了所有mod（无）。
        if modname == nil or fancy_name == modinfo.name then
            -- 更改回默认的模式 即生存
            screen.server_settings_tab.game_mode.spinner:Enable()
            screen.server_settings_tab.game_mode.spinner:SetOptions(GetGameModesSpinnerData(ModManager:GetEnabledServerModNames()))
            screen.server_settings_tab.game_mode.spinner:SetSelectedIndex(1)
            screen.server_settings_tab.game_mode.spinner:Changed()
            -- 重新打开洞穴选项
            screen.world_tabs[2].isnewshard = true

            for i, v in pairs(screen.world_tabs[1].worldsettings_widgets) do
                v:LoadPreset() --重新载入预设
            end
        end
    end    
end

--卸下mod时会执行
ModsTab.OnConfirmEnable = function(self, restart, modname)
    local CurrentScreen = TheFrontEnd:GetActiveScreen()
    Reset(CurrentScreen, modname)
    _OnConfirmEnable(self, restart, modname)
end    

-- 返回退出创建世界时执行
ModsTab.Cancel = function(self)
    local CurrentScreen = TheFrontEnd:GetActiveScreen()
    Reset(CurrentScreen, modname)
    _Cancel(self)
end

-- 刷新时，有问题，会解锁存档的世界生存选项。我也没办法，暂时不能找到客户端读取有这个mod的存档时，洞穴依旧可以添加，而导致崩
WorldSettingsTab.Refresh = function(self)
    -- 不让客户端显示添加洞穴
    self.isnewshard = self.location_index == 1 and true or false
    return _Refresh(self)
end

--设置mod关闭时执行
local old_FrontendUnloadMod = ModManager.FrontendUnloadMod   
ModManager.FrontendUnloadMod = function(self, modname)
    old_FrontendUnloadMod(self, modname)
    local CurrentScreen = TheFrontEnd:GetActiveScreen()    
    if CurrentScreen and CurrentScreen.server_settings_tab then
        local fancy_name = modname and KnownModIndex:GetModFancyName(modname) or nil
        --如果有人禁用了我们的mod或卸载了所有mod（无）。
        if modname == nil or fancy_name == modinfo.name then    
            --恢复原来的
            ModsTab.OnConfirmEnable = _OnConfirmEnable
            ModsTab.Cancel = _Cancel
            ModManager.FrontendUnloadMod = old_FrontendUnloadMod 
            WorldSettingsTab.Refresh = _Refresh
        end
    end
end

if IsTheFrontEnd then
    local CurrentScreen = TheFrontEnd:GetActiveScreen() --获取活动屏幕ServerSlotScreen文档界面ServerCreationScreen具体档/新档
    --server_settings_tab服务器设置选项卡game_mode游戏模式启用
    
    if CurrentScreen and CurrentScreen.server_settings_tab and CurrentScreen.server_settings_tab.game_mode.spinner.enabled then
                                                            --从mod中添加数据模式，并设置
        CurrentScreen.server_settings_tab.game_mode.spinner:SetOptions(_G.GetGameModesSpinnerData(_G.ModManager:GetEnabledServerModNames()))
                                                            --选择，有选择
        CurrentScreen.server_settings_tab.game_mode.spinner:SetSelected("sandstorm")
                                                            --改变
        CurrentScreen.server_settings_tab.game_mode.spinner:Changed()
                                                            -- 锁定值    
        CurrentScreen.server_settings_tab.game_mode.spinner:Disable()
        -- 主是显示
        -- --world_tabs第一个世界的设置(最多支持2个) worldsettings_widgets世界设置(1世界选项、2世界生成) settingslist设置列表scroll_list滚动列表widgets_to_update网格表opt_spinner选择器
        -- local scroll_list = CurrentScreen.world_tabs[1].worldsettings_widgets[2].settingslist.scroll_list
        -- -- 生物群落
        -- scroll_list.widgets_to_update [10].opt_spinner.spinner:SetSelected("cs_sz2")
        -- scroll_list.widgets_to_update[10].opt_spinner.spinner:Changed()        
        -- -- 设置出生点
        -- scroll_list.widgets_to_update[11].opt_spinner.spinner:SetSelected("cs_sl")
        -- scroll_list.widgets_to_update[11].opt_spinner.spinner:Changed()

        -- -- 重新加载一次预设
        -- for i, v in pairs(CurrentScreen.world_tabs[1].worldsettings_widgets) do
        --     v:LoadPreset() -- 重新加载预设
        -- end
    end
end