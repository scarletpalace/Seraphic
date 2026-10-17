local t = Def.ActorFrame {}
local inMulti = Var("LoadingScreen") == "ScreenNetEvaluation"

if GAMESTATE:GetNumPlayersEnabled() == 1 then
	if inMulti then
		t[#t + 1] = LoadActor("MPscoreboard")
	else
		t[#t + 1] = LoadActor("scoreboard")
	end
end

--[[
	This needs a rewrite so that there is a single point of entry for choosing the displayed score, rescoring it, and changing its judge.
	We "accidentally" started using inconsistent methods of communicating between actors and files due to lack of code design.
	The primary rescore function is hiding in the function responsible for displaying the graphs, which may or may not be called by random code everywhere.
]]

local translated_info = {
	CCOn = THEME:GetString("ScreenEvaluation", "ChordCohesionOn"),
	MAPARatio = THEME:GetString("ScreenEvaluation", "MAPARatio")
}

-- im going to cry
local aboutToForceWindowSettings = false

local function scaleToJudge(scale)
	scale = notShit.round(scale, 2)
	local scales = ms.JudgeScalers
	local out = 4
	for k,v in pairs(scales) do
		if v == scale then
			out = k
		end
	end
	return out
end

local judge = PREFSMAN:GetPreference("SortBySSRNormPercent") and 4 or GetTimingDifficulty()
local judge2 = judge
local score = SCOREMAN:GetMostRecentScore()
if not score then
	score = SCOREMAN:GetTempReplayScore()
end
local dvt = {}
local totalTaps = 0
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats()

local frameX = 20
local frameY = 147
local frameWidth = 256

-- Seraphic: IIDX-style left column, laid out in screen coordinates
local LX, LW = 19.4, 243 -- left / width of the column contents
local PREVX, SEPX, NOWX = LX + 128, LX + 170, LX + 210 -- "best | this play" cells of the compare rows
-- (the column sits at the bottom of the screen, under the song data line in the same window)
local optionY = 176
local rowY = {clear = 192, level = 208, score = 226, scoreSub = 241, miss = 254, rating = 270}
local judgeHeadY, judgeY0, judgeStep = 286, 298, 14
local comboY, ratioY = 384, 395
local statsY0, statsStep = 409, 9
local fastColor, slowColor = color("#7cc4ff"), color("#ffa060")

-- dont default to using custom windows and dont persist that state
-- custom windows are meant to be used as a thing you occasionally check, not the primary way to play the game
local usingCustomWindows = false

--ScoreBoard
local judges = {
	"TapNoteScore_W1",
	"TapNoteScore_W2",
	"TapNoteScore_W3",
	"TapNoteScore_W4",
	"TapNoteScore_W5",
	"TapNoteScore_Miss"
}

-- Seraphic: pack name at the top of the middle, under a small crimson point
t[#t + 1] = Def.ActorFrame {
	Name = "PackTitle",
	InitCommand = function(self)
		self:xy(SCREEN_CENTER_X, 13)
	end,
	OnCommand = function(self)
		local song = GAMESTATE:GetCurrentSong()
		local txt = self:GetChild("Text")
		txt:settext(song and song:GetGroupName() or "")
		-- the side rules start just outside the text
		local half = txt:GetZoomedWidth() / 2 + 8
		self:GetChild("LeftRule"):x(-half)
		self:GetChild("RightRule"):x(half)
		self:diffusealpha(0):decelerate(0.4):diffusealpha(1)
	end,
	Def.Quad {
		InitCommand = function(self)
			-- centred on the screen's top edge, so only its lower half shows as a small point above the text
			self:y(-13):rotationz(45):zoomto(12, 12):diffuse(color("#9c1428")):diffusealpha(0.9)
		end
	},
	Def.Quad {
		Name = "LeftRule",
		InitCommand = function(self)
			self:y(6):halign(1):zoomto(110, 1)
			self:diffuseleftedge(color("#ffffff00")):diffuserightedge(color("#ffffff60"))
		end
	},
	Def.Quad {
		Name = "RightRule",
		InitCommand = function(self)
			self:y(6):halign(0):zoomto(110, 1)
			self:diffuseleftedge(color("#ffffff60")):diffuserightedge(color("#ffffff00"))
		end
	},
	LoadFont("Seraphic Title") .. {
		Name = "Text",
		InitCommand = function(self)
			-- sits low enough that the crimson point never touches it
			self:y(6):zoom(0.5):maxwidth(300 / 0.5):diffuse(color(seraphicValueColor))
		end
	}
}

-- Seraphic: song title (with the rate next to it) and artist under the banner, over a soft dark pool
t[#t + 1] = Def.ActorFrame {
	Name = "SongHead",
	InitCommand = function(self)
		self:xy(SCREEN_CENTER_X, 140)
	end,
	BeginCommand = function(self)
		self:queuecommand("Set")
	end,
	ScoreChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	SetCommand = function(self)
		local song = GAMESTATE:GetCurrentSong()
		local title, rateText = self:GetChild("Title"), self:GetChild("Rate")
		title:settext(song and song:GetDisplayMainTitle() or "")
		self:GetChild("Artist"):settext(song and song:GetDisplayArtist() or "")
		local rate = 1
		pcall(function()
			local top = SCREENMAN:GetTopScreen()
			if top:GetName() == "ScreenNetEvaluation" then
				rate = score:GetMusicRate()
			else
				rate = top:GetReplayRate() or getCurRateValue()
			end
		end)
		rateText:settext(getRateString(notShit.round(rate, 3)))
		-- title and rate are centred together
		local tw, rw, gap = title:GetZoomedWidth(), rateText:GetZoomedWidth(), 6
		local left = -(tw + gap + rw) / 2
		title:x(left + tw / 2)
		rateText:x(left + tw + gap)
	end,
	Def.Quad {
		InitCommand = function(self)
			self:y(8):halign(1):zoomto(160, 42)
			self:diffuseleftedge(color("#00000000")):diffuserightedge(color("#000000B0"))
			self:fadetop(0.3):fadebottom(0.3)
		end
	},
	Def.Quad {
		InitCommand = function(self)
			self:y(8):halign(0):zoomto(160, 42)
			self:diffuseleftedge(color("#000000B0")):diffuserightedge(color("#00000000"))
			self:fadetop(0.3):fadebottom(0.3)
		end
	},
	LoadFont("Seraphic Artist") .. {
		Name = "Title",
		InitCommand = function(self)
			self:zoom(0.62):maxwidth(260 / 0.62)
		end
	},
	LoadFont("Seraphic Artist") .. {
		Name = "Rate",
		InitCommand = function(self)
			self:halign(0):y(1):zoom(0.42):diffuse(color("#e8b8c2"))
		end
	},
	LoadFont("Seraphic Artist") .. {
		Name = "Artist",
		InitCommand = function(self)
			self:y(17):zoom(0.44):maxwidth(290 / 0.44):diffuse(color("#bdbdbd"))
		end
	}
}

-- Seraphic: online leaderboard at the rate that was played, top right: this score's place in a small window,
-- and under it a scrollable list of the players around it
do
	local lbRows, lbStep, lbY0 = 15, 14, 90
	local lbOffset = 0
	local lbList = {}
	local lbScrolled = false -- the list centres on your score until you scroll it yourself
	local playedRate = 1
	pcall(function() playedRate = score:GetMusicRate() end)

	-- this chart's online scores at the played rate, best first, plus the index of your best one
	local function rateBoard()
		if not DLMAN:IsLoggedIn() then return nil end
		local steps = GAMESTATE:GetCurrentSteps()
		local lb = steps and DLMAN:GetChartLeaderBoard(steps:GetChartKey())
		if not lb then return {} end
		local want = string.format("%.2f", playedRate)
		local list, mine = {}, nil
		local me = DLMAN:GetUsername()
		for _, hs in ipairs(lb) do
			if string.format("%.2f", hs:GetMusicRate()) == want then
				list[#list + 1] = hs
				if not mine and hs:GetDisplayName() == me then mine = #list end
			end
		end
		return list, mine
	end
	local function rankText(list, mine)
		if not list then return "NOT LOGGED IN", nil end
		if #list == 0 then return "-", nil end
		if mine then return string.format("#%d", mine), string.format("of %d", #list) end
		return "UNRANKED", string.format("of %d", #list)
	end

	t[#t + 1] = Def.ActorFrame {
		Name = "OnlineRank",
		InitCommand = function(self)
			self:xy(590, 40)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
			-- ask again a little later, so the score just uploaded is on the board
			self:sleep(0.2):queuecommand("Request"):sleep(5):queuecommand("Request")
		end,
		RequestCommand = function(self)
			pcall(function()
				if not DLMAN:IsLoggedIn() then return end
				DLMAN:RequestChartLeaderBoardFromOnline(GAMESTATE:GetCurrentSteps():GetChartKey(), function()
					self:queuecommand("Set")
				end)
			end)
		end,
		SetCommand = function(self)
			local ok, list, mine = pcall(rateBoard)
			if not ok then list, mine = {}, nil end
			local main, sub = rankText(list, mine)
			self:GetChild("Value"):settext(main)
			self:GetChild("Of"):settext(sub or "")
			MESSAGEMAN:Broadcast("SeraLeaderboardData")
		end,
		LoginMessageCommand = function(self)
			self:queuecommand("Request")
		end,
		seraphicBullet(-3, 0),
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:x(4):halign(0):zoom(0.34):diffuse(color(seraphicLabelColor))
				self:settext("ONLINE RANK  " .. getRateString(notShit.round(playedRate, 3)))
			end
		},
		LoadFont("Common Normal") .. {
			Name = "Of",
			InitCommand = function(self)
				self:x(246):halign(1):zoom(0.32):diffuse(color("#8f8588"))
			end
		},
		LoadFont("Common Large") .. {
			Name = "Value",
			InitCommand = function(self)
				self:x(196):halign(1):zoom(0.3):maxwidth(110 / 0.3):diffuse(color(seraphicValueColor))
			end
		}
	}

	-- header in the same style as the other windows (seraHeader is defined further down)
	t[#t + 1] = Def.ActorFrame {
		seraphicHeaderBand(590, 64, 246, 16),
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(594, 72):halign(0):valign(0.5):zoom(0.45):maxwidth(238 / 0.45)
				self:settext(seraphicHeading("LEADERBOARD")):diffuse(color(seraphicLabelColor))
			end
		}
	}
	local board = Def.ActorFrame {
		Name = "RateLeaderboard",
		BeginCommand = function(self)
			-- mouse wheel over the list scrolls it
			SCREENMAN:GetTopScreen():AddInputCallback(function(event)
				if event.type ~= "InputEventType_FirstPress" then return false end
				local b = event.DeviceInput.button
				local dir = (b == "DeviceButton_mousewheel up" and -1) or (b == "DeviceButton_mousewheel down" and 1) or 0
				if dir ~= 0 and isOver(self:GetChild("Hover")) then
					lbScrolled = true
					lbOffset = lbOffset + dir
					self:playcommand("Refresh")
				end
				return false
			end)
		end,
		SeraLeaderboardDataMessageCommand = function(self)
			self:playcommand("Refresh")
		end,
		-- works out the visible slice, then the rows redraw themselves with Set
		RefreshCommand = function(self)
			local ok, list, mine = pcall(rateBoard)
			if not ok then list = {} end
			list = list or {}
			if not lbScrolled and mine then lbOffset = mine - math.ceil(lbRows / 2) end
			lbOffset = math.max(0, math.min(lbOffset, #list - lbRows))
			lbList = list
			local msg = self:GetChild("Empty")
			if not DLMAN:IsLoggedIn() then
				msg:settext("Log in to see the leaderboard")
			elseif #list == 0 then
				msg:settext("No online scores at this rate yet")
			else
				msg:settext("")
			end
			self:GetChild("Scroll"):visible(#list > lbRows)
			if #list > lbRows then
				local trackH = lbRows * lbStep
				local h = math.max(8, trackH * lbRows / #list)
				self:GetChild("Scroll"):zoomy(h):y(lbY0 - lbStep / 2 + (trackH - h) * lbOffset / (#list - lbRows))
			end
			self:playcommand("Set")
		end,
		-- hover area for the mouse wheel
		Def.Quad {
			Name = "Hover",
			InitCommand = function(self)
				self:xy(586, lbY0 - lbStep / 2):halign(0):valign(0):zoomto(254, lbRows * lbStep):diffusealpha(0)
			end
		},
		LoadFont("Common Normal") .. {
			Name = "Empty",
			InitCommand = function(self)
				self:xy(713, lbY0 + lbStep * 3):zoom(0.34):diffuse(color("#8f8588"))
			end
		},
		-- thin scroll position bar on the right edge
		Def.Quad {
			Name = "Scroll",
			InitCommand = function(self)
				self:x(838):valign(0):zoomto(2, 10):diffuse(color("#ffffff")):diffusealpha(0.35):visible(false)
			end
		}
	}
	for r = 1, lbRows do
		local y = lbY0 + (r - 1) * lbStep
		board[#board + 1] = Def.ActorFrame {
			Name = "Row" .. r,
			SetCommand = function(self)
				local i = lbOffset + r
				local hs = lbList[i]
				self:visible(hs ~= nil)
				if not hs then return end
				local mineRow = hs:GetDisplayName() == DLMAN:GetUsername()
				self:GetChild("Mine"):visible(mineRow)
				self:GetChild("Rank"):settextf("%d", i)
				self:GetChild("Name"):settext(hs:GetDisplayName()):diffuse(color(mineRow and "#ffffff" or seraphicValueColor))
				local okS, ssr = pcall(function() return hs:GetSkillsetSSR("Overall") end)
				if okS and ssr then
					self:GetChild("SSR"):settextf("%5.2f", ssr):diffuse(byMSD(ssr))
				else
					self:GetChild("SSR"):settext("")
				end
				self:GetChild("Pct"):settextf("%05.2f%%", notShit.floor(hs:GetWifeScore() * 100, 2)):diffuse(byGrade(hs:GetWifeGrade()))
			end,
			Def.Quad {
				InitCommand = function(self)
					self:xy(588, y):halign(0):zoomto(248, lbStep - 1):diffuse(color("#000000")):diffusealpha(r % 2 == 1 and 0.4 or 0.18)
				end
			},
			-- your own score: crimson band
			Def.Quad {
				Name = "Mine",
				InitCommand = function(self)
					self:xy(588, y):halign(0):zoomto(248, lbStep - 1)
					self:diffuseleftedge(color("#9c1428D0")):diffuserightedge(color("#9c142840")):visible(false)
				end
			},
			LoadFont("Common Normal") .. {
				Name = "Rank",
				InitCommand = function(self)
					self:xy(616, y):halign(1):zoom(0.32):diffuse(color(seraphicLabelColor))
				end
			},
			LoadFont("Common Normal") .. {
				Name = "Name",
				InitCommand = function(self)
					self:xy(622, y):halign(0):zoom(0.34):maxwidth(110 / 0.34)
				end
			},
			LoadFont("Common Normal") .. {
				Name = "SSR",
				InitCommand = function(self)
					self:xy(772, y):halign(1):zoom(0.32)
				end
			},
			LoadFont("Common Normal") .. {
				Name = "Pct",
				InitCommand = function(self)
					self:xy(832, y):halign(1):zoom(0.34)
				end
			}
		}
	end
	t[#t + 1] = board
end

-- a helper to get the radar value for a score and fall back to playerstagestats if that fails
local function gatherRadarValue(radar, score)
    local n = score:GetRadarValues():GetValue(radar)
    if n == -1 then
        return pss:GetRadarActual():GetValue(radar)
    end
    return n
end

local function getRescoreElements(score)
	local o = {}
	o["dvt"] = dvt
    o["totalHolds"] = pss:GetRadarPossible():GetValue("RadarCategory_Holds") + pss:GetRadarPossible():GetValue("RadarCategory_Rolls")
	o["holdsHit"] = gatherRadarValue("RadarCategory_Holds", score) + gatherRadarValue("RadarCategory_Rolls", score)
	if o["totalHolds"] < o["holdsHit"] then
		-- dunno
		o["totalHolds"] = score:GetRadarPossible():GetValue("RadarCategory_Holds") + score:GetRadarPossible():GetValue("RadarCategory_Rolls")
	end
	o["holdsMissed"] = o["totalHolds"] - o["holdsHit"]
    o["minesHit"] = pss:GetRadarPossible():GetValue("RadarCategory_Mines") - gatherRadarValue("RadarCategory_Mines", score)
	o["totalTaps"] = totalTaps
	return o
end
local lastSnapshot = nil

local function scoreBoard(pn, position)
	local dvtTmp = {}
	local tvt = {}
	dvt = {}
	totalTaps = 0

	local function setupNewScoreData(score)
		local replay = usingCustomWindows and REPLAYS:GetActiveReplay() or score:GetReplay()
		replay:LoadAllData()
		local dvtTmp = replay:GetOffsetVector()
		local tvt = replay:GetTapNoteTypeVector()
		-- if available, filter out non taps from the deviation list
		-- (hitting mines directly without filtering would make them appear here)
		if tvt ~= nil and #tvt > 0 then
			dvt = {}
			for i, d in ipairs(dvtTmp) do
				local ty = tvt[i]
				if ty == "TapNoteType_Tap" or ty == "TapNoteType_HoldHead" or ty == "TapNoteType_Lift" then
					dvt[#dvt+1] = d
				end
			end
		else
			dvt = dvtTmp
		end

		totalTaps = 0
		for k, v in ipairs(judges) do
			totalTaps = totalTaps + score:GetTapNoteScore(v)
		end
	end
	setupNewScoreData(score)

	-- we removed j1-3 so uhhh this stops things lazily
	local function clampJudge()
		if judge < 4 then judge = 4 end
		if judge > 9 then judge = 9 end
	end
	clampJudge()

	local t = Def.ActorFrame {
		Name = "ScoreDisplay",
		BeginCommand = function(self)
			if position == 1 then
				self:x(SCREEN_WIDTH - (frameX * 2) - frameWidth)
			end
			if PREFSMAN:GetPreference("SortBySSRNormPercent") then
				judge = 4
				judge2 = judge
				-- you ever hack something so hard?
				aboutToForceWindowSettings = true
				MESSAGEMAN:Broadcast("ForceWindow", {judge=4})
				MESSAGEMAN:Broadcast("RecalculateGraphs", {judge=4})
				MESSAGEMAN:Broadcast("LoadScoreInOffsetPlot", {score = score})
			else
				judge = scaleToJudge(SCREENMAN:GetTopScreen():GetReplayJudge())
				clampJudge()
				judge2 = judge
				MESSAGEMAN:Broadcast("ForceWindow", {judge=judge})
				MESSAGEMAN:Broadcast("RecalculateGraphs", {judge=judge})
				MESSAGEMAN:Broadcast("LoadScoreInOffsetPlot", {score = score})
			end
		end,
		ChangeScoreCommand = function(self, params)
			if params.score then
				score = params.score
				if usingCustomWindows then
					-- this is done very carefully to rescore a newly selected score once for wife3 and once for custom rescoring
					unloadCustomWindowConfig()
					usingCustomWindows = false
					setupNewScoreData(score)
					MESSAGEMAN:Broadcast("ScoreChanged")
					usingCustomWindows = true
					loadCurrentCustomWindowConfig()
					setupNewScoreData(score)
				else
					setupNewScoreData(score)
				end
			end

			if usingCustomWindows then
				lastSnapshot = REPLAYS:GetActiveReplay():GetLastReplaySnapshot()
				self:playcommand("MoveCustomWindowIndex", {direction = 0})
			else
				MESSAGEMAN:Broadcast("ScoreChanged")
			end
		end,
		UpdateNetEvalStatsMessageCommand = function(self)
			local s = SCREENMAN:GetTopScreen():GetHighScore()
			if s then
				score = s
			end
			local replay = score:GetReplay()
			replay:LoadAllData()
			local dvtTmp = replay:GetOffsetVector()
			local tvt = replay:GetTapNoteTypeVector()
			-- if available, filter out non taps from the deviation list
			-- (hitting mines directly without filtering would make them appear here)
			if tvt ~= nil and #tvt > 0 then
				dvt = {}
				for i, d in ipairs(dvtTmp) do
					local ty = tvt[i]
					if ty == "TapNoteType_Tap" or ty == "TapNoteType_HoldHead" or ty == "TapNoteType_Lift" then
						dvt[#dvt+1] = d
					end
				end
			else
				dvt = dvtTmp
			end
			totalTaps = 0
			for k, v in ipairs(judges) do
				totalTaps = totalTaps + score:GetTapNoteScore(v)
			end
			MESSAGEMAN:Broadcast("ScoreChanged")
		end,

		Def.Quad {
			Name = "DisplayBG",
			InitCommand = function(self)
				self:visible(false)
				self:xy(frameX - 5, frameY + 5)
				self:zoomto(frameWidth + 10, 217)
				self:halign(0):valign(0)
				self:diffuse(getMainColor("tabs")):diffusetopedge(panelTopColor())
			end,
		},
		Def.ActorFrame {
			Name = "CustomScoringDisplay",
			InitCommand = function(self)
				self:xy(LX + 10, rowY.score + 9)
				self:visible(usingCustomWindows)
			end,
			ToggleCustomWindowsMessageCommand = function(self)
				if inMulti then return end
				usingCustomWindows = not usingCustomWindows

				self:visible(usingCustomWindows)
				self:GetParent():GetChild("GraphDisplayP1"):visible(not usingCustomWindows)
				self:GetParent():GetChild("ComboGraphP1"):visible(not usingCustomWindows)
				if not usingCustomWindows then
					unloadCustomWindowConfig()
					MESSAGEMAN:Broadcast("UnloadedCustomWindow")
					MESSAGEMAN:Broadcast("RecalculateGraphs", {judge=judge})
					self:GetParent():playcommand("ChangeScore", {score = score})
					MESSAGEMAN:Broadcast("SetFromDisplay", {score = score})
					MESSAGEMAN:Broadcast("ForceWindow", {judge=judge})
				else
					loadCurrentCustomWindowConfig()
					MESSAGEMAN:Broadcast("RecalculateGraphs", {judge=judge})
					lastSnapshot = REPLAYS:GetActiveReplay():GetLastReplaySnapshot()
					self:playcommand("Set")
					MESSAGEMAN:Broadcast("LoadedCustomWindow")
				end
			end,
			EndCommand = function(self)
				unloadCustomWindowConfig()
			end,
			MoveCustomWindowIndexMessageCommand = function(self, params)
				if not usingCustomWindows then return end
				moveCustomWindowConfigIndex(params.direction)
				loadCurrentCustomWindowConfig()
				MESSAGEMAN:Broadcast("RecalculateGraphs", {judge=judge})
				lastSnapshot = REPLAYS:GetActiveReplay():GetLastReplaySnapshot()
				self:playcommand("Set")
				MESSAGEMAN:Broadcast("LoadedCustomWindow")
			end,
			CodeMessageCommand = function(self, params)
				if inMulti then return end
				if params.Name == "Coin" then
					self:playcommand("ToggleCustomWindows")
				end
				if not usingCustomWindows then return end
				if params.Name == "PrevJudge" then
					MESSAGEMAN:Broadcast("MoveCustomWindowIndex", {direction=-1})
				elseif params.Name == "NextJudge" then
					MESSAGEMAN:Broadcast("MoveCustomWindowIndex", {direction=1})
				end
			end,

			UIElements.QuadButton(1, 1) .. {
				Name = "BG",
				InitCommand = function(self)
					self:zoomto(LW - 20, 18)
					self:halign(0):valign(1)
					self:diffuse(getMainColor("tabs")):diffusetopedge(panelTopColor())
				end,
				MouseClickCommand = function(self, params)
					if self:IsVisible() and usingCustomWindows then
						if params.event ~= "DeviceButton_left mouse button" then
							moveCustomWindowConfigIndex(1)
						else
							moveCustomWindowConfigIndex(-1)
						end
						loadCurrentCustomWindowConfig()
						MESSAGEMAN:Broadcast("RecalculateGraphs", {judge=judge})
						lastSnapshot = REPLAYS:GetActiveReplay():GetLastReplaySnapshot()
						self:GetParent():playcommand("Set")
						MESSAGEMAN:Broadcast("LoadedCustomWindow")
					end
				end,
			},
			Def.Quad {
				Name = "SmallHorizontalLine",
				InitCommand = function(self)
					self:xy(0, 0)
					self:zoomto(LW - 20, 1)
					self:halign(0)
					self:diffuse(getMainColor("highlight"))
					self:diffusealpha(0.5)
				end,
			},
			LoadFont("Common Large") .. {
				Name = "CustomPercent",
				InitCommand = function(self)
					self:xy(LW - 22, -9)
					self:zoom(0.36)
					self:halign(1):valign(0.5)
					self:maxwidth((LW - 30) / 0.36)
				end,
				SetCommand = function(self)
					self:diffuse(getGradeColor(score:GetWifeGrade()))
					-- 2 billion should be the last noterow always. just interested in the final score.
					local wife = lastSnapshot:GetWifePercent() * 100
					if wife > 99 then
						self:settextf(
							"%05.4f%% (%s)",
							notShit.floor(wife, 4), getCurrentCustomWindowConfigName()
						)
					else
						self:settextf(
							"%05.2f%% (%s)",
							notShit.floor(wife, 2), getCurrentCustomWindowConfigName()
						)
					end
				end,
			},
		},
		LoadFont("Common Large") .. {
			Name = "MSDDisplay",
			InitCommand = function(self)
				self:xy(PREVX, rowY.rating)
				self:zoom(0.27)
				self:halign(0.5):valign(0.5)
				self:maxwidth(70 / 0.27)
			end,
			BeginCommand = function(self)
				self:queuecommand("Set")
			end,
			ScoreChangedMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			SetCommand = function(self)
				local top = SCREENMAN:GetTopScreen()
				local rate
				if top:GetName() == "ScreenNetEvaluation" then
					rate = score:GetMusicRate()
				else
					rate = top:GetReplayRate()
					if not rate then rate = getCurRateValue() end
				end
				rate = notShit.round(rate,3)
				local meter = GAMESTATE:GetCurrentSteps():GetMSD(rate, 1)
				if meter < 10 then
					self:settextf("%4.2f", meter)
				else
					self:settextf("%5.2f", meter)
				end
				self:diffuse(byMSD(meter))
			end,
		},
		LoadFont("Common Large") .. {
			Name = "SSRDisplay",
			InitCommand = function(self)
				self:xy(NOWX, rowY.rating)
				self:zoom(0.27)
				self:halign(0.5):valign(0.5)
				self:maxwidth(70 / 0.27)
			end,
			BeginCommand = function(self)
				self:queuecommand("Set")
			end,
			ScoreChangedMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			SetCommand = function(self)
				local meter = score:GetSkillsetSSR("Overall")
				self:settextf("%5.2f", meter)
				self:diffuse(byMSD(meter))
			end,
		},
		LoadFont("Common Large") .. {
			Name = "DifficultyName",
			InitCommand = function(self)
				self:xy(LX + 86, rowY.rating)
				self:zoom(0.24)
				self:halign(0.5):valign(0.5)
				self:maxwidth(30 / 0.24)
			end,
			BeginCommand = function(self)
				self:queuecommand("Set")
			end,
			SetCommand = function(self)
				local steps = GAMESTATE:GetCurrentSteps()
				local diff = getDifficulty(steps:GetDifficulty())
				self:settext(getShortDifficulty(diff))
				self:diffuse(getDifficultyColor(GetCustomDifficulty(steps:GetStepsType(), steps:GetDifficulty())))
			end,
		},
		Def.ActorFrame {
			Name = "WifeDisplay",
			ForceWindowMessageCommand = function(self, params)
				self:playcommand("Set")
			end,
			-- Seraphic: the high precision rollover is driven by polling isOver() every frame (the BUTTON
			-- MouseOver/MouseOut events never reached this button on the results screen)
			OnCommand = function(self)
				local bg = self:GetChild("MouseHoverBG")
				self:SetUpdateFunction(function(f)
					local over = isOver(bg)
					if over ~= f.seraOver then
						f.seraOver = over
						f:GetChild("NormalText"):visible(not over)
						f:GetChild("LongerText"):visible(over)
					end
				end)
			end,
			UIElements.QuadButton(1, 1) .. {
				Name = "MouseHoverBG",
				InitCommand = function(self)
					self:xy(LX + LW - 12, rowY.score)
					self:zoomto(175, 18)
					self:halign(1):valign(0.5)
					self:diffusealpha(0)
				end,
				MouseOverCommand = function(self)
					if self:IsVisible() then
						self:GetParent():GetChild("NormalText"):visible(false)
						self:GetParent():GetChild("LongerText"):visible(true)
					end
				end,
				MouseOutCommand = function(self)
					if self:IsVisible() then
						self:GetParent():GetChild("NormalText"):visible(true)
						self:GetParent():GetChild("LongerText"):visible(false)
					end
				end,
				MouseClickCommand = function(self)
					if inMulti then return end
					if self:IsVisible() then
						MESSAGEMAN:Broadcast("ToggleCustomWindows")
					end
				end,
			},
			LoadFont("Common Large") .. {
				Name = "NormalText",
				InitCommand = function(self)
					self:xy(LX + LW - 12, rowY.score)
					self:zoom(0.36)
					self:halign(1):valign(0.5)
					self:maxwidth(175 / 0.36)
					self:visible(true)
				end,
				BeginCommand = function(self)
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					local wv = score:GetWifeVers()
					local js = judge ~= 9 and judge or "ustice"
					local rescoretable = getRescoreElements(score)
					local rescorepercent = getRescoredWife3Judge(3, judge, rescoretable)
					wv = 3 -- this should really only be applicable if we can convert the score
					local ws = "Wife" .. wv .. " J"
					self:diffuse(getGradeColor(score:GetWifeGrade()))
					self:settextf(
						"%05.2f%% (%s)",
						notShit.floor(rescorepercent, 2), ws .. js
					)
				end,
				ScoreChangedMessageCommand = function(self)
					self:queuecommand("Set")
				end,
				CodeMessageCommand = function(self, params)
					if usingCustomWindows then
						return
					end

					local rescoretable = getRescoreElements(score)
					local rescorepercent = 0
					local ws = "Wife3" .. " J"
					if params.Name == "PrevJudge" and judge > 4 then
						judge = judge - 1
						clampJudge()
						rescorepercent = getRescoredWife3Judge(3, judge, rescoretable)
						local pct = notShit.floor(rescorepercent, 2)
						self:diffuse(getGradeColor(GetGradeFromPercent(pct/100)))
						self:settextf(
							"%05.2f%% (%s)", pct, ws .. judge
						)
						MESSAGEMAN:Broadcast("RecalculateGraphs", {judge = judge})
					elseif params.Name == "NextJudge" and judge < 9 then
						judge = judge + 1
						clampJudge()
						rescorepercent = getRescoredWife3Judge(3, judge, rescoretable)
						local js = judge ~= 9 and judge or "ustice"
						local pct = notShit.floor(rescorepercent, 2)
						self:diffuse(getGradeColor(GetGradeFromPercent(pct/100)))
						self:settextf(
							"%05.2f%% (%s)", pct, ws .. js
						)
						MESSAGEMAN:Broadcast("RecalculateGraphs", {judge = judge})
					end
					if params.Name == "ResetJudge" then
						judge = GetTimingDifficulty()
						clampJudge()
						self:playcommand("Set")
						MESSAGEMAN:Broadcast("RecalculateGraphs", {judge = judge})
					end
				end,
			},
			LoadFont("Common Large") ..	{-- high precision rollover
				Name = "LongerText",
				InitCommand = function(self)
					self:xy(LX + LW - 12, rowY.score)
					self:zoom(0.36)
					self:halign(1):valign(0.5)
					self:maxwidth(175 / 0.36)
					self:visible(false)
				end,
				BeginCommand = function(self)
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					local wv = score:GetWifeVers()
					local js = judge ~= 9 and judge or "ustice"
					local rescoretable = getRescoreElements(score)
					local rescorepercent = getRescoredWife3Judge(3, judge, rescoretable)
					wv = 3 -- this should really only be applicable if we can convert the score
					local ws = "Wife" .. wv .. " J"
					self:diffuse(getGradeColor(score:GetWifeGrade()))
					self:settextf(
						"%05.4f%% (%s)",
						notShit.floor(rescorepercent, 4), ws .. js
					)
				end,
				ScoreChangedMessageCommand = function(self)
					self:queuecommand("Set")
				end,
				CodeMessageCommand = function(self, params)
					if usingCustomWindows then
						return
					end

					local rescoretable = getRescoreElements(score)
					local rescorepercent = 0
					local wv = score:GetWifeVers()
					local ws = "Wife3" .. " J"
					if params.Name == "PrevJudge" and judge2 > 4 then
						judge2 = judge2 - 1
						rescorepercent = getRescoredWife3Judge(3, judge2, rescoretable)
						local pct = notShit.floor(rescorepercent, 4)
						self:diffuse(getGradeColor(GetGradeFromPercent(pct/100)))
						self:settextf(
							"%05.4f%% (%s)", pct, ws .. judge2
						)
					elseif params.Name == "NextJudge" and judge2 < 9 then
						judge2 = judge2 + 1
						rescorepercent = getRescoredWife3Judge(3, judge2, rescoretable)
						local js = judge2 ~= 9 and judge2 or "ustice"
						local pct = notShit.floor(rescorepercent, 4)
						self:diffuse(getGradeColor(GetGradeFromPercent(pct/100)))
						self:settextf(
							"%05.4f%% (%s)", pct, ws .. js
						)
					end
					if params.Name == "ResetJudge" then
						judge2 = GetTimingDifficulty()
						self:playcommand("Set")
					end
				end,
			},
		},
		-- play options along the top of the left column
		Def.Quad {
			InitCommand = function(self)
				self:xy(LX, optionY):halign(0):zoomto(LW, 10):diffuse(color("#000000")):diffusealpha(0.4)
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + 4, optionY):halign(0):zoom(0.3):diffuse(color(seraphicLabelColor)):settext("OPTION")
			end
		},
		LoadFont("Common Normal") .. {
			Name = "ModString",
			InitCommand = function(self)
				self:xy(LX + LW - 4, optionY)
				self:zoom(0.32)
				self:halign(1)
				self:maxwidth((LW - 44) / 0.32)
				self:diffuse(color(seraphicValueColor))
			end,
			BeginCommand = function(self)
				self:queuecommand("Set")
			end,
			SetCommand = function(self)
				local mstring = GAMESTATE:GetPlayerState():GetPlayerOptionsString("ModsLevel_Current")
				local ss = SCREENMAN:GetTopScreen():GetStageStats()
				if not ss:GetLivePlay() then
					mstring = SCREENMAN:GetTopScreen():GetReplayModifiers()
				end
				self:settext(getModifierTranslations(mstring))
			end,
			ScoreChangedMessageCommand = function(self)
				local mstring = score:GetModifiers()
				self:settext(getModifierTranslations(mstring))
			end,
		},
		LoadFont("Common Large") .. {
			Name = "ChordCohesionIndicator",
			InitCommand = function(self)
				self:xy(LX + 4, ratioY)
				self:zoom(0.19)
				self:halign(0)
				self:maxwidth(80 / 0.19)
				self:settext(tostring(translated_info["CCOn"]):upper())
				self:diffuse(color(seraphicLabelColor))
				self:visible(false)
			end,
			BeginCommand = function(self)
				self:queuecommand("Set")
			end,
			ScoreChangedMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			SetCommand = function(self)
				if score:GetChordCohesion() then
					self:visible(true)
				else
					self:visible(false)
				end
			end,
		},
	}

	-- Seraphic: IIDX-style FAST / SLOW split per judgment (fast = hit early, slow = hit late), from the replay offsets
	local SLOWX, FASTX = LX + 202, LX + LW - 6
	local fsCache = {}
	local function fastSlow()
		local cfg = ""
		if usingCustomWindows then
			pcall(function() cfg = tostring(getCurrentCustomWindowConfigName()) end)
		end
		local key = tostring(dvt) .. ":" .. #dvt .. ":" .. tostring(judge) .. ":" .. tostring(usingCustomWindows) .. ":" .. cfg
		if fsCache.key == key then return fsCache end
		local w
		if usingCustomWindows then
			pcall(function()
				local tbl = getCurrentCustomWindowConfigJudgmentWindowTable()
				local cw = {}
				for i = 1, 5 do
					cw[i] = tbl["TapNoteScore_W" .. i]
				end
				if #cw == 5 then w = cw end
			end)
		end
		if not w then
			local s = ms.JudgeScalers[judge] or 1
			w = {22.5 * s, 45 * s, 90 * s, 135 * s, math.max(180, 180 * s)}
		end
		local fast, slow = {0, 0, 0, 0, 0}, {0, 0, 0, 0, 0}
		for _, o in ipairs(dvt) do
			local a = math.abs(o)
			if o ~= 0 then
				for j = 1, 5 do
					if a <= w[j] then
						if o < 0 then
							fast[j] = fast[j] + 1
						else
							slow[j] = slow[j] + 1
						end
						break
					end
				end
			end
		end
		local ft, st = 0, 0
		for j = 1, 5 do
			ft = ft + fast[j]
			st = st + slow[j]
		end
		fsCache = {key = key, fast = fast, slow = slow, fastTotal = ft, slowTotal = st, empty = #dvt == 0}
		return fsCache
	end
	-- text for one cell of the FAST / SLOW columns ("" on the miss row, "-" without replay data)
	local function fastSlowText(judgmentIndex, which)
		if judgmentIndex > 5 then return "" end
		local fs = fastSlow()
		if fs.empty then return "-" end
		return tostring(fs[which][judgmentIndex])
	end

	-- judgment counts at the judge currently shown (or the loaded custom windows)
	local function currentCounts()
		local c = {}
		for i, j in ipairs(judges) do
			if usingCustomWindows and lastSnapshot then
				c[i] = lastSnapshot:GetJudgments()[(j:gsub("TapNoteScore_", ""))] or 0
			elseif #dvt > 0 then
				c[i] = getRescoredJudge(dvt, judge, i)
			else
				c[i] = score:GetTapNoteScore(j)
			end
		end
		return c
	end
	-- wife percent at the judge currently shown
	local function currentPercent()
		if usingCustomWindows and lastSnapshot then
			return lastSnapshot:GetWifePercent() * 100
		end
		if #dvt > 0 then
			return getRescoredWife3Judge(3, judge, getRescoreElements(score))
		end
		return score:GetWifeScore() * 100
	end
	-- IIDX "miss count": every judgment that breaks the combo (good, bad, miss), as the clear lamps count it
	local function missCountOf(c)
		return c[4] + c[5] + c[6]
	end
	-- identity of a score: its score key, or its date and percent if the key can't be read
	local function scoreId(s)
		local ok, k = pcall(function() return s:GetScoreKey() end)
		if ok and k then return k end
		return tostring(s:GetDate()) .. ":" .. tostring(s:GetWifeScore())
	end
	-- best other score on this chart at this rate (what IIDX shows on the left of each compare row)
	local function previousBest(cur)
		local best
		pcall(function()
			local byRate = SCOREMAN:GetScoresByKey(cur:GetChartKey())
			local list = byRate and byRate[getRate(cur)]
			local scores = list and list:GetScores()
			if not scores then return end
			local ck = scoreId(cur)
			for _, s in ipairs(scores) do
				if scoreId(s) ~= ck and (not best or s:GetWifeScore() > best:GetWifeScore()) then
					best = s
				end
			end
		end)
		return best
	end

	local function judgmentBar(judgmentIndex, judgmentName)
		local t = Def.ActorFrame {
			Name = "JudgmentBar"..judgmentName,
			BeginCommand = function(self)
				-- (was: jcount = 0 while aboutToForceWindowSettings) the ForceWindow message that fills jcount has
				-- already been sent by the parent's BeginCommand, so zeroing here left every bar with a stale 0.
				if aboutToForceWindowSettings then
					self.jcount = getRescoredJudge(dvt, judge, judgmentIndex)
				else
					self.jcount = score:GetTapNoteScore(judgmentName)
				end
			end,
			ForceWindowMessageCommand = function(self, params)
				self.jcount = getRescoredJudge(dvt, judge, judgmentIndex)
				self:playcommand("Set")
			end,
			LoadedCustomWindowMessageCommand = function(self)
				self.jcount = lastSnapshot:GetJudgments()[judgmentName:gsub("TapNoteScore_", "")]
				self:playcommand("Set")
			end,
			ScoreChangedMessageCommand = function(self)
				self.jcount = getRescoredJudge(dvt, judge, judgmentIndex)
				self:playcommand("Set")
			end,
			CodeMessageCommand = function(self, params)
				if usingCustomWindows then return end
				if params.Name == "PrevJudge" or params.Name == "NextJudge" then
					self.jcount = getRescoredJudge(dvt, judge, judgmentIndex)
				elseif params.Name == "ResetJudge" then
					self.jcount = score:GetTapNoteScore(judgmentName)
				else
					return -- other codes (e.g. ToggleHands on MenuDown) must not redraw the bars
				end
				self:playcommand("Set")
			end,
			-- the judge text updates the judge before it broadcasts this, so FAST / SLOW are redrawn here too
			RecalculateGraphsMessageCommand = function(self)
				self:GetChild("Slow"):playcommand("Set")
				self:GetChild("Fast"):playcommand("Set")
			end,

			-- IIDX style row: dark band, judgment name in its colour, count, percentage, then SLOW / FAST
			Def.Quad {
				Name = "BG",
				InitCommand = function(self)
					self:xy(LX, judgeY0 + (judgmentIndex - 1) * judgeStep)
					self:zoomto(LW, judgeStep - 1)
					self:halign(0)
					self:diffuse(color("#000000")):diffusealpha(judgmentIndex % 2 == 1 and 0.4 or 0.18)
				end,
			},
			-- thin proportion strip along the bottom of the row
			Def.Quad {
				Name = "Fill",
				InitCommand = function(self)
					self:xy(LX, judgeY0 + (judgmentIndex - 1) * judgeStep + judgeStep / 2 - 2)
					self:zoomto(0, 1)
					self:halign(0)
					self:diffuse(byJudgment(judgmentName))
					self:diffusealpha(0.45)
				end,
				BeginCommand = function(self)
					if aboutToForceWindowSettings then return end

					self:sleep(0.2)
					self:smooth(1.5)
					self:playcommand("Set")
				end,
				SetCommand = function(self)
					self:finishtweening()
					self:bounceend(0.2)
					self:zoomx(LW * self:GetParent().jcount / totalTaps)
				end,
			},
			LoadFont("Common Large") .. {
				Name = "Name",
				InitCommand = function(self)
					self:xy(LX + 6, judgeY0 + (judgmentIndex - 1) * judgeStep)
					self:zoom(0.2)
					self:halign(0)
					self:maxwidth(70 / 0.21)
					self:diffuse(byJudgment(judgmentName))
				end,
				BeginCommand = function(self)
					if aboutToForceWindowSettings then return end
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					if usingCustomWindows then
						self:settext(tostring(getCustomWindowConfigJudgmentName(judgmentName)):upper())
					else
						self:settext(tostring(getJudgeStrings(judgmentName)):upper())
					end
				end,
			},
			LoadFont("Common Large") .. {
				Name = "Count",
				InitCommand = function(self)
					self:xy(LX + 112, judgeY0 + (judgmentIndex - 1) * judgeStep)
					self:zoom(0.22)
					self:halign(1)
					self:diffuse(color(seraphicValueColor))
				end,
				BeginCommand = function(self)
					if aboutToForceWindowSettings then return end
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					self:settext(self:GetParent().jcount)
				end,
			},
			LoadFont("Common Normal") .. {
				Name = "Percentage",
				InitCommand = function(self)
					self:xy(LX + 115, judgeY0 + (judgmentIndex - 1) * judgeStep + 0.5)
					self:zoom(0.24)
					self:halign(0)
					self:diffuse(color("#8f8588"))
				end,
				BeginCommand = function(self)
					if aboutToForceWindowSettings then return end
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					self:settextf("(%03.2f%%)", self:GetParent().jcount / totalTaps * 100)
				end,
			},
			LoadFont("Common Normal") .. {
				Name = "Slow",
				InitCommand = function(self)
					self:xy(SLOWX, judgeY0 + (judgmentIndex - 1) * judgeStep + 0.5)
					self:zoom(0.3)
					self:halign(1)
					self:diffuse(slowColor)
				end,
				BeginCommand = function(self)
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					self:settext(fastSlowText(judgmentIndex, "slow"))
				end,
			},
			LoadFont("Common Normal") .. {
				Name = "Fast",
				InitCommand = function(self)
					self:xy(FASTX, judgeY0 + (judgmentIndex - 1) * judgeStep + 0.5)
					self:zoom(0.3)
					self:halign(1)
					self:diffuse(fastColor)
				end,
				BeginCommand = function(self)
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					self:settext(fastSlowText(judgmentIndex, "fast"))
				end,
			},
		}
		return t
	end

	local jc = Def.ActorFrame {
		Name = "JudgmentBars",
	}
	for i, v in ipairs(judges) do
		jc[#jc+1] = judgmentBar(i, v)
	end
	t[#t+1] = jc

	-- Seraphic: compare rows in the theme's own row style (dark band, crimson bullet, fading hairline under it):
	-- label, best other score | this play
	local function band(y, h)
		return Def.ActorFrame {
			Def.Quad {
				InitCommand = function(self)
					self:xy(LX, y):halign(0):zoomto(LW, h):diffuse(color("#000000")):diffusealpha(0.4)
				end
			},
			Def.Quad {
				InitCommand = function(self)
					self:xy(LX, y + h / 2):halign(0):valign(0):zoomto(LW, 1)
					self:diffuseleftedge(color("#ffffff30")):diffuserightedge(color("#ffffff06"))
				end
			},
			seraphicBullet(LX + 5, y)
		}
	end
	local function rowLabel(y, text)
		return LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + 12, y):halign(0):zoom(0.3):maxwidth(64 / 0.3)
				self:diffuse(color(seraphicLabelColor)):settext(text)
			end
		}
	end
	local function rowSep(y, h)
		return Def.Quad {
			InitCommand = function(self)
				self:xy(SEPX, y):zoomto(1, h - 6):diffuse(color("#ffffff")):diffusealpha(0.3)
			end
		}
	end
	local dimColor = color("#8f8588")
	local function diffColor(v, lowerIsBetter)
		if v == 0 then return dimColor end
		if (v > 0) ~= (lowerIsBetter == true) then return color("#8fd0ff") end
		return color("#ff7a7a")
	end

	local cmp = {}
	local cr = Def.ActorFrame {
		Name = "CompareRows",
		BeginCommand = function(self)
			self:queuecommand("Refresh")
		end,
		RefreshCommand = function(self)
			local prev = previousBest(score)
			local c = currentCounts()
			local pct = currentPercent()
			cmp = {
				prev = prev,
				counts = c,
				pct = pct,
				grade = GetGradeFromPercent(pct / 100),
				miss = missCountOf(c),
			}
			if prev then
				cmp.prevPct = prev:GetWifeScore() * 100
				cmp.prevGrade = prev:GetWifeGrade()
				cmp.prevMiss = prev:GetTapNoteScore("TapNoteScore_W4") + prev:GetTapNoteScore("TapNoteScore_W5")
					+ prev:GetTapNoteScore("TapNoteScore_Miss")
			end
			self:playcommand("Set")
			MESSAGEMAN:Broadcast("SeraCompareUpdated", {grade = cmp.grade})
		end,
		ScoreChangedMessageCommand = function(self)
			self:queuecommand("Refresh")
		end,
		RecalculateGraphsMessageCommand = function(self)
			self:queuecommand("Refresh")
		end,
		LoadedCustomWindowMessageCommand = function(self)
			self:queuecommand("Refresh")
		end,
		UnloadedCustomWindowMessageCommand = function(self)
			self:queuecommand("Refresh")
		end,

		band(rowY.clear, 14),
		band(rowY.level, 14),
		band(rowY.score, 18),
		band(rowY.miss, 14),
		band(rowY.rating, 14),
		rowLabel(rowY.clear, "CLEAR TYPE"),
		rowLabel(rowY.level, "DJ LEVEL"),
		rowLabel(rowY.score, "SCORE"),
		rowLabel(rowY.miss, "MISS COUNT"),
		rowLabel(rowY.rating, "RATING"),
		rowSep(rowY.clear, 14),
		rowSep(rowY.level, 14),
		rowSep(rowY.miss, 14),
		rowSep(rowY.rating, 14),

		-- CLEAR TYPE: best | this play
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(PREVX, rowY.clear):zoom(0.32):maxwidth(76 / 0.32)
			end,
			SetCommand = function(self)
				if cmp.prev then
					self:settext(tostring(getClearTypeFromScore(PLAYER_1, cmp.prev, 0)):upper())
					self:diffuse(getClearTypeFromScore(PLAYER_1, cmp.prev, 2)):diffusealpha(0.65)
				else
					self:settext("NO PLAY"):diffuse(dimColor)
				end
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(NOWX, rowY.clear):zoom(0.34):maxwidth(76 / 0.34)
			end,
			SetCommand = function(self)
				self:settext(tostring(getClearTypeFromScore(PLAYER_1, score, 0)):upper())
				self:diffuse(getClearTypeFromScore(PLAYER_1, score, 2))
			end
		},

		-- DJ LEVEL: rank emblems
		Def.Sprite {
			Name = "PrevGrade",
			InitCommand = function(self)
				self:xy(PREVX, rowY.level)
			end,
			SetCommand = function(self)
				local k = cmp.prevGrade and seraphicGradeIndex(cmp.prevGrade)
				self:visible(k ~= nil)
				if k then seraphicGradeFit(self, k, 0.4, 60):diffusealpha(0.65) end
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(PREVX, rowY.level):zoom(0.32):diffuse(dimColor)
			end,
			SetCommand = function(self)
				self:settext((cmp.prevGrade and seraphicGradeIndex(cmp.prevGrade)) and "" or "-")
			end
		},
		Def.Sprite {
			Name = "NowGrade",
			InitCommand = function(self)
				self:xy(NOWX, rowY.level)
			end,
			SetCommand = function(self)
				local k = seraphicGradeIndex(cmp.grade)
				self:visible(k ~= nil)
				if k then seraphicGradeFit(self, k, 0.42, 64) end
			end
		},

		-- SCORE: this play is the wife percent text drawn by WifeDisplay; best and difference underneath
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + LW - 64, rowY.scoreSub):halign(1):zoom(0.3):diffuse(dimColor)
			end,
			SetCommand = function(self)
				if cmp.prevPct then
					self:settextf("BEST  %05.2f%%", notShit.floor(cmp.prevPct, 2))
				else
					self:settext("BEST  -")
				end
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + LW - 12, rowY.scoreSub):halign(1):zoom(0.32)
			end,
			SetCommand = function(self)
				if cmp.prevPct then
					local d = notShit.floor(cmp.pct, 2) - notShit.floor(cmp.prevPct, 2)
					self:settextf("%+.2f%%", d):diffuse(diffColor(d))
				else
					self:settext("")
				end
			end
		},

		-- MISS COUNT: best | this play, difference at the right end
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:xy(PREVX, rowY.miss):zoom(0.22):diffuse(dimColor)
			end,
			SetCommand = function(self)
				self:settext(cmp.prevMiss and tostring(cmp.prevMiss) or "-")
			end
		},
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:xy(NOWX - 8, rowY.miss):zoom(0.22):diffuse(color(seraphicValueColor))
			end,
			SetCommand = function(self)
				self:settext(tostring(cmp.miss))
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + LW - 6, rowY.miss):halign(1):zoom(0.3)
			end,
			SetCommand = function(self)
				if cmp.prevMiss then
					local d = cmp.miss - cmp.prevMiss
					self:settextf("%+d", d):diffuse(diffColor(d, true))
				else
					self:settext("")
				end
			end
		},

		-- judgment table header
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + 4, judgeHeadY):halign(0):zoom(0.26):diffuse(color(seraphicLabelColor)):settext("JUDGE DETAIL")
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(SLOWX, judgeHeadY):halign(1):zoom(0.26):diffuse(slowColor):settext("SLOW")
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(FASTX, judgeHeadY):halign(1):zoom(0.26):diffuse(fastColor):settext("FAST")
			end
		},

		-- MAX COMBO and the FAST / SLOW totals under the table
		Def.Quad {
			InitCommand = function(self)
				self:xy(LX, comboY):halign(0):zoomto(LW, 10):diffuse(color("#000000")):diffusealpha(0.25)
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + 4, comboY):halign(0):zoom(0.28):diffuse(color(seraphicLabelColor)):settext("MAX COMBO")
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(LX + 112, comboY):halign(1):zoom(0.32):diffuse(color(seraphicValueColor))
			end,
			SetCommand = function(self)
				local ok, mc = pcall(function() return score:GetMaxCombo() end)
				if not ok or not mc then mc = pss:MaxCombo() end
				self:settext(tostring(mc))
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(SLOWX, comboY):halign(1):zoom(0.3):diffuse(slowColor)
			end,
			SetCommand = function(self)
				local fs = fastSlow()
				self:settext(fs.empty and "-" or tostring(fs.slowTotal))
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(FASTX, comboY):halign(1):zoom(0.3):diffuse(fastColor)
			end,
			SetCommand = function(self)
				local fs = fastSlow()
				self:settext(fs.empty and "-" or tostring(fs.fastTotal))
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(SLOWX - 34, comboY):halign(1):zoom(0.26):diffuse(color(seraphicLabelColor)):settext("TOTAL")
			end
		},
	}
	-- the compare bands go under the score text that WifeDisplay / MSD / SSR draw on top of them
	table.insert(t, 1, cr)

	-- Boolean to check whether shift or alt/backslash is held
	local shiftHeld = false

	t[#t+1] = Def.ActorFrame {
		OnCommand = function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(function(event)
				-- Detect if first or repeated shift press
				local button = event.DeviceInput.button
				if button == "DeviceButton_left shift" or button == "DeviceButton_right shift" or button == "DeviceButton_tab" then
					if event.type == "InputEventType_FirstPress" or event.type == "InputEventType_Repeat" then
						if not shiftHeld then
							shiftHeld = true
							MESSAGEMAN:Broadcast("ShiftPressed")
						end
					elseif event.type == "InputEventType_Release" then
						if shiftHeld then
							shiftHeld = false
							MESSAGEMAN:Broadcast("ShiftReleased")
						end
					end
				end
			end)
		end
	}

	-- Function for calculating RA and LA, returns the ratio of ridiculous to marvelous and ludicrous to ridiculous from offset plot in replay.
	local function calculateRatios(score)
		-- Get replay depending on whether custom windows were used or not
		local replay = usingCustomWindows and REPLAYS:GetActiveReplay() or score:GetReplay()
		replay:LoadAllData()
		-- Offset and tap note vectors from replay
		local offsetTable = replay:GetOffsetVector()
		local typeTable = replay:GetTapNoteTypeVector()

		if not offsetTable or #offsetTable == 0 or not typeTable or #typeTable == 0 then
			return -1, -1, -1
		end

		-- Define judgement windows
		local window = usingCustomWindows and getCurrentCustomWindowConfigJudgmentWindowTable() or {
			TapNoteScore_W1 = 22.5 * ms.JudgeScalers[judge], -- j4 marv
			TapNoteScore_W2 = 45 * ms.JudgeScalers[judge],   -- j4 perf
			TapNoteScore_W3 = 90 * ms.JudgeScalers[judge],   -- j4 g
		}
		-- Define RA and LA thresholds
		window["TapNoteScore_W0"] = window["TapNoteScore_W1"] / 2 -- ra threshold
		window["TapNoteScore_W-1"] = window["TapNoteScore_W0"] / 2 -- la threshold

		local laThreshold = window["TapNoteScore_W-1"]
		local raThreshold = window["TapNoteScore_W0"]
		local marvThreshold = window["TapNoteScore_W1"] -- marv

		local ludic = 0
		local ridicLA = 0
		local ridic = 0
		local marvRA = 0

		-- Iterate over offset table
		for i, o in ipairs(offsetTable) do
			-- Check if note is tap or hold
			if typeTable[i] == "TapNoteType_Tap" or typeTable[i] == "TapNoteType_HoldHead" then
				local off = math.abs(o)
				if off <= raThreshold then
					ridic = ridic + 1
				elseif off <= marvThreshold then
					marvRA = marvRA + 1
				end
				if off <= laThreshold then
					ludic = ludic + 1
				elseif off <= raThreshold then
					ridicLA = ridicLA + 1
				end
			end
		end

		-- Return ratios, ridic count, and marv count
		local ridiculousAttack = ridic / marvRA
		local ludicrousAttack = ludic / ridicLA
		return ridiculousAttack, ludicrousAttack, ridicLA, marvRA
	end

	--[[
	The following section first adds the ratioText, laRatio, raRatio, maRatio, and paRatio. Then the correct values are filled in.
	When shift or alt/backslash is held, the display changes accordingly.
	--]]
	local ratioText, raRatio, laRatio, maRatio, paRatio, marvelousTaps, perfectTaps, greatTaps
	local mapaHover = nil
	t[#t+1] = Def.ActorFrame {
		Name = "MAPARatioContainer",
		-- Seraphic: refresh the ratio display whenever the hover state changes (polled, see WifeDisplay)
		OnCommand = function(self)
			self:SetUpdateFunction(function(f)
				local over = mapaHover ~= nil and isOver(mapaHover)
				if over ~= f.seraOver then
					f.seraOver = over
					f:GetChild("PAText"):playcommand("Set")
				end
			end)
		end,

		-- LR2 banded row behind the ratio line
		Def.Quad {
			InitCommand = function(self)
				self:xy(LX, ratioY):halign(0):zoomto(LW, 10):diffuse(color("#000000")):diffusealpha(0.4)
			end
		},
		UIElements.QuadButton(1,1) .. {
			Name = "MAPAHoverThing",
			InitCommand = function(self)
				self:xy(LX + LW / 3, ratioY + 6)
				self:zoomto(LW / 3 * 2, 12)
				self:halign(0):valign(1)
				self:diffusealpha(0)
				mapaHover = self
			end,
			MouseOverCommand = function(self)
				self:GetParent():GetChild("PAText"):playcommand("Set")
			end,
			MouseOutCommand = function(self)
				self:GetParent():GetChild("PAText"):playcommand("Set")
			end,
		},
		LoadFont("Common Large") .. {
			Name = "Text",
			InitCommand = function(self)
				ratioText = self
				self:settextf("%s:", tostring(translated_info["MAPARatio"]):upper())
				self:zoom(0.18):halign(1):diffuse(color(seraphicLabelColor))
			end
		},
		LoadFont("Common Large") .. {
			Name = "LAText",
			InitCommand = function(self)
				laRatio = self
				self:settextf("%.2f:1", 0)
				self:zoom(0.19):halign(1):rainbow() -- Rainbow cuz it's LA man come on
				self:visible(false)
			end
		},
		LoadFont("Common Large") .. {
			Name = "RAText",
			InitCommand = function(self)
				raRatio = self
				self:settextf("%.2f:1", 0)
				self:zoom(0.19):halign(1)  -- No color, user can set whatever they want here. AAAAA is white so I left as white
				self:visible(false)
			end
		},
		LoadFont("Common Large") .. {
			Name = "MAText",
			InitCommand = function(self)
				maRatio = self
				self:zoom(0.19):halign(1):diffuse(byJudgment(judges[1]))
			end
		},
		LoadFont("Common Large") .. {
			Name = "PAText",
			InitCommand = function(self)
				paRatio = self
				self:xy(LX + LW - 4, ratioY)
				self:zoom(0.19)
				self:halign(1)
				self:diffuse(byJudgment(judges[2]))

				marvelousTaps = score:GetTapNoteScore(judges[1])
				perfectTaps = score:GetTapNoteScore(judges[2])
				greatTaps = score:GetTapNoteScore(judges[3])
				self:playcommand("Set")
			end,
			SetCommand = function(self)
				-- Fill in raRatio, laRatio, maRatio, and paRatio
				local ridiculousAttack, ludicrousAttack, ridics, marvs = calculateRatios(score)
				maRatio:settextf("%.1f:1", marvelousTaps / perfectTaps)
				paRatio:settextf("%.1f:1", perfectTaps / greatTaps)
				raRatio:settextf("%.2f:1", ridiculousAttack)
				laRatio:settextf("%.2f:1", ludicrousAttack)

				-- Align with where paRatio was and move things accordingly
				if shiftHeld and isOver(mapaHover) then
					-- Show LA/RA ratios
					laRatio:visible(true)
					raRatio:visible(true)
					maRatio:visible(false)
					paRatio:visible(false)

					raRatio:settextf("%.2f:1", ridics / marvs) -- ridic:marv
					raRatio:xy(paRatio:GetX(), paRatio:GetY())
					local laRatioX = raRatio:GetX() - raRatio:GetZoomedWidth() - 10
					laRatio:xy(laRatioX, raRatio:GetY())
					local ratioTextX = laRatioX - laRatio:GetZoomedWidth() - 10
					ratioText:xy(ratioTextX, raRatio:GetY())

					ratioText:settextf("LA/RA RATIO:")
				elseif shiftHeld or isOver(mapaHover) then
					-- Show RA/MA ratios
					raRatio:visible(true)
					laRatio:visible(false)
					maRatio:visible(true)
					paRatio:visible(false)

					maRatio:settextf("%.1f:1", marvs / perfectTaps) -- marv:perf
					raRatio:xy(paRatio:GetX() - maRatio:GetZoomedWidth() - 10, paRatio:GetY())
					maRatio:xy(paRatio:GetX(), paRatio:GetY())
					local ratioTextX = raRatio:GetX() - raRatio:GetZoomedWidth() - 10
					ratioText:xy(ratioTextX, paRatio:GetY())

					ratioText:settextf("RA/MA RATIO:")
				else
					-- Show MA/PA ratios
					raRatio:visible(false)
					laRatio:visible(false)
					maRatio:visible(true)
					paRatio:visible(true)

					maRatio:settextf("%.1f:1", marvelousTaps / perfectTaps) -- marv:perf
					local maRatioX = paRatio:GetX() - paRatio:GetZoomedWidth() - 10
					maRatio:xy(maRatioX, paRatio:GetY())
					local ratioTextX = maRatioX - maRatio:GetZoomedWidth() - 10
					ratioText:xy(ratioTextX, paRatio:GetY())

					ratioText:settextf("%s:", tostring(translated_info["MAPARatio"]):upper())
				end

				if score:GetChordCohesion() == true then
					maRatio:maxwidth(maRatio:GetZoomedWidth()/0.19)
					self:maxwidth(self:GetZoomedWidth()/0.19)
					ratioText:maxwidth(capWideScale(get43size(65), 85)/0.27)
				end
			end,

			ShiftPressedMessageCommand = function(self)
				self:playcommand("Set")
			end,
			ShiftReleasedMessageCommand = function(self)
				self:playcommand("Set")
			end,

			CodeMessageCommand = function(self, params)
				if usingCustomWindows then
					return
				end

				if params.Name == "PrevJudge" or params.Name == "NextJudge" then
					marvelousTaps = getRescoredJudge(dvt, judge, 1)
					perfectTaps = getRescoredJudge(dvt, judge, 2)
					greatTaps = getRescoredJudge(dvt, judge, 3)
					self:playcommand("Set")
				end
				if params.Name == "ResetJudge" then
					marvelousTaps = score:GetTapNoteScore(judges[1])
					perfectTaps = score:GetTapNoteScore(judges[2])
					greatTaps = score:GetTapNoteScore(judges[3])
					self:playcommand("Set")
				end
			end,
			ForceWindowMessageCommand = function(self)
				marvelousTaps = getRescoredJudge(dvt, judge, 1)
				perfectTaps = getRescoredJudge(dvt, judge, 2)
				greatTaps = getRescoredJudge(dvt, judge, 3)
				self:playcommand("Set")
			end,
			ScoreChangedMessageCommand = function(self)
				self:playcommand("ForceWindow")
			end,
			LoadedCustomWindowMessageCommand = function(self)
				marvelousTaps = lastSnapshot:GetJudgments()["W1"]
				perfectTaps = lastSnapshot:GetJudgments()["W2"]
				greatTaps = lastSnapshot:GetJudgments()["W3"]
				self:playcommand("Set")
			end,
		},
	}

	local radars = {"Holds", "Mines", "Rolls", "Lifts", "Fakes"}
	local radars_translated = {
		Holds = THEME:GetString("RadarCategory", "Holds"),
		Mines = THEME:GetString("RadarCategory", "Mines"),
		Rolls = THEME:GetString("RadarCategory", "Rolls"),
		Lifts = THEME:GetString("RadarCategory", "Lifts"),
		Fakes = THEME:GetString("RadarCategory", "Fakes")
	}
	local function radarEntry(i)
		return Def.ActorFrame {
			Name = "Radar"..radars[i],

			-- LR2 banded row: uppercase silver label, light right-aligned value
			Def.Quad {
				InitCommand = function(self)
					self:xy(LX, statsY0 + statsStep * (i - 1)):halign(0):zoomto(111, statsStep)
					self:diffuse(color("#000000")):diffusealpha(i % 2 == 1 and 0.4 or 0.15)
				end,
			},
			LoadFont("Common Normal") .. {
				InitCommand = function(self)
					self:xy(LX + 4, statsY0 + statsStep * (i - 1))
					self:zoom(0.31)
					self:halign(0)
					self:diffuse(color(seraphicLabelColor))
					self:settext(tostring(radars_translated[radars[i]]):upper())
				end,
			},
			LoadFont("Common Normal") .. {
				InitCommand = function(self)
					self:xy(LX + 108, statsY0 + statsStep * (i - 1))
					self:zoom(0.33)
					self:halign(1)
					self:diffuse(color(seraphicValueColor))
				end,
				BeginCommand = function(self)
					self:queuecommand("Set")
				end,
				SetCommand = function(self)
					self:settextf(
						"%03d/%03d",
						gatherRadarValue("RadarCategory_" .. radars[i], score),
						score:GetRadarPossible():GetValue("RadarCategory_" .. radars[i])
					)
				end,
				ScoreChangedMessageCommand = function(self)
					self:queuecommand("Set")
				end,
			},
		}
	end
	local rb = Def.ActorFrame {
		Name = "RadarContainer",
		Def.Quad {
			Name = "BG",
			InitCommand = function(self)
				self:visible(false)
				self:xy(frameX - 5, frameY + 228):zoomto(frameWidth / 2 - 10, 55.5)
				self:halign(0):valign(0)
				self:diffuse(getMainColor("tabs")):diffusetopedge(panelTopColor())
			end,
		},
	}
	for i = 1, #radars do
		rb[#rb+1] = radarEntry(i)
	end
	t[#t+1] = rb

	local function scoreStatistics(score)
		local replay = usingCustomWindows and REPLAYS:GetActiveReplay() or score:GetReplay()
		replay:LoadAllData()
		local tracks = replay:GetTrackVector()
		local dvtTmp = replay:GetOffsetVector() or {}
		local devianceTable = {}
		local types = replay:GetTapNoteTypeVector()

		local cbl = 0
		local cbr = 0
		local cbm = 0
		local tst = ms.JudgeScalers
		local tso = tst[judge]
		local ncol = GAMESTATE:GetCurrentSteps():GetNumColumns() - 1
		local middleCol = ncol/2

		-- if available, filter out non taps from the deviation list
		-- (hitting mines directly without filtering would make them appear here)
		if types ~= nil and #types > 0 then
			devianceTable = {}
			for i, d in ipairs(dvtTmp) do
				local ty = types[i]
				if ty == "TapNoteType_Tap" or ty == "TapNoteType_HoldHead" or ty == "TapNoteType_Lift" then
					devianceTable[#devianceTable+1] = d
				end
			end
		else
			devianceTable = dvtTmp
		end

		for i = 1, #devianceTable do
			if tracks[i] then
				if math.abs(devianceTable[i]) > tso * 90 then
					if tracks[i] < middleCol then
						cbl = cbl + 1
					elseif tracks[i] > middleCol then
						cbr = cbr + 1
					else
						cbm = cbm + 1
					end
				end
			end
		end
		local smallest, largest = wifeRange(devianceTable)

		-- this needs to match the statValues table below
		return {
			wifeMean(devianceTable),
			wifeSd(devianceTable),
			largest,
			cbl,
			cbr,
			cbm
		}
	end

	-- stats stuff
	local replay = score:GetReplay()
	replay:LoadAllData()
	local tracks = replay:GetTrackVector()
	local dvtTmp = replay:GetOffsetVector()
	local devianceTable = {}
	local types = replay:GetTapNoteTypeVector() or {}
	local cbl = 0
	local cbr = 0
	local cbm = 0

	-- basic per-hand stats to be expanded on later
	local tst = ms.JudgeScalers
	local tso = tst[judge]
	local ncol = GAMESTATE:GetCurrentSteps():GetNumColumns() - 1 -- cpp indexing -mina
	local middleCol = ncol/2

	-- if available, filter out non taps from the deviation list
	-- (hitting mines directly without filtering would make them appear here)
	if types ~= nil and #types > 0 then
		devianceTable = {}
		for i, d in ipairs(dvtTmp) do
			local ty = types[i]
			if ty == "TapNoteType_Tap" or ty == "TapNoteType_HoldHead" or ty == "TapNoteType_Lift" then
				devianceTable[#devianceTable+1] = d
			end
		end
	else
		devianceTable = dvtTmp
	end

	if devianceTable ~= nil then
		for i = 1, #devianceTable do
			if tracks[i] then	-- we dont load track data when reconstructing eval screen apparently so we have to nil check -mina
				if math.abs(devianceTable[i]) > tso * 90 then
					if tracks[i] < middleCol then
						cbl = cbl + 1
					elseif tracks[i] > middleCol then
						cbr = cbr + 1
					else
						cbm = cbm + 1
					end
				end
			end
		end

		local smallest, largest = wifeRange(devianceTable)
		local statNames = {
			THEME:GetString("ScreenEvaluation", "Mean"),
			THEME:GetString("ScreenEvaluation", "StandardDev"),
			THEME:GetString("ScreenEvaluation", "LargestDev"),
			THEME:GetString("ScreenEvaluation", "LeftCB"),
			THEME:GetString("ScreenEvaluation", "RightCB"),
			THEME:GetString("ScreenEvaluation", "MiddleCB")
		}
		local statValues = {
			wifeMean(devianceTable),
			wifeSd(devianceTable),
			largest,
			cbl,
			cbr,
			cbm
		}
		-- if theres a middle lane, display its cbs too
		local lines = ((ncol+1) % 2 == 0) and #statNames-1  or #statNames
		local tzoom = lines == 5 and 0.33 or 0.28
		local ySpacing = lines == 5 and statsStep or statsStep * 0.87
		local statsMid = statsY0 + statsStep * 2
		local function statsLine(i)
			return Def.ActorFrame {
				Name = "StatLine"..statNames[i],
				-- LR2 banded row
				Def.Quad {
					InitCommand = function(self)
						self:xy(LX + 113, statsMid + ySpacing * (i - (lines + 1) / 2)):halign(0)
						self:zoomto(LW - 113, ySpacing)
						self:diffuse(color("#000000")):diffusealpha(i % 2 == 1 and 0.4 or 0.15)
					end,
				},
				LoadFont("Common Normal") .. {
					Name = "StatText",
					InitCommand = function(self)
						self:xy(LX + 117, statsMid + ySpacing * (i - (lines + 1) / 2))
						self:zoom(tzoom * 0.95)
						self:halign(0)
						self:diffuse(color(seraphicLabelColor))
						self:settext(tostring(statNames[i]):upper())
					end,
				},
				LoadFont("Common Normal") .. {
					Name=i,
					InitCommand = function(self)
						self:queuecommand("Set")
					end,
					SetCommand = function(self, params)
						local statValues = scoreStatistics(params ~= nil and params.score or score)
						if i < 4 then
							self:xy(LX + LW - 4, statsMid + ySpacing * (i - (lines + 1) / 2))
							self:zoom(tzoom)
							self:halign(1)
							self:diffuse(color(seraphicValueColor))
							self:settextf("%5.2fms", statValues[i])
						else
							self:xy(LX + LW - 4, statsMid + ySpacing * (i - (lines + 1) / 2))
							self:zoom(tzoom)
							self:halign(1)
							self:diffuse(color(seraphicValueColor))
							self:settext(statValues[i])
						end
					end,
					ChangeScoreCommand = function(self, params)
						self:queuecommand("Set", {score=params.score})
					end,
					LoadedCustomWindowMessageCommand = function(self)
						self:queuecommand("Set")
					end,
					CodeMessageCommand = function(self, params)
						if usingCustomWindows then
							return
						end

						if i > 3 and (params.Name == "PrevJudge" or params.Name == "NextJudge") then
							self:queuecommand("Set")
						end
					end,
					ForceWindowMessageCommand = function(self)
						self:queuecommand("Set")
					end,
				},
			}
		end

		local sl = Def.ActorFrame {
			Name = "ScoreStatsContainer",
			Def.Quad {
				Name = "BG",
				InitCommand = function(self)
					self:diffuse(getMainColor("tabs")):diffusetopedge(panelTopColor())
					self:visible(false)
					self:xy(frameWidth + 25, frameY + 228)
					self:zoomto(frameWidth / 2 + 10, 55.5)
					self:halign(1):valign(0)
				end,
			},
		}
		for i = 1, lines do
			sl[#sl+1] = statsLine(i)
		end
		t[#t+1] = sl
	end

	
	-- life graph
	local function GraphDisplay()
		return Def.ActorFrame {
			Def.GraphDisplay {
				InitCommand = function(self)
					self:Load("GraphDisplay")
				end,
				BeginCommand = function(self)
					local ss = SCREENMAN:GetTopScreen():GetStageStats()
					self:Set(ss, ss:GetPlayerStageStats())
					self:diffusealpha(0.95)
					self:GetChild("Line"):diffuse(color("#f2f2fa")):diffusealpha(0.9)
					self:zoomx(0.95):zoomy(1.45)
					self:xy(0, 0)
				end,
				ScoreChangedMessageCommand = function(self)
					if score and judge then
						self:playcommand("RecalculateGraphs", {judge=judge})
					end
				end,
				RecalculateGraphsMessageCommand = function(self, params)
					-- called by the end of a codemessagecommand somewhere else
					if not ms.JudgeScalers[params.judge] then return end
					local success = SCREENMAN:GetTopScreen():RescoreReplay(SCREENMAN:GetTopScreen():GetStageStats():GetPlayerStageStats(), ms.JudgeScalers[params.judge], score, usingCustomWindows and currentCustomWindowConfigUsesOldestNoteFirst())
					if not success then ms.ok("Failed to recalculate score for some reason...") return end
					self:playcommand("Begin")
					MESSAGEMAN:Broadcast("SetComboGraph")
				end,
			},
		}
	end

	-- combo graph
	local function ComboGraph()
		return Def.ActorFrame {
			Def.ComboGraph {
				InitCommand = function(self)
					self:Load("ComboGraph")
				end,
				BeginCommand = function(self)
					local ss = SCREENMAN:GetTopScreen():GetStageStats()
					self:Set(ss, ss:GetPlayerStageStats())
					self:zoom(0.95)
					self:xy(0, 0)
				end,
				SetComboGraphMessageCommand = function(self)
					self:Clear()
					self:Load("ComboGraph")
					self:playcommand("Begin")
				end,
			},
		}
	end

	-- Seraphic: the life / combo graphs are not shown on this layout. They stay loaded (hidden) because the life
	-- graph's RecalculateGraphs handler rescores the replay for the judge / custom window changes, and the custom
	-- window toggle looks both frames up by name.
	t[#t + 1] = Def.ActorFrame {Name = "GraphDisplayP1", Def.ActorFrame {InitCommand = function(self) self:visible(false) end, GraphDisplay()}}
	t[#t + 1] = Def.ActorFrame {Name = "ComboGraphP1", Def.ActorFrame {InitCommand = function(self) self:visible(false) end, ComboGraph()}}

	return t
end

-- Seraphic: IIDX / beatoraja-style result layout (left: graph + compare rows + judgments, centre: open background with
-- the song text at the bottom, right: song data / plot / scores)
-- LR2 style: dark header band (16px, ending at y with a crimson rule) and a small "::HEADING"
local function seraHeader(x, y, w, label)
	return Def.ActorFrame {
		seraphicHeaderBand(x, y - 16, w, 16),
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(x + 4, y - 8):halign(0):valign(0.5):zoom(0.45):maxwidth((w - 8) / 0.45)
				self:settext(seraphicHeading(label)):diffuse(color(seraphicLabelColor))
			end
		}
	}
end

-- panel behind the life / combo graphs (left column, top)
-- Seraphic: single left window (body + border are drawn in the underlay); thin dividers between sections
local function seraDivider(x, y, w)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, 1):diffuse(color("#ffffff"))
			self:diffuseleftedge(color("#ffffff30")):diffuserightedge(color("#ffffff06"))
		end
	}
end
t[#t + 1] = seraDivider(19.4, 182, 242.1)
t[#t + 1] = seraDivider(19.4, 403, 242.1)
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(131.4, 404.5):halign(0):valign(0):zoomto(1, 45):diffuse(color("#ffffff"))
		self:diffusetopedge(color("#ffffff30")):diffusebottomedge(color("#ffffff06"))
	end
}

-- right column headers + panel behind the offset plot
t[#t + 1] = seraHeader(18.4, 152, 246, "SONG DATA")
-- judge details fill the bottom of the middle, joined to the left and right windows
t[#t + 1] = seraHeader(280, 334, 294, "JUDGE DETAILS")
t[#t + 1] = seraHeader(590, 337, 246, "SCORE HISTORY")

do
	local rows = {"MUSIC TITLE", "ARTIST", "BPM", "DURATION", "NOTES"}
	local function getVals()
		local out = {"", "", "", "", ""}
		pcall(function()
			local song = GAMESTATE:GetCurrentSong()
			local steps = GAMESTATE:GetCurrentSteps()
			local rate = getCurRateValue() or 1
			pcall(function()
				local r = SCREENMAN:GetTopScreen():GetReplayRate()
				if r then rate = r end
			end)
			out[1] = song:GetDisplayMainTitle()
			out[2] = song:GetDisplayArtist()
			local b = song:GetDisplayBpms()
			local lo, hi = math.floor(b[1] * rate + 0.5), math.floor(b[2] * rate + 0.5)
			out[3] = (lo == hi) and tostring(lo) or (lo .. "-" .. hi)
			local len = song:MusicLengthSeconds() / rate
			out[4] = string.format("%d:%02d", math.floor(len / 60), math.floor(len % 60))
			out[5] = tostring(steps:GetRadarValues(PLAYER_1):GetValue("RadarCategory_Notes"))
		end)
		return out
	end
	-- Seraphic: compact song data line at the top of the left window: BPM / DURATION / NOTES
	-- (title and artist sit under the banner)
	local stats = {{"BPM", 3}, {"DURATION", 4}, {"NOTES", 5}}
	for i, st in ipairs(stats) do
		local x0 = 18.4 + (i - 1) * 82
		local labelW = 0
		t[#t + 1] = LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(x0, 163):halign(0):valign(0.5):zoom(0.26):settext(st[1]):diffuse(color("#9a9a9a"))
				labelW = self:GetZoomedWidth()
			end
		}
		-- value follows its label instead of sitting at the far end of the slot
		t[#t + 1] = LoadFont("Common Normal") .. {
			InitCommand = function(self)
				local gap = 5
				self:xy(x0 + labelW + gap, 163):halign(0):valign(0.5):zoom(0.32):maxwidth(math.max(20, 78 - labelW - gap) / 0.32):settext("")
			end,
			OnCommand = function(self) self:settext(getVals()[st[2]]) end
		}
	end
end

if GAMESTATE:IsPlayerEnabled() then
	t[#t + 1] = scoreBoard(PLAYER_1, 0)
end

t[#t + 1] = LoadActor("../offsetplot")

-- NEW RECORD ribbon in the open centre of the screen: this play beat the previous best on this chart at this rate
-- (only for scores set this session, so opening old results from the Scores tab doesn't show it)
do
	local gain
	pcall(function()
		local hs = score
		if not hs then return end
		local started = SeraphicSession and SeraphicSession.started or ""
		if started ~= "" and hs:GetDate() < started then return end
		local byRate = SCOREMAN:GetScoresByKey(hs:GetChartKey())
		local list = byRate and byRate[getRate(hs)]
		local scores = list and list:GetScores()
		if not scores or #scores < 2 or getHighScoreIndex(scores, hs) ~= 1 then return end
		local diff = (hs:GetWifeScore() - scores[2]:GetWifeScore()) * 100
		if diff > 0 then gain = diff end
	end)
	if gain then
		local rx, ry, rw = SCREEN_CENTER_X, 215, 290
		t[#t + 1] = Def.ActorFrame {
			Name = "NewRecord",
			InitCommand = function(self)
				self:xy(rx, ry):diffusealpha(0)
			end,
			OnCommand = function(self)
				self:sleep(0.9):decelerate(0.4):diffusealpha(1)
			end,
			-- crimson band fading out to both ends
			Def.Quad {
				InitCommand = function(self)
					self:halign(1):zoomto(rw / 2, 26)
					self:diffuseleftedge(color("#9c142800")):diffuserightedge(color("#9c1428E0"))
				end
			},
			Def.Quad {
				InitCommand = function(self)
					self:halign(0):zoomto(rw / 2, 26)
					self:diffuseleftedge(color("#9c1428E0")):diffuserightedge(color("#9c142800"))
				end
			},
			Def.Quad {
				InitCommand = function(self)
					self:y(-13):zoomto(rw, 1):diffuse(color("#ffffff")):diffusealpha(0.35)
					self:diffuseleftedge(color("#ffffff00")):diffuserightedge(color("#ffffff00"))
				end
			},
			LoadFont("Seraphic Title") .. {
				InitCommand = function(self)
					self:y(-1):zoom(0.5):maxwidth((rw - 20) / 0.5):diffuse(color("#f4ecee"))
					self:settext(string.format("New Record  +%.2f%%", gain))
				end,
				OnCommand = function(self)
					self:sleep(1.3):diffuseshift():effectcolor1(color("#ffffff")):effectcolor2(color("#e8b8c2")):effectperiod(2)
				end
			}
		}
	end
end

-- session chronicle: record this play once per results screen (Scripts/05 SeraphicSession.lua)
t[#t + 1] = Def.Actor {
	OnCommand = function(self)
		if self.recorded or not SeraphicSessionRecordScore then return end
		self.recorded = true
		pcall(function()
			local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats()
			SeraphicSessionRecordScore(pss and pss:GetHighScore())
		end)
	end
}

return t
