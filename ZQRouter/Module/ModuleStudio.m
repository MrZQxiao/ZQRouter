//
//  ModuleStudio.m
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import "ModuleStudio.h"
#import "ModuleManage.h"


@implementation ModuleStudio

+ (instancetype)shareInstance {
    static ModuleStudio *magic;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        magic = [[self alloc] init];
    });

    return magic;
}

+ (void)triggerEvent:(NSString *)eventType {
    [[ModuleManage shareInstance] triggerEvent:eventType];
}

+ (void)triggerEvent:(NSString *)eventType customParam:(NSDictionary *)param {
    [[ModuleManage shareInstance] triggerEvent:eventType customParam:param];
}

@end
