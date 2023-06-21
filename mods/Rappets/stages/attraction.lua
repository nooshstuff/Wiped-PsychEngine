function onCreatePost()

	makeLuaSprite('colors', 'attraction/colohs', 65.15 * 1.5, 879.5 * 1.025)
	setScrollFactor('colors', 1.1, 1.1)
	
	setObjectOrder('colors', 12)
	
	setProperty('iconP2.y', getProperty('iconP2.y') - 10)
	addHaxeLibrary('ColorSwap')
	runHaxeCode([[
		coolors = new ColorSwap();
		game.getLuaObject('colors').shader = coolors.shader;
		FlxTween.tween(coolors, {hue: 1}, (Conductor.crochet / 1000) * 3.2, {type: 2});
				]])
end

function onCountdownTick(counter)
	beatHitDance(counter);
end

function onBeatHit()
	beatHitDance(curBeat);
end