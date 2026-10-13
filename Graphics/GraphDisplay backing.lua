-- Seraphic: gothic life graph backing. Must stay a single Quad: the engine zooms it to the graph size.
return Def.Quad {
	InitCommand = function(self)
		self:setsize(256, 80):diffuse(color("#0b0710")):diffusealpha(0.92)
		self:diffusetopedge(color("#1d1426F0")):diffusebottomedge(color("#07040bF0"))
	end
}
