//
//  AudioRecordWithAVRecord.h
//  01-AudioRecord
//
//  Created by K K on 2019/6/17.
//  Copyright © 2019 KK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioRecordProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AudioRecordWithAVAudioRecord;

@protocol AudioRecordWithAVAudioRecordDelegate <NSObject>

- (void)audioRecorder:(AudioRecordWithAVAudioRecord *)recorder outAudioData:(NSData *)data;

@end

@interface AudioRecordWithAVAudioRecord : NSObject<AudioRecordBase>

/** 是否保存到本地：默认YES */
@property (nonatomic, assign) BOOL saveAudioFile;

/** 保存的路径：默认--docment/demo.pcm */
@property (nonatomic, strong) NSString *filePath;

/** delegate */
@property (nonatomic, weak) id<AudioRecordWithAVAudioRecordDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
