//
//  DZQUser.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DZQUser : NSObject

@property (nonatomic,assign) int userSessionID;
@property (nonatomic,assign) int userID;
@property (nonatomic,strong) NSString *userUUID;
@property (nonatomic,strong) NSString *userName;

@property (nonatomic,assign) BOOL isHost;

@end
