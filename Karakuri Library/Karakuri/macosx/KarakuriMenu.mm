//
//  KarakuriMenu.mm
//  Karakuri Prototype
//
//  Created by numata on 09/07/17.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "KarakuriMenu.h"
#import "KarakuriController.h"


@interface NSApplication(Boohoo)

- (void)setAppleMenu:(NSMenu *)menu;

@end


@implementation KarakuriMenu

- (id)init {
    self = [super initWithTitle:@"MainMenu"];
    if (self) {
    }
    return self;
}

- (NSMenu *)makeAppleMenu {
    KarakuriController *controller = [KarakuriController sharedController];
    KarakuriGame *game = [controller game];
    NSString *appName = [NSString stringWithCString:game->getTitle().c_str() encoding:NSUTF8StringEncoding];

    NSMenu *appleMenu = [[NSMenu alloc] initWithTitle:@"AppleMenu"];
    
    {
        NSString *titleFormat = @"About %@";
        if (KRLanguage == KRLanguageJapanese) {
            titleFormat = @"%@ について";
        }
        NSString *title = [NSString stringWithFormat:titleFormat, appName];
        NSMenuItem *menuItem = [appleMenu addItemWithTitle:title
                                                    action:@selector(openAboutPanel:)
                                             keyEquivalent:@""];
        [menuItem setTarget:controller];
    }

    [appleMenu addItem:[NSMenuItem separatorItem]];
    
    {
        NSString *titleFormat = @"Hide %@";
        if (KRLanguage == KRLanguageJapanese) {
            titleFormat = @"%@ を隠す";
        }
        NSString *title = [NSString stringWithFormat:titleFormat, appName];
        [appleMenu addItemWithTitle:title action:@selector(hide:) keyEquivalent:@"h"];
    }
    {
        NSString *title = @"Hide Others";
        if (KRLanguage == KRLanguageJapanese) {
            title = @"ほかを隠す";
        }
        NSMenuItem *menuItem = (NSMenuItem *)[appleMenu addItemWithTitle:title action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
        [menuItem setKeyEquivalentModifierMask:(NSAlternateKeyMask|NSCommandKeyMask)];
    }
    {
        NSString *title = @"Show All";
        if (KRLanguage == KRLanguageJapanese) {
            title = @"すべてを表示";
        }
        [appleMenu addItemWithTitle:title action:@selector(unhideAllApplications:) keyEquivalent:@""];
    }
    
    [appleMenu addItem:[NSMenuItem separatorItem]];
    
    {
        NSString *titleFormat = @"Quit %@";
        if (KRLanguage == KRLanguageJapanese) {
            titleFormat = @"%@ を終了";
        }
        NSString *title = [NSString stringWithFormat:titleFormat, appName];
        NSMenuItem *menuItem = [appleMenu addItemWithTitle:title action:@selector(terminate:) keyEquivalent:@"q"];
        [menuItem setTarget:controller];
    }
    
    return appleMenu;
}

- (NSMenu *)makeWindowMenu
{
    NSString *menuTitle = @"Window";
    if (KRLanguage == KRLanguageJapanese) {
        menuTitle = @"ウィンドウ";
    }
    NSMenu *windowMenu = [[[NSMenu alloc] initWithTitle:menuTitle] autorelease];

    KarakuriController *controller = [KarakuriController sharedController];

    {
        NSString *title = @"Minimize";
        if (KRLanguage == KRLanguageJapanese) {
            title = @"しまう";
        }
        NSMenuItem *menuItem = [windowMenu addItemWithTitle:title action:@selector(minimizeWindow:) keyEquivalent:@"m"];
        [menuItem setTarget:controller];
    }
    
    [windowMenu addItem:[NSMenuItem separatorItem]];

#if KR_MACOSX
    {
        NSString *title = @"Full Screen";
        if (KRLanguage == KRLanguageJapanese) {
            title = @"フルスクリーン";
        }
        NSMenuItem *menuItem = [windowMenu addItemWithTitle:title action:@selector(toggleFullScreen:) keyEquivalent:@"f"];
        [menuItem setTarget:controller];
    }

    [windowMenu addItem:[NSMenuItem separatorItem]];
#endif

    return windowMenu;
}

- (void)setupMenuItems
{
    // Set up Apple Menu
    NSMenu *appleMenu = [self makeAppleMenu];
    NSMenuItem *appleMenuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [appleMenuItem setSubmenu:appleMenu];
    [self addItem:appleMenuItem];
    
    // Set up Window Menu
    NSMenu *windowMenu = [self makeWindowMenu];
    NSMenuItem *windowMenuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    [windowMenuItem setSubmenu:windowMenu];
    [self addItem:windowMenuItem];
    
    [NSApp setAppleMenu:appleMenu];
    [NSApp setWindowsMenu:windowMenu];
}

@end
