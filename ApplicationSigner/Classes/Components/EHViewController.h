//
//  EHViewController.h
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EHCodeSignWindowController.h"

@interface EHViewController : NSViewController

@property (nonatomic, readonly) EHCodeSignWindowController *navigationController;

@end
