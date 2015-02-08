//
//  NSData+SocketData.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/7.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SocketData)

+(NSData *)encodeDataForSocket:(id)object;

@end
