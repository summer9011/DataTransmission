//
//  ChooseHardWareController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/10.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "ChooseHardWareController.h"
#import "SimulatorHardWareController.h"
#import "CommunicationController.h"
#import "AppDelegate.h"

@interface ChooseHardWareController () <CBConnectionDelegate,ASConnectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *userNameText;

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (nonatomic,strong) NSMutableArray *playerArr;

@property (nonatomic,strong) AppDelegate *dele;

@end

static NSString *CellIdentifier=@"ChoosePlayerCell";

@implementation ChooseHardWareController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden=YES;
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //开启搜索设备
    self.dele.CBDelegate=self;
    self.dele.centralManager=[[CBCentralManager alloc] initWithDelegate:self.dele queue:nil];
    
    //开启连接网络
    self.dele.ASDelegate=self;
    self.dele.asyncSocket=[[AsyncSocket alloc] initWithDelegate:self.dele];
    
    //初始化用户Table
    self.playerArr=[NSMutableArray array];
    
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.table.tableFooterView=[[UIView alloc] init];
    
    //测试
    [self didConnectedPeripheral];
    
//    //获取用户名
//    NSUserDefaults *userInfo=[NSUserDefaults standardUserDefaults];
//    if ([userInfo objectForKey:UserNameKey]) {
//        NSString *str=[userInfo objectForKey:UserNameKey];
//    }else{
//        
//    }
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

//进入模拟
- (IBAction)goSimulatorHardWare:(id)sender {
    self.dele.centralManager.delegate=nil;
    
    if (self.dele.discoveredPeripheral) {
        self.dele.discoveredPeripheral.delegate=nil;
        self.dele.discoveredPeripheral=nil;
    }
    
    UIStoryboard *story=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SimulatorHardWareController *simulatorVC=[story instantiateViewControllerWithIdentifier:@"SimulatorVC"];
    
    [self presentViewController:simulatorVC animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.playerArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *ID=[NSString stringWithFormat:@"%@",self.playerArr[indexPath.row]];
    
    if ([self.dele.ownerID isEqualToString:ID]) {
        cell.textLabel.textColor=[UIColor redColor];
        cell.textLabel.text=[NSString stringWithFormat:@"%@ (自己)",ID];
    }else{
        cell.textLabel.textColor=[UIColor blackColor];
        cell.textLabel.text=ID;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    
    if ([self.dele.ownerID intValue]!=[cell.textLabel.text intValue]) {
        [self.dele.recevierList removeAllObjects];
        [self.dele.recevierList addObject:cell.textLabel.text];
        
        NSString *str=[NSString stringWithFormat:@"{\"code\":%d,\"msg\":\"%@\",\"clientid\":%d}",4,@"",[cell.textLabel.text intValue]];
        NSData *data=[NSData encodeDataForSocket:str];
        [self.dele.asyncSocket writeData:data withTimeout:-1 tag:3];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"不能和自己发送消息" message:nil delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}

#pragma mark - CBConnectionDelegate

-(void)didFindPeripheral:(CBPeripheral *)peripheral {
    [self.dele.centralManager stopScan];
    self.dele.discoveredPeripheral=peripheral;
    [self.dele.centralManager connectPeripheral:self.dele.discoveredPeripheral options:nil];
}

-(void)didConnectedPeripheral {
    //连接设备成功后连接网络
    NSError *error;
    if (![self.dele.asyncSocket connectToHost:IP onPort:PORT error:&error]) {
        [SVProgressHUD showErrorWithStatus:@"无法连接到网络"];
    }
}

#pragma mark - ASConnectionDelegate

-(void)didConnectedAsyncSocket {
    //获取用户是否已存在
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageBeginConnect],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"currentUserID":@0,
                        @"currentName":@"",
                        @"currentUserIdentifier":[[[UIDevice currentDevice] identifierForVendor] UUIDString],
                        @"currentUserPlayStatus":[NSNumber numberWithInt:UserFree],
                        @"currentUserMusical":[NSNumber numberWithInt:MusicalStatusUndefind],
                        @"currentGroupID":@0,
                        @"currentGroupName":@"",
                        @"currentGroupUsers":[NSArray array]
                        };
    NSData *data=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:1];
}

-(void)didReadData:(NSData *)jsonData {
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    NSLog(@"dic %@",dic);
    
    switch ([dic[@"type"] intValue]) {
        case 1:             //获取欢迎
            self.dele.ownerID=[NSString stringWithFormat:@"%@",dic[@"currentid"]];
            
            break;
        case 2:{            //获取用户列表
            NSArray *arr=dic[@"msg"];
            
            [self.playerArr removeAllObjects];
            [self.playerArr addObjectsFromArray:arr];
            
            [self.table reloadData];
        }
            break;
        case 4:{            //建立聊天窗口
            if (dic[@"from"]) {
                [self.dele.recevierList removeAllObjects];
                [self.dele.recevierList addObject:[NSString stringWithFormat:@"%@",dic[@"from"]]];
            }
            
            UIStoryboard *story=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
            CommunicationController *communicationVC=[story instantiateViewControllerWithIdentifier:@"CommunicationVC"];
            
            [self.navigationController pushViewController:communicationVC animated:YES];
        }
            break;
    }
    
}

@end
