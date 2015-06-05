//
//  OctoSansaSocketPair.m
//  Drone
//
//  Created by Patrick Quinn-Graham on 4/6/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import "OctoSansaSocketPair.h"

@implementation OctoSansaSocketPair

+ (instancetype)forHost:(NSString*)host onPort:(unsigned int)port {
    OctoSansaSocketPair *pair = [[OctoSansaSocketPair alloc] init];
    [pair createStreamsToHost:host onPort:port];
    return pair;
}

- (void)createStreamsToHost:(NSString*)host onPort:(unsigned int)port  {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
}


@end
