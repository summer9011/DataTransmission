//
//  DZQGroup.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/15.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DZQGroup : NSObject

@property (nonatomic,assign) int groupID;
@property (nonatomic,retain) NSString *groupName;
@property (nonatomic,assign) GroupStatus groupStatus;
@property (nonatomic,assign) GroupType groupType;

@end
