//
//  EHFileDragView.h
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol EHFileDragViewDelegate;


@interface EHFileDragView : NSView <NSDraggingDestination>

@property (nonatomic, assign) IBOutlet id <EHFileDragViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet NSImageView *imageView;

@end


@protocol EHFileDragViewDelegate <NSObject>

- (BOOL)fileDragView:(EHFileDragView *)view shouldAcceptFiles:(NSArray *)files;
- (void)fileDragView:(EHFileDragView *)view didReceiveFiles:(NSArray *)files;

@end
