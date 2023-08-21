//
//  ZQContext.h
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface ZQContext : NSObject

+ (instancetype)shareInstance;

///应用启动时的application
@property(nonatomic, strong) UIApplication *application;
///应用启动时的launchOptions
@property(nonatomic, copy) NSDictionary *launchOptions;
///自定义事件名称
@property(nonatomic, assign) NSString *customEvent;
///跟随事件传递的参数
@property(nonatomic, copy) NSDictionary *customParam;

@end

NS_ASSUME_NONNULL_END
