local t = Def.ActorFrame {}
t[#t + 1] = LoadActor("../_frame")
t[#t + 1] = LoadActor("../_PlayerInfo")

translated_info = {
	Title = THEME:GetString("ScreenEvaluation", "Title"),
	Replay = THEME:GetString("ScreenEvaluation", "ReplayTitle")
}

--what the settext says
t[#t + 1] = LoadFont("Common Large") .. {
	InitCommand = function(self)
		self:xy(42, 37):halign(0):valign(1):zoom(0.55):diffuse(getMainColor("positive"))
		self:settext("")
	end,
	OnCommand = function(self)
		local title = translated_info["Title"]
		local ss = SCREENMAN:GetTopScreen():GetStageStats()
		if not ss:GetLivePlay() then title = translated_info["Replay"] end
		local gamename = GAMESTATE:GetCurrentGame():GetName():lower()
		if gamename ~= "dance" then
			title = gamename:gsub("^%l", string.upper) .. " " .. title
		end
		self:settextf("%s:", title)
	end,
}

--Group folder name
local frameWidth = 280
local frameHeight = 20
local frameX = SCREEN_WIDTH - 40
local frameY = 15

t[#t + 1] = LoadFont("Seraphic Title") .. {
	InitCommand = function(self)
		self:xy(frameX, frameY + 10):halign(1):zoom(0.55):maxwidth((frameWidth - 40) / 0.35)
	end,
	BeginCommand = function(self)
		self:queuecommand("Set"):diffuse(getMainColor("positive"))
	end,
	SetCommand = function(self)
		local song = GAMESTATE:GetCurrentSong()
		if song ~= nil then
			self:settext(song:GetGroupName())
		end
	end
}

-- Seraphic: STAGE CLEARED / STAGE FAILED emblem
do
	local failed = false
	pcall(function()
		local sc = SCOREMAN:GetMostRecentScore() or SCOREMAN:GetTempReplayScore()
		if sc and sc:GetWifeGrade() == "Grade_Failed" then
			failed = true
		end
	end)
	local emblem = THEME:GetPathG("", failed and "seraphic_failed" or "seraphic_cleared")
	-- soft additive glow behind the emblem
	t[#t + 1] = LoadActor(emblem) .. {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X, 316):zoom(0.76):diffusealpha(0):blend("BlendMode_Add")
		end,
		OnCommand = function(self)
			self:sleep(0.3):smooth(1.0):diffusealpha(0.22)
			self:queuecommand("Pulse")
		end,
		PulseCommand = function(self)
			self:smooth(2.2):diffusealpha(0.10):smooth(2.2):diffusealpha(0.24):queuecommand("Pulse")
		end
	}
	t[#t + 1] = LoadActor(emblem) .. {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X, 316):zoom(0.68):diffusealpha(0)
		end,
		OnCommand = function(self)
			self:sleep(0.3):smooth(0.8):diffusealpha(0.95)
		end
	}
end

t[#t + 1] = LoadActor("../_cursor")

return t
