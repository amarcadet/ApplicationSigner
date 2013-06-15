//
//  EHCodeSignWindowController.h
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EHCodeSignWindowController : NSWindowController

- (id)initWithRootController:(NSViewController *)controller;
- (void)pushViewController:(NSViewController *)controller;

@end
