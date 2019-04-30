//
//  AudioPlayer.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/25.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioPlayer.h"

#define kSampleRate 44100

#define kQueueBufferCount (4)
#define kMinSizePerBuffer (70000)
#define kFillBufferSize (960*2*2)


@interface AudioPlayer() {
    AudioQueueBufferRef _audioQueueBuffers[kQueueBufferCount];
    BOOL audioQueueBufferUsed[kQueueBufferCount];             //判断音频缓存是否在使用
}

/** audioQueue */
@property (nonatomic, assign) AudioQueueRef audioQueue;

/** audioQueueBuffers */

/** 频道数 */
@property (nonatomic, assign) NSInteger numOfChannel;

/** 采样率 */
@property (nonatomic, assign) double sampleRate;


/** 音频输出参数 */
@property (nonatomic, assign) AudioStreamBasicDescription audioDescription;

/** queue */
@property (nonatomic, strong) dispatch_queue_t queue;

/** 是否初始化 */
@property (nonatomic, assign) BOOL isSetUpAudio;

@property (assign, nonatomic) FILE *pcmFile;

/** 数据 */
@property (nonatomic, strong) NSMutableData *tempData;

@end

@implementation AudioPlayer

- (instancetype)init {
    if (self = [super init]) {
        self.option = [[AudioPlayerOption alloc] init];
        _queue = dispatch_queue_create("com.kk.tutu.audioPlay", DISPATCH_QUEUE_SERIAL);
        _audioDescription = [self defaultAudioDescriptionWithSampleRate:self.option.sampleRate numOfChannels:self.option.channels];
    }
    return self;
}

- (AudioStreamBasicDescription)defaultAudioDescriptionWithSampleRate:(Float64)sampleRate numOfChannels:(int)channels {
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    asbd.mSampleRate = sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mChannelsPerFrame = (UInt32)channels; //双声道
    asbd.mFramesPerPacket = 1;//每一个packet一侦数据
    asbd.mBitsPerChannel = 16;//每个采样点16bit量化
    asbd.mBytesPerFrame = (asbd.mBitsPerChannel/8) * asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket;
    return asbd;
}

// 初始化audioQueue;
- (void)setupAudioQueue {
    if (!_isSetUpAudio) {
        AudioQueueNewOutput(&_audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &_audioQueue);
        
        // 初始化audioQueue中的缓冲区
        for(int i=0; i<kQueueBufferCount; i++) {
            audioQueueBufferUsed[i] = false;
            int result =  AudioQueueAllocateBuffer(_audioQueue, kMinSizePerBuffer, &_audioQueueBuffers[i]); //创建buffer区，kMinSizePerBuffer为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
            NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d", i, result);
        }
        
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
        [[AVAudioSession sharedInstance] setPreferredSampleRate:self.option.sampleRate error:&error];
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (error) {
            NSLog(@"AVAudioSession Error: %@", error.localizedDescription);
        }
        self.isSetUpAudio = YES;
    }
}

// 填充完成回调
void AudioPlayerAQInputCallback(void *input, AudioQueueRef audioQueue, AudioQueueBufferRef audioQueueBuffer) {
    
    // 将填充完成的buffer空置出来，留下一个使用
    AudioPlayer *player = (__bridge AudioPlayer *)input;
    [player resetBufferState:audioQueue and:audioQueueBuffer];
    if (player.isEnqueueData) {
        return;
    }
    // 通过datasource获取数据
    [player readAndPlayWithAudioQueue:audioQueue queueBuffer:audioQueueBuffer];
}

// 标致闲置的buffer
- (void)resetBufferState:(AudioQueueRef)audioQueueRef and:(AudioQueueBufferRef)audioQueueBufferRef {
    
    for (int i = 0; i < kQueueBufferCount; i++) {
        // 将这个buffer设为未使用
        if (audioQueueBufferRef == _audioQueueBuffers[i]) {
            audioQueueBufferUsed[i] = false;
        }
    }
}

- (void)readAndPlayWithAudioQueue:(AudioQueueRef)audioQueue queueBuffer:(AudioQueueBufferRef)audioQueueBuffe {
    if (self.dataSource) {
        if ([self.dataSource respondsToSelector:@selector(audioPlayer:getBytesWithLength:)]) {
            UInt32 readLength = 0;
            Byte *readInByte = [_dataSource audioPlayer:self getBytesWithLength:&readLength];
            if (readLength > 0 && !!readInByte) {
                audioQueueBuffe->mAudioDataByteSize = readLength;
                memcpy(audioQueueBuffe->mAudioData, readInByte, readLength);
                AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffe, 0, NULL);
            }
        } else if ([self.dataSource respondsToSelector:@selector(audioPlayer:fillWithBuffer:withLength:)]) {
            Byte fillBuffer[kFillBufferSize];
            [self.dataSource audioPlayer:self fillWithBuffer:fillBuffer withLength:kFillBufferSize];
            audioQueueBuffe->mAudioDataByteSize = kFillBufferSize;
            memcpy(audioQueueBuffe->mAudioData, fillBuffer, kFillBufferSize);
            AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffe, 0, NULL);
        }
    } else {
        NSLog(@"error-----no datasource");
    }
}

// 向缓冲区中填充sampleBuffer
- (void)enqueueBufferWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    // 将sampleBuffer转成data
    if (sampleBuffer != nil) {
        AudioBufferList audioBufferList;
        CMBlockBufferRef blockBuffer;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
        NSData *data = [NSData dataWithBytes:(void *)(audioBufferList.mBuffers[0].mData) length:audioBufferList.mBuffers[0].mDataByteSize];
        [self enqueueBufferWithData:data];
        free(blockBuffer);
        blockBuffer = NULL;
    }
    
}

// 向缓冲区中填充数据
- (void)enqueueBufferWithData:(NSData *)data {
    
    if (!self.isSetUpAudio) {
        [self setupAudioQueue];
    }
    self.tempData = [NSMutableData new];
    [self.tempData appendData: data];
    // 得到数据
    NSUInteger len = self.tempData.length;
    Byte *bytes = (Byte*)malloc(len);
    [self.tempData getBytes:bytes length: len];
    
    // 找出闲置的buffer
    int i = 0;
    while (true) {
        if (!self->audioQueueBufferUsed[i]) {
            self->audioQueueBufferUsed[i] = true;
            break;
        }else {
            i++;
            if (i >= kQueueBufferCount) {
                i = 0;
            }
        }
    }
    self->_audioQueueBuffers[i] -> mAudioDataByteSize = (unsigned int)len;
    memcmp(self->_audioQueueBuffers[i] -> mAudioData, bytes, len);
    free(bytes);
    bytes = NULL;
    AudioQueueEnqueueBuffer(self.audioQueue, self->_audioQueueBuffers[i], 0, NULL);
}

- (void)setFilePath:(NSString *)filePath {
    _filePath = filePath;
    _pcmFile = fopen(_filePath.UTF8String, "r");
}


#pragma mark - player
- (void)resetPlayer {
    if (self.isSetUpAudio) {
        AudioQueuePause(_audioQueue);
        AudioQueueStop(_audioQueue, true);
        AudioQueueReset(_audioQueue);
    }
}


- (void)prepareToPlay {
    if (!self.isSetUpAudio) {
        [self setupAudioQueue];
    }
    
    if (!self.isEnqueueData) {
        for(int i=0; i<kQueueBufferCount; i++) {
            [self readAndPlayWithAudioQueue:self.audioQueue queueBuffer:_audioQueueBuffers[i]];
        }
    }
}


- (void)play {
    if (self.isSetUpAudio) {
        AudioQueueStart(_audioQueue, NULL);
    }
}

- (void)pause {
    if (self.isSetUpAudio) {
        AudioQueuePause(_audioQueue);
    }
}

- (void)stop {
    if (self.isSetUpAudio) {
        AudioQueueStop(_audioQueue, true);
    }
}

- (void)changeSpeed:(double)speed {
    _audioDescription.mSampleRate = _sampleRate*speed;
    [self resetPlayer];
    self.isSetUpAudio = NO;
    [self setupAudioQueue];
    [self prepareToPlay];
}

- (double)currentProgress {
    AudioQueueTimelineRef timeLine;
    AudioQueueCreateTimeline(_audioQueue, &timeLine);
    AudioTimeStamp timeStamp;
    AudioQueueGetCurrentTime(_audioQueue, timeLine, &timeStamp, NULL);
    return (double)timeStamp.mSampleTime/_audioDescription.mSampleRate;
}

#pragma mark - dealloc
- (void)dealloc {
    NSLog(@"KKAudioPlayer-----dealloc");
    if (_audioQueue != nil) {
        AudioQueueStop(_audioQueue,true);
        AudioQueueDispose(_audioQueue, true);
    }
    _audioQueue = nil;
}

@end


@implementation AudioPlayerOption

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
