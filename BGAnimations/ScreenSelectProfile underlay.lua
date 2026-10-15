-- Seraphic: the same sanctuary as the title menu, with the rose window behind the profile card
-- (kept in a local: "return LoadActor(...)" is a tail call, and LoadActor then can't find this file's folder)
local t = LoadActor("_sanctuary", SCREEN_CENTER_Y)
return t
