//
//  AudioRecordWithAVRecord.m
//  01-AudioRecord
//
//  Created by K K on 2019/6/17.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioSimpleRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioSimpleRecorder()<AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation AudioSimpleRecorder

@synthesize options;
@synthesize delegate;
@synthesize saveAudioFile;
@synthesize filePath;


- (instancetype)initWithOption:(id<AudioRecorderOptions>)options {
    if (self = [super init]) {
        self.options = options;
    }
    return self;
}


#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecorder:complete:)]) {
        [self.delegate audioRecorder:self complete:filePath];
    }
    [self notificateStatus:AudioRecorderStatusCompleted];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecorder:error:)]) {
        [self.delegate audioRecorder:self error:error];
    }
    [self notificateStatus:AudioRecorderStatusError];
}

- (void)notificateStatus:(AudioRecorderStatus)status {
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecorder:statusChanged:)]) {
        [self.delegate audioRecorder:self statusChanged:status];
    }
}


#pragma mark - controll

- (void)preparRecord {
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    [self.recorder prepareToRecord];
    
    [self notificateStatus:AudioRecorderStatusPrepare];
}

- (BOOL)startRecord {
    BOOL start = [self.recorder record];
    
    if (start) {
        [self notificateStatus:AudioRecorderStatusRecording];
    }
    
    return start;
}

- (void)pause {
    [self.recorder pause];
    [self notificateStatus:AudioRecorderStatusPause];
}

- (void)stopRecord {
    [self.recorder stop];
}

- (void)completeRecord {
    [self.recorder stop];
}

- (AVAudioRecorder *)recorder {
    if (_recorder == nil ) {
        if (self.filePath == nil) {
            NSLog(@"需要设置filePath");
            return nil;
        }
        NSError *error;
        _recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:self.filePath] settings:self.options.audioRecorderSettings error:&error];
        _recorder.delegate = self;
        // 监控声波
        _recorder.meteringEnabled = YES;
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return nil;
        }
    }
    return _recorder;
}


- (float)averagePowerForChannel:(int)channel {
    
    //更新测量值
    [self.recorder updateMeters];
    
    //取得第一个通道的音频，注意音频强度范围时-160到0
    float power= [self.recorder averagePowerForChannel:channel];
    CGFloat progress=(1.0/160.0)*(power+160.0);
    
    return progress;
}

@end
