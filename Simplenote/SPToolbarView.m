//
//  CustomToolbar.m
//  Simplenote
//
//  Created by Rainieri Ventura on 1/31/12.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "SPToolbarView.h"
#import "NoteListViewController.h"
#import "TagListViewController.h"
#import "SimplenoteAppDelegate.h"
#import "Note.h"
#import "NoteEditorBottomBar.h"
#import "VSThemeManager.h"
#import "VSTheme+Simplenote.h"
#import "NSColor+Simplenote.h"
#import "NSApplication+Helpers.h"
@import Simperium_OSX;


@implementation SPToolbarView

- (VSTheme *)theme {

    return [[VSThemeManager sharedManager] theme];
}

- (void)awakeFromNib {
    NSButtonCell *addNoteCell = [addButton cell];
    [addNoteCell setHighlightsBy:NSContentsCellMask];
    
    NSButtonCell *shareNoteCell = [self.actionButton cell];
    [shareNoteCell setHighlightsBy:NSContentsCellMask];

    NSButtonCell *sidebarCell = [sidebarButton cell];
    [sidebarCell setHighlightsBy:NSContentsCellMask];
    
    NSButtonCell *restoreCell = [restoreButton cell];
    [restoreCell setHighlightsBy:NSContentsCellMask];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noNoteLoaded:) name:SPNoNoteLoadedNotificationName object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteLoaded:) name:SPNoteLoadedNotificationName object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trashDidLoad:) name:kDidBeginViewingTrash object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidLoad:) name:kTagsDidLoad object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trashDidEmpty:) name:kDidEmptyTrash object:nil];
    
    // Interface builder doesn't like decimal values? Set width to 0.5 here to match borders
    CGRect splitterFrame = splitter.frame;
    splitterFrame.size.width = 0.5f;
    [splitter setFrame:splitterFrame];

    [self applyStyle];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    if (_drawsBackground) {
        [[[[VSThemeManager sharedManager] theme] colorForKey:@"tableViewBackgroundColor"] setFill];
        NSRectFill(dirtyRect);
    }
    

    if (_drawsSeparator) {
        CGContextRef context    = [[NSGraphicsContext currentContext] graphicsPort];
        NSRect separator        = self.bounds;
        separator.size.height   = 1.0f / [[NSScreen mainScreen] backingScaleFactor];
        
        CGContextBeginPath(context);

        [[[[VSThemeManager sharedManager] theme] colorForKey:@"dividerColor"] setFill];
        CGContextFillRect(context, separator);
    }    
}

- (void)enableButtons:(BOOL)enabled {
    [self.actionButton setEnabled:enabled];
    [restoreButton setEnabled:enabled];
    [trashButton setEnabled:enabled];
    [historyButton setEnabled:enabled];
}

- (void)noNoteLoaded:(id)sender {
    [self enableButtons:NO];
}

- (void)noteLoaded:(id)sender {
    [self enableButtons:YES];
}

- (void)configureForTrash:(BOOL)trash {
    [self.actionButton setEnabled:!trash];
    [addButton setEnabled:!trash];
    
    [restoreButton setHidden:!trash];
    [noteEditor setEditable:!trash];
    [noteEditor setSelectable:!trash];
}

- (void)trashDidLoad:(NSNotification *)notification {
    [self configureForTrash:YES];
}

- (void)tagsDidLoad:(NSNotification *)notification {
    [self configureForTrash:NO];
}

- (void)trashDidEmpty:(NSNotification *)notification {
    [restoreButton setEnabled:NO];
}

- (void)moveView:(NSView *)view x:(CGFloat)x y:(CGFloat)y {
    [view setFrame:NSMakeRect(view.frame.origin.x + x, view.frame.origin.y + y, view.frame.size.width, view.frame.size.height)];
    [view setNeedsLayout:YES];
}

- (void)setFullscreen:(BOOL)fullscreen {
    // Account for fullscreen button going away
    //int moveRightX = fullscreen ? 36 : -36;
    //[self moveView:self.actionButton x:moveRightX y:0];

// This was hiding the button, actually!
//     Account for traffic lights going away
//    int moveLeftDistance = fullscreen ? -80 : 80;
//    [self moveView:sidebarButton x:moveLeftDistance y:0];
}

- (void)setSplitPositionLeft:(CGFloat)left right:(CGFloat)right {
    CGFloat distance = right - splitter.frame.origin.x;
    
    if (distance == 0)
        return;
    
    BOOL collapsed = left <= 1;
    CGRect searchFrame = searchBox.frame;
    // TODO: Magic numbers
    searchFrame.origin.x = collapsed ? 62 : 156;
    CGFloat searchFrameAdjustment = collapsed ? 119 : 79;
    searchFrame.size.width = tableViewController.view.frame.size.width - searchFrameAdjustment;
    [searchBox setFrame: searchFrame];
    
    [self moveView:addButton x:distance y:0];
    [self moveView:splitter x:distance y:0];
}

#pragma mark - Theme

- (void)applyStyle {
    [self applySearchBoxStyle];
    [splitter setFillColor:[self.theme colorForKey:@"dividerColor"]];
}

- (void)applySearchBoxStyle {
    [searchBox setFillColor:[self.theme colorForKey:@"tableViewBackgroundColor"]];
}

@end
