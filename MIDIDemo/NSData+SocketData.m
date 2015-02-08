//
//  NSData+SocketData.m
//  MIDIDemo
//
//  Created by 赵立波 on 15/2/7.
//  Copyright (c) 2015年 赵立波. All rights reserved.
//

#import <objc/runtime.h>
#import "NSData+SocketData.h"

@implementation NSData (SocketData)

+(NSData *)encodeDataForSocket:(id)object {
    NSString *dataString=[self encodeObjectToJsonString:object];
    
    int totalLength=(int)dataString.length+sizeof(int);
    NSData *lengthData=[NSData dataWithBytes:&totalLength length:4];
    NSData *strData=[dataString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *totalData=[NSMutableData dataWithData:lengthData];
    [totalData appendData:strData];
    
    return totalData;
}

+(NSString *)encodeObjectToJsonString:(id)object {
    Class clazz = [object class];
    u_int count;
    objc_property_t *properties = class_copyPropertyList(clazz, &count);
    
    NSMutableArray *propertyArray = [NSMutableArray arrayWithCapacity:count];
    NSMutableArray *valueArray = [NSMutableArray arrayWithCapacity:count];
    
    for (int i=0;i<count;i++) {
        objc_property_t prop=properties[i];
        const char* propertyName = property_getName(prop);
        [propertyArray addObject:[NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
        id value =  [object valueForKey:[NSString stringWithUTF8String:propertyName]];
        
        if(value ==nil){
            [valueArray addObject:@""];
        }else{
            [valueArray addObject:value];
        }
    }
    
    free(properties);
    
    NSDictionary* dtoDic = [NSDictionary dictionaryWithObjects:valueArray forKeys:propertyArray];
    
    NSMutableString *tempJson=[NSMutableString string];
    [tempJson appendString:@"{"];
    
    int i=1;
    for (NSString *key in dtoDic) {
        [tempJson appendFormat:@"\"%@\":",key];
        
        if ([dtoDic[key] isKindOfClass:[NSNumber class]]) {
            [tempJson appendFormat:@"%@",dtoDic[key]];
        }
        if ([dtoDic[key] isKindOfClass:[NSString class]]) {
            [tempJson appendFormat:@"\"%@\"",dtoDic[key]];
        }
        
        if (i<count) {
            [tempJson appendString:@","];
        }
        
        i++;
    }
    
    [tempJson appendString:@"}"];
    
    NSLog(@"tempJson %@",tempJson);
    
    return tempJson;
}

@end
