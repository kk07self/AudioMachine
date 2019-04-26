//
//  AudioRecord.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/24.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioRecord.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioRecord() {
    // 音频格式信息配置
    AudioStreamBasicDescription audioFormat;
    // 音频录制单元
    AudioUnit audioUnit;
    // 音频缓冲列表
    AudioBufferList bufferList;
    BOOL isSetupAudioUnit;
}

/** fileHandle */
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation AudioRecord

- (instancetype)init {
    if (self = [super init]) {
        
        _defaultOption = [[AudioRecordOption alloc] init];
        _saveAudioFile = YES;
        _filePath = [NSString stringWithFormat:@"%@/demo.pcm",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
    }
    return self;
}


// Bus 0 is used for the output side, bus 1 is used to get audio input.
#define kOutputBus 0
#define kInputBus 1

- (void)setupAudioUint {
    
    // 配置file
    if (_saveAudioFile) {
        NSLog(@"%@",_filePath);
        if ([NSFileManager.defaultManager fileExistsAtPath:_filePath]) {
            [NSFileManager.defaultManager removeItemAtPath:_filePath error:NULL];
        }
        [NSFileManager.defaultManager createFileAtPath:_filePath contents:nil attributes:nil];
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    }
    
    // 配置session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [audioSession setPreferredSampleRate:_defaultOption.sampleRate error:&error];
    [audioSession setPreferredInputNumberOfChannels:_defaultOption.channels error:&error];
    [audioSession setActive:YES error:&error];
    
    OSStatus status;
    // 描述音频元件
    AudioComponentDescription desc = {0};
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // 创建音频元件
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // 创建audio Unit
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    // 给Audio Unit设置信息
    
    // 0.1 打开IO
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    // 为播放打开 IO
//    status = AudioUnitSetProperty(audioUnit,
//                                  kAudioOutputUnitProperty_EnableIO,
//                                  kAudioUnitScope_Output,
//                                  kOutputBus,
//                                  &flag,
//                                  sizeof(flag));
    // 0.2 音频描述格式
    audioFormat.mSampleRate = _defaultOption.sampleRate; // 采样率
    audioFormat.mFormatID = kAudioFormatLinearPCM; // pcm格式
    audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1; // 声道数
    audioFormat.mBitsPerChannel = _defaultOption.bitsPerChannel; // 16字节
    audioFormat.mBytesPerPacket = (audioFormat.mBitsPerChannel/8) * audioFormat.mChannelsPerFrame;
    audioFormat.mBytesPerFrame = audioFormat.mBytesPerPacket;
    
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    
//    AudioStreamBasicDescription output = audioFormat;
//    output.mChannelsPerFrame = _defaultOption.channels;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    
    
    // 0.3 设置数据采集回调
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallBack;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputBus, &callbackStruct, sizeof(callbackStruct));
    checkStatus(status);
    
    // 0.4 关闭为录制分配的缓冲区 --- 使用我们自己分配的
    flag = 0;
    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, kInputBus, &flag, sizeof(flag));
    checkStatus(status);
    
    // 0.5 初始化
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    isSetupAudioUnit = YES;
}


static OSStatus recordingCallBack(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    AudioRecord *record = (__bridge AudioRecord *)(inRefCon);
    record->bufferList.mNumberBuffers = 1;
    record->bufferList.mBuffers[0].mDataByteSize = sizeof(SInt16)*inNumberFrames; // 数据大小
    record->bufferList.mBuffers[0].mNumberChannels = record.defaultOption.channels; // 频道数
    record->bufferList.mBuffers[0].mData = malloc(sizeof(SInt16)*inNumberFrames);
    
    // 获得录制的采样数据
    OSStatus status;
    status = AudioUnitRender(record->audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &record->bufferList);
    checkStatus(status);
    
    // 处理在bufferList中的数据
    NSData *data = [NSData dataWithBytes:record->bufferList.mBuffers[0].mData length:record->bufferList.mBuffers[0].mDataByteSize];
    
    if (record.saveAudioFile) {
        [record.fileHandle writeData:data];
    }
    
    if (record.delegate && [record.delegate respondsToSelector:@selector(audioRecorder:outAudioData:)]) {
        [record.delegate audioRecorder:record outAudioData:data];
    }
    
    return noErr;
}


- (void)preparRecord {
    if (isSetupAudioUnit == NO) {
        [self setupAudioUint];
    }
}

- (BOOL)startRecord {
    [self preparRecord];
    OSStatus status = AudioOutputUnitStart(audioUnit);
    return status == noErr;
}

- (void)pauseRecord {
    if (isSetupAudioUnit) {
        AudioOutputUnitStop(audioUnit);
    }
}

- (void)cancelRecord {
    if (isSetupAudioUnit) {
        AudioOutputUnitStop(audioUnit);
        AudioComponentInstanceDispose(audioUnit);
        AudioUnitUninitialize(audioUnit);
    }
}

- (void)stopRecord {
    if (isSetupAudioUnit) {
        AudioOutputUnitStop(audioUnit);
    }
}

- (void)completeRecord {
    if (isSetupAudioUnit) {
        AudioOutputUnitStop(audioUnit);
        AudioComponentInstanceDispose(audioUnit);
        AudioUnitUninitialize(audioUnit);
    }
}


void checkStatus(OSStatus status) {
    if (status != 0) {
        printf("Error: %d\n", (int)status);
    }
}

@end


@implementation AudioRecordOption
- (instancetype)init {
    if (self = [super init]) {
        
        _sampleRate = 44100;
        _bitsPerChannel = 16;
        _channels = 1;
    }
    return self;
}
@end
