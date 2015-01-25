//
//  CommunicationController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/10.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "CommunicationController.h"
#import "AppDelegate.h"

@interface CommunicationController () <ASConnectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *hardwareLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerLabel;
@property (weak, nonatomic) IBOutlet UITextView *msgView;

@property (nonatomic,strong) AppDelegate *dele;

@end

@implementation CommunicationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dele=(AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.dele.ASDelegate=self;
    
    self.hardwareLabel.text=self.dele.peripheral.name;
    
    NSMutableString *str=[NSMutableString stringWithFormat:@"%@(自己)",self.dele.ownerID];
    for (NSString *receiver in self.dele.recevierList) {
        [str appendFormat:@",%@",receiver];
    }
    self.playerLabel.text=str;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.dele.ASDelegate=self;
}

//断开
- (IBAction)doDisConnect:(id)sender {
    NSString *str=[NSString stringWithFormat:@"{\"code\":%d,\"msg\":\"%d\",\"clientid\":%d}\n",6,0,[self.dele.recevierList[0] intValue]];
    NSData *data=[str dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.dele.asyncSocket writeData:data withTimeout:-1 tag:6];
    
    [self.dele.heartBeatTimer invalidate];
    [self.dele.recevierList removeAllObjects];
    [self.dele.asyncSocket disconnect];
    
    [self.dele.centralManager cancelPeripheralConnection:self.dele.peripheral];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - ASConnectionDelegate

-(void)didReadData:(NSData *)data {
    NSString *str=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *tempArr=[str componentsSeparatedByString:@"\n"];
    
    NSMutableArray *strArr=[tempArr mutableCopy];
    [strArr removeLastObject];
    
    for (NSString *str in strArr) {
        NSLog(@"%@",str);
        
        NSError *error;
        NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
        
        switch ([dic[@"code"] intValue]) {
            case 5:{            //发送数据
                NSDate *current=[NSDate date];
                double diff=current.timeIntervalSince1970-[dic[@"clickTime"] doubleValue];
                
                NSString *oldStr=self.msgView.text;
                if ([oldStr isEqualToString:@""]) {
                    self.msgView.text=[NSString stringWithFormat:@"(%@,%f)",dic[@"msg"],diff];
                }else{
                    self.msgView.text=[NSString stringWithFormat:@"%@;(%@,%f)",oldStr,dic[@"msg"],diff];
                }
                
                NSData *midiData=[[NSData alloc] initWithBase64EncodedString:dic[@"msg"] options:0];
                
                [self.dele.midiPlayer playMIDIData:midiData];
                
            }
                break;
            case 6:{            //一方退出
                if (dic[@"clientid"]) {
                    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"ID:%@ 已退出",dic[@"clientid"]] message:@"队友都走了，你还留着干什么？" delegate:self cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
                    [alert show];
                }
                
            }
                break;
        }
    }
}

-(void)didSendData:(NSData *)data FromPeripheral:(CBPeripheral *)peripheral {
    NSString *temp=[data base64EncodedStringWithOptions:0];
    
    NSDate *currentDate=[NSDate date];
    
    NSString *str=[NSString stringWithFormat:@"{\"code\":%d,\"msg\":\"%@\",\"clientid\":%d,\"clickTime\":%f}\n",5,temp,[self.dele.recevierList[0] intValue],currentDate.timeIntervalSince1970];
    NSData *strData=[str dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.dele.asyncSocket writeData:strData withTimeout:-1 tag:5];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.dele.recevierList removeAllObjects];
    [self.dele.heartBeatTimer invalidate];
    
    self.msgView=nil;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
