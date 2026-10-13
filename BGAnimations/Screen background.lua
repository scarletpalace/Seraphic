return Def.Quad {
	InitCommand = function(self)
		self:xy(0, 0):halign(0):valign(0):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(color("#04060cBB"))
		self:diffusetopedge(color("#0b0b0bA8")):diffusebottomedge(color("#02030aD8"))
	end
}
