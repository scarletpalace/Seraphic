local enabled = PREFSMAN:GetPreference("ShowBackgrounds")
local brightness = 0.28
local t = Def.ActorFrame {}

if enabled then
	t[#t + 1] = Def.Sprite {
		OnCommand = function(self)
			if GAMESTATE:GetCurrentSong() and GAMESTATE:GetCurrentSong():GetBackgroundPath() then
				self:finishtweening()
				self:visible(true)
				self:LoadBackground(GAMESTATE:GetCurrentSong():GetBackgroundPath())
				self:scaletocover(0, 0, SCREEN_WIDTH, SCREEN_BOTTOM)
				self:sleep(0.5)
				self:decelerate(2)
				self:diffusealpha(brightness)
			else
				self:visible(false)
			end
		end
	}
end

-- vignette: darker toward the screen edges
local function vig(x, halign, left)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, 0):halign(halign):valign(0):zoomto(160, SCREEN_HEIGHT):diffuse(color("#000000"))
			if left then
				self:diffuseleftedge(color("#000000C0")):diffuserightedge(color("#00000000"))
			else
				self:diffuseleftedge(color("#00000000")):diffuserightedge(color("#000000C0"))
			end
		end
	}
end
t[#t + 1] = vig(0, 0, true)
t[#t + 1] = vig(SCREEN_WIDTH, 1, false)

-- Seraphic: tall framed stage image in the centre (LR2 / beatoraja result style)
local cx, cy, cw, ch = SCREEN_CENTER_X, 46, 230, 318
t[#t + 1] = Def.Sprite {
	Name = "StageImage",
	OnCommand = function(self)
		self:xy(cx, cy):valign(0)
		local song = GAMESTATE:GetCurrentSong()
		local path = song and (song:GetBackgroundPath() or song:GetBannerPath())
		if not path then path = THEME:GetPathG("Common", "fallback banner") end
		self:LoadBackground(path)
		self:scaletoclipped(cw, ch)
		self:diffusealpha(0):sleep(0.2):smooth(0.6):diffusealpha(1)
	end
}
t[#t + 1] = seraphicPanel(cx - cw / 2, cy, cw, ch, "clean")
do
	local function gem(x, y, zx, zy)
		return Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_corner"),
			InitCommand = function(self)
				self:xy(x, y):halign(0):valign(0):zoomx(0.34 * zx):zoomy(0.34 * zy):diffuse(color("#ffffff")):diffusealpha(0.95)
			end
		}
	end
	t[#t + 1] = gem(cx - cw / 2 - 4, cy - 4, 1, 1)
	t[#t + 1] = gem(cx + cw / 2 + 4, cy - 4, -1, 1)
	t[#t + 1] = gem(cx - cw / 2 - 4, cy + ch + 4, 1, -1)
	t[#t + 1] = gem(cx + cw / 2 + 4, cy + ch + 4, -1, -1)
end

-- Seraphic: one window per column (drawn here so the banner stays on top of the body)
local function seraWindow(x, y, w, h)
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, h)
			self:diffuseupperleft(color("#262626E6")):diffuseupperright(color("#1a1a1aE6"))
			self:diffuselowerleft(color("#0a0a0aF0")):diffuselowerright(color("#060606F0"))
		end
	}
	t[#t + 1] = seraphicPanel(x, y, w, h, "clean")
end
seraWindow(10, 24, 262, 432)
seraWindow(582, 24, 262, 432)

-- small banner next to the song data block (right column):
-- shown whole (not cropped to the centre), anchored top-left, with the frame hugging the actual image
if BannersEnabled() then
	local bx, by, bw, bh = 590, 54, 246, 76.3
	t[#t + 1] = Def.Sprite {
		Name = "Banner",
		OnCommand = function(self)
			self:xy(bx, by):halign(0):valign(0)
			local song = GAMESTATE:GetCurrentSong()
			local bnpath = song and song:GetBannerPath()
			if not bnpath then bnpath = THEME:GetPathG("Common", "fallback banner") end
			self:LoadBackground(bnpath)
			local w, h = self:GetWidth(), self:GetHeight()
			local zw, zh = bw, bh
			if w > 0 and h > 0 then
				-- as wide as the box; if the banner is taller than the box show its top part (no centre crop)
				local fullh = h * (bw / w)
				self:zoomto(bw, fullh)
				if fullh > bh then
					self:cropbottom((fullh - bh) / fullh)
					zh = bh
				else
					zh = fullh
				end
			else
				self:zoomto(bw, bh)
			end
			MESSAGEMAN:Broadcast("SeraBannerSized", {w = zw, h = zh})
		end
	}
	local function edge(place)
		return Def.Quad {
			InitCommand = function(self)
				self:halign(0):valign(0):diffuse(color("#ffffff")):diffusealpha(0.35)
				place(self, bw, bh)
			end,
			SeraBannerSizedMessageCommand = function(self, params)
				place(self, params.w, params.h)
			end
		}
	end
	t[#t + 1] = edge(function(self, w, h) self:xy(bx, by):zoomto(w, 1) end)
	t[#t + 1] = edge(function(self, w, h) self:xy(bx, by + h - 1):zoomto(w, 1) end)
	t[#t + 1] = edge(function(self, w, h) self:xy(bx, by):zoomto(1, h) end)
	t[#t + 1] = edge(function(self, w, h) self:xy(bx + w - 1, by):zoomto(1, h) end)
end

return t
