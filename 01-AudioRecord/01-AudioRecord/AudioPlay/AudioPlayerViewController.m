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

/**
 UIButton
 */
@property (nonatomic, strong) UIButton *changedSpeed;

@end

@implementation AudioPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.reader.filePath = _filePath;
    self.reader.delegate = self;
    
    self.player.dataSource = self;
    
    _pcmDatas = [NSMutableData data];
    
    _changedSpeed = [[UIButton alloc] initWithFrame:CGRectMake(15, 100, 60, 40)];
    [_changedSpeed setTitle:@"变速" forState:UIControlStateNormal];
    [_changedSpeed setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [_changedSpeed addTarget:self action:@selector(changeSpeed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_changedSpeed];
}

- (void)changeSpeed:(UIButton *)btn {
    btn.selected = !btn.selected;
    [self.player changeSpeed:btn.selected ? 2.0 : 1.0];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.reader startReader];
    [self.player play];
}

#pragma mark - AudioReaderDelegate
- (void)audioReaderCompleted:(AudioReader *)reader {
    NSLog(@"--------read completed");
//    [self.player prepareToPlay];
//    [self.player play];
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
    [self.player enqueueBufferWithData:[NSData dataWithBytes:buffer length:length]];
//    [_pcmDatas appendBytes:buffer length:length];
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
        _player.isEnqueueData = YES;
        [_player prepareToPlay];
    }
    return _player;
}

@end
