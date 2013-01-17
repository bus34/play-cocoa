//
//  PLALogInViewControllerViewController.m
//  Play Item
//
//  Created by Jon Maddox on 4/10/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "PLALogInViewControllerViewController.h"
#import "PLAController.h"
#import "PLAPlayerViewController.h"

@implementation PLALogInViewControllerViewController
@synthesize pagingScrollView, pageControl, urlView, tokenView, welcomeLabel, urlInstructionLabel, tokenInstructionLabel, playUrlTextField, playTokenTextField, urlButton;



- (void)viewDidLoad{
  [super viewDidLoad];
  
  pageControlBeingUsed = NO;
  NSLog(@"font names: %@", [UIFont fontNamesForFamilyName:@"Open Sans"]);

  [welcomeLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:24.0]];
  [urlInstructionLabel setFont:[UIFont fontWithName:@"OpenSans" size:18.0]];
  [tokenInstructionLabel setFont:[UIFont fontWithName:@"OpenSans" size:18.0]];
  
  if ([[PLAController sharedController] playUrl]) {
    [playUrlTextField setText:[[PLAController sharedController] playUrl]];
  }

  if ([[PLAController sharedController] authToken]) {
    [playTokenTextField setText:[[PLAController sharedController] authToken]];
  }
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];

  CGFloat pageWidth = self.view.bounds.size.width;
  
  [pagingScrollView setContentSize:CGSizeMake(pageWidth * 2, 200.0)];
  [pagingScrollView setPagingEnabled:YES];
  
  
  [urlView setFrame:CGRectMake(0, 0, pageWidth, 200.0)];  
  [tokenView setFrame:CGRectMake(pageWidth, 0, pageWidth, 200.0)];
  
  [pagingScrollView addSubview:urlView];
  [pagingScrollView addSubview:tokenView];
  
  [pageControl setNumberOfPages:2];
}

- (void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  
  CGFloat pageWidth = self.view.bounds.size.width;
  NSLog(@"pageWidth: %f", pageWidth);

  [playUrlTextField becomeFirstResponder];
}

- (void)viewDidUnload{
  self.playUrlTextField = nil;
  self.playTokenTextField = nil;
  self.pagingScrollView = nil;
  self.pageControl = nil;
  self.urlView = nil;
  self.tokenView = nil;
  self.urlButton = nil;
  self.welcomeLabel = nil;
  self.urlInstructionLabel = nil;
  self.tokenInstructionLabel = nil;
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
  } else {
    return YES;
  }
}

- (void)logIn{
  [[PLAController sharedController] setPlayUrl:playUrlTextField.text];
  [[PLAController sharedController] setAuthToken:playTokenTextField.text];
    
  [[PLAController sharedController] logInWithBlock:^(BOOL succeeded) {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      if (succeeded) {
        [(PLAPlayerViewController *)self.presentingViewController setUpForStreaming];
        [self dismissModalViewControllerAnimated:YES];
      }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Play cannot be reached or your log in details are incorrect. Try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
      }
    });
  }];
}

- (IBAction)changePage {
  pageControlBeingUsed = YES;
  CGRect frame;
  frame.origin.x = self.pagingScrollView.frame.size.width * self.pageControl.currentPage;
  frame.origin.y = 0;
  frame.size = self.pagingScrollView.frame.size;
  [self.pagingScrollView scrollRectToVisible:frame animated:YES];
}

- (IBAction)goToPlayToken{
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/token?back_to=play-ios://", playUrlTextField.text]]];
}

- (void)setUpTokenView{
  [urlButton setTitle:[NSString stringWithFormat:@"%@ →", playUrlTextField.text] forState:UIControlStateNormal];
  
  pageControl.currentPage = 1;
  [self changePage];

}

- (void)setFirstResponder{
  if (pageControl.currentPage == 0) {
    [playUrlTextField becomeFirstResponder];
  }else if (pageControl.currentPage == 1) {
    [playTokenTextField becomeFirstResponder];
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  pageControlBeingUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  pageControlBeingUsed = NO;

  [self setFirstResponder];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
  [self setFirstResponder];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
  if (!pageControlBeingUsed) {
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.pagingScrollView.frame.size.width;
    int page = floor((self.pagingScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
  }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField{
  if (textField == playUrlTextField) {
    [self setUpTokenView];
  }else{
    [self logIn];
  }
  
  return YES;
}

@end
