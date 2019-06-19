//
//  ViewController.h
//  01-AudioRecord
//
//  Created by tutu on 2019/4/24.
//  Copyright © 2019 KK. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AudioRecorderType) {
    AudioRecorderTypeSimple = 0,
    AudioRecorderTypeCapture,
    AudioRecorderTypeUnit
};


@interface AudioRecordViewController : UIViewController

/**
 录音器类型
 */
@property (nonatomic, assign) AudioRecorderType recorderType;

@end

