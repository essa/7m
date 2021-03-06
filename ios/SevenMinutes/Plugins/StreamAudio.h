//
//  StreamAudio.h
//  SevenMinutes
//
//  Created by Nakajima Taku on 2013/05/12.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAudioSession.h>

#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVCommandDelegate.h>

enum CDVMediaError {
    MEDIA_ERR_ABORTED = 1,
    MEDIA_ERR_NETWORK = 2,
    MEDIA_ERR_DECODE = 3,
    MEDIA_ERR_NONE_SUPPORTED = 4
};
typedef NSUInteger CDVMediaError;

enum CDVMediaStates {
    MEDIA_NONE = 0,
    MEDIA_STARTING = 1,
    MEDIA_RUNNING = 2,
    MEDIA_PAUSED = 3,
    MEDIA_STOPPED = 4,
    MEDIA_BEGININTERACTION = 5,
    MEDIA_ENDINTERACTION = 6,
    MEDIA_INPUTCHANGED = 7,
    MEDIA_REMOTECONTROL = 8
};
typedef NSUInteger CDVMediaStates;

enum CDVMediaMsg {
    MEDIA_STATE = 1,
    MEDIA_DURATION = 2,
    MEDIA_POSITION = 3,
    MEDIA_COMMAND = 4,
    MEDIA_ERROR = 9
};
typedef NSUInteger CDVMediaMsg;

@interface CDVStreamAudioPlayer : AVPlayer
{
    NSString* mediaId;
}
@property (nonatomic, copy) NSString* mediaId;

@end

@interface CDVStreamAudioFile : NSObject
{
    NSString* resourcePath;
    NSURL* resourceURL;
    CDVStreamAudioPlayer* player;
    NSNumber* volume;
}

@property (nonatomic, strong) NSString* resourcePath;
@property (nonatomic, strong) NSURL* resourceURL;
@property (nonatomic, strong) CDVStreamAudioPlayer* player;
@property (nonatomic, strong) NSString* mediaId;
@property (nonatomic, strong) CDVPlugin* parent;
@property (nonatomic, strong) NSTimer* timer;

- (void)play;
- (void)invalidateTimer;

@end

@interface CDVStreamAudio : CDVPlugin <AVAudioPlayerDelegate, AVAudioRecorderDelegate, AVAudioSessionDelegate>
{
    NSMutableDictionary* soundCache;
    AVAudioSession* avSession;
}

+ (CDVStreamAudio *)current ;

@property (nonatomic, strong) NSMutableDictionary* soundCache;
@property (nonatomic, strong) AVAudioSession* avSession;
@property (nonatomic, strong) NSString* mediaId;

- (void)startPlayingAudio:(CDVInvokedUrlCommand*)command;
- (void)pausePlayingAudio:(CDVInvokedUrlCommand*)command;
- (void)continuePlayingAudio:(CDVInvokedUrlCommand*)command;
- (void)stopPlayingAudio:(CDVInvokedUrlCommand*)command;
- (void)seekToAudio:(CDVInvokedUrlCommand*)command;
- (void)release:(CDVInvokedUrlCommand*)command;
- (void)getCurrentPositionAudio:(CDVInvokedUrlCommand*)command;
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent;

- (BOOL)hasAudioSession;
- (CDVStreamAudioFile*)audioFileForResource:(NSString*)resourcePath withId:(NSString*)mediaId doValidation:(BOOL)bValidate forRecording:(BOOL)bRecord;

// helper methods

@end
