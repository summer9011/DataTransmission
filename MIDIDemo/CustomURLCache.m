//
//  CustomURLCache.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/1.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "CustomURLCache.h"

@implementation CustomURLCache

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSDictionary *MIMEType=URLMIMEType;
    NSString *ext =request.URL.pathExtension;
    
    NSString *fileName=request.URL.relativePath.lastPathComponent;
    NSString *resourcePath=[[NSBundle mainBundle] pathForResource:fileName ofType:@""];
    
    if (resourcePath) {
        NSData *data=[NSData dataWithContentsOfFile:resourcePath];
        NSURLResponse *response=[[NSURLResponse alloc] initWithURL:[request URL] MIMEType:MIMEType[ext] expectedContentLength:data.length textEncodingName:nil];
        
        if ([fileName isEqualToString:@"acoustic_grand_piano-mp3.js"]) {
            [SVProgressHUD dismissWithSuccess:@"完成"];
        }
        
        return [[NSCachedURLResponse alloc] initWithResponse:response data:data];
    }
    
    return nil;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
    
}

@end
