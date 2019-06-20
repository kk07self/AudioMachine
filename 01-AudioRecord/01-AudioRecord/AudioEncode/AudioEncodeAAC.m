//
//  AudioEncodeAAC.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/25.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioEncodeAAC.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioEncodeAAC () {
    AudioConverterRef converter;
    AudioBufferList inputBufferList;
    // 未进行解码的
    char *leftBuffer;
}

/** fileHandle */
@property (nonatomic, strong) NSFileHandle *fileHandle;

/** bufferLength: 每次转码的长度 */
@property (nonatomic, assign) NSUInteger bufferLength;

/** leftLength: 未转码的长度 */
@property (nonatomic, assign) NSUInteger leftLength;

@end


@implementation AudioEncodeAAC

- (instancetype)init {
    if (self = [super init]) {
        _options = [[AudioEncodeAACOption alloc] init];
        _isSaveToFile = YES;
        leftBuffer = malloc(1024*2*2); // 即使频道数是2个也够用
    }
    return self;
}


/**
 初始化解码器
 */
- (BOOL)setupConverter {
    if (converter) {
        return YES;
    }
    
    // 音频流输入参数配置
    AudioStreamBasicDescription inputFormat = {0};
    inputFormat.mSampleRate = _options.sampleRate;
    inputFormat.mFormatID = kAudioFormatLinearPCM;
    inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger;
    inputFormat.mChannelsPerFrame = _options.channels;
    inputFormat.mFramesPerPacket = 1;
    inputFormat.mBitsPerChannel = _options.bitsPerChannel;
    inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
    inputFormat.mBytesPerPacket = inputFormat.mBytesPerFrame * inputFormat.mFramesPerPacket;
    
    // 音频流输出参数配置
    AudioStreamBasicDescription outputFormat;
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate = inputFormat.mSampleRate;       // 采样率保持一致
    outputFormat.mFormatID = kAudioFormatMPEG4AAC;            // AAC编码 kAudioFormatMPEG4AAC kAudioFormatMPEG4AAC_HE_V2
    outputFormat.mFormatFlags = kMPEG4Object_AAC_LC;
    outputFormat.mChannelsPerFrame = _options.channels;
    outputFormat.mFramesPerPacket = 1024;                     // AAC一帧是1024个字节
    
    
    // 属性配置
    const OSType subtype = kAudioFormatMPEG4AAC;
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer // 软解码
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer // 硬解码
        }
    };
    
    // 创建编码器
    OSStatus result = AudioConverterNewSpecific(&inputFormat, &outputFormat, 2, requestedCodecs, &converter);;
    UInt32 outputBitrate = _options.audioBitrate;
    UInt32 propSize = sizeof(outputBitrate);
    
    // 设置码率
    if(result == noErr) {
        result = AudioConverterSetProperty(converter, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }
    return result == noErr;
}

/**
 音频转码回调：需要给ioData 填充好数据
 
 @param inAudioConverter 音频变流器
 @param ioNumberDataPackets 数据包数量
 @param ioData ioData 数据
 @param outDataPacketDescription 音频流输出数据包
 @param inUserData 编码函数中传的第三个参数
 @return 状态码
 */
OSStatus inputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    
    // 填充数据
    AudioBufferList *audioBufferList = (AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = audioBufferList->mBuffers[0].mNumberChannels;
    ioData->mBuffers[0].mDataByteSize = audioBufferList->mBuffers[0].mDataByteSize;
    ioData->mBuffers[0].mData = audioBufferList->mBuffers[0].mData;
    
    return noErr;
}


/**
 编码数据

 @param audioPCMData 要编码的数据
 */
- (void)encodeData:(NSData *)audioPCMData {
    
    // 创建编码器
    if (![self setupConverter]) {
        return;
    }
    
    NSUInteger currentLength = audioPCMData.length;
    char *currentData = (char *)[audioPCMData bytes];
    if (self.leftLength+currentLength >= self.bufferLength) {
        // 解码
        NSInteger totalSize = self.leftLength + currentLength;
        NSInteger encodeCount = totalSize/self.bufferLength; // 需要解码多少次
        
        char *totalBuf = malloc(totalSize);
        char *p = totalBuf; // p指向数据的起始点
        
        memset(totalBuf, 0, (int)totalSize);
        
        // 将数据全拷贝到totalBuf
        memcpy(totalBuf, leftBuffer, self.leftLength);
        memcpy(totalBuf + self.leftLength, currentData, currentLength);
        
        for(NSInteger index = 0; index < encodeCount; index++){
            [self encodeBuffeLengthData:p];
            p += self.bufferLength; // 数据指向已编码的后面
        }
        
        // 重新设置未编码数据
        self.leftLength = totalSize % self.bufferLength;
        memset(leftBuffer, 0, self.bufferLength);
        // 将未解码的数据拷贝到为解码区
        memcpy(leftBuffer, totalBuf + (totalSize - self.leftLength), self.leftLength);
        
        free(totalBuf);
    } else {
        // 放到带解码区
        memcmp(leftBuffer+self.leftLength, currentData, currentLength);
        self.leftLength += currentLength;
    }
    
}

- (void)encodeBuffeLengthData:(char *)buf {
    
    // 音频解码前的输入流
    AudioBufferList inputBuffers;
    inputBuffers.mNumberBuffers = _options.channels;
    inputBuffers.mBuffers[0].mNumberChannels = _options.channels;
    inputBuffers.mBuffers[0].mDataByteSize = (UInt32)(self.bufferLength);
    inputBuffers.mBuffers[0].mData = buf;
    
    // 这里将输入流放入self对象中，因为在转码回调函数中需要额外的参数支持
    // 放到self中，把self传递过去就可以使用self中的多个参数
    // 如果只把inputBuffers作为解码参数传递过去，那么参数个数有限
    self->inputBufferList = inputBuffers;
    
    // 音频解码后的输出流
    AudioBufferList outBufferList;
    char *aacBuf = malloc(self.bufferLength);
    
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = _options.channels;
    outBufferList.mBuffers[0].mDataByteSize = (UInt32)(self.bufferLength);   // 设置缓冲区大小
    outBufferList.mBuffers[0].mData = aacBuf;           // 设置AAC缓冲区
    UInt32 outputDataPacketSize = 1;
    
    // 进行转码：
    // 第一个参数转码器
    // 第二个参数回调函数
    // 第三个参数对应回调函数中的最后一个参数---inUserData
    // 第四个参数解码后的输出流
    // 第五个NULL
    if (AudioConverterFillComplexBuffer(converter, inputDataProc, &inputBuffers, &outputDataPacketSize, &outBufferList, NULL) != noErr) {
        return;
    }
    
    NSData* data = [NSData dataWithBytes:aacBuf length:outBufferList.mBuffers[0].mDataByteSize];
    NSData *adts = [self adtsData:_options.channels rawDataLength:data.length];
    NSMutableData *fullData = [NSMutableData data];
    [fullData appendData:adts];
    [fullData appendData:data];
//    free(aacBuf);
    // 处理输出的数据
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioEncoder:progressWithAACData:)]) {
        [self.delegate audioEncoder:self progressWithAACData:fullData];
    }
    
    if (_isSaveToFile) {
        [self.fileHandle writeData:fullData];
    }
}


/**
 adts数据------aac header
 
 @param channel 声道
 @param rawDataLength 包长度
 @return adts 数据（aac header）
 */
- (NSData *)adtsData:(NSInteger)channel rawDataLength:(NSInteger)rawDataLength {
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    NSInteger freqIdx = _options.sampleRate;  //44.1KHz
    int chanCfg = (int)channel;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + rawDataLength;
    // fill in ADTS data
    packet[0] = (char)0xFF;     // 11111111     = syncword
    packet[1] = (char)0xF9;     // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}


/**
 懒加载文件操作器

 @return 文件操作器
 */
- (NSFileHandle *)fileHandle {
    if (!_fileHandle) {
        NSLog(@"%@",_filePath);
        if ([NSFileManager.defaultManager fileExistsAtPath:_filePath]) {
            [NSFileManager.defaultManager removeItemAtPath:_filePath error:NULL];
        }
        [NSFileManager.defaultManager createFileAtPath:_filePath contents:nil attributes:nil];
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    }
    return _fileHandle;
}

- (NSUInteger)bufferLength {
    return 1024*2*_options.channels;
}

@end


@implementation AudioEncodeAACOption

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
