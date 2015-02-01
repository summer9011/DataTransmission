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

@end

@implementation AppDelegate
@synthesize ownerID,heartBeatTimer,midiPlayer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.recevierList=[NSMutableArray array];
    
    [NSURLCache setSharedURLCache:[[CustomURLCache alloc] init]];
    
    //设置应用保持常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    midiPlayer=[[PlayMIDI alloc] initWithHTML5];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

//心跳检测
-(void)longConnectToSocket {
    NSString *str=[NSString stringWithFormat:@"{\"code\":%d,\"msg\":\"%@\",\"clientid\":%d}\n",2,@"",0];
    NSData *data=[str dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.asyncSocket writeData:data withTimeout:-1 tag:2];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:{
            //搜寻所有的服务
            [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        }
            break;
            
        default:{
            NSLog(@"打开蓝牙后重试");
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
    NSLog(@"成功连接到外设:%@",peripheral);
    
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
    NSLog(@"断开与外设:%@ 的连接 错误:%@",peripheral,error);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error discovering service" message:[NSString stringWithFormat:@"%@",[error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            NSLog(@"serviceUUID %@",service.UUID);
            
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
                NSLog(@"readCharacteristic %@",characteristic.UUID);
                self.discoveredReadCharacteristic=characteristic;
                self.canRead=YES;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            //发现写特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kWriteCharacteristicUUID]]) {
                NSLog(@"writeCharacteristic %@",characteristic.UUID);
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

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@",characteristic.UUID);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"特征 %@ 更新了值 错误 %@",characteristic,error);
    if (error) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error change notification state" message:[NSString stringWithFormat:@"%@",[error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kReadCharacteristicUUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@",characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    }else{
        NSLog(@"Notification stopped on %@ disconnecting",characteristic);
        [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    }
}

#pragma mark - AsyncSocketDelegate

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    NSLog(@"断开连接");
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    if ([self.ASDelegate respondsToSelector:@selector(didConnectedAsyncSocket)]) {
        [self.ASDelegate didConnectedAsyncSocket];
    }
    
    [sock readDataWithTimeout:-1 tag:1];
    
    heartBeatTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    [heartBeatTimer fire];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if ([self.ASDelegate respondsToSelector:@selector(didReadData:)]) {
        [self.ASDelegate didReadData:data];
    }
    
    [sock readDataWithTimeout:-1 tag:tag];
}


@end
