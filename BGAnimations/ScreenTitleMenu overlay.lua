local t = Def.ActorFrame {}

t[#t+1] = LoadActor(THEME:GetPathG("", "_crashUploadOptIn"))

t[#t + 1] = LoadActor("_corners")
t[#t + 1] = LoadActor("_cursor")
return t
