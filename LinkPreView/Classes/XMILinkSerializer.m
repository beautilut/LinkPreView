//
//  XMILinkSerializer.m
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/31.
//

#import "XMILinkSerializer.h"
#import "NSString+linkPreviewExtension.h"

NSString * const metatagPattern = @"<meta(.*?)>";
NSString * const metatagContentPattern = @"content=(\"(.*?)\")|('(.*?)')";
NSString * const titlePattern = @"<title(.*?)>(.*?)</title>";
NSString * const imageTagPattern = @"<img(.+?)src=\"([^\"]+)\"(.+?)[/]?>";
NSString * const imageIconPattern = @"<link(.+?) type=\"image/x-icon\">";
NSString * const hrefPattern = @"href=(\"(.*?)\")|('(.*?)')";

@implementation XMILinkSerializer

-(void)preObject:(XMILinkPreObject *)preObject withResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error
{
    preObject.finalUrl = response.URL.absoluteString;
    
    //取出网页内容
    NSString * htmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (htmlString == nil ) {
        NSMutableArray *arrayOfEncodings = [NSMutableArray new];
        const NSStringEncoding *encodings = [NSString availableStringEncodings];
        while (*encodings != 0){
            [arrayOfEncodings addObject:[NSNumber numberWithUnsignedLong:*encodings]];
            encodings++;
        }
        htmlString = [self stringFromData:data withEncodeArray:arrayOfEncodings];
    }
    
    //取出来的htmlstring
    htmlString = htmlString.trim;
    
    [self preObject:preObject crawlMetaTags:htmlString];
}

-(NSString *)stringFromData:(NSData *)data withEncodeArray:(NSArray *)array
{
    NSString * htmlString = [[NSString alloc] initWithData:data encoding:[array.firstObject unsignedLongValue]];
    if (!htmlString) {
        NSNumber *firstEncoding = array[0];
        array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSNumber *evaluatedObject, NSDictionary<NSString *,id> *bindings) {
            return ![evaluatedObject isEqualToNumber:firstEncoding];
        }]];
        [self stringFromData:data withEncodeArray:array];
    }
    return htmlString;
}

-(void)preObject:(XMILinkPreObject *)object crawlMetaTags:(NSString *)htmlCode {
    NSArray <NSString *> *possibleTags = [XMILinkPreObject tagList];
    
    NSArray <NSString *> *metatags = [XMILinkSerializer pregMatchAllString:htmlCode regex:metatagPattern index:1];
    
    [metatags enumerateObjectsUsingBlock:^(NSString * _Nonnull metaTag, NSUInteger idx, BOOL * _Nonnull stop) {
        for (NSString * tag in possibleTags) {
            [self preObject:object
                    metaTag:metaTag
                        tag:tag
            withContainlist:@[
                              @"property=\"og:%@",
                              @"property='og:%@",
                              @"name=\"twitter:%@",
                              @"name='twitter:%@",
                              @"name=\"%@",
                              @"name='%@",
                              @"itemprop=\"%@",
                              @"itemprop='%@"
                              ]];
        }
    }];
    
    //额外取值
    [self preObject:object crawTitle:htmlCode]; //额外处理title
    [self preObject:object crawImage:htmlCode]; //额外处理image
}

-(void)preObject:(XMILinkPreObject *)preObject metaTag:(NSString *)metaTag tag:(NSString *)tag withContainlist:(NSArray *)list
{
    NSString * filter = list.firstObject;
    if (filter) {
        if ([metaTag containsString:[NSString stringWithFormat:filter , tag]]) {
            NSString * value = nil;
            if ((value = [[self class] pregMatchFirstString:metaTag regex:metatagContentPattern index:2])) {
                value = [value decoded].extendedTrim;
                
                if ([tag isEqualToString:@"image"]) {
                    value = [self preObject:preObject withImagePath:value];
                }
                
                [preObject setValue:value forKey:[NSString stringWithFormat:@"meta_%@" , tag]];
                
            }
        }else {
            NSMutableArray * newArray = [[NSMutableArray alloc] initWithArray:list];
            [newArray removeObjectAtIndex:0];
            [self preObject:preObject metaTag:metaTag tag:tag withContainlist:[newArray copy]];
        }
    }
}

-(NSString *)preObject:(XMILinkPreObject *)preObject withImagePath:(NSString *)imagePath
{
    NSString * image  = imagePath;
    NSString * baseUrl = preObject.finalUrl ? : preObject.baseUrl;
    
    if ([image containsString:@"http"] || image.length == 0) {
        return image;
    }
    
    if (baseUrl) {
        if ([image hasPrefix:@"//"]) {
            image = [@"http:" stringByAppendingString:image];
        } else if([image hasPrefix:@"/"]){
            image = [image substringFromIndex:1];
            
            NSURL * url = [NSURL URLWithString:baseUrl];
            image = [url URLByAppendingPathComponent:image].absoluteString;
        } else {
            NSURL * url = [NSURL URLWithString:baseUrl];
            image = [url URLByAppendingPathComponent:image].absoluteString;
        }
    }
    return image;
}
#pragma mark -- additional Craw --
//额外处理title
-(void)preObject:(XMILinkPreObject *)preObject crawTitle:(NSString *)htmlCode {
    if (!preObject.meta_title || preObject.meta_title.length == 0) {
        NSString * value = nil;
        if ((value = [[self class] pregMatchFirstString:htmlCode regex:titlePattern index:2])) {
            preObject.meta_title = value;
        }
    }
}

-(void)preObject:(XMILinkPreObject *)preObject crawImage:(NSString *)htmlCode {
    if (!preObject.meta_image || preObject.meta_image.length == 0) {
        NSString * value = nil;
        
        NSArray <NSString *> * values = [[self class] pregMatchAllString:htmlCode regex:imageTagPattern index:2];
        if (values.count > 0) {
            value = [self preObject:preObject withImagePath:values[0]];
            preObject.meta_image = value;
        }
    }
    
    //实在不行处理小cion
    if (!preObject.meta_image || preObject.meta_image.length == 0) {
        NSString * value = nil;
        
        NSArray <NSString *> * values = [[self class] pregMatchAllString:htmlCode regex:imageIconPattern index:0];
        if (values.count > 0) {
            
            value = [[self class] pregMatchFirstString:values[0] regex:hrefPattern index:2];
            if (value.length > 0) {
                value = [self preObject:preObject withImagePath:value];
                preObject.meta_image = value;
            }
        }
    }
}

#pragma mark -- regex --

+(NSString *)pregMatchFirstString:(NSString *)string regex:(NSString *)regex index:(NSUInteger)index {
    NSRegularExpression * rx = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:NULL];
    NSTextCheckingResult * match = [rx firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if (match == nil) {
        return nil;
    }
    NSArray * result = [XMILinkSerializer stringMatchesResults:@[match] text:string index:index];
    return result.count == 0 ? nil : result[0];
}

+(NSArray <NSString *> *)pregMatchAllString:(NSString *)string regex:(NSString *)regex index:(NSUInteger)index {
    NSRegularExpression *rx = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray * matches = [rx matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    return [self stringMatchesResults:matches text:string index:index];
}

+(NSArray <NSString *> *)stringMatchesResults:(NSArray *)results text:(NSString *)text index:(NSUInteger)index {
    NSMutableArray <NSString *> * resValue = [NSMutableArray new];
    [results enumerateObjectsUsingBlock:^(NSTextCheckingResult * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [obj rangeAtIndex:index];
        if (text.length > range.location + range.length) {
            [resValue addObject:[text substringWithRange:range]];
        } else {
            [resValue addObject:@""];
        }
    }];
    return resValue;
}


@end
