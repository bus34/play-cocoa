//
//  PLAItemAppDelegate.m
//  Play
//
//  Created by Jon Maddox on 2/9/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLAItemAppDelegate.h"

#import "AudioStreamer.h"

#import "LIFlipEffect.h"
#import "PLAController.h"
#import "PLAPlayClient.h"
#import "PLAItemLogInWindowController.h"
#import "PLAQueueWindowController.h"
#import "PLATrack.h"
#import "SPMediaKeyTap.h"

NSString *const PLAItemStartedPlayingNotificationName = @"PLAItemStartedPlayingNotificationName";
NSString *const PLAItemStoppedPlayingNotificationName = @"PLAItemStoppedPlayingNotificationName";

@interface PLAItemAppDelegate ()

@property (nonatomic, retain) SPMediaKeyTap *keyTap;
@property (nonatomic, retain) AudioStreamer *streamer;

@end

@implementation PLAItemAppDelegate

@synthesize statusItem = _statusItem;
@synthesize logInWindowController = _logInWindowController;
@synthesize streamer = _streamer;

@synthesize keyTap = _keyTap;
@synthesize queueWindowController = _queueWindowController;

- (id)init
{	
	self = [super init];
	if (self == nil)
		return nil;
	
	_queueWindowController = [[PLAQueueWindowController alloc] init];
	_logInWindowController = [[PLAItemLogInWindowController alloc] init];

	return self;
}

- (void)dealloc{
  [self destroyStreamer];
  [_statusItem release];

	[_logInWindowController release];
  [_keyTap release], _keyTap = nil;
	[_queueWindowController release], _queueWindowController = nil;
  [super dealloc];
}

-(void)awakeFromNib{
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [self.statusItem setAction:@selector(toggleWindow:)];
  [self.statusItem setImage:[NSImage imageNamed:@"status-icon-off.png"]];
  [self.statusItem setAlternateImage:[NSImage imageNamed:@"status-icon-inverted.png"]];
  [self.statusItem setHighlightMode:YES];  
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
  
  [[PLAController sharedController] logInWithBlock:^(BOOL succeeded) {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      if (succeeded) {
        [self didLogIn];
      }else{
		  [self.queueWindowController showWindow:self]; //Make sure the flip animation happens in the right place
        [self flipWindow:nil];
      }
    
    });
  }];
  
    self.keyTap = [[[SPMediaKeyTap alloc] initWithDelegate:self] autorelease];
    [self.keyTap startWatchingMediaKeys];
}

- (void)didLogIn{
  [PLATrack currentTrackWithBlock:^(PLATrack *track, NSError *err) {
    [[PLAController sharedController] setCurrentlyPlayingTrack:track];
  }];
}

- (IBAction)toggleWindow:(id)sender
{
	if (self.queueWindowController.window.isVisible) {
		[self.queueWindowController close];
	} else {
		NSWindow *statusItemWindow = [[NSApp currentEvent] window]; //Bit of a cheat, but we know here that the last click was in the status item (remember that all menu items are rendered as windows)
		NSRect statusItemScreenRect = [statusItemWindow frame]; 
		CGFloat midX = NSMidX(statusItemScreenRect);
		CGFloat windowWidth = NSWidth(self.queueWindowController.window.frame);
		CGFloat windowHeight = NSHeight(self.queueWindowController.window.frame);
		NSRect windowFrame = NSMakeRect(floor(midX - (windowWidth / 2.0)), floor(NSMaxY(statusItemScreenRect) - windowHeight - [[NSApp mainMenu] menuBarHeight]), windowWidth, windowHeight);
		
		//Check we aren't going to go off screen
		CGFloat screenMaxX = NSMaxX([[statusItemWindow screen] frame]);
		if (NSMaxX(windowFrame) > screenMaxX) {
			windowFrame.origin.x = floor(screenMaxX - windowWidth);
		}
		
		[self.queueWindowController.window setFrameOrigin:windowFrame.origin];
		[self.queueWindowController showWindow:sender];
	}
}


#pragma mark - View State Methods

- (IBAction)flipWindow:(id)sender{
	[self.queueWindowController showWindow:sender];
	
	LIFlipEffect *flipEffect = [[LIFlipEffect alloc] initFromWindow:self.queueWindowController.window toWindow:self.logInWindowController.window];
	[flipEffect run];
}

- (IBAction)goToPlay:(id)sender{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[PLAController sharedController] playUrl]]];
}


#pragma mark - Play Methods

- (void)togglePlayState{
  if (self.streamer && [self.streamer isPlaying]) {
		[self destroyStreamer];
  }else{
    [self createStreamer];
    [self.streamer start];
  }
}

- (void)createStreamer{
	if (self.streamer){
		return;
	}
  
  NSString *streamUrl = [[PLAController sharedController] streamUrl];
  
  NSLog(@"opening stream at: %@", streamUrl);
  
	[self destroyStreamer];
  
	self.streamer = [[AudioStreamer alloc] initWithURL:[NSURL URLWithString:streamUrl]];
  
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:ASStatusChangedNotification object:self.streamer];
}

- (void)destroyStreamer{
	if (self.streamer){
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:self.streamer];
		
		[self.streamer stop];
		self.streamer = nil;
	}
}

- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([self.streamer isPlaying]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PLAItemStartedPlayingNotificationName object:self];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:PLAItemStoppedPlayingNotificationName object:self];
	}
}

#pragma mark -
#pragma mark SPMediaKeyTap Delegate

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
{
    if ([event type] != NSSystemDefined || [event subtype] != SPSystemDefinedEventMediaKeys)
        return;
    
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	int keyRepeat = (keyFlags & 0x1);
    
    if (keyState != 1 || keyRepeat > 1 || keyCode != NX_KEYTYPE_PLAY) //Only supporting play/pause for now
        return;
    
    [self togglePlayState];
}

@end
