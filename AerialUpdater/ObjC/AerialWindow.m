//
//  AerialWindow.m
//  Aerial
//
//  Created by Guillaume Louel on 29/08/2020.
//

#import "AerialWindow.h"
#include <dlfcn.h>
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>

@interface AerialWindow ()
@property (strong) IBOutlet NSView *mainView;
@property (strong) IBOutlet NSView *childView;

@property ScreenSaverView *ssv;
@end

@implementation AerialWindow
- (void)awakeFromNib {
    // Load Aerial's bundle
    void *handle = dlopen("/Users/glouel/Aerial.saver/Contents/MacOS/Aerial", RTLD_LAZY);
    
    [super awakeFromNib];
    NSLog(@"awoken");

    [self.window setDelegate:self];
    [self.window.contentView setAutoresizesSubviews:YES];
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
                       self.window.frame.size.width,
                       self.window.frame.size.height)
            isPreview:false];
    
    [self.window setContentView:_ssv];
    
    //[self.window setLevel:NSFullScreenModeWindowLevel];
    /*
    [self.window  setLevel:kCGDesktopWindowLevel - 1];
    [self.window setCollectionBehavior:
                (NSWindowCollectionBehaviorCanJoinAllSpaces |
                 NSWindowCollectionBehaviorStationary |
                 NSWindowCollectionBehaviorIgnoresCycle)];*/
    
    
    //  [self setCollectionBehavior:(NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorIgnoresCycle)];
}

- (void)windowWillClose:(NSNotification *)notification {
    [_ssv stopAnimation];
    NSLog(@"willclose");
}

@end
