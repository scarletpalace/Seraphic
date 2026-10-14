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

local progX, progY, progW, progH = 18, 13, barW - 40, 3
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
				x = x + w
			end
		end,
		-- track (unplayed songs)
		Def.Quad {
			InitCommand = function(self)
				self:xy(progX, progY):halign(0):zoomto(progW, progH):diffuse(color("#000000")):diffusealpha(0.55)
			end
		},
		seraphicSoftEdge(progX - 1, progY - progH / 2 - 1, progW + 2, progH + 2, 0.18)
	}
	for i, fam in ipairs(SeraphicPackProgressFamilies or {}) do
		f[#f + 1] = Def.Quad {
			Name = "Seg" .. i,
			InitCommand = function(self)
				self:xy(progX, progY):halign(0):zoomto(0, progH):diffuse(getGradeColor(fam.grade))
			end
		}
	end
	return f
end

return Def.ActorFrame {
	seraphicBar("bar", 31, 1, 0.78),
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
