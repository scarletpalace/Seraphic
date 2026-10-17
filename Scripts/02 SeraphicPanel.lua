-- Seraphic panel: dark gradient body, silver beveled double border, corner diamonds, filigree footer.
-- Returns an ActorFrame positioned with its top-left at (x, y).
-- LR2-style window pieces, shared by the music select tabs and the info panel ---------------------------

-- faint 1px outline around a window
function seraphicSoftEdge(x, y, w, h, alpha)
	local a = alpha or 0.1
	local function edge(ex, ey, ew, eh)
		return Def.Quad {
			InitCommand = function(self)
				self:xy(x + ex, y + ey):halign(0):valign(0):zoomto(ew, eh):diffuse(color("#ffffff")):diffusealpha(a)
			end
		}
	end
	return Def.ActorFrame {
		edge(0, 0, w, 1), edge(0, h - 1, w, 1), edge(0, 1, 1, h - 2), edge(w - 1, 1, 1, h - 2)
	}
end

-- dark header band with a crimson rule along its bottom edge
function seraphicHeaderBand(x, y, w, h)
	return Def.ActorFrame {
		Def.Quad {
			InitCommand = function(self)
				self:xy(x, y):halign(0):valign(0):zoomto(w, h):diffuse(color("#000000")):diffusealpha(0.55)
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:xy(x, y + h):halign(0):valign(0):zoomto(w, 1)
				self:diffuseleftedge(color("#9c1428E6")):diffuserightedge(color("#9c142820"))
			end
		}
	}
end

-- alternating row band (odd rows darker); i is the 1-based row number
function seraphicRowBand(x, y, w, h, i)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, h):diffuse(color("#000000"))
			self:diffusealpha(i % 2 == 1 and 0.4 or 0.15)
		end
	}
end

-- small crimson diamond used as a row bullet
function seraphicBullet(x, y)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):rotationz(45):zoomto(3.5, 3.5):diffuse(color("#9c1428"))
		end
	}
end

-- "::SECTION" style header text. A literal "::" is turned into a line break by the engine's text
-- handling, so the two colons are split by a soft hyphen (U+00AD, a blank 1px glyph in the serif font).
seraphicColons = ":\194\173:"
function seraphicHeading(text)
	return seraphicColons .. tostring(text):upper()
end

-- colors for LR2-style labels and values
seraphicLabelColor = "#bdb3b6"
seraphicValueColor = "#f4ecee"

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
	-- tab windows (border only): LR2-style soft edge instead of the silver frame
	if borderOnly == true then
		return Def.ActorFrame {
			InitCommand = function(self) self:xy(x, y) end,
			Def.Sprite {
				Texture = THEME:GetPathG("", "seraphic_filigree"),
				InitCommand = function(self)
					self:xy(4, h - 3):halign(0):valign(1):zoomto(w - 8, fh):diffusealpha(0.16)
				end
			},
			seraphicSoftEdge(0, 0, w, h)
		}
	end
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

-- results screen, right column: the leaderboard and the score history share the space under the rank window.
-- Clicking one of them grows it and folds the other down to its header; clicking it again evens them out.
-- states: "mid" (both open), "lb" (leaderboard grown), "sh" (score history grown); kept for the session
seraResultPanelState = "mid"
function seraResultPanels(state)
	local top, bottom, gap, folded = 60, 456, 6, 24
	local lbH = 216
	if state == "lb" then
		lbH = bottom - top - gap - folded
	elseif state == "sh" then
		lbH = folded
	end
	return {lbTop = top, lbH = lbH, shTop = top + lbH + gap, shH = bottom - top - lbH - gap}
end
