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
-- each window is only as tall as what it holds
seraWindow(10, 24, 262, 432) -- song data, options, compare rows, judgments, stats (full height)
seraWindow(582, 24, 262, 32) -- online leaderboard rank at the played rate
-- leaderboard and score history: they grow and fold when clicked (sizes from seraResultPanels)
local function foldWindow(x, w, part)
	local function geom(state)
		local g = seraResultPanels(state)
		if part == "lb" then return g.lbTop, g.lbH end
		return g.shTop, g.shH
	end
	-- every piece places itself from the window's top / height; animated unless it is the first placement
	local function piece(actor, place)
		actor.InitCommand = function(self)
			local y, h = geom(seraResultPanelState)
			place(self, y, h, true)
		end
		actor.SeraRightPanelMessageCommand = function(self, params)
			local y, h = geom(params.state)
			self:stoptweening():decelerate(0.2)
			place(self, y, h, false)
		end
		return actor
	end
	local function edge(place)
		return piece(Def.Quad {}, function(self, y, h, first)
			if first then self:halign(0):valign(0):diffuse(color("#ffffff")):diffusealpha(0.1) end
			place(self, y, h)
		end)
	end
	t[#t + 1] = piece(Def.Quad {}, function(self, y, h, first)
		if first then
			self:x(x):halign(0):valign(0)
			self:diffuseupperleft(color("#262626E6")):diffuseupperright(color("#1a1a1aE6"))
			self:diffuselowerleft(color("#0a0a0aF0")):diffuselowerright(color("#060606F0"))
			self:diffusealpha(0.62)
		end
		self:y(y):zoomto(w, h)
	end)
	t[#t + 1] = piece(Def.Sprite {Texture = THEME:GetPathG("", "seraphic_filigree")}, function(self, y, h, first)
		if first then self:x(x + 4):halign(0):valign(1):zoomto(w - 8, 30) end
		-- no filigree on a folded window (it would stick out of it)
		self:y(y + h - 3):diffusealpha(h > 60 and 0.16 or 0)
	end)
	t[#t + 1] = edge(function(self, y, h) self:xy(x, y):zoomto(w, 1) end)
	t[#t + 1] = edge(function(self, y, h) self:xy(x, y + h - 1):zoomto(w, 1) end)
	t[#t + 1] = edge(function(self, y, h) self:xy(x, y + 1):zoomto(1, h - 2) end)
	t[#t + 1] = edge(function(self, y, h) self:xy(x + w - 1, y + 1):zoomto(1, h - 2) end)
end
foldWindow(582, 262, "lb") -- leaderboard around your score (scrollable)
foldWindow(582, 262, "sh") -- score history
-- judge details window joined to both side windows along the bottom of the middle
seraWindow(272, 314, 310, 142)

-- banner at the top of the middle, under the RESULT title:
-- same 3.2:1 shape as the song select banner
if BannersEnabled() then
	local bw = 310 -- the full width of the middle
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
