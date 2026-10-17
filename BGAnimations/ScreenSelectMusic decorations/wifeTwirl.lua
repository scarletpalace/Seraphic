local profile = PROFILEMAN:GetProfile(PLAYER_1)
local frameX = 10
local boxDY = 10 -- info box moved down so it sits 6px above the bottom bar (same gap as banner <-> top bar)
local frameY0 = 250 + capWideScale(get43size(120), 90) + 16 + boxDY -- whole info box sits a bit lower
local frameY = frameY0 - 20 -- contents sit higher: the old button rows above them are gone, so the box can be shorter
local frameWidth = capWideScale(get43size(455), 455)
-- Seraphic: LR2-style info window, one header band over three columns
local infoTop = frameY0 - 146
local colA = frameX -- rating, rate, note counts
local colB = frameX + 112 -- skillsets, tags, goal
local colC = frameX + frameWidth - 78 -- cd title, bpm, length
local colCEnd = frameX + frameWidth - 4
local ssRowW = math.min(140, colC - colB - 14)
local tagsBeside = colC - (colB + 6 + ssRowW) >= 90 -- wide screens: tags get their own column next to the skillsets
local tagX = tagsBeside and colB + ssRowW + 16 or colB + 10
local tagY = tagsBeside and infoTop + 26 or infoTop + 100
local goalY = tagsBeside and infoTop + 104 or infoTop + 126
local silverC = "#bdb3b6"

local function infoQuad(x, y, w, h, setup)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, h):diffuse(color("#000000"))
			setup(self)
		end
	}
end

local function infoHeader(x, y, text)
	return LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(x, y):halign(0):zoom(0.34):diffuse(color(silverC)):settext(text)
		end
	}
end

local function infoBullet(x, y)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):rotationz(45):zoomto(3.5, 3.5):diffuse(color("#9c1428"))
		end
	}
end

-- LR2-style window: translucent dark body, faint edge, no silver frame
local function infoWindowBody()
	local w, h = frameWidth + 4, 164
	local function edge(x, y, ew, eh)
		return infoQuad(frameX + x, infoTop + y, ew, eh, function(s) s:diffuse(color("#ffffff")):diffusealpha(0.1) end)
	end
	return Def.ActorFrame {
		infoQuad(frameX, infoTop, w, h, function(s)
			s:diffuseupperleft(color("#262626E6")):diffuseupperright(color("#1a1a1aE6"))
			s:diffuselowerleft(color("#0a0a0aF0")):diffuselowerright(color("#060606F0"))
			s:diffusealpha(0.62)
		end),
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_filigree"),
			InitCommand = function(self)
				self:xy(frameX + 4, infoTop + h - 3):halign(0):valign(1):zoomto(w - 8, 30):diffusealpha(0.22)
			end
		},
		edge(0, 0, w, 1), edge(0, h - 1, w, 1), edge(0, 1, 1, h - 2), edge(w - 1, 1, 1, h - 2),
	}
end

-- bands, headers and dividers drawn under the info texts
local function infoWindowDecor()
	local d = Def.ActorFrame {
		-- header band with a crimson rule under it
		infoQuad(frameX + 4, infoTop + 4, frameWidth - 4, 14, function(s) s:diffusealpha(0.55) end),
		infoQuad(frameX + 4, infoTop + 18, frameWidth - 4, 1, function(s)
			s:diffuseleftedge(color("#9c1428E6")):diffuserightedge(color("#9c142820"))
		end),
		infoHeader(colA + 10, infoTop + 11, seraphicHeading("RATING")),
		infoHeader(colC + 6, infoTop + 11, seraphicHeading("SONG")),
		-- column dividers
		infoQuad(colB, infoTop + 22, 1, 136, function(s)
			s:diffuse(color("#ffffff")):diffusetopedge(color("#ffffff50")):diffusebottomedge(color("#ffffff06"))
		end),
		infoQuad(colC, infoTop + 22, 1, 136, function(s)
			s:diffuse(color("#ffffff")):diffusetopedge(color("#ffffff50")):diffusebottomedge(color("#ffffff06"))
		end),
		-- rule between the rating and the note counts
		infoQuad(colA + 8, infoTop + 76, 96, 1, function(s)
			s:diffuse(color("#ffffff")):diffuseleftedge(color("#ffffff40")):diffuserightedge(color("#ffffff08"))
		end),
	}
	-- note count rows, every other one banded
	for i = 1, 5 do
		d[#d + 1] = infoQuad(colA + 5, infoTop + 78 + 14 * i - 7, 102, 13, function(s)
			s:diffusealpha(i % 2 == 1 and 0.4 or 0.15)
		end)
	end
	-- song rows (bpm, time)
	for i = 1, 2 do
		d[#d + 1] = infoQuad(colC + 4, infoTop + 84 + 18 * i - 7, colCEnd - colC - 4, 15, function(s)
			s:diffusealpha(i % 2 == 1 and 0.4 or 0.15)
		end)
	end
	-- skillset side, hidden while the chart preview covers it
	local b = Def.ActorFrame {
		ChartPreviewOnMessageCommand = function(self) self:visible(false) end,
		ChartPreviewOffMessageCommand = function(self) self:visible(true) end,
		infoHeader(colB + 8, infoTop + 11, seraphicHeading("SKILLSETS")),
		infoHeader(tagsBeside and tagX - 2 or tagX, tagsBeside and infoTop + 11 or tagY - 2, seraphicHeading("TAGS")),
		infoQuad(colB + 6, goalY - 8, ssRowW, 1, function(s)
			s:diffuse(color("#ffffff")):diffuseleftedge(color("#ffffff30")):diffuserightedge(color("#ffffff04"))
		end),
	}
	for i = 1, 3 do
		local y = infoTop + 10 + 22 * i
		b[#b + 1] = infoQuad(colB + 6, y - 9, ssRowW, 18, function(s)
			s:diffusealpha(i % 2 == 1 and 0.4 or 0.15)
		end)
		b[#b + 1] = infoBullet(colB + 13, y)
	end
	if tagsBeside then
		b[#b + 1] = infoQuad(tagX - 6, infoTop + 22, 1, 70, function(s)
			s:diffuse(color("#ffffff")):diffusetopedge(color("#ffffff30")):diffusebottomedge(color("#ffffff04"))
		end)
	end
	d[#d + 1] = b
	return d
end
-- banner fills the space between the top bar (y 90) and the info box, 6px gap on both sides, 3.2:1
local bannerY = 96
local bannerH = (frameY0 - 146) - 6 - bannerY
local bannerW = math.min(bannerH * 3.2, frameWidth + 4)
local score
local song
local steps
local noteField = false
local infoOnScreen = false
local heyiwasusingthat = false
local mcbootlarder
local pOptions = GAMESTATE:GetPlayerState():GetCurrentPlayerOptions()
local usingreverse = pOptions:UsingReverse()
local prevX = capWideScale(get43size(98), 98)
local prevY = 55
local prevrevY = 60
local boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
local hackysack = false
local songChanged = false
local songChanged2 = false
local previewVisible = false
local onlyChangedSteps = false
local shouldPlayMusic = false
local prevtab = 0

local itsOn = false

local translated_info = {
	GoalTarget = THEME:GetString("ScreenSelectMusic", "GoalTargetString"),
	MaxCombo = THEME:GetString("ScreenSelectMusic", "MaxCombo"),
	BPM = THEME:GetString("ScreenSelectMusic", "BPM"),
	NegBPM = THEME:GetString("ScreenSelectMusic", "NegativeBPM"),
	HasLua = THEME:GetString("ScreenSelectMusic", "HasLua"),
	UnForceStart = THEME:GetString("GeneralInfo", "UnforceStart"),
	ForceStart = THEME:GetString("GeneralInfo", "ForceStart"),
	Unready = THEME:GetString("GeneralInfo", "Unready"),
	Ready = THEME:GetString("GeneralInfo", "Ready"),
	TogglePreview = THEME:GetString("ScreenSelectMusic", "TogglePreview"),
	PlayerOptions = THEME:GetString("ScreenSelectMusic", "PlayerOptions"),
	OpenSort = THEME:GetString("ScreenSelectMusic", "OpenSortMenu"),
	CloseSort = THEME:GetString("ScreenSelectMusic", "CloseSortMenu"),
}

-- to reduce repetitive code for setting preview music position with booleans
local function playMusicForPreview(song)
	SOUND:StopMusic()
	SCREENMAN:GetTopScreen():PlayCurrentSongSampleMusic(true, true)
	MESSAGEMAN:Broadcast("PreviewMusicStarted") -- this is lying tbh

	restartedMusic = true

	-- use this opportunity to set all the random booleans to make it consistent
	songChanged = false
	boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
	hackysack = false
end

-- to toggle calc info display stuff
local function toggleCalcInfo(state)
	infoOnScreen = state

	if infoOnScreen then
		MESSAGEMAN:Broadcast("CalcInfoOn")
	else
		MESSAGEMAN:Broadcast("CalcInfoOff")
	end
end

local hoverAlpha = 0.8
local hoverAlpha2 = 0.6

-- to reduce repetitive code for setting preview visibility with booleans
local function setPreviewPartsState(state)
	if state == nil then return end
	mcbootlarder:visible(state)
	mcbootlarder:GetChild("NoteField"):visible(state)
	heyiwasusingthat = not state
	previewVisible = state
	if state ~= infoOnScreen and not state then
		toggleCalcInfo(false)
	end
end

local function toggleNoteField()
	local nf = mcbootlarder:GetChild("NoteField")
	if song and not noteField then -- first time setup
		noteField = true
		MESSAGEMAN:Broadcast("ChartPreviewOn") -- for banner reaction... lazy -mina
		mcbootlarder:playcommand("SetupNoteField")
		mcbootlarder:xy(prevX, prevY)
		mcbootlarder:diffusealpha(1)

		pOptions = GAMESTATE:GetPlayerState():GetCurrentPlayerOptions()
		usingreverse = pOptions:UsingReverse()
		local usingscrollmod = false
		if pOptions:Split() ~= 0 or pOptions:Alternate() ~= 0 or pOptions:Cross() ~= 0 or pOptions:Centered() ~= 0 then
			usingscrollmod = true
		end

		nf:y(prevY * 2.85)
		if usingscrollmod then
			nf:y(prevY * 3.55)
		elseif usingreverse then
			nf:y(prevY * 2.85 + prevrevY)
		end

		if not songChanged then
			playMusicForPreview(song)
			tryingToStart = true
		else
			tryingToStart = false
		end
		songChanged = false
		hackysack = false
		previewVisible = true
		return true
	end

	if song then
		nf:diffusealpha(1)
		if mcbootlarder:IsVisible() then
			mcbootlarder:visible(false)
			nf:visible(false)
			MESSAGEMAN:Broadcast("ChartPreviewOff")
			toggleCalcInfo(false)
			previewVisible = false
			hackysack = changingSongs
			changingSongs = false
			return false
		else
			mcbootlarder:visible(true)
			nf:visible(true)
			if boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone or songChanged or songChanged2 then
				if not restartedMusic then
					playMusicForPreview(song)
				end
				boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
				hackysack = false
				songChanged = false
				songChanged2 = false
			end
			MESSAGEMAN:Broadcast("ChartPreviewOn")
			previewVisible = true
			return true
		end
	end
	return false
end

local mintyFreshIntervalFunction = nil
local update = false
local t = Def.ActorFrame {
	Name = "wifetwirler",
	BeginCommand = function(self)
		self:queuecommand("MintyFresh")
	end,
	OffCommand = function(self)
		self:bouncebegin(0.2):xy(-500, 0):diffusealpha(0)
		toggleCalcInfo(false)
		self:sleep(0.04):queuecommand("Invis")
	end,
	InvisCommand= function(self)
		self:visible(false)
	end,
	OnCommand = function(self)
		self:bouncebegin(0.2):xy(0, 0):diffusealpha(1)
	end,
	CurrentSongChangedMessageCommand = function()
		-- This will disable mirror when switching songs if OneShotMirror is enabled or if permamirror is flagged on the chart (it is enabled if so in screengameplayunderlay/default)
		if playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).OneShotMirror or profile:IsCurrentChartPermamirror() then
			local modslevel = topscreen == "ScreenEditOptions" and "ModsLevel_Stage" or "ModsLevel_Preferred"
			local playeroptions = GAMESTATE:GetPlayerState():GetPlayerOptions(modslevel)
			playeroptions:Mirror(false)
		end
		-- if not on General and we started the noteField and we changed tabs then changed songs
		-- this means the music should be set again as long as the preview is still "on" but off screen
		if getTabIndex() ~= 0 and noteField and heyiwasusingthat then
			boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = true
		end

		-- if the preview was turned on ever but is currently not on screen as the song changes
		-- this goes hand in hand with the above boolean
		if noteField and not previewVisible then
			songChanged = true
		end

		-- check to see if the song actually really changed
		-- >:(
		if noteField and GAMESTATE:GetCurrentSong() ~= song then
			-- always true if switching songs and preview has ever been opened
			songChanged2 = true
			restartedMusic = false
		else
			songChanged2 = false
		end

		-- an awkwardly named bool describing the fact that we just changed songs
		-- used in notefield creation function to see if we should restart music
		-- it is immediately turned off when toggling notefield
		changingSongs = true
		tryingToStart = false

		-- if switching songs, we want the notedata to disappear temporarily
		if noteField and songChanged2 and previewVisible then
			mcbootlarder:GetChild("NoteField"):finishtweening()
			mcbootlarder:GetChild("NoteField"):diffusealpha(0)
		end
	end,
	DelayedChartUpdateMessageCommand = function(self)
		-- wait for the music wheel to settle before playing the music
		-- to keep things very slightly more easy to deal with
		-- and reduce a tiny bit of lag
		local s = GAMESTATE:GetCurrentSong()
		local unexpectedlyChangedSong = s ~= song

		local st = GAMESTATE:GetCurrentSteps()

		shouldPlayMusic = false
		-- should play the music because the notefield is visible
		shouldPlayMusic = shouldPlayMusic or (noteField and mcbootlarder:GetChild("NoteField") and mcbootlarder:GetChild("NoteField"):IsVisible())
		-- should play the music if we switched songs while on a different tab
		shouldPlayMusic = shouldPlayMusic or boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone
		-- should play the music if we switched to a song from a pack tab
		-- also applies for if we just toggled the notefield or changed screen tabs
		shouldPlayMusic = shouldPlayMusic or hackysack
		-- should play the music if we already should and we either jumped song or we didnt change the song
		shouldPlayMusic = shouldPlayMusic and (not onlyChangedSteps or unexpectedlyChangedSong) and not tryingToStart

		if onlyChangedSteps and not shouldPlayMusic then
			-- the sample music for a single song might change
			-- if it is ssc and defines different songs for the music
			if st ~= nil then
				if st:GetPreviewMusicPath() ~= self.stepspreview then
					shouldPlayMusic = true
					self:queuecommand("PlayingSampleMusic")
				end
			end
		end

		if st ~= nil then
			self.stepspreview = st:GetPreviewMusicPath()
		else
			self.stepspreview = nil
		end

		-- at this point the music will or will not play ....

		boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
		hackysack = false
		tryingToStart = false
		songChanged = false
		onlyChangedSteps = true
	end,
	PlayingSampleMusicMessageCommand = function(self)
		-- delay setting the music for preview up until after the sample music starts (smoothness)
		if shouldPlayMusic then
			shouldPlayMusic = false
			local s = GAMESTATE:GetCurrentSong()
			if s then
				if mcbootlarder and mcbootlarder:GetChild("NoteField") then mcbootlarder:GetChild("NoteField"):diffusealpha(1) end
				playMusicForPreview(s)
			end
		end
	end,
	MintyFreshCommand = function(self)
		self:finishtweening()
		local bong = GAMESTATE:GetCurrentSong()
		-- if not on a song and preview is on, hide it (dont turn it off)
		if not bong and noteField and mcbootlarder:IsVisible() then
			setPreviewPartsState(false)
			MESSAGEMAN:Broadcast("ChartPreviewOff")
		end

		-- if the song changed
		if song ~= bong then
			if not lockbools then
				onlyChangedSteps = false
			end
			if not song and previewVisible and not lockbools then
				hackysack = true -- used in cases when moving from null song (pack hover) to a song (this fixes searching and preview not working)
			end
			song = bong
			self:queuecommand("MortyFarts")
		else
			if not lockbools and not songChanged2 then
				onlyChangedSteps = true
			end
		end

		-- on general tab
		if getTabIndex() == 0 then
			-- if preview was on and should be made visible again
			if heyiwasusingthat and bong and noteField then
				setPreviewPartsState(true)
				MESSAGEMAN:Broadcast("ChartPreviewOn")
			elseif bong and noteField and previewVisible then
				-- make sure that it is visible even if it isnt, when it should be
				-- (haha lets call this 1000000 times nothing could go wrong)
				setPreviewPartsState(true)
			end

			self:visible(true)
			self:queuecommand("On")
			update = true
		else
			-- changing tabs off of general with preview on, hide the preview
			if bong and noteField and mcbootlarder:IsVisible() then
				setPreviewPartsState(false)
				MESSAGEMAN:Broadcast("ChartPreviewOff")
			end

			self:queuecommand("Off")
			update = false
		end
		lockbools = false
	end,
	TabChangedMessageCommand = function(self)
		local newtab = getTabIndex()
		if newtab ~= prevtab then
			self:queuecommand("MintyFresh")
			prevtab = newtab
			if getTabIndex() == 0 and noteField then
				mcbootlarder:GetChild("NoteField"):diffusealpha(1)
				lockbools = true
			elseif getTabIndex() ~= 0 and noteField then
				hackysack = mcbootlarder:IsVisible()
				onlyChangedSteps = false
				boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
				lockbools = true
			end
		end
	end,
	MilkyTartsCommand = function(self) -- when entering pack screenselectmusic explicitly turns visibilty on notefield off -mina
		if noteField and mcbootlarder:IsVisible() then
			toggleCalcInfo(false)
		end
	end,
	CurrentStepsChangedMessageCommand = function(self)
		-- this basically queues MintyFresh every 0.5 seconds but only once and also resets the 0.5 seconds
		-- if you scroll again
		-- so if you scroll really fast it doesnt pop at all until you slow down
		-- lag begone
		local topscr = SCREENMAN:GetTopScreen()

		if mintyFreshIntervalFunction ~= nil then
			topscr:clearInterval(mintyFreshIntervalFunction)
			mintyFreshIntervalFunction = nil
		end
		mintyFreshIntervalFunction = topscr:setInterval(function()
			self:queuecommand("MintyFresh")
			if mintyFreshIntervalFunction ~= nil then
				topscr:clearInterval(mintyFreshIntervalFunction)
				mintyFreshIntervalFunction = nil
			end
		end,
		0.05)
	end,
	-- Seraphic: one window for the whole left info area, split by thin lines instead of three separate frames
	infoWindowBody(),
	infoWindowDecor(),
}

-- Music Rate Display
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	InitCommand = function(self)
		self:xy(colA + 56, infoTop + 62):visible(true):halign(0.5):zoom(0.34):maxwidth(
			capWideScale(get43size(360), 360) / capWideScale(get43size(0.45), 0.45)
		)
	end,
	CurrentRateChangedMessageCommand = function(self)
		self:queuecommand("MintyFresh")
	end,
	MintyFreshCommand = function(self)
		if song then
			self:settext((getCurRateDisplayString():gsub("%s*Music%s*", "")))
		else
			self:settext("")
		end
	end,
	CodeMessageCommand = function(self, params)
		local rate = getCurRateValue()
		ChangeMusicRate(rate, params)
		self:settext((getCurRateDisplayString():gsub("%s*Music%s*", "")))
	end,
	GoalSelectedMessageCommand = function(self)
		self:queuecommand("MintyFresh")
	end,
	MouseOverCommand = function(self)
		self:diffusealpha(hoverAlpha2)
	end,
	MouseOutCommand = function(self)
		self:diffusealpha(1)
	end,
	MouseDownCommand = function(self, params)
		if not self:IsVisible() then return end
		if params.event == "DeviceButton_right mouse button" then
			ChangeMusicRate(nil, {Name="NextRate"})
		elseif params.event == "DeviceButton_left mouse button" then
			ChangeMusicRate(nil, {Name="PrevRate"})
		end
		self:settext((getCurRateDisplayString():gsub("%s*Music%s*", "")))
	end,
}

t[#t + 1] = Def.Actor {
	MintyFreshCommand = function(self)
		if song then
			ptags = tags:get_data().playerTags
			steps = GAMESTATE:GetCurrentSteps()
			chartKey = steps:GetChartKey()
			ctags = {}
			for k, v in pairs(ptags) do
				if ptags[k][chartKey] then
					ctags[#ctags + 1] = k
				end
			end
		end
	end
}

t[#t + 1] = Def.ActorFrame {
	Name = "RateDependentStuff", -- msd/display score/bpm/songlength -mina
	MintyFreshCommand = function()
		score = GetDisplayScore()
	end,
	CurrentRateChangedMessageCommand = function(self)
		self:queuecommand("MintyFresh") --steps stuff
		self:queuecommand("MortyFarts") --songs stuff
	end,
	LoadFont("Common Large") .. {
		Name = "MSD",
		InitCommand = function(self)
			self:xy(colA + 56, infoTop + 38):halign(0.5):zoom(0.6):maxwidth(100 / 0.6)
		end,
		MintyFreshCommand = function(self)
			if song then
				local stype = steps:GetStepsType()
				local meter = steps:GetMSD(getCurRateValue(), 1)
				self:settextf("%05.2f", meter)
				self:diffuse(byMSD(meter))
			else
				self:settext("")
			end
		end
	},
	-- skillset suff (these 3 can prolly be wrapped)
	LoadFont("Seraphic Artist") .. {
		Name = "SkillsetName1",
		InitCommand = function(self)
			self:xy(colB + 20, infoTop + 32):halign(0):zoom(0.5):maxwidth((ssRowW - 58) / 0.5):diffuse(color("#f4ecee"))
		end,
		MintyFreshCommand = function(self)
			if song and GAMESTATE:GetCurrentStyle():ColumnsPerPlayer() == 4 then
				local ss = steps:GetRelevantSkillsetsByMSDRank(getCurRateValue(), 1)
				local out = ss == "" and "" or ms.SkillSetsTranslatedByName[ss]

				self:settext(out)
			else
				self:settext("")
			end
		end,
		ChartPreviewOnMessageCommand = function(self)
			self:visible(false)
		end,
		ChartPreviewOffMessageCommand = function(self)
			self:visible(true)
		end
	},
	LoadFont("Seraphic Artist") .. {
		Name = "SkillsetName2",
		InitCommand = function(self)
			self:xy(colB + 20, infoTop + 54):halign(0):zoom(0.5):maxwidth((ssRowW - 58) / 0.5):diffuse(color("#f4ecee"))
		end,
		MintyFreshCommand = function(self)
			if song and GAMESTATE:GetCurrentStyle():ColumnsPerPlayer() == 4 then
				local ss = steps:GetRelevantSkillsetsByMSDRank(getCurRateValue(), 2)
				local out = ss == "" and "" or ms.SkillSetsTranslatedByName[ss]
				self:settext(out)
			else
				self:settext("")
			end
		end,
		ChartPreviewOnMessageCommand = function(self)
			self:visible(false)
		end,
		ChartPreviewOffMessageCommand = function(self)
			self:visible(true)
		end
	},
	LoadFont("Seraphic Artist") .. {
		Name = "SkillsetName3",
		InitCommand = function(self)
			self:xy(colB + 20, infoTop + 76):halign(0):zoom(0.5):maxwidth((ssRowW - 58) / 0.5):diffuse(color("#f4ecee"))
		end,
		MintyFreshCommand = function(self)
			if song and GAMESTATE:GetCurrentStyle():ColumnsPerPlayer() == 4 then
				local ss = steps:GetRelevantSkillsetsByMSDRank(getCurRateValue(), 3)
				local out = ss == "" and "" or ms.SkillSetsTranslatedByName[ss]
				self:settext(out)
			else
				self:settext("")
			end
		end,
		ChartPreviewOnMessageCommand = function(self)
			self:visible(false)
		end,
		ChartPreviewOffMessageCommand = function(self)
			self:visible(true)
		end
	},
	LoadFont("Seraphic Artist") .. {
		InitCommand = function(self)
			self:xy(colB + ssRowW, infoTop + 32):halign(1):zoom(0.5)
		end,
		MintyFreshCommand = function(self)
			self:settext("")
			if song and steps and GAMESTATE:GetCurrentStyle():ColumnsPerPlayer() == 4 then
				local ss = steps:GetRelevantSkillsetsByMSDRank(getCurRateValue(), 1)
				for i, name in ipairs(ms.SkillSets) do
					if name == ss then
						local v = steps:GetMSD(getCurRateValue(), i)
						self:settextf("%05.2f", v):diffuse(byMSD(v))
						break
					end
				end
			end
		end,
		ChartPreviewOnMessageCommand = function(self) self:visible(false) end,
		ChartPreviewOffMessageCommand = function(self) self:visible(true) end
	},
	LoadFont("Seraphic Artist") .. {
		InitCommand = function(self)
			self:xy(colB + ssRowW, infoTop + 54):halign(1):zoom(0.5)
		end,
		MintyFreshCommand = function(self)
			self:settext("")
			if song and steps and GAMESTATE:GetCurrentStyle():ColumnsPerPlayer() == 4 then
				local ss = steps:GetRelevantSkillsetsByMSDRank(getCurRateValue(), 2)
				for i, name in ipairs(ms.SkillSets) do
					if name == ss then
						local v = steps:GetMSD(getCurRateValue(), i)
						self:settextf("%05.2f", v):diffuse(byMSD(v))
						break
					end
				end
			end
		end,
		ChartPreviewOnMessageCommand = function(self) self:visible(false) end,
		ChartPreviewOffMessageCommand = function(self) self:visible(true) end
	},
	LoadFont("Seraphic Artist") .. {
		InitCommand = function(self)
			self:xy(colB + ssRowW, infoTop + 76):halign(1):zoom(0.5)
		end,
		MintyFreshCommand = function(self)
			self:settext("")
			if song and steps and GAMESTATE:GetCurrentStyle():ColumnsPerPlayer() == 4 then
				local ss = steps:GetRelevantSkillsetsByMSDRank(getCurRateValue(), 3)
				for i, name in ipairs(ms.SkillSets) do
					if name == ss then
						local v = steps:GetMSD(getCurRateValue(), i)
						self:settextf("%05.2f", v):diffuse(byMSD(v))
						break
					end
				end
			end
		end,
		ChartPreviewOnMessageCommand = function(self) self:visible(false) end,
		ChartPreviewOffMessageCommand = function(self) self:visible(true) end
	},
	-- **score related stuff** These need to be updated with rate changed commands
	-- Primary percent score
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(-1000, 0):zoom(0.6):halign(0.5):maxwidth(150):valign(1)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local perc = score:GetWifeScore() * 100
				if perc > 99.65 then
					self:settextf("%05.4f%%", notShit.floor(perc, 4))
				else
					self:settextf("%05.2f%%", notShit.floor(perc, 2))
				end
				self:diffuse(getGradeColor(score:GetWifeGrade()))
			else
				self:settext("")
			end
		end
	},
	-- Seraphic: LR2 rank emblem for the displayed score
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_rankglyph_7"),
		InitCommand = function(self)
			self:xy(-1000, 0):zoomto(66, 28):blend("BlendMode_Add"):visible(false)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local k = seraphicGradeIndex(score:GetWifeGrade()) or 7
				seraphicGradeFit(self, k, 28 / 32):visible(true)
			else
				self:visible(false)
			end
		end
	},
	-- Mirror PB Indicator
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(-1000, 0):zoom(0.5):halign(1)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local mirrorStr = ""
				if score:GetModifiers():lower():find("mirror") then
					mirrorStr = "(M)"
				end
				self:settext(mirrorStr)
			else
				self:settext("")
			end
		end
	},
	-- Rate for the displayed score
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(-1000, 0):zoom(0.5):halign(0.5)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local rate = notShit.round(score:GetMusicRate(), 3)
				local notCurRate = notShit.round(getCurRateValue(), 3) ~= rate
				local rate = string.format("%.2f", rate)
				if rate:sub(#rate, #rate) == "0" then
					rate = rate:sub(0, #rate - 1)
				end
				rate = rate .. "x"
				if notCurRate then
					self:settext("(" .. rate .. ")")
				else
					self:settext(rate)
				end
			else
				self:settext("")
			end
		end
	},
	-- wife 2/3 indicator
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(-1000, 0):zoom(0.5):halign(0):maxwidth(140)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local wv = score:GetWifeVers()
				local ws = " W" .. wv
				self:settext(ws):diffuse(byGrade(score:GetWifeGrade()))
			else
				self:settext("")
			end
		end
	},
	-- goal for current rate if there is one stuff
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "Goalll",
		InitCommand = function(self)
			self:xy(colB + 10, goalY):zoom(0.42):halign(0):maxwidth((colC - colB - 16) / 0.42)
			self:diffuse(getMainColor("positive"))
		end,
		GoalsUpdatedMessageCommand = function(self)
			self:playcommand("MintyFresh")
		end,
		MintyFreshCommand = function(self)
			if song and steps then
				local goal = profile:GetEasiestGoalForChartAndRate(steps:GetChartKey(), getCurRateValue())
				if goal then
					local perc = notShit.round(goal:GetPercent() * 100000) / 1000
					if (perc < 99.8) then
						self:settextf("%s : %.2f%%", translated_info["GoalTarget"]:upper(), perc)
					else
						self:settextf("%s : %.3f%%", translated_info["GoalTarget"]:upper(), perc)
					end
				else
					self:settext("")
				end
			else
				self:settext("")
			end
		end,
		MouseDownCommand = function(self, params)
			if song and steps then
				if params.event == "DeviceButton_left mouse button" then
					local sg = profile:GetEasiestGoalForChartAndRate(steps:GetChartKey(), getCurRateValue())
					if sg and update then
						sg:SetPercent(sg:GetPercent() + 0.01)
						self:GetParent():GetParent():GetDescendant("RateDependentStuff", "Goalll"):queuecommand("MintyFresh")
					end
				elseif params.event == "DeviceButton_right mouse button" then
					local sg = profile:GetEasiestGoalForChartAndRate(steps:GetChartKey(), getCurRateValue())
					if sg and update then
						sg:SetPercent(sg:GetPercent() - 0.01)
						self:GetParent():GetParent():GetDescendant("RateDependentStuff", "Goalll"):queuecommand("MintyFresh")
					end
				end
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	-- Date score achieved on
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(-1000, 0):zoom(0.4):halign(0)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				self:settext(getScoreDate(score))
            else
                self:settext("")
            end
		end
	},
	-- MaxCombo
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(-1000, 0):zoom(0.4):halign(0)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				self:settextf("%s: %d", translated_info["MaxCombo"], score:GetMaxCombo())
			else
				self:settext("")
			end
		end
	},
	LoadFont("Common Normal") .. {
		Name = "ClearType",
		InitCommand = function(self)
			self:xy(-1000, 0):zoom(0.6):halign(0)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				self:visible(true)
				self:settext(getClearTypeFromScore(PLAYER_1, score, 0))
				self:diffuse(getClearTypeFromScore(PLAYER_1, score, 2))
			else
				self:visible(false)
			end
		end
	},
	-- **song stuff that scales with rate**
	Def.BPMDisplay {
		File = THEME:GetPathF("BPMDisplay", "bpm"),
		Name = "BPMDisplay",
		InitCommand = function(self)
			self:xy(colCEnd - 4, infoTop + 102):halign(1):zoom(0.44):maxwidth(40 / 0.44):diffuse(color("#f4ecee"))
		end,
		MintyFreshCommand = function(self)
			if song then
				self:visible(true)
				self:SetFromSteps(steps)
			else
				self:visible(false)
			end
		end
	},
	LoadFont("Common Large") .. {
		Name = "PlayableDuration",
		InitCommand = function(self)
			self:xy(colCEnd - 4, infoTop + 120):visible(true):halign(1):zoom(0.24):maxwidth(40 / 0.24)
		end,
		MintyFreshCommand = function(self)
			if song then
				local playabletime = GetPlayableTime()
				self:settext(SecondsToMMSS(playabletime))
				self:diffuse(byMusicLength(playabletime))
			else
				self:settext("")
			end
		end
	},
}

-- "Radar values", noteinfo that isn't rate dependent -mina
local function radarPairs(i)
	local o = Def.ActorFrame {
		Name = "radarpair_"..i,
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(colA + 10, infoTop + 78 + 14 * i):zoom(0.38):halign(0):maxwidth(50 / 0.38):diffuse(color(silverC))
			end,
			MintyFreshCommand = function(self)
				if song then
					self:settext((ms.RelevantRadarsShort[i]:gsub(":", "")):upper())
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(colA + 103, infoTop + 78 + 14 * i):zoom(0.4):halign(1):maxwidth(48 / 0.4):diffuse(color("#f4ecee"))
			end,
			CurrentStepsChangedMessageCommand = function(self, steps)
				if steps.ptr then
					-- LR2 style zero padded counts
					self:settextf("%05d", tonumber(steps.ptr:GetRelevantRadars()[i]) or 0)
				else
					self:settext("")
				end
			end
		},
	}
	return o
end

local r = Def.ActorFrame {
	Name = "RadarValues",
}

-- Create the radar values
for i = 1, 5 do
	r[#r + 1] = radarPairs(i)
end

-- putting lua warning here
r[#r + 1] = LoadFont("Common Large") .. {
	InitCommand = function(self)
		self:xy(colB + 10, goalY + 18):visible(true):halign(0):zoom(0.24):maxwidth((colC - colB - 16) / 0.24)
		self:diffuse(getMainColor("negative"))
	end,
	MintyFreshCommand = function(self)
		if song and song:HasLua() then
			self:settext(translated_info["HasLua"])
		else
			self:settext("")
		end
	end
}

t[#t + 1] = r

-- song only stuff that doesnt change with rate

-- bpm
t[#t + 1] =LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(colC + 8, infoTop + 102):halign(0):zoom(0.38):diffuse(color(silverC))
	end,
	MortyFartsCommand = function(self)
		if song then
			self:settext(translated_info["BPM"]:upper())
		else
			self:settext("")
		end
	end
}

-- length label
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(colC + 8, infoTop + 120):halign(0):zoom(0.38):diffuse(color(silverC))
	end,
	MortyFartsCommand = function(self)
		self:settext(song and "TIME" or "")
	end
}

-- cdtitle
t[#t + 1] = UIElements.SpriteButton(1, 1, nil) .. {
	InitCommand = function(self)
		self.bx, self.by = colC + 39, infoTop + 84
		self:xy(self.bx, self.by)
		self:halign(0.5):valign(1)
		self.clicked = false
	end,
	CurrentStyleChangedMessageCommand = function(self)
		self:playcommand("MortyFarts")
	end,
	MortyFartsCommand = function(self)
		self:finishtweening()
		self.song = song
		if song then
			if song:HasCDTitle() then
				self:visible(true)
				self:Load(song:GetCDTitlePath())
			else
				self:visible(false)
			end
		else
			self:visible(false)
		end
		local height = self:GetHeight()
		local width = self:GetWidth()

		if height >= 60 and width >= 75 then
			if height * (75 / 60) >= width then
				self:zoom(60 / height)
			else
				self:zoom(75 / width)
			end
		elseif height >= 60 then
			self:zoom(60 / height)
		elseif width >= 75 then
			self:zoom(75 / width)
		else
			self:zoom(1)
		end
		-- Seraphic: inside the 75x60 box a wide cd title hugs the top edge, a tall thin one the right edge
		do
			local zw, zh = width * self:GetZoom(), height * self:GetZoom()
			local bx, by = self.bx, self.by
			self:xy(bx, by):halign(0.5):valign(1)
			if zw >= 74 and zh < 60 then
				self:valign(0):y(by - 60)
			elseif zh >= 59 and zw < 75 then
				self:halign(1):x(bx + 37.5)
			end
		end
		if isOver(self) then
			self:playcommand("ToolTip")
		end
	end,
	ToolTipCommand = function(self)
		if isOver(self) then
			if self.song and song:HasCDTitle() and self:GetVisible() then
				local auth = self.song:GetOrTryAtLeastToGetSimfileAuthor()
				if auth and #auth > 0 and auth ~= "Author Unknown" then
					TOOLTIP:SetText(auth)
					TOOLTIP:Show()
				else
					TOOLTIP:Hide()
				end
			else
				TOOLTIP:Hide()
			end
		end
	end,
	ChartPreviewOnMessageCommand = function(self)
		if not itsOn then
			self:addx(capWideScale(34, 0))
			itsOn = true
		end
		self:playcommand("ToolTip")
	end,
	ChartPreviewOffMessageCommand = function(self)
		if itsOn then
			self:addx(capWideScale(-34, 0))
			itsOn = false
		end
		self:playcommand("ToolTip")
	end,
	MouseOverCommand = function(self)
		self:playcommand("ToolTip")
		self:diffusealpha(hoverAlpha)
	end,
	MouseOutCommand = function(self)
		TOOLTIP:Hide()
		self:diffusealpha(1)
	end,
	MouseDownCommand = function(self, params)
		-- because this button covers the background
		if params.event == "DeviceButton_right mouse button" then
			SCREENMAN:GetTopScreen():PauseSampleMusic()
			MESSAGEMAN:Broadcast("MusicPauseToggled")
		end
	end,
	MouseDoubleClickCommand = function(self, params)
		if params.event == "DeviceButton_left mouse button" then
			if not self:GetVisible() then return end
			local whee = SCREENMAN:GetTopScreen():GetMusicWheel()
			local author = string.lower(self.song:GetOrTryAtLeastToGetSimfileAuthor())

			if self.clicked then
				whee:ReloadSongList()
				MESSAGEMAN:Broadcast("SetSearchString", {searchstring = ""})
				self.clicked = false
			elseif whee ~= nil and author ~= nil then
				local theSongThatWasSelectedBeforeTheWheelWasReset = self.song
				local searchstring = "author=" .. author
				whee:SongSearch(searchstring)
				whee:SelectSong(theSongThatWasSelectedBeforeTheWheelWasReset)
				MESSAGEMAN:Broadcast("SetSearchString", {searchstring = searchstring})
				self.clicked = true
			end
		end
	end,
	UpdateStringMessageCommand = function(self)
		--if the searchstring is updated at all then we are no longer solely searching for the chart author,
		--so we should reset
		self.clicked = false
	end
}

t[#t + 1] = Def.Sprite {
	Name = "Banner",
	InitCommand = function(self)
		self:x(10):y(bannerY):halign(0):valign(0)
		self:scaletoclipped(bannerW, bannerH):diffusealpha(1)
	end,
	MintyFreshCommand = function(self)
		if INPUTFILTER:IsBeingPressed("tab") then
			self:finishtweening():smooth(0.25):diffusealpha(0):sleep(0.2):queuecommand("ModifyBanner")
		else
			self:finishtweening():queuecommand("ModifyBanner")
		end
	end,
	ModifyBannerCommand = function(self)
		self:finishtweening()
		if song and GAMESTATE:GetCurrentSong() ~= nil then
			local bnpath = GAMESTATE:GetCurrentSong():GetBannerPath()
			if not BannersEnabled() then
				self:visible(false)
			elseif not bnpath then
				bnpath = THEME:GetPathG("Common", "fallback banner")
			end
			self:LoadBackground(bnpath)
		else
			local bnpath = SONGMAN:GetSongGroupBannerPath(SCREENMAN:GetTopScreen():GetMusicWheel():GetSelectedSection())
			if not BannersEnabled() then
				self:visible(false)
			elseif not bnpath or bnpath == "" then
				bnpath = THEME:GetPathG("Common", "fallback banner")
			end
			self:LoadBackground(bnpath)
		end
		if self:GetNumStates() > 1 then
			self:StopUsingCustomTexCoords()
		else
			self:EnableCustomTexCoords()
		end
		self:diffusealpha(1)
	end,
	ChartPreviewOnMessageCommand = function(self)
		self:visible(false)
	end,
	ChartPreviewOffMessageCommand = function(self)
		self:visible(BannersEnabled())
	end
}
-- Seraphic: silver frame + crystals around the banner (hidden together with the banner)
do
	local bw, bh = bannerW, bannerH
	local function gem(x, y, zx)
		return Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_corner"),
			InitCommand = function(self)
				self:xy(x, y):halign(0):valign(0):zoomx(0.34 * zx):zoomy(0.34):diffusealpha(0.95)
			end
		}
	end
	t[#t + 1] = Def.ActorFrame {
		seraKeep = true, -- banner outline: stays when the info window hides on packs
		InitCommand = function(self) self:visible(BannersEnabled()) end,
		ChartPreviewOnMessageCommand = function(self) self:visible(false) end,
		ChartPreviewOffMessageCommand = function(self) self:visible(BannersEnabled()) end,
		-- thin outline instead of a full double frame (the corner gems stay)
		Def.Quad {InitCommand = function(self) self:xy(10, bannerY):halign(0):valign(0):zoomto(bw, 1):diffuse(color("#ffffff")):diffusealpha(0.4) end},
		Def.Quad {InitCommand = function(self) self:xy(10, bannerY + bh - 1):halign(0):valign(0):zoomto(bw, 1):diffuse(color("#ffffff")):diffusealpha(0.4) end},
		Def.Quad {InitCommand = function(self) self:xy(10, bannerY):halign(0):valign(0):zoomto(1, bh):diffuse(color("#ffffff")):diffusealpha(0.4) end},
		Def.Quad {InitCommand = function(self) self:xy(10 + bw - 1, bannerY):halign(0):valign(0):zoomto(1, bh):diffuse(color("#ffffff")):diffusealpha(0.4) end},
	}
end

local enabledC = "#099948"
local disabledC = "#ff6666"
local force = false
local ready = false
-- Seraphic: Ready / Force Start as LR2 toggles stacked right of the banner (they used to sit on top of it):
-- dark glass with a soft edge, crimson when on, lighter on hover
local function toggleButton(textEnabled, textDisabled, msg, x, extrawidth, y, enabledF)
	local ison = false
	local bw, bh = 84, 18
	local bx = capWideScale(get43size(438), 438)
	local by = (msg == "/force") and 188 or 166
	local function paint(self, over)
		local q = self:GetChild("Top")
		local glow = self:GetChild("Glow")
		if ison then
			q:diffuse(color("#9c1428")):diffusealpha(over and 0.75 or 0.55)
			glow:diffusealpha(0.35)
		else
			q:diffuse(color("#000000")):diffusealpha(over and 0.3 or 0.5)
			glow:diffusealpha(over and 0.2 or 0)
		end
		self:GetChild("Words"):settext((ison and textEnabled or textDisabled):upper())
		self:GetChild("Words"):diffuse(color(ison and seraphicValueColor or seraphicLabelColor))
	end
	return Def.ActorFrame {
		InitCommand = function(self)
			self:xy(bx, by)
			self.updatebutton = function()
				if self.ison ~= nil then
					ison = self.ison
				end
				paint(self, isOver(self:GetChild("Top")))
			end
		end,
		BeginCommand = function(self)
			paint(self, false)
		end,
		UIElements.QuadButton(1, 1) .. {
			Name = "Top",
			InitCommand = function(self)
				self:zoomto(bw, bh):diffuse(color("#000000")):diffusealpha(0.5)
			end,
			MouseOverCommand = function(self)
				paint(self:GetParent(), true)
			end,
			MouseOutCommand = function(self)
				paint(self:GetParent(), false)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" then
					if enabledF then
						ison = enabledF()
					else
						ison = (not ison)
					end
					paint(self:GetParent(), true)
					NSMAN:SendChatMsg(msg, 1, NSMAN:GetCurrentRoomName())
				end
			end,
		},
		-- crimson rule along the bottom, brighter while the toggle is on
		Def.Quad {
			Name = "Glow",
			InitCommand = function(self)
				self:y(bh / 2 - 1):zoomto(bw - 4, 1):diffuse(color("#e8b8c2")):diffusealpha(0)
			end
		},
		seraphicSoftEdge(-bw / 2, -bh / 2, bw, bh, 0.25),
		LoadFont("Common Normal") .. {
			Name = "Words",
			InitCommand = function(self)
				self:zoom(0.42):maxwidth((bw - 8) / 0.42)
				self:diffuse(color(seraphicLabelColor))
				self:settext(textDisabled:upper())
			end,
		},
	}
end
local forceStart = toggleButton(translated_info["UnForceStart"], translated_info["ForceStart"], "/force", -35, 30, 11) .. {
	Name = "ForceStart",
}
local readyButton = nil
do
	-- do-end block to minimize the scope of 'f'
	local areWeReadiedUp = function()
		local top = SCREENMAN:GetTopScreen()
		if top:GetName() == "ScreenNetSelectMusic" then
			local qty = top:GetUserQty()
			local loggedInUser = NSMAN:GetLoggedInUsername()
			for i = 1, qty do
				local user = top:GetUser(i)
				if user == loggedInUser then
					return top:GetUserReady(i)
				end
			end
			-- ???? this should never happen
			-- retroactive - had this happen once and i still dont know why
			error "Could not find ourselves in the userlist"
		end
	end
	readyButton = toggleButton(translated_info["Unready"], translated_info["Ready"], "/ready", 50, 0, 11, areWeReadiedUp) .. {
		Name = "Ready",
		UsersUpdateMessageCommand = function(self)
			self.ison = areWeReadiedUp()
			self.updatebutton()
		end
	}
end

local sn = Var ("LoadingScreen")
if sn and sn:find("Net") ~= nil then
	t[#t + 1] = forceStart
	t[#t + 1] = readyButton
end

-- t[#t+1] = LoadFont("Common Large") .. {
-- InitCommand=function(self)
-- 	self:xy((capWideScale(get43size(384),384))+68,SCREEN_BOTTOM-135):halign(1):zoom(0.4,maxwidth,125)
-- end,
-- BeginCommand=function(self)
-- 	self:queuecommand("Set")
-- end,
-- SetCommand=function(self)
-- if song then
-- self:settext(song:GetOrTryAtLeastToGetSimfileAuthor())
-- else
-- self:settext("")
-- end
-- end,
-- CurrentStepsChangedMessageCommand=function(self)
-- 	self:queuecommand("Set")
-- end,
-- RefreshChartInfoMessageCommand=function(self)
-- 	self:queuecommand("Set")
-- end,
-- }

-- active filters display
-- t[#t+1] = Def.Quad{InitCommand=cmd(xy,16,capWideScale(SCREEN_TOP+172,SCREEN_TOP+194);zoomto,SCREEN_WIDTH*1.35*0.4 + 8,24;halign,0;valign,0.5;diffuse,color("#000000");diffusealpha,0),
-- EndingSearchMessageCommand=function(self)
-- self:diffusealpha(1)
-- end
-- }
-- t[#t+1] = LoadFont("Common Large") .. {
-- InitCommand=function(self)
-- 	self:xy(20,capWideScale(SCREEN_TOP+170,SCREEN_TOP+194)):halign(0):zoom(0.4):settext("Active Filters: "..GetPersistentSearch()):maxwidth(SCREEN_WIDTH*1.35)
-- end,
-- EndingSearchMessageCommand=function(self, msg)
-- self:settext("Active Filters: "..msg.ActiveFilter)
-- end
-- }

-- tags: stacked in their own column on wide screens, one line under the skillsets otherwise
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(tagX, tagsBeside and tagY or tagY + 12):halign(0):valign(0):zoom(0.4):vertspacing(4)
		self:maxwidth((colC - tagX - 6) / 0.4):diffuse(color("#f4ecee"))
	end,
	MintyFreshCommand = function(self)
		local shown = {}
		if song and ctags then
			for i = 1, math.min(#ctags, 3) do
				shown[i] = ctags[i]
			end
		end
		self:settext(table.concat(shown, tagsBeside and "\n" or "  /  "))
	end,
	ChartPreviewOnMessageCommand = function(self)
		self:visible(false)
	end,
	ChartPreviewOffMessageCommand = function(self)
		self:visible(true)
	end
}

--Chart Preview Button
local yesiwantnotefield = false
local lastratepresses = {0,0}
local function ihatestickinginputcallbackseverywhere(event)
	if event.type ~= "InputEventType_Release" and getTabIndex() == 0 then
		if event.DeviceInput.button == "DeviceButton_space" then
			toggleNoteField()
		end
		if event.GameButton == "EffectUp" then
			lastratepresses[1] = 0
		end
		if event.GameButton == "EffectDown" then
			lastratepresses[2] = 0
		end
	end
	if event.type == "InputEventType_FirstPress" then
		local CtrlPressed = INPUTFILTER:IsControlPressed()
		if CtrlPressed and event.DeviceInput.button == "DeviceButton_l" then
			MESSAGEMAN:Broadcast("LoginHotkeyPressed")
		end
		if event.GameButton == "EffectUp" then
			lastratepresses[1] = GetTimeSinceStart()
		end
		if event.GameButton == "EffectDown" then
			lastratepresses[2] = GetTimeSinceStart()
		end
		-- this sucks so bad
		if math.abs(lastratepresses[1] - lastratepresses[2]) < 0.05 and lastratepresses[1] ~= 0 and lastratepresses[2] ~= 0 then
			MESSAGEMAN:Broadcast("Code", {Name="ResetRate"})
			ChangeMusicRate(nil, {Name="ResetRate"})
		end
	end
	return false
end

local prevplayerops = "Main"

local lastsortmode = nil
t[#t + 1] = Def.ActorFrame {
	Name = "LittleButtonsOnTheLeft",

	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "PreviewViewer",
		BeginCommand = function(self)
			mcbootlarder = self:GetParent():GetParent():GetChild("ChartPreview")
			SCREENMAN:GetTopScreen():AddInputCallback(MPinput)
			SCREENMAN:GetTopScreen():AddInputCallback(ihatestickinginputcallbackseverywhere)
			self:xy(-1000, 235):zoom(0.5):halign(0):maxwidth(186)
			self:diffuse(getMainColor("positive"))
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and (song or noteField) then
				toggleNoteField()
			elseif params.event == "DeviceButton_right mouse button" and (song or noteField) then
				if mcbootlarder:IsVisible() then
					toggleCalcInfo(not infoOnScreen)
				else
					if toggleNoteField() then
						toggleCalcInfo(true)
					end
				end
			end
		end,
		ChartPreviewOnMessageCommand = function(self)
			local ready = self:GetParent():GetParent():GetChild("Ready")
			local force = self:GetParent():GetParent():GetChild("ForceStart")
			if ready ~= nil then
				ready:visible(false)
			end
			if force ~= nil then
				force:visible(false)
			end
		end,
		ChartPreviewOffMessageCommand = function(self)
			if SCREENMAN:GetTopScreen():GetName():find("Net") ~= nil then
				local ready = self:GetParent():GetParent():GetChild("Ready")
				local force = self:GetParent():GetParent():GetChild("ForceStart")
				if ready ~= nil then
					ready:visible(true)
				end
				if force ~= nil then
					force:visible(true)
				end
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha2)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MintyFreshCommand = function(self)
			if song then
				self:settext(translated_info["TogglePreview"])
			else
				self:settext("")
			end
		end,
	},

	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "PlayerOptionsButton",
		BeginCommand = function(self)
			self:xy(-1000, 218):halign(0):zoom(0.5):maxwidth(186)
			self:settext(translated_info["PlayerOptions"])
			self:diffuse(getMainColor("positive"))
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha2)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and song then
				SCREENMAN:GetTopScreen():OpenOptions()
			end
		end,
		OptionsScreenClosedMessageCommand = function(self)
			-- hate this so much
			-- the point of this is to force the multi paged options screen to work when using this button
			-- its a massive hack
			local nextplayerops = getenv("NewOptions") or "Main"
			if nextplayerops == prevplayerops then
				-- exit the options and dont reopen and reset its state
				setenv("NewOptions", "Main")
				prevplayerops = "Main"
				return
			end

			prevplayerops = nextplayerops
			setenv("NewOptions", nextplayerops)
			-- if you ever reload the options screen and the game hard locks, this is why
			SCREENMAN:GetTopScreen():OpenOptions()
		end,
	},

--[[ -- This is the Widget Button alternative of the above implementation.
t[#t + 1] =
	Widg.Button {
	text = "Options",
	width = 50,
	height = 25,
	border = false,
	bgColor = BoostColor(getMainColor("frames"), 7.5),
	highlight = {color = BoostColor(getMainColor("frames"), 10)},
	x = SCREEN_WIDTH / 2,
	y = 5,
	onClick = function(self)
		SCREENMAN:GetTopScreen():OpenOptions()
	end
}]]

	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "MusicWheelSortButton",
		BeginCommand = function(self)
			self:xy(-1000, 201):zoom(0.5):halign(0):maxwidth(186):settext(translated_info["OpenSort"])
			self:diffuse(getMainColor("positive"))
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				if GAMESTATE:GetSortOrder() == "SortOrder_ModeMenu" then
					if lastsortmode == nil then lastsortmode = "SortOrder_Group" end
					SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort(lastsortmode)
					return
				end
				lastsortmode = GAMESTATE:GetSortOrder()

				local ind = 0 -- 0 is group sort usually
				-- find the sort mode menu no matter where it is
				for i, sm in ipairs(SortOrder) do
					if sm == "SortOrder_ModeMenu" then
						ind = i - 1
						break
					end
				end
				SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort(ind)
			end
		end,
		SortOrderChangedMessageCommand = function(self)
			local so = GAMESTATE:GetSortOrder()
			if so == "SortOrder_ModeMenu" then
				self:settext(translated_info["CloseSort"])
			else
				self:settext(translated_info["OpenSort"])
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha2)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	}
}

-- Seraphic: the info window only shows on songs; on a pack row (no song selected) it fades away.
-- Everything except the banner, its outline and the off-screen buttons moves into one frame for that.
do
	local keep = {Banner = true, LittleButtonsOnTheLeft = true, Ready = true, ForceStart = true}
	local panel = Def.ActorFrame {
		Name = "InfoPanel",
		BeginCommand = function(self)
			self:playcommand("SeraPanel", {instant = true})
		end,
		CurrentSongChangedMessageCommand = function(self)
			self:playcommand("SeraPanel")
		end,
		SeraPanelCommand = function(self, params)
			local show = GAMESTATE:GetCurrentSong() ~= nil
			if show == self.shown then return end
			self.shown = show
			self:stoptweening()
			if show then
				self:visible(true)
				if params and params.instant then self:diffusealpha(1) else self:linear(0.15):diffusealpha(1) end
			elseif params and params.instant then
				self:diffusealpha(0):visible(false)
			else
				self:linear(0.15):diffusealpha(0):queuecommand("SeraPanelHide")
			end
		end,
		SeraPanelHideCommand = function(self)
			if not self.shown then self:visible(false) end
		end
	}
	local rest = {}
	for _, a in ipairs(t) do
		if (a.Name and keep[a.Name]) or a.seraKeep then
			rest[#rest + 1] = a
		else
			panel[#panel + 1] = a
		end
	end
	for i = #t, 1, -1 do t[i] = nil end
	t[1] = panel
	for _, a in ipairs(rest) do t[#t + 1] = a end
end

t[#t + 1] = LoadActorWithParams("../_chartpreview.lua", {yPos = prevY, yPosReverse = prevrevY})
return t
