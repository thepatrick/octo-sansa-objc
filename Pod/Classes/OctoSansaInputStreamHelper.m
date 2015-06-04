//
//  OctoSansaInputStreamHelper.m
//  Drone
//
//  Created by Patrick Quinn-Graham on 3/6/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import "OctoSansaInputStreamHelper.h"

@interface OctoSansaInputStreamHelper()


@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSMutableData *buffer;

@end

@implementation OctoSansaInputStreamHelper

+ (instancetype)helperForStream:(NSInputStream*)stream {
    OctoSansaInputStreamHelper *helper = [[self alloc] init];
    helper.inputStream = stream;
    return helper;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.buffer = [NSMutableData data];
    }
    return self;
}

- (NSData*)readBytes:(NSUInteger)readBytes error:(NSError**)error {
    if (!self.inputStream.hasBytesAvailable) {
        NSLog(@"No bytes available :(");
        return nil;
    }
    
    NSUInteger neededBytes = readBytes - self.buffer.length;
    
    NSLog(@"Asked for %lu, we have %lu, which means we need %lu", (unsigned long)readBytes, (unsigned long)self.buffer.length, (unsigned long)neededBytes);
    
    uint8_t buf[neededBytes];
    
    NSInteger read = [self.inputStream read:buf maxLength:neededBytes];
    
    NSLog(@"This leaves us with %ld", (long)read);
    
    if (read < 0) { // Something else happened :(
        *error = [self.inputStream streamError];
        return nil;
    }
    
    if (read == 0) { // Reached end of stream
        return nil;
    }
    
    [self.buffer appendBytes:buf length:read];
    
    if (self.buffer.length == readBytes) {
        // give them the buffer
        NSData *theBuffer = self.buffer;
        self.buffer = [NSMutableData data];
        return theBuffer;
    } else {
        // not enough data yet
        return nil;
    }
}
@end
