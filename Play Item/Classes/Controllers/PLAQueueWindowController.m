//
//  PLAQueueWindowController.m
//  Play Item
//
//  Created by Danny Greg on 11/04/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLAQueueWindowController.h"

#import "PLAItemAppDelegate.h"
#import "PLAController.h"
#import "PLAShadowTextField.h"
#import "PLATrack.h"

#import "AFNetworking.h"

@interface PLAQueueWindowController ()

@property (retain) NSArray *queue;
@property (retain) PLATrack *currentTrack;
@property (nonatomic, readonly) NSOperationQueue *downloadQueue;

- (void)updateQueue;
- (void)downloadTrack:(PLATrack *)track;

@end

@implementation PLAQueueWindowController

@synthesize playButton = _playButton;

@synthesize queue = _queue;
@synthesize currentTrack = _currentTrack;
@synthesize downloadQueue = _downloadQueue;

- (id)init
{	
	self = [super initWithWindowNibName:@"PLAQueueWindow"];
	if (self == nil)
		return nil;
	
	_downloadQueue = [[NSOperationQueue alloc] init];

	return self;
}

- (void)dealloc
{
	[_queue release], _queue = nil;
	[_currentTrack release], _currentTrack = nil;
	[_downloadQueue release], _downloadQueue = nil;
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self.window setOpaque:NO];
	self.window.backgroundColor = [NSColor clearColor];
	[self.window setLevel:NSFloatingWindowLevel];
		
	[self updateQueue];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateQueue) name:PLANowPlayingUpdated object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStarted:) name:PLAItemStartedPlayingNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStopped:) name:PLAItemStoppedPlayingNotificationName object:nil];
}

- (void)updateQueue
{
	[PLATrack currentTrackWithBlock: ^ (PLATrack *track, NSError *err) 
	{
		if (track == nil) {
			NSLog(@"Could not get current track: %@", err);
			return;
		}
		
		self.currentTrack = track;
	}];
	
	[PLATrack currentQueueWithBlock: ^ (NSArray *tracks, NSError *err) 
	{
		if (tracks == nil) {
			NSLog(@"Could not get current queue: %@", err);
			return;
		}
		
		self.queue = tracks;
	 }];
}

#pragma mark -
#pragma mark Actions

- (IBAction)togglePlay:(id)sender
{
	[[NSApp delegate] togglePlayState];
}

NSURL *(^downloadsFolderLocation)() = ^ 
{
	NSArray *downloadFolderPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	if (downloadFolderPaths.count < 1)
		return (NSURL *)nil;
	
	return [NSURL fileURLWithPath:[downloadFolderPaths objectAtIndex:0]];
};

- (void)downloadTrack:(PLATrack *)track
{
	if (track == nil)
		return;
	
	NSURL *downloadsFolder = downloadsFolderLocation();
	if (downloadsFolder == nil) {
		NSBeep();
		return;
	}
	
	NSURL *targetURL = [downloadsFolder URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.m4a", track.name, track.artist]]; //I'm just guessing m4a… there should probably be a smart way to get the format
	NSOutputStream *outStream = [NSOutputStream outputStreamWithURL:targetURL append:NO];
	AFHTTPRequestOperation *downloadOperation = [[[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:track.downloadURL]] autorelease];
	downloadOperation.outputStream = outStream;
	[downloadOperation setCompletionBlockWithSuccess: ^ (AFHTTPRequestOperation *operation, id responseObject) 
	 {
		 //Um… do something? I guess?
	 } failure:^(AFHTTPRequestOperation *operation, NSError *error) 
	 {
		 NSBeep(); // :trollface: we should probably be way better with errors
	 }];
	[self.downloadQueue addOperation:downloadOperation];
}

#pragma mark -
#pragma mark Notification Callbacks

- (void)playbackStarted:(NSNotification *)note
{
	self.playButton.image = [NSImage imageNamed:@"stop-button"];
	self.playButton.alternateImage = [NSImage imageNamed:@"stop-button-down"];
}

- (void)playbackStopped:(NSNotification *)note
{
	self.playButton.image = [NSImage imageNamed:@"play-button"];
	self.playButton.alternateImage = [NSImage imageNamed:@"play-button-down"];
}

@end
