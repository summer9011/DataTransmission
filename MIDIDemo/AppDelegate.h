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
#import "DZQUser.h"
#import "DZQGroup.h"

@protocol CBConnectionDelegate <NSObject>

@required

//找到外设
-(void)didFindPeripheral:(CBPeripheral *)peripheral;

//成功连接连接到外设
-(void)didConnectedPeripheral;

//连接外设失败
-(void)didDisConnectedPeripheral;

@end

@protocol ASConnectionDelegate <NSObject>

@required
//从socket中读取数据
-(void)didReadData:(NSData *)jsonData;

@optional
//连接到asyncSocket
-(void)didConnectedAsyncSocket;

//断开连接
-(void)didDisConnectedAsyncSocket;

//向另一方发送数据
-(void)didSendData:(NSData *)data FromPeripheral:(CBPeripheral *)peripheral;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate,CBCentralManagerDelegate,CBPeripheralDelegate,AsyncSocketDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,strong) CBCentralManager *centralManager;

@property (nonatomic,strong) CBPeripheral *discoveredPeripheral;
@property (nonatomic,strong) CBService *discoveredService;
@property (nonatomic,strong) CBCharacteristic *discoveredReadCharacteristic;
@property (nonatomic,assign) BOOL canRead;
@property (nonatomic,strong) CBCharacteristic *discoveredWriteCharacteristic;
@property (nonatomic,assign) BOOL canWrite;

@property (nonatomic,strong) id<CBConnectionDelegate> CBDelegate;

@property (nonatomic,strong) AsyncSocket *asyncSocket;
@property (nonatomic,strong) id<ASConnectionDelegate> ASDelegate;

@property (nonatomic,strong) NSMutableArray *recevierList;
@property (nonatomic,strong) NSTimer *heartBeatTimer;

@property (nonatomic,strong) PlayMIDI *midiPlayer;

@property (nonatomic,strong) NSString *cachePath;

@property (nonatomic,strong) DZQUser *user;
@property (nonatomic,strong) DZQGroup *group;

@end

