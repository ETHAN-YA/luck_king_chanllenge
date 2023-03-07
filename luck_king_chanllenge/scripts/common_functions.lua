local function IsScripter(userid)
    local script_data = _G.Settings.match_results and _G.Settings.match_results.outcome and _G.Settings.match_results.outcome.script_data or _G.TheFrontEnd.match_results and _G.TheFrontEnd.match_results.outcome and _G.TheFrontEnd.match_results.outcome.script_data
    return script_data and script_data[userid] and script_data[userid].exp_mult > 0
end

-------------
-- Network --
-------------
local function OnNewCenter(inst)
    local center_str = inst.center_point_str:value()
    local center_pos = ConvertStringToTable(center_str)
    inst.center_pos = center_str and Vector3(center_pos.x, center_pos.y, center_pos.z) or Vector3()
end

local FollowText = require "widgets/followtext"
local DEFAULT_OFFSET = _G.Vector3(0, -400, 0)
local function NetworkSetup(inst)
    -- Total Rounds and Waves
    local function OnWavesetData(inst)
        inst.waveset_data = _G.ConvertStringToTable(inst:GetWavesetData())
    end
    inst._waveset_data = _G.net_string(inst.GUID, "lavaarena_network._waveset_data", "wavesetdata")
    inst.waveset_data = {}
    if not _G.TheNet:IsDedicated() then
        inst:ListenForEvent("wavesetdata", OnWavesetData)
    end
    function inst:SetWavesetData(data)
        local waveset_data = {}
        for i = 1,#data do
            waveset_data[i] = #(data[i].waves)
        end
        inst._waveset_data:set(_G.SerializeTable(waveset_data))
    end
    function inst:GetWavesetData()
        return inst._waveset_data:value()
    end
    function inst:GetTotalRounds()
        return #inst.waveset_data
    end
    function inst:GetTotalWaves(round)
        return inst.waveset_data[round] or 0
    end

    function inst:GetForgeLord()
        return inst.forge_lord
    end

    function inst:SetForgeLord(forge_lord)
        inst.forge_lord = forge_lord
        inst:UpdateForgeLord()
    end

    function inst:UpdateForgeLord(previous_name)
        local current_name = _G.REFORGED_DATA.wavesets[_G.REFORGED_SETTINGS.gameplay.waveset].forge_lord
        local current_forge_lord = _G.GetForgeLord(nil, true)
        local previous_forge_lord = _G.GetForgeLord(previous_name)
        if inst.forge_lord and current_forge_lord and (previous_forge_lord == nil or previous_name ~= current_name) then
            if previous_forge_lord and previous_forge_lord.on_changed_from_fn then
                previous_forge_lord.on_changed_from_fn(inst.forge_lord)
            end
			inst.forge_lord.nameoverride = current_forge_lord.nameoverride or nil
            inst.forge_lord.AnimState:SetBank(current_forge_lord.bank or "boarlord")
            inst.forge_lord.AnimState:SetBuild(current_forge_lord.build or "boarlord")
            inst.forge_lord.AnimState:SetScale(current_forge_lord.scale[1] or -1, current_forge_lord.scale[2] or 1)
			if TheWorld.ismastersim and not TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
				inst.forge_lord:SetStateGraph(current_forge_lord.stategraph or "SGboarlord")
			end            
            inst.forge_lord.avatar = current_forge_lord.avatar
            if current_forge_lord and current_forge_lord.on_changed_to_fn then
                current_forge_lord.on_changed_to_fn(inst.forge_lord)
            end
        end
    end

    inst.admin_talker = _G.SpawnPrefab("reforged_admin_talker")
    function inst:GetAdminTalker()
        return inst.admin_talker
    end

    -- Gameplay Settings Update
    inst.settings_str      = net_string(inst.GUID, "lavaarena_network.gameplay_settings", "updategameplaysettings")
    inst.scripts_str       = net_string(inst.GUID, "lavaarena_network.scripts", "updatescripts")
    inst.chat_announce_str = net_string(inst.GUID, "lavaarena_network.chat_announce", "updatechatannounce")
    inst.center_pos        = inst.center_pos or Vector3(0,0,0)
    inst.center_point_str  = net_string(inst.GUID, "lavaarena_network.center_point_str", "new_center")
    if not _G.TheNet:IsDedicated() then
        inst:ListenForEvent("updategameplaysettings", function(inst, data)
            _G.REFORGED_SETTINGS.gameplay = _G.ConvertStringToTable(inst.settings_str:value())
            inst:UpdateForgeLord()
        end)
        local scripts_text_list = {}
        local function SetScripterHUD(HUD, scripts_text, player)
            if not (HUD and scripts_text and player) then return end
            scripts_text:SetTarget(player)
            for _,healthbar in pairs(HUD.controls.teamstatus.healthbars) do
                if healthbar.userid == player.userid then
                    healthbar.playername:SetColour(_G.unpack(_G.UICOLOURS.RED))
                    break
                end
            end
        end
        inst:ListenForEvent("updatescripts", function(inst, data)
            local HUD = _G.ThePlayer and _G.ThePlayer.HUD
            if not HUD then return end
            local scripts = _G.ConvertStringToTable(inst.scripts_str:value())
            for userid,_ in pairs(scripts) do
                if not scripts_text_list[userid] then
                    for __,player in pairs(_G.AllPlayers) do
                        if player.userid == userid then
                            local scripts_text = HUD:AddChild(FollowText(_G.TALKINGFONT, 35, STRINGS.NAMES.CHEATER))
                            scripts_text.text:SetColour(_G.unpack(_G.UICOLOURS.RED))
                            scripts_text:SetOffset(DEFAULT_OFFSET)
                            SetScripterHUD(HUD, scripts_text, player)
                            scripts_text_list[userid] = scripts_text
                            break
                        end
                    end
                end
            end
        end)
        inst:ListenForEvent("playerentered", function(inst, player)
            local userid = player and player.userid
            if userid and scripts_text_list[userid] then
                scripts_text_list[userid]:Show()
                SetScripterHUD(_G.ThePlayer and _G.ThePlayer.HUD, scripts_text_list[userid], player)
            end
        end, _G.TheWorld)
        inst:ListenForEvent("playerexited", function(inst, player)
            local userid = player and player.userid
            if userid and scripts_text_list[userid] then
                scripts_text_list[userid]:Hide()
            end
        end, _G.TheWorld)
        inst:ListenForEvent("updatechatannounce", function(inst, data)
            _G.Networking_Say(nil, nil, STRINGS.UI.LOBBYSCREEN.SERVER_ANNOUNCEMENT_NAME, nil, inst.chat_announce_str:value(), _G.UICOLOURS.WHITE)
        end)
        inst:ListenForEvent("new_center", OnNewCenter)
    end
    if _G.TheWorld.ismastersim then -- TODO is this still used?
        -- Initialize Gameplay Settings
        inst.settings_str:set(_G.SerializeTable(_G.REFORGED_SETTINGS.gameplay))
        inst.UpdateGameplaySettings = function()
            inst.settings_str:set(_G.SerializeTable(_G.REFORGED_SETTINGS.gameplay))
        end
        inst.scripts_list = {}
        function inst:UpdateScripts(player)
            local userid = player.userid
            if inst.scripts_list[userid] then return end
            inst.scripts_list[userid] = true
            inst.scripts_str:set(_G.SerializeTable(inst.scripts_list))
        end
        function inst:SendChatAnnouncement(message)
            inst.chat_announce_str:set(message)
        end
    end

    inst:AddComponent("worldvoter")

    if _G.TheWorld and _G.TheWorld.ismastersim then
        inst:AddComponent("lobbyvote")
        --inst:AddComponent("leaderboardmanager")
        inst:AddComponent("levelmanager")
        inst:AddComponent("achievementmanager")
        inst:AddComponent("mutatormanager")
        inst:AddComponent("serverinfomanager")
        --inst:AddComponent("fxnetwork")
        inst:AddComponent("perk_tracker")
        inst:AddComponent("command_manager")
        -- Sync Initial Gameplay Settings
        _G.TheWorld:ListenForEvent("ms_clientauthenticationcomplete", function()
            inst:UpdateGameplaySettings()
        end)

        local UserCommands = require "usercommands"
        --Leo: Overwrite /rescue because its not good at its job and is used to break even further oob.
        local rescue_command = UserCommands.GetCommandFromName("rescue")
        rescue_command.serverfn = function(params, caller)
            local pos = caller:GetPosition()
            if not _G.TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z, true) or _G.TheWorld.Map:IsGroundTargetBlocked(pos) then
                local portal = _G.TheWorld.multiplayerportal
                if portal then
                    caller.Physics:Teleport(portal:GetPosition():Get())
                else
                    _G.COMMON_FNS.ReturnToGround(caller)
                end
            end
        end

        -- Update kleis user commands to support our command manager
        local player_ready_command = UserCommands.GetCommandFromName("playerreadytostart")
        player_ready_command.hasaccessfn = function(command, caller, targetid)
            return _G.COMMON_FNS.CheckCommand("playerreadytostart", caller.userid)
        end
    end
end

local function PostInit(inst)
    inst:LongUpdate(0)
    inst.entity:FlushLocalDirtyNetVars()

    for k, v in pairs(inst.components) do
        if v.OnPostInit ~= nil then
            v:OnPostInit()
        end
    end
end

local function OnRemoveEntity(inst)
    if TheWorld ~= nil then
        assert(TheWorld.net == inst)
        TheWorld.net = nil
    end
end

local function DoPostInit(inst)
    if not TheWorld.ismastersim then
        if TheWorld.isdeactivated then
            --wow what bad timing!
            return
        end
        --master sim would have already done a proper PostInit in loading
        TheWorld:PostInit()
    end
    if not TheNet:IsDedicated() then
        if ThePlayer == nil then
            TheNet:SendResumeRequestToServer(TheNet:GetUserID())
        end
        PlayerHistory:StartListening()
    end
end

local function NetworkInit()
    local inst = CreateEntity()
    ------------------------------------------
    assert(TheWorld ~= nil and TheWorld.net == nil)
    TheWorld.net = inst
    ------------------------------------------
    inst.entity:SetCanSleep(false)
    inst.persists = false
    ------------------------------------------
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst.entity:SetPristine()
    ------------------------------------------
    inst:AddComponent("autosaver")
    inst:AddComponent("worldcharacterselectlobby")
    inst:AddComponent("lavaarenaeventstate")
    inst:AddComponent("bgm_manager_reforged")
    ------------------------------------------
    inst.PostInit = PostInit
    inst.OnRemoveEntity = OnRemoveEntity
    ------------------------------------------
    inst:DoTaskInTime(0, DoPostInit)
    ------------------------------------------
    NetworkSetup(inst)
    ------------------------------------------
    return inst
end

---------
-- Map --
---------
local function MapPreInit(inst, map_values)
    REFORGED_SETTINGS.gameplay.map = map_values.name or "lavaarena"
    MapLayerManager:SetSampleStyle(map_values.sample_style or MAP_SAMPLE_STYLE.MARCHING_SQUARES)
end

local function MapPostInit(inst, map_values)
    inst:AddComponent("ambientlighting")
    if map_values.ambient_lighting then
        inst:PushEvent("overrideambientlighting", Point(unpack(map_values.ambient_lighting)))
    end
    ------------------------------------------
    inst:AddComponent("lavaarenamobtracker")
    ------------------------------------------
    -- Dedicated server does not require these components
    -- NOTE: ambient lighting is required by light watchers
    if not TheNet:IsDedicated() then
        inst:AddComponent("ambientsound")
        ------------------------------------------
        inst:AddComponent("colourcube")
        if map_values.colour_cube then
            inst:PushEvent("overridecolourcube",  map_values.colour_cube)
        end
        ------------------------------------------
        inst:ListenForEvent("playeractivated", function(inst, player)
            if ThePlayer == player then
                TheNet:UpdatePlayingWithFriends()
            end
        end)
    end
end

local function FindNextValidSpawnerID(spawners)
    local current_index = 1
    for i,_ in ipairs(spawners) do
        current_index = i
    end
    return current_index
end

local function MapMasterPostInit(inst)
    -- Forge Event Manager
    inst:AddComponent("lavaarenaevent")
    inst:AddComponent("stat_tracker")
    inst:AddComponent("achievement_tracker")
    --inst:AddComponent("wavetracker") -- TODO not used at all? Should we take wave stuff out of lavaarenaevent, move it to wavetracker and then call that?
    ------------------------------------------
    -- Spawn Portal
    ------------------------------------------
    inst:ListenForEvent("ms_register_lavaarenaportal", function(inst, portal)
        inst.multiplayerportal = portal
    end)
    ------------------------------------------
    -- Mob Spawners
    ------------------------------------------
    inst.spawners = {}
    inst:ListenForEvent("ms_register_lavaarenaspawner", function(inst, data)
        local spawner_id = not inst.spawners[data.id] and data.id or FindNextValidSpawnerID(inst.spawners)
        if data.id ~= spawner_id then
            if not data.id then
                Debug:Print("Spawner has no ID and has been assigned the next valid id of " .. tostring(spawner_id) .. ".", "warning")
            elseif inst.spawners[data.id] then
                Debug:Print("Duplicate spawner ID detected. Assigning spawner a new valid id of " .. tostring(spawner_id) .. ".", "warning")
            end
            data.spawner.spawnerid = spawner_id
        end
        inst.spawners[spawner_id] = data.spawner
    end)
    ------------------------------------------
    -- Mob Tracker
    ------------------------------------------
    inst:AddComponent("forgemobtracker")
    local _onstoptrackingold = inst.components.lavaarenamobtracker._onremovemob
    inst.components.lavaarenamobtracker._onremovemob = function(mob)
        _onstoptrackingold(mob)
        inst:PushEvent("ms_lavaarena_mobgone") -- TODO what is this used for? if nothing then this function can be removed
    end
    ------------------------------------------
    -- Load Gametypes
    ------------------------------------------
    local gameplay_settings = _G.REFORGED_SETTINGS.gameplay
    local gametype = gameplay_settings.gametype
    local gametype_data = _G.REFORGED_DATA.gametypes[gametype]
    if gametype_data and gametype_data.fns.enable_server_fn then
        gametype_data.fns.enable_server_fn(inst)
    end
    ------------------------------------------
    local function OnPlayerDied(world, data)
        local self = world.components.lavaarenaevent
        -- End game if all players are dead
        if self.victory == nil and AreAllPlayersDead({[data.userid] = true}) then
            self:End(false)
        -- Let the Forge Lord know a player has died (ex. this will cause pugna to laugh)
        else
            local forge_lord = self:GetForgeLord()
            if forge_lord then
                forge_lord:PushEvent("player_died")
            end
        end
    end
    inst:ListenForEvent("ms_playerdied", OnPlayerDied)
    ------------------------------------------
    local function OnPlayerLeft(world, data)
        local self = world.components.lavaarenaevent
        if #AllPlayers == 0 then -- Reset world if no players are left in the server
            COMMON_FNS.ResetWorld()
        elseif self.start_time > 0 then -- Check if last player alive left the game.
            OnPlayerDied(world, data)
        end
    end
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
end

-- local function MapMasterPostInit(inst)
--     -- Forge Event Manager
--     inst:AddComponent("lavaarenaevent")
--     inst:AddComponent("stat_tracker")
--     inst:AddComponent("achievement_tracker")
--     --inst:AddComponent("wavetracker") -- TODO not used at all? Should we take wave stuff out of lavaarenaevent, move it to wavetracker and then call that?
--     ------------------------------------------
--     -- Spawn Portal
--     ------------------------------------------
--     inst:ListenForEvent("ms_register_lavaarenaportal", function(inst, portal)
--         inst.multiplayerportal = portal
--     end)
--     ------------------------------------------
--     -- Mob Spawners
--     ------------------------------------------
--     inst.spawners = {}
--     inst:ListenForEvent("ms_register_lavaarenaspawner", function(inst, data)
--         local spawner_id = not inst.spawners[data.id] and data.id or FindNextValidSpawnerID(inst.spawners)
--         if data.id ~= spawner_id then
--             if not data.id then
--                 Debug:Print("Spawner has no ID and has been assigned the next valid id of " .. tostring(spawner_id) .. ".", "warning")
--             elseif inst.spawners[data.id] then
--                 Debug:Print("Duplicate spawner ID detected. Assigning spawner a new valid id of " .. tostring(spawner_id) .. ".", "warning")
--             end
--             data.spawner.spawnerid = spawner_id
--         end
--         inst.spawners[spawner_id] = data.spawner
--     end)
--     ------------------------------------------
--     -- Mob Tracker
--     ------------------------------------------
--     inst:AddComponent("forgemobtracker")
--     local _onstoptrackingold = inst.components.lavaarenamobtracker._onremovemob
--     inst.components.lavaarenamobtracker._onremovemob = function(mob)
--         _onstoptrackingold(mob)
--         inst:PushEvent("ms_lavaarena_mobgone") -- TODO what is this used for? if nothing then this function can be removed
--     end
--     ------------------------------------------
--     -- Load Gametypes
--     ------------------------------------------
--     local gameplay_settings = _G.REFORGED_SETTINGS.gameplay
--     local gametype = gameplay_settings.gametype
--     local gametype_data = _G.REFORGED_DATA.gametypes[gametype]
--     if gametype_data and gametype_data.fns.enable_server_fn then
--         gametype_data.fns.enable_server_fn(inst)
--     end
--     ------------------------------------------
--     local function OnPlayerDied(world, data)
--         local self = world.components.lavaarenaevent
--         -- End game if all players are dead
--         if self.victory == nil and AreAllPlayersDead({[data.userid] = true}) then
--             self:End(false)
--         -- Let the Forge Lord know a player has died (ex. this will cause pugna to laugh)
--         else
--             local forge_lord = self:GetForgeLord()
--             if forge_lord then
--                 forge_lord:PushEvent("player_died")
--             end
--         end
--     end
--     inst:ListenForEvent("ms_playerdied", OnPlayerDied)
--     ------------------------------------------
--     local function OnPlayerLeft(world, data)
--         local self = world.components.lavaarenaevent
--         if #AllPlayers == 0 then -- Reset world if no players are left in the server
--             COMMON_FNS.ResetWorld()
--         elseif self.start_time > 0 then -- Check if last player alive left the game.
--             OnPlayerDied(world, data)
--         end
--     end
--     inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
-- end
local function CheckCommand(name, userid, conditional_fn)
    return TheWorld ~= nil and (not TheWorld.ismastersim or (TheWorld.net.components.command_manager == nil or TheWorld.net.components.command_manager:IsCommandReadyForUser(name, userid, conditional_fn)))
end

return {
    IsScripter                   = IsScripter,
    CheckCommand                 = CheckCommand,
    -- Map
    MapPreInit        = MapPreInit,
    MapPostInit       = MapPostInit,
    MapMasterPostInit = MapMasterPostInit,
    -- Network
    NetworkInit  = NetworkInit,
    NetworkSetup = NetworkSetup,
    -- Map
    -- MapMasterPostInit = MapMasterPostInit,
}