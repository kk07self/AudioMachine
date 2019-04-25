//
//  AudioEncodeAAC.h
//  01-AudioRecord
//
//  Created by tutu on 2019/4/25.
//  Copyright © 2019 KK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AudioEncodeAAC, AudioEncodeAACOption;

@protocol AudioEncodeAACDelegate <NSObject>

- (void)audioEncoder:(AudioEncodeAAC *)encoder progressWithAACData:(NSData *)aacData;

@end


@interface AudioEncodeAAC : NSObject

/** 是否保存到本地：默认是YES */
@property (nonatomic, assign) BOOL isSaveToFile;
/** file --- 转到文件的路径, 默认是docm下的demo.aac文件 */
@property (nonatomic, strong) NSString *filePath;

/** options */
@property (nonatomic, strong) AudioEncodeAACOption *options;

/** 回调代理 */
@property (nonatomic, assign) id<AudioEncodeAACDelegate> delegate;

- (void)encodeData:(NSData *)audioPCMData;

@end



@interface AudioEncodeAACOption : NSObject

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
