-- Old avatar actor frame.. renamed since much more will be placed here (hopefully?)
local t =
	Def.ActorFrame {
	Name = "PlayerAvatar"
}

local profile

local profileName = THEME:GetString("GeneralInfo", "NoProfile")
local playCount = 0
local playTime = 0
local noteCount = 0
local numfaves = 0
-- Seraphic: on the select screen the left side of the bottom bar belongs to the feather tabs, so the profile
-- block sits further right. The result screens have no tabs: profile on the left (clear of the crystal),
-- login / session info in the middle, version + clock on the right.
local loadingScreen = Var("LoadingScreen") or ""
local onResults = loadingScreen:find("Evaluation") ~= nil
-- Seraphic (select screen): nick + judge move to the top-left, clock to the top-right, the rest of the old
-- bottom-right profile block is moved off screen (the bottom-right now holds the score panel, _scorepanel.lua)
local onSelect = loadingScreen == "ScreenSelectMusic" or loadingScreen == "ScreenNetSelectMusic"
local AvatarY = SCREEN_HEIGHT - 62 -- must be set before uploadY below (it was nil there off the select screen, which broke every overlay loading this file)
local AvatarX = onResults and 62 or 424
local centerBlockX = onResults and 470 or 668 -- login / judge column, sits between the profile and the right column
local uploadX = onSelect and 250 or (centerBlockX - 50)
local uploadY = onSelect and 72 or (AvatarY + 41)
local uploadTextY = onSelect and 58 or (AvatarY + 27)
local nameMaxWidth = onResults and 240 or 122 -- keeps the profile name clear of the login column
local playerRating = 0
local uploadbarwidth = 100
local uploadbarheight = 10

local ButtonColor = getMainColor("positive")
local nonButtonColor = ColorMultiplier(getMainColor("positive"), 1.25)
--------UNCOMMENT THIS NEXT LINE IF YOU WANT THE OLD LOOK--------
--nonButtonColor = getMainColor("positive")

local setnewdisplayname = function(answer)
	if answer ~= "" then
		profile:RenameProfile(answer)
		profileName = answer
		MESSAGEMAN:Broadcast("ProfileRenamed", {doot = answer})
	end
end

local function highlightIfOver(self)
	if isOver(self) then
		local topname = SCREENMAN:GetTopScreen():GetName()
		if topname ~= "ScreenEvaluationNormal" and topname ~= "ScreenNetEvaluation" then
			self:diffusealpha(0.6)
		end
	else
		self:diffusealpha(1)
	end
end

local translated_info = {
	ProfileNew = THEME:GetString("ProfileChanges", "ProfileNew"),
	NameChange = THEME:GetString("ProfileChanges", "ProfileNameChange"),
	ClickLogin = THEME:GetString("GeneralInfo", "ClickToLogin"),
	ClickLogout = THEME:GetString("GeneralInfo", "ClickToLogout"),
	NotLoggedIn = THEME:GetString("GeneralInfo", "NotLoggedIn"),
	LoggedInAs = THEME:GetString("GeneralInfo", "LoggedInAs.."),
	LoginFailed = THEME:GetString("GeneralInfo", "LoginFailed"),
	LoginSuccess = THEME:GetString("GeneralInfo", "LoginSuccess"),
	LoginCanceled = THEME:GetString("GeneralInfo", "LoginCanceled"),
	Password = THEME:GetString("GeneralInfo","Password"),
	Username = THEME:GetString("GeneralInfo","Email"),
	Plays = THEME:GetString("GeneralInfo", "ProfilePlays"),
	PlaysThisSession = THEME:GetString("GeneralInfo", "PlaysThisSession"),
	TapsHit = THEME:GetString("GeneralInfo", "ProfileTapsHit"),
	Playtime = THEME:GetString("GeneralInfo", "ProfilePlaytime"),
	Judge = THEME:GetString("GeneralInfo", "ProfileJudge"),
	RefreshSongs = THEME:GetString("GeneralInfo", "DifferentialReloadTrigger"),
	SongsLoaded = THEME:GetString("GeneralInfo", "ProfileSongsLoaded"),
	SessionTime = THEME:GetString("GeneralInfo", "SessionTime"),
	GroupsLoaded = THEME:GetString("GeneralInfo", "GroupsLoaded"),
}

local function UpdateTime(self)
	local year = Year()
	local month = MonthOfYear() + 1
	local day = DayOfMonth()
	local hour = Hour()
	local minute = Minute()
	local second = Second()
	self:GetChild("CurrentTime"):settextf("%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second)

	local sessiontime = GAMESTATE:GetSessionTime()
	self:GetChild("SessionTime"):settextf("%s: %s", translated_info["SessionTime"], SecondsToHHMMSS(sessiontime))
	self:diffuse(nonButtonColor)
end

-- handle logging in
local function loginStep1(self)
	local redir = SCREENMAN:get_input_redirected(PLAYER_1)
	local function off()
		if redir then
			SCREENMAN:set_input_redirected(PLAYER_1, false)
		end
	end
	local function on()
		if redir then
			SCREENMAN:set_input_redirected(PLAYER_1, true)
		end
	end
	off()

	username = ""

	-- this sets up 2 text entry windows to pull your username and pass
	-- if you press escape or just enter nothing, you are forced out
	-- input redirects are controlled here because we want to be careful not to break any prior redirects
	easyInputStringOKCancel(
		translated_info["Username"]..":", 255, true,
		function(answer)
			username = answer
			-- moving on to step 2 if the answer isnt blank
			if answer:gsub("^%s*(.-)%s*$", "%1") ~= "" then
				self:sleep(0.04):queuecommand("LoginStep2")
			else
				ms.ok(translated_info["LoginCanceled"])
				on()
			end
		end,
		function()
			ms.ok(translated_info["LoginCanceled"])
			on()
		end
	)
end

-- do not use this function outside of first calling loginStep1
local function loginStep2()
	local redir = SCREENMAN:get_input_redirected(PLAYER_1)
	local function off()
		if redir then
			SCREENMAN:set_input_redirected(PLAYER_1, false)
		end
	end
	local function on()
		if redir then
			SCREENMAN:set_input_redirected(PLAYER_1, true)
		end
	end
	-- try to keep the scope of password here
	-- if we open up the scope, if a lua error happens on this screen
	-- the password may show up in the error message
	local password = ""
	easyInputStringOKCancel(
		translated_info["Password"]..":", 255, true,
		function(answer)
			password = answer
			-- log in if not blank
			if answer:gsub("^%s*(.-)%s*$", "%1") ~= "" then
				DLMAN:Login(username, password)
			else
				ms.ok(translated_info["LoginCanceled"])
			end
			on()
		end,
		function()
			ms.ok(translated_info["LoginCanceled"])
			on()
		end
	)
end



t[#t + 1] = Def.Actor {
	BeginCommand = function(self)
		self:queuecommand("Set")
	end,
	SetCommand = function(self)
		profile = GetPlayerOrMachineProfile(PLAYER_1)
		profileName = profile:GetDisplayName()
		playCount = SCOREMAN:GetTotalNumberOfScores()
		playTime = profile:GetTotalSessionSeconds()
		noteCount = profile:GetTotalTapsAndHolds()
		playerRating = profile:GetPlayerRating()
	end,
	PlayerRatingUpdatedMessageCommand = function(self)
		playerRating = profile:GetPlayerRating()
		self:GetParent():GetDescendant("AvatarPlayerNumber_P1", "Name"):playcommand("Set")
	end
}

t[#t + 1] = Def.ActorFrame {
	Name = "Avatar" .. PLAYER_1,
	BeginCommand = function(self)
		self:queuecommand("Set")
	end,
	SetCommand = function(self)
		if profile == nil then
			self:visible(false)
		else
			self:visible(true)
		end
	end,
	UIElements.SpriteButton(1, 1, nil) .. {
		Name = "Image",
		InitCommand = function(self)
			self:visible(true):halign(0):valign(0):xy(onSelect and -1000 or AvatarX, AvatarY)
		end,
		BeginCommand = function(self)
			self:queuecommand("ModifyAvatar")
		end,
		ModifyAvatarCommand = function(self)
			self:finishtweening()
			self:Load(getAvatarPath(PLAYER_1))
			self:zoomto(50, 50)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and not SCREENMAN:get_input_redirected(PLAYER_1) then
				local top = SCREENMAN:GetTopScreen()
				SCREENMAN:SetNewScreen("ScreenAssetSettings")
			end
		end
	},
	-- Seraphic: name and judge sit on a thin dark plate, split by a diamond (select screen only)
	Def.ActorFrame {
		InitCommand = function(self)
			self:visible(onSelect)
		end,
		TabChangedMessageCommand = function(self, params)
			if onSelect then self:visible(((params and params.to) or getTabIndex()) == 0) end
		end,
		ChartPreviewOnMessageCommand = function(self) if onSelect then self:visible(false) end end,
		ChartPreviewOffMessageCommand = function(self) if onSelect then self:visible(getTabIndex() == 0) end end,
		Def.Quad {
			InitCommand = function(self)
				self:xy(22, 78):halign(0):zoomto(196, 15):diffuse(color("#0a0507")):diffusealpha(0.75):faderight(0.25)
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:xy(22, 70):halign(0):zoomto(196, 1):diffuse(color("#e2e2e2")):diffusealpha(0.6):faderight(0.6)
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:xy(22, 86):halign(0):zoomto(196, 1):diffuse(color("#9c1428")):diffusealpha(0.8):faderight(0.6)
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:xy(22, 78):rotationz(45):zoomto(4, 4):diffuse(color("#ffffff"))
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:xy(151, 78):rotationz(45):zoomto(4, 4):diffuse(color("#ffffff")):diffusealpha(0.85)
			end
		}
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "Name",
		InitCommand = function(self)
			self:halign(0)
			self:xy(onSelect and 34 or (AvatarX + 54), onSelect and 78 or (AvatarY + 8))
			self:zoom(onSelect and 0.34 or 0.42)
			self:maxwidth(onSelect and (108 / 0.34) or (nameMaxWidth / 0.42))
			self:maxheight(22)
			self:diffuse(ButtonColor)
		end,
		SetCommand = function(self)
			self:settextf("%s: %5.2f", profileName, playerRating)
			self:queuecommand("Tint")
			if profileName == "Default Profile" or profileName == "" then
				easyInputStringWithFunction(
					translated_info["ProfileNew"],
					64,
					false,
					setnewdisplayname
				)
			end
		end,
		TabChangedMessageCommand = function(self, params)
			if onSelect then self:visible(((params and params.to) or getTabIndex()) == 0) end
		end,
		ChartPreviewOnMessageCommand = function(self) if onSelect then self:visible(false) end end,
		ChartPreviewOffMessageCommand = function(self) if onSelect then self:visible(getTabIndex() == 0) end end,
		-- offline = dimmed nick (select screen only)
		TintCommand = function(self)
			if onSelect then
				self:diffuse(DLMAN:IsLoggedIn() and ButtonColor or color("#9a9a9a"))
			end
		end,
		LoginMessageCommand = function(self) self:queuecommand("Tint") end,
		LogOutMessageCommand = function(self) self:queuecommand("Tint") end,
		OnlineUpdateMessageCommand = function(self) self:queuecommand("Tint") end,
		MouseDownCommand = function(self, params)
			if SCREENMAN:get_input_redirected(PLAYER_1) then return end
			local loginActor = self:GetParent():GetChild("loginlogout")
			if params.event == "DeviceButton_left mouse button" then
				if onSelect and not DLMAN:IsLoggedIn() then
					-- Seraphic: clicking the nick logs in
					loginStep1(loginActor)
				else
					easyInputStringWithFunction(translated_info["NameChange"], 64, false, setnewdisplayname)
				end
			elseif params.event == "DeviceButton_right mouse button" and onSelect and DLMAN:IsLoggedIn() then
				-- right click logs out
				loginActor:queuecommand("LogOut")
			end
		end,
		ProfileRenamedMessageCommand = function(self, params)
			self:settextf("%s: %5.2f", params.doot, playerRating)
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "loginlogout",
		InitCommand = function(self)
			self:xy(onSelect and -1000 or centerBlockX, AvatarY + 8):halign(0.5):zoom(0.4):maxwidth(126 / 0.4):diffuse(ButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			if DLMAN:IsLoggedIn() then
				self:queuecommand("Login")
			else
				self:queuecommand("LogOut")
			end
		end,
		LogOutMessageCommand = function(self)
			local top = SCREENMAN:GetTopScreen():GetName()
			if DLMAN:IsLoggedIn() then
				playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).UserName = ""
				playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).PasswordToken = ""
				playerConfig:set_dirty(pn_to_profile_slot(PLAYER_1))
				playerConfig:save(pn_to_profile_slot(PLAYER_1))
				DLMAN:Logout()
			end
			if top == "ScreenSelectMusic" or top == "ScreenNetSelectMusic" or top == "ScreenTextEntry" then
				self:settext(translated_info["ClickLogin"])
			else
				self:settext(translated_info["NotLoggedIn"])
			end
		end,
		LoginMessageCommand = function(self)
			if not SCREENMAN:GetTopScreen() then return end -- ?????
			local top = SCREENMAN:GetTopScreen():GetName()
			if not DLMAN:IsLoggedIn() then return end
			playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).UserName = DLMAN:GetUsername()
			playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).PasswordToken = DLMAN:GetToken()
			playerConfig:set_dirty(pn_to_profile_slot(PLAYER_1))
			playerConfig:save(pn_to_profile_slot(PLAYER_1))
			if top == "ScreenSelectMusic" or top == "ScreenNetSelectMusic" or top == "ScreenTextEntry" then
				self:settext(translated_info["ClickLogout"])
			else
				self:settext("")
			end
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and not SCREENMAN:get_input_redirected(PLAYER_1) then
				if DLMAN:IsLoggedIn() then
					self:queuecommand("LogOut")
				else
					loginStep1(self)
				end
			end
		end,
		OnlineUpdateMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
		end,
		LoginFailedMessageCommand = function(self, params)
			ms.ok(translated_info["LoginFailed"] .. " -- " .. params.why)
		end,
		LoginHotkeyPressedMessageCommand = function(self)
			if DLMAN:IsLoggedIn() then
				self:queuecommand("LogOut")
			else
				loginStep1(self)
			end
		end,
		LoginStep2Command = function(self)
			loginStep2()
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "LoggedInAs",
		InitCommand = function(self)
			self:xy(onSelect and -1000 or centerBlockX, AvatarY + 19):halign(0.5):zoom(0.32):maxwidth(126 / 0.32):diffuse(ButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			if DLMAN:IsLoggedIn() then
				self:queuecommand("Login")
			else
				self:queuecommand("LogOut")
			end
		end,
		LogOutMessageCommand = function(self)
			self:settext("")
		end,
		LoginMessageCommand = function(self) --this seems a little clunky -mina
			if not DLMAN:IsLoggedIn() then
				self:halign(0.5)
				return
			end
			self:settextf(
				"%s %s (%5.2f: #%i)",
				translated_info["LoggedInAs"],
				DLMAN:GetUsername(),
				DLMAN:GetSkillsetRating("Overall"),
				DLMAN:GetSkillsetRank(ms.SkillSets[1])
			)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				DLMAN:ShowUserPage(DLMAN:GetUsername())
			end
		end,
		OnlineUpdateMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		InitCommand = function(self)
			self:xy(onSelect and -1000 or AvatarX + 54, AvatarY + 21):halign(0):zoom(0.3):diffuse(nonButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			self:settextf("%s %s", playCount, translated_info["Plays"])
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
			if not self:IsVisible() then return end
			TOOLTIP:SetText(SCOREMAN:GetNumScoresThisSession() .. " " .. translated_info["PlaysThisSession"])
			TOOLTIP:Show()
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
			if not self:IsVisible() then return end
			TOOLTIP:Hide()
		end,
	},
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(onSelect and -1000 or AvatarX + 54, AvatarY + 31.5):halign(0):zoom(0.3):diffuse(nonButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			local time = SecondsToHHMMSS(playTime)
			self:settextf("%s %s", time, translated_info["Playtime"])
		end
	},
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(onSelect and -1000 or AvatarX + 54, AvatarY + 42):halign(0):zoom(0.3):diffuse(nonButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			self:settextf("%s %s", noteCount, translated_info["TapsHit"])
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		InitCommand = function(self)
			self:xy(onSelect and 160 or centerBlockX, onSelect and 78 or (AvatarY + 31)):halign(onSelect and 0 or 0.5):zoom(onSelect and 0.34 or 0.38):diffuse(ButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		OptionsScreenClosedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		TabChangedMessageCommand = function(self, params)
			if onSelect then self:visible(((params and params.to) or getTabIndex()) == 0) end
		end,
		ChartPreviewOnMessageCommand = function(self) if onSelect then self:visible(false) end end,
		ChartPreviewOffMessageCommand = function(self) if onSelect then self:visible(getTabIndex() == 0) end end,
		SetCommand = function(self)
			local online = IsNetSMOnline() and IsSMOnlineLoggedIn() and NSMAN:IsETTP()
			self:y(onSelect and 78 or (AvatarY + 31)) -- below "Logged in as" (AvatarY + 19), not on top of it
			self:settextf("%s: %s", translated_info["Judge"], GetTimingDifficulty())
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				-- raise judge
				local cur_judge = GetTimingDifficulty()
				if (cur_judge < 9) then
					local scale = ms.JudgeScalers[cur_judge+1]
					SetTimingDifficulty(scale)
					self:queuecommand("Set")
				end
			end
			if params.event == "DeviceButton_right mouse button" then
				-- lower judge
				local cur_judge = GetTimingDifficulty()
				if (cur_judge > 4) then
					local scale = ms.JudgeScalers[cur_judge-1]
					SetTimingDifficulty(scale)
					self:queuecommand("Set")
				end
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "Version",
		InitCommand = function(self)
			self:xy(onSelect and -1000 or SCREEN_WIDTH - 38, AvatarY + 8):halign(1):zoom(0.38):diffuse(ButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			self:settext(GAMESTATE:GetEtternaVersion())
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				DLMAN:ShowProjectReleases()
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "refreshbutton",
		InitCommand = function(self)
			self:xy(onSelect and -1000 or SCREEN_WIDTH - 38, AvatarY + 19):halign(1):zoom(0.32):diffuse(ButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			self:settextf(translated_info["RefreshSongs"])
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				SONGMAN:DifferentialReload()
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		InitCommand = function(self)
			self:xy(onSelect and -1000 or SCREEN_WIDTH - 38, AvatarY + 30):halign(1):zoom(0.32):diffuse(nonButtonColor)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			self:settextf("%s: %i", translated_info["SongsLoaded"], SONGMAN:GetNumSongs())
		end,
		DFRFinishedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			highlightIfOver(self)
			if not self:IsVisible() then return end
			TOOLTIP:SetText(SONGMAN:GetNumSongGroups() .. " " .. translated_info["GroupsLoaded"])
			TOOLTIP:Show()
		end,
		MouseOutCommand = function(self)
			highlightIfOver(self)
			if not self:IsVisible() then return end
			TOOLTIP:Hide()
		end,
	},
	-- ok coulda done this as a separate object to avoid copy paste but w.e
	-- upload progress bar bg
	UIElements.QuadButton(1,1) .. {
		InitCommand = function(self)
			self:xy(uploadX, uploadY):zoomto(uploadbarwidth, uploadbarheight)
			self:diffuse(color("#111111")):diffusealpha(0):halign(0)
		end,
		UploadProgressMessageCommand = function(self, params)
			self:diffusealpha(1)
			if params.percent == 1 then
				self:diffusealpha(0)
				if isOver(self) then
					TOOLTIP:Hide()
				end
			end
		end,
		SequentialScoreUploadFinishedMessageCommand = function(self)
			self:diffusealpha(0)
			if isOver(self) then
				TOOLTIP:Hide()
			end
		end,
		LogOutMessageCommand = function(self)
			self:playcommand("SequentialScoreUploadFinished")
		end,
		MouseOverCommand = function(self)
			if not self:IsVisible() or DLMAN:GetQueuedScoreUploadTotal() == 0 then return end
			local remaining = DLMAN:GetQueuedScoreUploadsRemaining()
			local total = DLMAN:GetQueuedScoreUploadTotal()
			TOOLTIP:SetText("Remaining Scores: "..remaining.." out of "..total)
			TOOLTIP:Show()
		end,
		MouseOutCommand = function(self)
			if not self:IsVisible() then return end
			TOOLTIP:Hide()
		end,
	},
	-- fill bar
	Def.Quad {
		InitCommand = function(self)
			self:xy(uploadX, uploadY):zoomto(0, uploadbarheight)
			self:diffuse(color("#AAAAAAA")):diffusealpha(0):halign(0)
		end,
		UploadProgressMessageCommand = function(self, params)
			self:diffusealpha(1)
			self:zoomto(params.percent * uploadbarwidth, uploadbarheight)
			if params.percent == 1 then
				self:diffusealpha(0)
			end
		end,
		SequentialScoreUploadFinishedMessageCommand = function(self)
			self:diffusealpha(0)
		end,
		LogOutMessageCommand = function(self)
			self:playcommand("SequentialScoreUploadFinished")
		end,
	},
	-- super required explanatory text
	LoadFont("Common Normal") .. {
	    InitCommand = function(self)
			self:xy(uploadX, uploadTextY):halign(0):valign(0)
			self:diffuse(nonButtonColor):diffusealpha(0):zoom(0.35)
        	self:settext("Uploading Scores...")
		end,
		UploadProgressMessageCommand = function(self, params)
			self:diffusealpha(1)
			if params.percent == 1 then
				self:diffusealpha(0)
			end
		end,
		SequentialScoreUploadFinishedMessageCommand = function(self)
			self:diffusealpha(0)
		end,
		LogOutMessageCommand = function(self)
			self:playcommand("SequentialScoreUploadFinished")
		end,
	}
}

-- Seraphic (select screen): date / time box in the top-right strip, set in the second (artist) font
local dateBoxW, dateBoxH = 290, 29
local dateBoxX, dateBoxY = SCREEN_WIDTH - 60 - dateBoxW, 10

t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:SetUpdateFunction(UpdateTime)
	end,
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_packbar"),
		InitCommand = function(self)
			if not onSelect then self:visible(false) return end
			self:xy(dateBoxX, dateBoxY):halign(0):valign(0):zoomto(dateBoxW, dateBoxH)
		end
	},
	(onSelect and LoadFont("Seraphic Date") or LoadFont("Common Normal")) .. {
		Name = "CurrentTime",
		InitCommand = function(self)
			if onSelect then
				self:xy(dateBoxX + dateBoxW / 2, dateBoxY + dateBoxH / 2):halign(0.5):valign(0.5):zoom(0.46):maxwidth((dateBoxW - 24) / 0.46)
			else
				self:xy(SCREEN_WIDTH - 38, SCREEN_BOTTOM - 3.5):halign(1):valign(1):zoom(0.3)
			end
		end
	},

	LoadFont("Common Normal") .. {
		Name = "SessionTime",
		InitCommand = function(self)
			self:xy(onSelect and -1000 or centerBlockX, AvatarY + 45):halign(0.5):valign(1):zoom(0.28)
		end
	}
}

local function UpdateAvatar(self)
	if getAvatarUpdateStatus() then
		self:GetChild("Avatar" .. PLAYER_1):GetChild("Image"):queuecommand("ModifyAvatar")
		setAvatarUpdateStatus(PLAYER_1, false)
	end
end
t.InitCommand = function(self)
	self:SetUpdateFunction(UpdateAvatar)
end

return t
