//
//  GroupInController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "GroupInController.h"
#import "AppDelegate.h"

@interface GroupInController () <ASConnectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *groupInTable;

@property (nonatomic,strong) NSMutableArray *groupInArr;
@property (nonatomic,strong) AppDelegate *dele;
@property (nonatomic,strong) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UIButton *startBtn;

@end

static NSString *CellIdentifier=@"GroupInCell";

@implementation GroupInController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.groupNameLabel.text=[NSString stringWithFormat:@"组名：%@",self.dele.group.groupName];
    
    self.groupInArr=[NSMutableArray array];
    [self.groupInTable registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.groupInTable.tableFooterView=[[UIView alloc] init];
    
    self.timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(refreshGroupInTable) userInfo:nil repeats:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=self;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=nil;
    }
}

-(void)refreshGroupInTable {
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageGetGroupInUser],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"groupID":[NSNumber numberWithInt:self.dele.group.groupID]
                        };
    NSData *data=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:5];
}

- (IBAction)goBackToGroupList:(id)sender {
    [self.timer invalidate];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doStart:(id)sender {
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupInArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell==nil) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *groupInUser=self.groupInArr[indexPath.row];
    
    return cell;
}

#pragma mark - ASConnectionDelegate

-(void)didReadData:(NSData *)jsonData {
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    NSLog(@"result %@",dic);
    
    switch ([dic[@"type"] intValue]) {
        case MessageGetGroupInUser:
            if (![dic[@"error"] boolValue]) {
                NSArray *groupList=dic[@"result"];
                [self.groupInArr removeAllObjects];
                [self.groupInArr addObjectsFromArray:groupList];
                
                [self.groupInTable reloadData];
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
        case MessageQuitGroup:
            break;
        case MessageUserGameReady:
            break;
        case MessageUserGameCancel:
            break;
        case MessageGameStart:
            break;
    }
    
}

@end
