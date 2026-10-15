if SeraphicStamp then SeraphicStamp("underlay (_songbg) start") end
local enabled = PREFSMAN:GetPreference("ShowBackgrounds")
local brightness = 0.3

local t = Def.ActorFrame {}

-- bg
if enabled then
	t[#t + 1] = Def.Sprite {
		Name = "BGSprite",
		InitCommand = function(self)
			self:diffusealpha(0)
		end,
		CurrentSongChangedMessageCommand = function(self)
			self:stoptweening():smooth(0.5):diffusealpha(0)
			self:sleep(0.2):queuecommand("ModifySongBackground")
		end,
		ModifySongBackgroundCommand = function(self)
			if GAMESTATE:GetCurrentSong() and GAMESTATE:GetCurrentSong():GetBackgroundPath() then
				self:finishtweening()
				self:visible(true)
				self:LoadBackground(GAMESTATE:GetCurrentSong():GetBackgroundPath())
				self:scaletocover(0, 0, SCREEN_WIDTH, SCREEN_BOTTOM)
				self:sleep(0.05)
				self:smooth(0.4):diffusealpha(brightness)
			else
				self:visible(false)
			end
		end,
		OffCommand = function(self)
			self:smooth(0.6):diffusealpha(0)
		end,
	}
end

-- slowly rotating magic circle behind the left side (from the LR2 skin)
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_circle"),
	InitCommand = function(self)
		self:xy((SCREEN_WIDTH - capWideScale(get43size(350), 350)) / 2, SCREEN_CENTER_Y - 8)
		self:zoom(0.9):diffusealpha(0.42):blend("BlendMode_Add")
		self:spin():effectmagnitude(0, 0, 14)
	end
}

--vertical bar left of songwheel
--[[t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(SCREEN_WIDTH - capWideScale(get43size(350), 350), 0):halign(0):valign(0):zoomto(3, SCREEN_HEIGHT)
		self:diffuse(getMainColor("highlight"))
		self:diffusetopedge(getMainColor("positive")):diffusebottomedge(getMainColor("highlight"))
		self:diffusealpha(0.85)
	end
}]]

t[#t+1] = UIElements.QuadButton(-1000, 1) .. {-- a fullscreen button for right click pausing so your right clicks dont pause accidentally
	InitCommand = function(self)
		self:valign(0):halign(0)
		self:zoomto(SCREEN_WIDTH, SCREEN_HEIGHT)
		self:diffusealpha(0)
	end,
	MouseDownCommand = function(self, params)
		if params.event == "DeviceButton_right mouse button" then
			SCREENMAN:GetTopScreen():PauseSampleMusic()
			MESSAGEMAN:Broadcast("MusicPauseToggled")
		end
	end
}

if SeraphicStamp then SeraphicStamp("underlay read") end
return t
