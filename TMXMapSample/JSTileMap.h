//
//  JSTileMap.h
//  TMXMapSample
//
//  Created by Maros Galik on 5/2/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "TMXTileMap.h"

@interface TMXLayer : SKNode

@property (nonatomic, strong) TMXTileLayer *tmxTileLayer;

-(void)removeTileAtCoord:(CGPoint)coord;

+(id) layerWithTilesetInfo:(NSArray*)tilesets
                 layerInfo:(TMXLayerInfo*)layerInfo
                   mapInfo:(TMXTileMap*)mapInfo;

@end

@interface JSTileMap : SKNode

@property (nonatomic, strong) TMXTileMap *tmxMap;

+ (JSTileMap*)mapNamed:(NSString*)mapName;

@end
