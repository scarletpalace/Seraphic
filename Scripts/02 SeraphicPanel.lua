-- Seraphic panel: dark gradient body, silver beveled double border, corner diamonds, filigree footer.
-- Returns an ActorFrame positioned with its top-left at (x, y).
function seraphicPanel(x, y, w, h, borderOnly, bodyAlpha)
	local function edge(ex, ey, ew, eh, setup)
		return Def.Quad {
			InitCommand = function(self)
				self:xy(ex, ey):halign(0):valign(0):zoomto(ew, eh):diffuse(color("#ffffff"))
				setup(self)
			end
		}
	end
	local function diamond(dx, dy)
		return Def.Quad {
			InitCommand = function(self)
				self:xy(dx, dy):rotationz(45):zoomto(5, 5):diffuse(color("#ffffff")):diffusealpha(0.95)
			end
		}
	end
	local fh = math.min(h * 0.35, 30)
	return Def.ActorFrame {
		InitCommand = function(self) self:xy(x, y) end,
		-- body (skipped when the panel already has its own background)
		Def.Quad {
			InitCommand = function(self)
				if borderOnly then
					self:visible(false)
					return
				end
				self:halign(0):valign(0):zoomto(w, h)
				self:diffuseupperleft(color("#262626E6")):diffuseupperright(color("#1a1a1aE6"))
				self:diffuselowerleft(color("#0a0a0aF0")):diffuselowerright(color("#060606F0"))
				if bodyAlpha then self:diffusealpha(bodyAlpha) end
			end
		},
		-- filigree footer
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_filigree"),
			InitCommand = function(self)
				self:xy(4, h - 3):halign(0):valign(1):zoomto(w - 8, fh):diffusealpha(borderOnly == "clean" and 0 or (borderOnly and 0.16 or 0.28))
			end
		},
		-- outer border (bright at one end, fading along the edge)
		edge(0, 0, w, 1, function(s) s:diffuseleftedge(color("#ffffffE6")):diffuserightedge(color("#ffffff55")) end),
		edge(0, h - 1, w, 1, function(s) s:diffuseleftedge(color("#ffffff55")):diffuserightedge(color("#ffffffE6")) end),
		edge(0, 0, 1, h, function(s) s:diffusetopedge(color("#ffffffE6")):diffusebottomedge(color("#ffffff55")) end),
		edge(w - 1, 0, 1, h, function(s) s:diffusetopedge(color("#ffffff55")):diffusebottomedge(color("#ffffffE6")) end),
		-- inner hairline border
		edge(3, 3, w - 6, 1, function(s) s:diffusealpha(0.16) end),
		edge(3, h - 4, w - 6, 1, function(s) s:diffusealpha(0.16) end),
		edge(3, 3, 1, h - 6, function(s) s:diffusealpha(0.16) end),
		edge(w - 4, 3, 1, h - 6, function(s) s:diffusealpha(0.16) end),
		diamond(0, 0), diamond(w, 0), diamond(0, h), diamond(w, h)
	}
end


-- Metallic dark version of a bright judgment color: returns (top, bottom) gradient colors.
function seraphicBarColors(c)
	local l = c[1] * 0.299 + c[2] * 0.587 + c[3] * 0.114
	local function mix(v) return (v * 0.65 + l * 0.35) * 0.62 end
	local r, g, b = mix(c[1]), mix(c[2]), mix(c[3])
	local function sc(m) return {math.min(r * m, 1), math.min(g * m, 1), math.min(b * m, 1), 1} end
	return sc(1.5), sc(0.5)
end

-- Silver border for a box centered on its parent's origin whose size can change.
-- getSize() must return width, height. Redraws on JudgeDisplayChanged.
function seraphicCenteredBorder(getSize)
	local function piece(setup)
		return Def.Quad {
			InitCommand = function(self)
				self:diffuse(color("#ffffff")):diffusealpha(0.6)
				setup(self, getSize())
			end,
			JudgeDisplayChangedMessageCommand = function(self)
				setup(self, getSize())
			end
		}
	end
	local function diamond(sx, sy)
		return piece(function(self, w, h)
			self:xy(sx * w / 2, sy * h / 2):rotationz(45):zoomto(5, 5):diffusealpha(0.95)
		end)
	end
	return Def.ActorFrame {
		piece(function(self, w, h) self:xy(0, -h / 2):zoomto(w, 1) end),
		piece(function(self, w, h) self:xy(0, h / 2):zoomto(w, 1) end),
		piece(function(self, w, h) self:xy(-w / 2, 0):zoomto(1, h) end),
		piece(function(self, w, h) self:xy(w / 2, 0):zoomto(1, h) end),
		diamond(-1, -1), diamond(1, -1), diamond(-1, 1), diamond(1, 1)
	}
end
