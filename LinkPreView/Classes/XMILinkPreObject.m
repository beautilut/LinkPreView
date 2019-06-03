//
//  XMILinkPreObject.m
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/29.
//

#import "XMILinkPreObject.h"
#import <objc/runtime.h>

@implementation XMILinkPreObject

+(NSArray *)tagList
{
    NSMutableArray * tagsList = [[NSMutableArray alloc] init];
    unsigned int count;
    objc_property_t * property_list = class_copyPropertyList([XMILinkPreObject class], &count);
    NSString * key = nil;
    for (int i = 0; i < count; i ++) {
        objc_property_t property = property_list[i];
        key = [NSString stringWithUTF8String:property_getName(property)];
        if ([key containsString:@"meta_"]) {
            NSString * subString = [key stringByReplacingOccurrencesOfString:@"meta_" withString:@""];
            [tagsList addObject:subString];
        }
    }
    return [tagsList copy];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"baseUrl:%@ \n finalUrl:%@ \n title:%@ \n description:%@ \n image:%@",self.baseUrl , self.finalUrl , self.meta_title , self.meta_description , self.meta_image];
}

@end
