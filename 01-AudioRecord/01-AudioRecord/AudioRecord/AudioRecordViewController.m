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

#import "AudioRecordWithCapture.h"
#import "AudioSimplePlayer.h"

@interface AudioRecordViewController ()<AudioRecordDelegate, AudioEncodeAACDelegate, AudioRecordWithCaptureDelegate>

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

/** 录音机 */
@property (nonatomic, strong) AudioRecordWithCapture *audioRecordWithCapture;

/** 播放器 */
@property (nonatomic, strong) AudioSimplePlayer *simplePlayer;
@end

@implementation AudioRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.audioEncoder.delegate = self;
    self.audioRecord.delegate = self;
    self.audioRecordWithCapture.delegate = self;
}



- (IBAction)record:(UIButton *)sender {
    _isPlaying = !_isPlaying;
    _recordButton.selected = _isPlaying;
    
//    if (_isPlaying) {
//        [self.audioRecord startRecord];
//    } else {
//        [self.audioRecord stopRecord];
//    }
    
    if (_isPlaying) {
        [self.audioRecordWithCapture startRecord];
    } else {
        [self.audioRecordWithCapture stopRecord];
    }
}


- (IBAction)play:(UIButton *)sender {
//    [self.audioRecord stopRecord];
    [self.audioRecordWithCapture stopRecord];
//    self.simplePlayer.file = self.audioRecordWithCapture.aacFiles.lastObject;
    self.simplePlayer.file = self.audioEncoder.filePath;
    [self.simplePlayer startPlay];
}



#pragma 代理回调
/**
 音频编码回调

 @param encoder 编码器
 @param aacData 编码后的数据
 */
- (void)audioEncoder:(AudioEncodeAAC *)encoder progressWithAACData:(NSData *)aacData {
//    NSLog(@"%@",aacData);
}


/**
 音频录制回调

 @param recorder 录制器
 @param data 录制的数据
 */
- (void)audioRecorder:(AudioRecord *)recorder outAudioData:(NSData *)data {
    [self.audioEncoder encodeData:data];
}


#pragma 录制回调
- (void)audioRecorderWithCapture:(AudioRecordWithCapture *)recorder outAudioData:(NSData *)data {
    [self.audioEncoder encodeData:data];
}

- (void)audioRecorderWithCapture:(AudioRecordWithCapture *)recorder outAudioBuffer:(CMSampleBufferRef)buffer {
    
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


- (AudioRecordWithCapture *)audioRecordWithCapture {
    if (!_audioRecordWithCapture) {
        _audioRecordWithCapture = [[AudioRecordWithCapture alloc] init];
        [_audioRecordWithCapture preparRecord];
    }
    return _audioRecordWithCapture;
}

- (AudioSimplePlayer *)simplePlayer {
    if (!_simplePlayer) {
        _simplePlayer = [[AudioSimplePlayer alloc] init];
    }
    return _simplePlayer;
}
@end
