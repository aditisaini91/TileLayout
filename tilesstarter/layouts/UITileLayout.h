//
//  UITileLayout.h
//  tilesstarter
//
//  Created by H231412 on 12.10.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import <UIKit/UIKit.h>

//Size supported for tiles
typedef NS_ENUM(NSInteger, RelativeTileSize) {
    RelativeTileSizeQuarter,
    RelativeTileSizeOneThird,
    RelativeTileSizeHalf,
    RelativeTileSizeTwoThird,
    RelativeTileSizeThreeQuarters,
    RelativeTileSizeFull
};

@protocol UITileLayoutDelegate <UICollectionViewDelegate>
@optional

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout relativeTileSizeForItemAtIndexPath:(NSIndexPath *)indexPath;

-(int)numberOfFullTilesInLayout;

@end

@interface UITileLayout : UICollectionViewLayout

@property (nonatomic, weak)  NSObject<UITileLayoutDelegate>* delegate;

@end
