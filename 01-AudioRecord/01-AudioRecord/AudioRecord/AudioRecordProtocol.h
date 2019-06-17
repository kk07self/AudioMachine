//
//  AudioRecordProtocol.h
//  01-AudioRecord
//
//  Created by K K on 2019/6/17.
//  Copyright © 2019 KK. All rights reserved.
//

#ifndef AudioRecordProtocol_h
#define AudioRecordProtocol_h


@protocol AudioRecordOptions <NSObject>

/** 采样率: 默认44100 */
@property (nonatomic, assign) Float64 sampleRate;

/** 采样深度: 8 16 24 32 默认16 */
@property (nonatomic, assign) uint bitsPerChannel;

/** 声道数 */
@property (nonatomic, assign) uint channels;

@end


#pragma mark - AudioRecordBase
@protocol AudioRecordBase <NSObject>

@property (nonatomic, strong) id<AudioRecordOptions> options;

- (instancetype)initWithOption:(id<AudioRecordOptions>)options;

- (void)preparRecord;

- (BOOL)startRecord;

- (void)stopRecord;

- (void)completeRecord;

@end

//
//@protocol AudioRecordDelegate <NSObject>
//
//- (void)audioRecorder:(id<AudioRecordBase> )recorder outAudioData:(NSData *)data;
//
//@end

#endif /* AudioRecordProtocol_h */
