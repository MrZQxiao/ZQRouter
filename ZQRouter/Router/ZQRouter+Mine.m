//
//  ZQRouter+Mine.m
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import "ZQRouter+Mine.h"

static NSString * const kTarget = @"Mine";

@implementation ZQRouter (Mine)

+ (UIViewController *)Mine_main {
    UIViewController *mine = [ZQRouter performTarget:kTarget action:@"main" params:nil];
    return mine;
}

@end
