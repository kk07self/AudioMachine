//
//  AudioRecord.h
//  01-AudioRecord
//
//  Created by tutu on 2019/4/24.
//  Copyright © 2019 KK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class AudioRecordOption, AudioRecord;

@protocol AudioRecordDelegate <NSObject>

- (void)audioRecorder:(AudioRecord *)recorder outAudioData:(NSData *)data;

@end


@interface AudioRecord : NSObject

/** option */
@property (nonatomic, strong) AudioRecordOption *defaultOption;

/** 是否保存到本地：默认YES */
@property (nonatomic, assign) BOOL saveAudioFile;

/** 保存的路径：默认--docment/demo.pcm */
@property (nonatomic, strong) NSString *filePath;

/** delegate */
@property (nonatomic, weak) id<AudioRecordDelegate> delegate;

- (void)preparRecord;

- (BOOL)startRecord;

- (void)stopRecord;

- (void)completeRecord;

@end




@interface AudioRecordOption : NSObject

/** 采样率: 默认44100 */
@property (nonatomic, assign) Float64 sampleRate;

/** 采样深度: 8 16 24 32 默认16 */
@property (nonatomic, assign) uint bitsPerChannel;

/** 声道数 */
@property (nonatomic, assign) uint channels;

@end
NS_ASSUME_NONNULL_END
