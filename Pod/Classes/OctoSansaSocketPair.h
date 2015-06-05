//
//  OctoSansaSocketPair.h
//  Drone
//
//  Created by Patrick Quinn-Graham on 4/6/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OctoSansaSocketPair : NSObject

@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;

+ (instancetype)forHost:(NSString*)host onPort:(unsigned int)port;

@end
