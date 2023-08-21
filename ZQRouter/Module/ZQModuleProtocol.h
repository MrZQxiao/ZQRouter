//
//  ModuleProtocol.h
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import <Foundation/Foundation.h>
@class ZQContext;


@protocol ZQModuleProtocol <NSObject>
#pragma mark - App生命周期事件
@optional
///App启动
- (void)modDidFinishLaunchingEvent:(ZQContext *)context;

///App被挂起
- (void)modWillResignActiveEvent:(ZQContext *)context;

///App被挂起后复原
- (void)modDidBecomeActiveEvent:(ZQContext *)context;

///App进入后台
- (void)modDidEnterBackgroundEvent:(ZQContext *)context;

///App进入前台
- (void)modWillEnterForegroundEvent:(ZQContext *)context;

///App终止
- (void)modWillTerminateEvent:(ZQContext *)context;

///App收到内存警告
- (void)modDidReceiveMemoryWarningEvent:(ZQContext *)context;


///安装模块
- (void)modInstallEvent:(ZQContext *)context;

@end
