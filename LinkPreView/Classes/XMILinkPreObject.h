//
//  XMILinkPreObject.h
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XMILinkPreObject : NSObject

@property (nonatomic , strong) NSString * baseUrl;
@property (nonatomic , strong) NSString * finalUrl;


@property (nonatomic , strong) NSString * meta_title;
@property (nonatomic , strong) NSString * meta_description;
@property (nonatomic , strong) NSString * meta_image;


//支持解析 xmi开头的属性列表
+(NSArray *)tagList;

@end

NS_ASSUME_NONNULL_END
