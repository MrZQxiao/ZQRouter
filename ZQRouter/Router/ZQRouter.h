//
//  ZQRouter.h
//  ZQRouter
//
//  Created by LY on 2023/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZQRouter : NSObject

@property (nonatomic, strong) NSMutableDictionary *swiftModuleMap;

+ (instancetype)sharedInstance;

+ (BOOL)openURL:(NSURL *)URL;

+ (BOOL)openURL:(NSURL *)URL withParams:(NSDictionary<NSString *, NSString *> *)params;

+ (BOOL)openURL:(NSURL *)URL
     withParams:(NSDictionary<NSString *, NSString *> *)params
  customHandler:(void(^)(NSString *pathComponentKey, id obj, id returnValue))customHandler;

+ (id)performTarget:(NSString *)targetName
             action:(NSString *)actionName
             params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
