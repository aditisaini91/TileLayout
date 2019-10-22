//
//  CustomLayout.h
//  tilesstarter
//
//  Created by H231412 on 19.07.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomLayoutDelegate <UICollectionViewDelegate>
@optional
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout tileSizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

//horizontal layouting  here

@interface CustomLayout : UICollectionViewLayout
@property (nonatomic, weak)  NSObject<CustomLayoutDelegate>* delegate;

@end
