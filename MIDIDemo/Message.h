//
//  Message.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/7.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

@property(nonatomic,assign) int code;
@property(nonatomic,strong) NSString *msg;
@property(nonatomic,assign) int clientid;

@property(nonatomic,assign) double clicktime;

@end
