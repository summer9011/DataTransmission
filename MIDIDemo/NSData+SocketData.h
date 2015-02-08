//
//  NSData+SocketData.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/7.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, MessageType){
    MessageUndefind,
    MessageBeginConnect,                                                            //连接服务器
    MessageGetUserList,                                                             //获取用户列表
    MessageInGroup,                                                                 //进入游戏组
    MessageReadyGame,                                                               //开始游戏
    MessageGamingMIDIData,                                                          //发送MIDI
    MessageEndGame,                                                                 //退出游戏
    MessageOutGroup,                                                                //退出游戏组
    MessageEndConnect                                                               //断开服务器
};

typedef NS_ENUM(int, UserPlayStatus){
    UserStatusUndefind,
    UserFree,                                                                       //自由状态
    UserInGroupNotGame,                                                             //进入组状态
    UserInGroupGaming,                                                              //正在游戏状态
    UserInGroupGamed                                                                //游戏结束状态
};

typedef NS_ENUM(int, MusicalType){
    MusicalUndefind,
    MusicalPiano                                                                    //钢琴
};

typedef NS_ENUM(int, MusicalStatus){
    MusicalStatusUndefind,
    MusicalNotConnect,                                                              //乐器未连接
    MusicalConnected                                                                //乐器已连接
};
    
@interface NSData (SocketData)

+(NSData *)encodeDataForSocket:(NSDictionary *)dic;

@end
