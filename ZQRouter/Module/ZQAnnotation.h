//
//  ZQAnnotation.h
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import <Foundation/Foundation.h>
#import "ZQModule.h"

NS_ASSUME_NONNULL_BEGIN

#ifndef MagicModSectName
#define MagicModSectName  "MagicMods"
#endif

#ifndef RouterSerSectName
#define RouterSerSectName  "RouterService"
#endif


#define MagicDATA(sectname) __attribute((used, section("__DATA,"#sectname" ")))
#define ServiceDATA(servicename) __attribute((used, section("__DATA,"#servicename" ")))


/**
 模块注册宏（同步触发模块的init事件）
 @param name 模块名称
 */
#define MagicMod(name) \
class Magic; char * k##name##_mod MagicDATA(MagicMods) = ""#name"";

/**
Swift模块Service注册宏
@param mod 模块名称
@param target target名称
*/
#define RouterServiceMap(mod, target) \
class Magic; char * k##target##_ser ServiceDATA(RouterService) = ""#mod"_"#target"";


@interface ZQAnnotation : NSObject

@end

NS_ASSUME_NONNULL_END
