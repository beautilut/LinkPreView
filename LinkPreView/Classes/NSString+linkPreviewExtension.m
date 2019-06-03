//
//  NSString+linkPreviewExtension.m
//  XMIInteraction
//
//  Created by Beautilut on 2019/5/30.
//

#import "NSString+linkPreviewExtension.h"

@implementation NSString (linkPreviewExtension)

-(NSString *)trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString *)extendedTrim {
    NSArray * components = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [[components filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.length > 0;
    }]] componentsJoinedByString:@" "].trim;
}

/// Decode HTML entities
- (NSString *)decoded {
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                 documentAttributes:nil error:nil];
    return attributedString.string ? : self;
}
@end
