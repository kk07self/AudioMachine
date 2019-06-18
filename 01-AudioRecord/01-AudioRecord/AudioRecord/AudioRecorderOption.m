//
//  AudioRecorderOption.m
//  01-AudioRecord
//
//  Created by tutu on 2019/6/18.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioRecorderOption.h"
#import <AVFoundation/AVFoundation.h>



@implementation AudioRecorderOption

@synthesize bitsPerChannel = _bitsPerChannel;
@synthesize channels = _channels;
@synthesize sampleRate = _sampleRate;
@synthesize audioRecorderSettings = _audioRecorderSettings;
@synthesize formatIDKey = _formatIDKey;

- (instancetype)init {
    if (self = [super init]) {
        _channels = 1;
        _sampleRate = 44100;
        _bitsPerChannel = 16;
        _formatIDKey = kAudioFormatLinearPCM;
    }
    return self;
}

- (NSDictionary *)audioRecorderSettings {
    if (!_audioRecorderSettings) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        //设置录音格式
        [dict setObject:@(_formatIDKey) forKey:AVFormatIDKey];
        //设置录音采样率
        [dict setObject:@(_sampleRate) forKey:AVSampleRateKey];
        //设置通道,这里采用单声道
        [dict setObject:@(_channels) forKey:AVNumberOfChannelsKey];
        //每个采样点位数,分为8、16、24、32
        [dict setObject:@(_bitsPerChannel) forKey:AVLinearPCMBitDepthKey];
        //是否使用浮点数采样
        [dict setObject:@(NO) forKey:AVLinearPCMIsFloatKey];
        //....其他设置等
        _audioRecorderSettings = dict;
    }
    return _audioRecorderSettings;
}

@end
