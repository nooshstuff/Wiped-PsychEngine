package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

using StringTools;

class FlashBoyfriend extends FlashCharacter
{
	public function new(x:Float, y:Float, ?char:String = 'bf') {
		super(x, y, char, true);
	}

	override function update(elapsed:Float) {
		if (!debugMode && currentAnim != null) {
			if (currentAnim.startsWith('sing')) {
				holdTimer += elapsed;
			}
			else {
				holdTimer = 0;
			}

			if (currentAnim.endsWith('miss') && flAnim == null && !debugMode) {
				playAnim('idle', true, false, 10);
			}
			if (currentAnim == 'firstDeath' && flAnim == null && startedDeath) {
				playAnim('deathLoop');
			}
		}
		super.update(elapsed);
	}
}
