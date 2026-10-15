if SeraphicStamp then SeraphicStamp("wheel item grades") end
-- bar geometry (same numbers as MusicWheelItem Song NormalPart)
local barX, barW, barH = 8, capWideScale(get43size(342), 342), 38

-- plain rectangular wash (fallback when SeraphicFx.shapedTint is false)
local function seraphicGradeTintSimple()
	return Def.Quad {
		InitCommand = function(self)
			self:xy(13, -2):halign(0):zoomto(barW - 10, barH - 2):blend("BlendMode_Add"):visible(false)
		end,
		SetGradeCommand = function(self, params)
			if params.Grade and params.Grade ~= "Grade_None" then
				local c = getGradeColor(params.Grade)
				local function k(m) return {c[1] * m, c[2] * m, c[3] * m, 1} end
				self:diffuseleftedge(k(0.24)):diffuserightedge(k(0.08)):visible(true)
			else
				self:visible(false)
			end
		end
	}
end

local function seraphicGradeTint()
	local zy = (barH + 6) / 31
	local capW = 24 * zy
	local x0 = barX - 2
	local w = barW + 4
	local function k(c, m) return {c[1] * m, c[2] * m, c[3] * m, 1} end
	local function piece(tex, setup, colorfn)
		return Def.Sprite {
			Texture = THEME:GetPathG("", tex),
			InitCommand = function(self)
				self:blend("BlendMode_Add"):visible(false)
				setup(self)
			end,
			SetGradeCommand = function(self, params)
				if params.Grade and params.Grade ~= "Grade_None" then
					colorfn(self, getGradeColor(params.Grade))
					self:visible(true)
				else
					self:visible(false)
				end
			end
		}
	end
	local strong, weak = 0.24, 0.08
	return Def.ActorFrame {
		piece("seraphic_barmask_mid", function(self)
			self:xy(x0 + capW, -2):halign(0):zoomto(w - capW * 2, barH + 6)
			self:texturewrapping(true):customtexturerect(0, 0, (w - capW * 2) / (64 * zy), 1)
		end, function(self, c) self:diffuseleftedge(k(c, strong)):diffuserightedge(k(c, weak)) end),
		piece("seraphic_barmask_cap", function(self)
			self:xy(x0, -2):halign(0):zoomto(capW, barH + 6)
		end, function(self, c) self:diffuse(k(c, strong)) end),
		piece("seraphic_barmask_cap", function(self)
			self:xy(x0 + w, -2):halign(0):zoomto(-capW, barH + 6)
		end, function(self, c) self:diffuse(k(c, weak)) end),
	}
end

return Def.ActorFrame {
	Def.Quad {
		InitCommand = function(self)
			self:xy(2, -2):zoomto(4, 19)
		end,
		SetGradeCommand = function(self, params)
			if params.HasGoal then
				if not params.AllGoalsComplete then
					self:diffuse(byJudgment("TapNoteScore_Miss"))
				else
					self:diffuse(byJudgment("TapNoteScore_W1"))
				end
				self:diffusealpha(1)
			else
				self:diffusealpha(0)
			end
		end
	},
	-- Seraphic: the row is washed with a dark version of the grade colour, in the exact shape of the bar
	-- (masks cut from the bar art: left cap + tiled middle + mirrored right cap)
	Def.ActorFrame {
		-- Seraphic: the lamp pulses like in the original skin (1 -> 0.5 alpha every second)
		InitCommand = function(self)
			self:diffuseshift():effectcolor1(color("1,1,1,1")):effectcolor2(color("1,1,1,0.5")):effectperiod(2)
		end,
		(SeraphicFx.shapedTint and seraphicGradeTint or seraphicGradeTintSimple)()
	},
	Def.Sprite {
		InitCommand = function(self)
			self:xy(1, 3):zoomto(4, 19)
		end,
		SetGradeCommand = function(self, params)
			if params.PermaMirror then
				self:Load(THEME:GetPathG("", "mirror"))
				self:zoomto(16, 16)
				self:visible(true)
			else
				self:visible(false)
			end
		end
	},
	Def.Sprite {
		InitCommand = function(self)
			self:xy(1, -13):zoomto(4, 19)
		end,
		SetGradeCommand = function(self, params)
			if params.Favorited then
				self:Load(THEME:GetPathG("", "favorite"))
				self:zoomto(16, 16)
				self:visible(true)
			else
				self:visible(false)
			end
		end
	}
}
