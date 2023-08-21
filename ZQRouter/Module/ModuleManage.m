//
//  ModuleManage.m
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import "ModuleManage.h"
#import "ZQContext.h"
#import <objc/runtime.h>


NSString * const kModDidFinishLaunchingEvent                        = @"modDidFinishLaunchingEvent:";
NSString * const kModWillResignActiveEvent                          = @"modWillResignActiveEvent:";
NSString * const kModDidBecomeActiveEvent                           = @"modDidBecomeActiveEvent:";
NSString * const kModWillEnterForegroundEvent                       = @"modWillEnterForegroundEvent:";
NSString * const kModDidEnterBackgroundEvent                        = @"modDidEnterBackgroundEvent:";
NSString * const kModWillTerminateEvent                             = @"modWillTerminateEvent:";
NSString * const kModDidReceiveMemoryWarningEvent                   = @"modDidReceiveMemoryWarningEvent:";

NSString * const kModInstallEvent                                   = @"modInstallEvent:";

@interface ModuleManage ()

@property(nonatomic, strong) NSMutableArray *modules;
@property(nonatomic, strong) NSMutableSet *selectorByEvent;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<id<ZQModuleProtocol>> *> *modulesByEvent;

@end

@implementation ModuleManage

+ (instancetype)shareInstance {
    static ModuleManage *manager;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });

    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        //...
    }
    return self;
}

- (void)registerModule:(Class)moduleClass {
    if (!moduleClass) return;

    NSString *moduleName = NSStringFromClass(moduleClass);

    if ([moduleClass conformsToProtocol:@protocol(ZQModuleProtocol)]) {
        //实例化
        id<ZQModuleProtocol> moduleInstance = [[moduleClass alloc] init];
        [self.modules addObject:moduleInstance];

        NSLog(@"%@模块初始化完成.", NSStringFromClass(moduleClass));

        //注册事件-模块映射表
        [self registerEventWithModuleInstance:moduleInstance];
    }else{
        NSLog(@">>>MagicStudioError:[%@]没有实现MSModuleProtocol协议", moduleName);
    }
}

- (void)registerEventWithModuleInstance:(id<ZQModuleProtocol>)moduleInstance {
    NSArray<NSString *> *events = self.selectorByEvent.allObjects;

    //遍历所有事件,创建事件-模块映射关系
    [events enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerEvent:obj withModuleInstance:moduleInstance];
    }];
}

- (void)registerEvent:(NSString *)event withModuleInstance:(id<ZQModuleProtocol>)moduleInstance {
    NSParameterAssert(event);
    if (!event) return;
    SEL selector = NSSelectorFromString(event);
    if(!selector) return;

    if (![self.selectorByEvent containsObject:event]) {
        //如果eventType类型不存在就添加到事件字典中,为的是扩充自定义事件类型
        [self.selectorByEvent addObject:event];
    }
    if (!self.modulesByEvent[event]) {
        [self.modulesByEvent setObject:@[].mutableCopy forKey:event];
    }
    NSMutableArray *modulesOfEvent = [self.modulesByEvent objectForKey:event];

    if (![modulesOfEvent containsObject:moduleInstance] && [moduleInstance respondsToSelector:selector]) {
        [modulesOfEvent addObject:moduleInstance];
    }
}


- (void)unregisterModuleWithModule:(Class)moduleClass {
    if (!moduleClass) return;

    //modules删除moduleClass对应的module
    __block NSInteger index = -1;
    [self.modules enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:moduleClass]) {
            index = idx;
            *stop = YES;
        }
    }];

    if (index >= 0) {
        [self.modules removeObjectAtIndex:index];
    }

    //模块-事件映射表删除moduleClass对应的module
    [self.modulesByEvent enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<id<ZQModuleProtocol>> * _Nonnull obj, BOOL * _Nonnull stop) {
        __block NSInteger index = -1;

        [obj enumerateObjectsUsingBlock:^(id<ZQModuleProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:moduleClass]) {
                index = idx;
                *stop = YES;
            }
        }];

        if (index >= 0) {
            [obj removeObjectAtIndex:index];
        }
    }];
}

- (void)registerCustomEvent:(NSString *)event withModuleInstance:(id<ZQModuleProtocol>)moduleInstance {
    [self registerEvent:event withModuleInstance:moduleInstance];
}

#pragma mark - 触发事件
- (void)triggerEvent:(NSString *)event {
    [self triggerEvent:event customParam:nil];
}

- (void)triggerEvent:(NSString *)event customParam:(NSDictionary *)customParam {
    [self triggerModuleEvent:event withTarget:nil withCustomParam:customParam];
}

- (void)triggerModuleEvent:(NSString *)event
                withTarget:(id<ZQModuleProtocol>)target
           withCustomParam:(NSDictionary *)customParam {
    if ([event isEqualToString:kModInstallEvent]) {
        [self triggerModuleInstallEventWithTarget:target withCustomParam:customParam];
    }else {
        [self triggerModuleCommonEvent:event withTarget:target withCustomParam:customParam];
    }
}

- (void)triggerModuleInstallEventWithTarget:(id<ZQModuleProtocol>)target withCustomParam:(NSDictionary *)customParam {

    NSArray<id<ZQModuleProtocol>> *moduleInstances;
    if (target) {
        moduleInstances = @[target];
    }else{
        moduleInstances = [self.modulesByEvent objectForKey:kModInstallEvent];
    }

    [self triggerModuleCommonEvent:kModInstallEvent withTarget:target withCustomParam:customParam];
}



- (void)triggerModuleCommonEvent:(NSString *)eventType
                      withTarget:(id<ZQModuleProtocol>)target
                 withCustomParam:(NSDictionary *)customParam {
    if (!eventType) return;
    if (![self.selectorByEvent containsObject:eventType]) return;
    SEL selector = NSSelectorFromString(eventType);
    NSArray<id<ZQModuleProtocol>> *moduleInstances;
    if (target) {
        moduleInstances = @[target];
    }else{
        moduleInstances = [self.modulesByEvent objectForKey:eventType];
    }

    ZQContext *context = [ZQContext shareInstance].copy;
    context.customEvent = eventType;
    context.customParam = customParam;

    [moduleInstances enumerateObjectsUsingBlock:^(id<ZQModuleProtocol>  _Nonnull moduleInstance, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([moduleInstance respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [moduleInstance performSelector:selector withObject:context];
#pragma clang diagnostic pop
        }
    }];
}


#pragma mark - property getter
- (NSMutableArray *)modules {
    if (!_modules) {
        _modules = [NSMutableArray array];
    }
    return _modules;
}

- (NSMutableDictionary<NSString *,NSMutableArray<id<ZQModuleProtocol>> *> *)modulesByEvent {
    if (!_modulesByEvent) {
        _modulesByEvent = [NSMutableDictionary dictionary];
    }
    return _modulesByEvent;
}

- (NSMutableSet *)selectorByEvent {
    if (!_selectorByEvent) {
        _selectorByEvent = [NSMutableSet set];
        NSSet *blackSelList = [NSSet setWithObjects:@"priority", @"async", nil];

        unsigned int numberOfMethods = 0;
        struct objc_method_description *methodDescriptions = protocol_copyMethodDescriptionList(@protocol(ZQModuleProtocol), NO, YES, &numberOfMethods);
        for (unsigned int i = 0; i < numberOfMethods; ++i) {
            struct objc_method_description methodDescription = methodDescriptions[i];
            SEL selector = methodDescription.name;
            if (! class_getInstanceMethod([self class], selector)) {
                NSString *selectorString = [NSString stringWithCString:sel_getName(selector) encoding:NSUTF8StringEncoding];
                if (![blackSelList containsObject:selectorString]) {
                    [_selectorByEvent addObject:selectorString];
                }
            }
        }
    }
    return _selectorByEvent;
}




@end
