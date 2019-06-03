//
//  XMILinkSerializer.h
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/31.
//

#import <Foundation/Foundation.h>
#import "XMILinkPreObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol XMILinkSerializerDelegate <NSObject>

-(void)preObject:(XMILinkPreObject *)preObject
                  withResponse:(NSURLResponse *)response
                          data:(NSData *)data
                         error:(NSError *__autoreleasing *)error;

@end


@interface XMILinkSerializer : NSObject <XMILinkSerializerDelegate>




@end

NS_ASSUME_NONNULL_END
