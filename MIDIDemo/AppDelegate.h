//
//  AppDelegate.h
//  MIDIDemo
//
//  Created by 赵立波 on 14/12/14.
//  Copyright (c) 2014年 赵立波. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "AsyncSocket.h"
#import "PlayMIDI.h"

@protocol CBConnectionDelegate <NSObject>

@required

//找到外设
-(void)didFindPeripheral:(CBPeripheral *)peripheral;

//成功连接连接到外设
-(void)didConnectedPeripheral;

@end

@protocol ASConnectionDelegate <NSObject>

@required
//从socket中读取数据
-(void)didReadData:(NSData *)data;

@optional
#pragma mark - ChoosePlayerController必须实现
//连接到asyncSocket
-(void)didConnectedAsyncSocket;

#pragma mark - CommunicationController必须实现
//向另一方发送数据
-(void)didSendData:(NSString *)data FromPeripheral:(CBPeripheral *)peripheral;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate,CBCentralManagerDelegate,CBPeripheralDelegate,AsyncSocketDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,strong) CBCentralManager *centralManager;
@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) id<CBConnectionDelegate> CBDelegate;

@property (nonatomic,strong) AsyncSocket *asyncSocket;
@property (nonatomic,strong) id<ASConnectionDelegate> ASDelegate;

@property (nonatomic,strong) NSString *ownerID;
@property (nonatomic,strong) NSMutableArray *recevierList;
@property (nonatomic,strong) NSTimer *heartBeatTimer;

@property (nonatomic,strong) PlayMIDI *midiPlayer;

@end

