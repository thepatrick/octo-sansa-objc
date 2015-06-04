//
//  OctoSansaInputStreamHelper.h
//  Drone
//
//  Created by Patrick Quinn-Graham on 3/6/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OctoSansaInputStreamHelper : NSObject

+ (instancetype)helperForStream:(NSInputStream*)stream;

- (NSData*)readBytes:(NSUInteger)readBytes error:(NSError**)error;

@end
