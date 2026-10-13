return Def.Quad {
	InitCommand = function(self)
		self:setsize(1, 12):diffuse(color("#8f93aa")):diffusealpha(0.85)
		self:diffusetopedge(color("#c9cde0")):diffusebottomedge(color("#4b4e63"))
	end
}
