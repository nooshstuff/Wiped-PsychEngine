function onCreatePost()
	if isStoryMode then
		setProperty('cameraSpeed', 0)
		setProperty('camGame.zoom', 0.7)
	end
end

function onSongStart()
	if isStoryMode then
		setProperty('cameraSpeed', 1)
		setProperty('camZooming', true)
	end
end

function linerp(a, b, ratio)
	return a + ratio * (b - a)
end

local sc = 0
local vel = 16
local deer = 1

function onUpdate(el)
	sc = linerp(sc, 0, el*6)

	vel = linerp(vel, 16, el*6)

	local valoo = vel*deer*el
	local scol = 6+sc
	local scal = 6-(sc/2)

	runHaxeCode([[
		for (msh in game.threeD.meshs) {
			if (msh != null) {
				msh.scaleX =]]..scol..[[;
				msh.scaleZ =]]..scal..[[;
				msh.rotationY += ]]..valoo..[[;
			}
		}
	]])

end

function goodNoteHit(id, dir, NT, sus)
	if (dir < 2) then
		vel = vel + 256
		deer = 1
	else
		vel = vel + 256
		deer = -1
	end
end

function onBeatHit()
	sc = 2
	if curBeat == 95 then
		for i,sprites in pairs({'gfGroup', 'boyfriendGroup', 'colors'}) do
			doTweenColor(sprites..'Color', sprites, '949494', (stepCrochet / 1000) * 2)
		end
		setProperty('dad.stunned', true)
		setProperty('dad.specialAnim', false)
	elseif curBeat == 96 then
		setProperty('dad.stunned', false)
		for i,sprites in pairs({'gfGroup', 'boyfriendGroup', 'colors'}) do
			doTweenColor(sprites..'Color', sprites, 'FFFFFF', (stepCrochet / 1000) * 2)
		end
	end
end