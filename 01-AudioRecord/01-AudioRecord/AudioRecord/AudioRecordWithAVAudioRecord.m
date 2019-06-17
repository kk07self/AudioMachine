//
//  AudioRecordWithAVRecord.m
//  01-AudioRecord
//
//  Created by K K on 2019/6/17.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioRecordWithAVAudioRecord.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioRecordWithAVAudioRecord()

@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation AudioRecordWithAVAudioRecord

@synthesize options;

- (instancetype)initWithOption:(id<AudioRecordOptions>)options {
    if (self = [super init]) {
        self.options = options;
    }
    return self;
}

- (void)preparRecord {
    
}

- (BOOL)startRecord {
    
    return YES;
}

- (void)stopRecord {
    
}

- (void)completeRecord {
    
}

@end
