#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#include "bridge.h"

void RunMainLoop(void) {
    NSApplication * app = [NSApplication sharedApplication];
    [app setActivationPolicy: NSApplicationActivationPolicyAccessory];
    [app run];
}

unsigned int GetMouseDisplayID(void) {
    CGEventRef evt = CGEventCreate(NULL);
    if (!evt) return (unsigned int) CGMainDisplayID();
    CGPoint mouse = CGEventGetLocation(evt);
    CFRelease(evt);

    CGDirectDisplayID displayID = CGMainDisplayID();
    uint32_t matchCount = 0;
    CGGetDisplaysWithPoint(mouse, 1, & displayID, & matchCount);
    return (unsigned int) displayID;
}

int GetActiveAppPidOnDisplay(unsigned int display_id) {
    @autoreleasepool {
        CGRect displayBounds = CGDisplayBounds((CGDirectDisplayID) display_id);

        CFArrayRef windowList = CGWindowListCopyWindowInfo(
            kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
            kCGNullWindowID);
        if (!windowList) return -1;

        int result = -1;
        CFIndex count = CFArrayGetCount(windowList);

        for (CFIndex i = 0; i < count; i++) {
            CFDictionaryRef win = (CFDictionaryRef) CFArrayGetValueAtIndex(windowList, i);

            CFNumberRef layerNum = (CFNumberRef) CFDictionaryGetValue(win, kCGWindowLayer);
            int layer = 0;
            if (layerNum) CFNumberGetValue(layerNum, kCFNumberIntType, & layer);
            if (layer != 0) continue;

            CFDictionaryRef boundsDict = (CFDictionaryRef) CFDictionaryGetValue(win, kCGWindowBounds);
            if (!boundsDict) continue;
            CGRect bounds;
            if (!CGRectMakeWithDictionaryRepresentation(boundsDict, & bounds)) continue;

            CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
            if (!CGRectContainsPoint(displayBounds, center)) continue;

            CFNumberRef pidNum = (CFNumberRef) CFDictionaryGetValue(win, kCGWindowOwnerPID);
            if (!pidNum) continue;
            int pid = 0;
            CFNumberGetValue(pidNum, kCFNumberIntType, & pid);
            result = pid;
            break;
        }

        CFRelease(windowList);
        return result;
    }
}

void FocusAppByPid(int pid) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        @autoreleasepool {
            NSRunningApplication * app = [NSRunningApplication
                runningApplicationWithProcessIdentifier: (pid_t) pid
            ];
            if (!app) return;
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [app activateWithOptions: NSApplicationActivateIgnoringOtherApps];
            #pragma clang diagnostic pop
        }
    });
}
