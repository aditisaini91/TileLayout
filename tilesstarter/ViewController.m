//
//  ViewController.m
//  tilesstarter
//
//  Created by H231412 on 19.07.18.
//  Copyright © 2018 H231412. All rights reserved.
//

#import "ViewController.h"
#import "UICustomCell.h"

@interface ViewController ()

@end

@implementation ViewController{

    NSArray* _relativeSizes;
    UITileLayout* _layout;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    _relativeSizes = [[NSArray alloc] initWithObjects:@(RelativeTileSizeFull),@(RelativeTileSizeThreeQuarters),@(RelativeTileSizeTwoThird),@(RelativeTileSizeHalf),@(RelativeTileSizeOneThird), @(RelativeTileSizeQuarter), nil];

    _layout  = [[UITileLayout alloc] init];
    _layout.delegate = self;
    
    _collectionView = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:_layout];
    [_collectionView setDataSource:self];
    [_collectionView setDelegate:self];
    [_collectionView registerClass:[UICustomCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    
    [self.view addSubview:_collectionView];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    [_collectionView setFrame:self.view.frame];
    [_layout invalidateLayout];
}

#pragma mark - collection view  datasource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 100;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Content to put in the tile :
    UICustomCell* cell = (UICustomCell* )[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithHue:drand48() saturation:1.0 brightness:1.0 alpha:1.0];
    [cell.label setText:[NSString stringWithFormat:@"%ld %ld",(long)indexPath.section ,(long)indexPath.row]];

    return cell;
}

#pragma mark - block layout delegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout relativeTileSizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >= _relativeSizes.count) {
        return CGSizeMake([_relativeSizes[indexPath.row % 6] integerValue], [_relativeSizes[indexPath.row % 6] integerValue]);

    }
    return CGSizeMake([_relativeSizes[indexPath.row] integerValue], [_relativeSizes[indexPath.row] integerValue]);
}

//This method decided the content size of the collection view based on the number of full tiles
- (int)numberOfFullTilesInLayout{
    //for now , in landscape : 2 full tiles and in potrait : 1 full tile
    if (CGRectGetHeight(self.view.bounds) > CGRectGetWidth(self.view.bounds)) {
        return 1;
    } else {
        return 2;
    }
    return 1;
}

@end
