#ifndef SIMPLEGUI_NATIVE_MACOS_H
#define SIMPLEGUI_NATIVE_MACOS_H

#import <Cocoa/Cocoa.h>

static inline void mac_enter_fullscreen(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        for (NSWindow *win in [app windows]) {
            if ([win isVisible] && ([win styleMask] & (NSWindowStyleMaskTitled | NSWindowStyleMaskResizable))) {
                win.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
                if (!([win styleMask] & NSWindowStyleMaskFullScreen)) {
                    [win toggleFullScreen:nil];
                }
            }
        }
    }
}

static inline void mac_exit_fullscreen(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        for (NSWindow *win in [app windows]) {
            if ([win isVisible] && ([win styleMask] & NSWindowStyleMaskFullScreen)) {
                [win toggleFullScreen:nil];
            }
        }
    }
}

static inline void mac_toggle_fullscreen(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        for (NSWindow *win in [app windows]) {
            if ([win isVisible] && ([win styleMask] & (NSWindowStyleMaskTitled | NSWindowStyleMaskResizable))) {
                win.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
                [win toggleFullScreen:nil];
            }
        }
    }
}

static inline bool mac_is_fullscreen(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        for (NSWindow *win in [app windows]) {
            if ([win isVisible] && ([win styleMask] & NSWindowStyleMaskFullScreen)) {
                return true;
            }
        }
    }
    return false;
}

#endif
