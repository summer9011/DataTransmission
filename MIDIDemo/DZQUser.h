//
//  DZQUser.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DZQUser : NSObject

@property (nonatomic,assign) int userSessionID;                 //用户session
@property (nonatomic,assign) int userID;                        //用户数据库中id
@property (nonatomic,strong) NSString *userUUID;                //用户唯一标识
@property (nonatomic,strong) NSString *userName;                //用户名

@property (nonatomic,assign) BOOL isHost;                       //是否为游戏房主

@end
