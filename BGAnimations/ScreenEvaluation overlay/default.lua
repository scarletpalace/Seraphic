-- Seraphic: the results layout uses the whole screen (its windows reach from the top edge to the bottom edge),
-- so this overlay draws no top/bottom bars, screen title, profile block or stage emblem over it; only the cursor.
local t = Def.ActorFrame {}

t[#t + 1] = LoadActor("../_cursor")

return t
