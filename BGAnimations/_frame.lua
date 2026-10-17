local t = Def.ActorFrame {}
local onSelect = (Var("LoadingScreen") or "") == "ScreenSelectMusic" or (Var("LoadingScreen") or "") == "ScreenNetSelectMusic"
local topFrameHeight = onSelect and 90 or 40
local bottomFrameHeight = onSelect and 90 or 72
-- select screen: the top bar is as tall as the bottom bar. Its right part (clock + pack, x >= stripX) is drawn here,
-- above the wheel; the left part (x < stripX) is drawn in _topbar.lua underneath the info panels, so panels and
-- banner simply overlap it instead of being hidden by it.
local stripX, stripH = 488, 90
local borderWidth = 4

-- brighten/darken a color table {r,g,b,a} without touching alpha
local function scaleColor(c, m)
	return {math.min(c[1] * m, 1), math.min(c[2] * m, 1), math.min(c[3] * m, 1), c[4]}
end

--Frames
if not onSelect then
t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(0, 0):halign(0):valign(0):zoomto(SCREEN_WIDTH, topFrameHeight):diffuse(getMainColor("frames"))
		self:diffusetopedge(scaleColor(getMainColor("frames"), 1.5))
	end
}
end

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(0, SCREEN_HEIGHT):halign(0):valign(1):zoomto(SCREEN_WIDTH, bottomFrameHeight):diffuse(getMainColor("frames"))
		self:diffusebottomedge(scaleColor(getMainColor("frames"), 1.5))
	end
}

--soft shadow cast below the top bar
if not onSelect then
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, topFrameHeight):halign(0):valign(0):zoomto(SCREEN_WIDTH, 10):diffuse(color("#000000"))
		self:diffusetopedge(color("#00000088")):diffusebottomedge(color("#00000000"))
	end
}
end

--soft shadow under the top-right strip (select screen)
if onSelect then
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(stripX, stripH):halign(0):valign(0):zoomto(SCREEN_WIDTH - stripX, 10):diffuse(color("#000000"))
			self:diffusetopedge(color("#00000088")):diffusebottomedge(color("#00000000"))
		end
	}
end

--soft shadow cast above the bottom bar
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, SCREEN_HEIGHT - bottomFrameHeight):halign(0):valign(1):zoomto(SCREEN_WIDTH, 10):diffuse(color("#000000"))
		self:diffusetopedge(color("#00000000")):diffusebottomedge(color("#00000088"))
	end
}

-- Seraphic: filigree ornament tiled along the bars (alternate tiles are mirrored so it stays seamless)
local function filigree(y, h, valign)
	local tileW = h * 642 / 102
	local a = Def.ActorFrame {}
	local n = math.ceil(SCREEN_WIDTH / tileW) + 1
	for i = 0, n - 1 do
		a[#a + 1] = Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_filigree"),
			InitCommand = function(self)
				local flip = (i % 2 == 0) and 1 or -1
				self:xy(i * tileW + (flip == -1 and tileW or 0), y):halign(0):valign(valign)
				self:zoomto(tileW * flip, h):diffusealpha(0.5)
			end
		}
	end
	return a
end
-- Seraphic: hanging cross / bead-chain texture (from the LR2 select skin) behind the top bar on the select screen
local function chains(h, x0)
	x0 = x0 or 0
	local tileW = h * 640 / 96
	local a = Def.ActorFrame {}
	local n = math.ceil((SCREEN_WIDTH - x0) / tileW) + 1
	for i = 0, n - 1 do
		a[#a + 1] = Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_chain"),
			InitCommand = function(self)
				local flip = (i % 2 == 0) and 1 or -1
				self:xy(x0 + i * tileW + (flip == -1 and tileW or 0), 0):halign(0):valign(0)
				self:zoomto(tileW * flip, h):diffusealpha(0.9)
			end
		}
	end
	return a
end
if onSelect then
	-- right part of the one wide top bar (the left part is drawn in _topbar.lua with the very same base and
	-- chain-tile pattern, so the two halves look like a single bar)
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(stripX, 0):halign(0):valign(0):zoomto(SCREEN_WIDTH - stripX, stripH):diffuse(getMainColor("frames"))
			self:diffusetopedge(scaleColor(getMainColor("frames"), 1.5))
		end
	}
	local tileW = stripH * 640 / 96
	for i = 0, math.ceil(SCREEN_WIDTH / tileW) do
		if (i + 1) * tileW > stripX then
			t[#t + 1] = Def.Sprite {
				Texture = THEME:GetPathG("", "seraphic_chain"),
				InitCommand = function(self)
					local flip = (i % 2 == 0) and 1 or -1
					self:xy(i * tileW + (flip == -1 and tileW or 0), 0):halign(0):valign(0)
					self:zoomto(tileW * flip, stripH):diffusealpha(0.9)
					if i * tileW < stripX then self:cropleft((stripX - i * tileW) / tileW) end
				end
			}
		end
	end
	t[#t + 1] = Def.Quad { -- bottom edge line (same colour as the left half)
		InitCommand = function(self)
			self:xy(stripX, stripH):halign(0):valign(1):zoomto(SCREEN_WIDTH - stripX, 2):diffuse(getMainColor("positive")):diffusealpha(0.9)
		end
	}
else
	t[#t + 1] = filigree(0, topFrameHeight, 0)
end
t[#t + 1] = filigree(SCREEN_HEIGHT, bottomFrameHeight, 1)

--FrameBorders: thin accent line that fades out toward the right edge
if not onSelect then
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, topFrameHeight):halign(0):valign(1):zoomto(SCREEN_WIDTH, 2):diffuse(getMainColor("positive"))
		self:diffuseleftedge(getMainColor("positive")):diffuserightedge(scaleColor(getMainColor("highlight"), 0.4))
		self:diffusealpha(0.9)
	end
}
end

t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, SCREEN_HEIGHT - bottomFrameHeight):halign(0):valign(0):zoomto(SCREEN_WIDTH, 2):diffuse(getMainColor("positive"))
		self:diffuseleftedge(scaleColor(getMainColor("highlight"), 0.4)):diffuserightedge(getMainColor("positive"))
		self:diffusealpha(0.9)
	end
}

--[[
if themeConfig:get_data().global.TipType == 2 or themeConfig:get_data().global.TipType == 3 then
	t[#t + 1] =
		LoadFont("Common Normal") ..
		{
			InitCommand = function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM - 7):zoom(0.35):settext(
					getRandomQuotes(themeConfig:get_data().global.TipType)
				):diffuse(getMainColor("highlight")):diffusealpha(0):zoomy(0):maxwidth((SCREEN_WIDTH - 350) / 0.35)
			end,
			BeginCommand = function(self)
				self:sleep(2)
				self:smooth(1)
				self:diffusealpha(1)
				self:zoomy(0.35)
			end
		}
end
]]

-- Seraphic: scroll rail of the music wheel (select screen): crystal ends + tube, like the LR2 skin.
-- Purely decorative; the engine's own scroll thumb (metrics.ini, ScrollBarOnCommand) travels inside it.
if onSelect then
	local rx = SCREEN_WIDTH - 18
	t[#t + 1] = Def.Quad { -- dark fill inside the tube, like the LR2 rail
		InitCommand = function(self)
			self:xy(rx, 134):halign(0.5):valign(0):zoomto(7, 212)
			self:diffusetopedge(color("#14161e")):diffusebottomedge(color("#000000")):diffusealpha(0.95)
		end
	}
	t[#t + 1] = Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_scroll_tube"),
		InitCommand = function(self) self:xy(rx - 1, 132):halign(0.5):valign(0):zoomto(12, 216):diffusealpha(0.9) end
	}
	t[#t + 1] = Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_scroll_wing_top"),
		InitCommand = function(self) self:xy(rx, 92):halign(0.5):valign(0) end
	}
	t[#t + 1] = Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_scroll_wing_bot"),
		InitCommand = function(self) self:xy(rx, 388):halign(0.5):valign(1) end
	}
	t[#t + 1] = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rx + 0.7, 140)
			self:SetUpdateFunction(function(f)
				local top = SCREENMAN:GetTopScreen()
				if not top or (top:GetName() ~= "ScreenSelectMusic" and top:GetName() ~= "ScreenNetSelectMusic") then return end
				-- Playlists tab: follow the playlist wheel that stands in for the song wheel
				if SeraphicPlaylistWheel and SeraphicPlaylistWheel.active then
					f:y(140 + 200 * SeraphicPlaylistWheel.fraction)
					return
				end
				local w = top:GetMusicWheel()
				if not w then return end
				local n = w:GetNumItems()
				if n and n > 1 then
					f:y(140 + 200 * math.min(math.max(w:GetCurrentIndex() / (n - 1), 0), 1))
				end
			end)
		end,
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_crystal"),
			InitCommand = function(self)
				self:zoomto(19, 20)
				self:diffuseshift():effectcolor1(color("#e0283c")):effectcolor2(color("#ffd3d8")):effectperiod(1.3)
			end
		}
	}
end

t[#t + 1] = LoadActor("_corners")

return t
