//
//  JSTileMap.m
//  TMXMapSample
//
//  Created by Jeremy, Maros Galik on 6/11/13.
//  Copyright (c) 2013 Jeremy. All rights reserved.
//


#import "TMXTileMap.h"


@interface TMXTileMap ()
{
	NSMutableString* currentString;
	BOOL storingCharacters;
	int currentFirstGID;
	int layerAttributes;
}


@end

@interface TMXLayerInfo ()

@end

@interface TMXObjectGroup ()

@end

@interface TMXImageLayer ()

@end

@interface TMXTilesetInfo ()
@property (nonatomic,strong) NSMutableDictionary* textureCache;
@end


#pragma mark -


@implementation TMXTileLayer


-(int)tileGidAt:(CGPoint)point
{
	// get index
	CGPoint pt = [self coordForPoint:point];
	int idx = pt.x + (pt.y * self.layerInfo.layerGridSize.width);
	
	// bounds check, invalid GID if out of bounds
	if(idx > (_layerInfo.layerGridSize.width * _layerInfo.layerGridSize.height) ||
	   idx < 0)
	{
		NSAssert(true, @"index out of bounds!");
		return 0;
	}
	
	// return the Gid
	return _layerInfo.tiles[ idx ];
}


//#warning need to write setTileGidAt:


- (NSDictionary*)properties
{
	return self.layerInfo.properties;
}


- (id) propertyWithName:(NSString*)name
{
	return self.layerInfo.properties[name];
}


#pragma mark -



-(void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_layerInfo forKey:@"TMXLayerLayerInfo"];
  [aCoder encodeObject:_tileInfo forKey:@"TMXLayerTileInfo"];
#if TARGET_OSX
    NSPoint p = {.x =  _mapTileSize.width, .y =  _mapTileSize.height};
    [aCoder encodePoint:p forKey:@"TMXLayerTileSize"];
#else
    [aCoder encodeCGSize:_mapTileSize forKey:@"TMXLayerTileSize"];
#endif
  [aCoder encodeObject:_map forKey:@"TMXLayerMap"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if(self = [super init])
  {
    _layerInfo = [aDecoder decodeObjectForKey:@"TMXLayerLayerInfo"];
    _tileInfo = [aDecoder decodeObjectForKey:@"TMXLayerTileInfo"];
#if TARGET_OSX
      NSPoint p = [aDecoder decodePointForKey:@"TMXLayerTileSize"];
      _mapTileSize = CGSizeMake(p.x, p.y);
#else
      _mapTileSize = [aDecoder decodeCGSizeForKey:@"TMXLayerTileSize"];
#endif
    _map = [aDecoder decodeObjectForKey:@"TMXLayerMap"];
  }
  return self;
}

@end


#pragma mark -


@implementation TMXLayerInfo

- (id)init
{
    self = [super init];
    if (self) {
        self.properties = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)dealloc
{
  free(_tiles);
}

-(int)tileGidAtCoord:(CGPoint)coord
{
	int idx = coord.x + coord.y * _layerGridSize.width;
	
	NSAssert(idx < (_layerGridSize.width * _layerGridSize.height), @"index out of bounds!");
	
	return _tiles[ idx ];
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_name forKey:@"TMXLayerInfoName"];
#if TARGET_OSX
    NSPoint p = {.x = _layerGridSize.width, .y = _layerGridSize.height};
    [aCoder encodePoint:p forKey:@"TMXLayerInfoGridSize"];
#else
    [aCoder encodeCGSize:_layerGridSize forKey:@"TMXLayerInfoGridSize"];
#endif
  [aCoder encodeObject:[NSData dataWithBytes:(void*)_tiles
                                      length:sizeof(int)*(_layerGridSize.width*_layerGridSize.height)]
                forKey:@"TMXLayerInfoTiles"];
  [aCoder encodeBool:_visible forKey:@"TMXLayerInfoVisible"];
  [aCoder encodeFloat:_opacity forKey:@"TMXLayerInfoOpacity"];
  [aCoder encodeInteger:_minGID forKey:@"TMXLayerInfoMinGid"];
  [aCoder encodeInteger:_maxGID forKey:@"TMXLayerInfoMaxGid"];

  [aCoder encodeObject:_properties forKey:@"TMXLayerInfoProperties"];
#if TARGET_OSX
    [aCoder encodePoint:_offset forKey:@"TMXLayerInfoOffset"];
#else
    [aCoder encodeCGPoint:_offset forKey:@"TMXLayerInfoOffset"];
#endif
  [aCoder encodeObject:_layer forKey:@"TMXLayerInfoLayer"];
  [aCoder encodeInteger:_zOrderCount forKey:@"TMXLayerInfoZOrderCount"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if(self = [super init])
  {
    _name = [aDecoder decodeObjectForKey:@"TMXLayerInfoName"];
#if TARGET_OSX
      NSPoint p = [aDecoder decodePointForKey:@"TMXLayerInfoGridSize"];
      _layerGridSize = CGSizeMake(p.x, p.y);
#else
      _layerGridSize = [aDecoder decodeCGSizeForKey:@"TMXLayerInfoGridSize"];
#endif

    NSData* data = [aDecoder decodeObjectForKey:@"TMXLayerInfoTiles"];
    int* temp = (int*)[data bytes];
    _tiles = malloc(sizeof(int)*(_layerGridSize.width*_layerGridSize.height));
    for(int i = 0; i < (_layerGridSize.width*_layerGridSize.height); ++i) {
      _tiles[i] = temp[i];
    }
  
    _visible = [aDecoder decodeBoolForKey:@"TMXLayerInfoVisible"];
    _opacity = [aDecoder decodeFloatForKey:@"TMXLayerInfoOpacity"];
    _minGID = [aDecoder decodeIntForKey:@"TMXLayerInfoMinGid"];
    _maxGID = [aDecoder decodeIntForKey:@"TMXLayerInfoMaxGid"];
    
    _properties = [aDecoder decodeObjectForKey:@"TMXLayerInfoProperties"];
#if TARGET_OSX
	_offset = [aDecoder decodePointForKey:@"TMXLayerInfoOffset"];
#else
    _offset = [aDecoder decodeCGPointForKey:@"TMXLayerInfoOffset"];
#endif
    _layer = [aDecoder decodeObjectForKey:@"TMXLayerInfoLayer"];
    _zOrderCount = [aDecoder decodeIntForKey:@"TMXLayerInfoZOrderCount"];
  }
  return self;
}

@end

@implementation TMXObjectGroup

- (id)init
{
    self = [super init];
    if (self) {
        self.objects = [NSMutableArray array];
        self.properties = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_groupName forKey:@"TMXObjectGroupName"];
#if TARGET_OSX
    [aCoder encodePoint:_positionOffset forKey:@"TMSObjectGroupPosOffset"];
#else
    [aCoder encodeCGPoint:_positionOffset forKey:@"TMSObjectGroupPosOffset"];
#endif
  [aCoder encodeObject:_objects forKey:@"TMXObjectGroupObjects"];
  [aCoder encodeObject:_properties forKey:@"TMXObjectGroupProperties"];
  [aCoder encodeInteger:_zOrderCount forKey:@"TMXObjectGroupZOrderCount"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if(self = [super init])
  {
    _groupName = [aDecoder decodeObjectForKey:@"TMXObjectGroupName"];
#if TARGET_OSX
    _positionOffset = [aDecoder decodePointForKey:@"TMSObjectGroupPosOffset"];
#else
	_positionOffset = [aDecoder decodeCGPointForKey:@"TMSObjectGroupPosOffset"];
#endif
    _objects = [aDecoder decodeObjectForKey:@"TMXObjectGroupObjects"];
    _properties = [aDecoder decodeObjectForKey:@"TMXObjectGroupProperties"];
    _zOrderCount = [aDecoder decodeIntForKey:@"TMXObjectGroupZOrderCount"];
  }
  return self;
}

- (NSDictionary *)objectNamed:(NSString *)objectName {
	__block NSDictionary *object = nil;
	[self.objects enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
		if ([[obj valueForKey:@"name"] isEqualToString:objectName]) {
			object = obj;
			*stop = YES;
		}
	}];
	
	return object;
}

- (NSArray *)objectsNamed:(NSString *)objectName {
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:self.objects.count];
	[self.objects enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
		if ([[obj valueForKey:@"name"] isEqualToString:objectName]) {
			[objects addObject:obj];
		}
	}];
	
	return objects;
}

- (id)propertyNamed:(NSString *)propertyName {
	return [self.properties valueForKey:propertyName];
}

@end


@implementation TMXImageLayer

- (id)init
{
    self = [super init];
    if (self) {
        self.properties = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_name forKey:@"TMXImageLayerName"];
	[aCoder encodeObject:_imageSource forKey:@"TMXImageLayerSource"];
	[aCoder encodeObject:_properties forKey:@"TMXImageLayerProperties"];
	[aCoder encodeInteger:_zOrderCount forKey:@"TMXImageLayerZOrderCount"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if(self = [super init])
	{
		_name = [aDecoder decodeObjectForKey:@"TMXImageLayerName"];
		_imageSource = [aDecoder decodeObjectForKey:@"TMXImageLayerSource"];
		_properties = [aDecoder decodeObjectForKey:@"TMXImageLayerProperties"];
		_zOrderCount = [aDecoder decodeIntForKey:@"TMXImageLayerZOrderCount"];
	}
	return self;
}

@end


@implementation TMXTilesetInfo

-(instancetype)initWithGid:(int)gID attributes:(NSDictionary*)attributes
{
	if((self = [super init]))
	{
		_name = [attributes[@"name"] copy];
		_firstGid = gID;
		_spacing = [attributes[@"spacing"] intValue];
		_margin = [attributes[@"margin"] intValue];
		_tileSize = CGSizeMake([attributes[@"tilewidth"] intValue],
							   [attributes[@"tileheight"] intValue]);
		
		_textureCache = [NSMutableDictionary dictionary];
		
	}
	return self;
}

-(void)setSourceImage:(NSString *)sourceImage
{
	_sourceImage = [sourceImage copy];
#if TARGET_OSX
	NSImageRep* atlas = [NSImageRep imageRepWithContentsOfFile:_sourceImage];
#else
	UIImage* atlas = [UIImage imageWithContentsOfFile:_sourceImage];
#endif
	_imageSize = atlas.size;
//	_atlasTexture = [SKTexture textureWithImage:atlas];           // CML: There seems to be a bug where creating with Image instead of ImageNamed breaks the
	_atlasTexture = [SKTexture textureWithImageNamed:_sourceImage]; //      archiving.
	
	NSLog(@"texture image: %@\rSize (%f, %f)", _sourceImage, _atlasTexture.size.width, _atlasTexture.size.height);
	
	_unitTileSize = CGSizeMake(_tileSize.width / _imageSize.width,
							   _tileSize.height / _imageSize.height);
	
	_atlasTilesPerRow = (_imageSize.width - _margin * 2 + _spacing) / (_tileSize.width + _spacing);
	_atlasTilesPerCol = (_imageSize.height - _margin * 2 + _spacing) / (_tileSize.height + _spacing);
}

-(int)rowFromGid:(int)gid
{
	return gid / self.atlasTilesPerRow;
}

-(int)colFromGid:(int)gid
{
	return gid % self.atlasTilesPerRow;
}

-(SKTexture*)textureForGid:(int)gid
{
  gid = gid & kFlippedMask;
  gid -= self.firstGid;
  
  SKTexture* texture = self.textureCache[@(gid)];
	if(!texture)
	{
		CGFloat rowOffset = ( (((self.tileSize.height + self.spacing) * [self rowFromGid:gid]) + self.margin) / self.imageSize.height);
		CGFloat colOffset = ( (((self.tileSize.width + self.spacing) * [self colFromGid:gid]) + self.margin) / self.imageSize.width);
		// reverse y axis
		rowOffset = 1.0 - rowOffset - self.unitTileSize.height;
		
		// note that the width and height of the tiles are always the same in TMX maps or the atlas (GIDs) couldn't be calculated consistently.
		CGRect rect = CGRectMake(colOffset, rowOffset,
								 self.unitTileSize.width, self.unitTileSize.height);
		
		texture = [SKTexture textureWithRect:rect inTexture:self.atlasTexture];
		texture.usesMipmaps = YES;
		texture.filteringMode = SKTextureFilteringNearest;
		self.textureCache[@(gid)] = texture;
		
		// tile data
#ifdef DEBUG
//		NSLog(@"The regular atlas is %f x %f.  Tile size is %f x % f plus %d spaces between each tile.", self.atlasTexture.size.width, self.atlasTexture.size.height, self.tileSize.width, self.tileSize.height, self.spacing);
//		NSLog(@"Tile margins for this atlas are %d.  This means the atlas image is inset by this amount, from both the top left and bottom right.", self.margin);
//		NSLog(@"gid %d is row %d, col %d of the atlas.  (map base gid is %d)", gid, [self rowFromGid:gid] + 1, [self colFromGid:gid] + 1, self.firstGid);
//		NSLog(@"This means that the tile x offset is %f%% into the atlas and %f%% from the top-left of the atlas.", colOffset, rowOffset);
//		NSLog(@"The adjusted tile size in percentages is %f wide and %f tall.", self.unitTileSize.width, self.unitTileSize.height);
#endif
	}
	return texture;
}

-(SKTexture*)textureAtPoint:(CGPoint)p
{
  SKTexture *atlas = self.atlasTexture;
  return [SKTexture textureWithRect:
          CGRectMake(p.x / atlas.size.width, 1.0-((p.y + self.tileSize.height) / atlas.size.height),
                     self.unitTileSize.width, self.unitTileSize.height)
                          inTexture:atlas];
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:_name forKey:@"TMXTilesetName"];
  [aCoder encodeInteger:_firstGid forKey:@"TMXTilesetFirstGid"];
#if TARGET_OSX
    NSPoint p = {.x = _tileSize.width, .y = _tileSize.height};
    [aCoder encodePoint:p forKey:@"TMXTilesetTileSize"];
    p.x = _unitTileSize.width; p.y = _unitTileSize.height;
    [aCoder encodePoint:p forKey:@"TMXTilesetUnitTileSize"];
    p.x = _imageSize.width; p.y = _imageSize.height;
    [aCoder encodePoint:p forKey:@"TMXTilesetImageSize"];
#else
    [aCoder encodeCGSize:_tileSize forKey:@"TMXTilesetTileSize"];
    [aCoder encodeCGSize:_unitTileSize forKey:@"TMXTilesetUnitTileSize"];
    [aCoder encodeCGSize:_imageSize forKey:@"TMXTilesetImageSize"];
#endif
  [aCoder encodeInteger:_spacing forKey:@"TMXTilesetSpacing"];
  [aCoder encodeInteger:_margin forKey:@"TMXTilesetMargin"];
  [aCoder encodeObject:_sourceImage forKey:@"TMXTilesetSourceImage"];
  [aCoder encodeInteger:_atlasTilesPerRow forKey:@"TMXTilesetTilesPerRow"];
  [aCoder encodeInteger:_atlasTilesPerCol forKey:@"TMXTilesetTilesPerCol"];
  [aCoder encodeObject:_atlasTexture forKey:@"TMXTilesetAtlasTexture"];
  [aCoder encodeObject:_textureCache forKey:@"TMXTilesetTextureCache"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if(self = [super init])
  {
    _name = [aDecoder decodeObjectForKey:@"TMXTilesetName"];
    _firstGid = [aDecoder decodeIntForKey:@"TMXTilesetFirstGid"];
#if TARGET_OSX
      NSPoint p = [aDecoder decodePointForKey:@"TMXTilesetTileSize"];
      _tileSize = CGSizeMake(p.x, p.y);
      p = [aDecoder decodePointForKey:@"TMXTilesetUnitTileSize"];
      _unitTileSize = CGSizeMake(p.x, p.y);
      p = [aDecoder decodePointForKey:@"TMXTilesetImageSize"];
      _imageSize = CGSizeMake(p.x, p.y);
#else
      _tileSize = [aDecoder decodeCGSizeForKey:@"TMXTilesetTileSize"];
      _unitTileSize = [aDecoder decodeCGSizeForKey:@"TMXTilesetUnitTileSize"];
      _imageSize = [aDecoder decodeCGSizeForKey:@"TMXTilesetImageSize"];
#endif
    _spacing = [aDecoder decodeIntForKey:@"TMXTilesetSpacing"];
    _margin = [aDecoder decodeIntForKey:@"TMXTilesetMargin"];
    _sourceImage = [aDecoder decodeObjectForKey:@"TMXTilesetSourceImage"];
    _atlasTilesPerRow = [aDecoder decodeIntForKey:@"TMXTilesetTilesPerRow"];
    _atlasTilesPerCol = [aDecoder decodeIntForKey:@"TMXTilesetTilesPerCol"];
    _atlasTexture = [aDecoder decodeObjectForKey:@"TMXTilesetAtlasTexture"];
    _textureCache = [aDecoder decodeObjectForKey:@"TMXTilesetTextureCache"];
  }
  return self;
}

@end


@implementation TMXTileMap


+ (TMXTileMap*)mapNamed:(NSString*)mapName
{
	// zOrder offset.  Make this bigger if you want more space between layers.
	// higher numbers act further away.
	return [TMXTileMap mapNamed:mapName withBaseZPosition:0.0f andZOrderModifier:-20.0f];
}


+ (TMXTileMap*)mapNamed:(NSString*)mapName
      withBaseZPosition:(CGFloat)baseZPosition
      andZOrderModifier:(CGFloat)zOrderModifier
{
	// create the map
	TMXTileMap* map = [[TMXTileMap alloc] init];
	
	// get the TMX map filename
	NSString* name = mapName;
	NSString* extension = nil;
	
	// split the extension off if there is one passed
	if ([mapName rangeOfString:@"."].location != NSNotFound)
	{
		name = [mapName stringByDeletingPathExtension];
		extension = [mapName pathExtension];
	}
	
	// load the TMX map from disk
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:extension];
	NSData* mapData = [NSData dataWithContentsOfFile:path];
	
	// set the filename
	map.filename = path;
	
	// parse the map
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData:mapData];
	parser.delegate = map;
	parser.shouldProcessNamespaces = NO;
	parser.shouldReportNamespacePrefixes = NO;
	parser.shouldResolveExternalEntities = NO;
	BOOL parsed = [parser parse];
	if (!parsed)
	{
		NSLog(@"Error parsing map! \n%@", [parser parserError]);
		return nil;
	}
	
	// set zPosition range
	if (baseZPosition < (baseZPosition + (zOrderModifier * (map.zOrderCount + 1))))
	{
		map->_minZPositioning = baseZPosition;
		map->_maxZPositioning = baseZPosition + (zOrderModifier * (map.zOrderCount + 1));
	}
	else
	{
		map->_maxZPositioning = baseZPosition;
		map->_minZPositioning = baseZPosition + (zOrderModifier * (map.zOrderCount + 1));
	}

	
	return map;
}

-(TMXTilesetInfo*)tilesetInfoForGid:(int)gID
{
	if (!gID)
		return nil;
	
	for (TMXTilesetInfo* tileset in self.tilesets)
	{
		// check to see if the gID is in the info's atlas gID range.  If not, skip this one and go to the next.
		int lastPossibleGid = tileset.firstGid + (tileset.atlasTilesPerRow * tileset.atlasTilesPerCol) - 1;
		if (gID < tileset.firstGid || gID > lastPossibleGid)
			continue;
    
		return tileset;
	}
	
	return nil;		// should never get here?
}


-(NSDictionary*)propertiesForGid:(int)gID
{
	return self.tileProperties[@(gID)];
}


-(TMXLayer*)layerNamed:(NSString*)name
{
	for(TMXLayerInfo* layerInfo in self.layers)
	{
		if ([name isEqualToString:layerInfo.name])
			return layerInfo.layer;
	}
	return nil;
}

-(TMXObjectGroup*)groupNamed:(NSString*)name
{
	for(TMXObjectGroup* group in self.objectGroups)
	{
		if ([name isEqualToString:group.groupName])
			return group;
	}
	return nil;
}

- (id)init
{
    self = [super init];
    if (self)
	{
		currentFirstGID = 0;
		currentString = [NSMutableString string];
		storingCharacters = NO;
		layerAttributes = TMXLayerAttributeNone;

		self.zOrderCount = 1;
		self.parentElement = TMXPropertyNone;
		self.tilesets = [NSMutableArray array];
		self.tileProperties = [NSMutableDictionary dictionary];
		self.properties = [NSMutableDictionary dictionary];
		self.layers = [NSMutableArray array];
		self.imageLayers = [NSMutableArray array];
		self.objectGroups = [NSMutableArray array];
		self.resources = nil;	// possible future resources path
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
//  [super encodeWithCoder:aCoder];
  
#if TARGET_OSX
    NSPoint p = {.x = _mapSize.width, .y = _mapSize.height};
    [aCoder encodePoint:p forKey:@"JSTileMapMapSize"];
    p.x = _tileSize.width; p.y = _tileSize.height;
    [aCoder encodePoint:p forKey:@"JSTileMapTileSize"];
#else
    [aCoder encodeCGSize:_mapSize forKey:@"JSTileMapMapSize"];
    [aCoder encodeCGSize:_tileSize forKey:@"JSTileMapTileSize"];
#endif
  [aCoder encodeInt:_parentElement forKey:@"JSTileMapParentElement"];
  [aCoder encodeInteger:_parentGID forKey:@"JSTileMapParentGid"];
  [aCoder encodeInt:_orientation forKey:@"JSTileMapOrientation"];
  [aCoder encodeObject:_filename forKey:@"JSTileMapFilename"];
  [aCoder encodeObject:_resources forKey:@"JSTileMapResources"];
  [aCoder encodeObject:_tilesets forKey:@"JSTileMapTilesets"];
  [aCoder encodeObject:_tileProperties forKey:@"JSTileMapTileProperties"];
  [aCoder encodeObject:_properties forKey:@"JSTileMapProperties"];
  [aCoder encodeObject:_layers forKey:@"JSTileMapLayers"];
  [aCoder encodeObject:_imageLayers forKey:@"JSTileMapImageLayers"];
  [aCoder encodeObject:_objectGroups forKey:@"JSTileMapObjectGroups"];
  [aCoder encodeObject:_gidData forKey:@"JSTileMapGidData"];
  [aCoder encodeInteger:_zOrderCount forKey:@"JSTileMapZOrderCount"];

  // parsing variables -- not sure they need to be coded, but just in case
  [aCoder encodeObject:currentString forKey:@"JSTileMapCurrentString"];
  [aCoder encodeBool:storingCharacters forKey:@"JSTileMapStoringChars"];
  [aCoder encodeInteger:currentFirstGID forKey:@"JSTileMapCurrentFirstGid"];
  [aCoder encodeInteger:layerAttributes forKey:@"JSTileMapLayerAttributes"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if(self = [super init])
  {
#if TARGET_OSX
      NSPoint p = [aDecoder decodePointForKey:@"JSTileMapMapSize"];
      _mapSize = CGSizeMake(p.x, p.y);
      p = [aDecoder decodePointForKey:@"JSTileMapTileSize"];
      _tileSize = CGSizeMake(p.x, p.y);
#else
      _mapSize = [aDecoder decodeCGSizeForKey:@"JSTileMapMapSize"];
      _tileSize = [aDecoder decodeCGSizeForKey:@"JSTileMapTileSize"];
#endif
    _parentElement = [aDecoder decodeIntForKey:@"JSTileMapParentElement"];
    _parentGID = [aDecoder decodeIntForKey:@"JSTileMapParentGid"];
    _orientation = [aDecoder decodeIntForKey:@"JSTileMapOrientation"];
    _filename = [aDecoder decodeObjectForKey:@"JSTileMapFilename"];
    _resources = [aDecoder decodeObjectForKey:@"JSTileMapResources"];
    _tilesets = [aDecoder decodeObjectForKey:@"JSTileMapTilesets"];
    _tileProperties = [aDecoder decodeObjectForKey:@"JSTileMapTileProperties"];
    _properties = [aDecoder decodeObjectForKey:@"JSTileMapProperties"];
    _layers = [aDecoder decodeObjectForKey:@"JSTileMapLayers"];
    _objectGroups = [aDecoder decodeObjectForKey:@"JSTileMapObjectGroups"];
    _gidData = [aDecoder decodeObjectForKey:@"JSTileMapGidData"];
    _imageLayers = [aDecoder decodeObjectForKey:@"JSTileMapImageLayers"];
    _zOrderCount = [aDecoder decodeIntForKey:@"JSTileMapZOrderCount"];
    
    // parsing variables -- not sure they need to be coded, but just in case
    currentString = [aDecoder decodeObjectForKey:@"JSTileMapCurrentString"];
    storingCharacters = [aDecoder decodeBoolForKey:@"JSTileMapStoringChars"];
    currentFirstGID = [aDecoder decodeIntForKey:@"JSTileMapCurrentFirstGid"];
    layerAttributes = [aDecoder decodeIntForKey:@"JSTileMapLayerAttributes"];
  }
  return self;
}

#pragma mark - parsing


// the XML parser calls here with all the elements
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if([elementName isEqualToString:@"map"])
	{
		NSString* orientationStr = attributeDict[@"orientation"];
		if ([[orientationStr lowercaseString] isEqualToString:@"orthogonal"])
		{
			self.orientation = OrientationStyle_Orthogonal;
		}
		else if ( [[orientationStr lowercaseString] isEqualToString:@"isometric"])
		{
			self.orientation = OrientationStyle_Isometric;
		}
		else
		{
			NSLog(@"Unsupported orientation: %@", attributeDict[@"orientation"]);
			[parser abortParsing];
		}
		
		self.mapSize = CGSizeMake([attributeDict[@"width"] intValue], [attributeDict[@"height"] intValue]);
		self.tileSize = CGSizeMake([attributeDict[@"tilewidth"] intValue], [attributeDict[@"tileheight"] intValue]);
		
		// The parent element is now "map"
		self.parentElement = TMXPropertyMap;
	}
	else if([elementName isEqualToString:@"tileset"])
	{
		// If this has an external tileset we're done
		NSString *externalTilesetFilename = attributeDict[@"source"];
		if (externalTilesetFilename)
		{
			NSLog(@"External tilesets unsupported!");
			[parser abortParsing];
			return;
		}
		
		int gID;
		if(currentFirstGID == 0) {
			gID = [attributeDict[@"firstgid"] intValue];
		} else {
			gID = currentFirstGID;
			currentFirstGID = 0;
		}
		
		TMXTilesetInfo *tileset = [[TMXTilesetInfo alloc] initWithGid:gID
														   attributes:attributeDict];
		[self.tilesets addObject:tileset];
	}
	else if([elementName isEqualToString:@"tile"])
	{
		if (!storingCharacters)
		{
			TMXTilesetInfo* info = [self.tilesets lastObject];
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:3];
			self.parentGID =  info.firstGid + [attributeDict[@"id"] intValue];
			(self.tileProperties)[@(self.parentGID)] = dict;
			
			self.parentElement = TMXPropertyTile;
		}
		else
		{
			if (!self.gidData)
				self.gidData = [NSMutableArray array];
			
			// remember XML gids for the data tag in the order they come in.
			[self.gidData addObject:attributeDict[@"gid"]];
		}
		
	}
	else if([elementName isEqualToString:@"layer"])
	{
		TMXLayerInfo* layer = [[TMXLayerInfo alloc] init];
		layer.name = attributeDict[@"name"];
		layer.layerGridSize = CGSizeMake([attributeDict[@"width"] intValue], [attributeDict[@"height"] intValue]);
		layer.visible = ![attributeDict[@"visible"] isEqualToString:@"0"];
		layer.offset = CGPointMake([attributeDict[@"x"] intValue], [attributeDict[@"y"] intValue]);
		layer.opacity = 1.0;
		if( attributeDict[@"opacity"] )
			layer.opacity = [attributeDict[@"opacity"] floatValue];
		
		layer.zOrderCount = self.zOrderCount;
		self.zOrderCount++;

		[self.layers addObject:layer];
		
		self.parentElement = TMXPropertyLayer;
		
	}
	else if([elementName isEqualToString:@"imagelayer"])
	{
		TMXImageLayer* imageLayer = [[TMXImageLayer alloc] init];
		imageLayer.name = attributeDict[@"name"];
		imageLayer.zOrderCount = self.zOrderCount;
		self.zOrderCount++;
		
		[self.imageLayers addObject:imageLayer];
		
		self.parentElement = TMXPropertyImageLayer;
	}
	else if([elementName isEqualToString:@"objectgroup"])
	{
		TMXObjectGroup *objectGroup = [[TMXObjectGroup alloc] init];
		objectGroup.groupName = attributeDict[@"name"];
		
		CGPoint positionOffset;
		positionOffset.x = [attributeDict[@"x"] intValue] * self.tileSize.width;
		positionOffset.y = [attributeDict[@"y"] intValue] * self.tileSize.height;
		objectGroup.positionOffset = positionOffset;
		
		objectGroup.zOrderCount = self.zOrderCount;
		self.zOrderCount++;

		[self.objectGroups addObject:objectGroup];
		
		// The parent element is now "objectgroup"
		self.parentElement = TMXPropertyObjectGroup;
		
	}
	else if([elementName isEqualToString:@"image"])
	{
		if (self.parentElement == TMXPropertyImageLayer)
		{
			TMXImageLayer* imageLayer = [self.imageLayers lastObject];
			imageLayer.imageSource = attributeDict[@"source"];
			//		imageLayer.transparencyColor = attributeDict[@"trans"];
		}
		else
		{
			TMXTilesetInfo *tileset = [self.tilesets lastObject];
			
			// build full path
			NSString* imageName = attributeDict[@"source"];
			NSString* path = [self.filename stringByDeletingLastPathComponent];
			if (!path)
				path = self.resources;
			[tileset setSourceImage:[path stringByAppendingPathComponent:imageName]];
		}
	}
	else if([elementName isEqualToString:@"data"])
	{
		NSString *encoding = attributeDict[@"encoding"];
		NSString *compression = attributeDict[@"compression"];
		
		storingCharacters = YES;
		
		if( [encoding isEqualToString:@"base64"] )
		{
			layerAttributes |= TMXLayerAttributeBase64;
			
			if([compression isEqualToString:@"gzip"])
				layerAttributes |= TMXLayerAttributeGzip;
			else if([compression isEqualToString:@"zlib"])
				layerAttributes |= TMXLayerAttributeZlib;
		}
	}
	else if([elementName isEqualToString:@"object"])
	{
		TMXObjectGroup *objectGroup = [self.objectGroups lastObject];
		
		// The value for "type" was blank or not a valid class name
		// Create an instance of TMXObjectInfo to store the object and its properties
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
		
		// Parse everything automatically
		NSArray *array = @[@"name", @"type", @"width", @"height", @"gid"];
		for( id key in array ) {
			NSObject *obj = attributeDict[key];
			if( obj )
				dict[key] = obj;
		}
		
		// But X and Y since they need special treatment
		// X
		NSString *value = attributeDict[@"x"];
		if( value )
		{
			int x = [value intValue] + objectGroup.positionOffset.x;
			dict[@"x"] = @(x);
		}
		
		// Y
		value = attributeDict[@"y"];
		if( value )
		{
			int y = [value intValue] + objectGroup.positionOffset.y;
			// Correct y position. (Tiled's origin is top-left. SpriteKit's origin is bottom-left)
			y = (_mapSize.height * _tileSize.height) - y - [attributeDict[@"height"] intValue];
			dict[@"y"] = @(y);
		}
		
		// Add the object to the objectGroup
		[[objectGroup objects] addObject:dict];
		
		// The parent element is now "object"
		self.parentElement = TMXPropertyObject;
		
	}
	else if([elementName isEqualToString:@"property"])
	{
		if ( self.parentElement == TMXPropertyNone )
		{
			NSLog( @"TMX tile map: Parent element is unsupported. Cannot add property named '%@' with value '%@'", attributeDict[@"name"], attributeDict[@"value"]);
		}
		else if ( self.parentElement == TMXPropertyMap )
		{
			// The parent element is the map
			(self.properties)[attributeDict[@"name"]] = attributeDict[@"value"];
		}
		else if ( self.parentElement == TMXPropertyLayer )
		{
			// The parent element is the last layer
			TMXLayerInfo *layer = [self.layers lastObject];
			// Add the property to the layer
			[layer properties][attributeDict[@"name"]] = attributeDict[@"value"];
		}
		else if ( self.parentElement == TMXPropertyImageLayer)
		{
			TMXImageLayer* imageLayer = [self.imageLayers lastObject];
			[imageLayer properties][attributeDict[@"name"]] = attributeDict[@"value"];
		}
		else if ( self.parentElement == TMXPropertyObjectGroup )
		{
			// The parent element is the last object group
			TMXObjectGroup *objectGroup = [self.objectGroups lastObject];
			[objectGroup properties][attributeDict[@"name"]] = attributeDict[@"value"];
		}
		else if ( self.parentElement == TMXPropertyObject )
		{
			// The parent element is the last object
			TMXObjectGroup *objectGroup = [self.objectGroups lastObject];
			NSMutableDictionary *dict = [[objectGroup objects] lastObject];
			
			NSString *propertyName = attributeDict[@"name"];
			NSString *propertyValue = attributeDict[@"value"];
			
			dict[propertyName] = propertyValue;
		}
		else if ( self.parentElement == TMXPropertyTile )
		{
			NSMutableDictionary* dict = (self.tileProperties)[@(self.parentGID)];
			NSString *propertyName = attributeDict[@"name"];
			NSString *propertyValue = attributeDict[@"value"];
			dict[propertyName] = propertyValue;
		}
	}
	else if ([elementName isEqualToString:@"polygon"])
	{
		// find parent object's dict and add polygon-points to it
		TMXObjectGroup *objectGroup = [self.objectGroups lastObject];
		NSMutableDictionary *dict = [[objectGroup objects] lastObject];
		dict[@"polygonPoints"] = attributeDict[@"points"];
	}
	else if ([elementName isEqualToString:@"polyline"])
	{
		// find parent object's dict and add polyline-points to it
		TMXObjectGroup *objectGroup = [self.objectGroups lastObject];
		NSMutableDictionary *dict = [[objectGroup objects] lastObject];
		dict[@"polylinePoints"] = attributeDict[@"points"];
	}
	else if ([elementName isEqualToString:@"ellipse"])
	{
        // find parent object's dict and add ellipse to it
        TMXObjectGroup *objectGroup = [self.objectGroups lastObject];
		NSMutableDictionary *dict = [[objectGroup objects] lastObject];
		[dict setObject:[NSNumber numberWithBool:YES] forKey:@"ellipse"];
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	unsigned int len = 0;
	
	if([elementName isEqualToString:@"data"])
	{
		storingCharacters = NO;
		TMXLayerInfo *layer = [self.layers lastObject];
		
		if (layerAttributes & TMXLayerAttributeBase64)
		{
			// clean whitespace from string
			currentString = [NSMutableString stringWithString:[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
						
			NSData* buffer = [[NSData alloc] initWithBase64EncodedString:currentString options:0];
			if( ! buffer.length ) {
				NSLog(@"TiledMap: decode data error");
				[parser abortParsing];
				return;
			}
			
			len = (unsigned int)buffer.length;
			
			if( layerAttributes & (TMXLayerAttributeGzip | TMXLayerAttributeZlib) )
			{
				unsigned char *deflated;
				CGSize s = [layer layerGridSize];
				int sizeHint = s.width * s.height * sizeof(uint32_t);
				
				int inflatedLen = InflateMemoryWithHint((unsigned char*)[buffer bytes], len, &deflated, sizeHint);
				NSAssert( inflatedLen == sizeHint, @"CCTMXXMLParser: Hint failed!");
												
				if( ! deflated )
				{
					NSLog(@"TiledMap: inflate data error");
					[parser abortParsing];
					return;
				}
				
				layer.tiles = (int*) deflated;
			}
			else
			{
				char* tileArray = malloc(buffer.length);
				memmove(tileArray, buffer.bytes, buffer.length);
				layer.tiles = (int*) tileArray;
			}
		}
		else
		{
			// convert to binary gid data
			if (self.gidData.count)
			{
				layer.tiles = malloc(self.gidData.count * sizeof(unsigned int));
				int x = 0;
				for (NSString* gid in self.gidData)
				{
					layer.tiles[x] = [gid intValue];
					x++;
				}
			}
		}
		
		[self.gidData removeAllObjects];
		currentString = [NSMutableString string];
		
	}
	else if ([elementName isEqualToString:@"map"])
	{
		// The map element has ended
		self.parentElement = TMXPropertyNone;
	}
	else if ([elementName isEqualToString:@"layer"])
	{
		// The layer element has ended
		self.parentElement = TMXPropertyNone;
	}
	else if ([elementName isEqualToString:@"objectgroup"])
	{
		// The objectgroup element has ended
		self.parentElement = TMXPropertyNone;
	}
	else if ([elementName isEqualToString:@"object"])
	{
		// The object element has ended
		self.parentElement = TMXPropertyNone;
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (storingCharacters)
		[currentString appendString:string];
}


-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"Error on XML Parse: %@", [parseError localizedDescription]);
}


@end