//
//  AudioReader.m
//  01-AudioRecord
//
//  Created by KK on 2019/4/29.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioReader.h"

@interface AudioReader()

/** 音频写入对象 */
@property (nonatomic, strong) AVAssetReader *audioReader;

/** 写入对象管理器 */
@property (nonatomic, strong) AVAssetReaderTrackOutput *audioOutput;

@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation AudioReader

- (instancetype)init {
    if (self = [super init]) {
        self.option = [[AudioReaderOption alloc] init];
    }
    return self;
}

- (void)setFilePath:(NSString *)filePath {
    _filePath = filePath;
    
    [self setupReader];
}

- (void)setupReader {
    _asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:_filePath] options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    _audioReader = [[AVAssetReader alloc] initWithAsset:_asset error:NULL];
    
    NSDictionary *audioS = @{AVFormatIDKey: @(kAudioFormatLinearPCM), // pcm格式
                         AVNumberOfChannelsKey: @(1), // 采样通道
                     AVLinearPCMIsBigEndianKey: @(false), // 音频采用高位优先的记录格式
                         AVLinearPCMIsFloatKey: @(false), // 采样信号是否浮点数
                        AVLinearPCMBitDepthKey: @(16) // 音频的每个样点的位数
                             };
    _audioOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:[_asset tracksWithMediaType:AVMediaTypeAudio].firstObject outputSettings:audioS];
    if ([_audioReader canAddOutput:_audioOutput]) {
        [_audioReader addOutput:_audioOutput];
    }
    _queue = dispatch_queue_create("kk.com", DISPATCH_QUEUE_SERIAL);
}

- (void)startReader {
    if ([_audioReader startReading]) {
        dispatch_async(_queue, ^{
            while (1) {
                CMSampleBufferRef audioBuffer = [self->_audioOutput copyNextSampleBuffer];
                if (audioBuffer == NULL || self->_audioReader.status != AVAssetReaderStatusReading) {
                    break;
                }
                if (self.delegate) {
                    if ([self.delegate respondsToSelector:@selector(audioReader:outputAudioBuffer:)]) {
                        [self.delegate audioReader:self outputAudioBuffer:audioBuffer];
                    }
                }
            }
        });
    }
}

@end


@implementation AudioReaderOption

- (instancetype)init {
    if (self = [super init]) {
        _sampleRate = 44100;
        _bitsPerChannel = 16;
        _channels = 1;
        _audioBitrate = 96000;
    }
    return self;
}

@end
