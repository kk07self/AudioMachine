//
//  AudioRecordWithCaptrue.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/26.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioRecordWithCapture.h"
#import <AVFoundation/AVFoundation.h>

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

/** fileHandle */
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end


@implementation AudioRecordWithCapture

- (instancetype)init {
    if (self = [super init]) {
        
        _defaultOption = [[AudioRecordWithCaptureOption alloc] init];
        _saveAudioFile = YES;
        
        // pcm文件保存
        _filePath = [NSString stringWithFormat:@"%@/capture.pcm",[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0].path];
        if ([NSFileManager.defaultManager fileExistsAtPath:_filePath]) {
            [NSFileManager.defaultManager removeItemAtPath:_filePath error:NULL];
        }
        [NSFileManager.defaultManager createFileAtPath:_filePath contents:nil attributes:nil];
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
        [self setupSession];
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
            if (self.saveAudioFile && self.audioWriter.isReadyForMoreMediaData) {
                BOOL isSu = [self.audioWriter appendSampleBuffer:sampleBuffer];
                NSLog(@"%ld", isSu);
            }
            
            // fileHandle写入pcm
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            Byte buffer[length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
            NSData *data = [NSData dataWithBytes:buffer length:length];
            [self.fileHandle writeData:data];
            
            // 代理回调
            if ([self.delegate respondsToSelector:@selector(audioRecorderWithCapture:outAudioData:)]) {
                // data
                [self.delegate audioRecorderWithCapture:self outAudioData:data];
            }
            if ([self.delegate respondsToSelector:@selector(audioRecorderWithCapture:outAudioBuffer:)]) {
                [self.delegate audioRecorderWithCapture:self outAudioBuffer:sampleBuffer];
            }
        }
    }
}

#pragma play controller
- (void)preparRecord {
    [self.session startRunning];
}

- (void)startRecord {
    if (self.session.isRunning == NO) {
        [self preparRecord];
    }
    [self startAssetWriter];
    self.isRecording = YES;
}

- (void)pauseRecord {
    self.isRecording = NO;
}

- (void)stopRecord {
    self.isRecording = NO;
    [self endAssetWrite];
    [self.session stopRunning];
}

- (void)completeRecord {
    self.isRecording = NO;
    [self endAssetWrite];
    [self.session stopRunning];
}


#pragma 录制控制区域
- (void)setupSession {
    
    [self.session beginConfiguration];
    
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
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
}

- (void)endAssetWrite {
    
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
        _assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:[self newAacFile]] fileType:AVFileTypeMPEG4 error:NULL];
    }
    return _assetWriter;
}

- (AVAssetWriterInput *)audioWriter {
    if (!_audioWriter) {
        AudioChannelLayout acl;
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        NSDictionary *audioSetting = @{AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
//                                       AVEncoderBitDepthHintKey: @(32),
                                       AVSampleRateKey: @(44100.0),
                                       AVNumberOfChannelsKey: @(1),
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


- (NSString *)newAacFile {
    
    NSString *file = [NSString stringWithFormat:@"%@/capture_%ld.aac",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],self.aacFiles.count];
    NSLog(@"%@",file);
    if ([NSFileManager.defaultManager fileExistsAtPath:file]) {
        [NSFileManager.defaultManager removeItemAtPath:file error:NULL];
    }
//    [NSFileManager.defaultManager createFileAtPath:file contents:nil attributes:nil];
    [self.aacFiles addObject:file];
    return file;
}

- (NSMutableArray *)aacFiles {
    if (!_aacFiles) {
        _aacFiles = [NSMutableArray array];
    }
    return _aacFiles;
}

@end



@implementation AudioRecordWithCaptureOption
- (instancetype)init {
    if (self = [super init]) {
        
        _sampleRate = 44100;
        _bitsPerChannel = 16;
    }
    return self;
}
@end
