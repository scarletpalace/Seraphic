if SeraphicStamp then SeraphicStamp("wheel item part") end
local lastclick = GetTimeSinceStart()
local requiredtimegap = 0.1

-- Seraphic: LR2-style list bar (bevelled gradient, silver edge lines, diamond marker)
local barX, barW, barH = 8, capWideScale(get43size(342), 342), 38


-- Seraphic: bar built from the LR2 skin art (left cap + tiled middle + mirrored right cap)
function seraphicBar(name, texH, alpha, vis)
	local zy = (barH + 6) / texH
	local capW = 24 * zy
	local x0 = barX - 2
	local w = barW + 4
	return Def.ActorFrame {
		InitCommand = function(self) self:y(-2):diffusealpha(alpha or 1) end,
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_" .. name .. "_mid"),
			InitCommand = function(self)
				self:xy(x0 + capW, 0):halign(0):zoomto(w - capW * 2, barH + 6)
				self:texturewrapping(true):customtexturerect(0, 0, (w - capW * 2) / (64 * zy), 1)
				if vis then self:diffusealpha(vis) end
			end
		},
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_" .. name .. "_cap"),
			InitCommand = function(self) self:xy(x0, 0):halign(0):zoomto(capW, barH + 6) end
		},
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_" .. name .. "_cap"),
			InitCommand = function(self) self:xy(x0 + w, 0):halign(0):zoomto(-capW, barH + 6) end
		},
	}
end

-- tube under the pack name, with room on the right for the "played / total" count
local progX, progY, progW, progH = 24, 10, barW - 104, 6
-- grade colour softened toward silver so it sits with the theme: lit top, deeper bottom
local function progShade(c, toWhite, dark)
	local m = 0.18
	local r, g, b = c[1] + (0.91 - c[1]) * m, c[2] + (0.87 - c[2]) * m, c[3] + (0.88 - c[3]) * m
	if toWhite then
		return {r + (1 - r) * toWhite, g + (1 - g) * toWhite, b + (1 - b) * toWhite, 0.95}
	end
	return {r * dark, g * dark, b * dark, 0.95}
end
function seraphicPackProgressBar()
	local f = Def.ActorFrame {
		InitCommand = function(self) self:visible(false) end,
		SetCommand = function(self, params)
			local isPack = params and params.Song == nil and type(params.Text) == "string" and params.Text ~= ""
				and (params.Type == nil or tostring(params.Type):find("Section") ~= nil)
			local prog = isPack and SeraphicPackProgress and SeraphicPackProgress(params.Text)
			if not prog then
				self:visible(false)
				return
			end
			self:visible(true)
			local x = progX
			for i = 1, #SeraphicPackProgressFamilies do
				local w = progW * prog.counts[i] / prog.total
				self:GetChild("Seg" .. i):x(x):zoomto(w, progH):visible(w > 0)
				self:GetChild("Sep" .. i):x(x + w):visible(w > 0 and x + w < progX + progW - 1)
				x = x + w
			end
			-- small crystal riding the end of the filled part
			self:GetChild("Head"):x(x):visible(x > progX + 1 and x < progX + progW - 1)
			local played = 0
			for i = 1, #prog.counts do played = played + prog.counts[i] end
			self:GetChild("Count"):settextf("%d / %d", played, prog.total)
		end,
		-- tube: dark glass with a silver rim (brighter on top), fading in at both ends
		Def.Quad {
			InitCommand = function(self)
				self:xy(progX, progY):halign(0):zoomto(progW, progH + 2):diffuse(color("#050505")):diffusealpha(0.8)
			end
		},
		-- inner shadow at the top of the empty tube
		Def.Quad {
			InitCommand = function(self)
				self:xy(progX, progY - progH / 2):halign(0):valign(0):zoomto(progW, progH / 2)
				self:diffusetopedge(color("#00000099")):diffusebottomedge(color("#00000000"))
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:xy(progX, progY - progH / 2 - 1.5):halign(0):zoomto(progW, 1):diffuse(color("#ffffff"))
				self:diffusealpha(0.32):fadeleft(0.08):faderight(0.08)
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:xy(progX, progY + progH / 2 + 1.5):halign(0):zoomto(progW, 1):diffuse(color("#bdb3b6"))
				self:diffusealpha(0.22):fadeleft(0.08):faderight(0.08)
			end
		}
	}
	for i, fam in ipairs(SeraphicPackProgressFamilies or {}) do
		local c = getGradeColor(fam.grade)
		f[#f + 1] = Def.Quad {
			Name = "Seg" .. i,
			InitCommand = function(self)
				self:xy(progX, progY):halign(0):zoomto(0, progH)
				self:diffusetopedge(progShade(c, 0.45)):diffusebottomedge(progShade(c, nil, 0.6))
			end
		}
	end
	-- hairline breaks between grade families
	for i = 1, #(SeraphicPackProgressFamilies or {}) do
		f[#f + 1] = Def.Quad {
			Name = "Sep" .. i,
			InitCommand = function(self)
				self:xy(progX, progY):zoomto(1, progH):diffuse(color("#000000")):diffusealpha(0.6)
			end
		}
	end
	-- glass sheen over the fill
	f[#f + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(progX, progY - progH / 2):halign(0):valign(0):zoomto(progW, progH * 0.45)
			self:diffusetopedge(color("#ffffff40")):diffusebottomedge(color("#ffffff08")):blend("BlendMode_Add")
		end
	}
	-- crystal caps at both ends (like the grade gauge) and a small one at the fill's tip
	local function crystal(name, x, z)
		return Def.Sprite {
			Name = name,
			Texture = THEME:GetPathG("", "seraphic_crystal"),
			InitCommand = function(self)
				self:xy(x, progY):zoom(z)
			end
		}
	end
	f[#f + 1] = crystal("CapL", progX - 4, 0.28)
	f[#f + 1] = crystal("CapR", progX + progW + 4, 0.28)
	f[#f + 1] = crystal("Head", progX, 0.18)
	-- songs with a score / songs in the pack
	f[#f + 1] = LoadFont("Common Normal") .. {
		Name = "Count",
		InitCommand = function(self)
			self:xy(progX + progW + 14, progY):halign(0):zoom(0.34):diffuse(color(seraphicLabelColor))
		end
	}
	return f
end

-- selected row: red rim + faint red bloom drawn with the bar's own cap/middle geometry, inside the item itself so it
-- always sits exactly on the bar (also while the wheel scrolls); shown only on the centre slot of the wheel
local wheelCentre = math.ceil(15 / 2)
function seraphicSelectedBar()
	local zy = (barH + 6) / 31
	local capW = 24 * zy
	local x0 = barX - 2
	local w = barW + 4
	local function k(m) return {1 * m, 0.1 * m, 0.14 * m, 1} end
	local strong, weak = 0.22, 0.07
	-- one bar-shaped layer: left cap + tiled middle + mirrored right cap
	local function layer(name, add, midfn, leftfn, rightfn)
		local mid, cap = name .. "_mid", name .. "_cap"
		return Def.ActorFrame {
			Def.Sprite {
				Texture = THEME:GetPathG("", "seraphic_" .. mid),
				InitCommand = function(self)
					if add then self:blend("BlendMode_Add") end
					self:xy(x0 + capW, 0):halign(0):zoomto(w - capW * 2, barH + 6)
					self:texturewrapping(true):customtexturerect(0, 0, (w - capW * 2) / (64 * zy), 1)
					if midfn then midfn(self) end
				end
			},
			Def.Sprite {
				Texture = THEME:GetPathG("", "seraphic_" .. cap),
				InitCommand = function(self)
					if add then self:blend("BlendMode_Add") end
					self:xy(x0, 0):halign(0):zoomto(capW, barH + 6)
					if leftfn then leftfn(self) end
				end
			},
			Def.Sprite {
				Texture = THEME:GetPathG("", "seraphic_" .. cap),
				InitCommand = function(self)
					if add then self:blend("BlendMode_Add") end
					self:xy(x0 + w, 0):halign(0):zoomto(-capW, barH + 6)
					if rightfn then rightfn(self) end
				end
			},
		}
	end
	local f = Def.ActorFrame {
		InitCommand = function(self) self:y(-2):visible(false) end,
		SetCommand = function(self, params)
			self:visible(params ~= nil and params.DrawIndex == wheelCentre)
		end,
		-- faint red bloom inside the bar (masks from the bar art)
		layer("barmask", true,
			function(self) self:diffuseleftedge(k(strong)):diffuserightedge(k(weak)) end,
			function(self) self:diffuse(k(strong)) end,
			function(self) self:diffuse(k(weak)) end),
		-- red rim traced over the bar's silver edge (seraphic_barsel_cap/mid are the bar's edge lines recoloured)
		layer("barsel", false),
	}
	-- optional: silver light band sweeping across the selected bar once each time the selection changes
	if SeraphicFx and SeraphicFx.sweep then
		f[#f + 1] = Def.ActorFrame {
			Name = "Sweep",
			InitCommand = function(self)
				self:x(barX + 12):diffusealpha(0)
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
	return f
end

return Def.ActorFrame {
	seraphicBar("bar", 31, 1, 0.78),
	seraphicSelectedBar(),
	-- silver sheen along the top, like the lit edge on the LR2 bars
	Def.Quad {
		InitCommand = function(self)
			self:xy(barX + 8, -2 - barH / 2 + 3):halign(0):zoomto(barW - 16, 1)
			self:diffuseleftedge(color("#ffffff66")):diffuserightedge(color("#ffffff00"))
		end
	},
	-- pack progress: one thin bar under the pack name, split by grade family (best first), dark for the rest
	-- (Scripts/06 SeraphicPackProgress.lua); only shown on pack rows
	seraphicPackProgressBar(),
    UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:halign(0)
			self:xy(0,0)
			self:diffusealpha(0)
			self:zoomto(854, 46)
		end,
        SetCommand = function(self, params)
            self.index = params.DrawIndex
        end,
		MouseDownCommand = function(self, params)
            if params.event == "DeviceButton_left mouse button" then
                local now = GetTimeSinceStart()
                if now - lastclick < requiredtimegap then return end
                lastclick = now

                local numwheelitems = 15
                local middle = math.ceil(15 / 2)
                local top = SCREENMAN:GetTopScreen()
                local we = top:GetMusicWheel()
                if we then
                    local dist = self.index - middle
                    if dist == 0 and we:IsSettled() then
                        -- clicked current item
                        top:SelectCurrent()
                    else
                        local itemtype = we:MoveAndCheckType(self.index - middle)
                        we:Move(0)
                        if itemtype == "WheelItemDataType_Section" then
                            -- clicked a group
                            top:SelectCurrent()
                        end
                    end
                end
            elseif params.event == "DeviceButton_right mouse button" then
                -- right click opens playlists
                local tind = getTabIndex()
	    		setTabIndex(7)
    			MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 7})
            end
		end,
	},
}
