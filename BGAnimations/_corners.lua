-- Seraphic crystal corner ornaments + thin silver frame (art from the LR2 skin "Seraphic")
local size = 0.6
local function corner(x, y, zx, zy)
	return Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_corner"),
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomx(size * zx):zoomy(size * zy):diffusealpha(0.95)
		end
	}
end

local function line(x, y, w, h, vertical)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, h):diffuse(color("#e2e2e2")):diffusealpha(0.35)
		end
	}
end

return Def.ActorFrame {
	-- thin double-line border, inset from the screen edge
	line(2, 2, SCREEN_WIDTH - 4, 1),
	line(2, SCREEN_HEIGHT - 3, SCREEN_WIDTH - 4, 1),
	line(2, 2, 1, SCREEN_HEIGHT - 4),
	line(SCREEN_WIDTH - 3, 2, 1, SCREEN_HEIGHT - 4),
	corner(0, 0, 1, 1),
	corner(SCREEN_WIDTH, 0, -1, 1),
	corner(0, SCREEN_HEIGHT, 1, -1),
	corner(SCREEN_WIDTH, SCREEN_HEIGHT, -1, -1)
}
