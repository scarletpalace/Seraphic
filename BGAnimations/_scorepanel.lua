-- Seraphic: score panel of the selected chart, bottom-right of the select screen (modelled on the LR2 skin):
-- a gauge with crystal wings and rank labels, the big rank emblem + clear type, and the score rows.
local pw, ph = 356, 82
local px, py = 438, SCREEN_HEIGHT - 86 -- stays clear of the tabs (left) and the bottom-right crystal
local wingW = 44
local tube0 = 39 -- slot 0 of the gauge (the tube overlaps the wings by 5px, as in the LR2 sheet)
local tubeW = pw - tube0 * 2
local slotW = tubeW / 9

-- gauge: one label per grade, placed on slots 2..8 at the percent where Etterna awards it (wife3 thresholds).
-- percent -> slot is piecewise linear through those marks, so the fill reaches a label exactly at its grade;
-- the top of the scale is stretched because the grades cluster near 100%. D has no lower bound, so it sits at 50%.
local gaugeMarks = {{"D", 50}, {"C", 60}, {"B", 70}, {"A", 80}, {"AA", 93}, {"AAA", 99.7}, {"AAAA", 99.955}}
local gaugePoints = {{0, 0}}
for i, m in ipairs(gaugeMarks) do gaugePoints[#gaugePoints + 1] = {m[2], i + 1} end
gaugePoints[#gaugePoints + 1] = {100, 9}
local function slotOf(pct)
	if pct <= 0 then return 0 end
	for i = 2, #gaugePoints do
		local a, b = gaugePoints[i - 1], gaugePoints[i]
		if pct <= b[1] then return a[2] + (pct - a[1]) / (b[1] - a[1]) * (b[2] - a[2]) end
	end
	return 9
end

local colAx, colAv = 92, 216 -- left column: label x, value x (right aligned)
local colBx, colBv = 228, 350
local rowY = {48, 62, 76}
local labelsA = {"SCORE", "MAXCOMBO", "COMBOBREAKS"}
local labelsB = {"RANKING", "RATE", "MARVELOUS"}

local requested = {} -- chart keys we already asked the leaderboard for (avoid request loops)

local function currentScore()
	local song, steps = GAMESTATE:GetCurrentSong(), GAMESTATE:GetCurrentSteps()
	if not song or not steps then return nil, steps end
	local ok, sc = pcall(GetDisplayScore)
	if ok and sc and sc:GetWifeScore() > 0 then return sc, steps end
	return nil, steps
end

local t = Def.ActorFrame {
	Name = "SeraScorePanel",
	InitCommand = function(self) self:xy(px, py) end,
	BeginCommand = function(self) self:queuecommand("Set") end,
	CurrentSongChangedMessageCommand = function(self) self:queuecommand("Set") end,
	CurrentStepsChangedMessageCommand = function(self) self:queuecommand("Set") end,
	CurrentRateChangedMessageCommand = function(self) self:queuecommand("Set") end,
	DelayedChartUpdateMessageCommand = function(self) self:queuecommand("Set") end,
	LoginMessageCommand = function(self) self:queuecommand("Set") end,
	LogOutMessageCommand = function(self) self:queuecommand("Set") end,
	OnlineUpdateMessageCommand = function(self) self:queuecommand("Set") end,
	SeraphicLeaderboardMessageCommand = function(self) self:queuecommand("Set") end,
	SeraLeaderboardArrivedMessageCommand = function(self) self:queuecommand("Set") end,

	SetCommand = function(self)
		local score, steps = currentScore()
		local grade, clear, fill = self:GetChild("Grade"), self:GetChild("Clear"), self:GetChild("Fill")
		local date = self:GetChild("Date")
		local v = {}
		for i = 1, 6 do v[i] = self:GetChild("V" .. i) end

		-- leaderboard place (needs a login)
		local rank = "---"
		if steps and DLMAN:IsLoggedIn() then
			local key = steps:GetChartKey()
			local lb = DLMAN:GetChartLeaderBoard(key)
			if lb and #lb > 0 then
				local me = DLMAN:GetUsername()
				rank = string.format("--- / %03d", #lb)
				for i, hs in ipairs(lb) do
					if hs:GetDisplayName() == me then
						rank = string.format("#%03d / %03d", i, #lb)
						break
					end
				end
			elseif not requested[key] and playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).leaderboardEnabled then
				requested[key] = true
				seraphicRequestLeaderboard(key)
			end
		end
		v[4]:settext(rank)

		if score then
			local k = seraphicGradeIndex(score:GetWifeGrade())
			if k then
				-- AAAA/AAAAA emblems are wider; keep them inside the left block
				seraphicGradeFit(grade, k, 1.1, 88):visible(true)
			else
				grade:visible(false)
			end
			local okd, ds = pcall(getScoreDate, score)
			date:settext(okd and ds or "")
			clear:settext(string.upper(getClearTypeFromScore(PLAYER_1, score, 0)))
			clear:diffuse(getClearTypeFromScore(PLAYER_1, score, 2))
			local pct = score:GetWifeScore() * 100
			local gc = byGrade(score:GetWifeGrade())
			fill:diffuse(gc):zoomx(slotOf(pct) * slotW)
			v[1]:settextf("%.2f%%", (notShit and notShit.floor) and notShit.floor(pct, 2) or pct):diffuse(gc)
			v[2]:settextf("%05d", score:GetMaxCombo())
			local okb, cb = pcall(getScoreComboBreaks, score)
			v[3]:settextf("%05d", (okb and tonumber(cb)) or 0)
			local okr, rate = pcall(function() return score:GetMusicRate() end)
			v[5]:settextf("%.2fx", okr and rate or 1)
			local okm, marv = pcall(function() return score:GetTapNoteScore("TapNoteScore_W1") end)
			v[6]:settextf("%05d", okm and marv or 0)
		else
			grade:visible(false)
			date:settext("")
			clear:settext("NO PLAY"):diffuse(color("#8a8a8a"))
			fill:zoomx(0)
			v[1]:settext("0.00%"):diffuse(color("#ffffff"))
			v[2]:settext("00000")
			v[3]:settext("00000")
			v[5]:settext("-.--x")
			v[6]:settext("00000")
		end
	end,

	-- soft dark backing so the numbers stay readable on the filigree
	Def.Quad {
		InitCommand = function(self)
			self:xy(-6, 3):halign(0):valign(0):zoomto(pw + 12, ph - 2)
			self:diffuse(color("#000000")):diffusealpha(0.38)
			self:fadeleft(0.06):faderight(0.06)
		end
	},

	-- gauge: tube (tiled), fill, crystal wings
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_gauge_tube"),
		InitCommand = function(self)
			self:xy(tube0, 10):halign(0):valign(0):zoomto(tubeW, 12)
		end
	},
	Def.Quad {
		Name = "Fill",
		InitCommand = function(self)
			self:xy(tube0, 12):halign(0):valign(0):zoomto(0, 6):diffusealpha(0.85)
		end
	},
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_gauge_wing"),
		InitCommand = function(self) self:xy(0, 0):halign(0):valign(0) end
	},
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_gauge_wing"),
		InitCommand = function(self) self:xy(pw, 0):halign(0):valign(0):zoomx(-1) end
	},

	-- left block: rank emblem + clear type
	Def.Sprite {
		Name = "Grade",
		InitCommand = function(self) self:xy(44, 52):visible(false) end
	},
	LoadFont("Common Normal") .. {
		Name = "Date",
		InitCommand = function(self)
			self:xy(44, 80):halign(0.5):zoom(0.27):maxwidth(92 / 0.27):diffuse(color("#bdbdbd"))
		end
	},
	LoadFont("Seraphic Artist") .. {
		Name = "Clear",
		InitCommand = function(self)
			self:xy(44, 68):halign(0.5):zoom(0.4):maxwidth(84 / 0.4):settext("NO PLAY"):diffuse(color("#8a8a8a"))
		end
	},
}

for _, m in ipairs(gaugeMarks) do
	t[#t + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(tube0 + slotOf(m[2]) * slotW, 5):halign(0.5):valign(0.5):zoom(0.26):settext(m[1]):diffuse(color("#e6e6e6"))
		end
	}
end

local function row(i, labelX, valueX, label, name)
	t[#t + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(labelX, rowY[i]):halign(0):valign(0.5):zoom(0.32):settext(label):diffuse(color("#a8a8a8"))
		end
	}
	t[#t + 1] = LoadFont("Seraphic Artist") .. {
		Name = name,
		InitCommand = function(self)
			self:xy(valueX, rowY[i]):halign(1):valign(0.5):zoom(0.44):maxwidth(78 / 0.44):settext("-")
		end
	}
	-- dotted rule under the row
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(labelX, rowY[i] + 6):halign(0):valign(0):zoomto(valueX - labelX, 1):diffuse(color("#ffffff")):diffusealpha(0.14)
		end
	}
end
for i = 1, 3 do
	row(i, colAx, colAv, labelsA[i], "V" .. i)
	row(i, colBx, colBv, labelsB[i], "V" .. (i + 3))
end

return t
