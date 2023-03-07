local Text = require("widgets/text") --Text类，文本处理
local Widget = require("widgets/widget")
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"
local LobbyVoteDialog = require "widgets/lobbyvotedialog"
local ImageButton = require "widgets/imagebutton"

_G.COMMON_FNS = require "common_functions"
-- _G.UICOLOURS = require("constants")
--Fixing the lobby screen
local LobbyScreen = require("screens/redux/lobbyscreen")
-- Replace the client side event file saving with our own.
local _old_ctor = LobbyScreen._ctor
LobbyScreen._ctor = function(self, profile, cb) -- TODO need to replace the entire function, can't set the stats before and after, other functions need it in the middle of the call
	_G.Settings.temp_player_stats =  _G.Settings.match_results.player_stats and _G.deepcopy(_G.Settings.match_results.player_stats)
	local exp_data = _G.Settings.match_results.wxp_data and _G.Settings.match_results.wxp_data[_G.TheNet:GetUserID()]
	_G.TheFrontEnd.match_results.match_xp = exp_data and exp_data.match_xp or 0 -- Used for total exp display
	_G.Settings.match_results.player_stats = nil
	local front_end = _G.TheFrontEnd.match_results.player_stats and _G.deepcopy(_G.TheFrontEnd.match_results.player_stats)
	_G.TheFrontEnd.match_results.player_stats = nil
	_old_ctor(self, profile, cb)
	_G.Settings.match_results.player_stats = _G.Settings.temp_player_stats
	_G.TheFrontEnd.match_results.player_stats = front_end
	-- if not _G.TheNet:IsDedicated() then
	-- 	_G.SaveEventMatchStats()
	-- end
end

local _oldToNextPanel = LobbyScreen.ToNextPanel
LobbyScreen.ToNextPanel = function(self, dir)
	_oldToNextPanel(self, dir)
	if _G.TheNet:GetServerGameMode() == "sandstorm" and self.panel and self.panel.name then
		if self.panel.name == "CharacterSelectPanel" then
            print("+++++++++++++ CharacterSelectPanel")
			self.panel:SetPosition(0, 150) -- I have no idea why Klei offsets it.
		-- elseif self.panel.name == "WaitingPanel" then
        --     print("+++++++++++++ WaitingPanel +++++++")
		-- 	self.next_button:Enable() --BANDAIIIID
		-- 	self.next_button.inst:DoTaskInTime(_G.FRAMES * 5, function() self.next_button:_RefreshImageState() end) -- Fox: Skip one frame to run this after constructor
		else 
			print("++++++++++++++++++ panel.name", self.panel.name)
			print("++++++++++++++++++ _G.GetGameModeProperty", _G.GetGameModeProperty("lobbywaitforallplayers"))
		end
	end
end

AddClassPostConstruct( "widgets/playerbadge", function(self)
    local _oldSet = self.Set
    self.Set = function(self, prefab, colour, ishost, userflags)
        local is_loading_icon = self.loading_icon.shown
        _oldSet(self, prefab, colour, ishost, userflags)
        local parent = self:GetParent()
        local userid = parent and parent.userid
        if self.ishost ~= ishost then
            self.ishost = ishost
        end
        if self.isHost then
            self.headframe:SetTint(unpack(_G.UICOLOURS.RED))
            self.head:SetTint(unpack(_G.UICOLOURS.RED))
            self.headbg:SetTint(unpack(_G.UICOLOURS.RED))
        else
            if self:IsLoading() then
                if not is_loading_icon then
                    self.head:SetTint(0,0,0,1)
                end
            else
                self.head:SetTint(1,1,1,1)
                self.headbg:SetTint(1,1,1,1)
            end
        end
    end
end)

function RemoveTask(task, param)
	if task then
        if param ~= nil and task[param] then
             task[param]:Cancel()
             task[param] = nil
        elseif param == nil then
            task:Cancel()
        end
	end
end

key = ""
function PrintTable(table , level)
  level = level or 1
  local indent = ""
  for i = 1, level do
    indent = indent.."  "
  end

  if key ~= "" then
    print(indent..key.." ".."=".." ".."{")
  else
    print(indent .. "{")
  end

  key = ""
  for k,v in pairs(table) do
     if type(v) == "table" then
        key = k
        PrintTable(v, level + 1)
     else
        local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
      print(content)  
      end
  end
  print(indent .. "}")

end

------------------------------
-- Force Start/Cancel Setup --
------------------------------
local UserCommands = require "usercommands"
local FadeableText = require "widgets/fadeable_text"
local PlayerList = require "widgets/redux/playerlist"
local TEMPLATES = require "widgets/redux/templates"
local LobbyVoteDialog = require "widgets/lobbyvotedialog"
local FadeableText = require "widgets/fadeable_text"

local subfmt = _G.subfmt
local next = _G.next
local assert = _G.assert
local tonumber = _G.tonumber
local getlocal = _G.debug.getlocal
local getupvalue = _G.debug.getupvalue
local setupvalue = _G.debug.setupvalue
local getinfo = _G.debug.getinfo
AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
	-- new inst vars
	self.countdown_started = false
	self.countdown_time = 255
	self.spawndelaytext = self.panel_root:AddChild(Text(_G.CHATFONT, 50))
    self.spawndelaytext:SetPosition(0, -290)
    self.spawndelaytext:SetColour(_G.UICOLOURS.GOLD)
    self.spawndelaytext:Hide()

    if _G.rawget(_G, "TheFrontEnd") then
		self.announcementtext = _G.TheFrontEnd.overlayroot:AddChild(FadeableText(_G.CHATFONT, 50))
		self.announcementtext:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)
		self.announcementtext:SetMaxPropUpscale(_G.MAX_HUD_SCALE)
		self.announcementtext:SetVAnchor(_G.ANCHOR_TOP)
		self.announcementtext:SetHAnchor(_G.ANCHOR_MIDDLE)
		self.announcementtext:SetPosition(0, -25)
		self.announcementtext:SetColour(_G.UICOLOURS.GOLD)
		self.announcementtext:Hide()

		-- if _G.CHEATS_ENABLED then
		-- 	_G.rawset(_G, "ann", self.announcementtext)
		-- end
	else
		self.announcementtext = self.panel_root:AddChild(Text(_G.CHATFONT, 50))
		self.announcementtext:SetPosition(0, 330)
		self.announcementtext:SetColour(_G.UICOLOURS.GOLD)
		self.announcementtext:Hide()
	end

    self.lobby_name_text = self.root:AddChild(Text(_G.CHATFONT, 25))
    self.lobby_name_text:SetPosition(-_G.RESOLUTION_X/2-5 + 175, 340) -- Numbers received from chatsidebar, 375 is max height
    self.lobby_name_text:SetColour(_G.UICOLOURS.GOLD)
    self.lobby_name_text:SetTruncatedString(_G.TheNet:GetServerName(), 300, 50)

    -- Dedicated server icon
    if _G.TheNet:GetServerIsDedicated() then
    	self.dedicated_server_icon = self.root:AddChild(Image("images/servericons.xml", "dedicated.tex"))
    	local dedi_icon_size = 30
    	self.dedicated_server_icon:ScaleToSize(dedi_icon_size, dedi_icon_size, true)
    	self.dedicated_server_icon:SetPosition(-_G.RESOLUTION_X/2-5 + dedi_icon_size/2 + 5, 310)
    end

    local old_OnControl = self.OnControl
	self.OnControl = function(self, control, down)
		if not self.enabled then
			return false
		end

		-- breaks the MVP widget
		--if self._base.OnControl(self, control, down) then return true end

		-- make it so cant use "escape" to disconnect or go back if back button is disabled and <= 5 on countdown
		if not down and control == _G.CONTROL_CANCEL and not self.back_button.enabled and self.countdown_started and self.countdown_time <= 5 then
			return false
		end

		return old_OnControl(self, control, down)
	end

    local function StartGame(this)
		if this.startbutton then
			this.startbutton:Disable()
			this.startbutton:Hide()
		end

		if this.cb then
			local skins = this.currentskins
			this.cb(this.character_for_game, skins.base, skins.body, skins.hand, skins.legs, skins.feet) --parameters are base_prefab, skin_base, clothing_body, clothing_hand, then clothing_legs
		end
	end

    self.startbutton = self.root:AddChild(TEMPLATES.StandardButton(function() StartGame(self) end, "就是这里", {200, 50}))
	self.startbutton:SetPosition(500, self.back_button:GetPosition().y - 5)
	self.startbutton:Hide()

    local old_ToNextPanel = self.ToNextPanel
    -- logical for next and start buttion
	self.ToNextPanel = function(self, dir)
		old_ToNextPanel(self, dir)
		print("+++++++++++++++++++++ count down ", self.countdown_started)
		if self.countdown_started then
			-- panel we want to go to has a disconnect button and time <= 5, hide it, otherwise show em
			if self.countdown_time <= 5 and (self.back_button.text:GetString() == STRINGS.UI.LOBBYSCREEN.DISCONNECT or self.panel.title == STRINGS.UI.LOBBYSCREEN.WAITING_FOR_PLAYERS_TITLE) then
				print("+++++++++++++++++++ ToNextPanel count down")
				self.back_button:Hide()
				self.back_button:Disable()
			else
				print("+++++++++++++++++++ ToNextPanel count down Enable")
				self.back_button:Enable()
				self.back_button:Show()
			end
			self.spawndelaytext:Show()
			-- waiting for players, set their countdown to active to immediately start their countdown text n tick sound, otherwise display our lobbyscreen one
			if self.panel.title == STRINGS.UI.LOBBYSCREEN.WAITING_FOR_PLAYERS_TITLE then
				self.panel.waiting_for_players.spawn_countdown_active = true
			else
				self.spawndelaytext:Show()
			end
		end
		-- Add a spawn button if forge is in progress and hide the vote to start option
		-- if _G.TheWorld.net.components.lavaarenaeventstate and _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() and self.panel.title == STRINGS.UI.LOBBYSCREEN.WAITING_FOR_PLAYERS_TITLE then
		-- if self.panel.title == STRINGS.UI.LOBBYSCREEN.WAITING_FOR_PLAYERS_TITLE then
		if false then
			print("++++++++++++++++ show false")
			self.startbutton:Show()
			self.panel.waiting_for_players.playerready_checkbox:Hide()
		else
			self.startbutton:Hide()
		end
	end

    -- Random Character and Skin
    local function PickRandomCharacterAndSkins()
		if self.character_for_game == nil then
			--local all_chars = _G.ExceptionArrays(_G.GetActiveCharacterList(), _G.MODCHARACTEREXCEPTIONS_DST)
			--self.character_for_game = "random"--all_chars[math.random(#all_chars)]
			-- Go to loadout panel and select random character. If already at the loadout panel then the currently selected character will be used.
			local loadout_panel_index = #self.panels > 3 and 3 or 2
			print("+++++++++++++++ PickRandomCharacterAndSkins", #self.panels)
			if self.current_panel_index ~= loadout_panel_index then
				self.lobbycharacter = "random"
				self:ToNextPanel(loadout_panel_index - self.current_panel_index)
			end
			-- Go to waiting panel
			self.next_button.onclick()
		end
	end

    local function OnCountdown()
		if self.countdown_started then
			-- make users pop disconnect/ready/any dialog box if countdown <= 5
			local active_screen = _G.TheFrontEnd:GetActiveScreen()
			if active_screen and active_screen.name and active_screen.name == "PopupDialogScreen" and (active_screen.dialog.title:GetString() == "Confirm Force Start" or self.countdown_time <= 5) then
				_G.TheFrontEnd:PopScreen()
			end
			-- if time <= 5, dont show disconnect button and dont show back button for waiting panel
			if self.countdown_time <= 5 and (self.back_button.text:GetString() == STRINGS.UI.LOBBYSCREEN.DISCONNECT or self.panel.title == STRINGS.UI.LOBBYSCREEN.WAITING_FOR_PLAYERS_TITLE) then
				self.back_button:Hide()
				self.back_button:Disable()
			else
				self.back_button:Enable()
				self.back_button:Show()
			end
			-- always update our countdown incase it is shown offtick
			local str = _G.subfmt(STRINGS.UI.LOBBY_WAITING_FOR_PLAYERS_SCREEN.SPAWN_DELAY, { time = math.max(0, self.countdown_time) })
			if str ~= self.spawndelaytext:GetString() then
				self.spawndelaytext:SetString(str)
			end
			-- on countdown tick check to see if at waiting players, if so hide our countdown, else play sound and show
			if self.panel.title ~= STRINGS.UI.LOBBYSCREEN.WAITING_FOR_PLAYERS_TITLE then
				self.spawndelaytext:Show()
				_G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/WorldDeathTick")
			else
				self.spawndelaytext:Hide()
			end
		else
			self.spawndelaytext:Hide()
			self.spawndelaytext:SetString("")
			self.back_button:Enable()
			self.back_button:Show()
			if self.panel.title == STRINGS.UI.LOBBYSCREEN.WAITING_FOR_PLAYERS_TITLE then
				local children = self.panel.waiting_for_players:GetChildren()
				for i, child in pairs(children) do
					-- Currently only 2 children, but technically the only thing that should be hidden is the countdown so should be fine.
					if child.name == "Text" then
						child:Hide()
					else
						child:Show()
					end
				end
				self.panel.waiting_for_players.spawn_countdown_active = false
				self.panel.waiting_for_players.playerready_checkbox.checked = false
				self.panel.waiting_for_players.playerready_checkbox.votestart_warned = false
				self.panel.waiting_for_players.playerready_checkbox:Enable()
				self.panel.waiting_for_players.playerready_checkbox:Refresh()
			end
		end
	end

    self.inst:ListenForEvent("lobbyplayerspawndelay", function(world, data)
        if data then
			-- if 1 second left on clock, force character/skin selection
			if data.active and data.time == 1 then
				PickRandomCharacterAndSkins()
			end
			self.countdown_started = data.active
			print("+++++++++++++++++++ data.active", data.active)
			-- subtract one so we hang on 0 for a second
			self.countdown_time = self.countdown_started and (data.time - 1) or 255
			OnCountdown()
        end
		print("+++++++++++++++++ data is nil")
    end, _G.TheWorld)

    self.vote_root = self:AddChild(Widget("vote_root"))
    self.vote_root:SetVAnchor(_G.ANCHOR_TOP)
    self.vote_root:SetHAnchor(_G.ANCHOR_RIGHT)
    self.vote_root:SetPosition(-200,0,0)
    self.vote_menu = self.vote_root:AddChild(LobbyVoteDialog(self))

    function self:DisplayAnnouncement(str)
		local clr = _G.UICOLOURS.GOLD
		local hide_clr = {clr[1], clr[2], clr[2], 0}
		self.announcementtext:FadeTo(hide_clr, clr, 0.25)
		self.announcementtext:SetString(str)
		self.announcementtext:Show()
		RemoveTask(self.announce_timer)
		self.announce_timer = self.inst:DoTaskInTime(3, function()
			self.announcementtext:FadeTo(clr, hide_clr, 0.25, function()
				self.announcementtext:Hide()
			end)
		end)
	end

    local character_select_panel_index = #self.panels > 3 and 2 or 1
	print("+++++++++++++++++++ #self.panels", #self.panels)
	print("+++++++++++++++++++ character_select_panel_index", character_select_panel_index)
	print("+++++++++++++++++++ character_select_panel_index", self.panels[character_select_panel_index])
	character_select_panel_index = 2
	local _oldCharacterSelectPanelFN = self.panels[character_select_panel_index].panelfn
    self.panels[character_select_panel_index].panelfn = function(self)
		local panel = _oldCharacterSelectPanelFN(self)

		panel.next_button_title = GetGameModeProperty("lobbywaitforallplayers") and STRINGS.UI.LOBBYSCREEN.SELECT

		local _oldOnNextButton = panel.OnNextButton
		local owner = self
		print("+++++++++++++++++++ #self.panels character_select_panel_index", #self.panels)
		panel.OnNextButton = function(self)
			local server_shutting_down = TheWorld ~= nil and TheWorld.net ~= nil and TheWorld.net.components.worldcharacterselectlobby ~= nil and TheWorld.net.components.worldcharacterselectlobby:IsServerLockedForShutdown()
			print("+++++++++++++++++++ server_shutting_down", server_shutting_down)
			print("+++++++++++++++++++ GetGameModeProperty", GetGameModeProperty("lobbywaitforallplayers"))
			local portrait = panel.character_scroll_list.selectedportrait
			UserCommands.RunUserCommand("updateuserscurrentperk", {current_perk = portrait.current_perks[portrait.selected_perk_index].name}, _G.TheNet:GetClientTableForUser(_G.TheNet:GetUserID()))
			return _oldOnNextButton(self)
		end

		return panel
	end

	local loadout_panel_index = #self.panels > 3 and 3 or 2
	print("++++++++++++++++ loadout_panel_index", loadout_panel_index)
	print("++++++++++++++++ load #seld.panels", #self.panels)
	print("+++++++++++++++ self.panels", self.panels[loadout_panel_index])
	local gamemode = _G.TheNet:GetServerGameMode()
	print("+++++++++++++++ gamemode", gamemode)
	loadout_panel_index = 2
	local _oldLoadoutSelectPanelFN = self.panels[loadout_panel_index].panelfn
	print("+++++++++++++++ 297 is ok")
	self.panels[loadout_panel_index].panelfn = function(self)
		local panel = _oldLoadoutSelectPanelFN(self)

		-- Remove spectator as a possibility for a random character.
		local _oldOnNextButton = self.OnNextButton
		local owner = self
		print("+++++++++++++++++++ #self.panels loadout_panel_index", #self.panels)
		panel.OnNextButton = function(self)
			owner.currentskins = self.loadout.selected_skins
			owner.character_for_game = self.loadout.currentcharacter

		    owner.profile:SetCollectionTimestamp(_G.GetInventoryTimestamp())

			if not _G.IsCharacterOwned( owner.character_for_game ) then
				_G.DisplayCharacterUnownedPopup( owner.character_for_game, self.loadout.subscreener )
				return false
			end

	        --We can't be random character at this point
			if owner.character_for_game == "random" then
				local char_list = _G.GetActiveCharacterList()

				--remove unowned characters
				for i = #char_list, 1, -1 do
					if not _G.IsCharacterOwned(char_list[i]) or char_list[i] == "spectator" then
						table.remove(char_list, i)
					end
				end

			    local all_chars = _G.ExceptionArrays(char_list, _G.MODCHARACTEREXCEPTIONS_DST)
			    local current_perk = "full_random"
			    local perk_info = {
					TITLE       = "Full Random",
					DESCRIPTION = "Selects a random character and a random perk.",
					STARTING_ITEMS = "Starting items of the randomly selected characters loadout.",
				}
			    owner.character_for_game = perk_info and perk_info.fn and perk_info.fn(all_chars) or all_chars[math.random(#all_chars)]

	            local bases = owner.profile:GetSkinsForPrefab(owner.character_for_game)
	            owner.currentskins.base = _G.GetRandomItem(bases)
	        else
	            self.loadout:_SaveLoadout() --only save the loadout when it's not a random character
	        end
			print("++++++++++++++++++++ GetGameModeProperty before start", _G.GetGameModeProperty("lobbywaitforallplayers"))
			if _G.GetGameModeProperty("lobbywaitforallplayers") then
				print("+++++++++++++++++++++++  start game before ", _G.GetGameModeProperty("lobbywaitforallplayers"))
				if owner.lobbycharacter == "random" then
					_G.TheNet:SendLobbyCharacterRequestToServer("random")
				else
					local skins = owner.currentskins
					_G.TheNet:SendLobbyCharacterRequestToServer(owner.lobbycharacter, skins.base, skins.body, skins.hand, skins.legs, skins.feet)
				end
				return true
			else
				print("+++++++++++++++++++++++  start game before false")
				StartGame(owner)
				return false
			end
		end

		--[[
		local _oldPanelOnShow = panel.OnShow
		panel.OnShow = function(self)
			if true then
			else
				_oldPanelOnShow(self)
			end
		end--]]
		return panel
	end
	print("+++++++++++++++ 362 is ok")
    local function SpawnSpectator()
		if true and _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() or true then
			_G.TheFrontEnd:PopScreen()
			_G.TheNet:SendSpawnRequestToServer("spectator")
		end
	end
	-- Set fade callback function so that player is spawned as soon as screen has finished fading into the lobby.
	_G.TheWorld:ListenForEvent("entercharacterselect", function()
		--_G.TheFrontEnd.fadecb = SpawnSpectator
	end)
	print("+++++++++++++++ 373 is ok")
end)

---------------------------------------------------------------------------------------------------------------------------

local function FindUpvalue(fn, upvalue_name)
	assert(type(fn) == "function", "Function expected as 'fn' parameter.")
	local info = getinfo(fn, "u")
	local nups = info and info.nups
	if not nups then return end
	for i = 1, nups do
		local name, val = getupvalue(fn, i)
		if name == upvalue_name then
			return val, i
		end
	end
end

-- ugly but easiest way to change size of playerinfolist
local PlayerInfoListing_width, PlayerInfoListing_widthIndex = FindUpvalue(PlayerList.BuildPlayerList, "PlayerInfoListing_width")
if PlayerInfoListing_widthIndex then
	setupvalue(PlayerList.BuildPlayerList, PlayerInfoListing_widthIndex, PlayerInfoListing_width + 30)
else
	_G.Debug:Print("Failed to find PlayerInfoListing_width upvalue!", "error")
end

local function SendCommand(fnstr)
	local x, _, z = _G.TheSim:ProjectScreenPos(_G.TheSim:GetPosition())
	local is_valid_time_to_use_remote = _G.TheNet:GetIsClient() and _G.TheNet:GetIsServerAdmin()
	if is_valid_time_to_use_remote then
		_G.TheNet:SendRemoteExecute(fnstr, x, z)
	else
		_G.ExecuteConsoleCommand(fnstr)
	end
end

local old_BuildPlayerList = PlayerList.BuildPlayerList
PlayerList.BuildPlayerList = function(self, players, nextWidgets)

	old_BuildPlayerList(self, players, nextWidgets)

	local this_user = _G.TheNet:GetClientTableForUser(_G.TheNet:GetUserID())

	self.match_countdown = false
	local function UpdateForceStart(has_started)
		if self.match_countdown ~= has_started then
			self.match_countdown = has_started
			if self.scroll_list and self.scroll_list.old_update then
				local all_playerInfoListings = self.scroll_list:GetListWidgets()
				for i, listing in ipairs(all_playerInfoListings) do
					if listing.forcestart then
						if self.match_countdown then
							listing.forcestart.image_focus = "cancel.tex"
							listing.forcestart:SetHoverText(this_user.admin and STRINGS.UI.LOBBYSCREEN.CANCELSTART or STRINGS.REFORGED.VOTE.CANCEL_START)
							listing.forcestart.image:SetTexture("images/force_start.xml", "cancel.tex")
							listing.forcestart:SetTextures("images/force_start.xml", "cancel.tex")
						else
							listing.forcestart.image_focus = "start.tex"
							listing.forcestart:SetHoverText(this_user.admin and STRINGS.UI.LOBBYSCREEN.FORCESTART or STRINGS.REFORGED.VOTE.FORCE_START_TITLE)
							listing.forcestart.image:SetTexture("images/force_start.xml", "start.tex")
							listing.forcestart:SetTextures("images/force_start.xml", "start.tex")
						end
					end
				end
			end
		end
	end

	self.inst:ListenForEvent("lobbyplayerspawndelay", function(world, data)
		if data then
			UpdateForceStart(data.active)
		end
	end, _G.TheWorld)

	if not self.scroll_list.old_update then
		local MOVE_RIGHT = _G.MOVE_RIGHT
		local MOVE_LEFT = _G.MOVE_LEFT
		local MOVE_DOWN = _G.MOVE_DOWN
		local x_offset = 29
		local all_playerInfoListings = self.scroll_list:GetListWidgets()
		local old_mute_position = all_playerInfoListings[1].mute and all_playerInfoListings[1].mute:GetPosition()
		local old_viewprofile_position = all_playerInfoListings[1].viewprofile and all_playerInfoListings[1].viewprofile:GetPosition()
		local old_netscore_position = all_playerInfoListings[1].netscore and all_playerInfoListings[1].netscore:GetPosition()
		for i, listing in ipairs(all_playerInfoListings) do

			listing.empty = not listing.bg:IsVisible()

			-- hardcoded scaling since they did too
			listing.highlight:ScaleToSize(250,50)
			local highlight_position = listing.highlight:GetPosition()
			listing.highlight:SetPosition(highlight_position.x + 13.5, 0)	-- 13.5 looks good

			listing.kick = listing:AddChild(ImageButton("images/scoreboard.xml", "kickout.tex", "kickout.tex", "kickout_disabled.tex", "kickout.tex", nil, {1,1}, {0,0}))
			listing.kick:SetPosition(old_mute_position.x + x_offset, 0)
			listing.kick:SetNormalScale(0.234)
			listing.kick:SetFocusScale(0.234 * 1.1)
			listing.kick:SetFocusSound("dontstarve/HUD/click_mouseover")
			listing.kick:SetHoverText(this_user.admin and STRINGS.UI.PLAYERSTATUSSCREEN.KICK or STRINGS.REFORGED.VOTE.KICK_PLAYER, { font = _G.NEWFONT_OUTLINE, offset_x = -35, offset_y = 0, colour = {1,1,1,1} })
			listing.kick:SetOnClick(function()
				-- doesnt really matter since will be updated
				if listing.userid then
					if this_user.admin then
						UserCommands.RunUserCommand("kick", { user = listing.userid }, this_user)
					else
						local params_str = _G.SerializeTable({target_id = listing.userid})
						UserCommands.RunUserCommand("lobbyvotestart", {command = "kick", force_success = "false", params_str = params_str}, this_user)
					end
				end
			end)
			-- empty, admin, or if its yourself, hide kick (no voting...)
			if listing.empty or this_user.admin or (listing.userid and listing.userid == this_user.userid) then
				listing.kick:Hide()
			else
				listing.kick:Show()
			end

			listing.forcestart = listing:AddChild(ImageButton("images/force_start.xml", "start.tex"))
			listing.forcestart:SetPosition(old_mute_position.x + x_offset, 0)
			-- same scale as theirs for 100x100px icon
			listing.forcestart:SetNormalScale(0.234)
			listing.forcestart:SetFocusScale(0.234 * 1.1)
			-- 0.6 makes it look about same birghtness as other buttons
			listing.forcestart.image:SetTint(1, 1, 1, 0.6)
			listing.forcestart:SetFocusSound("dontstarve/HUD/click_mouseover")
			listing.forcestart:SetHoverText(this_user.admin and STRINGS.UI.LOBBYSCREEN.FORCESTART or "Vote to Force Start", { font = _G.NEWFONT_OUTLINE, offset_x = -50, offset_y = 0, colour = {1,1,1,1} })
			listing.forcestart:SetOnClick(function()
				if self.match_countdown then
					if this_user.admin then
						SendCommand("TheWorld.net.components.worldcharacterselectlobby:CancelForceStart()")
						_G.TheNet:Say(STRINGS.UI.LOBBYSCREEN.SAYCANCEL)
					else
						UserCommands.RunUserCommand("lobbyvotestart", {command = "cancel_force_start", force_success = "false"}, this_user)
					end
				elseif not _G.AreClientsLoading() then
					if this_user.admin then
						_G.TheFrontEnd:PushScreen(
							PopupDialogScreen(STRINGS.UI.LOBBYSCREEN.FORCESTARTTITLE,
							string.format(STRINGS.UI.LOBBYSCREEN.FORCESTARTDESC, _G.REFORGED_SETTINGS.force_start_delay), {
								{ text = STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function()
									_G.TheFrontEnd:PopScreen()
									if not self.match_countdown and not _G.AreClientsLoading() then
										SendCommand("TheWorld.net.components.worldcharacterselectlobby:ForceStart(" .. tostring(_G.REFORGED_SETTINGS.force_start_delay) .. ")")
										_G.TheNet:Say(string.format(STRINGS.UI.LOBBYSCREEN.SAYSTART, _G.REFORGED_SETTINGS.force_start_delay))
									end
								end },
								{ text = STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() _G.TheFrontEnd:PopScreen() end }
							} )
						)
					else
						UserCommands.RunUserCommand("lobbyvotestart", {command = "force_start", force_success = "false"}, this_user)
					end
				end
			end)

			-- by default move netscore to right edge of new listing
			listing.netscore:SetPosition(old_netscore_position.x + x_offset, 0)

			-- new focus that changes based on if empty or not, klei bug fix
			listing.OnGainFocus = function()
				if not listing.empty then
					listing.highlight:Show()
				end
			end
			listing.OnLoseFocus = function()
				listing.highlight:Hide()
			end
		end
		self.scroll_list.old_update = self.scroll_list.update_fn
		self.scroll_list.update_fn = function(context, widget, data, index)
			self.scroll_list.old_update(context, widget, data, index)
			widget.empty = data == nil or next(data) == nil
			widget.kick:SetHoverText(this_user.admin and STRINGS.UI.PLAYERSTATUSSCREEN.KICK or STRINGS.REFORGED.VOTE.KICK_PLAYER, { font = _G.NEWFONT_OUTLINE, offset_x = -35, offset_y = 0, colour = {1,1,1,1} })
			widget.kick:SetOnClick(function()
				-- dont care if not admin, should be hidden anyway
				if data ~= nil and data.userid ~= nil then
					if this_user.admin then
					UserCommands.RunUserCommand("kick", { user = data.userid }, this_user)
					else
						local params_str = _G.SerializeTable({target_id = data.userid})
						UserCommands.RunUserCommand("lobbyvotestart", {command = "kick", force_success = "false", params_str = params_str}, this_user)
					end
				end
			end)
			-- hide if empty, im not admin, this is my listing, or target is admin
			if widget.empty or not this_user.admin and not _G.REFORGED_SETTINGS.vote.kick or data.userid == this_user.userid or data.admin then
				widget.kick:Hide()
			else
				widget.kick:Show()
			end
			-- if kick shown, then leave viewprofile and mute at original positions
			widget.viewprofile:SetPosition(old_viewprofile_position.x + (widget.kick.shown and 0 or x_offset), 0)
			widget.mute:SetPosition(old_mute_position.x + (widget.kick.shown and 0 or x_offset), 0)

			-- only show for your listing, and if you are admin (need vote!)
			if data and data.userid == this_user.userid and (data.admin or _G.REFORGED_SETTINGS.vote.force_start) and not (_G.TheWorld.net and _G.TheWorld.net.components.lavaarenaeventstate and _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress()) then
				widget.forcestart:Show()
				widget.netscore:SetPosition(old_netscore_position.x, 0)
			else
				widget.forcestart:Hide()
				widget.netscore:SetPosition(old_netscore_position.x + x_offset, 0)
			end

			-- new focus hookups thats ran onupdate incase you lose/gain buttons (before only once on creation)
			local function newFocus(self)
				local buttons = {}
				if self.viewprofile:IsVisible() then table.insert(buttons, self.viewprofile) end
				if self.mute:IsVisible() then table.insert(buttons, self.mute) end
				if self.kick:IsVisible() then table.insert(buttons, self.kick) end
				if self.forcestart:IsVisible() then table.insert(buttons, self.forcestart) end

				self.focus_forward = nil
				local focusforwardset = false
				for i,button in ipairs(buttons) do
					if not focusforwardset then
						focusforwardset = true
						self.focus_forward = button
					end
					if buttons[i-1] then
						button:SetFocusChangeDir(MOVE_LEFT, buttons[i-1])
					end
					if buttons[i+1] then
						button:SetFocusChangeDir(MOVE_RIGHT, buttons[i+1])
					end
				end
			end
			if not widget.empty then
				newFocus(widget)
			end
		end
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------
-- Force Start/Cancel commands
print("+++++++++++++++ 378 is ok")
local function BuildNumConfig(startNum, endNum, step, percent)
    local numTable = {}
    local iterator = 1
    local suffix = percent and "%" or ""
    for i = startNum, endNum, step or 1 do
        numTable[iterator] = {description = i..suffix, data = percent and i / 100 or i}
        iterator = iterator + 1
    end
    return numTable
end
print("+++++++++++++++ 389 is ok")
AddComponentPostInit("worldcharacterselectlobby", function(self)
	self.timer = _G.net_byte(self.inst.GUID, "worldcharacterselectlobby._timer")
	function self:GetTimer()
		return self.timer:value()
	end

	if _G.TheWorld and _G.TheWorld.ismastersim then
		local force_start = false
		local initial_delay = false
		local total_delay = BuildNumConfig(5, 12 * 5, 5) -- +++++++++++++ change
		local default_delay = 5

		function self:ResetTimer(time)
			self.timer:set(time)
			self.real_timer = time
		end
		self:ResetTimer(default_delay)

		-- Initiates a timer that will start the game when completed
		function self:ForceStart(delay_time)
			total_delay = delay_time or BuildNumConfig(5, 12 * 5, 5)
			force_start = true
			self:ResetTimer(total_delay)
			for _,data in pairs(_G.GetPlayersClientTable()) do
				local userid = data.userid
				if userid then
					if not self:IsPlayerReadyToStart(userid) then
						UserCommands.RunUserCommand("playerreadytostart", { ready = "true" }, _G.TheNet:GetClientTableForUser(userid), true)
					end
				end
			end
		end

		-- Stops the game from starting and resets the timer
		function self:CancelForceStart()
			force_start = false
			self.inst:StopWallUpdatingComponent(self)
			_G.TheNet:SetAllowNewPlayersToConnect(true)
			_G.TheNet:SetIsMatchStarting(false)
			-- param is reverse logic to set _countdowni to COUNTDOWN_INACTIVE of 255
			self:OnWallUpdate(-255 + self:GetSpawnDelay())
			initial_delay = false
			self:ResetTimer(default_delay)
			-- _G.Debug:Print("Countdown canceled", "log")
		end

		-- Updates the current delay
		local old_OnWallUpdate = self.OnWallUpdate
		function self:OnWallUpdate(dt)
			-- Cancel all votes if time to start is less than or equal to 5 seconds.
			self.real_timer = self.real_timer - dt
			self.timer:set(math.ceil(self.real_timer))
			if self:GetTimer() <= 5 then
				_G.TheWorld.net.components.lobbyvote:CancelVote()
			end
			-- add -5 to delay to compensate for default _countdowni
			old_OnWallUpdate(self, force_start and not initial_delay and -math.max(0, total_delay - default_delay - dt) or dt)
			initial_delay = true
		end

		function self:OnUpdate(dt)
			-- Continue countdown if there are sill players connected
			if #_G.AllPlayers <= 0 then
				local clients = _G.TheNet:GetClientTable()
				if clients ~= nil then
					local isdedicated = not _G.TheNet:GetServerIsClientHosted()
					for i, v in ipairs(clients) do
						if not isdedicated or v.performance == nil then
							return
						end
					end
				end
				-- Allow players to connect again since all players have disconnected.
				_G.TheNet:SetAllowNewPlayersToConnect(true)
			end
			-- Reset since all players disconnected or the match has started
			_G.TheNet:SetIsMatchStarting(false)
			self.inst:StopUpdatingComponent(self)
			self:CancelForceStart()
		end

		-- Allow players to change characters when force start has been activated
		local old_IsAllowingCharacterSelect = self.IsAllowingCharacterSelect
		function self:IsAllowingCharacterSelect()
			return _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() or force_start and self:GetSpawnDelay() > 1 or old_IsAllowingCharacterSelect(self)
		end

		-- TheFrontEnd:PopScreen() TheFrontEnd:PopScreen() TheNet:SendSpawnRequestToServer("spectator")
		--[[
		local function doSpawn() TheFrontEnd:PopScreen() TheNet:SendSpawnRequestToServer("spectator") end TheFrontEnd:Fade(FADE_OUT, 1, doSpawn, nil, nil, "white")
		--]]
		local _oldCanPlayersSpawn = self.CanPlayersSpawn
		function self:CanPlayersSpawn()
			return _G.REFORGED_SETTINGS.joinable_midmatch and _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() or _oldCanPlayersSpawn() or true -- TODO add setting check here
		end
	end
	print("+++++++++++++++ 486 is ok")
end)

--------------------------
-- CharacterSelectPanel --
--------------------------
-- Add detailed description of the character to their potrait on the character select screen
local function EditOvalPortrait(self)
	local old_BuildCharacterDetails = self._BuildCharacterDetails

	self._BuildCharacterDetails = function()
		local portrait_root = old_BuildCharacterDetails(self)
		if _G.TheNet:GetServerGameMode() == "lavaarena" then
			self.eventid = _G.TheNet:GetServerGameMode() --Note(Peter):Ahhhhh! we're mixing game mode and event id and server event name, it works though because it's all "lavarena" due to the c-side being case-insensitive
			portrait_root:SetPosition(0, -50)

			self.character_text:SetPosition(0, -150)

			self.la_health = self.character_text:AddChild(Text(_G.HEADERFONT, 28))
			self.la_health:SetHAlign(_G.ANCHOR_LEFT)
			self.la_health:SetRegionSize(300, 30)
			self.la_health:SetColour(_G.UICOLOURS.WHITE)
			self.la_health:SetPosition(15, -210)

			self.la_difficulty= self.character_text:AddChild(Text(_G.HEADERFONT, 20))
			self.la_difficulty:SetHAlign(_G.ANCHOR_LEFT)
			self.la_difficulty:SetRegionSize(300, 30)
			self.la_difficulty:SetColour(_G.UICOLOURS.EGGSHELL)
			self.la_difficulty:SetPosition(15, -235)

			self.la_items = self.character_text:AddChild(Text(_G.HEADERFONT, 20))
			self.la_items:SetVAlign(_G.ANCHOR_TOP)
			self.la_items:SetHAlign(_G.ANCHOR_LEFT)
			self.la_items:SetRegionSize(300, 70)
			self.la_items:SetColour(_G.UICOLOURS.EGGSHELL)
			self.la_items:EnableWordWrap(true)
			self.la_items:SetPosition(15, -280)
		end

		return portrait_root
	end

	self.portrait_root:KillAllChildren()
	self.portrait_root = self:AddChild(self:_BuildCharacterDetails(self))

	local old_SetPortrait = self.SetPortrait

	self.SetPortrait = function(self, character)
		--old_SetPortrait(self, character)
		_G.assert(character)

		self.currentcharacter = character

		local found_name = _G.SetHeroNameTexture_Gold(self.heroname, character)
		if found_name then
			self.heroname:Show()
		else
			self.heroname:Hide()
		end

		_G.SetOvalPortraitTexture(self.heroportrait, character)

		if self.charactername then
			self.charactername:SetString(STRINGS.CHARACTER_NAMES[character] or "")
		end
		if self.charactertitle then
			self.charactertitle:SetString(STRINGS.CHARACTER_TITLES[character] or "")
		end
		if self.characterquote then
			self.characterquote:SetString(STRINGS.CHARACTER_QUOTES[character] or "")
		end
		if self.characterdetails then
			self.characterdetails:SetString(self.description_getter_fn(character) or "")
		end

		if self.la_health then
			if _G.TUNING.LAVAARENA_STARTING_HEALTH[string.upper(character)] ~= nil then
				self.la_health:SetString(STRINGS.UI.PORTRAIT.HP .. " : " .. _G.TUNING.LAVAARENA_STARTING_HEALTH[string.upper(character)])
			else
				self.la_health:SetString("")
			end
		end

		if self.la_items then
			local hero_items = _G.TUNING.GAMEMODE_STARTING_ITEMS.LAVAARENA[string.upper(character)]
			if hero_items ~= nil then
				local items_str = STRINGS.UI.PORTRAIT.ITEMS .. " : "
				for i, item in pairs(hero_items) do
					local item_name = string.upper(type(item) == "table" and i or item)
					items_str = items_str .. ((STRINGS.REFORGED.WEAPONS[item_name] and STRINGS.REFORGED.WEAPONS[item_name].NAME) or (STRINGS.REFORGED.ARMOR[item_name] and STRINGS.REFORGED.ARMOR[item_name].NAME) or STRINGS.NAMES[item_name] or STRINGS.REFORGED.unknown) .. ", "
				end
				self.la_items:SetString(string.sub(items_str, 1, -3))
			else
				self.la_items:SetString("")
			end
		end

		if self.la_difficulty then
			local dif = _G.TUNING.LAVAARENA_SURVIVOR_DIFFICULTY[string.upper(character)]
			if dif ~= nil then
				self.la_difficulty:SetString(STRINGS.UI.PORTRAIT.DIFFICULTY .. " : " .. tostring((dif == 1 and "+") or (dif == 2 and "++") or "+++"))
			else
				self.la_difficulty:SetString("")
			end
		end
	end
end
AddClassPostConstruct( "widgets/redux/ovalportrait", EditOvalPortrait )

--------------------------
-- LoadoutPanel --
--------------------------
AddClassPostConstruct( "widgets/redux/loadoutselect", function(self)
end)

------------------
-- WaitingPanel --
------------------
local Grid = require "widgets/grid"
local function AdjustWaitingLobby(self)
	-- Dynamically scales the player portraits in the waiting lobby to fit the number of connected players.
	self.UpdatePlayerListing = function()
		local screen_width = 900--520--560--639.32--750--812 -- This was found through testing
		local screen_height = 450
		local widget_scalar = 0.43
		local widget_width = widget_scalar*324--125
		local widget_height = widget_scalar*511--250
		local offset_width = 110.68--250--125
		local offset_height = 30 + 20
		local col = 0
		local row = 1
		local scalar = 3
		local scalar_percent_increment = 0.005

		local current_players = _G.GetPlayerClientTable()
		local player_count = #current_players -- #self.player_listing
		while col*row < player_count do
			col = col + 1
			-- Find the next scalar
			local next_scalar = scalar
			local count = 0
			while (col * (widget_width + offset_width) - offset_width) * next_scalar > screen_width or ((widget_height + offset_height) * row - offset_height)*next_scalar > screen_height do
				count = count + 1
				next_scalar = scalar*(1 - scalar_percent_increment*count)
			end
			scalar = next_scalar
			-- If the current player badge is smaller than the size it would be if another row is added then add another row instead of a column.
			if ((widget_height + offset_height) * (row + 1) - offset_height)*scalar < screen_height then
				row = row + 1
				col = col - 1
				scalar = 2 / row
			end
		end
		-- Remove any leftover column space from recent new rows.
		while (col - 1)*row >= player_count do
			col = col - 1
		end
		-- Scale each widget based on number of max players
		for i,widget in pairs(self.player_listing) do
			if i <= player_count then
				widget:SetScale(scalar)
				widget:Show()
			else
				widget:Hide()
			end
		end
		-- Clear and Update grid based on amount of players
		local old_grid = self.list_root
		self.list_root = self.proot:AddChild(Grid())
		self.list_root:FillGrid(col, (widget_width + offset_width) * scalar, (widget_height + offset_height) * scalar, self.player_listing)
		self.list_root:SetPosition(-(widget_width + offset_width) * scalar * (col - 1)/2, (widget_height + offset_height)*scalar*(row - 1)/2 + 20)
		old_grid:Kill()
	end
	self:UpdatePlayerListing()

	-- Updates the given player widget with their selected character (weapon and armor)
	local function UpdatePlayerListing(widget, data)
	    local empty = data == nil or next(data) == nil

	    widget.userid = not empty and data.userid or nil
	    widget.performance = not empty and data.performance or nil
	    local player = _G.TheNet:GetClientTableForUser(widget.userid)
	    widget.lobbycharacter = player and player.prefab or not empty and data.lobbycharacter or nil

	    local puppet = widget.puppet

	    if empty then
	        widget:SetEmpty()
	     	widget._playerreadytext:Hide()
	    else
	        -- local prefab = player and player.prefab ~= "" and player.prefab or data.lobbycharacter or data.prefab or ""
	        -- widget:UpdatePlayerListing(data.name, data.colour, prefab, _G.GetSkinsDataFromClientTableData(data))
			-- if prefab ~= "" then
			-- 	local current_perk_options = _G.TheWorld.net.replica.perk_tracker:GetCurrentPerkOptions(widget.userid, prefab, true)
			-- 	local current_perk = _G.TheWorld.net.replica.perk_tracker:GetCurrentPerk(widget.userid, true)
			-- 	if _G.REFORGED_SETTINGS.display.lobby_gear then
			-- 		local starting_items = current_perk_options and current_perk_options.overrides.inventory or _G.TUNING.GAMEMODE_STARTING_ITEMS[string.upper(_G.TheNet:GetServerGameMode())][string.upper(prefab)]
			-- 		for _,item in pairs(starting_items or {}) do
			-- 			local forge_prefab = _G.GetValidForgePrefab(item)
			-- 			local swap_data = forge_prefab and forge_prefab.swap_data
			-- 			if swap_data and type(swap_data) == "table" then
			-- 				--Can be a table with 3 variables {player_symbol, build, item_symbol}
			-- 				--Can also be set as a string value ("swap_hat", "swap_body", OR "swap_object") and it will automatically fill in the 3 needed arguments!
			-- 				for _,swap_str in pairs(swap_data.swap or {}) do
			-- 					if type(swap_str) == "string" then
			-- 						local itemswap = forge_prefab.swap_build or item
			-- 						puppet.animstate:OverrideSymbol(swap_str, itemswap, swap_str == "swap_object" and itemswap or swap_str)
			-- 					else
			-- 						puppet.animstate:OverrideSymbol(_G.unpack(swap_str))
			-- 					end
			-- 				end
			-- 				for _,hide_str in pairs(swap_data.hide or {}) do
			-- 					puppet.animstate:Hide(hide_str)
			-- 				end
			-- 				for _,show_str in pairs(swap_data.show or {}) do
			-- 					puppet.animstate:Show(show_str)
			-- 				end
			-- 			end
			-- 		end
			-- 	end
			-- 	local perk_icon = current_perk_options and current_perk_options.icon or {atlas = "images/reforged.xml", tex = "p_unknown.tex"}
			-- 	local current_perk_strings = current_perk and (STRINGS.REFORGED.PERKS[prefab] and STRINGS.REFORGED.PERKS[prefab][current_perk] or STRINGS.REFORGED.PERKS.generic[current_perk])
			-- 	if perk_icon then
			-- 		if prefab == "spectator" or prefab == "random" then
			-- 			widget.perk_icon:SetPosition(0, -30)-- -65, 80)
			-- 		else
			-- 			widget.perk_icon:SetPosition(0, 90)-- -65, 80)
			-- 		end
        	-- 		widget.perk_icon:SetTexture(perk_icon.atlas, perk_icon.tex)
        	-- 		widget.perk_icon:SetHoverText(current_perk_strings and current_perk_strings.TITLE or STRINGS.REFORGED.PERKS.UNKNOWN)
        	-- 		widget.perk_icon:ScaleToSize(25,25,true)
        	-- 		widget.perk_icon:Show()
        	-- 	end
    		-- else
    		-- 	widget.perk_icon:Hide()
			-- end
	    end
	    -- Don't emote puppets that don't have emotes.
	    if puppet.noemotes then return end
	    --[[
		TODO
		after reviving make groggy for a while?
		infinite overwrite on the function?
		1st tier of angry emotes causes all of them to be used and not just one
	    --]]
	    -- Create or reset the puppets emotes
		local HEAL_TIME = 10
		local EMOTE_TIME = 10
		local MAX_WAIT_TIME = 60
		local MAX_YAWNS = 3
		puppet.time_to_next_emote = EMOTE_TIME
		puppet.time_to_next_health = HEAL_TIME
		puppet.time_to_next_health = 0
		puppet.wait_time = 0
		puppet.yawn_count = 0
		puppet.time_to_revive = HEAL_TIME
	    -- Connected Clients somehow call this multiple times so prevent multiple overwrites.
	    if puppet.emotes and puppet.noemotes then return end
	    puppet.emotes = true
		local emote_anims = {
			angry    = {"emoteXL_angry", "emoteXL_waving4", "emote_fistshake"},
			attack   = {"throw"}, -- TODO need more
			wave     = {"emoteXL_waving1", "emoteXL_waving2", "emoteXL_waving3"},
			happy    = {"emoteXL_happycheer", "research"},
			cry      = "emoteXL_sad",
			dance    = {{"emoteXL_pre_dance0", "emoteXL_loop_dance0"}},
			flex     = "emote_flex",
			sit      = {{"emote_pre_sit2", "emote_loop_sit2"}, {"emote_pre_sit4", "emote_loop_sit4"}},
			squat    = {{"emote_pre_sit1", "emote_loop_sit1"}, {"emote_pre_sit3", "emote_loop_sit3"}},
			facepalm = "emoteXL_facepalm",
			revive   = {{"death2_idle", "corpse_revive"}},
			death    = "death2",
			hit      = "hit",
			woodie   = "idle_woodie",
			wormwood = "idle_wormwood",
			winona   = "idle_winona",
			wortox   = "idle_wortox",
			warly    = "idle_warly",
			willow   = "idle_willow",
			yawn     = "emote_sleepy",
			sleep    = {"dozy", "sleep_loop"},
			wake     = "wakeup",
		}
	    local default_characters = {
	        wilson = true,
	        willow = true,
	        wendy = true,
	        wolfgang = true,
	        woodie = true,
	        wickerbottom = true,
	        wx78 = true,
	        wes = true,
	        waxwell = true,
	        wathgrithr = true,
	        webber = true,
	        winona = true,
	        wortox = true,
	        wormwood = true,
	        warly = true,
	        wurt = true,
	        walter = true,
	        wanda = true,
	    }
		local function GetEmote(emote)
			local character = widget.lobbycharacter
			if default_characters[character] then
				return emote_anims[emote]
			else
				return _G.TUNING.FORGE.EMOTES[character]
			end
		end
		puppet.hit_count = 0
		puppet.dead = false
		local MAX_HEALTH = 10
		local _oldOnControl = puppet.OnControl
	    puppet.OnControl = function(self, control, down)
		    if control == _G.CONTROL_ACCEPT and down then
				if not self.dead then
					_G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
					self.wait_time = 0
					self.yawn_count = 0
					-- Wake up
					if self.sleeping then
						self:DoEmote(GetEmote("wake"), false, true)
						self.sleeping = false
					else
						self.hit_count = self.hit_count + 1
						-- Kill puppet
						if self.hit_count >= MAX_HEALTH then
							self:DoEmote(GetEmote("death"), true, true, true)
							self.dead = true
							self.hit_count = 0
							self.death_time = _G.GetTimeRealSeconds()
						-- Hurt puppet
						else
							self:DoEmote(GetEmote("hit"), false, true)
						end
					end
				end
			end
			return _oldOnControl(self, control, down)
		end
		local random_emotes = {"wave", "happy", "dance", "flex", "facepalm"}
		-- Add selected characters custom idle anims
		if emote_anims[widget.lobbycharacter] or _G.TUNING.FORGE.EMOTES[widget.lobbycharacter] and _G.TUNING.FORGE.EMOTES[widget.lobbycharacter][widget.lobbycharacter] then
			table.insert(random_emotes, widget.lobbycharacter)
		end
		-- Prevent overriding the functions multiple times
		if not puppet.emote_overrides then
			local _oldDoEmote = puppet.DoEmote
			puppet.DoEmote = function(self, emote, loop, force, no_idle)
				if emote == nil then return end
				_oldDoEmote(self, emote, loop, force)
				-- Add idle loop if current emote does not loop
				if not self.looping and not no_idle then
					self.animstate:PushAnimation("idle_loop", true)
					self.looping = true
				end
			end
			puppet.DoChangeEmote = function(self, emote, loop, force, no_idle)
				local emote = emote or GetEmote(random_emotes[math.random(1, #random_emotes)])
				if emote == nil then return end
				if type(emote) == "table" then
					emote = emote[math.random(1, #emote)]
				end
				self:DoEmote(emote, loop or loop == nil, force or force == nil)
			end
			puppet.EmoteUpdate = function(self, dt)
				-- Revive Puppet
				if self.dead then
					if self.time_to_revive > 0 then
						self.time_to_revive = self.time_to_revive - dt
					else
						self.dead = false
						self.time_to_revive = HEAL_TIME
						self.time_to_next_health = HEAL_TIME
						self.time_to_next_emote = EMOTE_TIME
						self.wait_time = 0
						self.hit_count = 0
						self:DoChangeEmote(GetEmote("revive"), false, true)
					end
				elseif not self.sleeping then
					-- Heal Puppet
					if self.hit_count > 0 then
						if self.time_to_next_health > 0 then
							self.time_to_next_health = self.time_to_next_health - dt
						else
							self.time_to_next_health = HEAL_TIME
							self.hit_count = self.hit_count - 1
						end
					end
					-- Sit
					self.wait_time = self.wait_time + dt
					if self.wait_time >= MAX_WAIT_TIME then
						if self.yawn_count >= MAX_YAWNS then
							self.sleeping = true
							self.yawn_count = 0
							--self:DoChangeEmote(emote_anims.sit)
							self:DoEmote(GetEmote("sleep"), true, true)
						else
							self.wait_time = 0
							self.yawn_count = self.yawn_count + 1
							self:DoEmote(GetEmote("yawn"), false, true)
						end
					elseif self.time_to_next_emote > 0 then
						self.time_to_next_emote = self.time_to_next_emote - dt
					-- Random Emote
					elseif self.animstate:IsCurrentAnimation("idle_loop") then
						-- Cry
						if self.hit_count >= 8 then
							self:DoEmote(GetEmote("cry"), false, true)
						-- Attack
						elseif self.hit_count >= 6 then
							self:DoEmote(GetEmote("attack"), false, true)
						-- Angry
						elseif self.hit_count >= 3 then
							self:DoEmote(GetEmote("angry"), false, true)
						-- Random
						else
							self:DoChangeEmote()
						end
						self.time_to_next_emote = EMOTE_TIME
					-- Force idle if in anim loop (non idle)
					elseif not self.animstate:IsCurrentAnimation("wakeup") then
						self:DoEmote("idle_loop", true, true)
						self.time_to_next_emote = EMOTE_TIME
					end
				end
			end
			puppet.emote_overrides = true
		end
		puppet.enable_idle_emotes = false
		puppet.time_to_change_emote = 5
		puppet:SetClickable(true)
	end
	self.last_update_time = _G.GetTimeRealSeconds()
	self.Refresh = function(self, force)
		local current_update_time = _G.GetTimeRealSeconds()
	    local prev_num_players = self.players ~= nil and #self.players or 0
	    self.players = self:GetPlayerTable()

	    -- Update the display of any player that has changed characters
	    for i,widget in ipairs(self.player_listing) do
	        local player = self.players[i]
	        if i <= #self.players and (force or player == nil or
	            player.userid ~= widget.userid or
	            (player.prefab ~= "" and player.prefab or player.lobbycharacter) ~= widget.lobbycharacter or
	            (player.performance ~= nil) ~= (widget.performance ~= nil))
	            then
	            UpdatePlayerListing(widget, player)
	        end
	        widget.puppet:EmoteUpdate(current_update_time - self.last_update_time)
	    end
	    -- Update the Player Listing when player count changes aka when a player connects/disconnects
	    if prev_num_players ~= #self.players or force then
			self:UpdatePlayerListing()
		end
	    self:RefreshPlayersReady()
		-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	    if _G.TheWorld.net.components.lavaarenaeventstate:IsInProgress() then
			self.playerready_checkbox:Hide()
	    end
		self.last_update_time = current_update_time
	end
	-- Initialize the settings display
	self.settings_root = self.proot:AddChild(Widget())
	local link = {
		map        = "maps",
		mode       = "modes",
		gametype   = "gametypes",
		waveset    = "wavesets",
		difficulty = "difficulties",
	}
	self.settings = {}
	self.UpdateGameSettingsDisplay = function(self)
		-- Remove Old Setting Icons
		for index,icon in pairs(self.settings or {}) do
			icon:Kill()
			self.settings[index] = nil
		end
		local spacing = 5
		local icon_size = 25
		local current_x_offset = -290 + 200 - 160 - 200 -- = -250
		local y_offset = 310 - icon_size
		local function IconSetup(setting, value, mutator)
			local icon = mutator and _G.REFORGED_DATA.mutators[mutator].icon or _G.REFORGED_DATA[link[setting]][value].icon
			if icon then
				local setting_icon = self.settings_root:AddChild(Image(icon.atlas, icon.tex))
				setting_icon:SetPosition(current_x_offset, y_offset)
				setting_icon:ScaleToSize(icon_size, icon_size, true)
				local hover_text = mutator and _G.STRINGS.REFORGED.MUTATORS[mutator].name or _G.STRINGS.REFORGED[string.upper(link[setting])][value] and _G.STRINGS.REFORGED[string.upper(link[setting])][value].name or _G.STRINGS.REFORGED.unknown
				if type(value) == "number" then
					hover_text = hover_text .. " " .. tostring(value)
					local text_icon = self:AddChild(Text(_G.CHATFONT, 20, subfmt(STRINGS.UI.WXPLOBBYPANEL.MUTATOR_VAL, {val = value})))
					local w,h = text_icon:GetRegionSize()
					text_icon:SetPosition(current_x_offset + w/2 + icon_size/2, y_offset)
					current_x_offset = current_x_offset + w
					self.settings[(mutator or setting) .. tostring(value)] = text_icon
				end
				setting_icon:SetHoverText(hover_text)
				current_x_offset = current_x_offset + spacing + icon_size
				self.settings[mutator or setting] = setting_icon
			end
		end
		-- -- Update display for all active settings
		-- for setting,value in pairs(_G.REFORGED_SETTINGS.gameplay) do
		-- 	if setting == "mutators" then
		-- 		for mutator,val in pairs(value) do
		-- 			if type(val) == "number" and val ~= 1 or type(val) ~= "number" and val then
		-- 				IconSetup(setting, val, mutator)
		-- 			end
		-- 		end
		-- 	elseif setting ~= "preset" then
		-- 		IconSetup(setting, value)
		-- 	end
		-- end
	end
	self:UpdateGameSettingsDisplay()
end
AddClassPostConstruct( "widgets/waitingforplayers", AdjustWaitingLobby )

-- AddClassPostConstruct( "widgets/redux/playeravatarportrait", function(self)
-- 	self.perk_icon = self:AddChild(Image())
-- 	self.perk_icon:SetPosition(0, 90)-- -65, 80)
-- end)

-- local WXPLobbyPanel = require("widgets/redux/wxplobbypanel")
-- local _oldWXP_ctor = WXPLobbyPanel._ctor
-- WXPLobbyPanel._ctor = function(self, profile, on_anim_done_fn)
--     Widget._ctor(self, "WxpLobbyPanel")
--     self.profile = profile
--     self.on_anim_done_fn = on_anim_done_fn

--     self.current_eventid = _G.TheNet:GetServerGameMode()
--     self.levelup = false

-- 	self.wxp = _G.deepcopy((_G.TheNet:IsOnlineMode() and _G.Settings.match_results.wxp_data ~= nil) and _G.Settings.match_results.wxp_data[_G.TheNet:GetUserID()] or {})
-- 	local new_wxp = false
-- 	if next(self.wxp) ~= nil then
-- 		if self.wxp.match_xp ~= nil then
-- 			self.wxp.achievements = {}
-- 			--self.wxp.achievements_progress = {}
-- 			for k, detail in ipairs(self.wxp.details) do
-- 				if detail.name then
-- 					--table.insert(self.wxp.achievements_progress, _G.deepcopy(detail))
-- 					local detail_info = _G.REFORGED_SETTINGS.display.server_level and detail.server or not _G.REFORGED_SETTINGS.display.server_level and detail.client
-- 					if detail_info and detail_info.unlocked then
-- 						detail._has_icon = true
-- 						detail.is_match_goal = true
-- 						detail._sort_value = 1 -- Sort achievements last
-- 						detail.val = detail_info.exp
-- 						table.insert(self.wxp.achievements, _G.deepcopy(detail))
-- 						local achievement_exp = (detail_info.exp or 0)
-- 						self.wxp.match_xp = self.wxp.match_xp + achievement_exp
-- 						self.wxp.new_xp = self.wxp.new_xp + achievement_exp
-- 						_G.TheFrontEnd.match_results.match_xp = _G.TheFrontEnd.match_results.match_xp + achievement_exp
-- 					end
-- 				else
-- 					if _G.Settings.match_results.outcome ~= nil and _G.Settings.match_results.outcome.won and string.match(detail.desc, "MILESTONE_") then
-- 						detail.desc = "WIN"
-- 					end
-- 					detail._has_icon = true
-- 					detail.is_match_goal = true
-- 					detail._sort_value = 0
-- 					table.insert(self.wxp.achievements, _G.deepcopy(detail))
-- 				end
-- 			end

-- 			table.sort(self.wxp.details, function(a, b) return (a.val+(a._sort_value or 0)) < (b.val+(b._sort_value or 0)) end)
-- 			table.sort(self.wxp.achievements, function(a, b) return (a.val+(a._sort_value or 0)) < (b.val+(b._sort_value or 0)) end)


-- 			self.levelup = _G.wxputils.GetLevelForWXP(self.wxp.new_xp - self.wxp.match_xp) ~= _G.wxputils.GetLevelForWXP(self.wxp.new_xp)

-- 			self.wxp.old_xp = math.max(0, self.wxp.new_xp - self.wxp.match_xp)
-- 			self.wxp.old_level = _G.wxputils.GetLevelForWXP(self.wxp.old_xp)

-- 			new_wxp = true
-- 			_G.Settings.match_results.wxp_data[_G.TheNet:GetUserID()] = {new_xp = self.wxp.new_xp, achievements = self.wxp.achievements}
-- 		else
--             --V2C: make a new table so we don't write all the
--             --     data back to the table referenced in Settings!
--             self.wxp = { new_xp = self.wxp.new_xp, achievements = self.wxp.achievements }
-- 			self.wxp.earned_boxes = 0
-- 			self.wxp.details = {}
-- 			self.wxp.match_xp = 0
-- 			self.wxp.old_xp = self.wxp.new_xp
-- 			self.wxp.old_level = _G.wxputils.GetLevelForWXP(self.wxp.new_xp)
-- 		end
-- 	else
-- 		self.wxp = {}
-- 		self.wxp.new_xp = _G.wxputils.GetActiveWXP()
-- 		self.wxp.earned_boxes = 0
-- 		self.wxp.details = {}
-- 		self.wxp.match_xp = 0
-- 		self.wxp.old_xp = self.wxp.new_xp
-- 		self.wxp.old_level = _G.wxputils.GetActiveLevel()
-- 		self.wxp.achievements = {}
-- 	end

-- 	if not self.levelup then
-- 		achievement_max_per_row = 15
-- 		if #self.wxp.achievements > 30 then
-- 			achievement_spacing = 30
-- 			achievement_image_size = 28
-- 			achievement_max_per_row = 19
-- 		end
-- 	elseif #self.wxp.achievements > 18 then
-- 		achievement_spacing = 30
-- 		achievement_image_size = 28
-- 		achievement_max_per_row = 11
-- 	end

-- 	self.detail_index = 1

-- 	self.displayinfo = {}
-- 	self.displayinfo.timer = 0
-- 	local TIME_PER_DETAIL = 2
-- 	self.displayinfo.duration =  #self.wxp.achievements * TIME_PER_DETAIL
-- 	self.displayinfo.showing_level = self.wxp.old_level
-- 	self.displayinfo.showing_level_start_xp, self.displayinfo.showing_level_end_xp = _G.wxputils.GetWXPForLevel(self.wxp.old_level)

-- 	self.displayachievements = {}

--     self:DoInit(not new_wxp or self.displayinfo.duration <= 0)

-- 	if new_wxp then
-- 		self.inst:DoTaskInTime(0.5, function() self.is_updating = true self:RefreshWxpDetailWidgets() end)
--     else
-- 		self.inst:DoTaskInTime(0.0, function() self:OnCompleteAnimation() end)
-- 	end
-- end

-- -- Custom Experience
-- local function AddCustomExperience(self)
-- 	self.wxpbar:SetRank(self.displayinfo.showing_level, self.displayinfo.showing_level_end_xp - self.displayinfo.showing_level_start_xp, _G.GetMostRecentlySelectedItem(_G.Profile, "profileflair"))

-- 	local LEVELUP_TIME = 1
-- 	local achievement_spacing = 38
-- 	local achievement_image_size = 36
-- 	local achievement_max_per_row = 9
-- 	local achievement_start = -256-18
-- 	local _oldShowAchievement = self.ShowAchievement
-- 	self.displayed_achievements_key = {}
-- 	self.ShowAchievement = function(self, achievement, animate)
-- 		local key = achievement.desc or achievement.name
-- 		if key and self.displayed_achievements_key[key] then return end
-- 		local num_shown = #self.displayachievements
-- 		local img_width = achievement_image_size
-- 		local max_num_wide = achievement_max_per_row
-- 		local achievement_altas = achievement.atlas or self.current_eventid == "lavaarena" and "images/lavaarena_quests.xml" or "images/quagmire_achievements.xml"
-- 		local achievement_info =_G.REFORGED_DATA.achievements[achievement.name]
-- 		local achievement_icon = achievement_info and achievement_info.icon
-- 		local icon = self.achievement_root:AddChild(Image(achievement_icon and achievement_icon.atlas or achievement_altas, achievement_icon and achievement_icon.tex or achievement.tex))
-- 		local hover_text = achievement.desc and _G.STRINGS.UI.WXP_DETAILS[string.upper(achievement.desc)] or achievement_info and _G.STRINGS.REFORGED.ACHIEVEMENTS[achievement.name] and _G.STRINGS.REFORGED.ACHIEVEMENTS[achievement.name].TITLE or _G.STRINGS.REFORGED.unknown
-- 		if hover_text then
-- 			if (achievement.val or 0) ~= 0 then
-- 				hover_text = subfmt(_G.STRINGS.UI.WXPLOBBYPANEL.ADD_XP_VAL, {name = hover_text, val = tostring(achievement.val)})
-- 			end
-- 			if (achievement.mult or 1) ~= 1 then
-- 				hover_text = subfmt(_G.STRINGS.UI.WXPLOBBYPANEL.MULT_VAL, {name = hover_text, val = tostring(achievement.mult)})
-- 			end
-- 			if (achievement.add or 0) ~= 0 then
-- 				hover_text = subfmt(_G.STRINGS.UI.WXPLOBBYPANEL.ADD_VAL, {name = hover_text, val = tostring(achievement.add)})
-- 			end
-- 			icon:SetHoverText(hover_text, {offset_y = 32, colour = _G.UICOLOURS.EGGSHELL})
-- 		end

-- 		icon:SetPosition(achievement_start + (achievement_spacing)*(num_shown%max_num_wide), (achievement_spacing*math.floor(1 + num_shown/max_num_wide)) + 3)
-- 		icon:ScaleToSize(img_width, img_width, true)
-- 		icon:MoveToBack()

-- 		if animate then
-- 			icon:SetTint(1,1,1,0)
-- 			icon:TintTo({r=1,g=1,b=1,a=0}, {r=1,g=1,b=1,a=1}, LEVELUP_TIME)
-- 		end

-- 		table.insert(self.displayachievements, icon)
-- 		if key then
-- 			self.displayed_achievements_key[key] = #self.displayachievements
-- 		end
-- 	end

-- 	self.settings = {}
-- 	-- Display Game Settings of last match played
-- 	self.UpdateGameSettingsDisplay = function(self)
-- 		-- Remove Old Setting Icons
-- 		for index,icon in pairs(self.settings or {}) do
-- 			icon:Kill()
-- 			self.settings[index] = nil
-- 		end
-- 		local outcome = _G.Settings.match_results ~= nil and _G.Settings.match_results.outcome or {}
-- 		local spacing = 5
-- 		local icon_size = 25
-- 		local line_height = 20
-- 		local x_pos = -440 -- -250
-- 		local y_pos = 480--490--390 --285 - line_height*2 -- numbers gotten from lobbyscreen
-- 		local y_pos_text = 390
-- 		local current_x_offset = 0
-- 		local function IconSetup(setting, value, mutator)
-- 			if value == nil then return end
-- 			local icon = mutator and _G.REFORGED_DATA.mutators[mutator].icon or _G.REFORGED_DATA[setting][value].icon
-- 			local setting_icon = self:AddChild(Image(icon.atlas, icon.tex))
-- 			setting_icon:SetPosition(x_pos + current_x_offset, y_pos)
-- 			setting_icon:ScaleToSize(icon_size, icon_size, true)
-- 			self.settings[mutator or setting] = setting_icon
-- 			local hover_text = mutator and _G.STRINGS.REFORGED.MUTATORS[mutator].name or _G.STRINGS.REFORGED[string.upper(setting)][value].name
-- 			if type(value) == "number" then
-- 				hover_text = hover_text .. " " .. tostring(value)
-- 				local text_icon = self:AddChild(Text(_G.CHATFONT, 20, subfmt(STRINGS.UI.WXPLOBBYPANEL.MUTATOR_VAL, {val = value})))
-- 				local w,h = text_icon:GetRegionSize()
-- 				text_icon:SetPosition(x_pos + current_x_offset + w/2 + icon_size/2, y_pos)
-- 				current_x_offset = current_x_offset + w
-- 				self.settings[(mutator or setting) .. tostring(value)] = text_icon
-- 			end
-- 			current_x_offset = current_x_offset + spacing + icon_size
-- 			setting_icon:SetHoverText(hover_text)
-- 		end

-- 		-- Version
-- 		if self.version then
-- 			self.version:SetString(tostring(outcome.version))
-- 		else
-- 			self.version = self:AddChild(Text(_G.CHATFONT, 18, tostring(outcome.version)))
-- 			self.version:SetPosition(225, y_pos)
-- 			self.version:SetColour(_G.UICOLOURS.GOLD)
-- 			self.version:SetRegionSize(500, 20)
-- 			self.version:SetHAlign(_G.ANCHOR_RIGHT)
-- 		end

-- 		-- Total Rounds Completed (Only if Endless)
-- 		if outcome.mutators and outcome.mutators.endless then
-- 			if self.total_rounds_completed then
-- 				self.total_rounds_completed:SetString(subfmt(STRINGS.UI.WXPLOBBYPANEL.TOTAL_ROUNDS_COMPLETED, {rounds = outcome.total_rounds_completed}))
-- 			else
-- 				self.total_rounds_completed = self:AddChild(Text(_G.CHATFONT, 18, subfmt(STRINGS.UI.WXPLOBBYPANEL.TOTAL_ROUNDS_COMPLETED, {rounds = outcome.total_rounds_completed})))
-- 				self.total_rounds_completed:SetPosition(-250, y_pos_text)
-- 				self.total_rounds_completed:SetColour(_G.UICOLOURS.GOLD)
-- 				self.total_rounds_completed:SetRegionSize(400, 20)
-- 				self.total_rounds_completed:SetHAlign(_G.ANCHOR_LEFT)
-- 			end
-- 			y_pos_text = y_pos_text - line_height
-- 		end

-- 		-- Mode
-- 		IconSetup("modes", outcome.mode)
-- 		-- Difficulty
-- 		IconSetup("difficulties", outcome.difficulty)
-- 		-- Gametype
-- 		IconSetup("gametypes", outcome.gametype)
-- 		-- Waveset
-- 		IconSetup("wavesets", outcome.waveset)
-- 		-- Map
-- 		IconSetup("maps", outcome.map)
-- 		-- Mutators
-- 		for mutator,val in pairs(outcome.mutators or {}) do
-- 			if type(val) == "number" and val ~= 1 or type(val) ~= "number" and val then
-- 				IconSetup("mutators", val, mutator)
-- 			end
-- 		end

-- 		-- Total Experience
-- 		if self.total_exp then
-- 			self.total_exp:SetString(subfmt(STRINGS.UI.WXPLOBBYPANEL.TOTAL_EXP_GAINED, {exp = _G.TheFrontEnd.match_results.match_xp}))
-- 		else
-- 			self.total_exp = self:AddChild(Text(_G.CHATFONT, 40, subfmt(STRINGS.UI.WXPLOBBYPANEL.TOTAL_EXP_GAINED, {exp = _G.TheFrontEnd.match_results.match_xp})))
-- 			self.total_exp:SetPosition(0, -150)
-- 			self.total_exp:SetColour(_G.UICOLOURS.GOLD)
-- 		end
-- 	end
-- 	self:UpdateGameSettingsDisplay()
-- end
-- AddClassPostConstruct( "widgets/redux/wxplobbypanel", AddCustomExperience)