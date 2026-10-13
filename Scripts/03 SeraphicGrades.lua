-- Seraphic rank emblems (from the LR2 skin): quint=AAAAA quad=AAAA 1=AAA 2=AA 3=A 4=B 5=C 6=D 7=F
-- Etterna's finer tiers (AAAA:, AAAA., AA:, AA., A: ...) share the emblem of their letter.
function seraphicGradeIndex(grade)
	if grade == nil or grade == "Grade_None" then return nil end
	local n = tonumber(tostring(grade):match("Tier(%d+)")) or 17
	return (n == 1 and "quint") or (n <= 4 and "quad") or (n <= 7 and 1) or (n <= 10 and 2) or (n <= 13 and 3)
		or (n == 14 and 4) or (n == 15 and 5) or (n == 16 and 6) or 7
end

function seraphicGradePath(k)
	return THEME:GetPathG("", "seraphic_rankglyph_" .. k)
end

-- width of the visible lettering inside each emblem image (all are ~27px tall;
-- 1..7 are 74x32, quad is 90x32, quint is 108x32)
seraphicGradeInkWidth = {54, 36, 19, 19, 17, 21, 18, quad = 71, quint = 89}

-- load emblem k into a sprite at the given zoom, shrinking it if its lettering would exceed maxInk px
function seraphicGradeFit(sprite, k, z, maxInk)
	sprite:Load(seraphicGradePath(k))
	local ink = seraphicGradeInkWidth[k]
	if maxInk and ink and ink * z > maxInk then
		z = maxInk / ink
	end
	sprite:zoom(z)
	return sprite
end
