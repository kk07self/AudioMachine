//
//  AudioSimplePlayer.h
//  01-AudioRecord
//
//  Created by tutu on 2019/4/26.
//  Copyright © 2019 KK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioSimplePlayer : NSObject

/** file */
@property (nonatomic, strong) NSString *file;

- (instancetype)initWithFilePath:(NSString *)filePath;

- (void)startPlay;

- (void)pausePlay;

- (void)stopPlay;

@end

NS_ASSUME_NONNULL_END
