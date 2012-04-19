//
//  PLTrack.m
//  Play
//
//  Created by Jon Maddox on 2/9/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLATrack.h"

#if !TARGET_OS_IPHONE
#import "PLAAlbumArtworkImageCache.h"
#endif

#import "PLAController.h"
#import "PLAPlayClient.h"

#import "AFNetworking.h"

#if !TARGET_OS_IPHONE
@interface PLATrack ()

@property (nonatomic, retain) NSImage *albumArtwork;

@end
#endif

@implementation PLATrack
@synthesize trackId, name, album, artist, queued, starred;

#if !TARGET_OS_IPHONE
@synthesize albumArtwork = _albumArtwork;
#endif

+ (void)currentTrackWithBlock:(void(^)(PLATrack *track, NSError *error))block{
	[[PLAPlayClient sharedClient] getPath:@"/now_playing" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		PLATrack *track = [[[PLATrack alloc] initWithAttributes:responseObject] autorelease];
		block(track, nil);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		block(nil, error);
	}];  
}

+ (void)currentQueueWithBlock:(void(^)(NSArray *tracks, NSError *error))block
{
	[[PLAPlayClient sharedClient] getPath:@"/queue" parameters:nil 
	success: ^ (AFHTTPRequestOperation *operation, id responseObject) 
	{
		NSArray *songDicts = [responseObject valueForKey:@"songs"];
		NSMutableArray *trackObjects = [NSMutableArray array];
		for (id song in songDicts) {
			PLATrack *track = [[[PLATrack alloc] initWithAttributes:song] autorelease];
			[trackObjects addObject:track];
		}
		
		block(trackObjects, nil);
	} 
	failure: ^ (AFHTTPRequestOperation *operation, NSError *error) 
	{
		block(nil, error);
	}];
}

- (id)initWithAttributes:(NSDictionary *)attributes {
  self = [super init];
  if (!self) {
    return nil;
  }
  
  self.trackId = [attributes valueForKeyPath:@"id"];
  self.name = [attributes valueForKeyPath:@"name"];
  self.album = [attributes valueForKeyPath:@"album"];
  self.artist = [attributes valueForKeyPath:@"artist"];
  queued = [[attributes valueForKeyPath:@"queued"] boolValue];
  starred = [[attributes valueForKeyPath:@"starred"] boolValue];
	
#if !TARGET_OS_IPHONE
	[[PLAAlbumArtworkImageCache sharedCache] imageForTrack:self withCompletionBlock: ^ (NSImage *image, NSError *error) 
	{
		self.albumArtwork = image;
	}];
#endif
  
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	PLATrack *copy = [[PLATrack alloc] init];
	copy.trackId = self.trackId;
	copy.name = self.name;
	copy.album = self.album;
	copy.artist = self.artist;
	copy.queued = self.queued;
	copy.starred = self.starred;
	
#if !TARGET_OS_IPHONE
	copy.albumArtwork = self.albumArtwork;
#endif
	return copy;
}

- (void)dealloc{
	[trackId release];
	[name release];
	[album release];
	[artist release];
	
#if !TARGET_OS_IPHONE
	[_albumArtwork release], _albumArtwork = nil;
#endif
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSURL *)albumArtURL
{
	NSString *urlString = [NSString stringWithFormat:@"%@/images/art/%@.png", [[PLAController sharedController] playUrl], self.trackId];
	return [NSURL URLWithString:urlString];
}

- (NSURL *)downloadURL
{
	NSString *urlString = [NSString stringWithFormat:@"%@/song/%@/download", [[PLAController sharedController] playUrl], self.trackId];
	return [NSURL URLWithString:urlString];
}

- (NSURL *)albumDownloadURL
{
	NSString *urlString = [NSString stringWithFormat:@"%@/artist/%@/album/%@/download", [[PLAController sharedController] playUrl], [self.artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [self.album stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	return [NSURL URLWithString:urlString];
}

#pragma mark -
#pragma mark Operations

- (void)toggleStarredWithCompletionBlock:(void(^)(BOOL success, NSError *err))completionBlock
{
	NSString *method = (self.starred ? @"DELETE" : @"POST");
	NSMutableURLRequest *request = [[PLAPlayClient sharedClient] requestWithMethod:method path:@"/star" parameters:[NSDictionary dictionaryWithObject:self.trackId forKey:@"id"]];
	AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
	[operation setCompletionBlockWithSuccess: ^ (AFHTTPRequestOperation *operation, id responseObject) 
	{
		self.starred = !self.starred;
		if (completionBlock != nil)
			completionBlock(YES, nil);
	} failure: ^ (AFHTTPRequestOperation *operation, NSError *error) 
	{
		if (completionBlock != nil)
			completionBlock(NO, error);
	}];
	[[PLAPlayClient sharedClient] enqueueHTTPRequestOperation:operation];
}

@end
