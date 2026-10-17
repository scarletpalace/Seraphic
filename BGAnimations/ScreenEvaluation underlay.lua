local enabled = PREFSMAN:GetPreference("ShowBackgrounds")
local brightness = 0.36 -- the centre is open now (no stage image), so the background shows a little more
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

-- Seraphic: one window per column (drawn here so the banner stays on top of the body)
-- LR2 window: translucent dark body, faint filigree footer and a soft 1px edge (no silver frame / diamonds)
local function seraWindow(x, y, w, h)
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, h)
			self:diffuseupperleft(color("#262626E6")):diffuseupperright(color("#1a1a1aE6"))
			self:diffuselowerleft(color("#0a0a0aF0")):diffuselowerright(color("#060606F0"))
			self:diffusealpha(0.62)
		end
	}
	t[#t + 1] = Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_filigree"),
		InitCommand = function(self)
			self:xy(x + 4, y + h - 3):halign(0):valign(1):zoomto(w - 8, 30):diffusealpha(0.16)
		end
	}
	t[#t + 1] = seraphicSoftEdge(x, y, w, h)
end
seraWindow(10, 24, 262, 432)
seraWindow(582, 24, 262, 432)
-- judge details window in the middle, next to the left column
seraWindow(278, 124, 254, 146)

-- banner at the top of the middle, under the RESULT title:
-- same 3.2:1 shape as the song select banner
if BannersEnabled() then
	local bw = 280
	local bx, by = SCREEN_CENTER_X - bw / 2, 30
	local bh = bw / 3.2
	t[#t + 1] = Def.Sprite {
		Name = "Banner",
		OnCommand = function(self)
			-- sized like Til Death: scaletoclipped first, then load
			self:xy(bx, by):halign(0):valign(0)
			self:scaletoclipped(bw, bh)
			local song = GAMESTATE:GetCurrentSong()
			local bnpath = song and song:GetBannerPath()
			if not bnpath then bnpath = THEME:GetPathG("Common", "fallback banner") end
			self:LoadBackground(bnpath)
			MESSAGEMAN:Broadcast("SeraBannerSized", {w = bw, h = bh})
		end
	}
	local function edge(place)
		return Def.Quad {
			InitCommand = function(self)
				self:halign(0):valign(0):diffuse(color("#ffffff")):diffusealpha(0.2)
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
