//
//  AudioPlayerViewController.m
//  01-AudioRecord
//
//  Created by tutu on 2019/6/18.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioPlayerViewController.h"
#import "AudioReader.h"
#import "AudioPlayer.h"
#import "AudioSimplePlayer.h"

@interface AudioPlayerViewController ()<AudioReaderDelegate, AudioPlayerDataSource>

@property (nonatomic, strong) AudioReader *reader;

@property (nonatomic, strong) AudioPlayer *player;

@property (nonatomic, strong) NSMutableData *pcmDatas;

@property (nonatomic, assign) UInt32 flag;

@end

@implementation AudioPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.reader.filePath = _filePath;
    self.reader.delegate = self;
    
    self.player.dataSource = self;
    
    _pcmDatas = [NSMutableData data];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.reader startReader];
}

#pragma mark - AudioReaderDelegate
- (void)audioReaderCompleted:(AudioReader *)reader {
    NSLog(@"--------read completed");
    [self.player prepareToPlay];
    [self.player play];
}

- (void)audioReader:(AudioReader *)reader statusChanged:(AVAssetReaderStatus)status {
    NSLog(@"--------status: %d", status);
}

- (void)audioReader:(AudioReader *)reader outputAudioBuffer:(CMSampleBufferRef)audioBuffer {
//    [self.player enqueueBufferWithSampleBuffer:audioBuffer];
    NSLog(@"%@", audioBuffer);
    // fileHandle写入pcm
    CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(audioBuffer);
    size_t length = CMBlockBufferGetDataLength(blockBufferRef);
    Byte buffer[length];
    CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
    [_pcmDatas appendBytes:buffer length:length];
}

- (void)audioReader:(AudioReader *)reader outputBytes:(Byte *)bytes length:(UInt32)length {
    
}

#pragma mark - AudioPlayDatasouce
- (void)audioPlayer:(AudioPlayer *)player fillWithBuffer:(Byte *)buffer withLength:(UInt32)length {
    [_pcmDatas getBytes:buffer range:NSMakeRange(_flag, length)];
    _flag += length;
}



- (AudioReader *)reader {
    if (!_reader) {
        _reader = [[AudioReader alloc] init];
    }
    return _reader;
}

- (AudioPlayer *)player {
    if (!_player) {
        _player = [[AudioPlayer alloc] init];
        _player.isEnqueueData = NO;
    }
    return _player;
}

@end
