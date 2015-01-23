//
//  MIDIPlayController.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/23.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "MIDIPlayController.h"
#import <AudioToolbox/AudioSession.h>

#import "fmod.hpp"
#import "fmod_errors.h"

@interface MIDIPlayController () {
    FMOD::System *system;
    FMOD::Sound *sound1,*sound2;
    FMOD::Channel *channel;
}

@end

@implementation MIDIPlayController

void ERRCHECK(FMOD_RESULT result) {
    if (result != FMOD_OK) {
        fprintf(stderr, "FMOD error! (%d) %s ", result, FMOD_ErrorString(result));
        exit(-1);
    }  
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    system=NULL;
    sound1=NULL;
    sound2=NULL;
    channel=NULL;
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self initFMOD];
}

-(void)initFMOD {
    FMOD_RESULT     result          =FMOD_OK;
    unsigned int    version         =0;
    
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
    FMOD_CREATESOUNDEXINFO soundExInfo;
    memset(&soundExInfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
    soundExInfo.cbsize=sizeof(FMOD_CREATESOUNDEXINFO);
    soundExInfo.dlsname=[[[NSBundle mainBundle] pathForResource:@"gs_instruments" ofType:@"dls"] UTF8String];
    
    //添加第一个MIDI文件
    result=system->createSound([[[NSBundle mainBundle] pathForResource:@"1" ofType:@"mid"] UTF8String], FMOD_DEFAULT, &soundExInfo, &sound1);
    ERRCHECK(result);
    result=sound1->setMode(FMOD_LOOP_OFF);
    ERRCHECK(result);
    
    //添加第二个MIDI文件
    result=system->createSound([[[NSBundle mainBundle] pathForResource:@"clap" ofType:@"mid"] UTF8String], FMOD_DEFAULT, &soundExInfo, &sound2);
    ERRCHECK(result);
    result=sound2->setMode(FMOD_LOOP_OFF);
    ERRCHECK(result);
    
}

- (IBAction)playMIDI1:(id)sender {
    FMOD_RESULT result=FMOD_OK;
    
    result=system->playSound(sound1, 0, false, &channel);
    ERRCHECK(result);
}

- (IBAction)playMIDI2:(id)sender {
    FMOD_RESULT result=FMOD_OK;
    
    result=system->playSound(sound1, 0, false, &channel);
    ERRCHECK(result);
}

@end
