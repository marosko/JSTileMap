//
//  JSTileMap.m
//  TMXMapSample
//
//  Created by Maros Galik on 5/2/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//

#import "JSTileMap.h"

#import "TMXTileMap.h"

@implementation TMXLayer

+(id) layerWithTilesetInfo:(NSArray*)tilesets
                 layerInfo:(TMXLayerInfo*)layerInfo
                   mapInfo:(TMXTileMap*)mapInfo
{
	TMXLayer* layer = [TMXLayer node];
    
    layer.tmxTileLayer = [[TMXTileLayer alloc] init];
    
    layer.tmxTileLayer.map = mapInfo;
	
	// basic properties from layerInfo
	layer.tmxTileLayer.layerInfo = layerInfo;
	layer.tmxTileLayer.layerInfo.layer = layer;
	layer.tmxTileLayer.mapTileSize = mapInfo.tileSize;
	layer.alpha = layerInfo.opacity;
	layer.position = layerInfo.offset;
	
	// recalc the offset if we are isometriic
	if (mapInfo.orientation == OrientationStyle_Isometric)
	{
		layer.position = CGPointMake((layer.tmxTileLayer.mapTileSize.width / 2.0) * (layer.position.x - layer.position.y),
									 (layer.tmxTileLayer.mapTileSize.height / 2.0) * (-layer.position.x - layer.position.y));
	}
	
	NSMutableDictionary* layerNodes = [NSMutableDictionary dictionaryWithCapacity:tilesets.count];
	
	// loop through the tiles
	for (int col = 0; col < layerInfo.layerGridSize.width; col++)
	{
		for (int row = 0; row < layerInfo.layerGridSize.height; row++)
		{
			// get the gID
			int gID = layerInfo.tiles[col + (int)(row * layerInfo.layerGridSize.width)];
			
			// mask off the flip bits and remember their result.
			bool flipX = (gID & kTileHorizontalFlag) != 0;
			bool flipY = (gID & kTileVerticalFlag) != 0;
			bool flipDiag = (gID & kTileDiagonalFlag) != 0;
			gID = gID & kFlippedMask;
			
			// skip 0 GIDs
			if (!gID)
				continue;
			
			// get the tileset for the passed gID.  This will allow us to support multiple tilesets!
			TMXTilesetInfo* tilesetInfo = [mapInfo tilesetInfoForGid:gID];
			[layer.tmxTileLayer.tileInfo addObject:tilesetInfo];
			
			if (tilesetInfo)	// should never be nil?
			{
				SKTexture* texture = [tilesetInfo textureForGid:gID];
				SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:texture];
				sprite.name = [NSString stringWithFormat:@"%d",(int)(col + row * layerInfo.layerGridSize.width)];
				
				// make sure it's in the right position.
				if (mapInfo.orientation == OrientationStyle_Isometric)
				{
					sprite.position = CGPointMake((layer.tmxTileLayer.mapTileSize.width / 2.0) * (layerInfo.layerGridSize.width + col - row - 1),
												  (layer.tmxTileLayer.mapTileSize.height / 2.0) * ((layerInfo.layerGridSize.height * 2 - col - row) - 2) );
				}
				else
				{
					sprite.position = CGPointMake(col * layer.tmxTileLayer.mapTileSize.width + layer.tmxTileLayer.mapTileSize.width/2.0,
												  (mapInfo.mapSize.height * (tilesetInfo.tileSize.height)) - ((row + 1) * layer.tmxTileLayer.mapTileSize.height) + layer.tmxTileLayer.mapTileSize.height/2.0);
				}
				
				// flip sprites if necessary
				if(flipDiag)
				{
					if(flipX)
						sprite.zRotation = -M_PI_2;
					else if(flipY)
						sprite.zRotation = M_PI_2;
				}
				else
				{
					if(flipY)
						sprite.yScale *= -1;
					if(flipX)
						sprite.xScale *= -1;
				}
				
				// add sprite to correct node for this tileset
				SKNode* layerNode = layerNodes[tilesetInfo.name];
				if (!layerNode) {
					layerNode = [[SKNode alloc] init];
					layerNodes[tilesetInfo.name] = layerNode;
				}
				[layerNode addChild:sprite];
                
#ifdef DEBUG
                NSLog(@"layer node added sprite: %f %f", sprite.position.x, sprite.position.y);
                //				CGRect textRect = [texture textureRect];
                //				NSLog(@"atlasNum %2d (%2d,%2d), gid (%d,%d), rect (%f, %f, %f, %f) sprite.pos (%3.2f,%3.2f) flipx%2d flipy%2d flipDiag%2d", gID+1, row, col, [tilesetInfo rowFromGid:gID], [tilesetInfo colFromGid:gID], textRect.origin.x, textRect.origin.y, textRect.size.width, textRect.size.height, sprite.position.x, sprite.position.y, flipX, flipY, flipDiag);
#endif
                
			}
		}
	}
	
	// add nodes for any tilesets that were used in this layer
	for (SKNode* layerNode in layerNodes.allValues) {
		if (layerNode.children.count > 0) {
			[layer addChild:layerNode];
		}
	}
	
	[layer calculateAccumulatedFrame];
	
	return layer;
}


-(CGFloat)layerWidth
{
    return self.tmxTileLayer.layerInfo.layerGridSize.width * self.tmxTileLayer.mapTileSize.width;
}

-(CGFloat)layerHeight
{
    return self.tmxTileLayer.layerInfo.layerGridSize.height * self.tmxTileLayer.mapTileSize.height;
}

- (CGPoint)pointForCoord:(CGPoint)coord
{
    return
    CGPointMake(coord.x * self.tmxTileLayer.mapTileSize.width + self.tmxTileLayer.mapTileSize.width / 2,
                [self layerHeight] - (coord.y * self.tmxTileLayer.mapTileSize.height + self.tmxTileLayer.mapTileSize.height / 2));
}

- (CGPoint) coordForPoint:(CGPoint) inPoint
{
	// invert y axis
	inPoint.y = [self layerHeight] - inPoint.y;
	
	int x = inPoint.x / self.tmxTileLayer.mapTileSize.height;
	int y = (int)inPoint.y / self.tmxTileLayer.mapTileSize.width;
	
	return CGPointMake(x, y);
}


- (SKSpriteNode*)tileAt:(CGPoint)point
{
    return [self tileAtCoord:[self coordForPoint:point]];
}

- (SKSpriteNode*)tileAtCoord:(CGPoint)coord
{
    NSString* nodeName = [NSString stringWithFormat:@"*/%d",(int)(coord.x + coord.y * self.tmxTileLayer.layerInfo.layerGridSize.width)];
    return (SKSpriteNode*)[self childNodeWithName:nodeName];
}

-(void)removeTileAtCoord:(CGPoint)coord
{
	uint32_t gid = [self.tmxTileLayer.layerInfo tileGidAtCoord:coord];
	
	if( gid )
	{
		int z = coord.x + coord.y * self.tmxTileLayer.layerInfo.layerGridSize.width;
		
		// remove tile from GID map
		self.tmxTileLayer.layerInfo.tiles[z] = 0;
		
		SKNode* tileNode = [self childNodeWithName:[NSString stringWithFormat:@"//%d",
													(int)(coord.x + coord.y * self.tmxTileLayer.layerInfo.layerGridSize.width)]];
		if(tileNode)
			[tileNode removeFromParent];
	}
}



@end

@implementation JSTileMap


- (CGPoint)screenCoordToPosition:(CGPoint)screenCoord
{
	CGPoint retVal;
	retVal.x = screenCoord.x / self.tmxMap.tileSize.width;
	retVal.y = screenCoord.y / self.tmxMap.tileSize.height;
	
	return retVal;
}

+ (JSTileMap*)mapNamed:(NSString*)mapName
{
	// zOrder offset.  Make this bigger if you want more space between layers.
	// higher numbers act further away.
	return [JSTileMap mapNamed:mapName withBaseZPosition:0.0f andZOrderModifier:-20.0f];
}

+ (JSTileMap*)mapNamed:(NSString*)mapName
      withBaseZPosition:(CGFloat)baseZPosition
      andZOrderModifier:(CGFloat)zOrderModifier
{
    TMXTileMap *tmxTileMap = [TMXTileMap mapNamed:mapName
                                withBaseZPosition:baseZPosition
                                andZOrderModifier:zOrderModifier];
    
    
    JSTileMap *jsTileMap = [[JSTileMap alloc] init];
    jsTileMap.tmxMap = tmxTileMap;
    
    // now actually using the data begins.
	
	// add layers
	for( TMXLayerInfo *layerInfo in tmxTileMap.layers )
	{
		if( layerInfo.visible )
		{
            
			TMXLayer *child = [TMXLayer layerWithTilesetInfo:tmxTileMap.tilesets layerInfo:layerInfo mapInfo:tmxTileMap];
			child.zPosition = baseZPosition + ((jsTileMap.tmxMap.zOrderCount - layerInfo.zOrderCount) * zOrderModifier);
#ifdef DEBUG
			NSLog(@"Layer %@ has zPosition %f", layerInfo.name, child.zPosition);
            NSLog(@"Layer %@ has position %f %f", layerInfo.name, child.position.x, child.position.y);
#endif
            
			[jsTileMap addChild:child];
		}
	}
	
	// add tile objects
	for (TMXObjectGroup* objectGroup in jsTileMap.tmxMap.objectGroups)
	{
#ifdef DEBUG
		NSLog(@"Object Group %@ has zPosition %f", objectGroup.groupName, (baseZPosition + (jsTileMap.tmxMap.zOrderCount - objectGroup.zOrderCount) * zOrderModifier));
#endif
		
		for (NSDictionary* obj in objectGroup.objects)
		{
			NSString* num = obj[@"gid"];
			if (num && [num intValue])
			{
				TMXTilesetInfo* tileset = [jsTileMap.tmxMap tilesetInfoForGid:[num intValue]];
				if (tileset)	// add a tile object if it is apropriate.
				{
					CGFloat x = [obj[@"x"] floatValue];
					CGFloat y = [obj[@"y"] floatValue];
					CGPoint pt;
					
					if (jsTileMap.tmxMap.orientation == OrientationStyle_Isometric)
					{
                        //#warning these appear to be incorrect for iso maps when used for tile objects!  Unsure why the math is different between objects and regular tiles.
						CGPoint coords = [jsTileMap screenCoordToPosition:CGPointMake(x, y)];
						pt = CGPointMake((jsTileMap.tmxMap.tileSize.width / 2.0) * (jsTileMap.tmxMap.tileSize.width + coords.x - coords.y - 1),
										 (jsTileMap.tmxMap.tileSize.height / 2.0) * (((jsTileMap.tmxMap.tileSize.height * 2) - coords.x - coords.y) - 2));
						
                        //  NOTE:
                        //	iso zPositioning may not work as expected for maps with irregular tile sizes.  For larger tiles (i.e. a box in front of some floor
                        //	tiles) We would need each layer to have their tiles ordered lower at the bottom coords and higher at the top coords WITHIN THE LAYER, in
                        //	addition to the layers being offset as described below. this could potentially be a lot larger than 20 as a default and may take some
                        //	thinking to fix.
					}
					else
					{
						pt = CGPointMake(x + (jsTileMap.tmxMap.tileSize.width / 2.0), y + (jsTileMap.tmxMap.tileSize.height / 2.0));
					}
					SKTexture* texture = [tileset textureForGid:[num intValue] - tileset.firstGid + 1];
					SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture:texture];
					sprite.position = pt;
					sprite.zPosition = baseZPosition + ((jsTileMap.tmxMap.zOrderCount - objectGroup.zOrderCount) * zOrderModifier);
#ifdef DEBUG
                    NSLog(@"Sprite has position %f %f", sprite.position.x, sprite.position.y);
#endif
					[jsTileMap addChild:sprite];
					
                    //#warning This needs to be optimized into tilemap layers like our regular layers above for performance reasons.
					// this could be problematic...  what if a single object group had a bunch of tiles from different tilemaps?  Would this cause zOrder problems if we're adding them all to tilemap layers?
				}
			}
		}
	}
	
	// add image layers
	for (TMXImageLayer* imageLayer in jsTileMap.tmxMap.imageLayers)
	{
		SKSpriteNode* image = [SKSpriteNode spriteNodeWithImageNamed:imageLayer.imageSource];
		image.position = CGPointMake(image.size.width / 2.0, image.size.height / 2.0);
		image.zPosition = baseZPosition + ((jsTileMap.tmxMap.zOrderCount - imageLayer.zOrderCount) * zOrderModifier);
		[jsTileMap addChild:image];
#ifdef DEBUG
		NSLog(@"IMAGE Layer %@ has zPosition %f", imageLayer.name, image.zPosition);
        
#endif
		
        //#warning the positioning is off here, seems to be bottom-left instead of top-left.  Might be off on the rest of the sprites too...?
	}
    
    return jsTileMap;
}








@end
