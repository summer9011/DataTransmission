//
//  PlayMIDI.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/1/24.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "PlayMIDI.h"

#import <AVFoundation/AVFoundation.h>
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
    
    BOOL isUseFMOD;
    BOOL isUseHTML5;
    BOOL isUseAVMIDIPlayer;
    
    AVMIDIPlayer *avMIDIPlayer;
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
    }
    return self;
}

//使用HTML5播放MIDI
-(id)initWithHTML5 {
    self=[super init];
    if (self) {
        isUseHTML5=YES;
        
        self.midiWeb=[[UIWebView alloc] initWithFrame:CGRectMake(0, 70, [UIScreen mainScreen].bounds.size.width, 400)];
        NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/MIDIPlayer.html",IP]];
        NSURLRequest *request=[NSURLRequest requestWithURL:url];
        self.midiWeb.scrollView.bounces=NO;
        self.midiWeb.delegate=(id<UIWebViewDelegate>)self;
        [self.midiWeb loadRequest:request];
        
    }
    return self;
}

//使用AVMIDIPlayer播放MIDI
-(id)initWithAVMIDIPlayer {
    self=[super init];
    if (self) {
        isUseAVMIDIPlayer=YES;
    }
    return self;
}

//播放MIDIData
-(void)playMIDIData:(NSData *)data {
    NSString *GMPath=[[NSBundle mainBundle] pathForResource:@"gm" ofType:@"dls"];
    
    //使用FMOD播放
    if (isUseFMOD) {
        //设置dls文件
        FMOD_CREATESOUNDEXINFO soundExInfo;
        memset(&soundExInfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
        soundExInfo.cbsize=sizeof(FMOD_CREATESOUNDEXINFO);
        soundExInfo.dlsname=[GMPath UTF8String];
        
        //添加第一个MIDI文件
        result=system->createSound((const char *)[data bytes], FMOD_DEFAULT|FMOD_LOOP_OFF, &soundExInfo, &sound);
        ERRCHECK(result);
        
        //播放
        result=system->playSound(sound, 0, false, &channel);
        ERRCHECK(result);
    }
    
    //使用HTML5播放
    if (isUseHTML5) {
        NSString *base64MIDI=[data base64EncodedStringWithOptions:0];
        NSString *base64Data=[@"data:audio/midi;base64," stringByAppendingString:base64MIDI];
        NSString *urlStr = [NSString stringWithFormat:@"setSong(\"%@\")",base64Data];
        [self.midiWeb stringByEvaluatingJavaScriptFromString:urlStr];
    }
    
    //使用AVMIDIPlayer播放
    if (isUseAVMIDIPlayer) {
        
        avMIDIPlayer=nil;
        
        NSError *error;
        avMIDIPlayer=[[AVMIDIPlayer alloc] initWithData:data soundBankURL:[NSURL URLWithString:GMPath] error:&error];
        
        if (!error) {
            [avMIDIPlayer prepareToPlay];
            [avMIDIPlayer play:^{
                NSLog(@"done");
            }];
        }else{
            NSLog(@"error %@",error);
        }
    }
}

//播放MIDI文件
-(void)playMIDIWithPath:(NSString *)resourcePath {
    NSString *GMPath=[[NSBundle mainBundle] pathForResource:@"gm" ofType:@"dls"];
    
    //使用FMOD播放
    if (isUseFMOD) {
        //设置dls文件
        FMOD_CREATESOUNDEXINFO soundExInfo;
        memset(&soundExInfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
        soundExInfo.cbsize=sizeof(FMOD_CREATESOUNDEXINFO);
        soundExInfo.dlsname=[GMPath UTF8String];
        
        //添加第一个MIDI文件
        result=system->createSound([resourcePath UTF8String], FMOD_DEFAULT|FMOD_LOOP_OFF, &soundExInfo, &sound);
        ERRCHECK(result);
        
        //播放
        result=system->playSound(sound, 0, false, &channel);
        ERRCHECK(result);
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"请求 %@",request.URL.absoluteString);
    
    if ([request.URL.absoluteString hasPrefix:@"objc"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MIDIPlayerSuccess object:nil];
        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:MIDIPlayerFailed object:nil];
}

@end
