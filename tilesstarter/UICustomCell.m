//
//  UICustomCell.m
//  tilesstarter
//
//  Created by H231412 on 15.10.18.
//  Copyright © 2018 H231412. All rights reserved.
//


#import "UICustomCell.h"

@implementation UICustomCell {
    UILabel* _label;
}

-(UILabel*)label{
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_label];
    }
    return _label;
}

-(void)layoutSubviews{
    [super layoutSubviews];

    if(_label) {
        _label.frame = CGRectMake(0, 0, 50, 50);
    }
}

@end
