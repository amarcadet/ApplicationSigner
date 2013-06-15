//
//  PNGTools.h
//  PNGTools
//
//  Created by Hjalti Jakobsson on 17.3.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PNGTools : NSObject

+ (BOOL)isPNGCrushed:(NSString*)path;
+ (NSData*)uncrushedPNGDataAtPath:(NSString*)path;

@end
