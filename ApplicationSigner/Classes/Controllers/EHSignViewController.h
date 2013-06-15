//
//  EHSignViewController.h
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EHViewController.h"

@interface EHSignViewController : EHViewController

@property (nonatomic, retain) NSString *operationUUID;

@property (nonatomic, retain) NSString *workingPath;
@property (nonatomic, retain) NSString *workingPackageFilePath;         // path to .ipa
@property (nonatomic, retain) NSString *workingProvisioningFilePath;    // path to .provisioning
@property (nonatomic, retain) NSString *workingPayloadPath;             // path to Payload
@property (nonatomic, retain) NSString *workingApplicationPath;         // path to .app

@end
