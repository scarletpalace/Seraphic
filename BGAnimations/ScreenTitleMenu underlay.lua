if IsSMOnlineLoggedIn() then
	CloseConnection()
end

local t = Def.ActorFrame {}

local frameX = THEME:GetMetric("ScreenTitleMenu", "ScrollerX") - 10
local frameY = THEME:GetMetric("ScreenTitleMenu", "ScrollerY")

--Fractal backdrop
t[#t + 1] = LoadActor(THEME:GetPathG("", "_OptionsScreen")) .. {
	InitCommand = function(self)
		self:FullScreen():diffusealpha(1)
	end
}

--Left panel (vertical gradient)
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, 0):halign(0):valign(0):zoomto(250, 900):diffuse(getTitleColor('BG_Left')):diffusealpha(1)
		self:diffusetopedge(color("#1f1f1fF2"))
		self:diffusebottomedge(color("#03050aF2"))
	end
}

--Right panel (soft gradient fading darker to the right)
t[#t + 1] =	Def.Quad {
	InitCommand = function(self)
		self:xy(250, 0):halign(0):valign(0):zoomto(1000, 900):diffuse(getTitleColor('BG_Right')):diffusealpha(1)
		self:diffuseleftedge(color("#0d1019D8"))
		self:diffuserightedge(color("#05070c55"))
	end
}

-- slowly turning magic circles behind the menu (art from the LR2 skin)
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_circle"),
	InitCommand = function(self)
		self:xy(600, SCREEN_CENTER_Y):zoom(1.05):diffusealpha(0.30):blend("BlendMode_Add")
		self:spin():effectmagnitude(0, 0, 3)
	end
}
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_circle"),
	InitCommand = function(self)
		self:xy(600, SCREEN_CENTER_Y):zoom(0.6):diffusealpha(0.22):blend("BlendMode_Add")
		self:spin():effectmagnitude(0, 0, -5)
	end
}

-- twinkling sparkles
do
	local sparks = {
		{330, 70, 0.9, 0.0}, {760, 110, 0.7, 1.2}, {470, 400, 0.8, 2.1}, {690, 330, 1.0, 0.6},
		{820, 420, 0.6, 1.7}, {400, 170, 0.7, 2.6}, {620, 60, 0.6, 0.9}, {300, 330, 0.6, 1.4}, {560, 250, 0.5, 3.0}
	}
	for _, sp in ipairs(sparks) do
		t[#t + 1] = Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_sparkle"),
			InitCommand = function(self)
				self:xy(sp[1], sp[2]):zoom(sp[3] * 0.55):blend("BlendMode_Add")
				self:diffuseshift():effectcolor1(color("1,1,1,0")):effectcolor2(color("1,1,1,0.95"))
				self:effectperiod(2.6 + (sp[4] % 1.5)):effectoffset(sp[4])
			end
		}
	end
end

--Glow spilling from the divider into the right panel
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(270, 0):halign(0):valign(0):zoomto(160, 900):diffuse(getTitleColor('Line_Right'))
		self:diffuseleftedge(color("#68686855")):diffuserightedge(color("#68686800"))
	end
}

--Light purple line (fades from bright at the top to deep at the bottom)
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(250, 0):halign(0):valign(0):zoomto(10, 900):diffuse(getTitleColor('Line_Left')):diffusealpha(1)
		self:diffusetopedge(getTitleColor('Line_Left')):diffusebottomedge(getTitleColor('Line_Right'))
	end
}

--Dark purple line
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(260, 0):halign(0):valign(0):zoomto(10, 900):diffuse(getTitleColor('Line_Right')):diffusealpha(1)
		self:diffusetopedge(getTitleColor('Line_Right')):diffusebottomedge(color("#272727"))
	end
}

--Thin divider under the logo block (fades out to the right)
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(50, frameY - 18):halign(0):zoomto(150, 1):diffuse(getTitleColor('Line_Left'))
		self:diffuseleftedge(color("#e2e2e2FF")):diffuserightedge(color("#e2e2e200"))
	end
}

-- ornaments around the logo block
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_filigree"),
	InitCommand = function(self)
		self:xy(125, frameY - 135):zoomto(232, 36):diffusealpha(0.55)
	end
}
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_filigree"),
	InitCommand = function(self)
		self:xy(125, frameY + 6):zoomto(232, 36):rotationx(180):diffusealpha(0.45)
	end
}
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(125, frameY - 18):rotationz(45):zoomto(6, 6):diffuse(color("#ffffff"))
	end
}

local playingMusic = {}
local playingMusicCounter = 1
--Title text
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	InitCommand=function(self)
		self:xy(125,frameY-84):zoom(0.85):maxwidth(226 / 0.85):align(0.5,1)
		self:diffusetopedge(Saturation(getMainColor("highlight"), 0.5))
		self:diffusebottomedge(Saturation(getMainColor("positive"), 0.8))
		self:diffusealpha(0)
	end,
	OnCommand=function(self)
		self:settext("Etterna")
		self:queuecommand("lazy")
	end,
	lazyCommand = function(self)
		if SOUND:GetMusicPath() ~= "" then
			self:playcommand("PlayingMusic", {file = SOUND:GetMusicPath()})
		end
	end,
	MouseOverCommand = function(self)
		self:diffusealpha(0.6)
	end,
	MouseOutCommand = function(self)
		self:diffusealpha(1)
	end,
	PlayingMusicMessageCommand = function(self, params)
		if params.file ~= "" and params.file:find("_missing") == nil then
			self:effectclock("beat")
			self:heartbeat()
			if playingMusicCounter == 1 then
				self:diffusealpha(0):smooth(2):diffusealpha(1)
			end
		else
			self:diffusealpha(1)
		end
	end,
	StoppedMusicMessageCommand = function(self)
		self:stopeffect()
	end,
	MouseDownCommand = function(self, params)
		if params.event == "DeviceButton_left mouse button" then
			local function startSong()
				local sngs = SONGMAN:GetAllSongs()
				if #sngs == 0 then ms.ok("No songs to play") return end

				local s = sngs[math.random(#sngs)]
				local p = s:GetMusicPath()
				local l = s:MusicLengthSeconds()
				local top = SCREENMAN:GetTopScreen()

				local thisSong = playingMusicCounter
				playingMusic[thisSong] = true

				SOUND:StopMusic()
				SOUND:PlayMusicPart(p, 0, l)
	
				ms.ok("NOW PLAYING: "..s:GetMainTitle() .. " | LENGTH: "..SecondsToMMSS(l))
	
				top:setTimeout(
					function()
						if not playingMusic[thisSong] then return end
						playingMusicCounter = playingMusicCounter + 1
						startSong()
					end,
					l
				)
	
			end
	
			SCREENMAN:GetTopScreen():setTimeout(function()
					playingMusic[playingMusicCounter] = false
					playingMusicCounter = playingMusicCounter + 1
					startSong()
				end,
			0.1)
		else
			SOUND:StopMusic()
			playingMusic = {}
			playingMusicCounter = playingMusicCounter + 1
			ms.ok("Stopped music")
		end
	end,
}

--Theme text
t[#t + 1] = LoadFont("Common Large") .. {
	InitCommand=function(self)
		self:xy(125,frameY-52):zoom(0.42):align(0.5,1)
		self:diffusetopedge(Saturation(getMainColor("highlight"), 0.5))
		self:diffusebottomedge(Saturation(getMainColor("positive"), 0.8))
	end,
	OnCommand=function(self)
		self:settext(getThemeName())
	end
}

--Version number
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	Name = "Version",
	InitCommand=function(self)
		self:xy(125,frameY-35):zoom(0.25):align(0.5,1)
		self:diffusetopedge(Saturation(getMainColor("highlight"), 0.5))
		self:diffusebottomedge(Saturation(getMainColor("positive"), 0.8))
	end,
	BeginCommand = function(self)
		self:settext(GAMESTATE:GetEtternaVersion())
	end,
	MouseDownCommand = function(self, params)
		if params.event == "DeviceButton_left mouse button" then
			DLMAN:ShowProjectReleases()
		end
	end
}

--game update button
local gameneedsupdating = false
local buttons = {x = 20, y = 20, width = 142, height = 42, fontScale = 0.35, color = getMainColor("frames")}
t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(buttons.x,buttons.y)
	end,
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:zoomto(buttons.width, buttons.height):halign(0):valign(0):diffuse(buttons.color):diffusealpha(0)
			self:playcommand("LastVersionUpdated")
		end,
		LastVersionUpdatedMessageCommand = function(self)
			local latest = tonumber((DLMAN:GetLastVersion():gsub("[.]", "", 1)))
			local current = tonumber((GAMESTATE:GetEtternaVersion():gsub("[.]", "", 1)))
			if latest and latest > current then
				gameneedsupdating = true
			end
			self:playcommand("On")
		end,
		OnCommand = function(self)
			if gameneedsupdating then
				self:diffusealpha(0.3)
			end
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and gameneedsupdating then
				DLMAN:ShowProjectReleases()
			end
		end
	},
	LoadFont("Common Large") .. {
		OnCommand = function(self)
			self:xy(1.7, 1):align(0,0):zoom(buttons.fontScale):diffuse(getMainColor("positive"))
			if gameneedsupdating then
				self:settext(THEME:GetString("ScreenTitleMenu", "UpdateAvailable"))
			else
				self:settext("")
			end
		end
	}
}

local function mysplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	i = 1
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

local transformF = THEME:GetMetric("ScreenTitleMenu", "ScrollerTransform")
local scrollerX = THEME:GetMetric("ScreenTitleMenu", "ScrollerX")
local scrollerY = THEME:GetMetric("ScreenTitleMenu", "ScrollerY")
local scrollerChoices = THEME:GetMetric("ScreenTitleMenu", "ChoiceNames")
local _, count = string.gsub(scrollerChoices, "%,", "")
local choices = mysplit(scrollerChoices, ",")
local choiceCount = count + 1
local i
for i = 1, choiceCount do
	t[#t + 1] = UIElements.QuadButton(1, 1) .. {
		OnCommand = function(self)
			self:xy(scrollerX, scrollerY):zoomto(260, 16)
			transformF(self, 0, i, choiceCount)
			self:addx(SCREEN_CENTER_X - 20)
			self:addy(SCREEN_CENTER_Y - 20)
			self:diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				SCREENMAN:GetTopScreen():playcommand("MadeChoicePlayer_1")
				SCREENMAN:GetTopScreen():playcommand("Choose")
				if choices[i] == "Multi" or choices[i] == "GameStart" then
					GAMESTATE:JoinPlayer()
				end
				GAMESTATE:ApplyGameCommand(THEME:GetMetric("ScreenTitleMenu", "Choice" .. choices[i]))
			end
		end
	}
end

return t
