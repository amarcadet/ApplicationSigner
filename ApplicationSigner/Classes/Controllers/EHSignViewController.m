//
//  EHSignViewController.m
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import <PNGTools/PNGTools.h>
#import "EHSignViewController.h"
#import "NSTask+LaunchSynchronous.h"

#define kInfoPlistFileName      @"Info.plist"
#define kEntitlementsFilename   @"Entitlements.plist"

@interface EHSignViewController ()

@property (nonatomic, assign) IBOutlet NSImageView *iconView;
@property (nonatomic, assign) IBOutlet NSTextField *applicationName;
@property (nonatomic, assign) IBOutlet NSTextField *applicationVersion;
@property (nonatomic, assign) IBOutlet NSTextField *applicationDate;
@property (nonatomic, assign) IBOutlet NSTextField *applicationIdentifier;
@property (nonatomic, assign) IBOutlet NSPopUpButton *certificateButton;

@property (nonatomic, assign) IBOutlet NSButton *codesignButton;

@property (nonatomic, assign) IBOutlet NSImageView *errorImageView;
@property (nonatomic, assign) IBOutlet NSTextField *errorTextField;

@property (nonatomic, retain) NSString *workingInfoPlistPath;
@property (nonatomic, retain) NSString *exportedPackagePath;

@property (nonatomic, assign) BOOL hasCertificateMatchingError;

@end


@implementation EHSignViewController

- (void)dealloc
{   
    [_operationUUID release];
    
    [_workingPath release];
    [_workingPackageFilePath release];
    [_workingProvisioningFilePath release];
    [_workingPayloadPath release];
    [_workingApplicationPath release];
    
    [_workingInfoPlistPath release];
    [_exportedPackagePath release];
    
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
        self.title = @"Step 2: Choose the certificate to sign the IPA";
        self.hasCertificateMatchingError = NO;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    [self.errorImageView setHidden:YES];
    [self.errorTextField setHidden:YES];
    
    [self.codesignButton setEnabled:NO];
    
    self.workingInfoPlistPath = [self.workingApplicationPath stringByAppendingPathComponent:kInfoPlistFileName];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:self.workingInfoPlistPath];
    DLog(@"infoPlist: %@", infoPlist);
    
    self.applicationName.stringValue = [infoPlist objectForKey:@"CFBundleDisplayName"];
    self.applicationVersion.stringValue = [NSString stringWithFormat:@"Version: %@ (%@)", [infoPlist objectForKey:@"CFBundleShortVersionString"], [infoPlist objectForKey:@"CFBundleVersion"]];
    self.applicationIdentifier.stringValue = [infoPlist objectForKey:@"CFBundleIdentifier"];
    
    NSString *icon = [infoPlist objectForKey:@"CFBundleIconFile"];
    if ([icon length] == 0)
    {
        NSArray *icons = [infoPlist objectForKey:@"CFBundleIconFiles"];
        if ([icons count] > 0)
        {
            icon = [icons objectAtIndex:0];
        }
    }
    
    if ([icon length] > 0)
    {
        NSString *iconPath = [self.workingApplicationPath stringByAppendingPathComponent:icon];
        self.iconView.image = [[[NSImage alloc] initWithContentsOfFile:iconPath] autorelease];
    }
    
    self.exportedPackagePath = [self.workingPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.resigned.ipa", [infoPlist objectForKey:@"CFBundleExecutable"]]];
    
    [self performSelectorInBackground:@selector(refreshCertificates) withObject:nil];
}


#pragma mark - Actions

- (IBAction)codesignApplication:(id)sender
{
    if ([self.certificateButton.selectedItem.title length] == 0)
    {
        
        return;
    }
    
    [self performSelectorInBackground:@selector(codesign) withObject:nil];
}

- (IBAction)certificateChanged:(id)sender
{
    if ([self.certificateButton.selectedItem.title length] == 0 || self.hasCertificateMatchingError)
    {
        [self.codesignButton setEnabled:NO];
    }
    else
    {
        [self.codesignButton setEnabled:YES];
    }
}

- (void)codesign
{
    @autoreleasepool
    {   
        // extract entitlements
        NSTask *entitlementsTask = [[NSTask alloc] init];
        [entitlementsTask setCurrentDirectoryPath:self.workingPath];
        [entitlementsTask setLaunchPath:@"/usr/bin/codesign"];
        [entitlementsTask setArguments:@[ @"-d", @"--entitlements", [NSString stringWithFormat:@":%@", kEntitlementsFilename], self.workingApplicationPath]];
        DLog(@"entitlements arguments: %@", entitlementsTask.arguments);
        
        NSString *entitlementsResult = [entitlementsTask launchSynchronous];
        [entitlementsTask release];
        
        DLog(@"entitlements result: %@", entitlementsResult);
    //    [self updateStatusMessage:@"Entitlements extracted"];
        
        // removing previous provisioning profile
        NSString *provisioningPath = [self.workingApplicationPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:provisioningPath])
        {
            DLog(@"Deleting: %@", provisioningPath);
            [[NSFileManager defaultManager] removeItemAtPath:provisioningPath error:nil];
        }
        
        // installing new provisioning
        NSError *provisioningCopyError = nil;
        [[NSFileManager defaultManager] copyItemAtPath:self.workingProvisioningFilePath toPath:provisioningPath error:&provisioningCopyError];
        
        // removing old code signature
        NSString *codeSignature = [self.workingApplicationPath stringByAppendingPathComponent:@"_CodeSignature"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:codeSignature])
        {
            DLog(@"Deleting: %@", codeSignature);
            [[NSFileManager defaultManager] removeItemAtPath:codeSignature error:nil];
        }
        
        // removing old code resources
        NSString *codeResources = [self.workingApplicationPath stringByAppendingPathComponent:@"CodeResources"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:codeResources])
        {
            DLog(@"Deleting: %@", codeResources);
            [[NSFileManager defaultManager] removeItemAtPath:codeResources error:nil];
        }
        
        // codesigning
        NSTask *codesignTask = [[NSTask alloc] init];
        [codesignTask setLaunchPath:@"/usr/bin/codesign"];
        [codesignTask setCurrentDirectoryPath:self.workingPath];
        [codesignTask setArguments:@[
            @"-fs",
            self.certificateButton.selectedItem.title,
            self.workingApplicationPath,
            @"--entitlements",
            kEntitlementsFilename,
            @"--preserve-metadata=resource-rules,requirements"
        ]];
        DLog(@"codesignTask arguments: %@", codesignTask.arguments);
        
    //    [self updateStatusMessage:@"Start codesigning"];
        
        NSString *codesignResult = [codesignTask launchSynchronous];
        [codesignTask release];
        
        DLog(@"codesign result: %@", codesignResult);
    //    [self updateStatusMessage:@"Codesigning completed"];
        
        // manual zip
        NSTask *zipTask = [[NSTask alloc] init];
        [zipTask setLaunchPath:@"/usr/bin/zip"];
        [zipTask setCurrentDirectoryPath:self.workingPath];
        [zipTask setArguments:[NSArray arrayWithObjects:@"-qry", self.exportedPackagePath, @"Payload", nil]];
        
        NSString *zipResult = [zipTask launchSynchronous];
        [zipTask release];
        
        DLog(@"zip result: %@", zipResult);
    //    [self updateStatusMessage:@"Packaging complete"];
    }
}


#pragma mark - Background

- (void)refreshCertificates
{
    @autoreleasepool
    {   
        NSTask *certTask = [[NSTask alloc] init];
        [certTask setLaunchPath:@"/usr/bin/security"];
        [certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
        
        NSString *certResult = [certTask launchSynchronous];
        [certTask release];
        
        DLog(@"cert result: %@", certResult);
        NSArray *certificates = [certResult componentsSeparatedByString:@"\""];
        
        NSMutableArray *certificateList = [NSMutableArray arrayWithCapacity:20];
        for (int i = 0; i <= [certificates count] - 2; i+=2)
        {
            DLog(@"i:%d", i+1);
            [certificateList addObject:[certificates objectAtIndex:i+1]];
        }
        
        if ([certificateList count] == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.errorImageView setHidden:NO];
                [self.errorTextField setHidden:NO];
                [self.errorTextField setStringValue:@"No certificate found"];
            });
            return;
        }
        
        // installing new provisioning
        NSTask *securityTask = [[NSTask alloc] init];
        [securityTask setCurrentDirectoryPath:self.workingPath];
        [securityTask setLaunchPath:@"/usr/bin/security"];
        [securityTask setArguments:@[ @"cms", @"-D", @"-i", self.workingProvisioningFilePath]];
        
        NSString *securityResults = [securityTask launchSynchronous];
        [securityTask release];
        
        DLog(@"securityResults: %@", securityResults);
        
        NSString *error;
        NSPropertyListFormat format;
        NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:[securityResults dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
        if (!plist)
        {
            DLog(@"Error: %@", error);
            return;
        }
        
        NSData *certificateData = [[plist objectForKey:@"DeveloperCertificates"] objectAtIndex:0];
        SecCertificateRef developerCertificate = SecCertificateCreateWithData(NULL, (CFDataRef)certificateData);
        CFStringRef commonName;
        SecCertificateCopyCommonName(developerCertificate, &commonName);
        
        NSString *certificateName = (NSString *)commonName;
        DLog(@"certificateName: %@", certificateName);
        
        [self performSelectorOnMainThread:@selector(refreshCertificateControl:) withObject:certificateList waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(selectCertificate:) withObject:certificateName waitUntilDone:YES];
    }
}

- (void)refreshCertificateControl:(NSArray *)certificates
{
    [self.certificateButton removeAllItems];
    [self.certificateButton addItemWithTitle:@""];
    [self.certificateButton addItemsWithTitles:certificates];
}

- (void)selectCertificate:(NSString *)certificateName
{
    if ([self.certificateButton itemWithTitle:certificateName])
    {
        [self.codesignButton setEnabled:YES];
        [self.certificateButton selectItemWithTitle:certificateName];
    }
    else
    {
        self.hasCertificateMatchingError = YES;
        [self.codesignButton setEnabled:NO];
        [self.errorImageView setHidden:NO];
        [self.errorTextField setHidden:NO];
        [self.errorTextField setStringValue:@"Valid certificate matching provisioning not found"];
    }
}

@end
