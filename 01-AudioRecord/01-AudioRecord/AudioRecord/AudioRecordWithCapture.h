//
//  AudioRecordWithCaptrue.h
//  01-AudioRecord
//
//  Created by tutu on 2019/4/26.
//  Copyright © 2019 KK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AudioRecordWithCaptureOption, AudioRecordWithCapture;

@protocol AudioRecordWithCaptureDelegate <NSObject>

- (void)audioRecorderWithCapture:(AudioRecordWithCapture *)recorder outAudioData:(NSData *)data;

- (void)audioRecorderWithCapture:(AudioRecordWithCapture *)recorder outAudioBuffer:(CMSampleBufferRef)buffer;

@end



@interface AudioRecordWithCapture : NSObject

/** option */
@property (nonatomic, strong) AudioRecordWithCaptureOption *defaultOption;

/** 是否保存到本地：默认YES */
@property (nonatomic, assign) BOOL saveAudioFile;

/** 保存的路径：默认--docment/capture.pcm */
@property (nonatomic, strong) NSString *filePath;

/** aac 文件数组 */
@property (nonatomic, strong) NSMutableArray<NSString *> *aacFiles;

/** delegate */
@property (nonatomic, weak) id<AudioRecordWithCaptureDelegate> delegate;

- (void)preparRecord;

- (void)startRecord;

- (void)pauseRecord;

- (void)stopRecord;

- (void)completeRecord;

@end


@interface AudioRecordWithCaptureOption : NSObject

/** 采样率: 默认44100 */
@property (nonatomic, assign) Float64 sampleRate;

/** 采样深度: 8 16 24 32 默认16 */
@property (nonatomic, assign) uint bitsPerChannel;


@end
NS_ASSUME_NONNULL_END
