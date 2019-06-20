//
//  AudioSimplePlayer.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/26.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioSimplePlayer.h"
#import <AVKit/AVKit.h>

@interface AudioSimplePlayer()

/** player */
@property (nonatomic, strong) AVAudioPlayer *player;

@end


@implementation AudioSimplePlayer

- (instancetype)initWithFilePath:(NSString *)filePath {
    if (self = [super init]) {
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] fileTypeHint:AVFileTypeMPEG4 error:NULL];
        [_player prepareToPlay];
    }
    return self;
}

- (void)startPlay {
    [self.player play];
}

- (void)pausePlay {
    [self.player pause];
}

- (void)stopPlay {
    [self.player stop];
}


- (void)setFile:(NSString *)file {
    _file = file;
    [self.player stop];
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&error];
    if (error) {
        NSLog(@"%@",error);
        return;
    }
    [self.player prepareToPlay];
}

@end
