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
#import "AudioPlayer.h"
#import "AudioReader.h"

@interface AudioRecordViewController ()<AudioRecordDelegate, AudioEncodeAACDelegate, AudioRecordWithCaptureDelegate, AudioPlayerDataSource, AudioReaderDelegate>

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

/** pcm播放器 */
@property (nonatomic, strong) AudioPlayer *pcmPlayer;

/** pcm文件流 */
@property (assign, nonatomic) FILE *pcmFile;

@property (nonatomic, strong) AudioReader *audioReader;

@end

@implementation AudioRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.audioEncoder.delegate = self;
    self.audioRecord.delegate = self;
    self.audioRecordWithCapture.delegate = self;
    self.pcmPlayer.dataSource = self;
    self.audioReader.delegate = self;
    self.pcmPlayer.isEnqueueData = NO;
}



- (IBAction)record:(UIButton *)sender {
    
    _isRecording = !_isRecording;
    _recordButton.selected = _isRecording;
    
    if (_isPlaying) {
        [self.audioRecord startRecord];
    } else {
        [self.audioRecord stopRecord];
    }
    return;
    if (_isRecording) {
        [self.audioRecordWithCapture startRecord];
    } else {
        [self.audioRecordWithCapture stopRecord];
        
        return;
//        // 设置路径试试
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.audioReader setFilePath:self.audioRecordWithCapture.aacFiles.firstObject];
//            [self.audioReader startReader];
//        });
    }
}


- (IBAction)play:(UIButton *)sender {
    if (_isRecording) {
        [self.audioRecord stopRecord];
        [self.audioRecordWithCapture stopRecord];
        _isRecording = NO;
    }
    if (_isPlaying) {
        _isPlaying = NO;
        [self.simplePlayer stopPlay];
        return;
    }
    _isPlaying = YES;
    self.simplePlayer.file = self.audioEncoder.filePath;
    [self.simplePlayer startPlay];
}


- (IBAction)pcmPlayer:(UIButton *)sender {
    if (_isRecording) {
        [self.audioRecord stopRecord];
        [self.audioRecordWithCapture stopRecord];
        _isRecording = NO;
    }
    
    if (_isPlaying) {
        _isPlaying = NO;
        [self.pcmPlayer stop];
        return;
    }
    _isPlaying = YES;
    [self.pcmPlayer prepareToPlay];
    [self.pcmPlayer play];
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

#pragma pcmPlayer dataSource
- (void)audioPlayer:(AudioPlayer *)player fillWithBuffer:(Byte *)buffer withLength:(UInt32)length {
    if (_pcmFile == nil) {
//        _pcmFile = fopen(self.audioRecordWithCapture.filePath.UTF8String, "r");
        _pcmFile = fopen(self.audioRecord.filePath.UTF8String, "r");
    }
    if (feof(self.pcmFile)) {
        // 播放结束
        [self.pcmPlayer stop];
        fseek(self.pcmFile, 0, SEEK_SET);
        [self.pcmPlayer resetPlayer];
        [self.pcmPlayer prepareToPlay];
        _isPlaying = NO;
    }
    fread(buffer, sizeof(Byte), length, self.pcmFile);
}

- (void)audioReader:(AudioReader *)reader outputAudioBuffer:(CMSampleBufferRef)audioBuffer {
    if (self.pcmPlayer) {
        [_pcmPlayer enqueueBufferWithSampleBuffer:audioBuffer];
    }
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

- (AudioPlayer *)pcmPlayer {
    if (!_pcmPlayer) {
        _pcmPlayer = [[AudioPlayer alloc] init];
    }
    return _pcmPlayer;
}

- (AudioReader *)audioReader {
    if (!_audioReader) {
        _audioReader = [[AudioReader alloc] init];
    }
    return _audioReader;
}
@end
