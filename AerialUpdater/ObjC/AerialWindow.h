//
//  AerialWindow.h
//  Aerial
//
//  Created by Guillaume Louel on 29/08/2020.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AerialWindow : NSWindowController <NSWindowDelegate>
- (void)awakeFromNib;
- (void)windowWillClose:(NSNotification *)notification;
@end

NS_ASSUME_NONNULL_END
