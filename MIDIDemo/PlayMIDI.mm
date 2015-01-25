//
//  PlayMIDI.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/24.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "PlayMIDI.h"
#import <AudioToolbox/AudioToolbox.h>

#import <AudioToolbox/AudioSession.h>
#import "fmod.hpp"
#import "fmod_errors.h"

void ERRCHECK(FMOD_RESULT result) {
    if (result != FMOD_OK) {
        fprintf(stderr, "FMOD error! (%d) %s ", result, FMOD_ErrorString(result));
        exit(-1);
    }
}

@interface PlayMIDI () {
    FMOD::System *system;
    FMOD::Sound *sound;
    FMOD::Channel *channel;
    FMOD_RESULT result;
    FMOD_CREATESOUNDEXINFO soundExInfo;
    
    BOOL isUseFMOD;
    BOOL isUseHTML5;
}

@end

@implementation PlayMIDI

//使用FMOD播放MIDI
-(id)initWithFMOD {
    self=[super init];
    if (self) {
        isUseFMOD=YES;
        
        result=FMOD_OK;
        system=NULL;
        sound=NULL;
        channel=NULL;
        
        [self initFMOD];
    }
    return self;
}

//初始化FMOD
-(void)initFMOD {
    unsigned int version=0;
    
    //初始化System
    result=FMOD::System_Create(&system);
    ERRCHECK(result);
    
    result=system->getVersion(&version);
    ERRCHECK(result);
    
    if (version<FMOD_VERSION) {
        fprintf(stderr, "You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
        exit(-1);
    }
    
    result=system->init(32, FMOD_INIT_NORMAL, NULL);
    ERRCHECK(result);
    
    //设置dls文件
    memset(&soundExInfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
    soundExInfo.cbsize=sizeof(FMOD_CREATESOUNDEXINFO);
    soundExInfo.dlsname=[[[NSBundle mainBundle] pathForResource:@"gs_instruments" ofType:@"dls"] UTF8String];
}

//使用HTML5播放MIDI
-(id)initWithHTML5 {
    self=[super init];
    if (self) {
        isUseHTML5=YES;
        
    }
    return self;
}

//播放MIDI文件
-(void)playMIDIData:(NSData *)data {
    //使用FMOD播放
    if (isUseFMOD) {
        void *pChar=const_cast<void *>(data.bytes);
        const char *p=static_cast<char *>(pChar);
        
        //添加第一个MIDI文件
        result=system->createSound(p, FMOD_DEFAULT, &soundExInfo, &sound);
        ERRCHECK(result);
        result=sound->setMode(FMOD_LOOP_OFF);
        ERRCHECK(result);
        
        //播放
        result=system->playSound(sound, 0, false, &channel);
        ERRCHECK(result);
    }
    
    //使用HTML5播放
    if (isUseHTML5) {
        NSLog(@"use html5");
    }
}

//播放wav格式文件，不播放MIDI
+(void)playSoundWithWAV:(NSString *)resourceName {
    NSString *path = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"wav"];
    if (path) {
        SystemSoundID theSoundID;
        OSStatus error =  AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &theSoundID);
        if (error == kAudioServicesNoError) {
            AudioServicesPlaySystemSound(theSoundID);
        }else {
            NSLog(@"Failed to create sound ");
        }
    }else{
        NSLog(@"no wav file :%@",resourceName);
    }
    
}


@end
