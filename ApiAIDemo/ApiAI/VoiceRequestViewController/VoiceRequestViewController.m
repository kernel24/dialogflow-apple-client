//
//  VoiceButtonRequestProgrammatically.m
//  ApiAIDemo
//
//  Created by Kuragin Dmitriy on 24/06/15.
//  Copyright (c) 2015 Kuragin Dmitriy. All rights reserved.
//

#import "VoiceRequestViewController.h"
#import "ResultNavigarionController.h"
#import <ApiAI/AIVoiceRequestButton.h>

@implementation VoiceRequestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AIVoiceRequestButton *button = [[AIVoiceRequestButton alloc] init];
    
    __weak typeof(self) selfWeak = self;
    
    [button setSuccessCallback:^(id response) {
        __strong typeof(selfWeak) selfStrong = selfWeak;
        
        ResultNavigarionController *resultNavigarionController = [selfStrong.storyboard instantiateViewControllerWithIdentifier:@"ResultNavigarionController"];
        resultNavigarionController.response = response;
        
        [selfStrong presentViewController:resultNavigarionController
                                 animated:YES
                               completion:NULL];
    }];
    
    [button setFailureCallback:^(NSError *error) {
        if (!([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled)) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
    
    [self.view addSubview:button];
    
    [self.view addConstraint:
    [NSLayoutConstraint constraintWithItem:button
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.view
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.f
                                  constant:0.f]];
    
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:button
                                  attribute:NSLayoutAttributeCenterY
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                  attribute:NSLayoutAttributeCenterY
                                 multiplier:1.f
                                   constant:0.f]];
    
    [self.view setNeedsLayout];
}

@end
