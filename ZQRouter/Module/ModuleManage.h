//
//  ModuleManage.h
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import <Foundation/Foundation.h>
#import "ZQModuleProtocol.h"


NS_ASSUME_NONNULL_BEGIN

extern NSString * const kModDidFinishLaunchingEvent;
extern NSString * const kModWillResignActiveEvent;
extern NSString * const kModDidBecomeActiveEvent;
extern NSString * const kModWillEnterForegroundEvent;
extern NSString * const kModDidEnterBackgroundEvent;
extern NSString * const kModWillTerminateEvent;
extern NSString * const kModDidReceiveMemoryWarningEvent;

extern NSString * const kModInstallEvent;



@interface ModuleManage : NSObject

+ (instancetype)shareInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

///注册模块
- (void)registerModule:(Class)moduleClass;

///注销模块
- (void)unregisterModuleWithModule:(Class)moduleClass;

///给模块实例对象注册自定义事件,注册代码可写在模块的install事件中
- (void)registerCustomEvent:(NSString *)event withModuleInstance:(id<ZQModuleProtocol>)moduleInstance;

///触发事件
- (void)triggerEvent:(NSString *)eventType;

///触发事件(携带自定义参数)
- (void)triggerEvent:(NSString *)eventType customParam:(NSDictionary *)customParam;

@end

NS_ASSUME_NONNULL_END
