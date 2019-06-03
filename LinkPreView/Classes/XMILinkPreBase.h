//
//  XMILinkPreBase.h
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/30.
//

#import <Foundation/Foundation.h>
#import "XMILinkPreObject.h"
#import "XMILinkSerializer.h"
NS_ASSUME_NONNULL_BEGIN

@interface XMILinkPreBase : NSObject

+(XMILinkPreBase *)shareInstance;

@property (nonatomic , strong) id <XMILinkSerializerDelegate> responseSerializer;

//暂只支持url 不支持图片 
-(NSURLSessionTask *)extractUrlString:(NSString *)urlString onCompletion:(void(^)(XMILinkPreObject * object , NSError * error))completionHandler;

@end

NS_ASSUME_NONNULL_END
