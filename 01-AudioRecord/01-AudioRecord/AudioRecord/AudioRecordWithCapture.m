//
//  AudioRecordWithCaptrue.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/26.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioRecordWithCapture.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioRecorderOption.h"

@interface AudioRecordWithCapture()<AVCaptureAudioDataOutputSampleBufferDelegate>
/** 音频输入设备 */
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

/** 音频数据输出 */
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

/** queue */
@property (nonatomic, strong) dispatch_queue_t queue;

/** 音频写入对象 */
@property (nonatomic, strong) AVAssetWriterInput *audioWriter;

/** 写入对象管理器 */
@property (nonatomic, strong) AVAssetWriter *assetWriter;

/** session */
@property (nonatomic, strong) AVCaptureSession *session;

/** 当前的时间 */
@property (nonatomic, assign) CMTime currentSampleTime;

/** 是否开启了录制 */
@property (nonatomic, assign) BOOL isRecording;


@end



@implementation AudioRecordWithCapture

@synthesize options;
@synthesize delegate;
@synthesize saveAudioFile;
@synthesize filePath;

- (instancetype)initWithOption:(id<AudioRecorderOptions>)options {
    if (self = [super init]) {
        self.options = options;
        self.currentSampleTime = kCMTimeZero;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        AudioRecorderOption *option = [[AudioRecorderOption alloc] init];
        self.options = option;
        self.currentSampleTime = kCMTimeZero;
    }
    return self;
}



/**
 outputData delegate

 @param output audioOutput
 @param sampleBuffer data
 @param connection connection
 */
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    if (output == self.audioOutput) {
        if (self.isRecording) {
            // 写入数据：
            // assetWriter写入aac
            if (self.saveAudioFile && self.audioWriter.isReadyForMoreMediaData && CMSampleBufferDataIsReady(sampleBuffer)) {
                BOOL isSu = [self.audioWriter appendSampleBuffer:sampleBuffer];
                NSLog(@"audioAssetStatus: %ld", (long)self.assetWriter.status);
                NSLog(@"%d", (int)isSu);
            }
            
            
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            Byte buffer[length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
            NSData *data = [NSData dataWithBytes:buffer length:length];
            
            // 代理回调
            if ([self.delegate respondsToSelector:@selector(audioRecorder:outAudioData:)]) {
                // data
                [self.delegate audioRecorder:self outAudioData:data];
            }
            if ([self.delegate respondsToSelector:@selector(audioRecorder:outAudioBuffer:)]) {
                [self.delegate audioRecorder:self outAudioBuffer:sampleBuffer];
            }
        }
    }
}


- (void)notificateStatus:(AudioRecorderStatus)status {
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecorder:statusChanged:)]) {
        [self.delegate audioRecorder:self statusChanged:status];
    }
}



#pragma play controller
- (void)preparRecord {
    [self setupSession];
    [self notificateStatus:AudioRecorderStatusPrepare];
    if (self.session.isRunning == NO) {
        [self.session startRunning];
    }
}

- (BOOL)startRecord {
    if (self.isRecording) {
        return YES;
    }
    
    if (self.session.isRunning == NO) {
        [self.session startRunning];
    }
    
    [self startAssetWriter];
    self.isRecording = self.session.isRunning;
    
    [self notificateStatus:AudioRecorderStatusRecording];
    return self.session.isRunning;
}


- (void)stopRecord {
    self.isRecording = NO;
    [self.session stopRunning];
    [self endAssetWrite];
    [self notificateStatus:AudioRecorderStatusCompleted];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecorder:complete:)]) {
        [self.delegate audioRecorder:self complete:filePath];
    }
}

- (void)completeRecord {
    self.isRecording = NO;
    [self endAssetWrite];
    [self.session stopRunning];
    [self notificateStatus:AudioRecorderStatusCompleted];
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioRecorder:complete:)]) {
        [self.delegate audioRecorder:self complete:filePath];
    }
}

- (void)pause {
    self.isRecording = NO;
    [self notificateStatus:AudioRecorderStatusPause];
}


#pragma 录制控制区域
- (void)setupSession {
    
    [self.session beginConfiguration];
    
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    if ([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    _queue = dispatch_queue_create("com.kk.audioRecordWithCapture", DISPATCH_QUEUE_SERIAL);
    [self.audioOutput setSampleBufferDelegate:self queue:_queue];
    
    [self.session commitConfiguration];
}


- (void)startAssetWriter {
    
    if ([self.assetWriter canAddInput:self.audioWriter]) {
        [self.assetWriter addInput:self.audioWriter];
    }
    [self.assetWriter startWriting];

    [self.assetWriter startSessionAtSourceTime:self.currentSampleTime];
    NSLog(@"audioAssetStatus: %ld", (long)self.assetWriter.status);
}

- (void)endAssetWrite {
    
    if (_audioWriter == nil) {
        return;
    }
    
    [self.assetWriter endSessionAtSourceTime:self.currentSampleTime];
    
    __weak typeof(self) weakSelf = self;
    [self.assetWriter finishWritingWithCompletionHandler:^{
        weakSelf.audioWriter = nil;
        weakSelf.assetWriter = nil;
        NSLog(@"结束录制");
    }];
}



#pragma setter getter
- (AVAssetWriter *)assetWriter {
    if (!_assetWriter) {
        _assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:[self filePath]] fileType:AVFileTypeMPEG4 error:NULL];
    }
    return _assetWriter;
}

- (AVAssetWriterInput *)audioWriter {
    if (!_audioWriter) {
        AudioChannelLayout acl;
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        NSDictionary *audioSetting = @{AVFormatIDKey: [NSNumber numberWithInt:options.formatIDKey],
                                       AVSampleRateKey: @(options.sampleRate),
                                       AVNumberOfChannelsKey: @(options.channels),
                                       AVEncoderBitRateKey: @(64000),
                                       AVChannelLayoutKey: [NSData dataWithBytes:&acl length:sizeof(AudioChannelLayout)]
                                       };
        
        _audioWriter = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioSetting];
        _audioWriter.expectsMediaDataInRealTime = YES;
    }
    return _audioWriter;
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (AVCaptureAudioDataOutput *)audioOutput {
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    }
    return _audioOutput;
}

- (AVCaptureDeviceInput *)audioInput {
    if (!_audioInput) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    }
    return _audioInput;
}

@end


