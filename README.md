TMXTileMap (JSTileMap) is a TMX Map Model extractor written in Objective-C
=========
If you are looking for TMX (Tiled Map Editor http://www.mapeditor.org/) model parser, you are on a good place. Objective-C TMX parsers that I found were already bound with some rendering engine (SpriteKit, Cocos2d, etc). If you are using another rendering engine or you already have one in SpriteKit, but you would not like to add any engine-related code to your project, TMXTileMap can be a right solution for you.

TMXTileMap was created by forking existing project JSTileMap (https://github.com/slycrel/JSTileMap, big thanks to authors) and refactoring the code. The original project includes SpriteKit logic and TMX Parsing in one class. My contribution simply consisted of refactoring the code and extracting the TMX parsing/model creation part of code to seperate classes (check TMXTileMap.h/.m).

However, you can still use JSTileMap.h./.m in you project, but these classes will only consist of code related to SpriteKit.

Include

	TMXTileMap.m
	TMXTileMap.h
	LFCGzipUtility.h
	LFCGzipUtility.m

In your project.  You will also need to add libz.dylib to the "linked
frameworks and libraries" section of your project itself.

Loading a map
=========

	...
	TMXTileMap* tiledMap = [TMXTileMap mapNamed:@"mapFileName.tmx"];
	...

Description of JSTileMap
=========

Browse the properties in TMXTileMap and TMXTileLayer for most of what you'll use 
frequently.  Limited accessor methods are included for convenience.

Tile atlases are expected to be in the same directory as the TMX file when loaded.  
At the moment this is only trying to load files from the app bundle itself.

The repository also contains an example project, containing the above files, that 
will give you a general idea of how layers, tilesets, and objects work, and a 
few examples of what does (and does not) currently work.

** NOTE:  The TMX map format is in pixels, not points like apple's format.  As 
such, you should -NOT- use the @2x format for your sprite atlas images or the 
map won't load properly.

** NOTE 2:  Isometric maps are currently considered to be in beta as 
there are bugs with tile object positioning in isometric maps.  If you do not 
use tile objects you should be able to use isometric maps.

Mac support works but there are points / pixels issues with the atlas images.  Should
be considered beta.
