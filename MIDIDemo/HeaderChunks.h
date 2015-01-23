//
//  HeaderChunks.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/21.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HeaderChunks : NSObject

@property (nonatomic,assign) void *midiId;
@property (nonatomic,assign) int length;
@property (nonatomic,assign) int format;
@property (nonatomic,assign) int trackNumber;
@property (nonatomic,assign) int midiTimeSet;

@end
