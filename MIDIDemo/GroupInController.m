//
//  GroupInController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "GroupInController.h"
#import "AppDelegate.h"
#import "GroupInCell.h"

#import "GamingController.h"

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
    self.groupInTable.tableFooterView=[[UIView alloc] init];
    
    self.timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshGroupInTable) userInfo:nil repeats:YES];
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
    int readyCount=0;
    for (NSDictionary *groupInUser in self.groupInArr) {
        if ([groupInUser[@"groupin_user_status"] intValue]==UserPlayStatusReady) {
            readyCount++;
        }
    }
    if (readyCount!=0&&readyCount==self.groupInArr.count) {
        self.startBtn.enabled=YES;
    }else{
        self.startBtn.enabled=NO;
    }
    
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageGetGroupInUser],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"groupID":[NSNumber numberWithInt:self.dele.group.groupID]
                        };
    NSData *data=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageGetGroupInUser];
}

- (IBAction)goBackToGroupList:(id)sender {
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageQuitGroup],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"userID":[NSNumber numberWithInt:self.dele.user.userID],
                        @"userName":self.dele.user.userName,
                        @"groupID":[NSNumber numberWithInt:self.dele.group.groupID],
                        @"userIsHost":[NSNumber numberWithBool:self.dele.user.isHost]
                        };
    NSData *data=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageQuitGroup];
}

- (IBAction)doStart:(id)sender {
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageGameStart],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"groupID":[NSNumber numberWithInt:self.dele.group.groupID]
                        };
    NSData *data=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageGameStart];
}

- (IBAction)doReady:(id)sender {
    UIButton *readyBtn=(UIButton *)sender;
    
    if ([readyBtn.titleLabel.text isEqualToString:@"准备"]) {
        [readyBtn setTitle:@"取消" forState:UIControlStateNormal];
        
        NSDate *date=[NSDate date];
        NSDictionary *dic=@{
                            @"type":[NSNumber numberWithInt:MessageUserGameReady],
                            @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                            @"userID":[NSNumber numberWithInt:self.dele.user.userID],
                            @"groupID":[NSNumber numberWithInt:self.dele.group.groupID],
                            @"userIsHost":[NSNumber numberWithBool:self.dele.user.isHost]
                            };
        NSData *data=[NSData encodeDataForSocket:dic];
        [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageUserGameReady];
    }else{
        [readyBtn setTitle:@"准备" forState:UIControlStateNormal];
        
        NSDate *date=[NSDate date];
        NSDictionary *dic=@{
                            @"type":[NSNumber numberWithInt:MessageUserGameCancel],
                            @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                            @"userID":[NSNumber numberWithInt:self.dele.user.userID],
                            @"groupID":[NSNumber numberWithInt:self.dele.group.groupID],
                            @"userIsHost":[NSNumber numberWithBool:self.dele.user.isHost]
                            };
        NSData *data=[NSData encodeDataForSocket:dic];
        [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageUserGameCancel];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupInArr.count;
}

- (GroupInCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupInCell *cell=(GroupInCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *groupInUser=self.groupInArr[indexPath.row];
    
    cell.groupInUserName.text=[NSString stringWithFormat:@"%@",groupInUser[@"groupin_user_name"]];
    
    if ([groupInUser[@"groupin_user_id"] intValue]==self.dele.user.userID) {
        cell.groupInReadyBtn.hidden=NO;
        cell.groupInUserName.textColor=[UIColor redColor];
    }else{
        cell.groupInReadyBtn.hidden=YES;
        cell.groupInUserName.textColor=[UIColor blackColor];
    }
    
    switch ([groupInUser[@"groupin_user_status"] intValue]) {
        case UserPlayStatusNotReady:
            cell.groupInUserStatus.text=@"未准备";
            cell.groupInUserStatus.textColor=[UIColor lightGrayColor];
            break;
        case UserPlayStatusReady:
            cell.groupInUserStatus.text=@"已准备";
            cell.groupInUserStatus.textColor=[UIColor greenColor];
            break;
        case UserPlayStatusStart:
            cell.groupInUserStatus.text=@"进行中";
            cell.groupInUserStatus.textColor=[UIColor blackColor];
            break;
        case UserPlayStatusEnd:
            cell.groupInUserStatus.text=@"已结束";
            cell.groupInUserStatus.textColor=[UIColor redColor];
            break;
    }
    
    switch ([groupInUser[@"groupin_user_musical"] intValue]) {
        case MusicalTypePiano:
            cell.groupInUserMusical.text=@"piano";
            break;
    }
    
    switch ([groupInUser[@"groupin_user_musical_status"] intValue]) {
        case MusicalStatusConnect:
            cell.groupInUserMusicalStatus.text=@"已连接";
            cell.groupInUserMusicalStatus.textColor=[UIColor greenColor];
            break;
        case MusicalStatusDisConnect:
            cell.groupInUserMusicalStatus.text=@"断开连接";
            cell.groupInUserMusicalStatus.textColor=[UIColor redColor];
            break;
    }
    
    if ([groupInUser[@"groupin_user_ishost"] boolValue]) {
        cell.groupInUserHost.hidden=NO;
        self.dele.user.isHost=YES;
    }else{
        cell.groupInUserHost.hidden=YES;
        self.dele.user.isHost=NO;
    }
    
    return cell;
}

#pragma mark - ASConnectionDelegate

-(void)didReadData:(NSData *)jsonData {
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    NSLog(@"GroupInController %@",dic);
    
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
            if (![dic[@"error"] boolValue]) {
                NSDictionary *result=dic[@"result"];
                if ([result[@"userID"] intValue]==self.dele.user.userID) {
                    [self.timer invalidate];
                    [self.navigationController popViewControllerAnimated:YES];
                }else{
                    NSString *msg=[NSString stringWithFormat:@"%@退出游戏组",result[@"userName"]];
                    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"通知" message:msg delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
                    [alert show];
                }
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
        case MessageUserGameReady:
            break;
        case MessageUserGameCancel:
            break;
        case MessageGameStart:
            NSLog(@"MessageGameStart %@",dic);
            
            if (![dic[@"error"] boolValue]) {
                [self.timer invalidate];
                
                UIStoryboard *story=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
                GamingController *gamingVC=[story instantiateViewControllerWithIdentifier:@"GameingVC"];
                [self.navigationController pushViewController:gamingVC animated:YES];
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
    }
    
}

@end
