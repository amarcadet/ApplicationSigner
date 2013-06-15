//
//  NSTask+LaunchSynchronous.h
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 10/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTask (LaunchSynchronous)

- (NSString *)launchSynchronous;

@end
