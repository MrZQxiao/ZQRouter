//
//  ZQContext.m
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import "ZQContext.h"

@implementation ZQContext

+ (instancetype)shareInstance {
    static ZQContext *context;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        context = [[self alloc] init];
    });

    return context;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ZQContext *context = [[self.class allocWithZone:zone] init];
    context.application = self.application;
    context.launchOptions = self.launchOptions;
    context.customEvent = self.customEvent;
    context.customParam = self.customParam;
   
    return context;
}



@end
