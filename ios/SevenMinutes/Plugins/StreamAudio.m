//
//  StreamAudio.m
//  SevenMinutes
//
//  Created by Nakajima Taku on 2013/05/12.
//
//

#import "StreamAudio.h"
#import <Cordova/NSArray+Comparisons.h>
#import <Cordova/CDVJSON.h>

#define DOCUMENTS_SCHEME_PREFIX @"documents://"
#define HTTP_SCHEME_PREFIX @"http://"
#define HTTPS_SCHEME_PREFIX @"https://"
#define RECORDING_WAV @"wav"

@implementation CDVStreamAudio

@synthesize soundCache, avSession;

// returns whether or not audioSession is available - creates it if necessary
- (BOOL)hasAudioSession
{
    BOOL bSession = YES;

    if (!self.avSession) {
        NSError* error = nil;

        self.avSession = [AVAudioSession sharedInstance];
        if (error) {
            // is not fatal if can't get AVAudioSession , just log the error
            NSLog(@"error creating audio session: %@", [[error userInfo] description]);
            self.avSession = nil;
            bSession = NO;
        }
    }
    return bSession;
}


- (NSString*)createMediaErrorWithCode:(CDVMediaError)code message:(NSString*)message
{
    NSMutableDictionary* errorDict = [NSMutableDictionary dictionaryWithCapacity:2];

    [errorDict setObject:[NSNumber numberWithUnsignedInt:code] forKey:@"code"];
    [errorDict setObject:message ? message:@"" forKey:@"message"];
    return [errorDict JSONString];
}

- (void)create:(CDVInvokedUrlCommand*)command
{
    NSString* mediaId = [command.arguments objectAtIndex:0];
    NSString* resourcePath = [command.arguments objectAtIndex:1];
    CDVStreamAudioFile* audioFile = [self audioFileForResource:resourcePath withId:mediaId doValidation:NO forRecording:NO];
    NSLog(@"StreamAudio create %@ %@", audioFile.mediaId, audioFile.resourcePath);

    if (audioFile == nil) {
        NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize Media file with path %@", resourcePath];
        NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova/plugin/Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:MEDIA_ERR_ABORTED message:errorMessage]];
        [self.commandDelegate evalJs:jsString];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)startPlayingAudio:(CDVInvokedUrlCommand*)command
{
    NSLog(@"StreamAudio startPlayingAudio");
    NSString* callbackId = command.callbackId;

#pragma unused(callbackId)
    NSString* mediaId = [command.arguments objectAtIndex:0];
    NSString* resourcePath = [command.arguments objectAtIndex:1];
    NSDictionary* options = [command.arguments objectAtIndex:2 withDefault:nil];

    BOOL bError = NO;

    CDVStreamAudioFile* audioFile = [self audioFileForResource:resourcePath withId:mediaId doValidation:YES forRecording:NO];
    if ((audioFile != nil) && (audioFile.resourceURL != nil)) {
      NSLog(@"StreamAudio startPlayingAudio OK url=%@", audioFile.resourcePath);
      if ([self hasAudioSession]) {
        NSError* __autoreleasing err = nil;
        NSNumber* playAudioWhenScreenIsLocked = [options objectForKey:@"playAudioWhenScreenIsLocked"];
        BOOL bPlayAudioWhenScreenIsLocked = YES;
        if (playAudioWhenScreenIsLocked != nil) {
          bPlayAudioWhenScreenIsLocked = [playAudioWhenScreenIsLocked boolValue];
        }

        NSString* sessionCategory = bPlayAudioWhenScreenIsLocked ? AVAudioSessionCategoryPlayback : AVAudioSessionCategorySoloAmbient;
        [self.avSession setCategory:sessionCategory error:&err];
        if (![self.avSession setActive:YES error:&err]) {
          // other audio with higher priority that does not allow mixing could cause this to fail
          NSLog(@"Unable to play audio: %@", [err localizedFailureReason]);
          bError = YES;
        }
      }
      [audioFile play];
      /*
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(playerItemDidReachEnd:)
                                                   name:AVPlayerItemDidPlayToEndTimeNotification
                                                 object:[player currentItem]];
                                                 */
    } else {
      NSLog(@"StreamAudio startPlayingAudio ERROR");
    }
    return;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {

  NSLog(@"StreamAudio playerItemDidReachEnd");

}

- (void)stopPlayingAudio:(CDVInvokedUrlCommand*)command
{
    NSLog(@"StreamAudio stopPlayingAudio");
    NSString* mediaId = [command.arguments objectAtIndex:0];
    CDVStreamAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    NSString* jsString = nil;

    if ((audioFile != nil) && (audioFile.player != nil)) {
        NSLog(@"Stopped playing audio sample '%@'", audioFile.resourcePath);
        [audioFile.player pause]; // AVPlayer doesn't support stop
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"plugins.StreamAudio.onStatus", mediaId, MEDIA_STATE, MEDIA_STOPPED];
    }  // ignore if no media playing
    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)pausePlayingAudio:(CDVInvokedUrlCommand*)command
{
    NSLog(@"StreamAudio pausePlayingAudio");
    NSString* mediaId = [command.arguments objectAtIndex:0];
    NSString* jsString = nil;
    CDVStreamAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];

    if ((audioFile != nil) && (audioFile.player != nil)) {
        NSLog(@"Paused playing audio sample '%@'", audioFile.resourcePath);
        [audioFile.player pause];
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"plugins.StreamAudio.onStatus", mediaId, MEDIA_STATE, MEDIA_PAUSED];
    }
    // ignore if no media playing

    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)continuePlayingAudio:(CDVInvokedUrlCommand*)command
{
    NSLog(@"StreamAudio continuePlayingAudio");
    NSString* mediaId = [command.arguments objectAtIndex:0];
    NSString* jsString = nil;
    CDVStreamAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];

    if ((audioFile != nil) && (audioFile.player != nil)) {
        NSLog(@"Continue playing audio sample '%@'", audioFile.resourcePath);
        [audioFile.player play];
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"plugins.StreamAudio.onStatus", mediaId, MEDIA_STATE, MEDIA_RUNNING];
    }
    // ignore if no media playing

    if (jsString) {
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)seekToAudio:(CDVInvokedUrlCommand*)command
{
    // args:
    // 0 = Media id
    // 1 = path to resource
    // 2 = seek to location in milliseconds

    NSString* mediaId = [command.arguments objectAtIndex:0];

    CDVStreamAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    double position = [[command.arguments objectAtIndex:1] doubleValue];

    NSLog(@"StreamAudio seekTo %f", position);
    double timescale = 60;
    CMTime time = CMTimeMake(position * timescale, timescale*1000);

    if ((audioFile != nil) && (audioFile.player != nil)) {
      [audioFile.player seekToTime:time];
    }
}

- (void)release:(CDVInvokedUrlCommand*)command
{
    NSLog(@"StreamAudio release");
    NSString* mediaId = [command.arguments objectAtIndex:0];

    if (mediaId != nil) {
        CDVStreamAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
        if (audioFile != nil) {
            if (audioFile.player) {
                [audioFile.player pause];
            }
            if (self.avSession) {
                [self.avSession setActive:NO error:nil];
                self.avSession = nil;
            }
            [[self soundCache] removeObjectForKey:mediaId];
            [audioFile invalidateTimer];
            NSLog(@"Media with id %@ released", mediaId);
        }
    }

}

- (void)getCurrentPositionAudio:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* mediaId = [command.arguments objectAtIndex:0];

#pragma unused(mediaId)
    CDVStreamAudioFile* audioFile = [[self soundCache] objectForKey:mediaId];
    double position = -1;

    if ((audioFile != nil) && (audioFile.player != nil)) {
      CMTime t = audioFile.player.currentTime ;
      if (t.timescale > 0) {
        position = t.value / t.timescale;
      }
      NSLog(@"getCurrentPosition %f %lld %d", position, t.value, t.timescale);
    }
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:position];
    NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);\n%@", @"plugins.StreamAudio.onStatus", mediaId, MEDIA_POSITION, position, [result toSuccessCallbackString:callbackId]];
    [self.commandDelegate evalJs:jsString];
}


// Creates or gets the cached audio file resource object
- (CDVStreamAudioFile*)audioFileForResource:(NSString*)resourcePath withId:(NSString*)mediaId doValidation:(BOOL)bValidate forRecording:(BOOL)bRecord
{
    BOOL bError = NO;
    CDVMediaError errcode = MEDIA_ERR_NONE_SUPPORTED;
    NSString* errMsg = @"";
    NSString* jsString = nil;
    CDVStreamAudioFile* audioFile = nil;
 
    if ([self soundCache] == nil) {
        [self setSoundCache:[NSMutableDictionary dictionaryWithCapacity:1]];
    } else {
        audioFile = [[self soundCache] objectForKey:mediaId];
    }
    if (audioFile == nil) {
        // validate resourcePath and create
        if ((resourcePath == nil) || ![resourcePath isKindOfClass:[NSString class]] || [resourcePath isEqualToString:@""]) {
            bError = YES;
            errcode = MEDIA_ERR_ABORTED;
            errMsg = @"invalid media src argument";
        } else {
            audioFile = [[CDVStreamAudioFile alloc] init];
            audioFile.resourcePath = resourcePath;
            audioFile.resourceURL = [NSURL URLWithString:resourcePath]; 
            audioFile.mediaId = mediaId;
            [[self soundCache] setObject:audioFile forKey:mediaId];
            audioFile.parent = self;
        }
    }

    if (bError) {
        jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%@);", @"cordova.require('cordova/plugin/Media').onStatus", mediaId, MEDIA_ERROR, [self createMediaErrorWithCode:errcode message:errMsg]];
        [self.commandDelegate evalJs:jsString];
    }

    return audioFile;
}


- (void)onMemoryWarning
{
    [[self soundCache] removeAllObjects];
    [self setSoundCache:nil];
    [self setAvSession:nil];

    [super onMemoryWarning];
}

- (void)dealloc
{
    [[self soundCache] removeAllObjects];
    [super dealloc];
}

- (void)onReset
{
    /*
    for (CDVStreamAudioFile* audioFile in [[self soundCache] allValues]) {
        if (audioFile != nil) {
            if (audioFile.player != nil) {
                [audioFile.player stop];
            }
        }
    }
    */

    [[self soundCache] removeAllObjects];
}

@end

@implementation CDVStreamAudioFile

@synthesize resourcePath;
@synthesize resourceURL;
@synthesize player;
- (void)play
{
  NSLog(@"CDVStreamAudioFile play");
  player = [[CDVStreamAudioPlayer alloc]initWithURL:resourceURL];
  [player addObserver:self forKeyPath:@"status" options:0 context:nil];
  self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
      
  [player play];
  NSLog(@"StreamAudio startPlayingAudio played mediaId=%@", self.mediaId);
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerItemDidReachEnd:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:[player currentItem]];
}

-(void)updateProgress:(NSTimer*)timer{
  CMTime t = player.currentTime ;
  double position = -1;
  if (t.timescale > 0) {
    position = t.value / t.timescale;
  }
  // NSLog(@"getCurrentPosition %f %lld %d", position, t.value, t.timescale);
  NSString* jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%.3f);\n", @"plugins.StreamAudio.onStatus", self.mediaId, MEDIA_POSITION, position];
  [self.parent.commandDelegate evalJs:jsString];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if (object == player && [keyPath isEqualToString:@"status"]) {
      CDVMediaStates media_status = 0;
        if (player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
            media_status = MEDIA_STOPPED;
        } else if (player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            media_status = MEDIA_STARTING;
        } else if (player.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
            media_status = MEDIA_NONE;
        }
        NSString *jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"plugins.StreamAudio.onStatus", self.mediaId, MEDIA_STATE, media_status];
        [self.parent.commandDelegate evalJs:jsString];
        NSLog(@"called evalJs '%@'", jsString);
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification 
{
  NSLog(@"Finished playing audio '%@' %@", resourcePath, self.mediaId);

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self invalidateTimer];

  CDVStreamAudio *p = (CDVStreamAudio *) self.parent;
  if (p.avSession) {
        [p.avSession setActive:NO error:nil];
  }

  NSString *jsString = [NSString stringWithFormat:@"%@(\"%@\",%d,%d);", @"plugins.StreamAudio.onStatus", self.mediaId, MEDIA_STATE, MEDIA_STOPPED];
  [self.parent.commandDelegate evalJs:jsString];
  NSLog(@"called evalJs '%@'", jsString);
}

- (void)invalidateTimer
{
  if (self.timer != nil) {
    NSLog(@"invalidateTimer");
    [self.timer invalidate];
    self.timer = nil;
  }
}

@end
@implementation CDVStreamAudioPlayer
@synthesize mediaId;

@end

