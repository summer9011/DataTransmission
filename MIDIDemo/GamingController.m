//
//  GamingController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "GamingController.h"
#import "AppDelegate.h"

@interface GamingController () <ASConnectionDelegate>

@property (weak, nonatomic) IBOutlet UIView *showView;

@property (nonatomic,strong) AppDelegate *dele;

@end

@implementation GamingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=self;
    }
    
    [self.showView addSubview:self.dele.midiPlayer.midiWeb];
    self.dele.midiPlayer.midiWeb.frame=CGRectMake(0, 0, self.showView.frame.size.width, self.showView.frame.size.height);
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.dele.asyncSocket) {
        self.dele.ASDelegate=nil;
    }
    
    [self.dele.midiPlayer.midiWeb removeFromSuperview];
}

//模拟发送数据
- (IBAction)similarSendData:(id)sender {
    NSString *tempPath=[[NSBundle mainBundle] pathForResource:@"fpc_DrumAndBass_1" ofType:@"mid"];
    NSData *data=[NSData dataWithContentsOfFile:tempPath];
    
    [self didSendData:data FromPeripheral:nil];
}

- (IBAction)quitGame:(id)sender {
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageQuitGame],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"userID":[NSNumber numberWithInt:self.dele.user.userID],
                        @"userName":self.dele.user.userName,
                        @"groupID":[NSNumber numberWithInt:self.dele.group.groupID]
                        };
    NSData *sendData=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:sendData withTimeout:-1 tag:MessageQuitGame];
}

#pragma mark - ASConnectionDelegate

-(void)didReadData:(NSData *)jsonData {
    NSError *error;
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
    NSLog(@"GamingController %@",dic);
    
    switch ([dic[@"type"] intValue]) {
        case MessageSendData:
            if (![dic[@"error"] boolValue]) {
                NSString *base64MIDIStr=[NSString stringWithFormat:@"%@",dic[@"result"]];
                NSData *midiData=[[NSData alloc] initWithBase64EncodedString:base64MIDIStr options:0];
                
                //播放MIDI
                [self.dele.midiPlayer playMIDIData:midiData];
                
                //向设备发送MIDI
                [self.dele.discoveredPeripheral writeValue:midiData forCharacteristic:self.dele.discoveredWriteCharacteristic type:CBCharacteristicWriteWithoutResponse];
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
        case MessageQuitGame:
            if (![dic[@"error"] boolValue]) {
                NSDictionary *result=dic[@"result"];
                if ([result[@"userID"] intValue]==self.dele.user.userID) {
                    NSArray *viewControllerArr=self.navigationController.viewControllers;
                    
                    [self.navigationController popToViewController:viewControllerArr[1] animated:YES];
                }else{
                    NSString *msg=[NSString stringWithFormat:@"%@退出游戏",result[@"userName"]];
                    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"通知" message:msg delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
                    [alert show];
                }
            }else{
                NSLog(@"error %@",dic[@"result"]);
            }
            break;
    }
    
}

-(void)didSendData:(NSData *)data FromPeripheral:(CBPeripheral *)peripheral {
    NSString *base64Data=[data base64EncodedStringWithOptions:0];
    
    NSDate *date=[NSDate date];
    NSDictionary *dic=@{
                        @"type":[NSNumber numberWithInt:MessageSendData],
                        @"triggerTime":[NSNumber numberWithDouble:date.timeIntervalSince1970],
                        @"userID":[NSNumber numberWithInt:self.dele.user.userID],
                        @"groupID":[NSNumber numberWithInt:self.dele.group.groupID],
                        @"base64MIDiData":base64Data
                        };
    NSData *sendData=[NSData encodeDataForSocket:dic];
    [self.dele.asyncSocket writeData:sendData withTimeout:-1 tag:MessageSendData];
}

@end
