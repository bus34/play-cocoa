//
//  PLAController.m
//  Play Item
//
//  Created by Jon Maddox on 4/9/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLAController.h"
#import "PTPusherChannel.h"

#if TARGET_OS_EMBEDDED
#import "Reachability.h"
#endif

@implementation PLAController

@synthesize queuedTracks, currentlyPlayingTrack, pusherClient;

- (void) dealloc{
  [queuedTracks release];
  [currentlyPlayingTrack release];
  [pusherClient release];

  [super dealloc];
}

+ (PLAController *)sharedController {
  static PLAController *_sharedController = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedController = [[self alloc] init];
  });
  
  return _sharedController;
}

- (id)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  
//  NSData *settingsFile = [NSData dataWithContentsOfFile:[self settingsPath]];
//  
//  if ([NSKeyedUnarchiver unarchiveObjectWithData:settingsFile]){
//    self.settingsDict = [NSKeyedUnarchiver unarchiveObjectWithData:settingsFile];
//    if (![settingsDict objectForKey:@"joinedRooms"]) {
//      [settingsDict setObject:[NSMutableArray array] forKey:@"joinedRooms"];
//      [self saveSettings];
//    }
//  }else{
//    self.settingsDict = [NSMutableDictionary dictionary];
//    [settingsDict setObject:[NSMutableArray array] forKey:@"joinedRooms"];
//    [self saveSettings];
//  }
  
  
  // set up pusher stuff
  self.pusherClient = [PTPusher pusherWithKey:@"e9b0032af2f98b47120f" delegate:self encrypted:NO];
  [pusherClient setReconnectAutomatically:YES];
  [pusherClient setReconnectDelay:30];

  PTPusherChannel *channel = [pusherClient subscribeToChannelNamed:@"now_playing_updates"];
  
  [channel bindToEventNamed:@"update_now_playing" target:self action:@selector(channelEventPushed:)];
  
  return self;
}

#pragma mark - State methods

- (void)updateNowPlaying:(NSDictionary *)nowPlayingDict{
  // record current state
  self.currentlyPlayingTrack = [[[PLATrack alloc] initWithAttributes:[nowPlayingDict objectForKey:@"now_playing"]] autorelease];

  NSMutableArray *tracks = [NSMutableArray array];
  for (NSDictionary *trackDict in [nowPlayingDict objectForKey:@"songs"]) {
    PLATrack *track = [[PLATrack alloc] initWithAttributes:trackDict];
    [tracks addObject:track];
    [track release];
  }
  
  self.queuedTracks = [NSArray arrayWithArray:tracks];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"PLANowPlayingUpdated" object:nil];
}

#pragma mark - Channel Even handler

- (void)channelEventPushed:(PTPusherEvent *)channelEvent{
  NSLog(@"name: %@", [channelEvent name]);
  if ([[channelEvent name] isEqualToString:@"update_now_playing"]) {
    [self updateNowPlaying:(NSDictionary *)[channelEvent data]];
  }
}

#pragma mark - PTPusher Delegate Methods

- (void)pusher:(PTPusher *)client connectionDidConnect:(PTPusherConnection *)connection{
  client.reconnectAutomatically = YES;
}

- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel {
  NSLog(@"did subscribe to channel: %@", [channel name]);
}

- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error{
  NSLog(@"failed to subscribe: %@", error.description);
}

- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent{
  NSLog(@"received error event: %@", errorEvent);
}

#if TARGET_OS_EMBEDDED
- (void)pusher:(PTPusher *)client connectionDidDisconnect:(PTPusherConnection *)connection{
  Reachability *reachability = [Reachability reachabilityForInternetConnection];
  
  if ([reachability currentReachabilityStatus] == NotReachable) {
    // there is no point in trying to reconnect at this point
    client.reconnectAutomatically = NO;
    
    // start observing the reachability status to see when we come back online
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:reachability];
    
    [reachability startNotifier];
  }
}

- (void)reachabilityChanged:(NSNotification *)note{
  Reachability *reachability = note.object;
  
  if ([reachability currentReachabilityStatus] != NotReachable) {
    // we seem to have some kind of network reachability, so try again
    [pusherClient connect];
    
    // we can stop observing reachability changes now
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [reachability stopNotifier];
  }
}
#endif




@end
