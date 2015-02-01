//
//  WriteValeController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/31.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "WriteValeController.h"

#import "AppDelegate.h"

@interface WriteValeController () <CBConnectionDelegate,ASConnectionDelegate>

@property (nonatomic,strong) AppDelegate *dele;

@end

@implementation WriteValeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.dele.CBDelegate=self;
    self.dele.ASDelegate=self;
    
    [self.view addSubview:self.dele.midiPlayer.midiWeb];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.dele.CBDelegate=nil;
    self.dele.ASDelegate=nil;
    self.dele=nil;
}

- (IBAction)goBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)writeToPeripheral:(id)sender {
    if (self.dele.canWrite) {
        NSDate *current=[NSDate date];
        NSString *str=[NSString stringWithFormat:@"%f",current.timeIntervalSince1970];
        
        NSLog(@"canWrite Data %@",str);
        
        [self.dele.discoveredPeripheral writeValue:[str dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.dele.discoveredWriteCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (IBAction)playMIDI:(id)sender {
    NSString *temp=[[NSBundle mainBundle] pathForResource:@"fpc_DrumAndBass_10" ofType:@"mid"];
    NSData *tempData=[NSData dataWithContentsOfFile:temp];

    [self.dele.midiPlayer playMIDIData:tempData];
}

-(void)connectToPeripheral {
    NSLog(@"%@",self.dele.discoveredPeripheral);
    if (self.dele.discoveredPeripheral) {
        [self.dele.centralManager stopScan];
        [self.dele.centralManager connectPeripheral:self.dele.discoveredPeripheral options:nil];
    }
}

#pragma mark - CBConnectionDelegate

-(void)didFindPeripheral:(CBPeripheral *)peripheral {
    self.dele.discoveredPeripheral=peripheral;
    [self connectToPeripheral];
}

-(void)didConnectedPeripheral {
    NSLog(@"已连接到外设");
}

#pragma mark - ASConnectionDelegate

//向另一方发送数据
-(void)didSendData:(NSData *)data FromPeripheral:(CBPeripheral *)peripheral {
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"外设传过来的数据" message:[NSString stringWithFormat:@"%@",data] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
    [alert show];
}

-(void)didReadData:(NSData *)data {
    NSLog(@"从网络过来的数据");
}

@end
