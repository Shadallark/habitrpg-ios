//
//  HRPGActivityIndicatorOverlayView.h
//  Habitica
//
//  Created by Phillip Thelen on 18/05/14.
//  Copyright (c) 2014 Phillip Thelen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HRPGActivityIndicatorOverlayView : NSObject

- (void)display:(void (^)())completitionBlock;

- (void)dismiss:(void (^)())completitionBlock;


- (id)initWithString:(NSString *)activityString withColor:(UIColor*)color;

@property NSString *activityString;
@property UIColor *ballColor;


@end
