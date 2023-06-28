//
//  AerialDesktop.m
//  Aerial Companion
//
//  Created by Guillaume Louel on 02/12/2020.
//

#import "Aerial_Companion-Swift.h"
#import "AerialDesktop.h"
#include <dlfcn.h>
#import <Cocoa/Cocoa.h>
//#import <ScreenSaver/ScreenSaver.h>
#import "AerialView.h"

@interface AerialDesktop ()
@property AerialView *ssv;
//@property NSWindowController *pwc;
@property void *handle;
@end

@implementation AerialDesktop
- (void)awakeFromNib {
    // Load Aerial's bundle
    NSString *path = [NSString stringWithFormat: @"%@/Contents/MacOS/Aerial", [Constant aerialPath]];
    NSLog(@"Desktop WOOO %@", path);
    const char* st = [path UTF8String];
    _handle = dlopen(st, RTLD_LAZY);
    
    [super awakeFromNib];
    NSLog(@"Desktop Awoken");
  
    //[self.window setDelegate:self];
    [self.window.contentView setAutoresizesSubviews:YES];
}

- (void)openPanel {
    //_pwc = [[NSClassFromString(@"PanelWindowController") alloc] init];
    //[_pwc showWindow:self];
}

- (void)togglePause {
    [_ssv togglePause];
}

- (void)nextVideo {
    [_ssv nextVideo];
}

- (void)skipAndHide {
    [_ssv skipAndHide];
}

- (float)getSpeed {
    return [_ssv getGlobalSpeed];
}

- (void)changeSpeed:(float) fSpeed {
    [_ssv setGlobalSpeed:fSpeed];
}


- (void)windowWillLoad {
    [super windowWillLoad];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Create a new AerialView of the window's inner size
    _ssv = [[NSClassFromString(@"AerialView") alloc]
            initWithFrame:
            CGRectMake(0, 0,
                       self.window.screen.frame.size.width,
                       self.window.screen.frame.size.height)
            isPreview:false];
  
    //NSLog(@"width %f",self.window.screen.frame.size.width);
    [self.window setContentView: _ssv];
    
    [self.window setFrame: [self.window.screen frame] display: YES animate: NO];

    /*if (@available(macOS 13, *)) {
        [self.window setLevel:kCGDesktopWindowLevel];
    } else {*/
    
    //[self.window setLevel:kCGDesktopWindowLevel - 1];
    //}
    
    [self.window setCollectionBehavior:
                (NSWindowCollectionBehaviorCanJoinAllSpaces |
                 NSWindowCollectionBehaviorStationary |
                 NSWindowCollectionBehaviorIgnoresCycle)];
}

- (void)stopScreensaver {
    [_ssv stopAnimation];
    _ssv = nil;
    
    int i = dlclose(_handle);
    NSLog(@"Desktop closed %d",i);
}

@end
