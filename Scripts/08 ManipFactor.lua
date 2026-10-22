-- Manip Factor (MF), ported from ManipFactorEtterna by MaidOfFire: https://github.com/MaidOfFire/ManipFactorEtterna
-- Estimates how much a play hits one-hand misaligned notes (trills, streams) as if they were aligned (jumps).
-- For every note on a column, the closest earlier note on the other column of the same hand is taken and
-- |error_B - error_A| is divided by half the average interval between notes on a column; pairs past 1.5 are
-- dropped and the rest averaged. 0 is clean, around 0.4 and up is heavy manip. 4 key only.
--
-- seraManipFactor(score) returns {total, left, right, rate, at = function(ms)} or nil (no replay data, not 4k);
-- at(ms) is the total MF of the notes up to that point of the play (ms of real time, i.e. already divided by rate).
-- Results are cached by score key, since the result screen asks again on every judge or score change.

local eps = 0.1

local function percentile(sorted, p)
	local index = (p / 100) * (#sorted - 1) + 1
	local lo, hi = math.floor(index), math.ceil(index)
	local frac = index - lo
	if frac == 0 then return sorted[lo] end
	return sorted[lo] + frac * (sorted[hi] - sorted[lo])
end

-- mean interval between consecutive notes of a column, leaving out the 5% shortest and longest
local function avgInterval(times)
	local diffs = {}
	for i = 2, #times do
		local d = times[i] - times[i - 1]
		if d ~= 0 then diffs[#diffs + 1] = d end
	end
	if #diffs == 0 then return nil end
	table.sort(diffs)
	local low, high = percentile(diffs, 5), percentile(diffs, 95)
	local sum, n = 0, 0
	for _, d in ipairs(diffs) do
		if d > low - eps and d < high + eps then
			sum = sum + d
			n = n + 1
		end
	end
	if n == 0 then return nil end
	return sum / n
end

-- {time, error} per note of a column (no mines or hold tails), sorted by time; nil with less than 2 notes
local function columnData(offsets, times, tracks, types, col)
	local out = {}
	for i = 1, #offsets do
		local ty = types[i]
		if tracks[i] == col and times[i] and ty ~= "TapNoteType_Mine" and ty ~= "TapNoteType_HoldTail" then
			out[#out + 1] = {times[i], offsets[i]}
		end
	end
	if #out < 2 then return nil end
	table.sort(out, function(a, b) return a[1] < b[1] end)
	return out
end

-- normalized error differences of each note of column A against the last earlier note of column B:
-- returns the note times and the prefix sums of the deviations (so the MF up to any time is a lookup)
local function deviations(a, b)
	local ta, tb = {}, {}
	for i = 1, #a do ta[i] = a[i][1] end
	for i = 1, #b do tb[i] = b[i][1] end
	local ia, ib = avgInterval(ta), avgInterval(tb)
	if not ia or not ib then return {times = {}, sums = {}} end
	-- average of both columns, halved (for trills)
	local interval = (ia + ib) / 4

	local times, sums = {}, {}
	local total = 0
	local finder = 1
	for i = 1, #a do
		local timeA, errorA = a[i][1], a[i][2]
		local lastB
		for j = finder, #b do
			if b[j][1] < timeA - eps then
				lastB = b[j]
				finder = j
			else
				break
			end
		end
		if lastB then
			local dev = math.abs((lastB[2] - errorA) / interval)
			if dev <= 1.5 then
				total = total + dev
				times[#times + 1] = timeA
				sums[#sums + 1] = total
			end
		end
	end
	return {times = times, sums = sums}
end

-- sum and count of the deviations of a pair up to time ms (all of them when ms is nil)
local function upTo(d, ms)
	local n = #d.times
	if ms and n > 0 and d.times[n] > ms then
		local lo, hi = 0, n
		while lo < hi do
			local mid = math.floor((lo + hi + 1) / 2)
			if d.times[mid] <= ms then lo = mid else hi = mid - 1 end
		end
		n = lo
	end
	return n > 0 and d.sums[n] or 0, n
end

-- count-weighted mean over the given pairs
local function combine(pairs_, ms)
	local sum, n = 0, 0
	for _, d in ipairs(pairs_) do
		local s, c = upTo(d, ms)
		sum = sum + s
		n = n + c
	end
	if n == 0 then return 0 end
	return sum / n
end

local function compute(score)
	local steps = GAMESTATE:GetCurrentSteps()
	if not steps or steps:GetNumColumns() ~= 4 then return nil end
	local replay = score:GetReplay()
	if not replay then return nil end
	replay:LoadAllData()
	-- (online replays can miss any of these)
	local offsets = replay:GetOffsetVector()
	local tracks = replay:GetTrackVector()
	local rows = replay:GetNoteRowVector()
	if not offsets or not tracks or not rows or #offsets == 0 or #tracks == 0 or #rows == 0 then return nil end
	local types = replay:GetTapNoteTypeVector() or {}

	local rate = score:GetMusicRate()
	if not rate or rate <= 0 then rate = 1 end
	local td = steps:GetTimingData()
	local times = {}
	for i = 1, #rows do
		times[i] = td:GetElapsedTimeFromNoteRow(rows[i]) / rate * 1000
	end

	local cols = {}
	for c = 0, 3 do
		cols[c] = columnData(offsets, times, tracks, types, c)
	end
	local left, right = {}, {}
	if cols[0] and cols[1] then
		left = {deviations(cols[0], cols[1]), deviations(cols[1], cols[0])}
	end
	if cols[2] and cols[3] then
		right = {deviations(cols[2], cols[3]), deviations(cols[3], cols[2])}
	end
	local all = {}
	for _, d in ipairs(left) do all[#all + 1] = d end
	for _, d in ipairs(right) do all[#all + 1] = d end

	return {
		total = combine(all),
		left = combine(left),
		right = combine(right),
		rate = rate,
		at = function(ms) return combine(all, ms) end,
	}
end

local cache = {}

function seraManipFactor(score)
	if not score then return nil end
	local okK, key = pcall(function() return score:GetScoreKey() end)
	local okR, rate = pcall(function() return score:GetMusicRate() end)
	key = okK and key and (key .. "@" .. tostring(okR and rate or "")) or nil
	if key and cache[key] then return cache[key] end
	local ok, mf = pcall(compute, score)
	if not ok then
		Trace("Seraphic: manip factor failed: " .. tostring(mf))
		return nil
	end
	-- (a result without one is not kept: an online score's replay may still be on its way)
	if mf and key then cache[key] = mf end
	return mf
end

-- green (clean) to red (0.4 and up)
function seraManipFactorColor(x)
	x = math.min(math.max(x or 0, 0), 0.4)
	return HSV(120 - x * 300, 0.7, 0.95)
end
