//
//  DemoListViewController.m
//  01-AudioRecord
//
//  Created by K K on 2019/6/17.
//  Copyright © 2019 KK. All rights reserved.
//

#import "DemoListViewController.h"
#import "AudioRecordViewController.h"

@interface DemoListViewController ()
{
    NSArray *_models;
    NSArray *_viewControllerSegueIDS;
}
@end



@implementation DemoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _models = @[@"SimpleAudioRecord",
                @"CaptureAudioRecord",
                @"CaptureAudioRecordAndEncodeToAAC",
                @"Audio List"];
    _viewControllerSegueIDS = @[@"AudioRecordViewController",
                                @"AudioRecordViewController",
                                @"AudioRecordViewController",
                                @"AudioFileListViewController"];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DemoListViewController"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _models.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DemoListViewController" forIndexPath:indexPath];
    cell.textLabel.text = _models[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:_viewControllerSegueIDS[indexPath.row] sender:_models[indexPath.row]];
}


#pragma mark - 跳转

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *model = (NSString *)sender;
    if ([model isEqualToString:@"SimpleAudioRecord"]) {
        AudioRecordViewController *vc = (AudioRecordViewController *)(segue.destinationViewController);
        vc.recorderType = AudioRecorderTypeSimple;
    } else if ([model isEqualToString:@"CaptureAudioRecord"]) {
        AudioRecordViewController *vc = (AudioRecordViewController *)(segue.destinationViewController);
        vc.recorderType = AudioRecorderTypeCapture;
    } else if ([model isEqualToString:@"CaptureAudioRecordAndEncodeToAAC"]) {
        AudioRecordViewController *vc = (AudioRecordViewController *)(segue.destinationViewController);
        vc.recorderType = AudioRecorderTypeCapture;
        vc.isEncodeToAAC = YES;
    }
}

@end
