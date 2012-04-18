//
//  PLAItemLogInViewController.h
//  Play Item
//
//  Created by Jon Maddox on 4/11/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PLAItemWindow.h"

@interface PLAItemLogInWindowController : NSWindowController{
  NSTextField *playUrlTextField;
  NSSecureTextField *authTokenTextField;
}

@property (nonatomic, retain) IBOutlet NSTextField *playUrlTextField;
@property (nonatomic, retain) IBOutlet NSSecureTextField *authTokenTextField;

- (id)init;
- (IBAction)logIn:(id)sender;
- (IBAction)getToken:(id)sender;

@end
