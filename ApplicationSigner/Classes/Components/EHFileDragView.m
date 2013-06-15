//
//  EHFileDragView.m
//  ApplicationSigner
//
//  Created by Antoine Marcadet on 14/06/13.
//  Copyright (c) 2013 Epershand. All rights reserved.
//

#import "EHFileDragView.h"

@interface EHFileDragView ()
{
    int _delegateHasRefusedFile;
}

@property (nonatomic, retain) NSMutableArray *files;

@end


@implementation EHFileDragView

- (void)dealloc
{
    [_files release];
    
    [self unregisterDraggedTypes];
    
    [super dealloc];
}

- (void)commonInit
{
    self.files = [NSMutableArray array];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        [self commonInit];
    }
    return self;
}


#pragma mark - View

- (void)awakeFromNib
{
    [self registerForDraggedTypes:@[ NSFilenamesPboardType ]];
    
    // avoid imageview handling dragging
    [self.imageView unregisterDraggedTypes];
}


#pragma mark - Dragging

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    DLog();
    
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    if ([[pasteboard types] containsObject:NSURLPboardType])
    {
        NSArray *files = [pasteboard propertyListForType:NSFilenamesPboardType];
        if ([files count] > 0)
        {
            DLog(@"dropping files: %@", files);
            
            if (![self.delegate fileDragView:self shouldAcceptFiles:files])
            {
                _delegateHasRefusedFile = YES;
                DLog(@"file refused by delegate");
                [[NSCursor operationNotAllowedCursor] push];
                return NSDragOperationNone;
            }
            
            _delegateHasRefusedFile = NO;
            
            [self.files removeAllObjects];
            [self.files addObjectsFromArray:files];
            
            if ((NSDragOperationCopy & [sender draggingSourceOperationMask]) == NSDragOperationCopy)
            {
                DLog(@"file accepted");
                return NSDragOperationCopy;
            }
        }
    }
    
    DLog(@"fallback");
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    DLog();
    if (_delegateHasRefusedFile)
    {
        // remove disallowed cursor
        [[NSCursor currentCursor] pop];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    DLog();
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    DLog();
    [self.delegate fileDragView:self didReceiveFiles:[[self.files copy] autorelease]];
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    DLog();
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    DLog();
}

/* the receiver of -wantsPeriodicDraggingUpdates should return NO if it does not require periodic -draggingUpdated messages (eg. not autoscrolling or otherwise dependent on draggingUpdated: sent while mouse is stationary) */
- (BOOL)wantsPeriodicDraggingUpdates
{
    DLog();
    return NO;
}

@end
