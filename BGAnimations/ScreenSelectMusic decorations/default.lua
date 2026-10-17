local t = Def.ActorFrame {}
-- Seraphic: load-time measurement, written to the log as "[Seraphic] ..." lines. For each part it logs the time
-- to read its file and the time to build its actors (a marker actor before and after it in this frame).
local clock0 = os.clock()
if SeraphicStamp then SeraphicStamp("decorations start") end
local mark = 0
local function timed(name)
	local c = os.clock()
	local a = LoadActor(name)
	local readTime = os.clock() - c
	t[#t + 1] = Def.Actor {InitCommand = function() mark = os.clock() end}
	t[#t + 1] = a
	return Def.Actor {
		InitCommand = function()
			Warn(string.format("[Seraphic] %s: file %.3fs, actors %.3fs", name, readTime, os.clock() - mark))
		end
	}
end

t[#t + 1] = timed("../_topbar")
t[#t + 1] = timed("wifetwirl")
t[#t + 1] = timed("msd")
t[#t + 1] = timed("songsearch")
t[#t + 1] = timed("score")
t[#t + 1] = timed("profile")
t[#t + 1] = timed("filter")
t[#t + 1] = timed("goaltracker")
t[#t + 1] = timed("playlists")
t[#t + 1] = timed("playlistwheel")
t[#t + 1] = timed("downloads")
t[#t + 1] = timed("tags")
t[#t + 1] = timed("stepsdisplay")

t[#t + 1] = timed("../_mousewheelscroll")
collectgarbage()
Warn(string.format("[Seraphic] decorations files read in %.3fs", os.clock() - clock0))
t[#t + 1] = Def.Actor {
	InitCommand = function()
		Warn(string.format("[Seraphic] decorations built in %.3fs", os.clock() - clock0))
		if SeraphicStamp then SeraphicStamp("decorations init done") end
	end
}
return t
