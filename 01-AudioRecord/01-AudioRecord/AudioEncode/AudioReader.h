//
//  AudioReader.h
//  01-AudioRecord
//
//  Created by KK on 2019/4/29.
//  Copyright © 2019 KK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AudioReader,AudioReaderOption;

@protocol AudioReaderDelegate <NSObject>
@optional

- (void)audioReader:(AudioReader *)reader outputAudioBuffer:(CMSampleBufferRef)audioBuffer;

- (void)audioReader:(AudioReader *)reader outputBytes:(Byte *)bytes length:(UInt32)length;

- (void)audioReader:(AudioReader *)reader statusChanged:(AVAssetReaderStatus)status;

- (void)audioReaderCompleted:(AudioReader *)reader;

@end

@interface AudioReader : NSObject

/** 要读的文件 */
@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, weak) id<AudioReaderDelegate> delegate;

/** 选项 */
@property (nonatomic, strong) AudioReaderOption *option;


/**
 是否只读一帧， 默认是NO
 */
@property (nonatomic, assign) BOOL isReadOneSampleBuffer;

- (void)startReader;

- (void)peekSampleBuffer;

@end


@interface AudioReaderOption : NSObject

/** 采样率: 默认44100 */
@property (nonatomic, assign) Float64 sampleRate;

/** 码率: 默认96000 */
@property (nonatomic, assign) Float64 audioBitrate;

/** 采样深度: 8 16 24 32 默认16 */
@property (nonatomic, assign) uint bitsPerChannel;

/** 声道数: 默认1 */
@property (nonatomic, assign) uint channels;

@end
NS_ASSUME_NONNULL_END
