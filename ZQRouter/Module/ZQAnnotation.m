//
//  ZQAnnotation.m
//  ZQRouter
//
//  Created by LY on 2023/8/21.
//

#import "ZQAnnotation.h"
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/ldsyms.h>
#import "ZQRouter.h"

NSArray<NSString *>* MSReadConfiguration(char *sectionName,const struct mach_header *mhp);
static void dyld_callback(const struct mach_header *mhp, intptr_t vmaddr_slide) {
    NSArray *mods = MSReadConfiguration(MagicModSectName, mhp);
    NSArray *services = MSReadConfiguration(RouterSerSectName, mhp);

    for (NSString *modName in mods) {
        Class cls;
        if (modName) {
            cls = NSClassFromString(modName);

            if (cls) {
                [[ModuleManage shareInstance] registerModule:cls];
            }
        }
    }

    for (NSString *service in services) {
        if (service) {
            [ZQRouter registerSwiftServiceMap:service];
        }
    }
}
__attribute__((constructor))
void initProphet() {
    _dyld_register_func_for_add_image(dyld_callback);
}

NSArray<NSString *>* MSReadConfiguration(char *sectionName,const struct mach_header *mhp) {
    NSMutableArray *configs = [NSMutableArray array];
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
#else
    const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
#endif

    unsigned long counter = size/sizeof(void*);
    for(int idx = 0; idx < counter; ++idx){
        char *string = (char*)memory[idx];
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;

        if(str) [configs addObject:str];
    }

    return configs;
}


@implementation ZQAnnotation

@end
