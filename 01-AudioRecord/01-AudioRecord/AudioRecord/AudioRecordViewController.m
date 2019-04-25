//
//  ViewController.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/24.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioRecordViewController.h"
#import "AudioRecord.h"
#import "AudioPlayer.h"
#import "AudioEncodeAAC.h"

@interface AudioRecordViewController ()<AudioRecordDelegate, AudioEncodeAACDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *completeButton;

/** 是否正在录制 */
@property (nonatomic, assign) BOOL isRecording;
/** 是否正在播放 */
@property (nonatomic, assign) BOOL isPlaying;

/** 录制器 */
@property (nonatomic, strong) AudioRecord *audioRecord;

/** 转码器 */
@property (nonatomic, strong) AudioEncodeAAC *audioEncoder;
@end

@implementation AudioRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.audioEncoder.delegate = self;
    self.audioRecord.delegate = self;
}



- (IBAction)record:(UIButton *)sender {
    _isPlaying = !_isPlaying;
    _recordButton.selected = _isPlaying;
    
    if (_isPlaying) {
        [self.audioRecord startRecord];
    } else {
        [self.audioRecord stopRecord];
    }
}


- (IBAction)play:(UIButton *)sender {
    [self.audioRecord stopRecord];
}



#pragma 代理回调
/**
 音频编码回调

 @param encoder 编码器
 @param aacData 编码后的数据
 */
- (void)audioEncoder:(AudioEncodeAAC *)encoder progressWithAACData:(NSData *)aacData {
    NSLog(@"%@",aacData);
}


/**
 音频录制回调

 @param recorder 录制器
 @param data 录制的数据
 */
- (void)audioRecorder:(AudioRecord *)recorder outAudioData:(NSData *)data {
    [self.audioEncoder encodeData:data];
}


#pragma getter方法
- (AudioRecord *)audioRecord {
    if (_audioRecord == nil) {
        _audioRecord = [[AudioRecord alloc] init];
        [_audioRecord preparRecord];
    }
    return _audioRecord;
}

- (AudioEncodeAAC *)audioEncoder {
    if (_audioEncoder == nil) {
        _audioEncoder = [[AudioEncodeAAC alloc] init];
    }
    return _audioEncoder;
}

@end
