//
//  PlayMIDI.h
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/24.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayMIDI : NSObject

@property (nonatomic,strong) UIWebView *midiWeb;

//使用FMOD播放MIDI
-(id)initWithFMOD;

//使用HTML5播放MIDI
-(id)initWithHTML5;

//使用AVMIDIPlayer播放MIDI
-(id)initWithAVMIDIPlayer;

//播放MIDIData
-(void)playMIDIData:(NSData *)data;

//播放MIDI文件
-(void)playMIDIWithPath:(NSString *)resourcePath;

@end
