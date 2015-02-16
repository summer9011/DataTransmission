//
//  AppDelegate.m
//  MIDIDemo
//
//  Created by 赵立波 on 14/12/14.
//  Copyright (c) 2014年 赵立波. All rights reserved.
//

#import "AppDelegate.h"
#import "CustomURLCache.h"

@interface AppDelegate ()

@property (nonatomic,strong)NSMutableData *receivedData;    //接收到的消息的二进制流
@property (nonatomic,assign)int dataLength;                 //一条消息的长度

@end

@implementation AppDelegate
@synthesize heartBeatTimer,midiPlayer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //设置应用保持常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [NSURLCache setSharedURLCache:[[CustomURLCache alloc] init]];
    self.recevierList=[NSMutableArray array];
    [self clearReceivedData];
    
    self.user=[[DZQUser alloc] init];
    self.user.userUUID=[[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    self.group=[[DZQGroup alloc] init];
    
    self.midiPlayer=[[PlayMIDI alloc] initWithHTML5];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"applicationDidEnterBackground");
    /*
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageQuitApp],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"userID":[NSNumber numberWithInt:self.user.userID]
                        };
    NSData *sendData=[NSData encodeDataForSocket:dic];
    [self.asyncSocket writeData:sendData withTimeout:-1 tag:MessageQuitApp];
    */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

-(void)clearReceivedData {
    if (!self.receivedData) {
        self.receivedData=[NSMutableData data];
    }
    
    //清空
    [self.receivedData resetBytesInRange:NSMakeRange(0, [self.receivedData length])];
    [self.receivedData setLength:0];
    self.dataLength=0;
}

-(void)startScanForPeripheral {
    [SVProgressHUD showWithStatus:@"正在查找硬件.." maskType:SVProgressHUDMaskTypeClear];
    
    //搜寻所有的服务
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:{
            [self startScanForPeripheral];
        }
            break;
            
        default:{
            [SVProgressHUD showErrorWithStatus:@"打开蓝牙后重试"];
        }
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if ([self.CBDelegate respondsToSelector:@selector(didFindPeripheral:)]) {
        [self.CBDelegate didFindPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self.discoveredPeripheral setDelegate:self];
    //请求外设寻找服务
    [self.discoveredPeripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
    
    if ([self.CBDelegate respondsToSelector:@selector(didConnectedPeripheral)]) {
        [self.CBDelegate didConnectedPeripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"连接失败" message:[NSString stringWithFormat:@"%@",error] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self startScanForPeripheral];
    
    if ([self.CBDelegate respondsToSelector:@selector(didDisConnectedPeripheral)]) {
        [self.CBDelegate didDisConnectedPeripheral];
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error discovering service" message:[NSString stringWithFormat:@"%@",[error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            self.discoveredService=service;
            [service.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kReadCharacteristicUUID],[CBUUID UUIDWithString:kWriteCharacteristicUUID]] forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error discovering characteristic" message:[NSString stringWithFormat:@"%@",[error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if (self.discoveredService&&[service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            //发现读特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kReadCharacteristicUUID]]) {
                self.discoveredReadCharacteristic=characteristic;
                self.canRead=YES;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            //发现写特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kWriteCharacteristicUUID]]) {
                //发现读特征
                self.discoveredWriteCharacteristic=characteristic;
                self.canWrite=YES;
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kReadCharacteristicUUID]]) {
        return;
    }
    
    if (characteristic.value) {
        if ([self.ASDelegate respondsToSelector:@selector(didSendData:FromPeripheral:)]) {
            [self.ASDelegate didSendData:characteristic.value FromPeripheral:peripheral];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error change notification state" message:[NSString stringWithFormat:@"%@",[error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kReadCharacteristicUUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    }else{
        [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    }
}

#pragma mark - AsyncSocketDelegate

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    if ([self.ASDelegate respondsToSelector:@selector(didDisConnectedAsyncSocket)]) {
        [self.ASDelegate didDisConnectedAsyncSocket];
    }
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    if ([self.ASDelegate respondsToSelector:@selector(didConnectedAsyncSocket)]) {
        [self.ASDelegate didConnectedAsyncSocket];
    }
    
    [sock readDataToLength:sizeof(int) withTimeout:-1 tag:1];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    int receviedLength=0;
    if (self.dataLength==0) {
        [data getBytes:&receviedLength length:sizeof(int)];
        self.dataLength=receviedLength-4;           //数据的长度=总长度-首部4字节
        
        [sock readDataToLength:self.dataLength withTimeout:-1 tag:tag];
    }else {
        if (self.receivedData.length<self.dataLength) {
            [self.receivedData appendData:data];
            int leftLength=self.dataLength-(int)self.receivedData.length;
            if (leftLength>0) {
                [sock readDataToLength:leftLength withTimeout:-1 tag:tag];
            }else if (leftLength==0) {
                if ([self.ASDelegate respondsToSelector:@selector(didReadData:)]) {
                    [self.ASDelegate didReadData:self.receivedData];
                }
                
                [self clearReceivedData];
                [sock readDataToLength:sizeof(int) withTimeout:-1 tag:tag];
            }
        }else{
            if ([self.ASDelegate respondsToSelector:@selector(didReadData:)]) {
                [self.ASDelegate didReadData:self.receivedData];
            }
            
            [self clearReceivedData];
            [sock readDataToLength:sizeof(int) withTimeout:-1 tag:tag];
        }
    }
}

-(void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    [sock readDataToLength:partialLength withTimeout:-1 tag:tag];
}

@end
