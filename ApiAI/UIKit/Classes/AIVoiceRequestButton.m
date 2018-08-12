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

#import "AIVoiceRequestButton.h"
#import "AIVoiceLevelView.h"
#import "AIVoiceContainerView.h"
#import "AIEllipseView.h"
#import "AIProgressView.h"

#import "ApiAI.h"
#import "AIVoiceRequest.h"

#import <CoreGraphics/CoreGraphics.h>
#import <Speech/Speech.h>

@interface AIVoiceRequestButton()<SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate> {
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    AVAudioEngine *audioEngine;
}

@property(nonatomic, weak) IBOutlet UIButton *button;

@property(nonatomic, weak) IBOutlet AIEllipseView *ellipseView;

@property(nonatomic, weak) IBOutlet AIVoiceLevelView *levelView;
@property(nonatomic, weak) IBOutlet AIVoiceContainerView *containerView;

@property(nonatomic, weak) IBOutlet AIProgressView *progressView;

@property(nonatomic, weak) IBOutlet AIVoiceRequest *request;

@property(nonatomic, strong) UIImage *defaultStateNormalImage;
@property(nonatomic, strong) UIImage *defaultStateHighlightedImage;

@property(nonatomic, strong) UIImage *sendingStateNormalImage;
@property(nonatomic, strong) UIImage *sendingStateHighlightedImage;

@property(nonatomic, assign) BOOL isListening;

@end

@implementation AIVoiceRequestButton

@synthesize color=_color, iconColor=_iconColor;

- (IBAction)clicked:(id)sender
{
    if (self.isProcessing) {
        if (self.isListening) {
        } else {
            [self cancel];
        }
    } else {
        [self start];
    }
}

- (void)restoreStateAnimated
{
    AIEllipseView *ellipseView = _ellipseView;
    AIVoiceLevelView *levelView = _levelView;
    AIProgressView *progressView = _progressView;
    
    [ellipseView setRadius:0.f animated:NO];
    
    [UIView transitionWithView:self.containerView
                      duration:0.2f
                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        [levelView setHidden:YES];
                        [levelView setLevel:0.f];
                        
                        [self setupDefaultButtonImages];
                        [progressView stopAnimating];
                    } completion:^(BOOL finished) {
                        
                    }];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    
    _progressView.color = _color;
    
    [self updateButtonImages];
    [self setupDefaultButtonImages];
}

- (UIColor *)color
{
    if (!_color) {
        _color = [UIColor orangeColor];
        _progressView.color = _color;
    }
    return _color;
}

- (void)setIconColor:(UIColor *)iconColor
{
    _iconColor = iconColor;
    
    [self updateButtonImages];
    [self setupDefaultButtonImages];
}

- (UIColor *)iconColor
{
    if (!_iconColor) {
        _iconColor = [UIColor whiteColor];
    }
    
    return _iconColor;
}

- (UIImage *)imageNamed:(NSString *)imageName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    if (floor(NSFoundationVersionNumber) >= NSFoundationVersionNumber_iOS_8_0) {
        return [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    } else {
        UIImage *image = [UIImage imageNamed:imageName];
        if (!image) {
            NSString *imagePath = [bundle pathForResource:imageName ofType:@"png"];
            
            if (imagePath) {
                image = [UIImage imageWithContentsOfFile:imagePath];
            }
        }
        
        return image;
    }
}

- (void)updateButtonImages
{
    UIImage *originalMicImage = [self imageNamed:@"AIMicrophoneControlImage"];
    
    UIImage *overlayMicIconImage = [self image:originalMicImage withColor:self.iconColor];
    UIImage *overlayMicImage = [self image:originalMicImage withColor:self.color];
    
    self.defaultStateNormalImage = overlayMicIconImage;
    self.defaultStateHighlightedImage = overlayMicImage;
    
    UIImage *originalBoxImage = [self imageNamed:@"AICubeIconImage"];
    
    UIImage *overlayBoxIconImage = [self image:originalBoxImage withColor:self.iconColor];
    UIImage *overlayBoxImage = [self image:originalBoxImage withColor:self.color];
    
    self.sendingStateNormalImage = overlayBoxIconImage;
    self.sendingStateHighlightedImage = overlayBoxImage;
}

- (void)setupDefaultButtonImages
{
    [_button setImage:self.defaultStateNormalImage forState:UIControlStateNormal];
    [_button setImage:self.defaultStateHighlightedImage forState:UIControlStateHighlighted];
}

- (void)setupSendingButtonImages
{
    [_button setImage:self.sendingStateNormalImage forState:UIControlStateNormal];
    [_button setImage:self.sendingStateHighlightedImage forState:UIControlStateHighlighted];
}

- (UIImage *)image:(UIImage *)img withColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(img.size, NO, img.scale);
    
    CGRect bounds = CGRectMake(0.f, 0.f, img.size.width, img.size.height);
    [color set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextClipToMask(context, bounds, [img CGImage]);
    CGContextFillRect(context, bounds);
    
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImg;
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self prepareInterface];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareInterface];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self prepareInterface];
    }
    return self;
}

- (void)prepareInterface
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    NSMutableArray *constraits = [NSMutableArray array];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    UIView *view = [[bundle loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    
    [self addSubview:view];
    
    [constraits addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    [constraits addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    [self addConstraints:constraits];
    
    [self addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:[self(72@900)]"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(self)]];
    
    [self addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:[self(72@900)]"
                                             options:0
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(self)]];
    
    
    
    self.backgroundColor = [UIColor clearColor];
    
    [self updateButtonImages];
    [self setupDefaultButtonImages];
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
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
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (BOOL)isProcessing {
    return self.request && ![self.request isFinished];
}

- (void)start {
    if (!self.isProcessing) {
        self.isListening = YES;
        
        AIEllipseView *ellipseView = _ellipseView;
        AIVoiceLevelView *levelView = _levelView;
        AIProgressView *progressView = _progressView;
        
        progressView.color = self.color;
        ellipseView.color = self.color;
        
        
        [levelView setHidden:NO];
        
        AIVoiceRequest *request = [[ApiAI sharedApiAI] voiceRequest];
        
        if (self.prepareRequest) {
            self.prepareRequest(request);
        }
        
        __weak typeof(self) selfWeak = self;
        
        __block float prevValue = 0.f;
        
        [request setSoundLevelHandleBlock:^(AIRequest *request, float level) {
            float prepared = MIN(level * 2.f, 1.f);
            prepared = MAX(prevValue * 0.96f, prepared);
            
            prevValue = prepared;
            selfWeak.levelView.level = prepared;
        }];
        
        [request setSoundRecordBeginBlock:^(AIRequest *request){
            
        }];
        
        [request setSoundRecordEndBlock:^(AIRequest *request){
            selfWeak.isListening = NO;
            [selfWeak changeButtonStateToSending];
        }];
        
        [request setCompletionBlockSuccess:^(AIRequest *request, id response) {
            [self restoreStateAnimated];
        } failure:^(AIRequest *request, NSError *error) {
            [self restoreStateAnimated];
        }];
        
        self.request = request;
        
        [[ApiAI sharedApiAI] enqueue:request];
        
        [ellipseView setRadius:1.f animated:YES];
        if (audioEngine.isRunning) {
            [audioEngine stop];
            [recognitionRequest endAudio];
        } else {
            [self startListening];
        }
    }
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
    
    __weak typeof(self) selfWeak = self;
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
            ApiAI *apiai = [ApiAI sharedApiAI];
            AITextRequest *request = [apiai textRequest];
            request.query = @[result.bestTranscription.formattedString?:@""];
            [request setCompletionBlockSuccess:^(AIRequest *request, id response) {
                if (selfWeak.successCallback) {
                    selfWeak.successCallback(response);
                    
                    NSString *_responseSpeech = [[[response objectForKey:@"result"] objectForKey:@"fulfillment"] objectForKey:@"speech"];
                    
                    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
                    synthesizer.delegate = self;
                    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:_responseSpeech];
                    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
                    [synthesizer speakUtterance:utterance];
                }
                
                [selfWeak restoreStateAnimated];
            } failure:^(AIRequest *request, NSError *error) {
                if (selfWeak.failureCallback) {
                    selfWeak.failureCallback(error);
                }
                
                [selfWeak restoreStateAnimated];
            }];
            [apiai enqueue:request];
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

- (void)changeButtonStateToSending {
    __weak typeof(self) selfWeak = self;
    
    [UIView transitionWithView:self.containerView
                      duration:0.2f
                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [selfWeak setupSendingButtonImages];
                    } completion:^(BOOL finished) {
                        
                    }];
    [self setupSendingButtonImages];
    [_levelView setHidden:YES];
    [_progressView startAnimating];
}

- (void)cancel {
    if (self.isProcessing) {
        self.isListening = NO;
        [self.request cancel];
    }
}

@end
