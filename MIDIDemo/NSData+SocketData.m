//
//  NSData+SocketData.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/7.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import "NSData+SocketData.h"

@implementation NSData (SocketData)

+(NSData *)encodeDataForSocket:(NSDictionary *)dic {
    NSString *dataString=[self encodeObjectToJsonString:dic];
    
    int totalLength=(int)dataString.length+sizeof(int);
    NSData *lengthData=[NSData dataWithBytes:&totalLength length:4];
    NSData *strData=[dataString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *totalData=[NSMutableData dataWithData:lengthData];
    [totalData appendData:strData];
    
    return totalData;
}

+(NSString *)encodeObjectToJsonString:(NSDictionary *)dic {
    NSMutableString *tempJson=[NSMutableString string];
    [tempJson appendString:@"{"];
    
    int count=(int)dic.count;
    int i=1;
    for (NSString *key in dic) {
        [tempJson appendFormat:@"\"%@\":",key];
        
        if ([dic[key] isKindOfClass:[NSNumber class]]) {
            [tempJson appendFormat:@"%@",dic[key]];
        }
        if ([dic[key] isKindOfClass:[NSString class]]) {
            [tempJson appendFormat:@"\"%@\"",dic[key]];
        }
        
        if ([dic[key] isKindOfClass:[NSArray class]]) {
            [tempJson appendString:@"["];
            
            NSArray *tempArr=dic[key];
            int arrCount=(int)tempArr.count;
            int arri=0;
            for (NSDictionary *one in tempArr) {
                NSString *oneJson=[self encodeObjectToJsonString:one];
                [tempJson appendString:oneJson];
                
                if (arri<arrCount) {
                    [tempJson appendString:@","];
                }
                
                arri++;
            }
            
            [tempJson appendString:@"]"];
        }
        
        if (i<count) {
            [tempJson appendString:@","];
        }
        
        i++;
    }
    
    [tempJson appendString:@"}"];
    
    return tempJson;
}

@end
