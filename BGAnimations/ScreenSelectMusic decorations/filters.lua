local numbershers = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}
local frameX = 10
local frameY = 45
local active = false
local whee
local spacingY = 22 -- filter row pitch
local textzoom = 0.35
local ActiveSS = 0
local SSQuery = {}
SSQuery[0] = {}
SSQuery[1] = {}
local frameWidth = capWideScale(360, 400)
local frameHeight = 341 -- ends at the bottom bar (y 386)
local offsetX = 10
local offsetY = 20
local activebound = 0
for i = 1, #ms.SkillSets + 2 do
	SSQuery[0][i] = "0"
	SSQuery[1][i] = "0"
end
local numbersafterthedecimal = 0

local hoverAlpha = 0.6
local instantSearch = themeConfig:get_data().global.InstantSearch

local function FilterInput(event)
	if event.type ~= "InputEventType_Release" and ActiveSS > 0 and active then
		local shouldUpdate = false
		if event.button == "Start" or event.button == "Back" then
			ActiveSS = 0
			MESSAGEMAN:Broadcast("NumericInputEnded")
			SCREENMAN:set_input_redirected(PLAYER_1, false)
			return true
		elseif event.DeviceInput.button == "DeviceButton_backspace" then
			SSQuery[activebound][ActiveSS] = SSQuery[activebound][ActiveSS]:sub(1, -2)
			shouldUpdate = true
		elseif event.DeviceInput.button == "DeviceButton_delete" then
			SSQuery[activebound][ActiveSS] = ""
			shouldUpdate = true
		else
			for i = 1, #numbershers do
				if event.DeviceInput.button == "DeviceButton_" .. numbershers[i] then
					shouldUpdate = true
					if SSQuery[activebound][ActiveSS] == "0" then
						SSQuery[activebound][ActiveSS] = ""
					end
					SSQuery[activebound][ActiveSS] = SSQuery[activebound][ActiveSS] .. numbershers[i]
					if (ActiveSS < #ms.SkillSets + 1 and #SSQuery[activebound][ActiveSS] > 2) or (ActiveSS < #ms.SkillSets + 2 and #SSQuery[activebound][ActiveSS] > 3) or #SSQuery[activebound][ActiveSS] > 5 then
						SSQuery[activebound][ActiveSS] = numbershers[i]
					end
				end
			end
		end
		if SSQuery[activebound][ActiveSS] == "" then
			shouldUpdate = true
			SSQuery[activebound][ActiveSS] = "0"
		end
		if shouldUpdate then
			local num = 0
			if ActiveSS == #ms.SkillSets+2 then
				local q = SSQuery[activebound][ActiveSS]
				numbersafterthedecimal = 0
				if #q > 2 then
					numbersafterthedecimal = #q-2
					local n = tonumber(q) / (10 ^ (#q-2))
					n = notShit.round(n, numbersafterthedecimal)
					num = n
				else
					num = tonumber(q)
				end
			else
				num = tonumber(SSQuery[activebound][ActiveSS])
			end
			FILTERMAN:SetSSFilter(num, ActiveSS, activebound)
			whee:SongSearch("") -- stupid workaround?
			MESSAGEMAN:Broadcast("UpdateFilter")
		end
	end
end

local translated_info = {
	Mode = THEME:GetString("TabFilter", "Mode"),
	HighestOnly = THEME:GetString("TabFilter", "HighestOnly"),
	HighestDifficultyOnly = THEME:GetString("TabFilter", "HighestDifficultyOnly"),
	On = THEME:GetString("OptionNames", "On"),
	Off = THEME:GetString("OptionNames", "Off"),
	Matches = THEME:GetString("TabFilter", "Matches"),
	CommonPackFilter = THEME:GetString("TabFilter", "CommonPackFilter"),
	Length = THEME:GetString("TabFilter", "Length"),
	BestPercent = "Best %",
	AND = THEME:GetString("TabFilter", "AND"),
	OR = THEME:GetString("TabFilter", "OR"),
	ExplainStartInput = THEME:GetString("TabFilter", "ExplainStartInput"),
	ExplainCancelInput = THEME:GetString("TabFilter", "ExplainCancelInput"),
	ExplainGrey = THEME:GetString("TabFilter", "ExplainGrey"),
	ExplainBounds = THEME:GetString("TabFilter", "ExplainBounds"),
	ExplainHighest = THEME:GetString("TabFilter", "ExplainHighest"),
	ExplainHighestDifficulty = THEME:GetString("TabFilter", "ExplainHighestDifficulty"),
	MaxRate = THEME:GetString("TabFilter", "MaxRate"),
	Title = THEME:GetString("TabFilter", "Title"),
	MinRate = THEME:GetString("TabFilter", "MinRate"),
}

-- LR2-style layout (all in panel-local coords; the whole tab ends at the bottom bar, y 386)
local labelZoom = 0.4 -- Common Normal, silver uppercase labels
local valueZoom = 0.21 -- Common Large (== Common Normal 0.42), light values
local rowH = 18
local rowsY = 82 -- top of the first filter row (under the help text)
local function rowTop(i) return rowsY + (i - 1) * spacingY end
local function rowMid(i) return rowTop(i) + rowH / 2 end
-- left column: filter rows with two value boxes
local leftX = 8
local leftW = frameWidth / 2 - 16
local boxW = 30
local boxH = 15
local box2Right = leftX + leftW - 4
local box1Right = box2Right - boxW - 5
-- right column: LABEL : value rows
local rightX = frameWidth / 2 + 4
local rightW = frameWidth / 2 - 12
local rightLabelX = rightX + 8
local rightLabelW = rightW * 0.62
local rightValueX = rightX + rightW - 6
local rightValueW = rightW * 0.34
local resetW = 64
local resetX = rightX + rightW - resetW / 2

local function helpLine(n, text)
	return LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(offsetX, offsetY + 10 + (n - 1) * 12):zoom(0.38):halign(0):maxwidth((frameWidth - 2 * offsetX) / 0.38)
			self:diffuse(color(seraphicLabelColor)):settext(text)
		end
	}
end

-- silver uppercase label for a right column row; dim=true greys it out while the filter mode is AND
local function rightLabel(i, text, dim)
	return LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(rightLabelX, rowMid(i)):zoom(labelZoom):halign(0):maxwidth(rightLabelW / labelZoom)
			self:settext(tostring(text):upper())
			self:diffuse(color(seraphicLabelColor))
		end,
		SetCommand = function(self)
			if dim then
				self:diffusealpha(FILTERMAN:GetFilterMode() and 0.2 or 1)
			end
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		FilterModeChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		ResetFilterMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}
end


local f = Def.ActorFrame {
	BeginCommand = function(self)
		self:halign(0):visible(false)
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
		SCREENMAN:GetTopScreen():AddInputCallback(FilterInput)
		self:queuecommand("Set")
	end,
	OffCommand = function(self)
		self:bouncebegin(0.2):xy(-500, frameY):diffusealpha(0)
		self:sleep(0.04):queuecommand("Invis")
	end,
	InvisCommand= function(self)
		self:visible(false)
	end,
	OnCommand = function(self)
		self:bouncebegin(0.2):xy(frameX, frameY):diffusealpha(1)
	end,
	SetCommand = function(self)
		self:finishtweening()
		if getTabIndex() == 5 then
			self:visible(true)
			self:queuecommand("On")
			active = true
		else
			MESSAGEMAN:Broadcast("NumericInputEnded")
			self:queuecommand("Off")
			active = false
		end
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	MouseRightClickMessageCommand = function(self)
		ActiveSS = 0
		MESSAGEMAN:Broadcast("NumericInputEnded")
		MESSAGEMAN:Broadcast("UpdateFilter")
		SCREENMAN:set_input_redirected(PLAYER_1, false)
	end,
	Def.Quad {
		InitCommand = function(self)
			self:zoomto(frameWidth, frameHeight):halign(0):valign(0):diffuse(getMainColor("tabs")):diffusetopedge(panelTopColor())
		end
	},
	seraphicPanel(0, 0, frameWidth, frameHeight, true),
	-- header band + ::FILTERS heading
	seraphicHeaderBand(0, 0, frameWidth, offsetY),
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(offsetX, offsetY / 2):zoom(0.45):halign(0):settext(seraphicHeading(translated_info["Title"]))
			self:diffuse(color(seraphicLabelColor))
		end
	},
	-- help text: small silver lines under the header
	helpLine(1, translated_info["ExplainStartInput"]),
	helpLine(2, translated_info["ExplainCancelInput"]),
	helpLine(3, translated_info["ExplainGrey"]),
	helpLine(4, translated_info["ExplainBounds"]),
	--[[ -- hiding extra unnecessary information
	helpLine(5, translated_info["ExplainHighest"]),
	helpLine(6, translated_info["ExplainHighestDifficulty"]),
	]]
	-- right column row bands
	seraphicRowBand(rightX, rowTop(1), rightW, rowH, 1),
	seraphicRowBand(rightX, rowTop(2), rightW, rowH, 2),
	seraphicRowBand(rightX, rowTop(3), rightW, rowH, 3),
	seraphicRowBand(rightX, rowTop(4), rightW, rowH, 4),
	seraphicRowBand(rightX, rowTop(5), rightW, rowH, 5),
	seraphicRowBand(rightX, rowTop(7), rightW, rowH, 1),
	rightLabel(1, translated_info["MaxRate"]),
	UIElements.TextToolTip(1, 1, "Common Large") ..{
		InitCommand = function(self)
			self:xy(rightValueX, rowMid(1)):zoom(valueZoom):halign(1):maxwidth(rightValueW / valueZoom)
			self:diffuse(color(seraphicValueColor))
		end,
		SetCommand = function(self)
			self:settextf("%5.1fx", FILTERMAN:GetMaxFilterRate())
		end,
		MaxFilterRateChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		ResetFilterMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(rightX, rowMid(1)):zoomto(rightW, rowH):halign(0):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and active then
				FILTERMAN:SetMaxFilterRate(FILTERMAN:GetMaxFilterRate() + 0.1)
				MESSAGEMAN:Broadcast("MaxFilterRateChanged")
				whee:SongSearch("")
			elseif params.event == "DeviceButton_right mouse button" and active then
				FILTERMAN:SetMaxFilterRate(FILTERMAN:GetMaxFilterRate() - 0.1)
				MESSAGEMAN:Broadcast("MaxFilterRateChanged")
				whee:SongSearch("")
			end
		end,
	},
	rightLabel(2, translated_info["MinRate"]),
	UIElements.TextToolTip(1, 1, "Common Large") ..{
		InitCommand = function(self)
			self:xy(rightValueX, rowMid(2)):zoom(valueZoom):halign(1):maxwidth(rightValueW / valueZoom)
			self:diffuse(color(seraphicValueColor))
		end,
		SetCommand = function(self)
			self:settextf("%5.1fx", FILTERMAN:GetMinFilterRate())
		end,
		MaxFilterRateChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		ResetFilterMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(rightX, rowMid(2)):zoomto(rightW, rowH):halign(0):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and active then
				FILTERMAN:SetMinFilterRate(FILTERMAN:GetMinFilterRate() + 0.1)
				MESSAGEMAN:Broadcast("MaxFilterRateChanged")
				whee:SongSearch("")
			elseif params.event == "DeviceButton_right mouse button" and active then
				FILTERMAN:SetMinFilterRate(FILTERMAN:GetMinFilterRate() - 0.1)
				MESSAGEMAN:Broadcast("MaxFilterRateChanged")
				whee:SongSearch("")
			end
		end,
	},
	rightLabel(3, translated_info["Mode"]),
	UIElements.TextToolTip(1, 1, "Common Large") ..{
		InitCommand = function(self)
			self:xy(rightValueX, rowMid(3)):zoom(valueZoom):halign(1):maxwidth(rightValueW / valueZoom)
			self:diffuse(color(seraphicValueColor))
		end,
		SetCommand = function(self)
			if FILTERMAN:GetFilterMode() then
				self:settext(translated_info["AND"])
			else
				self:settext(translated_info["OR"])
			end
		end,
		FilterModeChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		ResetFilterMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(rightX, rowMid(3)):zoomto(rightW, rowH):halign(0):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and active then
				FILTERMAN:ToggleFilterMode()
				MESSAGEMAN:Broadcast("FilterModeChanged")
				whee:SongSearch("")
			end
		end
	},
	rightLabel(4, translated_info["HighestOnly"], true),
	UIElements.TextToolTip(1, 1, "Common Large") ..{
		InitCommand = function(self)
			self:xy(rightValueX, rowMid(4)):zoom(valueZoom):halign(1):maxwidth(rightValueW / valueZoom)
		end,
		SetCommand = function(self)
			if FILTERMAN:GetHighestSkillsetsOnly() then
				self:settext(translated_info["On"])
			else
				self:settext(translated_info["Off"])
			end
			if FILTERMAN:GetFilterMode() then
				self:diffuse(1,1,1,0.2)
			else
				self:diffuse(color(seraphicValueColor))
			end
		end,
		FilterModeChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		ResetFilterMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			if not FILTERMAN:GetFilterMode() then
				self:diffusealpha(hoverAlpha)
			end
		end,
		MouseOutCommand = function(self)
			if FILTERMAN:GetFilterMode() then
				self:diffusealpha(0.2)
			else
				self:diffusealpha(1)
			end
		end,
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(rightX, rowMid(4)):zoomto(rightW, rowH):halign(0):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and active and not FILTERMAN:GetFilterMode() then
				FILTERMAN:ToggleHighestSkillsetsOnly()
				MESSAGEMAN:Broadcast("FilterModeChanged")
				whee:SongSearch("")
			end
		end
	},
	rightLabel(5, translated_info["HighestDifficultyOnly"], true),
	UIElements.TextToolTip(1, 1, "Common Large") ..{
		InitCommand = function(self)
			self:xy(rightValueX, rowMid(5)):zoom(valueZoom):halign(1):maxwidth(rightValueW / valueZoom)
		end,
		SetCommand = function(self)
			if FILTERMAN:GetHighestDifficultyOnly() then
				self:settext(translated_info["On"])
			else
				self:settext(translated_info["Off"])
			end
			if FILTERMAN:GetFilterMode() then
				self:diffuse(1,1,1,0.2)
			else
				self:diffuse(color(seraphicValueColor))
			end
		end,
		FilterModeChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		ResetFilterMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseOverCommand = function(self)
			if not FILTERMAN:GetFilterMode() then
				self:diffusealpha(hoverAlpha)
			end
		end,
		MouseOutCommand = function(self)
			if FILTERMAN:GetFilterMode() then
				self:diffusealpha(0.2)
			else
				self:diffusealpha(1)
			end
		end,
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(rightX, rowMid(5)):zoomto(rightW, rowH):halign(0):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and active and not FILTERMAN:GetFilterMode() then
				FILTERMAN:ToggleHighestDifficultyOnly()
				MESSAGEMAN:Broadcast("FilterModeChanged")
				whee:SongSearch("")
			end
		end
	},
	-- matches: label + count, hidden until the first results arrive
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(rightLabelX, rowMid(7)):zoom(labelZoom):halign(0):maxwidth(rightLabelW / labelZoom)
			self:diffuse(color(seraphicLabelColor)):settext("")
		end,
		FilterResultsMessageCommand = function(self, msg)
			self:settext(tostring(translated_info["Matches"]):upper())
		end
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(rightValueX, rowMid(7)):zoom(valueZoom):halign(1):maxwidth(rightValueW / valueZoom):settext("")
			self:diffuse(color(seraphicValueColor))
		end,
		FilterResultsMessageCommand = function(self, msg)
			self:settextf("%i/%i", msg.Matches, msg.Total)
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		BeginCommand = function(self)
			self:xy(rightLabelX, rowMid(8)):zoom(labelZoom):halign(0):maxwidth((rightW - 16) / labelZoom)
			self:diffuse(color(seraphicLabelColor))
			self.packlistFiltering = FILTERMAN:GetFilteringCommonPacks()
			self.enabled = SCREENMAN:GetTopScreen():GetName() == "ScreenNetSelectMusic"
			if not self.enabled then
				self:visible(false)
			end
			self:queuecommand("Set")
		end,
		MouseDownCommand = function(self, params)
			if self.enabled and params.event == "DeviceButton_left mouse button" and active then
				self.packlistFiltering = whee:SetPackListFiltering(not self.packlistFiltering)
				self:queuecommand("Set")
			end
		end,
		SetCommand = function(self)
			self:settextf("%s : %s", tostring(translated_info["CommonPackFilter"]):upper(), (self.packlistFiltering and translated_info["On"] or translated_info["Off"]))
		end,
		FilterModeChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		ResetFilterMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}
}

local function CreateFilterInputBox(i)
	local isWide = i == (#ms.SkillSets + 1) or i == (#ms.SkillSets + 2) -- length / best %
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:y(rowMid(i))
		end,
		-- banded row: label left, two value boxes right
		seraphicRowBand(leftX, -rowH / 2, leftW, rowH, i),
		seraphicBullet(leftX + 6, 0),
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(leftX + 14, 0):halign(0):zoom(labelZoom):maxwidth((box1Right - boxW - leftX - 20) / labelZoom)
				self:diffuse(color(seraphicLabelColor))
			end,
			SetCommand = function(self)
				self:settext(tostring(i == (#ms.SkillSets + 1) and translated_info["Length"] or (i == (#ms.SkillSets + 2) and translated_info["BestPercent"] or ms.SkillSetsTranslated[i])):upper())
			end
		},
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(box1Right):zoomto(boxW, boxH):halign(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and active then
					ActiveSS = i
					activebound = 0
					MESSAGEMAN:Broadcast("NumericInputActive")
					self:diffusealpha(0.1)
					SCREENMAN:set_input_redirected(PLAYER_1, true)
				end
			end,
			SetCommand = function(self)
				if ActiveSS == i and activebound == 0 then
					self:diffuse(color("#9c1428")):diffusealpha(0.55)
				else
					self:diffuse(color("#000000")):diffusealpha(0.6)
				end
			end,
			UpdateFilterMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			NumericInputEndedMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			NumericInputActiveMessageCommand = function(self)
				self:queuecommand("Set")
			end
		},
		seraphicSoftEdge(box1Right - boxW, -boxH / 2, boxW, boxH, 0.14),
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(box1Right - 4):halign(1):maxwidth((boxW - 6) / valueZoom):zoom(valueZoom)
			end,
			SetCommand = function(self)
				local fval = notShit.round(FILTERMAN:GetSSFilter(i, 0), numbersafterthedecimal) -- lower bounds
				local fmtstr = ""
				if i == #ms.SkillSets+2 then
					if numbersafterthedecimal > 0 then
						fmtstr = "%5."..numbersafterthedecimal.."f"
					else
						fmtstr = "%02d."
					end
				else
					fmtstr = "%d"
				end
				self:settextf(fmtstr, fval)
				if fval <= 0 and ActiveSS ~= i then
					self:diffuse(color("#666666"))
				elseif activebound == 0 then
					self:diffuse(color(seraphicValueColor))
				end
			end,
			UpdateFilterMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			NumericInputActiveMessageCommand = function(self)
				self:queuecommand("Set")
			end
		},
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(box2Right):zoomto(boxW, boxH):halign(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and active then
					ActiveSS = i
					activebound = 1
					MESSAGEMAN:Broadcast("NumericInputActive")
					self:diffusealpha(0.1)
					SCREENMAN:set_input_redirected(PLAYER_1, true)
				end
			end,
			SetCommand = function(self)
				if ActiveSS == i and activebound == 1 then
					self:diffuse(color("#9c1428")):diffusealpha(0.55)
				else
					self:diffuse(color("#000000")):diffusealpha(0.6)
				end
			end,
			UpdateFilterMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			NumericInputEndedMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			NumericInputActiveMessageCommand = function(self)
				self:queuecommand("Set")
			end
		},
		seraphicSoftEdge(box2Right - boxW, -boxH / 2, boxW, boxH, 0.14),
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(box2Right - 4):halign(1):maxwidth((boxW - 6) / valueZoom):zoom(valueZoom)
			end,
			SetCommand = function(self)
				local fval = notShit.round(FILTERMAN:GetSSFilter(i, 1), numbersafterthedecimal) -- upper bounds
				local fmtstr = "%5."
				if i == #ms.SkillSets+2 then
					if numbersafterthedecimal > 0 then
						fmtstr = "%5."..numbersafterthedecimal.."f"
					else
						fmtstr = "%02d."
					end
				else
					fmtstr = "%d"
				end
				self:settextf(fmtstr, fval)
				if fval <= 0 and ActiveSS ~= i then
					self:diffuse(color("#666666"))
				elseif activebound == 1 then
					self:diffuse(color(seraphicValueColor))
				end
			end,
			UpdateFilterMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			NumericInputActiveMessageCommand = function(self)
				self:queuecommand("Set")
			end
		}
	}
	return t
end

--reset button: small uppercase LR2 button at the bottom of the right column
f[#f + 1] = seraphicSoftEdge(resetX - resetW / 2, rowMid(10) - boxH / 2, resetW, boxH, 0.14)
f[#f + 1] = UIElements.TextButton(1, 1, "Common Large") .. {
	InitCommand = function(self)
		self:xy(resetX, rowMid(10))
		local txt = self:GetChild("Text")
		local bg = self:GetChild("BG")
		txt:zoom(valueZoom)
		txt:settext(tostring(THEME:GetString("TabFilter", "Reset")):upper())
		txt:diffuse(color(seraphicValueColor))
		bg:zoomto(resetW, boxH):diffuse(color("#000000")):diffusealpha(0.5)
	end,
	RolloverUpdateCommand = function(self, params)
		if params.update == "in" then
			self:diffusealpha(hoverAlpha)
		else
			self:diffusealpha(1)
		end
	end,
	ClickCommand = function(self, params)
		if params.update ~= "OnMouseDown" then return end
		if params.event == "DeviceButton_left mouse button" and active then
			FILTERMAN:ResetAllFilters()
			for i = 1, #ms.SkillSets + 2 do
				SSQuery[0][i] = "0"
				SSQuery[1][i] = "0"
			end
			numbersafterthedecimal = 0
			activebound = 0
			ActiveSS = 0
			MESSAGEMAN:Broadcast("UpdateFilter")
			MESSAGEMAN:Broadcast("ResetFilter")
			MESSAGEMAN:Broadcast("NumericInputEnded")
			SCREENMAN:set_input_redirected(PLAYER_1, false)
			whee:SongSearch("")
		end
	end,
}
--[[
-- apply button
f[#f + 1] = UIElements.TextButton(1, 1, "Common Large") .. {
	InitCommand = function(self)
		self:xy(frameX + frameWidth - 150, frameY + 250 + spacingY * -1)
		local txt = self:GetChild("Text")
		local bg = self:GetChild("BG")
		txt:zoom(0.35)
		txt:settext(THEME:GetString("TabFilter", "Apply"))
		txt:diffuse(getMainColor("positive"))
		bg:zoomto(60, 20)
	end,
	RolloverUpdateCommand = function(self, params)
		if params.update == "in" then
			self:diffusealpha(hoverAlpha)
		else
			self:diffusealpha(1)
		end
	end,
	ClickCommand = function(self, params)
		if params.update ~= "OnMouseDown" then return end
		if params.event == "DeviceButton_left mouse button" and active then
			MESSAGEMAN:Broadcast("NumericInputEnded")
			SCREENMAN:set_input_redirected(PLAYER_1, false)
			whee:SongSearch("")
		end
	end,
}
]]

for i = 1, (#ms.SkillSets + 2) do
	f[#f + 1] = CreateFilterInputBox(i)
end
return f
