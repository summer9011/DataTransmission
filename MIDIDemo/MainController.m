//
//  MainController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/14.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "MainController.h"
#import "AppDelegate.h"

#import "SimulatorHardWareController.h"

@interface MainController () <CBConnectionDelegate,ASConnectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *musicalStatus;
@property (weak, nonatomic) IBOutlet UILabel *networkStatus;
@property (weak, nonatomic) IBOutlet UILabel *midiPlayerStatus;

@property (nonatomic,assign) BOOL isMusicalReady;
@property (nonatomic,assign) BOOL isNetworkReady;
@property (nonatomic,assign) BOOL isMIDIPlayerReady;

@property (weak, nonatomic) IBOutlet UIButton *goGroupBtn;

//Register
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UIButton *registerBtn;

@property (nonatomic,strong) AppDelegate *dele;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation MainController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.isMusicalReady=NO;
    self.isNetworkReady=NO;
    self.isMIDIPlayerReady=NO;
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //开启搜索设备
    self.dele.CBDelegate=self;
    self.dele.centralManager=[[CBCentralManager alloc] initWithDelegate:self.dele queue:nil];
    
    //开启连接网络
    self.dele.ASDelegate=self;
    self.dele.asyncSocket=[[AsyncSocket alloc] initWithDelegate:self.dele];
    
    //测试
    [self didConnectedPeripheral];
    
    self.timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkAllStatus) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initMIDIPlayerSuccess) name:MIDIPlayerSuccess object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initMIDIPlayerFailed) name:MIDIPlayerFailed object:nil];
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

//判断三种状态是否都已准备就绪
-(void)checkAllStatus {
    if (self.isMusicalReady&&self.isNetworkReady&&self.isMIDIPlayerReady) {
        self.goGroupBtn.enabled=YES;
        
        [self.timer invalidate];
    }else {
        self.goGroupBtn.enabled=NO;
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

//进入游戏组
- (IBAction)goToGroupView:(id)sender {
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageUserLogin],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"userIdentifier":[[[UIDevice currentDevice] identifierForVendor] UUIDString]
                        };
    NSData *data=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:1];
}


#pragma mark - CBConnectionDelegate

-(void)didFindPeripheral:(CBPeripheral *)peripheral {
    [self.dele.centralManager stopScan];
    self.dele.discoveredPeripheral=peripheral;
    [self.dele.centralManager connectPeripheral:self.dele.discoveredPeripheral options:nil];
}

-(void)didConnectedPeripheral {
    self.musicalStatus.text=@"成功";
    self.musicalStatus.textColor=[UIColor greenColor];
    self.isMusicalReady=YES;
    
    //连接设备成功后连接网络
    NSError *error;
    if (![self.dele.asyncSocket connectToHost:IP onPort:PORT error:&error]) {
        [SVProgressHUD showErrorWithStatus:@"无法连接到网络"];
    }
}

-(void)didDisConnectedPeripheral {
    self.musicalStatus.text=@"失败";
    self.musicalStatus.textColor=[UIColor redColor];
    self.isMusicalReady=NO;
}

#pragma mark - ASConnectionDelegate

-(void)didConnectedAsyncSocket { 
    self.networkStatus.text=@"成功";
    self.networkStatus.textColor=[UIColor greenColor];
    self.isNetworkReady=YES;
}

-(void)didDisConnectedAsyncSocket {
    self.networkStatus.text=@"失败";
    self.networkStatus.textColor=[UIColor redColor];
    self.isNetworkReady=NO;
}

-(void)didReadData:(NSData *)jsonData {
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    
    switch ([dic[@"type"] intValue]) {
        case MessageUserLogin:
            if (![dic[@"error"] boolValue]) {
                NSLog(@"%@",dic[@"result"]);
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
    }
    
}

#pragma mark - NSNotification

-(void)initMIDIPlayerSuccess {
    self.midiPlayerStatus.text=@"成功";
    self.midiPlayerStatus.textColor=[UIColor greenColor];
    self.isMIDIPlayerReady=YES;
}

-(void)initMIDIPlayerFailed {
    self.midiPlayerStatus.text=@"失败";
    self.midiPlayerStatus.textColor=[UIColor redColor];
    self.isMIDIPlayerReady=NO;
}

@end
