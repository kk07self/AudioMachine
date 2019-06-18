//
//  AudioRecordProtocol.h
//  01-AudioRecord
//
//  Created by K K on 2019/6/17.
//  Copyright © 2019 KK. All rights reserved.
//

#ifndef AudioRecordProtocol_h
#define AudioRecordProtocol_h

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, AudioRecorderStatus) {
    AudioRecorderStatusUnknow,
    AudioRecorderStatusPrepare,
    AudioRecorderStatusRecording,
    AudioRecorderStatusPause,
    AudioRecorderStatusCompleted,
    AudioRecorderStatusError
};

@protocol AudioRecorder;

@protocol AudioRecorderDelegate <NSObject>

- (void)audioRecorder:(id<AudioRecorder> )recorder outAudioData:(NSData *)data;

- (void)audioRecorder:(id<AudioRecorder> )recorder outAudioBuffer:(CMSampleBufferRef)buffer;

- (void)audioRecorder:(id<AudioRecorder> )recorder complete:(NSString *)audioFilePath;

- (void)audioRecorder:(id<AudioRecorder> )recorder error:(NSError *)error;

- (void)audioRecorder:(id<AudioRecorder> )recorder statusChanged:(AudioRecorderStatus)status;

@end



@protocol AudioRecorderOptions <NSObject>

/** 采样率: 默认44100 */
@property (nonatomic, assign) Float64 sampleRate;

/** 采样深度: 8 16 24 32 默认16 */
@property (nonatomic, assign) uint bitsPerChannel;

/** 声道数 */
@property (nonatomic, assign) uint channels;

/** 音频格式 */
@property (nonatomic, assign) UInt32 formatIDKey;

/**
 options Dic
 */
@property (nonatomic, strong) NSDictionary *audioRecorderSettings;

@end


#pragma mark - AudioRecordBase

@protocol AudioRecorder <NSObject>

@property (nonatomic, strong) id<AudioRecorderOptions> options;


@property (nonatomic, weak) id<AudioRecorderDelegate> delegate;

/** 是否保存到本地：默认YES */
@property (nonatomic, assign) BOOL saveAudioFile;

/** 保存的路径 */
@property (nonatomic, strong) NSString *filePath;


- (instancetype)initWithOption:(id<AudioRecorderOptions>)options;

- (void)preparRecord;

- (BOOL)startRecord;

- (void)pause;

- (void)stopRecord;

- (void)completeRecord;

@end

#endif /* AudioRecordProtocol_h */
