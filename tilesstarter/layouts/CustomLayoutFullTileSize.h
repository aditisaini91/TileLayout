//
//  CustomLayoutFullTileSize.h
//  tilesstarter
//
//  Created by H231412 on 19.07.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomLayout.h"

//trying to achieve full tile size height in horizontal layout

@interface CustomLayoutFullTileSize : UICollectionViewLayout
@property (nonatomic, weak)  NSObject<CustomLayoutDelegate>* delegate;

@end
