//  XMLReader.h
//  Copyright 2014 Darshan kunjadiya. All rights reserved.


#import <Foundation/Foundation.h>

@interface XMLParser : NSObject<NSXMLParserDelegate>
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
    __strong NSError **errorPointer;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(__strong NSError **)errorPointer;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(__strong NSError **)errorPointer;

@end