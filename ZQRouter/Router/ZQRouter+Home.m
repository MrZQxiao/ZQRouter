//
//  ZQRouter+Home.m
//  ZQRouter
//
//  Created by LY on 2023/8/18.
//

#import "ZQRouter+Home.h"

static NSString * const kTarget = @"Home";

@implementation ZQRouter (Home)

+ (UIViewController *)Home_main {
    UIViewController *home = [ZQRouter performTarget:kTarget action:@"main" params:nil];
    return home;
}

@end
