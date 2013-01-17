//
//  PLAItemLogInViewController.m
//  Play Item
//
//  Created by Jon Maddox on 4/11/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLAItemLogInWindowController.h"
#import "PLAController.h"
#import "PLAItemAppDelegate.h"

@implementation PLAItemLogInWindowController

- (id)init
{	
	return [super initWithWindowNibName:@"PLAItemLogInWindow"];
}

- (void)awakeFromNib
{
	[self.window setLevel:NSFloatingWindowLevel];
	
	NSString *playURL = [[PLAController sharedController] playUrl]; //A URL which isn't NSURL… quit trolling maddox
    [_playUrlTextField setStringValue:(playURL ?: @"")];
	
	NSString *token = [[PLAController sharedController] authToken];
    [_authTokenTextField setStringValue:(token ?: @"")];
}

- (IBAction)logIn:(id)sender{
  [[PLAController sharedController] logInWithBlock:^(BOOL succeeded) {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      if (succeeded) {
        PLAItemAppDelegate *appDelegate = [NSApp delegate];
		[appDelegate flipWindowToQueue];
        [appDelegate didLogIn];
      }else{
        [(PLAItemWindow *)self.window shake];
      }
    });
  }];
}

- (IBAction)getToken:(id)sender 
{
	if ([self.playUrlTextField.stringValue rangeOfString:@"http://"].location != 0 && [self.playUrlTextField.stringValue rangeOfString:@"https://"].location != 0) {
		NSString *urlString = [NSString stringWithFormat:@"http://%@", self.playUrlTextField.stringValue];
		[[PLAController sharedController] setPlayUrl:urlString];
		self.playUrlTextField.stringValue = urlString; //bindings don't have a chance to update here
	}
		
	NSURL *playURL = [NSURL URLWithString:[[PLAController sharedController] playUrl]];
	if (playURL == nil) {
		NSBeep();
		return;
	}
	
	NSURL *tokenURL = [playURL URLByAppendingPathComponent:@"token"];
	[[NSWorkspace sharedWorkspace] openURL:tokenURL];
}

@end
