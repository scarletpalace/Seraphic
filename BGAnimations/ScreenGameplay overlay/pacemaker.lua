--[[
	BMS-style pacemaker graph: three bars for the current score (red), the target (green) and the
	personal best on this chart at this rate (blue), with lines at the grade thresholds.

	Each bar's outline is the percent it stands at (current wife%, target goal, PB wife%) and its fill
	is that percent times how much of the chart has been judged, so the fill reaches the outline at the end.
	Etterna percents bunch up near 100%, so heights use a piecewise scale that spreads the grade lines out.
]]
local allowedCustomization = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).CustomizeGameplay
local graphH = 170
local barW = 24
local barGap = 6
local graphW = barW * 3 + barGap * 4
local graphTop = 26 -- below the rank / percent header
local graphBottom = graphTop + graphH
-- backdrop box, relative to the frame's top-left origin
local boxX, boxY = -4, -4
local boxW, boxH = graphW + 8, graphBottom + 34

local curColor = color("#ff4848")
local targetColor = color("#88dd33")
local bestColor = color("#3388ff")

-- percent -> share of the graph height
local scale = {
	{0, 0},
	{80, 0.40}, -- A
	{93, 0.58}, -- AA
	{99.7, 0.76}, -- AAA
	{99.955, 0.90}, -- AAAA
	{100, 1}
}
local function heightOf(p)
	if not p or p <= 0 then return 0 end
	if p >= 100 then return graphH end
	for i = 2, #scale do
		local a, b = scale[i - 1], scale[i]
		if p <= b[1] then
			return graphH * (a[2] + (b[2] - a[2]) * (p - a[1]) / (b[1] - a[1]))
		end
	end
	return graphH
end

local lines = {
	{"MAX", 100},
	{"AAAA", 99.955},
	{"AAA", 99.7},
	{"AA", 93},
	{"A", 80}
}

local grades = {
	{99.9935, "AAAAA", "Grade_Tier01"},
	{99.955, "AAAA", "Grade_Tier04"},
	{99.7, "AAA", "Grade_Tier07"},
	{93, "AA", "Grade_Tier10"},
	{80, "A", "Grade_Tier13"},
	{70, "B", "Grade_Tier14"},
	{60, "C", "Grade_Tier15"}
}
local function gradeOf(p)
	for _, g in ipairs(grades) do
		if p >= g[1] then return g[2], g[3] end
	end
	return "D", "Grade_Tier16"
end

local target = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).TargetGoal
local pb -- best wife score (0-1) on this chart at the current rate, nil if none
local totalPoints = 0 -- max wife points on the whole chart
local wifePercent = 0
local progress = 0 -- share of the chart judged so far
local targetDiff = 0
local bestDiff
local judgedTaps = 0 -- only used when the engine doesn't send MaxWifeScore / TotalPercent
local autoplay = false

-- the engine sinks the wife score on every autoplay judgment on purpose,
-- so while autoplay is on (always the case in Customize Gameplay) its numbers are meaningless
local function isAutoplay()
	local controller = GAMESTATE:GetPlayerState():GetPlayerController()
	return controller == "PlayerController_Autoplay" or controller == "PlayerController_Cpu"
end

local function loadChart()
	pb = nil
	totalPoints = 0
	local steps = GAMESTATE:GetCurrentSteps()
	if not steps then return end
	pcall(function()
		totalPoints = steps:GetRadarValues(PLAYER_1):GetValue("RadarCategory_Notes") * 2
	end)
	pcall(function()
		local rate = getCurRateValue()
		local byRate = SCOREMAN:GetScoresByKey(steps:GetChartKey())
		if not byRate then return end
		for r, list in pairs(byRate) do
			local rv = tonumber((tostring(r):gsub("x", ""))) or 0
			if math.abs(rv - rate) < 0.001 then
				for _, s in ipairs(list:GetScores()) do
					local w = s:GetWifeScore()
					if w > 0 and (not pb or w > pb) then pb = w end
				end
			end
		end
	end)
end

local function reset()
	wifePercent = 0
	progress = 0
	judgedTaps = 0
	targetDiff = 0
	bestDiff = pb and 0 or nil
end

local function bar(name, col)
	return Def.ActorFrame {
		Name = name,
		Def.Quad {
			Name = "Fill",
			InitCommand = function(self)
				self:valign(1):halign(0):zoomto(barW, 0):diffuse(col)
			end
		},
		-- outline: two sides and a top
		Def.Quad {
			Name = "Left",
			InitCommand = function(self)
				self:valign(1):halign(0):zoomto(1, 0):diffuse(color("#ffffff")):diffusealpha(0.8)
			end
		},
		Def.Quad {
			Name = "Right",
			InitCommand = function(self)
				self:valign(1):halign(1):x(barW):zoomto(1, 0):diffuse(color("#ffffff")):diffusealpha(0.8)
			end
		},
		Def.Quad {
			Name = "Top",
			InitCommand = function(self)
				self:valign(0.5):halign(0):zoomto(barW, 1):diffuse(color("#ffffff")):diffusealpha(0)
			end
		},
		SetBarCommand = function(self, params)
			local h = heightOf(params.percent)
			local fill = self:GetChild("Fill")
			fill:finishtweening():linear(0.05):zoomy(h * progress)
			self:GetChild("Left"):zoomy(h)
			self:GetChild("Right"):zoomy(h)
			self:GetChild("Top"):y(-h):diffusealpha(h > 0 and 0.8 or 0)
			self:diffusealpha(params.percent and 1 or 0.25)
		end
	}
end

local function diffText(v)
	if not v then return "--" end
	return string.format("%+.2f", v)
end

local t = Def.ActorFrame {
	Name = "PaceMaker",
	InitCommand = function(self)
		self:xy(MovableValues.PaceMakerX, MovableValues.PaceMakerY):zoom(MovableValues.PaceMakerZoom)
		if allowedCustomization then
			Movable.PaceMakerPosition.element = self
			Movable.PaceMakerSize.element = self
			Movable.PaceMakerSize.Border = self:GetChild("Border")
			Movable.PaceMakerPosition.condition = true
			Movable.PaceMakerSize.condition = true
			Movable.PaceMakerPosition.propertyOffsets = {
				(boxX + boxW / 2) * MovableValues.PaceMakerZoom,
				(boxY + boxH / 2) * MovableValues.PaceMakerZoom
			}
		end
		loadChart()
		reset()
	end,
	OnCommand = function(self)
		self:playcommand("Update")
	end,
	DoneLoadingNextSongMessageCommand = function(self)
		loadChart()
		reset()
		self:playcommand("Update")
	end,
	PracticeModeResetMessageCommand = function(self)
		reset()
		self:playcommand("Update")
	end,
	JudgmentMessageCommand = function(self, msg)
		if msg.WifePercent == nil then return end
		autoplay = isAutoplay()
		if autoplay then
			wifePercent = 0
			targetDiff = nil
		else
			wifePercent = msg.WifePercent
			if msg.WifeDifferential ~= nil then targetDiff = msg.WifeDifferential end
		end
		local cur, max = msg.CurWifeScore, msg.MaxWifeScore
		if max and totalPoints > 0 then
			progress = math.min(1, max / totalPoints)
		elseif msg.TotalPercent and wifePercent > 0 then
			progress = math.min(1, msg.TotalPercent / wifePercent)
		elseif msg.TapNoteScore and not msg.HoldNoteScore and totalPoints > 0
			and msg.TapNoteScore ~= "TapNoteScore_HitMine" and msg.TapNoteScore ~= "TapNoteScore_AvoidMine" then
			judgedTaps = judgedTaps + 1
			progress = math.min(1, judgedTaps * 2 / totalPoints)
		end
		if pb and autoplay then
			bestDiff = nil
		elseif pb then
			if cur and max then
				bestDiff = cur - max * pb
			elseif msg.WifePBDifferential ~= nil and msg.WifePBGoal == pb then
				bestDiff = msg.WifePBDifferential
			end
		end
		self:playcommand("Update")
	end,

	-- backdrop
	Def.Quad {
		InitCommand = function(self)
			self:halign(0):valign(0):xy(boxX, boxY):zoomto(boxW, boxH)
			self:diffuse(color("#000000")):diffusealpha(0.55)
		end
	},
	LoadFont("Common Normal") .. {
		Name = "Rank",
		InitCommand = function(self)
			self:halign(0):valign(0):zoom(0.45)
		end,
		UpdateCommand = function(self)
			if autoplay then
				self:settext("AUTOPLAY"):diffuse(color("#bbbbbb"))
				return
			end
			local name, tier = gradeOf(wifePercent)
			self:settext("RANK " .. name):diffuse(getGradeColor(tier))
		end
	},
	LoadFont("Common Normal") .. {
		Name = "Percent",
		InitCommand = function(self)
			self:halign(1):valign(0):x(graphW):zoom(0.45)
		end,
		UpdateCommand = function(self)
			if autoplay then
				self:settext("--")
				return
			end
			self:settextf("%.2f%%", wifePercent)
		end
	},
	LoadFont("Common Normal") .. {
		Name = "Rate",
		InitCommand = function(self)
			self:halign(0):valign(0):y(12):zoom(0.3):diffuse(color("#bbbbbb"))
		end,
		UpdateCommand = function(self)
			self:settextf("%.0f%% of chart", progress * 100)
		end
	},
	-- graph floor
	Def.Quad {
		InitCommand = function(self)
			self:halign(0):valign(0):xy(0, graphBottom):zoomto(graphW, 1):diffuse(color("#ffffff")):diffusealpha(0.6)
		end
	}
}

for _, l in ipairs(lines) do
	local y = graphBottom - heightOf(l[2])
	local isMax = l[1] == "MAX"
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:halign(0):valign(0.5):xy(0, y):zoomto(graphW, 1)
			self:diffuse(isMax and color("#ffdd44") or color("#8888ff")):diffusealpha(0.7)
		end
	}
	t[#t + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:halign(0):valign(1):xy(1, y - 1):zoom(0.28):settext(l[1])
			self:diffuse(isMax and color("#ffdd44") or color("#aaaaff"))
		end
	}
end

local bars = {
	{"Current", curColor, function() return wifePercent end},
	{"Target", targetColor, function() return target end},
	{"Best", bestColor, function() return pb and pb * 100 end}
}
for i, b in ipairs(bars) do
	t[#t + 1] = bar(b[1], b[2]) .. {
		InitCommand = function(self)
			self:xy(barGap + (i - 1) * (barW + barGap), graphBottom)
		end,
		UpdateCommand = function(self)
			self:playcommand("SetBar", {percent = b[3]()})
		end
	}
end

-- differentials below the graph, in wife points like the regular goal tracker
t[#t + 1] = LoadFont("Common Normal") .. {
	Name = "TargetDiff",
	InitCommand = function(self)
		self:halign(0):valign(0):y(graphBottom + 5):zoom(0.35):maxwidth(graphW / 0.35):diffuse(targetColor)
	end,
	UpdateCommand = function(self)
		self:settextf("TARGET %s (%g%%)", diffText(targetDiff), target)
	end
}
t[#t + 1] = LoadFont("Common Normal") .. {
	Name = "BestDiff",
	InitCommand = function(self)
		self:halign(0):valign(0):y(graphBottom + 17):zoom(0.35):maxwidth(graphW / 0.35):diffuse(bestColor)
	end,
	UpdateCommand = function(self)
		if pb then
			self:settextf("MYBEST %s (%.2f%%)", diffText(bestDiff), pb * 100)
		else
			self:settext("MYBEST no score at this rate")
		end
	end
}

-- drag handle for Customize Gameplay (nil otherwise)
t[#t + 1] = MovableBorder(boxW, boxH, 1, boxX + boxW / 2, boxY + boxH / 2)

return t
