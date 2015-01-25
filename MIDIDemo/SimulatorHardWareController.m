//
//  SimulatorHardWareController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/10.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "SimulatorHardWareController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface SimulatorHardWareController () <CBPeripheralManagerDelegate>

@property (nonatomic,strong) CBPeripheralManager *peripheralManager;
@property (nonatomic,strong) CBMutableCharacteristic *customCharacteristic;
@property (nonatomic,strong) CBMutableService *customService;
@property (nonatomic,strong) CBCentral *receiverCentral;

@end

@implementation SimulatorHardWareController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.peripheralManager=[[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

//取消模拟
- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.peripheralManager.delegate=nil;
    self.peripheralManager=nil;
}

//发送数据
- (IBAction)sendData:(id)sender {
    UIButton *button=(UIButton *)sender;
    
    //midi数据
    NSString *resourcePath=[NSString stringWithFormat:@"fpc_DrumAndBass_%ld",(long)button.tag];
    NSString *midiPath=[[NSBundle mainBundle] pathForResource:resourcePath ofType:@"mid"];
    NSData *midiData=[NSData dataWithContentsOfFile:midiPath];
    
    if (self.receiverCentral) {
        [self.peripheralManager updateValue:midiData forCharacteristic:self.customCharacteristic onSubscribedCentrals:@[self.receiverCentral]];
    }else{
        NSLog(@"连接中心后重试");
    }
}

-(void)setupService {
    //创建特征
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    self.customCharacteristic=[[CBMutableCharacteristic alloc] initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    //创建服务
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    self.customService=[[CBMutableService alloc] initWithType:serviceUUID primary:YES];
    //给服务设置特征
    [self.customService setCharacteristics:@[self.customCharacteristic]];
    //发布服务
    [self.peripheralManager addService:self.customService];
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:{
            [self setupService];
        }
            break;
            
        default:{
            NSLog(@"打开蓝牙后重试");
        }
            break;
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"开始广播外设:%@ 错误:%@",peripheral,error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    NSLog(@"外设添加服务:%@ 错误:%@",service,error);
    
    if (!error) {
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey:@"模拟钢琴",CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:kServiceUUID]]}];
    }
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"中央预定该服务");
    
    self.receiverCentral=central;
}


@end
