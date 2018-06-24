//
//  CAMetalLayer+ARMetalLayer.m
//  ARRecorder
//
//  Created by 伍小华 on 2018/3/3.
//  Copyright © 2018年 伍小华. All rights reserved.
//

#import "CAMetalLayer+ARMetalLayer.h"
#import "AppDelegate.h"
#import <objc/runtime.h>
@implementation CAMetalLayer (ARMetalLayer)
- (void)setupSwizzling{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{

        SEL copiedOriginalSelector = @selector(orginalNextDrawable);
        SEL originalSelector = @selector(nextDrawable);
        SEL swizzledSelector = @selector(newNextDrawable);
        
        Class class = [self class];
        
        Method copiedOriginalMethod = class_getInstanceMethod(class, copiedOriginalSelector);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        IMP oldImp = method_getImplementation(originalMethod);
        method_setImplementation(copiedOriginalMethod, oldImp);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (nullable id <CAMetalDrawable>)newNextDrawable
{
    id drawable = [self orginalNextDrawable];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.currentSceneDrawable = drawable;
    return drawable;
}
- (id<CAMetalDrawable>)orginalNextDrawable
{
    return nil;
}
@end
