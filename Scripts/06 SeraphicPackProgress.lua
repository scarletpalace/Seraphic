-- Pack progress for the song list: how many songs in a pack have their best score
-- (at 1.0x or faster, any difficulty) in each grade family. Cached per pack;
-- the cache is dropped whenever a new score is set (Scripts/05 SeraphicSession.lua).
SeraphicPackProgressCache = {}

-- grade families, best first; colour comes from getGradeColor of the family's grade
SeraphicPackProgressFamilies = {
	{name = "AAAA", grade = "Grade_Tier04"},
	{name = "AAA", grade = "Grade_Tier07"},
	{name = "AA", grade = "Grade_Tier10"},
	{name = "A", grade = "Grade_Tier13"},
	{name = "B-", grade = "Grade_Tier14"}
}

local function familyOf(grade)
	if type(grade) ~= "string" then return nil end
	if grade == "Grade_Failed" then return 5 end
	local tier = tonumber(grade:match("Tier(%d+)"))
	if not tier then return nil end
	if tier <= 4 then return 1 end
	if tier <= 7 then return 2 end
	if tier <= 10 then return 3 end
	if tier <= 13 then return 4 end
	return 5
end

-- best wife score and its grade over every chart of a song, rates of 1.0x and up
local function songBest(song)
	local bestWife, bestGrade = -1, nil
	local charts
	pcall(function() charts = song:GetChartsOfCurrentGameMode() end)
	if not charts then pcall(function() charts = song:GetAllSteps() end) end
	for _, steps in ipairs(charts or {}) do
		pcall(function()
			local byRate = SCOREMAN:GetScoresByKey(steps:GetChartKey())
			if not byRate then return end
			for rate, list in pairs(byRate) do
				local r = tonumber((tostring(rate):gsub("x", ""))) or 0
				if r >= 0.999 then
					local top = list:GetScores()[1]
					if top then
						local w = top:GetWifeScore()
						if w > bestWife then
							bestWife, bestGrade = w, top:GetWifeGrade()
						end
					end
				end
			end
		end)
	end
	return bestGrade
end

-- {total = songs, counts = {AAAA, AAA, AA, A, B-}} for a pack, or nil when it has no songs
function SeraphicPackProgress(pack)
	if not pack or pack == "" then return nil end
	local cached = SeraphicPackProgressCache[pack]
	if cached then return cached end
	local songs
	pcall(function() songs = SONGMAN:GetSongsInGroup(pack) end)
	if not songs or #songs == 0 then return nil end
	local c = os.clock()
	local out = {total = #songs, counts = {0, 0, 0, 0, 0}}
	for _, song in ipairs(songs) do
		local f = familyOf(songBest(song))
		if f then out.counts[f] = out.counts[f] + 1 end
	end
	SeraphicPackProgressCache[pack] = out
	local took = os.clock() - c
	if took > 0.01 then Warn(string.format("[Seraphic] pack progress %s: %.3fs", pack, took)) end
	return out
end

-- drop one pack's cached counts (a score was set in it), or all of them when no pack is given
function SeraphicPackProgressReset(pack)
	if pack then
		SeraphicPackProgressCache[pack] = nil
	else
		SeraphicPackProgressCache = {}
	end
end
