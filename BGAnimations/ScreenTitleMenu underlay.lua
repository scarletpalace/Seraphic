if IsSMOnlineLoggedIn() then
	CloseConnection()
end

local t = Def.ActorFrame {}


-- Seraphic: a candle-lit sanctuary. Everything sits on the centre line: the shared rose-window
-- backdrop, the title under the chain garland, and the menu inside the window.
local cx = SCREEN_CENTER_X
t[#t + 1] = LoadActor("_sanctuary")

-- filigree above and below the title block, with a diamond on the centre line
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_filigree"),
	InitCommand = function(self)
		self:xy(cx, 52):zoomto(330, 52):diffusealpha(0.7)
	end
}
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_filigree"),
	InitCommand = function(self)
		self:xy(cx, 176):zoomto(250, 40):rotationx(180):diffusealpha(0.55)
	end
}
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_crystal"),
	InitCommand = function(self)
		self:xy(cx, 141):zoom(0.3)
		self:glowshift():effectcolor1(color("1,1,1,0")):effectcolor2(color("1,0.85,0.85,0.5")):effectperiod(2.4)
	end
}
for _, dir in ipairs({-1, 1}) do
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(cx + dir * 12, 141):halign(dir == 1 and 0 or 1):zoomto(110, 1):diffuse(color("#e2e2e2")):diffusealpha(0.7)
			if dir == 1 then self:faderight(1) else self:fadeleft(1) end
		end
	}
end

-- motto along the foot of the window
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(cx, SCREEN_HEIGHT - 22):zoom(0.36):settext("in tenebris lux")
		self:diffuse(color("#c9b8bc")):diffusealpha(0.45)
	end
}

local playingMusic = {}
local playingMusicCounter = 1
--Title text
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	InitCommand=function(self)
		self:xy(cx, 112):zoom(0.95):maxwidth(320 / 0.95):align(0.5,1)
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
		self:xy(cx, 129):zoom(0.36):align(0.5,1):diffusealpha(0.9)
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
		self:xy(cx, 158):zoom(0.22):align(0.5,1)
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
			self:x(scrollerX):zoomto(240, 20)
			transformF(self, 0, i - 1, choiceCount)
			self:addy(scrollerY)
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
