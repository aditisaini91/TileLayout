//
//  UITileLayout.m
//  tilesstarter
//
//  Created by H231412 on 12.10.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import "UITileLayout.h"

#define FULL_TILE_SIZE  CGRectGetWidth(self.collectionView.bounds) / [self.delegate numberOfFullTilesInLayout]
#define COLUMN_COUNT_IN_ONE_FULLTILE    12

@interface UITileLayout()

// this will be a 2x2 dictionary storing nsindexpaths
// which indicate the available/filled blocks
// indexPathByPosition[col][row] = indexPath;
@property(nonatomic) NSMutableDictionary* indexPathByPosition;

// indexed by "section, row" this will serve as the rapid
// lookup of block position by indexpath.
// positionByIndexPath[indexPath.section][indexPath.row] = point;
@property(nonatomic) NSMutableDictionary* positionByIndexPath;

//starts the search from this point
@property(nonatomic) CGPoint firstOpenSpace;

// Y value : the furthest tile + height of tile
// X value : the furthest tile + width of tile
@property(nonatomic) CGPoint furthestTilePoint;

@end

@implementation UITileLayout{
    NSMutableArray *_layoutAttributes;
    CGFloat _smallestBlockSize;
    BOOL _isLayoutHorizontal;
    CGFloat _xOffset;
}

- (id)init {
    if((self = [super init]))
        [self initialize];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if((self = [super initWithCoder:aDecoder]))
        [self initialize];
    
    return self;
}

- (void) initialize {
    self.positionByIndexPath = [NSMutableDictionary dictionary];
    _isLayoutHorizontal = NO;
}

#pragma mark - collection view layout
-(void)prepareLayout{
    _smallestBlockSize = floor(FULL_TILE_SIZE / COLUMN_COUNT_IN_ONE_FULLTILE);
    _xOffset = _isLayoutHorizontal ? (CGRectGetWidth(self.collectionView.bounds) - _smallestBlockSize * COLUMN_COUNT_IN_ONE_FULLTILE * [self.delegate numberOfFullTilesInLayout]) / 2 : 0.0f;

    NSLog(@"Smallest block size : %f",_smallestBlockSize);
    
    NSInteger numSections = [self.collectionView numberOfSections];
    for (NSInteger section=0; section<numSections; section++) {
        NSInteger numRows = [self.collectionView numberOfItemsInSection:section];
        
        self.firstOpenSpace = CGPointMake(_isLayoutHorizontal ? 0 : self.furthestTilePoint.x, _isLayoutHorizontal ? self.furthestTilePoint.y : 0);
        
        for (NSInteger row =0; row<numRows; row++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [self _computeAttributesForIndexPath:indexPath];
        }
    }
}

-(CGSize)collectionViewContentSize {
    return CGSizeMake(_isLayoutHorizontal ? CGRectGetWidth(self.collectionView.bounds): self.furthestTilePoint.x * _smallestBlockSize, self.furthestTilePoint.y * _smallestBlockSize);
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [_layoutAttributes objectAtIndex:indexPath.row];
}

-(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
    return [_layoutAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, layoutAttributes.frame);
    }]];
}

-(void)invalidateLayout{
    [super invalidateLayout];
    
    _layoutAttributes = [[NSMutableArray alloc] init];
    self.firstOpenSpace = CGPointZero;
    self.furthestTilePoint = CGPointZero;
    self.indexPathByPosition = [NSMutableDictionary dictionary];
    self.positionByIndexPath = [NSMutableDictionary dictionary];
}

#pragma mark - helper methods to compute attributes of tiles/cells

//compute and add layout attributes for the given indexpath to the layoutAttributes array
-(void)_computeAttributesForIndexPath:(NSIndexPath*)indexPath{
    UICollectionViewLayoutAttributes *layoutAttribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGSize sizeAtIndexpath = CGSizeZero;
    if([self.delegate respondsToSelector:@selector(collectionView:layout:relativeTileSizeForItemAtIndexPath:)])
        sizeAtIndexpath = [self.delegate collectionView:[self collectionView] layout:self relativeTileSizeForItemAtIndexPath:indexPath];
    
    sizeAtIndexpath = CGSizeMake([self _getRelativeSizeFor:sizeAtIndexpath.width], [self _getRelativeSizeFor:sizeAtIndexpath.height]);
    
    layoutAttribute.frame = [self _frameForIndexPath:indexPath WithRelativeSize:sizeAtIndexpath];
    NSLog(@"attributes : %@ for : %ld", layoutAttribute, (long)indexPath.row);
    
    [_layoutAttributes addObject:layoutAttribute];
}

- (CGRect) _frameForIndexPath:(NSIndexPath*)path WithRelativeSize:(CGSize)tileRelativeSize{
    // if item does not have a position, we will make one! (positionForIndexPath)
    if(!self.positionByIndexPath[@(path.section)][@(path.row)])
        [self _traverseOpenTilesForTileWithSize:tileRelativeSize andIndexPath:path];
    
    CGPoint blockPosition = [self.positionByIndexPath[@(path.section)][@(path.row)] CGPointValue];
    
    if (blockPosition.y +  COLUMN_COUNT_IN_ONE_FULLTILE / tileRelativeSize.height > self.furthestTilePoint.y)
        self.furthestTilePoint = CGPointMake(self.furthestTilePoint.x, blockPosition.y +  COLUMN_COUNT_IN_ONE_FULLTILE / tileRelativeSize.height);
    
    if (blockPosition.x +  COLUMN_COUNT_IN_ONE_FULLTILE / tileRelativeSize.width > self.furthestTilePoint.x)
        self.furthestTilePoint = CGPointMake(blockPosition.x +  COLUMN_COUNT_IN_ONE_FULLTILE / tileRelativeSize.width, self.furthestTilePoint.y);
    
    CGPoint blockOrigin = CGPointMake(floor(blockPosition.x * _smallestBlockSize + _xOffset), floor(blockPosition.y * _smallestBlockSize));
    CGSize tileSize = CGSizeMake(floor(_smallestBlockSize * COLUMN_COUNT_IN_ONE_FULLTILE / tileRelativeSize.width), floor(_smallestBlockSize * COLUMN_COUNT_IN_ONE_FULLTILE / tileRelativeSize.height));
    
    return CGRectMake(blockOrigin.x, blockOrigin.y, tileSize.width, tileSize.height);
}


//trying to find an open space/point in the view to place new tile at
- (BOOL) _traverseOpenTilesForTileWithSize:(CGSize)relativeSize andIndexPath:(NSIndexPath*)indexPath{
    BOOL allTakenBefore = YES;
    
    CGFloat maxNoOfColsAtXaxis = COLUMN_COUNT_IN_ONE_FULLTILE * [self.delegate numberOfFullTilesInLayout];
    
    //block by block search for open block
    for(int unrestrictedDimension = (_isLayoutHorizontal ? self.firstOpenSpace.y : self.firstOpenSpace.x);; unrestrictedDimension++) {
        for (int restrictedDimension = (_isLayoutHorizontal ? 0 : self.firstOpenSpace.y);; restrictedDimension++){
            
            //restricted condition only for horizontal layout
            //The block could not be accomodated at this position (there are not enough blocks left)
            if (_isLayoutHorizontal && (restrictedDimension + COLUMN_COUNT_IN_ONE_FULLTILE / relativeSize.width > maxNoOfColsAtXaxis))
                break;
            
            CGPoint blockPosition = CGPointMake(_isLayoutHorizontal ? restrictedDimension : unrestrictedDimension, _isLayoutHorizontal ? unrestrictedDimension: restrictedDimension);
            
            if([self _indexPathForPosition:blockPosition])
                continue;
            
            //found the open point
            if(allTakenBefore) {
                self.firstOpenSpace = blockPosition;
                allTakenBefore = NO;
            }
            
            //check availability for the block at the open point
            if(![self _checkSpaceAvailabilityAndOccupyBlock:blockPosition WithRelativeSize:relativeSize andIndexPath:indexPath])
                return NO;
        }
    }
    
    NSAssert(0, @"Could find no good place for a block!");
    return YES;
}

//when a open block is found, see if the all the needed blocks are free and then set their position : mark them occupied
-(BOOL)_checkSpaceAvailabilityAndOccupyBlock:(CGPoint)blockPosition WithRelativeSize:(CGSize)size andIndexPath:(NSIndexPath*)indexPath{
    
    // we need to make sure all blocks in the desired
    // area are available before we can place the block
    
    BOOL isSpaceFree = [self _checkAvailabilityOfBlocksWith:blockPosition withRelativeSize:size];
    
    if (!isSpaceFree)
        return YES;
    
    // because we have determined that the space is all
    // available, lets fill it in as taken.
    
    [self _setIndexPath:indexPath forPosition:blockPosition];
    
    [self _setPositionForAllBlocks:blockPosition withRelativeSize:size WithIndexpath:indexPath];
    
    return NO;
}

//check if all four corners are free
-(BOOL)_checkAvailabilityOfBlocksWith:(CGPoint)blockPosition withRelativeSize:(CGSize)relativeSize{
    CGFloat numberOfBlocksInRow = floor(COLUMN_COUNT_IN_ONE_FULLTILE / relativeSize.width);
    CGFloat numberOfBlocksInColumn = floor(COLUMN_COUNT_IN_ONE_FULLTILE / relativeSize.height);
    
    //  check all the blocks
    for (int row = blockPosition.y; row < blockPosition.y + numberOfBlocksInColumn; row++) {
        for (int col = blockPosition.x; col < blockPosition.x + numberOfBlocksInRow; col++) {
            CGPoint position = CGPointMake(col, row);
            if ((BOOL)[self _indexPathForPosition:position])
                return NO;
        }
    }
    return YES;
    
}

//set indexpath for all the blocks in the tile
-(void)_setPositionForAllBlocks:(CGPoint)blockPosition withRelativeSize:(CGSize)relativeSize WithIndexpath:(NSIndexPath*)indexPath{
    CGFloat numberOfBlocksInRow = floor(COLUMN_COUNT_IN_ONE_FULLTILE / relativeSize.width);
    CGFloat numberOfBlocksInColumn = floor(COLUMN_COUNT_IN_ONE_FULLTILE / relativeSize.height);
    
    //  set position for all the desired blocks
    for (int row = blockPosition.y; row < blockPosition.y + numberOfBlocksInColumn; row++) {
        for (int col = blockPosition.x; col < blockPosition.x + numberOfBlocksInRow; col++) {
            CGPoint position = CGPointMake(col, row);
            [self _setPosition:position forIndexPath:indexPath];
        }
    }
}

- (NSIndexPath*)_indexPathForPosition:(CGPoint)point {
    // to avoid creating unbounded nsmutabledictionaries we should
    // have the innerdict be the unrestricted dimension
    
    NSNumber* unrestrictedPoint = @(point.y);
    NSNumber* restrictedPoint = @(point.x);
    
    return self.indexPathByPosition[restrictedPoint][unrestrictedPoint];
}

- (void) _setIndexPath:(NSIndexPath*)path forPosition:(CGPoint)point {
    NSMutableDictionary* innerDict = self.positionByIndexPath[@(path.section)];
    if (!innerDict)
        self.positionByIndexPath[@(path.section)] = [NSMutableDictionary dictionary];
    
    self.positionByIndexPath[@(path.section)][@(path.row)] = [NSValue valueWithCGPoint:point];
}

- (void) _setPosition:(CGPoint)point forIndexPath:(NSIndexPath*)indexPath {
    
    // to avoid creating unbounded nsmutabledictionaries we should
    // have the innerdict be the unrestricted dimension
    
    NSNumber* unrestrictedPoint = @(point.y);
    NSNumber* restrictedPoint = @(point.x);
    
    NSMutableDictionary* innerDict = self.indexPathByPosition[restrictedPoint];
    if (!innerDict)
        self.indexPathByPosition[restrictedPoint] = [NSMutableDictionary dictionary];
    
    self.indexPathByPosition[restrictedPoint][unrestrictedPoint] = indexPath;
}

//enum to float (Size)
-(CGFloat)_getRelativeSizeFor:(RelativeTileSize)sizeEnum{
    CGFloat size;
    switch (sizeEnum) {
        case RelativeTileSizeQuarter:
            size = 4;
            break;
        case RelativeTileSizeOneThird:
            size = 3;
            break;
        case RelativeTileSizeHalf:
            size = 2;
            break;
        case RelativeTileSizeTwoThird:
            size = 1.5;
            break;
        case RelativeTileSizeThreeQuarters:
            size = 1.33;
            break;
        case RelativeTileSizeFull:
            size = 1;
            break;
        default:
            break;
    }
    return size;
}

@end
