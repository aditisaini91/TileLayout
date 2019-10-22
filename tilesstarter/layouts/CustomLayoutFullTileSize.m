//
//  CustomLayoutFullTileSize.m
//  tilesstarter
//
//  Created by H231412 on 19.07.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import "CustomLayoutFullTileSize.h"

#define MAX_WIDTH   CGRectGetWidth(self.collectionView.bounds)
#define FULL_TILE_SIZE  300

@interface CustomLayoutFullTileSize ()

// this will be a 2x2 dictionary storing nsindexpaths
// which indicate the available/filled spaces in our quilt
// indexPathByPosition[point.x][point.y] = indexPath;
@property(nonatomic) NSMutableDictionary* indexPathByPosition;

// indexed by "section, row" this will serve as the rapid
// lookup of block position by indexpath.
// positionByIndexPath[indexPath.section][indexPath.row] = point;
@property(nonatomic) NSMutableDictionary* positionByIndexPath;

// previous layout cache.  this is to prevent choppiness
// when we scroll to the bottom of the screen - uicollectionview
// will repeatedly call layoutattributesforelementinrect on
// each scroll event.  pow!
@property(nonatomic) NSArray* previousLayoutAttributes;
@property(nonatomic) CGRect previousLayoutRect;

//starts the search from this point
@property(nonatomic) CGPoint firstOpenSpace;

//variables used to enhance search speed
//the furthest Y value : the furthest tile + height of tile
@property(nonatomic) int furthestTilePointY;

//the shortest tile(in height) : y value + height of tile
@property(nonatomic) int smallestTilePointY;

// remember the last indexpath placed, as to not
// relayout the same indexpaths while scrolling
@property(nonatomic) NSIndexPath* lastIndexPathPlaced;

@end


@implementation CustomLayoutFullTileSize
{
    NSMutableArray *_layoutAttributes;
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
    
    _layoutAttributes = [[NSMutableArray alloc] init];
    self.positionByIndexPath = [NSMutableDictionary dictionary];
}

#pragma mark - collection view layout

-(void)prepareLayout{
    
    NSInteger numSections = [self.collectionView numberOfSections];
    for (NSInteger section=0; section<numSections; section++) {
        NSInteger numRows = [self.collectionView numberOfItemsInSection:section];
        
        [self displayTime];
        for (NSInteger row =0; row<numRows; row++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            
            [self _computeAttributesForIndexPath:indexPath];
        }
        [self displayTime];
    }
}


-(CGSize)collectionViewContentSize {
    return CGSizeMake([[UIScreen mainScreen] bounds].size.width, self.furthestTilePointY + 100);
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [_layoutAttributes objectAtIndex:indexPath.row];
}

-(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
    
    if(CGRectEqualToRect(rect, self.previousLayoutRect)) {
        return self.previousLayoutAttributes;
    }
    self.previousLayoutRect = rect;
    
    // Return the visible attributes (rect intersection)
    self.previousLayoutAttributes = [_layoutAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *layoutAttributes, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, layoutAttributes.frame);
    }]];
    
    return self.previousLayoutAttributes;
}

-(void)invalidateLayout{
    [super invalidateLayout];
    
    self.firstOpenSpace = CGPointZero;
    self.indexPathByPosition = [NSMutableDictionary dictionary];
    self.positionByIndexPath = [NSMutableDictionary dictionary];
    self.lastIndexPathPlaced = nil;
    self.previousLayoutRect = CGRectZero;
    self.previousLayoutAttributes = nil;
    self.smallestTilePointY = 200;
}

#pragma mark - helper methods to compute attributes of tiles/cells

//compute and add layout attributes for the given indexpath to the layoutAttributes array
-(void)_computeAttributesForIndexPath:(NSIndexPath*)indexPath{
    
    UICollectionViewLayoutAttributes *layoutAttribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGSize sizeAtIndexpath = CGSizeMake(50, 50);
    if([self.delegate respondsToSelector:@selector(collectionView:layout:tileSizeForItemAtIndexPath:)]){
        sizeAtIndexpath = [self.delegate collectionView:[self collectionView] layout:self tileSizeForItemAtIndexPath:indexPath];
    }
    layoutAttribute.frame = [self _frameForIndexPath:indexPath WithSize:sizeAtIndexpath];
    
    [_layoutAttributes addObject:layoutAttribute];
}

- (CGRect) _frameForIndexPath:(NSIndexPath*)path WithSize:(CGSize)tileSize{
    // if item does not have a position, we will make one! (positionForIndexPath)
    CGPoint position;
    if(!self.positionByIndexPath[@(path.section)][@(path.row)])
        [self _fillInBlocksToIndexPath:path WithSize:tileSize];
    
    position = [self.positionByIndexPath[@(path.section)][@(path.row)] CGPointValue];
    
    if (position.y + tileSize.height > self.furthestTilePointY) {
        self.furthestTilePointY = position.y + tileSize.height;
    }
    
    if (position.y + tileSize.height < self.smallestTilePointY) {
        self.smallestTilePointY = position.y + tileSize.height;
    }
    
    return CGRectMake(position.x, position.y, tileSize.width, tileSize.height);
}

- (void) _fillInBlocksToIndexPath:(NSIndexPath*)path WithSize:(CGSize)size{
    
    // we'll have our data structure as if we're planning
    // a vertical layout, then when we assign positions to
    // the items we'll invert the axis
    
    NSInteger numSections = [self.collectionView numberOfSections];
    for (NSInteger section= self.lastIndexPathPlaced.section; section<numSections; section++) {
        NSInteger numRows = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger row = (!self.lastIndexPathPlaced? 0 : self.lastIndexPathPlaced.row+1); row < numRows; row++) {
            
            //if on tile :6, newRow is set : this is one possibility of adding it in a new row
            //            if (row == 6) {
            //                self.firstOpenSpace = CGPointMake(0, self.furthestTilePointY);
            //            self.smallestTilePointY = self.furthestTilePointY;
            //            }
            
            // exit when we are past the desired row
            if(section >= path.section && row > path.row) {
                //this is where the loop ends when attrs for all the tiles/cells till the given indexpath are set
                return;
            }
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            
            //            if(![self _traverseOpenTilesForTileWithSize:size andIndexPath:indexPath])
            if (![self _searchforOpenPointForTileWithSize:size andIndexPath:indexPath])
                self.lastIndexPathPlaced = indexPath;
        }
    }
}



//replace _traverseOpenTilesForTileWithSize
//This method searches for the open point block by block : size of block is (FULL_TILE_SIZE,FULL_TILE_SIZE)
-(BOOL) _searchforOpenPointForTileWithSize:(CGSize)size andIndexPath:(NSIndexPath*)indexPath{
    for (int y = 0;; y += FULL_TILE_SIZE) {
        int x = 0;
        
        while (x < MAX_WIDTH) {
            
            if (![self _searchforOpenPointInBlockWithOrigin:CGPointMake(x, y) WithSize:size andIndexPath:indexPath]) {
                
                //the space is available at the given point: loop breaks here
                return NO;
            }
            
            x += FULL_TILE_SIZE;
        }
    }
    
    //should not reach here
    return YES;
}

//Searches for the open point in the given block
-(BOOL)_searchforOpenPointInBlockWithOrigin:(CGPoint)tileOrigin WithSize:(CGSize)size andIndexPath:(NSIndexPath*)indexPath{
    BOOL allTakenBefore = YES;
    
    for(int y = tileOrigin.y; y < tileOrigin.y + FULL_TILE_SIZE; y++) {
        for (int x = tileOrigin.x; x < tileOrigin.x + FULL_TILE_SIZE ; x++) {
            
            if (x + size.width > tileOrigin.x + FULL_TILE_SIZE) {
                self.firstOpenSpace = CGPointMake(tileOrigin.x, y);
                break;
            }
            
            CGPoint point = CGPointMake(x, y);
            
            if([self _indexPathForPosition:point]) {
                continue;
            }
            
            //found the open point
            if(allTakenBefore) {
                self.firstOpenSpace = point;
                allTakenBefore = NO;
            }
            
            if(![self _traverseThroughtPoints:point WithTileSize:size andIndexPath:indexPath]) {
                return NO;      // the space is available
            }
        }
    }
    
    //the space was not found in this block
    return YES;
}


//when a open point is found, see if the needed size is available at that point
-(BOOL)_traverseThroughtPoints:(CGPoint)tileOrigin WithTileSize:(CGSize)tileSize andIndexPath:(NSIndexPath*)indexPath {
    
    // we need to make sure each square in the desired
    // area is available before we can place the square
    
    BOOL didTraverseAllBlocks = [self _traverseTilesForPoint:tileOrigin withSize:tileSize iterator:^(CGPoint point) {
        BOOL spaceAvailable = (BOOL)![self _indexPathForPosition:point];
        BOOL inBounds = tileOrigin.x + tileSize.width <  MAX_WIDTH;
        return (BOOL) (spaceAvailable && inBounds);
    }];
    
    
    if (!didTraverseAllBlocks) { return YES; }
    
    // because we have determined that the space is all
    // available, lets fill it in as taken.
    
    [self _setIndexPath:indexPath forPosition:tileOrigin];
    
    //for all the points in that tile/block : indexpath is set (so that we can know which all points are already occupied)
    [self _traverseTilesForPoint:tileOrigin withSize:tileSize iterator:^(CGPoint point) {
        [self _setPosition:point forIndexPath:indexPath];
        
        return YES;
    }];
    
    return NO;
}

// returning no in the callback will
// terminate the iterations early
- (BOOL) _traverseTilesForPoint:(CGPoint)point withSize:(CGSize)size iterator:(BOOL(^)(CGPoint))block {
    //goes through all the points and check if available
    for(int col=point.x; col<point.x+size.width; col++) {
        for (int row=point.y; row<point.y+size.height; row++) {
            if(!block(CGPointMake(col, row))) {
                self.firstOpenSpace = CGPointMake(col, row);
                return NO;
            }
        }
    }
    return YES;
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

-(void)displayTime{
    // get current date/time
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // display in 12HR/24HR (i.e. 11:25PM or 23:25) format according to User Settings
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    NSLog(@"User's current time in their preference format:%@",currentTime);
    
}

@end
