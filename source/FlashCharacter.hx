package;

import openfl.geom.ColorTransform;
import sys.thread.Thread;
import openfl.geom.Matrix;
import flixel.math.FlxPoint;
import openfl.display.PixelSnapping;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.MovieClip;
import openfl.events.Event;
import animateatlas.displayobject.SpriteMovieClip;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef FlashCharacterFile = {
	var animations:Array<FlashAnimArray>;
	var swf:String;
	var specialframes:Array<SpecialFrames>;
	var dimensions:Array<Int>;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;
	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var extAnims:Array<String>;
}

typedef SpecialFrames = {
	var frame:Int;
	var label:String;
	var type:String;
	var value:String;
}

typedef FlashAnimArray = {
	var label:String;
	var anim:String;
	var endFrame:Int;
	var loop:Bool;
	var offsets:Array<Int>;
}

class FlashCharacter extends Character
{
	public var clip:MovieClip = null;
	public var flAnim:String = 'idle';
	public var theMatrix:Matrix;
	public var theCTF:ColorTransform;
	public var allowUpdate:Bool = true;
	public var doFill:Bool = true;

	public var flAnimationsArray:Array<FlashAnimArray> = [];
	public var endFrames:Array<Int> = [];
	public var externalAnims:Array<String>;

	public var json:FlashCharacterFile;
	public var anims:Map<String,Array<Dynamic>>;
	public var currentAnim:String = 'idle';
	public var currentLoops:Bool = false;
	public var currentEndFrame:Int = 14;
	public var displayedFrame:Int = 2;
	
	public static var DEFAULT_CHARACTER:String = 'bf-flash'; //In case a character is missing, it will use BF on its place
	
	public function new(x:Float, y:Float, ?character:String = 'bf-flash', ?isPlayer:Bool = false)
	{
		super(x, y, '!!!SKIP');

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;
		var library:String = null;

		var characterPath:String = 'characters/' + curCharacter + '.json';

		var path:String = Paths.getPreloadPath(characterPath);
		if (!Assets.exists(path))
		{
			path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		var rawJson = Assets.getText(path);

		json = cast Json.parse(rawJson);

		clip = Assets.getMovieClip(json.swf+':');
		clip.enabled = false;
		clip.mouseEnabled = false;

		theMatrix = new Matrix();
		theCTF = new ColorTransform();

		flAnimationsArray = json.animations;
		anims = new Map<String,Array<Dynamic>>();
		externalAnims = json.extAnims;
		if (json.extAnims.contains('singLEFTmiss')) { hasMissAnimations = true; }

		if(flAnimationsArray != null && flAnimationsArray.length > 0) {
			for (anim in flAnimationsArray) {
				var animLabel:String = '' + anim.label;
				var animName:String = '' + anim.anim;
				var animLoop:Bool = !!anim.loop; //Bruh
				
				endFrames.push(anim.endFrame);

				anims.set(animName, [animLabel, anim.endFrame, animLoop]);

				if(anim.offsets != null && anim.offsets.length > 1) {
					addOffset(anim.label, anim.offsets[0], anim.offsets[1]);
				}
			}
		}

		clip.x = clip.y = 9999;
		//FlxG.stage.addChildAt(clip,0);
		FlxG.stage.addChild(clip);

		positionArray = json.position;
		cameraPosition = json.camera_position;

		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = !!json.flip_x;
		if(json.no_antialiasing) {
			antialiasing = false;
			noAntialiasing = true;
		}

		if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
			healthColorArray = json.healthbar_colors;

		antialiasing = !noAntialiasing;
		if(!ClientPrefs.globalAntialiasing) antialiasing = false;

		originalFlipX = flipX;
		if (isPlayer) { flipX = !flipX; }

		if (json.extAnims.contains('idle')) {
			this.alpha = 0.00001;
		}

		recalculateDanceIdle();
		if (anims.exists('idle')) {
			playAnim('idle');
		}

		this.makeGraphic(json.dimensions[0], json.dimensions[1], 0x00000000, true, Std.string(this.ID) );

		//clip.addEventListener(Event.ENTER_FRAME, clipUpd);

		if(json.scale != 1) {
			jsonScale = json.scale;
			setGraphicSize(Std.int(json.dimensions[0] * jsonScale));
			updateHitbox();
		}
	}

	public function sneaky(clp:MovieClip) {
		@:privateAccess
		clp.__worldVisible = false;
	}

	function clipUpd(ev:Event)
	{
		var curFrame:Int = clip.currentFrame;
		if (curFrame >= currentEndFrame && clip.isPlaying) {
			if (currentLoops) {
				clip.gotoAndPlay(currentAnim);
			}
			else {
				flAnim = null;
				clip.gotoAndStop(currentEndFrame);
			}
		}
		if (displayedFrame != curFrame) {
			displayedFrame = curFrame;
			graphic.bitmap.fillRect(graphic.bitmap.rect, 0x00000000);
			graphic.bitmap.draw(clip);
		}
	}
	
	override function destroy()
	{
		//clip.removeEventListener(Event.ENTER_FRAME, clipUpd);
		allowUpdate = false;
		FlxG.stage.removeChild(clip);
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && currentAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed * PlayState.instance.playbackRate;
				if(heyTimer <= 0)
				{
					if(specialAnim && currentAnim == 'hey' || currentAnim == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if(specialAnim && flAnim == null)
			{
				specialAnim = false;
				dance();
			}

			if (!isPlayer)
			{
				if (currentAnim.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if(flAnim == null && anims.exists(currentAnim + '-loop'))
			{
				playAnim(currentAnim + '-loop');
			}
		}

		if (linked != null) { 
			linked.holdTimer = holdTimer;
			linked.heyTimer = heyTimer;
		}

		if (allowUpdate) { 
			if (clip.currentFrame >= currentEndFrame && clip.isPlaying) {
				if (currentLoops) { clip.gotoAndPlay(currentAnim); }
				else {
					flAnim = null;
					clip.gotoAndStop(currentEndFrame);
				}
			}
			if (displayedFrame != clip.currentFrame) {
				displayedFrame = clip.currentFrame;
				if (doFill) { graphic.bitmap.fillRect(graphic.bitmap.rect, 0x00000000); }
				graphic.bitmap.draw(clip);
			}
		}
		
		super.update(elapsed);
	}

	public override function dance()
	{
		if (!debugMode && !skipDance && !specialAnim) {
			if(danceIdle) {
				danced = !danced;
				if (danced) { playAnim('danceRight' + idleSuffix); }
				else { playAnim('danceLeft' + idleSuffix); }
			}
			else if (anims.exists('idle' + idleSuffix)) {
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public override function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		if (json.extAnims.contains(AnimName)) {
			if (linked != null) {
				linked.alpha = 1.0;
				if (clip.isPlaying) {clip.stop();}
				flAnim = AnimName;
				currentAnim = AnimName;
				this.alpha = 0.00001;
				allowUpdate = false;
				linked.playAnim(AnimName,Force,Reversed,Frame);
			}
			return;
		}
		else {
			if (linked != null) {
				linked.alpha = 0.00001;
				allowUpdate = true;
				this.alpha = 1.0;
				linked.animation.stop();
			}
		}
		var toplay:String = anims[AnimName][0];
		if (!Force && (flAnim == toplay)) {
			return;
		}
		specialAnim = false;
		//implement REVERSED & FRAME
		flAnim = AnimName;
		currentAnim = AnimName;
		currentLoops = anims[currentAnim][2];
		currentEndFrame = anims[currentAnim][1];
		
		clip.gotoAndPlay(toplay);
		/*
		if (animOffsets.exists(AnimName)) {
			var daOffset = animOffsets.get(AnimName);
			 offset.set(daOffset[0], daOffset[1]);
		}
		else { offset.set(0, 0); }
		*/
	}
	
	override function loadMappedAnims():Void
	{
		//nah
	}

	public override function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (anims.exists('danceLeft'+idleSuffix) && anims.exists('danceRight'+idleSuffix));

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
			flAnim = 'danceLeft'+idleSuffix;
		}
		settingCharacterUp = false;
	}

	public override function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public override function quickAnimAdd(name:String, anim:String)
	{
		//no thanks
	}

	override function get_curAnim():Dynamic
	{
		return currentAnim;
	}
	
	override function set_curAnim(an:flixel.animation.FlxAnimation):Dynamic
	{
		return currentAnim;
	}

	override function get_curAnimName():Null<String>
	{
		return currentAnim;
	}
		
	override function set_curAnimName(an:String):Null<String>
	{
		return currentAnim = an;
	}
}
