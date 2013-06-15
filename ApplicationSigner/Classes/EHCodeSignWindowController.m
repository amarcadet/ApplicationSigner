//
//  EHCodeSignWindowController.m
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import "EHCodeSignWindowController.h"
#import "EHMainViewController.h"

@interface EHCodeSignWindowController ()

@property (assign) IBOutlet NSTextField *titleLabel;
@property (assign) IBOutlet NSView *containerView;

@property (nonatomic, retain) EHMainViewController *mainController;
@property (nonatomic, retain) NSMutableArray *viewControllers;
@property (nonatomic, readonly) NSViewController *topController;
@property (nonatomic, readonly) NSViewController *visibleController;

@end


@implementation EHCodeSignWindowController

- (id)initWithRootController:(NSViewController *)controller
{
    self = [self init];
    if (self)
    {
        [self.viewControllers addObject:controller];
    }
    return self;
}

- (id)init
{
    return [self initWithWindowNibName:NSStringFromClass([self class])];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
        self.viewControllers = [NSMutableArray array];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.titleLabel.stringValue = self.topController.title;
    [self.topController.view setFrame:self.containerView.bounds];
    [self.containerView addSubview:self.topController.view];
}


#pragma mark - Properties

- (NSViewController *)topController
{
    if ([self.viewControllers count] > 0)
    {
        return [self.viewControllers objectAtIndex:0];
    }
    return nil;
}

- (NSViewController *)visibleController
{
    if ([self.viewControllers count] > 0)
    {
        return [self.viewControllers lastObject];
    }
    return nil;
}


#pragma mark -

- (void)pushViewController:(NSViewController *)pushedController
{
    NSViewController *visibleController = self.visibleController;
    [self.viewControllers addObject:pushedController];
    
    NSRect frame = self.containerView.bounds;
    frame.origin.x = frame.size.width;
    [pushedController.view setFrame:frame];
    [self.containerView addSubview:pushedController.view];
    NSDictionary *newViewAnimation = @{
                                       NSViewAnimationTargetKey: pushedController.view,
                                       NSViewAnimationStartFrameKey: [NSValue valueWithRect:pushedController.view.frame],
                                       NSViewAnimationEndFrameKey: [NSValue valueWithRect:self.containerView.bounds]
                                       };
    
    NSRect visibleEndFrame = visibleController.view.frame;
    visibleEndFrame.origin.x = -visibleEndFrame.size.width;
    NSDictionary *existingViewAnimation = @{
                                         NSViewAnimationTargetKey: visibleController.view,
                                         NSViewAnimationStartFrameKey: [NSValue valueWithRect:visibleController.view.frame],
                                         NSViewAnimationEndFrameKey: [NSValue valueWithRect:visibleEndFrame]
                                         };
    
    self.titleLabel.stringValue = pushedController.title;
    
    NSViewAnimation *transitionAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[ newViewAnimation, existingViewAnimation ]];
    [transitionAnimation setDuration:.25];
    [transitionAnimation setAnimationCurve:NSAnimationEaseIn];
    [transitionAnimation startAnimation];
    [transitionAnimation release];
}



@end
