//
//  ViewController.m
//  01-AudioRecord
//
//  Created by tutu on 2019/4/24.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioRecordViewController.h"
#import "AudioRecordUnit.h"
#import "AudioPlayer.h"
#import "AudioEncodeAAC.h"

#import "AudioSimpleRecorder.h"
#import "AudioRecordWithCapture.h"
#import "AudioSimplePlayer.h"
#import "AudioPlayer.h"
#import "AudioReader.h"
#import "AudioFile.h"
#import "AudioRecorderOption.h"

@interface AudioRecordViewController ()<AudioRecorderDelegate, AudioEncodeAACDelegate, AudioPlayerDataSource, AudioReaderDelegate>

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *completeButton;

/** 是否正在录制 */
@property (nonatomic, assign) BOOL isRecording;
/** 是否正在播放 */
@property (nonatomic, assign) BOOL isPlaying;

/** 录制器 */
@property (nonatomic, strong) AudioRecordUnit *audioUnitRecord;

/**
 录音器
 */
@property (nonatomic, strong) id<AudioRecorder> audioRecord;

/** 转码器 */
@property (nonatomic, strong) AudioEncodeAAC *audioEncoder;

/** 录音机 */
@property (nonatomic, strong) AudioRecordWithCapture *audioCaptureRecorder;

/** 录音机 */
@property (nonatomic, strong) AudioSimpleRecorder *simpleRecorder;

/** 播放器 */
@property (nonatomic, strong) AudioSimplePlayer *simplePlayer;

/** pcm播放器 */
@property (nonatomic, strong) AudioPlayer *pcmPlayer;

/** pcm文件流 */
@property (assign, nonatomic) FILE *pcmFile;

@property (nonatomic, strong) AudioReader *audioReader;


/**
 aac file
 */
@property (nonatomic, strong) NSString *aacFilePath;

/**
 aac from encode file
 */
@property (nonatomic, strong) NSString *aacFilePathFromEncode;

/**
 pcm filePath
 */
@property (nonatomic, strong) NSString *pcmFilePath;

/**
 pcmFileHandle
 */
@property (nonatomic, strong) NSFileHandle *pcmFileHandel;

@end

@implementation AudioRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch (self.recorderType) {
        case AudioRecorderTypeSimple:
            self.audioRecord = self.simpleRecorder;
            break;
            
        case AudioRecorderTypeCapture:
            self.audioRecord = self.audioCaptureRecorder;
            break;
        case AudioRecorderTypeUnit:
            self.audioRecord = self.simpleRecorder;
            break;
        default:
            break;
    }
    
    self.audioRecord.delegate = self;
//    self.audioEncoder.delegate = self;
//    self.audioRecord.delegate = self;
//    self.audioCaptureRecorder.delegate = self;
    
    self.pcmPlayer.dataSource = self;
    self.audioReader.delegate = self;
    self.pcmPlayer.isEnqueueData = NO;
}



- (IBAction)record:(UIButton *)sender {
    
    _isRecording = !_isRecording;
    _recordButton.selected = _isRecording;
    
    if (_isRecording) {
        [self.audioRecord startRecord];
    } else {
        [self.audioRecord stopRecord];
    }
}


- (IBAction)play:(UIButton *)sender {
    if (_isRecording) {
        [self.audioRecord stopRecord];
        _isRecording = NO;
    }
    if (_isPlaying) {
        _isPlaying = NO;
        [self.simplePlayer stopPlay];
        return;
    }
    _isPlaying = YES;
    if (self.isEncodeToAAC) {
        self.simplePlayer.file = self.aacFilePathFromEncode;
    }
    [self.simplePlayer startPlay];
}


- (IBAction)pcmPlayer:(UIButton *)sender {
    if (self.recorderType == AudioRecorderTypeSimple) {
        NSLog(@"-----Simple 录制没有输出pcm文件及流");
        return;
    }
    
    if (_isRecording) {
        [self.audioRecord stopRecord];
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


#pragma mark - encodeDelegate
/**
 音频编码回调

 @param encoder 编码器
 @param aacData 编码后的数据
 */
- (void)audioEncoder:(AudioEncodeAAC *)encoder progressWithAACData:(NSData *)aacData {
    
}


#pragma mark - recoderDelegate --- 数据回调
- (void)audioRecorder:(id<AudioRecorder>)recorder outAudioData:(NSData *)data {
    if (self.isEncodeToAAC) {
        [self.audioEncoder encodeData:data];
    }
    
    [self.pcmFileHandel writeData:data];
}


- (void)audioRecorder:(id<AudioRecorder>)recorder outAudioBuffer:(CMSampleBufferRef)buffer {
    
}

#pragma mark - recoderDelegate --- 状态回调
- (void)audioRecorder:(id<AudioRecorder>)recorder statusChanged:(AudioRecorderStatus)status {
    NSLog(@"-----status:%ld",(long)status);
}

- (void)audioRecorder:(id<AudioRecorder>)recorder complete:(NSString *)audioFilePath {
    NSLog(@"-----finished");
}

- (void)audioRecorder:(id<AudioRecorder>)recorder error:(NSError *)error {
    NSLog(@"-----error: %@", error);
}


#pragma pcmPlayer dataSource
- (void)audioPlayer:(AudioPlayer *)player fillWithBuffer:(Byte *)buffer withLength:(UInt32)length {
    if (_pcmFile == nil) {
        _pcmFile = fopen(self.pcmFilePath.UTF8String, "r");
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


#pragma mark - getter方法
- (AudioRecordUnit *)audioUnitRecord {
    if (_audioUnitRecord == nil) {
        _audioUnitRecord = [[AudioRecordUnit alloc] init];
        [_audioUnitRecord preparRecord];
    }
    return _audioUnitRecord;
}

- (AudioEncodeAAC *)audioEncoder {
    if (_audioEncoder == nil) {
        _audioEncoder = [[AudioEncodeAAC alloc] init];
        _audioEncoder.filePath = self.aacFilePathFromEncode;
    }
    return _audioEncoder;
}

- (id<AudioRecorder>)audioRecord {
    if (!_audioRecord) {
        _audioRecord = [self simpleRecorder];
    }
    return _audioRecord;
}

- (AudioSimpleRecorder *)simpleRecorder {
    if (!_simpleRecorder) {
        AudioRecorderOption *option = [[AudioRecorderOption alloc] init];
        option.formatIDKey = kAudioFormatMPEG4AAC;
        _simpleRecorder = [[AudioSimpleRecorder alloc] initWithOption:option];
        _simpleRecorder.filePath = [self aacFilePath];
        [_simpleRecorder preparRecord];
    }
    return _simpleRecorder;
}

- (AudioRecordWithCapture *)audioCaptureRecorder {
    if (!_audioCaptureRecorder) {
        
        AudioRecorderOption *option = [[AudioRecorderOption alloc] init];
        option.formatIDKey = kAudioFormatMPEG4AAC;
        _audioCaptureRecorder = [[AudioRecordWithCapture alloc] initWithOption:option];
        _audioCaptureRecorder.filePath = self.aacFilePath;
        _audioCaptureRecorder.saveAudioFile = YES;
        [_audioCaptureRecorder preparRecord];
    }
    return _audioCaptureRecorder;
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

- (NSString *)aacFilePath {
    if (!_aacFilePath) {
        NSInteger count = [[AudioFile audioFile] countOfFileType:@".mp4"];
        NSString *fileName = [NSString stringWithFormat:@"MP4-%@-%02ld.mp4", [self typeName], (long)count];
        _aacFilePath = [[AudioFile audioFile] createAudioFile:fileName];
    }
    return _aacFilePath;
}


- (NSString *)aacFilePathFromEncode {
    if (!_aacFilePathFromEncode) {
        NSInteger count = [[AudioFile audioFile] countOfFileType:@".aac"];
        NSString *fileName = [NSString stringWithFormat:@"AAC-%@-%02ld-Encode.aac", [self typeName], (long)count];
        _aacFilePathFromEncode = [[AudioFile audioFile] createAudioFile:fileName];
    }
    return _aacFilePathFromEncode;
}


- (NSString *)pcmFilePath {
    if (!_pcmFilePath) {
        NSInteger count = [[AudioFile audioFile] countOfFileType:@".pcm"];
        NSString *fileName = [NSString stringWithFormat:@"PCM-%02ld-%@.pcm", (long)count, [self typeName]];
        _pcmFilePath = [[AudioFile audioFile] createAudioFile:fileName];
    }
    return _pcmFilePath;
}

- (NSFileHandle *)pcmFileHandel {
    if (!_pcmFileHandel) {
        _pcmFileHandel = [[AudioFile audioFile] createFileHandleWithAudioFilePath:self.pcmFilePath];
    }
    return _pcmFileHandel;
}

- (NSString *)typeName {
    switch (self.recorderType) {
        case AudioRecorderTypeSimple:
            return @"Simple";
            break;
        case AudioRecorderTypeCapture:
            return @"Capture";
            break;
        case AudioRecorderTypeUnit:
            return @"Unit";
            break;
        default:
            break;
    }
    return @"";
}

@end
