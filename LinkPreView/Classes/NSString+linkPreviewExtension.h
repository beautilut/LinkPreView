//
//  NSString+linkPreviewExtension.h
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/30.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface NSString (linkPreviewExtension)
//trim
-(NSString *)trim;

//remove extra white spaces
-(NSString *)extendedTrim;

- (NSString *)decoded;

@end

NS_ASSUME_NONNULL_END
