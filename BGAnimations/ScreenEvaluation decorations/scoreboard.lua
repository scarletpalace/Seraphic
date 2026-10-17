local maxLines = 9 -- the most scores the window shows (when it is unfolded)
local S = 1.1667 -- the right column was enlarged by this factor
local framex = 600
local framey = 314 -- first row with the window in its "mid" place; the whole list moves with the window
local baseTop = 282 -- top of the score history window in the "mid" layout (see seraResultPanels)
local frameWidth = 236
local spacing = 30 * S

local song = STATSMAN:GetCurStageStats():GetPlayedSongs()[1]

local steps = STATSMAN:GetCurStageStats():GetPlayerStageStats():GetPlayedSteps()[1]
local origTable = getScoresByKey(player)
local score = SCOREMAN:GetMostRecentScore()
local rtTable = getRateTable(origTable) or {}
local hsTable = rtTable[getRate(score)] or {score}
local scoreIndex = getHighScoreIndex(hsTable, score)

local usingSSRSort = PREFSMAN:GetPreference("SortBySSRNormPercent")

if rtTable == nil then
	return {}
end


-- how many rows fit in the window for a fold state of the right column
local function fits(state)
	local g = seraResultPanels(state)
	return math.max(0, math.min(maxLines, math.floor((g.shH - 34) / spacing)))
end
local lines = fits(seraResultPanelState)
local pendingLines = lines -- row count to switch to once the window has moved
local offset = 0 -- scores scrolled past at the top of the list
local function clampOffset()
	offset = math.max(0, math.min(offset, #hsTable - lines))
end
-- the list opens with the score that was just played in view
local function centre()
	offset = (tonumber(scoreIndex) or 1) - math.ceil(lines / 2)
	clampOffset()
end
centre()

local function scroll(n)
	local old = offset
	offset = offset + n
	clampOffset()
	if offset ~= old then
		MESSAGEMAN:Broadcast("SeraScoreHistoryPage")
	end
end

--Input event for mouse clicks
local function input(event)
	local scoreBoard = SCREENMAN:GetTopScreen():GetChildren().scoreBoard

	if event.type == "InputEventType_FirstPress" and scoreBoard then
		if event.button == "MenuLeft" then
			scroll(-math.max(1, lines))
		end

		if event.button == "MenuRight" then
			scroll(math.max(1, lines))
		end

		if event.DeviceInput.button == "DeviceButton_mousewheel up" then
			MESSAGEMAN:Broadcast("WheelUpSlow")
		elseif event.DeviceInput.button == "DeviceButton_mousewheel down" then
			MESSAGEMAN:Broadcast("WheelDownSlow")
		end

	end
	return false
end

local t = Def.ActorFrame {
	Name = "scoreBoard",
	InitCommand = function(self)
		self:y(seraResultPanels(seraResultPanelState).shTop - baseTop)
	end,
	OnCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	-- the window grew or folded: slide along with it, then show as many rows as now fit
	-- (rows are added once the window has opened, removed right away when it folds)
	SeraRightPanelMessageCommand = function(self, params)
		local n = fits(params.state)
		self:stoptweening():decelerate(0.2):y(seraResultPanels(params.state).shTop - baseTop)
		pendingLines = n
		if n > lines then
			self:queuecommand("Fold")
		else
			self:playcommand("Fold")
		end
	end,
	FoldCommand = function(self)
		lines = pendingLines
		centre()
		MESSAGEMAN:Broadcast("SeraScoreHistoryPage")
	end
}

local function scoreitem(pn, drawindex)
	local index = offset + drawindex + 1

	--Whether the score at index is the score that was just played.
	local equals = (index == scoreIndex)

	--
	local t = Def.ActorFrame {
		Name = "scoreItem" .. tostring(drawindex),
		ShowCommand = function(self)
			self:playcommand("Begin")
			self:x(100)
			self:diffusealpha(0)
			self:finishtweening()
			self:sleep((drawindex)*0.03)
			self:linear(0.3)
			self:x(0)
			self:diffusealpha(1)
		end,
		HideCommand = function(self)
			self:stoptweening()
			self:linear(0.1)
			self:diffusealpha(0)
			self:x(SCREEN_WIDTH*10)
		end,
		SeraScoreHistoryPageMessageCommand = function(self)
			index = offset + drawindex + 1
			equals = (index == scoreIndex)
			if drawindex < lines and hsTable[index] ~= nil then
				self:playcommand("Show")
			else
				self:playcommand("Hide")
			end

			-- we won't have a score selected upon changing the page so make sure the highlights go away at first
			self:GetParent():GetParent():playcommand("HahaThisCodeINeedHelp", {doot = nil})
		end,
		BeginCommand = function(self)
			if drawindex >= lines or hsTable[index] == nil then
				self:playcommand("Hide")
			end
		end,
		--The main quad (LR2 style: alternating dark row bands)
		Def.Quad {
			InitCommand = function(self)
				self:xy(framex - 10, framey + (drawindex * spacing) - 4):zoomto(frameWidth + 10, 30 * S):halign(0):valign(0)
				self:diffuse(color("#000000")):diffusealpha(drawindex % 2 == 0 and 0.4 or 0.15)
			end,
			BeginCommand = function(self)
				self:visible(GAMESTATE:IsHumanPlayer())
			end
		},
		--Highlight quad for the current score
		Def.Quad {
			InitCommand = function(self)
				self:xy(framex - 10, framey + (drawindex * spacing) - 4):zoomto(frameWidth + 10, 30 * S):halign(0):valign(0)
				self:diffuseleftedge(color("#9c142866")):diffuserightedge(color("#9c142808"))
			end,
			HahaThisCodeINeedHelpCommand = function(self, params)
				local equis = params.doot == index
				self:visible(GAMESTATE:IsHumanPlayer() and equis)
			end,
			BeginCommand = function(self)
				self:visible(GAMESTATE:IsHumanPlayer() and equals)
			end
		},
		--Quad that will act as the bounding box for mouse rollover/click stuff.
		UIElements.QuadButton(1, 1) .. {
			Name = "mouseOver",
			InitCommand = function(self)
				self:xy(framex, framey + (drawindex * spacing) - 4):zoomto(frameWidth, 30 * S):halign(0):valign(0):diffuse(
					color("#ffffff")
				):diffusealpha(0)
			end,
			MouseDownCommand = function(self, params)
				local now = GetTimeSinceStart()
				if self.seraLastDown and now - self.seraLastDown < 0.1 then return end
				self.seraLastDown = now
				if params.event == "DeviceButton_left mouse button" then
					local p = self:GetParent()
					local grade = p:GetChild("grade")
					local judge = p:GetChild("judge")
					local date = p:GetChild("date")
					local option = p:GetChild("option")
					local cleartype = p:GetChild("ClearType")

					grade:visible(not grade:GetVisible())
					judge:visible(not judge:GetVisible())
					date:visible(not date:GetVisible())
					option:visible(not option:GetVisible())
					cleartype:visible(not cleartype:GetVisible())

					local score = hsTable[index]
					if score ~= nil then
						if not score:HasReplayData() then return end
						newindex = getHighScoreIndex(hsTable, hsTable[index])
						self:GetParent():GetParent():playcommand("HahaThisCodeINeedHelp", {doot = newindex})
						self:GetParent():GetParent():GetParent():GetChild("ScoreDisplay"):playcommand("ChangeScore", {score =  hsTable[index]})
						self:GetParent():GetParent():GetParent():GetChild("OffsetPlot"):playcommand("SetFromScore", {score =  hsTable[index]})
					end
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(0.08)
			end,
			MouseOutCommand = function(self)
				local p = self:GetParent()
				local grade = p:GetChild("grade")
				local judge = p:GetChild("judge")
				local date = p:GetChild("date")
				local option = p:GetChild("option")
				local cleartype = p:GetChild("ClearType")
				self:diffusealpha(0)
				grade:visible(true)
				judge:visible(true)
				date:visible(false)
				cleartype:visible(true)
				option:visible(false)
			end,
		},
		--ClearType lamps
		Def.Quad {
			InitCommand = function(self)
				self:xy(framex, framey + (drawindex * spacing) - 4):zoomto(3, 30 * S):halign(0):valign(0)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				self:visible(GAMESTATE:IsHumanPlayer()):diffuse(
					getClearTypeFromScore(pn, hsTable[index], 2))
			end
		},
		--rank
		LoadFont("Common normal") .. {
			InitCommand = function(self)
				self:xy(framex - 5, framey + 12 * S + (drawindex * spacing)):zoom(0.34):diffuse(color(seraphicLabelColor))
			end,
			HahaThisCodeINeedHelpCommand = function(self, params)
				if params.doot == index then
					self:diffuse(color("#ffcccc"))
				else
					self:diffuse(color(seraphicLabelColor))
				end
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				if #hsTable >= 1 then
					self:settext(index)
					if equals then
						self:diffuse(color("#ffcccc"))
					else
						self:stopeffect()
					end
				end
			end
		},
		-- Wife grade and %score
		LoadFont("Common normal") .. {
			Name = "grade",
			InitCommand = function(self)
				self:xy(framex + 8, framey + 11 * S + (drawindex * spacing)):zoom(0.36):halign(0):maxwidth((frameWidth - 90) / 0.36)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				local wv = hsTable[index]:GetWifeVers()
				local wstring = "Wife" .. wv
				if usingSSRSort then
					wstring = "Wife" .. wv .. " J4"
				end
				if hsTable[index]:GetWifeScore() == 0 then
					self:settextf("NA (%s)", wstring)
				else
					local perc = hsTable[index]:GetWifeScore() * 100
					if perc > 99.65 then
						self:settextf("%05.4f%% (%s)", notShit.floor(perc, 4), wstring)
					else
						self:settextf("%05.2f%% (%s)", notShit.floor(perc, 2), wstring)
					end
				end
			end
		},
		--mods
		LoadFont("Common normal") .. {
			Name = "option",
			InitCommand = function(self)
				self:xy(framex + 8, framey + 11 * S + (drawindex * spacing)):zoom(0.36):halign(0):maxwidth((frameWidth - 90) / 0.36)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				self:settext(getModifierTranslations(hsTable[index]:GetModifiers()))
				self:visible(false)
			end
		},
		--grade text
		LoadFont("Common normal") .. {
			Name = "Grade",
			InitCommand = function(self)
				self:xy(framex + frameWidth * 0.818, framey + 2 * S + (drawindex * spacing)):zoom(0.36):halign(0.5):maxwidth(76 / 0.36)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				if #hsTable >= 1 and index >= 1 then
					self:settext(getGradeStrings(hsTable[index]:GetWifeGrade()))
					self:diffuse(getGradeColor(hsTable[index]:GetWifeGrade()))
				end
			end
		},
		--cleartype text
		LoadFont("Common normal") .. {
			Name = "ClearType",
			InitCommand = function(self)
				self:xy(framex + frameWidth * 0.818, framey + 12 * S + (drawindex * spacing)):zoom(0.36):halign(0.5):maxwidth(76 / 0.36)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				if #hsTable >= 1 and index >= 1 then
					self:settext(getClearTypeFromScore(pn, hsTable[index], 0))
					self:diffuse(getClearTypeFromScore(pn, hsTable[index], 2))
				end
			end
		},
		--max combo
		LoadFont("Common normal") .. {
			InitCommand = function(self)
				self:xy(framex + frameWidth * 0.818, framey + 22 * S + (drawindex * spacing)):zoom(0.36):halign(0.5):maxwidth(76 / 0.36)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				if #hsTable >= 1 and index >= 1 then
					self:settextf("%sx", hsTable[index]:GetMaxCombo())
				end
			end
		},
		--judgment
		LoadFont("Common normal") .. {
			Name = "judge",
			InitCommand = function(self)
				self:xy(framex + 8, framey + 20 * S + (drawindex * spacing)):zoom(0.36):halign(0):maxwidth((frameWidth - 90) / 0.36)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				if #hsTable >= 1 and index >= 1 then
					self:settextf(
						"%d | %d | %d | %d | %d | %d",
						hsTable[index]:GetTapNoteScore("TapNoteScore_W1"),
						hsTable[index]:GetTapNoteScore("TapNoteScore_W2"),
						hsTable[index]:GetTapNoteScore("TapNoteScore_W3"),
						hsTable[index]:GetTapNoteScore("TapNoteScore_W4"),
						hsTable[index]:GetTapNoteScore("TapNoteScore_W5"),
						hsTable[index]:GetTapNoteScore("TapNoteScore_Miss")
					)
				end
			end
		},
		--date
		LoadFont("Common normal") .. {
			Name = "date",
			InitCommand = function(self)
				self:xy(framex + 8, framey + 20 * S + (drawindex * spacing)):zoom(0.36):halign(0):maxwidth((frameWidth - 90) / 0.36)
			end,
			BeginCommand = function(self)
				if hsTable[index] == nil then return end
				if #hsTable >= 1 and index >= 1 then
					self:settext(getScoreDate(hsTable[index]))
				end
				self:visible(false)
			end
		}
	}
	return t
end

for drawindex = 0, maxLines - 1 do
	t[#t+1] = scoreitem(player, drawindex)
end

t[#t+1] = Def.Quad {
	InitCommand = function(self)
		self:xy(framex - 20,framey - 20)
		self:valign(0):halign(0)
		self:diffusealpha(0)
		self:zoomto(20 + frameWidth, 20 + spacing * lines)
	end,
	SeraScoreHistoryPageMessageCommand = function(self)
		self:zoomto(20 + frameWidth, 20 + spacing * lines)
	end,
	WheelUpSlowMessageCommand = function(self)
		if isOver(self) then
			scroll(-1)
		end
	end,
	WheelDownSlowMessageCommand = function(self)
		if isOver(self) then
			scroll(1)
		end
	end,
}

-- Seraphic: hover + click for the score entries, driven by isOver() polling and our own input callback
-- (the BUTTON MouseOver/MouseDown events never reached these quads on the results screen)
-- an ActorFrame, not a plain Actor: only frames have SetUpdateFunction
t[#t+1] = Def.ActorFrame {
	OnCommand = function(self)
		local root = self:GetParent()
		local function each(fn)
			for i = 0, maxLines - 1 do
				local item = root:GetChild("scoreItem" .. i)
				local b = item and item:GetChild("mouseOver")
				if b then fn(b) end
			end
		end
		self:SetUpdateFunction(function()
			each(function(b)
				local over = isOver(b)
				if over ~= b.seraOver then
					b.seraOver = over
					b:playcommand(over and "MouseOver" or "MouseOut")
				end
			end)
		end)
		SCREENMAN:GetTopScreen():AddInputCallback(function(event)
			if event.type == "InputEventType_FirstPress" and event.DeviceInput.button == "DeviceButton_left mouse button" then
				each(function(b)
					if isOver(b) then
						b:playcommand("MouseDown", {event = "DeviceButton_left mouse button"})
					end
				end)
			end
			return false
		end)
	end
}

return t
