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


@interface AudioSimpleRecorder : NSObject<AudioRecorder>


/**
 获取声波

 @param channel 声道
 @return 声波大小【0,1】
 */
- (float)averagePowerForChannel:(int)channel;

@end

NS_ASSUME_NONNULL_END
