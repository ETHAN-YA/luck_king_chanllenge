--[[
Author: Ethan
Date: 2023-01-28 11:56:12
LastEditTime: 2023-03-03 13:21:04
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\modmain.lua
description:  
--]]
--[[
Author: Ethan
Date: 2023-01-28 11:56:12
LastEditTime: 2023-03-02 12:10:57
FilePath: \_scriptsd:\1\steamapps\common\Don't Starve Together\mods\luck_king_chanllenge\modmain.lua
description:  
--]]
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
--全部大写，最后面对应我们的预设物名
STRINGS.NAMES.MYBEARD = "一个简单的物品"    --显示的名字
STRINGS.CHARACTERS.GENERIC.DESCRIBE.MYBEARD = "你好"    --人物检查时说的话

local gamemode = _G.TheNet:GetServerGameMode()
if gamemode ~= "" and gamemode ~= "sandstorm" then
	print("[RF.ERROR] Forge mod was disabled because of not correct GameMode")
	return
else
end

_G.TUNING.FORGE = require "forge_tuning"
_G.COMMON_FNS = require "common_functions"

PrefabFiles = require("forge_prefabs")

for i, v in ipairs(PrefabFiles) do
	_G.TUNING.WINTERS_FEAST_LOOT_EXCLUSION[string.upper(v)] = true
end

AddUserCommand("updateuserscurrentperk", {
    prettyname = "Update Users Current Perk",
    desc = "Let the server know which perk you chose.",
    permission = _G.COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {"current_perk", "original_perk"},
    paramsoptional = {false, true},
    vote = false,
    hasaccessfn = function(command, caller, targetid)
    	return _G.COMMON_FNS.CheckCommand("updateuserscurrentperk", caller.userid)
    end,
    serverfn = function(params, caller)
    	if _G.TheWorld then
        	_G.TheWorld.net.components.command_manager:UpdateCommandCooldownForUser("updateuserscurrentperk", caller.userid)
        	local perk_tracker = _G.TheWorld.net.components.perk_tracker
			if perk_tracker then
				perk_tracker:SetCurrentPerk(caller.userid, params.current_perk, params.original_perk or params.current_perk)
			end
		end
    end,
})

AddComponentPostInit("lavaarenaeventstate", function(self)
	self.in_progress = _G.net_bool(self.inst.GUID, "lavaarenaeventstate.in_progress", "in_progressdirty")

	self.IsInProgress = function()
	    return self.in_progress:value()
	end
end)

if _G.rawget(_G, "FORGE_DBG") then
	modimport("scripts/forge_debug.lua")
end
-- Setup lobby voting
modimport("scripts/lobby_vote")

modimport("scripts/sandstorm_lobby.lua")

AddReplicableComponent("lobbyvote")