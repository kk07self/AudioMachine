//
//  AudioFileListViewController.m
//  01-AudioRecord
//
//  Created by tutu on 2019/6/18.
//  Copyright © 2019 KK. All rights reserved.
//

#import "AudioFileListViewController.h"
#import "AudioPlayerViewController.h"
#import "AudioFile.h"

#define kAudioFileListCellKey  @"AudioFileListViewControllerCellID"

@interface AudioFileListViewController ()

/**
 datas
 */
@property (nonatomic, strong) NSArray *datas;

@end

@implementation AudioFileListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"音频文件列表";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kAudioFileListCellKey];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.datas = [NSArray arrayWithArray:[[AudioFile audioFile] allAudioFiles]];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAudioFileListCellKey forIndexPath:indexPath];
    
    cell.textLabel.text = [[AudioFile audioFile] fileNameFromAudioFile:self.datas[indexPath.row]];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"AudioPlayerViewController" sender:[[AudioFile audioFile] createAudioFile:[[AudioFile audioFile] fileNameFromAudioFile:self.datas[indexPath.row]]]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[AudioPlayerViewController class]]) {
        AudioPlayerViewController *vc = (AudioPlayerViewController*)segue.destinationViewController;
        vc.filePath = (NSString *)sender;
    }
}

@end
