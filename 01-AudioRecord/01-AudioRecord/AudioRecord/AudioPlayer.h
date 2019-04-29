//
//  AudioPlayer.h
//  01-AudioRecord
//
//  Created by tutu on 2019/4/25.
//  Copyright © 2019 KK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AudioPlayerOption;
@interface AudioPlayer : NSObject

/** duration */
@property (nonatomic, assign) double currentProgress;

/** options */
@property (nonatomic, strong) AudioPlayerOption *option;

/** 播放file */
@property (nonatomic, strong) NSString *filePath;



- (void)enqueueBufferWithSampleBuffer: (CMSampleBufferRef)sampleBuffer;

// 播放并顺带附上数据
- (void)enqueueBufferWithData:(NSData *)data;

- (void)prepareToPlay;
- (void)play;
- (void)pause;
- (void)stop;
- (void)resetPlayer;


@end


@interface AudioPlayerOption : NSObject

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
