//
//  ViewController.h
//  tilesstarter
//
//  Created by H231412 on 19.07.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITileLayout.h"

@interface ViewController  : UIViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITileLayoutDelegate>
{
    UICollectionView *_collectionView;
}

@end

