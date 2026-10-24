local t = Def.ActorFrame {}

local translated_info = {
	PressStart = THEME:GetString("ScreenSelectMusic","PressStartForOptions"),
	EnteringOptions = THEME:GetString("ScreenSelectMusic","EnteringOptions"),
}

--black fade
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT)
	end,
	OnCommand = function(self)
		self:diffuse(color("0,0,0,0")):sleep(0.1):linear(0.1):diffusealpha(1)
	end
}

-- Seraphic: decide screen, after the LR2 Seraphic decide skin. Behind the filigree frame the song's
-- background shrinks from 3x down to the screen while the title settles between two lines, with the
-- genre above it and the subtitle and artist under it; then the background collapses into a streak
-- across the title and the screen fades to black.
-- The screen waits for this transition to finish, so it is also the window for entering player options.
-- (built when the screen loads, before a song is picked, so the song itself is read on StartTransitioning)
local showDecide = themeConfig:get_data().global.ShowDecideScreen ~= false
local decideIn = 0.2 -- black fade is done
-- the LR2 skin's timings, sped up; 1 = as in the skin (about 3s), 0.5 = twice as fast
local decideSpeed = 0.5
local function dt(seconds)
	return seconds * decideSpeed
end
local decideScene = dt(2.3) -- background zooming in
local decideFold = dt(0.2) -- background collapsing into a line
local decideOut = dt(0.35) -- fade to black

if showDecide then
	local add = "BlendMode_Add"
	local cyan = color("#80ffff")
	local lineTop, lineBottom = 154, 327 -- the LR2 skin's 640x480 layout, same height as ours
	local titleY = 232

	-- copy of the title or its glow, LR2 style; build(self) sets the start state, tween(self) animates it
	local function titleText(build, tween)
		return LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(SCREEN_CENTER_X, titleY):maxwidth(600 / 1.3):diffuse(color(seraphicValueColor))
				build(self)
			end,
			OnCommand = function(self)
				self:sleep(decideIn)
				tween(self)
			end,
			SetCommand = function(self)
				self:settext(GAMESTATE:GetCurrentSong():GetDisplayMainTitle())
			end
		}
	end

	local function infoText(y, z, c, get)
		return LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(SCREEN_CENTER_X, y):zoom(z):maxwidth(400 / z):diffuse(c):diffusealpha(0)
			end,
			OnCommand = function(self)
				self:sleep(decideIn):linear(dt(0.2)):diffusealpha(1)
			end,
			SetCommand = function(self)
				self:settext(get(GAMESTATE:GetCurrentSong()))
			end
		}
	end

	local function line(y)
		return Def.Quad {
			InitCommand = function(self)
				self:xy(SCREEN_CENTER_X, y):zoomto(0, 2):diffuse(color("#a0a0a0")):diffusealpha(0.63):blend(add)
			end,
			OnCommand = function(self)
				self:sleep(decideIn):decelerate(dt(0.4)):zoomto(SCREEN_WIDTH, 2)
			end
		}
	end

	t[#t + 1] = Def.ActorFrame {
		Name = "Decide",
		-- On runs when the screen loads (the tweens wait until the transition starts), so the song is
		-- only known here, once it has been picked
		StartTransitioningCommand = function(self)
			local song = GAMESTATE:GetCurrentSong()
			self:visible(song ~= nil)
			if not song then return end
			SeraphicDecideShown = true -- the gameplay title splash skips itself after this
			self:playcommand("Set")
		end,
		-- dark fractal underneath, what is left once the song background has collapsed
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_decide_bg"),
			InitCommand = function(self)
				self:Center()
				local z = math.max(SCREEN_WIDTH / 640, SCREEN_HEIGHT / 480)
				self:zoomto(640 * z, 480 * z):diffusealpha(0)
			end,
			OnCommand = function(self)
				self:sleep(decideIn):linear(dt(0.15)):diffusealpha(0.5)
			end
		},
		-- the song background, drawn twice (plain + added on top) for the washed out LR2 look
		Def.ActorFrame {
			Name = "Stage",
			InitCommand = function(self)
				self:Center():zoom(3)
			end,
			OnCommand = function(self)
				self:sleep(decideIn):decelerate(decideScene):zoom(1)
				self:accelerate(decideFold):zoomx(15):zoomy(0)
			end,
			SetCommand = function(self)
				local bgpath = GAMESTATE:GetCurrentSong():GetBackgroundPath()
				local has = bgpath ~= nil and bgpath ~= ""
				self:visible(has)
				if not has then return end
				for _, name in ipairs({"Plain", "Glow"}) do
					local spr = self:GetChild(name)
					spr:LoadBackground(bgpath)
					spr:scaletocover(-SCREEN_WIDTH / 2, -SCREEN_HEIGHT / 2, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
				end
			end,
			Def.Sprite {Name = "Plain"},
			Def.Sprite {
				Name = "Glow",
				InitCommand = function(self)
					self:blend(add):diffusealpha(0.5)
				end
			}
		},
		-- filigree frame
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_decide_frame"),
			InitCommand = function(self)
				self:Center():zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):blend(add):diffusealpha(0)
			end,
			OnCommand = function(self)
				self:sleep(decideIn):linear(dt(0.15)):diffusealpha(0.75)
			end
		},
		line(lineTop),
		line(lineBottom),
		-- big glow of the title drifting in behind it
		titleText(function(self)
			self:zoom(7.8):diffusealpha(0.5):blend(add)
		end, function(self)
			self:decelerate(dt(1.2)):zoom(3.9):diffusealpha(0)
		end),
		-- the title, shrinking into place
		titleText(function(self)
			self:zoom(3.9):diffusealpha(0)
		end, function(self)
			self:linear(dt(0.3)):zoom(1.3):diffusealpha(1)
		end),
		-- quick flicker over the title as it lands
		titleText(function(self)
			self:zoom(1.3):diffusealpha(0):blend(add)
		end, function(self)
			self:sleep(dt(0.2))
			for _ = 1, 4 do
				self:diffusealpha(1):sleep(dt(0.02)):diffusealpha(0):sleep(dt(0.02))
			end
		end),
		infoText(195, 0.6, cyan, function(song) return song:GetGenre() end),
		infoText(263, 0.7, color(seraphicValueColor), function(song) return song:GetDisplaySubTitle() end),
		infoText(295, 0.6, cyan, function(song) return song:GetDisplayArtist() end)
	}

	-- fade to black before gameplay fades in
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(color("0,0,0,0"))
		end,
		OnCommand = function(self)
			self:sleep(decideIn + decideScene + decideFold):linear(decideOut):diffusealpha(1)
		end
	}
end

-- skip showing the prompt
if not themeConfig:get_data().global.ShowPlayerOptionsHint then return t end

-- with the decide screen up the prompt moves down so it does not cover the banner
local promptY = showDecide and SCREEN_HEIGHT - 56 or SCREEN_CENTER_Y


--enter options prompt
t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:diffusealpha(0):xy(SCREEN_CENTER_X, promptY)
	end,
	ShowPressStartForOptionsCommand=function(self)
		self:zoom(0.9):smooth(0.2):diffusealpha(1):zoom(1)
	end,
	ShowEnteringOptionsCommand=function(self)
		--go read the comment below
	end,
	HidePressStartForOptionsCommand=function(self)
		self:decelerate(0.15):diffusealpha(0)
	end,
	Def.Quad {
		InitCommand = function(self)
			self:zoomto(SCREEN_WIDTH,80)
			self:diffusetopedge(Brightness(getMainColor("tabs"), 0.45))
			self:diffusebottomedge(Brightness(getMainColor("tabs"), 0.15))
		end,
	},
	Def.Quad {
		InitCommand = function(self)
			self:zoomto(SCREEN_WIDTH-10,70)
			self:diffusetopedge(Saturation(getMainColor("highlight"), 0.5))
			self:diffusebottomedge(Saturation(getMainColor("positive"), 0.6))
		end,
	},
}
t[#t + 1] = LoadFont("Common Large") ..  {
	InitCommand=function(self)
		self:xy(SCREEN_CENTER_X, promptY):diffusebottomedge(0.7,0.7,0.7,1):shadowlength(1.5):align(0.5,0.5)
	end,
	ShowPressStartForOptionsCommand=function(self)
		self:settext(translated_info["PressStart"]):diffusealpha(0):zoom(0.15)
		self:decelerate(0.2):zoom(0.55):diffusealpha(1)
	end,
	ShowEnteringOptionsCommand=function(self)
		self:finishtweening():settext(translated_info["EnteringOptions"])
		--for some reason, any tweens triggered by this command will get frozen after the first frame
		--unless you enter twice fast, that is
		--why? :shrug: Figure that out before putting a tween back in here -ulti_fd

		--self:zoom(0.65):accelerate(0.2):zoom(0.55)
	end,
	HidePressStartForOptionsCommand=function(self)
		-- do we even need this? AllowOptionsMenu() always returns true
		-- we may as well hard code it in the c++ if we're gonna do that tbh
		self:decelerate(0.15):diffusealpha(0)
	end
}


return t
