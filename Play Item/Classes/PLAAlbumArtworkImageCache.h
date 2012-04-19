//
//  PLAImageCache.h
//  Play Cocoa
//
//  Created by Danny Greg on 19/04/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PLATrack;

@interface PLAAlbumArtworkImageCache : NSObject

+ (id)sharedCache;

- (void)imageForTrack:(PLATrack *)track withCompletionBlock:(void(^)(NSImage *image, NSError *error))completionBlock; //image is nil in the event of error

@end
