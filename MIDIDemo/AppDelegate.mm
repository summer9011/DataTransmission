//
//  AppDelegate.m
//  MIDIDemo
//
//  Created by 赵立波 on 14/12/14.
//  Copyright (c) 2014年 赵立波. All rights reserved.
//

#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>

#import "ReadMini.h"

@interface AppDelegate () {
    SystemSoundID soundID;
}

@end

@implementation AppDelegate
@synthesize ownerID,heartBeatTimer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.recevierList=[NSMutableArray array];
    
    //设置应用保持常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //读取MIDI文件
    NSString *path=[[NSBundle mainBundle] pathForResource:@"clap" ofType:@"mid"];
    [ReadMini readMIDIFile:path];
    
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

//播放音效
-(void)playSound:(NSString *)latter {
    NSString *path = [[NSBundle mainBundle] pathForResource:latter ofType:@"wav"];
    if (path) {
        SystemSoundID theSoundID;
        OSStatus error =  AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &theSoundID);
        if (error == kAudioServicesNoError) {
            soundID = theSoundID;
        }else {
            NSLog(@"Failed to create sound ");
        }
    }else{
        NSLog(@"no wav file :%@",latter);
    }
    
    AudioServicesPlaySystemSound(soundID);
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
    
    [self.peripheral setDelegate:self];
    
    //请求外设寻找服务
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
    
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
        NSLog(@"找到的serviceUUID %@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            [service.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicUUID]] forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error discovering characteristic" message:[NSString stringWithFormat:@"%@",[error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
        return;
    }
    
    NSString *data=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    if (data&&![data isEqualToString:@""]) {
        if ([self.ASDelegate respondsToSelector:@selector(didSendData:FromPeripheral:)]) {
            [self.ASDelegate didSendData:data FromPeripheral:peripheral];
        }
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"特征 %@ 更新了值 错误 %@",characteristic,error);
    if (error) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"Error change notification state" message:[NSString stringWithFormat:@"%@",[error localizedDescription]] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
        return;
    }
    
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@",characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    }else{
        NSLog(@"Notification stopped on %@ disconnecting",characteristic);
        [self.centralManager cancelPeripheralConnection:self.peripheral];
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
    
    heartBeatTimer=[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    [heartBeatTimer fire];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if ([self.ASDelegate respondsToSelector:@selector(didReadData:)]) {
        [self.ASDelegate didReadData:data];
    }
    
    [sock readDataWithTimeout:-1 tag:tag];
}


@end
