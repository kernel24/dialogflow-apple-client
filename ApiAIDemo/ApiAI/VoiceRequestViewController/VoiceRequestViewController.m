/**
 * Copyright 2017 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
#import "VoiceRequestViewController.h"
#import "ResultNavigarionController.h"
#import <ApiAI/ApiAI.h>

#import <MBProgressHUD/MBProgressHUD.h>
#import <Speech/Speech.h>

@interface VoiceRequestViewController () <SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate> {
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    AVAudioEngine *audioEngine;
    AVSpeechSynthesizer *synthesizer;
}

@end

@implementation VoiceRequestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    // Set speech recognizer delegate
    speechRecognizer.delegate = self;
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
            NSLog(@"Authorized");
            break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
            NSLog(@"Denied");
            break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
            NSLog(@"Not Determined");
            break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
            NSLog(@"Restricted");
            break;
            default:
            break;
        }
    }];
    
    [self startVoice];
}
    
- (void)startListening {
    // Initialize the AVAudioEngine
    audioEngine = [[AVAudioEngine alloc] init];
    
    // Make sure there's not a recognition task already running
    if (recognitionTask) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }
    
    // Starts an AVAudio Session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord  error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    // Starts a recognition process, in the block it logs the input or stops the audio
    // process if there's an error.
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    recognitionRequest.shouldReportPartialResults = YES;
    __weak VoiceRequestViewController *weakSelf = self;
    __weak AVAudioEngine *weakAVAudioEngine = audioEngine;
    __weak SFSpeechAudioBufferRecognitionRequest *weakRecognitionRequest = recognitionRequest;

    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result) {
            // Whatever you say in the microphone after pressing the button should be being logged
            // in the console.
            NSLog(@"RESULT:%@",result.bestTranscription.formattedString);
            isFinal = !result.isFinal;
        }
        if (error) {
            [weakAVAudioEngine stop];
            [inputNode removeTapOnBus:0];
        }
        
        
        [weakAVAudioEngine stop];
        [weakRecognitionRequest endAudio];
        
        if (!isFinal) {
            NSLog(@"isFinal:%@",result.bestTranscription.formattedString);
            [weakSelf sendRequestWithString:result.bestTranscription.formattedString];
        }
    }];
    
    // Sets the recording format
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [weakRecognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    // Starts the audio engine, i.e. it starts listening.
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"Say Something, I'm listening");
}

- (void) sendRequestWithString:(NSString *) requestString {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    ApiAI *apiai = [ApiAI sharedApiAI];
    
    AITextRequest *request = [apiai textRequest];
    request.query = @[requestString?:@""];
    
    __weak typeof(self) selfWeak = self;
    synthesizer = [[AVSpeechSynthesizer alloc] init];
    synthesizer.delegate = self;
    __weak AVSpeechSynthesizer *weakSynthesizer = synthesizer;
    
    [request setCompletionBlockSuccess:^(AIRequest *request, id response) {
        __strong typeof(selfWeak) selfStrong = selfWeak;
        
//        ResultNavigarionController *resultNavigarionController = [selfStrong.storyboard instantiateViewControllerWithIdentifier:@"ResultNavigarionController"];
//        resultNavigarionController.response = response;
//        
//        [selfStrong presentViewController:resultNavigarionController
//                                 animated:YES
//                               completion:NULL];
        
        NSString *_responseSpeech = [[[response objectForKey:@"result"] objectForKey:@"fulfillment"] objectForKey:@"speech"];
        

        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:_responseSpeech];
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
        [weakSynthesizer speakUtterance:utterance];
        
        [MBProgressHUD hideHUDForView:selfStrong.view animated:YES];
    } failure:^(AIRequest *request, NSError *error) {
        __strong typeof(selfWeak) selfStrong = selfWeak;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        [MBProgressHUD hideHUDForView:selfStrong.view animated:YES];
    }];
    
    [apiai enqueue:request];
}

- (void)startVoice
{
    
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"This function is invalid on Simulator"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
#else
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
    } else {
        [self startListening];
    }
#endif
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"%@", [synthesizer debugDescription]);
    [self startVoice];
}
    
@end
