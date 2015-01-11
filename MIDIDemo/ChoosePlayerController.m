//
//  ChoosePlayerController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/10.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "ChoosePlayerController.h"
#import "AppDelegate.h"
#import "CommunicationController.h"

@interface ChoosePlayerController () <ASConnectionDelegate>

@property (weak, nonatomic) IBOutlet UITextField *IPText;
@property (weak, nonatomic) IBOutlet UITextField *Porttext;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (nonatomic,strong) NSMutableArray *playerArr;

@property (nonatomic,strong) AppDelegate *dele;

@end

static NSString *CellIdentifier=@"ChoosePlayerCell";

@implementation ChoosePlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    self.table.tableFooterView=[[UIView alloc] init];
    
    self.playerArr=[NSMutableArray array];
    
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

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=nil;
    }
}

//连接
- (IBAction)doConnect:(id)sender {
    NSString *ip;
    short port;
    
    if (self.IPText.text&&self.Porttext.text&&![self.IPText.text isEqualToString:@""]&&![self.Porttext.text isEqualToString:@""]) {
        ip=self.IPText.text;
        port=[self.Porttext.text intValue];
    }else{
        ip=IP;
        port=PORT;
    }
    
    NSError *error;
    if (![self.dele.asyncSocket connectToHost:ip onPort:port error:&error]) {
        NSLog(@"error %@",error);
    }
    
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
    NSLog(@"成功连接到Socket");
    
    self.connectBtn.enabled=NO;
}

-(void)didReadData:(NSData *)data {
    
    NSString *str=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"ChoosePlayerController %@",str);
    
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    switch ([dic[@"code"] intValue]) {
        case 1:             //获取欢迎
            self.dele.ownerID=dic[@"currentid"];
            
            break;
        case 2:{            //获取用户列表
            dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
            NSArray *arr=[NSJSONSerialization JSONObjectWithData:[dic[@"msg"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            
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
