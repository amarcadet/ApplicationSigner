//
//  ApplicationSignerAppDelegate.m
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 10/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import "ApplicationSignerAppDelegate.h"

#import "EHMainViewController.h"
#import "EHCodeSignWindowController.h"

@interface ApplicationSignerAppDelegate ()

@property (nonatomic, retain)  NSWindowController *windowController;

@end


@implementation ApplicationSignerAppDelegate

- (void)dealloc
{
    [_windowController release];
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{   
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/zip"])
    {
        NSRunAlertPanel(@"Error", 
                        @"This app cannot run without the zip utility present at /usr/bin/zip",
                        @"OK", nil, nil);
        exit(0);
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"])
    {
        NSRunAlertPanel(@"Error", 
                        @"This app cannot run without the unzip utility present at /usr/bin/unzip",
                        @"OK", nil, nil);
        exit(0);
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/codesign"])
    {
        NSRunAlertPanel(@"Error",
                        @"This app cannot run without the codesign utility present at /usr/bin/codesign",
                        @"OK", nil, nil);
        exit(0);
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/security"])
    {
        NSRunAlertPanel(@"Error",
                        @"This app cannot run without the security utility present at /usr/bin/security",
                        @"OK", nil, nil);
        exit(0);
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/xcrun"])
    {
        NSRunAlertPanel(@"Error",
                        @"This app cannot run without the xcrun utility present at /usr/bin/xcrun",
                        @"OK", nil, nil);
        exit(0);
    }
    
    EHMainViewController *mainController = [[[EHMainViewController alloc] init] autorelease];
    self.windowController = [[[EHCodeSignWindowController alloc] initWithRootController:mainController] autorelease];
    [self.windowController showWindow:self];
    [self.windowController.window makeMainWindow];
}


#pragma mark - Actions

- (IBAction)showHelp:(id)sender
{
    NSRunAlertPanel(@"How to use Application Signer",
                    @"Application Signer allows you to re codesign any IPA with any certificate for which you hold the corresponding private key.\n\n1. Drag your signed or unsigned .ipa file and .mobileprovision.\n\n2. Verify that the certificate automatically selected is correct, and click \"Sign application\".\n\n3. Drag the new IPA anywhere to save it.",
                    @"OK", nil, nil);
}

@end
