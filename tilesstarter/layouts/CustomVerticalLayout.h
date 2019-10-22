//
//  CustomVerticalLayout.h
//  tilesstarter
//
//  Created by H231412 on 19.07.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomLayout.h"

//@protocol CustomVerticalLayoutDelegate <UICollectionViewDelegate>
//@optional
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout tileSizeForItemAtIndexPath:(NSIndexPath *)indexPath;
//
//@end


@interface CustomVerticalLayout : UICollectionViewLayout
@property (nonatomic, weak)  NSObject<CustomLayoutDelegate>* delegate;

@end
