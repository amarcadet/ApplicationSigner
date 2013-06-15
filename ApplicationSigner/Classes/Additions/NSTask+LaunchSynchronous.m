//
//  NSTask+LaunchSynchronous.m
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 10/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import "NSTask+LaunchSynchronous.h"

@implementation NSTask (LaunchSynchronous)

- (NSString *)launchSynchronous
{
    // io
    [self setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    NSPipe *pipe = [NSPipe pipe];
    [self setStandardOutput: pipe];
    [self setStandardError: pipe];
    NSFileHandle *pipeFile = [pipe fileHandleForReading];
    //launch
    [self launch];
    
    // synchronous output
    return [[[NSString alloc] initWithData:[pipeFile readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
}

@end
