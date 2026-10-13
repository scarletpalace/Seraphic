-- Seraphic: left part of the select-screen top bar (x < 488). Lives in the decorations layer, under the info
-- panels and the banner, so they overlap it; the right part (clock / pack strip) is drawn by _frame.lua.
local h, w = 90, 488
local t = Def.ActorFrame {}

local function scaleColor(c, m)
	return {math.min(c[1] * m, 1), math.min(c[2] * m, 1), math.min(c[3] * m, 1), c[4]}
end

t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, 0):halign(0):valign(0):zoomto(w, h):diffuse(getMainColor("frames"))
		self:diffusetopedge(scaleColor(getMainColor("frames"), 1.5))
	end
}

-- hanging cross / bead-chain texture (mirrored tiles stay seamless)
local tileW = h * 640 / 96
for i = 0, math.ceil(w / tileW) do
	t[#t + 1] = Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_chain"),
		InitCommand = function(self)
			local flip = (i % 2 == 0) and 1 or -1
			self:xy(i * tileW + (flip == -1 and tileW or 0), 0):halign(0):valign(0)
			self:zoomto(tileW * flip, h):diffusealpha(0.9)
		end
	}
end

t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, h):halign(0):valign(1):zoomto(w, 2):diffuse(getMainColor("positive"))
		self:diffusealpha(0.9)
	end
}

return t
