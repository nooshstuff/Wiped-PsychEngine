package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class BackgroundDancer extends FlxSprite
{
	public function new(x:Float, y:Float, ?sprite:String = "limo/limoDancer")
	{
		super(x, y);

		frames = Paths.getSparrowAtlas(sprite);
		animation.addByPrefix('danceLeft', 'danceLeft', 24, false);
		animation.addByPrefix('danceRight', 'danceRight', 24, false);
		animation.play('danceLeft');
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	var danceDir:Bool = false;

	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir)
			animation.play('danceRight', true);
		else
			animation.play('danceLeft', true);
	}
}
