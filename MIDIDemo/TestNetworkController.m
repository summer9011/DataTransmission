//
//  TestNetworkController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/1.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "TestNetworkController.h"
#import "AppDelegate.h"

@interface TestNetworkController () <ASConnectionDelegate>

@property (nonatomic,strong) AppDelegate *dele;

@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UILabel *startTime;
@property (weak, nonatomic) IBOutlet UILabel *endTime;
@property (weak, nonatomic) IBOutlet UILabel *diffTime;
@property (weak, nonatomic) IBOutlet UITableView *table;

@property (nonatomic,strong) NSMutableArray *playerArr;

@property (nonatomic,assign) int countData;

@end

static NSString *CellIdentifier=@"ChoosePlayerCell";

@implementation TestNetworkController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.table.tableFooterView=[[UIView alloc] init];
    
    self.playerArr=[NSMutableArray array];
    self.countData=1;
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.dele.ASDelegate=self;
    
    self.dele.asyncSocket=[[AsyncSocket alloc] initWithDelegate:self.dele];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=self;
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [SVProgressHUD showWithStatus:@"连接网络..." maskType:SVProgressHUDMaskTypeClear];
    
    NSError *error;
    if (![self.dele.asyncSocket connectToHost:IP onPort:PORT error:&error]) {
        [SVProgressHUD dismissWithError:[NSString stringWithFormat:@"连接失败 %@",error] afterDelay:2.f];
        NSLog(@"error %@",error);
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=nil;
    }
}

- (IBAction)goBack:(id)sender {
    
    if (self.dele.recevierList.count>0) {
        NSString *str=[NSString stringWithFormat:@"{\"code\":%d,\"msg\":\"%d\",\"clientid\":%d}\n",6,0,[self.dele.recevierList[0] intValue]];
        NSData *data=[str dataUsingEncoding:NSUTF8StringEncoding];
        [self.dele.asyncSocket writeData:data withTimeout:-1 tag:6];
    }
    
    [self.dele.heartBeatTimer invalidate];
    [self.dele.recevierList removeAllObjects];
    [self.dele.asyncSocket disconnect];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doSend:(id)sender {
    NSDate *currentDate=[NSDate date];
    
    if (self.dele.recevierList.count>0) {
        NSString *str=[NSString stringWithFormat:@"{\"code\":%d,\"msg\":\"%@发送%d\",\"clientid\":%d,\"clickTime\":%f}\n",5,self.dele.ownerID,self.countData,[self.dele.recevierList[0] intValue],currentDate.timeIntervalSince1970];
        NSData *strData=[str dataUsingEncoding:NSUTF8StringEncoding];
        
        [self.dele.asyncSocket writeData:strData withTimeout:-1 tag:5];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"选择一个接收者" message:nil delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    self.countData++;
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
        
        NSString *str=[NSString stringWithFormat:@"{\"code\":%d,\"msg\":\"%@\",\"clientid\":%d}\n",4,@"",[cell.textLabel.text intValue]];
        NSData *data=[str dataUsingEncoding:NSUTF8StringEncoding];
        
        [self.dele.asyncSocket writeData:data withTimeout:-1 tag:3];
    }else{
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"不能和自己发送消息" message:nil delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}

#pragma mark - ASConnectionDelegate

-(void)didConnectedAsyncSocket {
    [SVProgressHUD dismissWithSuccess:@"连接成功"];
    NSLog(@"成功连接到Socket");
}

-(void)didReadData:(NSData *)jsonData {
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    NSLog(@"dic %@",dic);
    
    
    switch ([dic[@"code"] intValue]) {
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
        }
            break;
        case 5:{            //发送数据
            NSDate *current=[NSDate date];
            double diff=current.timeIntervalSince1970-[dic[@"clickTime"] doubleValue];
            
            self.dataLabel.text=[NSString stringWithFormat:@"%@",dic[@"msg"]];
            self.startTime.text=[NSString stringWithFormat:@"%fs",[dic[@"clickTime"] doubleValue]];
            self.endTime.text=[NSString stringWithFormat:@"%fs",current.timeIntervalSince1970];
            self.diffTime.text=[NSString stringWithFormat:@"%fms",diff*1000];
        }
            break;
        case 6:{            //一方退出
            if (dic[@"clientid"]) {
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"ID:%@ 已退出",dic[@"clientid"]] message:@"队友都走了，你还留着干什么？" delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
                [alert show];
            }
            
        }
            break;
    }
    
}

@end
