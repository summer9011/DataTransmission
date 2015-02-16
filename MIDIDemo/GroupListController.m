//
//  GroupListController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "GroupListController.h"
#import "AppDelegate.h"

#import "GroupInController.h"

@interface GroupListController () <ASConnectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *groupTable;

@property (nonatomic,strong) NSMutableArray *groupArr;
@property (nonatomic,strong) AppDelegate *dele;
@property (nonatomic,strong) NSTimer *timer;

//CreateGroup
@property (weak, nonatomic) IBOutlet UIView *createGroupView;
@property (weak, nonatomic) IBOutlet UITextField *createGroupName;
@property (weak, nonatomic) IBOutlet UIButton *createGroupBtn;

@end

static NSString *CellIdentifier=@"GroupCell";

@implementation GroupListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.createGroupView.backgroundColor=[UIColor colorWithWhite:0 alpha:0.3];
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.userNameLabel.text=[NSString stringWithFormat:@"用户名：%@",self.dele.user.userName];
    
    self.groupArr=[NSMutableArray array];
    [self.groupTable registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.groupTable.tableFooterView=[[UIView alloc] init];
    
    self.timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshGroupTable) userInfo:nil repeats:YES];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=self;
    }
    
    if (self.timer) {
        [self.timer setFireDate:[NSDate distantPast]];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=nil;
    }
    
    if (self.timer) {
        [self.timer setFireDate:[NSDate distantFuture]];
    }
}

-(void)refreshGroupTable {
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageGetGameGroup],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970]
                        };
    NSData *data=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageGetGameGroup];
}

- (IBAction)createGroup:(id)sender {
    self.createGroupView.hidden=NO;
}

- (IBAction)cancelGroup:(id)sender {
    self.createGroupView.hidden=YES;
}

- (IBAction)doCreateGroup:(id)sender {
    if (![self.createGroupName.text isEqualToString:@""]) {
        self.dele.group.groupName=self.createGroupName.text;
        
        NSDate *date=[NSDate date];
        NSDictionary *dic=@{
                            @"type":[NSNumber numberWithInt:MessageCreateGroup],
                            @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                            @"groupName":self.dele.group.groupName,
                            @"userID":[NSNumber numberWithInt:self.dele.user.userID],
                            @"userName":self.dele.user.userName
                            };
        NSData *data=[NSData encodeDataForSocket:dic];
        [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageCreateGroup];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"请输入游戏组名" message:nil delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (IBAction)tapOnCreateGroupBack:(id)sender {
    [self.createGroupName resignFirstResponder];
}

-(void)goGroupIn {
    UIStoryboard *story=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
    GroupInController *groupInVC=[story instantiateViewControllerWithIdentifier:@"GroupInVC"];
    
    [self.navigationController pushViewController:groupInVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell==nil) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *group=self.groupArr[indexPath.row];
    
    switch ([group[@"group_status"] intValue]) {
        case GroupStatusCancel:
            cell.textLabel.text=[NSString stringWithFormat:@"%@  (已取消)",group[@"group_name"]];
            break;
        case GroupStatusReady:
            cell.textLabel.text=[NSString stringWithFormat:@"%@  (可加入)",group[@"group_name"]];
            break;
        case GroupStatusStart:
            cell.textLabel.text=[NSString stringWithFormat:@"%@  (进行中)",group[@"group_name"]];
            break;
        case GroupStatusEnd:
            cell.textLabel.text=[NSString stringWithFormat:@"%@  (已结束)",group[@"group_name"]];
            break;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *group=self.groupArr[indexPath.row];
    
    if ([group[@"group_status"] intValue]==GroupStatusReady) {
        self.dele.group.groupID=[group[@"group_id"] intValue];
        self.dele.group.groupName=[NSString stringWithFormat:@"%@",group[@"group_name"]];
        self.dele.group.groupStatus=[group[@"group_status"] intValue];
        self.dele.group.groupType=[group[@"group_type"] intValue];
        
        NSDate *date=[NSDate date];
        NSDictionary *dic=@{
                            @"type":[NSNumber numberWithInt:MessageJoinInGroup],
                            @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                            @"groupID":[NSNumber numberWithInt:self.dele.group.groupID],
                            @"groupName":self.dele.group.groupName,
                            @"userID":[NSNumber numberWithInt:self.dele.user.userID],
                            @"userName":self.dele.user.userName
                            };
        NSData *data=[NSData encodeDataForSocket:dic];
        [self.dele.asyncSocket writeData:data withTimeout:-1 tag:MessageJoinInGroup];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"只允许加入已准备" message:nil delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}

#pragma mark - ASConnectionDelegate

-(void)didReadData:(NSData *)jsonData {
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
//    NSLog(@"GroupListController %@",dic);
    
    switch ([dic[@"type"] intValue]) {
        case MessageGetGameGroup:
            if (![dic[@"error"] boolValue]) {
                NSArray *groupList=dic[@"result"];
                [self.groupArr removeAllObjects];
                [self.groupArr addObjectsFromArray:groupList];
                
                [self.groupTable reloadData];
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
        case MessageCreateGroup:
            if (![dic[@"error"] boolValue]) {
                if ([dic[@"result"] intValue]>0) {
                    self.dele.group.groupID=[dic[@"result"] intValue];
                    self.dele.group.groupStatus=GroupStatusReady;
                    self.dele.group.groupType=GroupTypeNormal;
                    
                    self.dele.user.isHost=YES;
                    
                    self.createGroupView.hidden=YES;
                    [self.createGroupName resignFirstResponder];
                    
                    [self goGroupIn];
                    
                    [self.timer setFireDate:[NSDate distantFuture]];
                }else{
                    NSLog(@"insert groupname into mysql error");
                }
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
        case MessageJoinInGroup:
            if (![dic[@"error"] boolValue]) {
                if ([dic[@"result"] intValue]>0) {
                    self.dele.user.isHost=NO;
                    
                    [self goGroupIn];
                    
                    [self.timer setFireDate:[NSDate distantFuture]];
                }else{
                    NSLog(@"insert groupin into mysql error");
                }
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
    }
    
}

@end
