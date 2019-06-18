//
//  DemoListViewController.m
//  01-AudioRecord
//
//  Created by K K on 2019/6/17.
//  Copyright © 2019 KK. All rights reserved.
//

#import "DemoListViewController.h"

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
                @"Audio List"];
    _viewControllerSegueIDS = @[@"AudioRecordViewController",
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
    [self performSegueWithIdentifier:_viewControllerSegueIDS[indexPath.row] sender:indexPath];
}


#pragma mark - 跳转

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"%@",segue);
}

@end
