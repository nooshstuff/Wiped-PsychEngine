function onSectionHit()
	if gfSection and getProperty('dad.idleSuffix') ~= '-alt' then
		setProperty('dad.idleSuffix', '-alt')
		runHaxeCode([[
			game.dad.dance();
					]])
	elseif not gfSection and getProperty('dad.idleSuffix') == '-alt' then
		setProperty('dad.idleSuffix', '')
		runHaxeCode([[
			game.dad.dance();
					]])
	end
end