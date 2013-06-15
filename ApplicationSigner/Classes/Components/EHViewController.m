//
//  EHViewController.m
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import "EHViewController.h"

@interface EHViewController ()

@end


@implementation EHViewController

- (EHCodeSignWindowController *)navigationController
{
    return self.view.window.windowController;
}

@end
