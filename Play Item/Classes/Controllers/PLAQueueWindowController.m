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

- (IBAction)downloadCurrentSong:(id)sender
{
	if (self.currentTrack == nil)
		return;
	
	NSArray *downloadFolderPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	if (downloadFolderPaths.count < 1) {
		NSBeep();
		return;
	}
	
	NSURL *targetURL = [[NSURL fileURLWithPath:[downloadFolderPaths objectAtIndex:0]] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.m4a", self.currentTrack.name, self.currentTrack.artist]]; //I'm just guessing m4a… there should probably be a smart way to get the format
	NSOutputStream *outStream = [NSOutputStream outputStreamWithURL:targetURL append:NO];
	AFHTTPRequestOperation *downloadOperation = [[[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:self.currentTrack.downloadURL]] autorelease];
	downloadOperation.outputStream = outStream;
	[self.downloadQueue addOperation:downloadOperation];
}

#pragma mark -
#pragma mark Notification Callbacks

- (void)playbackStarted:(NSNotification *)note
{
	self.playButton.image = [NSImage imageNamed:@"play-button-on"];
	self.playButton.alternateImage = [NSImage imageNamed:@"play-button-on-pushed"];
}

- (void)playbackStopped:(NSNotification *)note
{
	self.playButton.image = [NSImage imageNamed:@"play-button-off"];
	self.playButton.alternateImage = [NSImage imageNamed:@"play-button-off-pushed"];
}

@end
