-- Seraphic: selected row = lit silver-rimmed bar (LR2 art), nudged left like the IIDX wheel.
-- Single pre-assembled sprite (no texture tiling -> no artifacts); interior is transparent so text stays readable.
local barX, barW, barH = 8, capWideScale(get43size(342), 342), 38

local t = Def.ActorFrame {
	InitCommand = function(self) self:x(-18) end,
	OffCommand = function(self) self:visible(false) end,
	Def.Sprite {
		Name = "Horizontal",
		Texture = THEME:GetPathG("", "seraphic_barsel_full"),
		InitCommand = function(self)
			self:xy(barX - 2, -2):halign(0):zoomto(barW + 4, barH + 6)
		end
	},
	-- faint orange bloom inside the bar, cut to the exact bar shape (masks from the bar art: cap + tiled middle + mirrored cap)
	(function()
		local zy = (barH + 6) / 31
		local capW = 24 * zy
		local x0 = barX - 2
		local w = barW + 4
		local function k(m) return {1 * m, 0.54 * m, 0.16 * m, 1} end
		local strong, weak = 0.22, 0.07
		local function piece(tex, setup, colorfn)
			return Def.Sprite {
				Texture = THEME:GetPathG("", tex),
				InitCommand = function(self)
					self:blend("BlendMode_Add")
					setup(self)
					colorfn(self)
				end
			}
		end
		return Def.ActorFrame {
			piece("seraphic_barmask_mid", function(self)
				self:xy(x0 + capW, -2):halign(0):zoomto(w - capW * 2, barH + 6)
				self:texturewrapping(true):customtexturerect(0, 0, (w - capW * 2) / (64 * zy), 1)
			end, function(self) self:diffuseleftedge(k(strong)):diffuserightedge(k(weak)) end),
			piece("seraphic_barmask_cap", function(self)
				self:xy(x0, -2):halign(0):zoomto(capW, barH + 6)
			end, function(self) self:diffuse(k(strong)) end),
			piece("seraphic_barmask_cap", function(self)
				self:xy(x0 + w, -2):halign(0):zoomto(-capW, barH + 6)
			end, function(self) self:diffuse(k(weak)) end),
		}
	end)(),
}

-- optional: silver light band sweeping across the selected bar once each time the selection changes
if SeraphicFx.sweep then
	t[#t + 1] = Def.ActorFrame {
	Name = "Sweep",
	InitCommand = function(self)
		self:xy(barX + 12, -2):diffusealpha(0)
	end,
	CurrentSongChangedMessageCommand = function(self)
		self:stoptweening():x(barX + 12):diffusealpha(1):linear(0.55):x(barX + barW - 22):diffusealpha(0)
	end,
	Def.Quad {
		InitCommand = function(self)
			self:halign(1):zoomto(24, barH - 6):skewx(-0.35):blend("BlendMode_Add")
			self:diffuseleftedge(color("#ffffff00")):diffuserightedge(color("#ffffff30"))
		end
	},
	Def.Quad {
		InitCommand = function(self)
			self:halign(0):zoomto(24, barH - 6):skewx(-0.35):blend("BlendMode_Add")
			self:diffuseleftedge(color("#ffffff30")):diffuserightedge(color("#ffffff00"))
		end
	}
}
end

return t
