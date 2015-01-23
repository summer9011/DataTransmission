//
//  ReadMini.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/21.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReadMini : NSObject

+(void)readMIDIFile:(NSString *)filePath;

+(void)readDataFile:(NSData *)data;

@end
