//
//  ModuleStudio.h
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import <Foundation/Foundation.h>
#import "ZQContext.h"


NS_ASSUME_NONNULL_BEGIN

@interface ModuleStudio : NSObject

///保存了容器所有数据
@property(nonatomic, strong) ZQContext *context;

+ (instancetype)shareInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - 触发事件
///触发事件
+ (void)triggerEvent:(NSString *)eventType;

///触发事件(携带自定义参数)
+ (void)triggerEvent:(NSString *)eventType customParam:(NSDictionary *)param;


@end

NS_ASSUME_NONNULL_END
