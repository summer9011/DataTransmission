//
//  DZQGroup.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DZQGroup : NSObject

@property (nonatomic,assign) int groupID;                       //游戏组id
@property (nonatomic,retain) NSString *groupName;               //游戏组名
@property (nonatomic,assign) GroupStatus groupStatus;           //游戏组状态
@property (nonatomic,assign) GroupType groupType;               //游戏组类型

@end
