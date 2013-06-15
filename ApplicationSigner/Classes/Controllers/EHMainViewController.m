//
//  EHMainViewController.m
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import "EHMainViewController.h"
#import "EHFileDragView.h"

#import "EHSignViewController.h"
#import "NSTask+LaunchSynchronous.h"

#define kApplicationPackageExtension    @"ipa"
#define kProvisionningExtension         @"mobileprovision"

@interface EHMainViewController () <EHFileDragViewDelegate>

@property (nonatomic, assign) IBOutlet EHFileDragView *fileView;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, assign) IBOutlet NSTextField *feedbackLabel;

@property (nonatomic, retain) NSString *originalPackagePath;
@property (nonatomic, retain) NSString *originalProvisioningPath;

@property (nonatomic, retain) NSString *operationUUID;

@property (nonatomic, retain) NSString *workingPath;
@property (nonatomic, retain) NSString *workingPackageFilePath;
@property (nonatomic, retain) NSString *workingProvisioningFilePath;
@property (nonatomic, retain) NSString *workingPayloadPath;
@property (nonatomic, retain) NSString *workingApplicationPath;

@end


@implementation EHMainViewController

- (void)dealloc
{
    [_originalPackagePath release];
    [_originalProvisioningPath release];
    
    [_operationUUID release];
    
    [_workingPath release];
    [_workingPackageFilePath release];
    [_workingProvisioningFilePath release];
    [_workingPayloadPath release];
    [_workingApplicationPath release];
    
    [super dealloc];
}

- (id)init
{
    return [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)    
    {
        self.title = @"Step 1: Drop the IPA and Provisioning Profile";
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    [self.feedbackLabel setHidden:YES];
}


#pragma mark - File Drag

- (BOOL)fileDragView:(EHFileDragView *)view shouldAcceptFiles:(NSArray *)files
{
    NSArray *allowedExtensions = @[ kApplicationPackageExtension, kProvisionningExtension ];
    for (NSString *file in files)
    {
        if (![allowedExtensions containsObject:[[[file lastPathComponent] pathExtension] lowercaseString]])
        {
            return NO;
        }
    }
    return YES;
}

- (void)fileDragView:(EHFileDragView *)view didReceiveFiles:(NSArray *)files
{
    for (NSString *file in files)
    {
        NSString *extension = [[[file lastPathComponent] pathExtension] lowercaseString];
        if ([extension isEqualToString:kApplicationPackageExtension])
        {
            self.originalPackagePath = file;
        }
        else if ([extension isEqualToString:kProvisionningExtension])
        {
            self.originalProvisioningPath = file;
        }
    }
    
    if ([self.originalPackagePath length] > 0 && [self.originalProvisioningPath length] > 0)
    {
        // we have both files we can start !
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        self.operationUUID = [(NSString *)string autorelease];
        DLog(@"operationUUID: %@", self.operationUUID);
        
        [self.fileView setHidden:YES];
        [self.progressIndicator startAnimation:self];
        
        [self performSelectorInBackground:@selector(start) withObject:nil];
    }
}


#pragma mark - Feedback

- (void)updateStatusMessage:(NSString *)message
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(updateStatusMessage:) withObject:message waitUntilDone:NO];
        return;
    }
    
    [self.feedbackLabel setHidden:NO];
    [self.feedbackLabel setStringValue:message];
}

- (void)displayErrorMessage:(NSString *)message
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(displayErrorMessage:) withObject:message waitUntilDone:NO];
        return;
    }
    
    NSRunAlertPanel(@"Error", message, @"OK", nil, nil);
    
    [self.progressIndicator stopAnimation:self];
    [self.feedbackLabel setHidden:NO];
    [self.feedbackLabel setStringValue:@"Failed"];
}


#pragma mark - Background task

- (void)start
{
    @autoreleasepool
    {
        self.workingPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"com.epershand.codesign"] stringByAppendingPathComponent:self.operationUUID];
        DLog(@"Setting up working directory in %@", self.workingPath);
        NSError *createDirectoryError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:self.workingPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
        
        // 1/ moving original files
        self.workingPackageFilePath = [self.workingPath stringByAppendingPathComponent:@"application.ipa"];
        DLog(@"workingApplicationFilePath: %@", self.workingPackageFilePath);
        NSError *applicationCopyError = nil;
        [[NSFileManager defaultManager] copyItemAtPath:self.originalPackagePath toPath:self.workingPackageFilePath error:&applicationCopyError];
        
        self.workingProvisioningFilePath = [self.workingPath stringByAppendingPathComponent:@"profile.mobileprovision"];
        DLog(@"workingProvisioningFilePath: %@", self.workingProvisioningFilePath);
        NSError *provisioningCopyError = nil;
        [[NSFileManager defaultManager] copyItemAtPath:self.originalProvisioningPath toPath:self.workingProvisioningFilePath error:&provisioningCopyError];
        
        
        // 2/ unzip the ipa
        [self updateStatusMessage:@"Extracting package"];
        
        NSTask *unzipTask = [[NSTask alloc] init];
        [unzipTask setLaunchPath:@"/usr/bin/unzip"];
        [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", self.workingPackageFilePath, @"-d", self.workingPath, nil]];
        DLog(@"unzip arguments: %@", unzipTask.arguments);
        
        NSString *unzipResult = [unzipTask launchSynchronous];
        [unzipTask release];
        DLog(@"unzip result: %@", unzipResult);
        
        self.workingPayloadPath = [self.workingPath stringByAppendingPathComponent:@"Payload"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.workingPayloadPath])
        {
            [self displayErrorMessage:@"Unzip failed"];
            return;
        }
        
        [self updateStatusMessage:@"Verifying package"];
        
        
        // 3/ look for ".app" package
        self.workingApplicationPath = nil;
        
        // scan contents of Payload to look for ".app" package
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.workingPayloadPath error:nil];
        for (NSString *file in dirContents)
        {
            if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"])
            {
                self.workingApplicationPath = [[self.workingPath stringByAppendingPathComponent:@"Payload"] stringByAppendingPathComponent:file];
                DLog(@"Found app: %@", self.workingApplicationPath);
                break;
            }
        }
        
        
        // 4/ check if we have found the application
        if ([self.workingApplicationPath length] == 0)
        {
            [self displayErrorMessage:@"Application directory not found"];
            return;
        }
        
        [self updateStatusMessage:@"Package extracted"];
        
        [self performSelectorOnMainThread:@selector(next) withObject:nil waitUntilDone:NO];
    }
}

- (void)next
{
    EHSignViewController *signController = [[EHSignViewController alloc] init];
    signController.workingPath = self.workingPath;
    signController.workingPackageFilePath = self.workingPackageFilePath;
    signController.workingProvisioningFilePath = self.workingProvisioningFilePath;
    signController.workingPayloadPath = self.workingPayloadPath;
    signController.workingApplicationPath = self.workingApplicationPath;
    [self.navigationController pushViewController:signController];
    [signController release];
}

@end
