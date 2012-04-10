//
//  PLAItemAppDelegate.m
//  Play
//
//  Created by Jon Maddox on 2/9/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLAItemAppDelegate.h"
#import "PLAController.h"
#import "PLATrack.h"
#import "PLAPlayClient.h"
//#import "SPMediaKeyTap.h"

@interface PLAItemAppDelegate ()

//@property (nonatomic, retain) SPMediaKeyTap *keyTap;

@end

@implementation PLAItemAppDelegate

@synthesize window = _window;
@synthesize statusItem;
@synthesize statusMenu;

//@synthesize keyTap = _keyTap;

- (void)dealloc{
  [self destroyStreamer];
  [statusItem release];
  [statusMenu release];
//  [_keyTap release], _keyTap = nil;
  [super dealloc];
}

-(void)awakeFromNib{
  self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  [statusItem setMenu:statusMenu];
  [statusItem setAction:@selector(toggleWindow:)];
  [statusItem setImage:[NSImage imageNamed:@"status-icon-off.png"]];
  [statusItem setAlternateImage:[NSImage imageNamed:@"status-icon-inverted.png"]];
  [statusItem setHighlightMode:YES];
  
  [self setPlayActionTitle:@"Play"];
  [[self playActionItem] setTarget:self];
  [[self playActionItem] setAction:@selector(toggelPlayState)];
  [[self playActionItem] setEnabled:YES];

  [[statusMenu itemAtIndex:1] setTarget:self];
  [[statusMenu itemAtIndex:1] setAction:@selector(goToPlay)];

  [self setPlayStatus:@""];

  [_window makeKeyWindow];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
  
  [[PLAController sharedController] setPlayUrl:@"http://localhost:5050"];

  
  // listen for notifications for updated songs from the CFController and pusher
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWithTrackInformation) name:@"PLANowPlayingUpdated" object:nil];
  
  
  
  [PLATrack currentTrackWithBlock:^(PLATrack *track) {
    [[PLAController sharedController] setCurrentlyPlayingTrack:track];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      [self updateWithTrackInformation];
    });
    
  }];

    
//    self.keyTap = [[[SPMediaKeyTap alloc] initWithDelegate:self] autorelease];
//    [self.keyTap startWatchingMediaKeys];

}

- (NSMenuItem *)playStatusItem{
  return [statusMenu itemAtIndex:4];
}

- (NSMenuItem *)playActionItem{
  return [statusMenu itemAtIndex:0];
}

- (void)setPlayStatus:(NSString *)statusString{
  if (statusString && statusString.length > 0) {
    [[self playStatusItem] setHidden:NO];
    [[statusMenu itemAtIndex:3] setHidden:NO];
    [[self playStatusItem] setTitle:statusString];
  }else{
    [[self playStatusItem] setHidden:YES];
    [[statusMenu itemAtIndex:3] setHidden:YES];
  }
}

- (void)setPlayActionTitle:(NSString *)actionTitle{
  [[self playActionItem] setTitle:actionTitle];
}

- (IBAction)toggelPlayState{
  if (streamer && [streamer isPlaying]) {
		[self destroyStreamer];
    [self setPlayActionTitle:@"Play"];
    [statusItem setImage:[NSImage imageNamed:@"status-icon-off.png"]];
  }else{
    
    [[PLAController sharedController] getStreamUrlWithBlock:^(NSString *streamUrl) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self createStreamer:streamUrl];
        [self setPlayStatus:@"Buffering..."];
        [streamer start];
      });
    }];

  }
}

- (IBAction)goToPlay{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://play.githubapp.com"]];
}


#pragma mark - Play Methods

- (void)createStreamer:(NSString *)streamUrl{
	if (streamer){
		return;
	}
  
  NSLog(@"opening stream at: %@", streamUrl);
  
	[self destroyStreamer];
  
  NSURL *url = [NSURL URLWithString:streamUrl];
	streamer = [[AudioStreamer alloc] initWithURL:url];
  
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:ASStatusChangedNotification object:streamer];
}

- (void)destroyStreamer{
	if (streamer){
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:streamer];
		
		[streamer stop];
		[streamer release];
		streamer = nil;
	}
}


#pragma mark - Audio player callbacks

- (void)playbackStateChanged:(NSNotification *)aNotification{
	if ([streamer isWaiting]){
    [self setPlayActionTitle:@"Play"];
    [statusItem setImage:[NSImage imageNamed:@"status-icon-off.png"]];
	}else if ([streamer isPlaying]){
    [self setPlayActionTitle:@"Stop"];
    [statusItem setImage:[NSImage imageNamed:@"status-icon-on.png"]];
    [self updateWithTrackInformation];
	}else if ([streamer isPaused]){
    [self setPlayActionTitle:@"Play"];
    [self setPlayStatus:@""];
    [statusItem setImage:[NSImage imageNamed:@"status-icon-off.png"]];
	}else if ([streamer isIdle]){
    [self setPlayActionTitle:@"Play"];
    [self setPlayStatus:@""];
    [statusItem setImage:[NSImage imageNamed:@"status-icon-off.png"]];
	}
}

- (void)updateWithTrackInformation{
  PLATrack *currentlyPlayingTrack = [[PLAController sharedController] currentlyPlayingTrack];
  
  NSString *playStatusString = [NSString stringWithFormat:@"%@ - %@ - %@", [currentlyPlayingTrack artist], [currentlyPlayingTrack album], [currentlyPlayingTrack name]];
  
  [self setPlayStatus:playStatusString];
}


#pragma mark -
//#pragma mark SPMediaKeyTap Delegate
//
//-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
//{
//    if ([event type] != NSSystemDefined || [event subtype] != SPSystemDefinedEventMediaKeys)
//        return;
//    
//	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
//	int keyFlags = ([event data1] & 0x0000FFFF);
//	int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
//	int keyRepeat = (keyFlags & 0x1);
//    
//    if (keyState != 1 || keyRepeat > 1 || keyCode != NX_KEYTYPE_PLAY) //Only supporting play/pause for now
//        return;
//    
//    [self toggelPlayState];
//}

@end
