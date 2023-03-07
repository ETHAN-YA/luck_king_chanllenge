--[[
Author: Ethan
Date: 2023-01-28 11:50:02
LastEditTime: 2023-02-01 23:48:34
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\modinfo.lua
description:  
--]]
--[[
Author: Ethan
Date: 2023-01-28 11:50:02
LastEditTime: 2023-01-28 11:50:02
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\modinfo.lua
description:  
--]]


name = "luck_king_chanllenge"  ---mod名字
description = "你好，世界"  --mod描述
author = "我" --作者
version = "1.0" -- mod版本 上传mod需要两次的版本不一样

forumthread = ""    --和官方论坛相关，一般不填

api_version = 10    --api版本，现在版本写10就行

dst_compatible = true --是否兼容联机

dont_starve_compatible = false --是否兼容原版
reign_of_giants_compatible = false --是否兼容巨人DLC
forge_compatible = true --是否兼容熔炉

all_clients_require_mod = true --所有人都需要mod，true就是

icon_atlas = "modicon.xml" --mod图标
icon = "modicon.tex"

-- server_filter_tags = {  --服务器标签
-- 	"reforged",
-- 	"the forged forge",
-- }

game_modes = {
	{
        name = "sandstorm",
		label = "Sandstorm",
		settings = {
			level_type = "SANDSTORM",
			spawn_mode = "fixed",
			resource_renewal = false,
			ghost_sanity_drain = false,
			ghost_enabled = false,
			revivable_corpse = true,
			spectator_corpse = true,
			portal_rez = false,
			reset_time = nil,
			invalid_recipes = nil,
			--
			override_item_slots = 0,
            drop_everything_on_despawn = true,
			no_air_attack = true,
			no_crafting = true,
			no_minimap = true,
			no_hunger = true,
			no_sanity = true,
			no_avatar_popup = true,
			no_morgue_record = true,
			override_normal_mix = "lavaarena_normal",
			override_lobby_music = "dontstarve/music/lava_arena/FE2",
			cloudcolour = { .4, .05, 0 },
			cameraoverridefn = function(camera)
				camera.mindist = 20
				camera.mindistpitch = 32
				camera.maxdist = 55
				camera.maxdistpitch = 60
				camera.distancetarget = 32
			end,
			lobbywaitforallplayers = true,
			hide_worldgen_loading_screen = true,
			hide_received_gifts = false,
			skin_tag = "LAVA",
		},
	}
}

-- game_modes = {
-- 	{
--         name = "lavaarena",
-- 		label = "The forge!",
-- 		settings = {
-- 			level_type = "LAVAARENA",
-- 			spawn_mode = "fixed",
-- 			resource_renewal = false,
-- 			ghost_sanity_drain = false,
-- 			ghost_enabled = false,
-- 			revivable_corpse = true,
-- 			spectator_corpse = true,
-- 			portal_rez = false,
-- 			reset_time = nil,
-- 			invalid_recipes = nil,
-- 			--
-- 			override_item_slots = 0,
--             drop_everything_on_despawn = true,
-- 			no_air_attack = true,
-- 			no_crafting = true,
-- 			no_minimap = true,
-- 			no_hunger = true,
-- 			no_sanity = true,
-- 			no_avatar_popup = true,
-- 			no_morgue_record = true,
-- 			override_normal_mix = "lavaarena_normal",
-- 			override_lobby_music = "dontstarve/music/lava_arena/FE2",
-- 			cloudcolour = { .4, .05, 0 },
-- 			cameraoverridefn = function(camera)
-- 				camera.mindist = 20
-- 				camera.mindistpitch = 32
-- 				camera.maxdist = 55
-- 				camera.maxdistpitch = 60
-- 				camera.distancetarget = 32
-- 			end,
-- 			lobbywaitforallplayers = true,
-- 			hide_worldgen_loading_screen = true,
-- 			hide_received_gifts = false,
-- 			skin_tag = "LAVA",
-- 		},
-- 	}
-- }

-- GAME_MODES = {
-- 	{
--         name = "lavaarena",
-- 		label = "The Forge",
-- 		settings = {
-- 			level_type = "LAVAARENA",
-- 		},
-- 	}
-- }

--[[  取消注释，在这行前面加个-就行。可选的mod设置，在modmain里面用 GetModConfigData("test_name") 来获取值，data只能是boolean/string/number
configuration_options = {
	{
		name = "test_name",
		label = "一直显示的选项标题",
		hover = "选中时最上面显示的提示",
		options =		
			{
				{description = "选项1", data = true, hover = "提示1"},
				{description = "选项2", data = false, hover = "提示2"},		
			},
		default = true,
	},
}
--]]

