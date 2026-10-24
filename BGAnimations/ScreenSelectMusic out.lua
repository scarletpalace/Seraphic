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

-- Seraphic: decide screen. After the fade to black the song banner opens up in the middle with the
-- title, subtitle and artist under it over the song's background, holds, then folds shut into a line.
-- The screen waits for this transition to finish, so it is also the window for entering player options.
-- (built when the screen loads, before a song is picked, so the song itself is checked when it plays)
local showDecide = themeConfig:get_data().global.ShowDecideScreen ~= false
local decideIn = 0.2 -- black fade is done
local decideHold = 1.0 -- seconds the decide screen stays fully open
local decideFold = 0.2

if showDecide then
	local bannerW, bannerH = 384, 120 -- 3.2:1, same as the music select banner
	local bannerY = SCREEN_CENTER_Y - 50
	local textY = bannerY + bannerH / 2 + 26
	local poolW = 460
	local foldAt = decideIn + 0.3 + decideHold

	t[#t + 1] = Def.ActorFrame {
		Name = "Decide",
		OnCommand = function(self)
			self:visible(GAMESTATE:GetCurrentSong() ~= nil)
			if not GAMESTATE:GetCurrentSong() then return end
			SeraphicDecideShown = true -- the gameplay title splash skips itself after this
			self:playcommand("Set")
			self:diffusealpha(0):sleep(decideIn):linear(0.25):diffusealpha(1)
		end,
		-- the song's own background (the LR2 decide backdrop when it has none), dimmed, drifting slowly inwards
		Def.ActorFrame {
			InitCommand = function(self)
				self:Center()
			end,
			SetCommand = function(self)
				self:zoom(1.08):linear(foldAt + decideFold):zoom(1)
			end,
			Def.Sprite {
				Name = "Backdrop",
				SetCommand = function(self)
					local bgpath = GAMESTATE:GetCurrentSong():GetBackgroundPath()
					if not bgpath or bgpath == "" then
						bgpath = THEME:GetPathG("", "seraphic_decide_bg")
					end
					self:LoadBackground(bgpath)
					self:scaletocover(-SCREEN_WIDTH / 2, -SCREEN_HEIGHT / 2, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
					self:diffuse(color("0.5,0.5,0.5,1"))
				end
			}
		},
		-- dark pool so the text stays readable over the backdrop
		Def.Quad {
			InitCommand = function(self)
				self:xy(SCREEN_CENTER_X, bannerY + 12):zoomto(SCREEN_WIDTH, bannerH + 170)
				self:diffuse(color("#000000")):diffusealpha(0.55):fadetop(0.25):fadebottom(0.25)
			end
		},
		-- everything that folds shut at the end lives in here
		Def.ActorFrame {
			Name = "Window",
			OnCommand = function(self)
				self:zoomy(0):sleep(decideIn):decelerate(0.3):zoomy(1)
				self:sleep(decideHold):accelerate(decideFold):zoomy(0)
			end,
			InitCommand = function(self)
				-- fold around the banner's centre line, like the LR2 skin
				self:y(bannerY)
			end,
			Def.Sprite {
				Name = "Banner",
				InitCommand = function(self)
					self:visible(BannersEnabled())
				end,
				SetCommand = function(self)
					if not BannersEnabled() then return end
					local bnpath = GAMESTATE:GetCurrentSong():GetBannerPath()
					if not bnpath or bnpath == "" then
						bnpath = THEME:GetPathG("Common", "fallback banner")
					end
					self:LoadBackground(bnpath)
					self:x(SCREEN_CENTER_X):scaletoclipped(bannerW, bannerH)
					if self:GetNumStates() > 1 then
						self:StopUsingCustomTexCoords()
					else
						self:EnableCustomTexCoords()
					end
				end
			},
			-- thin silver outline around the banner
			Def.ActorFrame {
				InitCommand = function(self)
					self:xy(SCREEN_CENTER_X - bannerW / 2, -bannerH / 2):visible(BannersEnabled())
				end,
				seraphicSoftEdge(-1, -1, bannerW + 2, bannerH + 2, 0.45)
			},
			-- crimson rules fading out from the middle, above and below the text block
			Def.Quad {
				InitCommand = function(self)
					self:xy(SCREEN_CENTER_X - poolW / 2, textY - bannerY - 16):halign(0):zoomto(poolW / 2, 1)
					self:diffuseleftedge(color("#9c142800")):diffuserightedge(color("#9c1428E6"))
				end
			},
			Def.Quad {
				InitCommand = function(self)
					self:xy(SCREEN_CENTER_X, textY - bannerY - 16):halign(0):zoomto(poolW / 2, 1)
					self:diffuseleftedge(color("#9c1428E6")):diffuserightedge(color("#9c142800"))
				end
			},
			-- title, then the subtitle on its own row, then the artist
			LoadFont("Common Normal") .. {
				Name = "Title",
				InitCommand = function(self)
					self:xy(SCREEN_CENTER_X, textY - bannerY):zoom(0.8):maxwidth(poolW / 0.8):diffuse(color(seraphicValueColor))
				end,
				SetCommand = function(self)
					self:settext(GAMESTATE:GetCurrentSong():GetDisplayMainTitle())
				end
			},
			LoadFont("Common Normal") .. {
				Name = "Subtitle",
				InitCommand = function(self)
					self:xy(SCREEN_CENTER_X, textY - bannerY + 22):zoom(0.45):maxwidth(poolW / 0.45):diffuse(color(seraphicValueColor)):diffusealpha(0.78)
				end,
				SetCommand = function(self)
					self:settext(GAMESTATE:GetCurrentSong():GetDisplaySubTitle())
				end
			},
			LoadFont("Seraphic Artist") .. {
				Name = "Artist",
				InitCommand = function(self)
					self:x(SCREEN_CENTER_X):zoom(0.5):maxwidth(poolW / 0.5):diffuse(color(seraphicLabelColor))
				end,
				SetCommand = function(self)
					local song = GAMESTATE:GetCurrentSong()
					local hasSub = song:GetDisplaySubTitle() ~= ""
					self:y(textY - bannerY + (hasSub and 42 or 24))
					self:settext(song:GetDisplayArtist())
				end
			}
		},
		-- crimson line that is left over when the window folds shut, then fades
		Def.Quad {
			InitCommand = function(self)
				self:xy(SCREEN_CENTER_X, bannerY):zoomto(0, 1):diffuse(color("#9c1428"))
			end,
			OnCommand = function(self)
				self:sleep(foldAt):decelerate(decideFold):zoomto(SCREEN_WIDTH, 1)
			end
		}
	}

	-- folds shut into a black screen before gameplay fades in
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(color("0,0,0,0"))
		end,
		OnCommand = function(self)
			if not GAMESTATE:GetCurrentSong() then return end
			self:sleep(foldAt + decideFold):linear(0.1):diffusealpha(1)
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
