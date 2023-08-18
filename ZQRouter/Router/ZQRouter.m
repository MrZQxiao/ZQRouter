//
//  ZQRouter.m
//  ZQRouter
//
//  Created by LY on 2023/8/17.
//

#import "ZQRouter.h"
#import "UIViewController+ZQExtension.h"

static NSString *const ZQURLFragmentControlerEnterModePush = @"push";
static NSString *const ZQURLFragmentControlerEnterModeModal = @"modal";

typedef NS_ENUM(NSUInteger, ZQRouteMode) {
    ZQRouteModeUnknown,       //未知类型
    ZQRouteModeTargetAction   //通过Target-Action调用
};

typedef NS_ENUM(NSUInteger, ZQRouterControlerEnterMode) {
    //未知类型(不进行跳转，只获取return object)
    ZQRouterControlerEnterModeUnknown,
    //push操作
    ZQRouterControlerEnterModePush,
    //modal操作
    ZQRouterControlerEnterModeModal
};


@interface ZQRouter()

@end

@implementation ZQRouter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ZQRouter *router;
    dispatch_once(&onceToken, ^{
        router = [[ZQRouter alloc] init];
    });
    return router;
}

#pragma mark - Public Method - OpenURL
+ (BOOL)canOpenURL:(NSURL *)URL {
    if (!URL) {
        return NO;
    }

    NSString *scheme = URL.scheme;
    if (!scheme.length) {
        return NO;
    }

    NSString *host = URL.host;
    if (!host.length) {
        return NO;
    }



    //优先查找Class
   NSString *modName = [ZQRouter.sharedInstance.swiftModuleMap valueForKey:host];
   NSString *targetClsStr = nil;
   if (modName) {
       //Swift
       targetClsStr = [NSString stringWithFormat:@"%@.Service_%@", modName,host];
   }else{
       //Objc
       targetClsStr = [NSString stringWithFormat:@"Service_%@", host];
   }

    Class mClass = NSClassFromString(targetClsStr);

    //selector
    NSArray<NSString *> *pathComponents = URL.pathComponents;

    __block NSString *selectorStr;

    [pathComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isEqualToString:@"/"]) {
            selectorStr = obj;
        }
    }];
    BOOL flag = NO;
    if (selectorStr) {
        selectorStr = [NSString stringWithFormat:@"func_%@:",selectorStr];
        SEL selector = NSSelectorFromString(selectorStr);
        id instance = [[mClass alloc] init];
        if ([instance respondsToSelector:selector]) {
            flag = YES;
        }
    }

    return flag;
}

+ (BOOL)openURL:(NSURL *)URL {
    return [self openURL:URL withParams:nil customHandler:nil];
}

+ (BOOL)openURL:(NSURL *)URL withParams:(NSDictionary<NSString *, NSString *> *)params {
    return [self openURL:URL withParams:params customHandler:nil];
}

+ (BOOL)openURL:(NSURL *)URL
     withParams:(NSDictionary<NSString *, NSString *> *)params
  customHandler:(void(^)(NSString *pathComponentKey, id obj, id returnValue))customHandler {

    if (![self canOpenURL:URL]) {
#if DEBUG
        NSString *errMsg = [NSString stringWithFormat:@"[%@]未能正常打开,请检查target-action是否有效.",URL.absoluteString];
        NSLog(@"errMsg");
#endif
        return NO;
    }

    //NSString *scheme = URL.scheme;
    NSString *host = URL.host;

    ZQRouterControlerEnterMode enterMode = ZQRouterControlerEnterModeUnknown;
    if (URL.fragment.length) {
        enterMode = [self viewControllerEnterMode:URL.fragment];
    }

    //parameters
    NSDictionary<NSString *, NSString *> *queryDic = [self queryParameterFromURL:URL];

    //selectorStr
    __block NSString *selectorStr;

    NSArray<NSString *> *pathComponents = URL.pathComponents;

    [pathComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isEqualToString:@"/"]) {
            selectorStr = obj;
        }
    }];

    id returnValue;
    id obj;
    NSString *pathComponentKey;
    NSString *modName = [ZQRouter.sharedInstance.swiftModuleMap valueForKey:host];
    //通过Target-Action调用
    NSString *targetClsStr = nil;
    if (modName) {
        //Swift
        targetClsStr = [NSString stringWithFormat:@"%@.Service_%@", modName,host];
    }else{
        //Objc
        targetClsStr = [NSString stringWithFormat:@"Service_%@", host];
    }
    Class mClass = NSClassFromString(targetClsStr);;
    selectorStr = [NSString stringWithFormat:@"func_%@:", selectorStr];
    SEL selector = NSSelectorFromString(selectorStr);
    id instance = [[mClass alloc] init];
    NSDictionary<NSString *, id> *finalParams = [self solveURLParams:queryDic withFuncParams:params forClass:mClass];
    returnValue = [self safePerformAction:selector target:instance params:finalParams];
    pathComponentKey = [NSString stringWithFormat:@"%@.%@",targetClsStr,selectorStr];

    if (enterMode == ZQRouterControlerEnterModePush || enterMode == ZQRouterControlerEnterModeModal) {
        [self solveJumpWithViewController:(UIViewController *)returnValue andJumpMode:enterMode shouldAnimate:YES];
    }

    !customHandler?:customHandler(pathComponentKey, obj, returnValue);

    return YES;
}


#pragma mark - Public Method - Target-Action
+ (id)performTarget:(NSString *)targetName
             action:(NSString *)actionName
             params:(NSDictionary *)params {

    NSString *modName = [ZQRouter.sharedInstance.swiftModuleMap valueForKey:targetName];
    NSString *targetClsStr = nil;
    if (modName) {
        //Swift
        targetClsStr = [NSString stringWithFormat:@"%@.Service_%@", modName,targetName];
    }else{
        //Objc
        targetClsStr = [NSString stringWithFormat:@"Service_%@", targetName];
    }
    NSString *actionString = [NSString stringWithFormat:@"func_%@:", actionName];
    Class targetClass = NSClassFromString(targetClsStr);
    NSObject *target  = [[targetClass alloc] init];

    SEL action = NSSelectorFromString(actionString);

    if (target == nil) {
        NSString *errMsg = [NSString stringWithFormat:@"%@未能找到,请检查%@是否存在.", targetClsStr, targetClsStr];
        NSLog(@"%@",errMsg);
        return nil;
    }

    if ([target respondsToSelector:action]) {
        return [self safePerformAction:action target:target params:params];
    }else {
#if DEBUG
        NSString *errMsg = [NSString stringWithFormat:@"%@未能正常响应%@,请检查%@是否存在及签名是否正确.", targetClsStr, actionString, actionString];
        NSLog(@"%@",errMsg);
#endif
        return nil;
    }
}


#pragma mark - getter
- (NSMutableDictionary *)swiftModuleMap {
    if (!_swiftModuleMap) {
        _swiftModuleMap = [NSMutableDictionary dictionary];
    }
    return _swiftModuleMap;
}

#pragma mark - Private Method
///根据URL分解出参数
+ (NSDictionary<NSString *, id> *)queryParameterFromURL:(NSURL *)URL {
    if (!URL) return nil;

    NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary *queryParams = @{}.mutableCopy;

    for (NSURLQueryItem *item in queryItems) {
        if (item.value == nil) {
            continue;
        }

        if (queryParams[item.name] == nil) {
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }

    return queryParams.copy;
}

//把json解析为dictionary
+ (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)queryParameterFromJson:(NSString *)json {
    if (!json.length) {
        return nil;
    }
    NSError *error;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"MSRouter [Error] Wrong URL Query Format: \n%@", error.description);
    }
    return dic;
}


+ (ZQRouterControlerEnterMode)viewControllerEnterMode:(NSString *)enterModePattern {
    enterModePattern = enterModePattern.lowercaseString;
    if ([enterModePattern isEqualToString:ZQURLFragmentControlerEnterModePush]) {
        return ZQRouterControlerEnterModePush;
    } else if ([enterModePattern isEqualToString:ZQURLFragmentControlerEnterModeModal]) {
        return ZQRouterControlerEnterModeModal;
    }
    return ZQRouterControlerEnterModePush;
}

+ (NSDictionary<NSString *, id> *)solveURLParams:(NSDictionary<NSString *, id> *)URLParams
                                  withFuncParams:(NSDictionary<NSString *, id> *)funcParams
                                        forClass:(Class)mClass {
    if (!URLParams) {
        URLParams = @{};
    }
    NSMutableDictionary<NSString *, id> *params = URLParams.mutableCopy;
    NSArray<NSString *> *funcParamKeys = funcParams.allKeys;
    [funcParamKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [params setObject:funcParams[obj] forKey:obj];
    }];

    return params;
}
//获取返回值
+ (id)safePerformAction:(SEL)action target:(NSObject *)target params:(NSDictionary *)params {

    NSMethodSignature* methodSig = [target methodSignatureForSelector:action];
    if(methodSig == nil) {
        return nil;
    }
    const char* retType = [methodSig methodReturnType];

    if (strcmp(retType, @encode(void)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        return nil;
    }

    if (strcmp(retType, @encode(NSInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(BOOL)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        BOOL result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(CGFloat)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        CGFloat result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(NSUInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSUInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
}

+ (void)solveJumpWithViewController:(UIViewController *)viewController
                        andJumpMode:(ZQRouterControlerEnterMode)enterMode
                      shouldAnimate:(BOOL)animate {
    if (viewController == nil) {return ;}
    Class accessTokenClass = NSClassFromString(@"MSAccessTokenViewController");
    if ([UIViewController.currentViewController isKindOfClass:accessTokenClass] && [viewController isKindOfClass:accessTokenClass]) {
        // 特殊判断 MSAccessTokenViewController，不能重复弹出
        return;
    }

    if (enterMode == ZQRouterControlerEnterModePush) {
        [UIViewController.currentViewController.navigationController pushViewController:viewController animated:YES];
    } else if (enterMode == ZQRouterControlerEnterModeModal) {
        [UIViewController.currentViewController presentViewController:viewController animated:animate completion:nil];
    }
}


@end
