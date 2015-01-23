//
//  ReadMini.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/21.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "ReadMini.h"

#import "HeaderChunks.h"
#import "TrackChunk.h"

@implementation ReadMini

//从文件中读取MIDI
+(void)readMIDIFile:(NSString *)filePath {
    NSData *midiData=[NSData dataWithContentsOfFile:filePath];
    
    NSLog(@"%@",midiData);
    
//    HeaderChunks *header=[self readHeaderChunkFromData: midiData.bytes];
//    NSArray *track=[self readTrackChunkFromData: midiData.bytes HeaderChunk:header];
    
//    [self printMIDIData:header TrackChunks:track];
}

+(void)readDataFile:(NSData *)data {
    
}

//头块
+(HeaderChunks *)readHeaderChunkFromData:(const void *)data {
    HeaderChunks *header=[[HeaderChunks alloc] init];
    
//    NSLog(@"%f",&data[0]);
    
    return header;
}

//音轨块
+(NSArray *)readTrackChunkFromData:(const void *)data HeaderChunk:(HeaderChunks *)headerChunk {
    return nil;
}

//输出解析后的MIDI数据
+(void)printMIDIData:(HeaderChunks *)headerChunk TrackChunks:(NSArray *)trackChunks {
    
}

@end
