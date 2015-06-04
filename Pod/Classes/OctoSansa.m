//
//  OctoSansa.m
//  Drone
//
//  Created by Patrick Quinn-Graham on 3/6/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import "OctoSansa.h"
#import "OctoSansaInputStreamHelper.h"

@interface OctoSansa()
{
    unsigned int outputByteIndex;
    OctoSansaConnection _connectionStatus;
}

@property (nonatomic) NSURL *connectTo;
@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;
@property (nonatomic) OctoSansaInputStreamHelper *inputHelper;

@property (nonatomic) unsigned int nextPayloadLength;

@property (nonatomic) BOOL outputHasSpaceAvailable;
@property (nonatomic) NSMutableArray *outputMessages;

@property (nonatomic) NSMutableDictionary *outstandingCallbacks;

@end

@implementation OctoSansa

- (instancetype)initWithDelegate:(id <OctoSansaDelegate>)delegate
{
    if ((self = [super init])) {
        _connectionStatus = OctoSansaConnectionDisconnected;
        self.outstandingCallbacks = [NSMutableDictionary dictionary];
        self.delegate = delegate;
    }
    return self;
}

- (OctoSansaConnection)connectionStatus {
    return _connectionStatus;
}

- (void)setConnectionStatus:(OctoSansaConnection)connectionStatus {
    OctoSansaConnection oldStatus = _connectionStatus;
    _connectionStatus = connectionStatus;
    
    if ([self.delegate respondsToSelector:@selector(octoSansa:connectionStatusChanged:)]) {
        [self.delegate octoSansa:self connectionStatusChanged:oldStatus];
    }
}

#pragma mark - Connections

- (void)connect:(NSURL*)connectTo {
    if (self.connectionStatus != OctoSansaConnectionDisconnected) {
        return; // Do nothing :)
    }
    
    self.connectionStatus = OctoSansaConnectionConnecting;
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)connectTo.host, connectTo.port.unsignedIntValue, &readStream, &writeStream);
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    
    self.inputHelper = [OctoSansaInputStreamHelper helperForStream:self.inputStream];
}

- (void)disconnect {
    if (self.connectionStatus == OctoSansaConnectionDisconnected) {
        return; // Do nothing :)
    }
    
    if (self.inputStream) {
        [self.inputStream close];
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
        self.inputStream = nil;
    }
    
    if(self.outputStream) {
        [self.outputStream close];
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                     forMode:NSDefaultRunLoopMode];
        self.outputStream = nil;
    }
    
    self.connectionStatus = OctoSansaConnectionDisconnected;
    
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    if(stream == self.inputStream) {
        [self inputStreamEvent:eventCode];
    } else if(stream == self.outputStream) {
        [self outputStreamEvent:eventCode];
    }
}

- (void)allOpened {
    if (self.inputStream.streamStatus == NSStreamStatusOpen && self.outputStream.streamStatus == NSStreamStatusOpen) {
        self.connectionStatus = OctoSansaConnectionConnected;
    }
}

#pragma mark - Input stream

- (void)inputStreamEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"NSStreamEventHasBytesAvailable...");
            while ([self readFromInputStream]) {
                // Good work!
                NSLog(@"& try again...");
            }
            break;
        }
            
        case NSStreamEventNone:
        {
            NSLog(@"input stream event None");
            break;
        }
            
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"input stream event Opened");
            [self allOpened];
            break;
        }
            
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"input stream has space available");
            break;
        }
            
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"input stream has error %@", self.inputStream.streamError);
            // flow through to End behaviour
        }
            
        case NSStreamEventEndEncountered:
        {
            NSLog(@"bye bye input stream");
            [self disconnect];
            
            break;
        }
    }
}

- (BOOL)readFromInputStream {
    NSError *err = nil;
    
    NSLog(@"self.nextPayloadedLength = %u", self.nextPayloadLength);
    if (!self.nextPayloadLength) {
        NSLog(@"asking self.inputHelper for 4 bytes!");
        NSData *nplData = [self.inputHelper readBytes:4 error:&err];
        NSLog(@"Got bytes %@", nplData);
        if (nplData) {
            uint8_t nplBuf[4];
            [nplData getBytes:nplBuf length:4];
            unsigned int i = nplBuf[3] | nplBuf[2] << 8 | nplBuf[1] << 16 | nplBuf[0] << 24;
            self.nextPayloadLength = i; // whatever
            NSLog(@"set self.nextPayloadLength to %u", i);
        } else {
            // shit went bad
            if (err) {
                NSLog(@"What happened? %@", err);
            }
            return NO;
        }
    }
    
    NSData *mainData = [self.inputHelper readBytes:self.nextPayloadLength error:&err];
    
    if (mainData) {
        self.nextPayloadLength = 0;
        NSError *err;
        id JSON = [NSJSONSerialization JSONObjectWithData:mainData options:kNilOptions error:&err];
        if(!JSON) {
            NSLog(@"errror %@", err);
        } else {
            [self receivedMessageFromServer:JSON];
        }
        return YES;
    } else {
        // maybe bad, maybe not.
        return NO;
    }
}

- (void)receivedMessageFromServer:(id)message {
    NSLog(@"Incoming singal server message: %@", message);
    
    NSString *kind = [(NSString*)message[@"kind"] lowercaseString];
    
    if ([kind isEqualToString:@"tell"]) {
        [self.delegate tell:message[@"function"] body:message[@"body"]];
    } else if ([kind isEqualToString:@"ask"]) {
        [self.delegate ask:message[@"function"] body:message[@"body"] completionHandler:^(NSError *err, NSDictionary *body) {
            [self respondToMessage:message withBody:body orError:err];
        }];
    } else if ([kind isEqualToString:@"reply"]) {
        OctoSansaCompletionHandler handler = self.outstandingCallbacks[message[@"id"]];
        if (handler) {
            NSError *messageErr = nil;
            NSString *potentialError = message[@"err"];
            if (potentialError) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: potentialError };
                messageErr = [NSError errorWithDomain:@"OctoSansa" code:1 userInfo:userInfo];
            }
            handler(message[@"err"], message[@"body"]);
            [self.outstandingCallbacks removeObjectForKey:message[@"id"]];
        }
    }
}

#pragma mark - Output stream

- (void)outputStreamEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
            
        case NSStreamEventHasSpaceAvailable:
        {
            self.outputHasSpaceAvailable = YES;
            [self trySendingAMessage];
            break;
        }
            
        case NSStreamEventHasBytesAvailable:
        {
            break;
        }
            
        case NSStreamEventNone:
        {
            break;
        }
            
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"output stream event Opened");
            [self allOpened];
            break;
        }
            
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"input stream has error");
            
            // flow through to End behaviour
        }
            
        case NSStreamEventEndEncountered:
        {
            NSLog(@"bye bye input stream");
            [self disconnect];
            break;
        }
    }
}


- (void)trySendingAMessage
{
    if(self.outputHasSpaceAvailable) {
        //        s(@"Trying to send...");
        NSMutableData *message = [self.outputMessages firstObject];
        if(message) {
            
            uint8_t *readBytes = (uint8_t *)[message mutableBytes];
            readBytes += outputByteIndex; // instance variable to move pointer
            
            NSUInteger dataLength = message.length;
            
            NSUInteger len = ((dataLength - outputByteIndex >= 1024) ?
                                1024 : (dataLength-outputByteIndex));
            
            uint8_t buf[len];
            memcpy(buf, readBytes, len);
            
            NSUInteger written = [self.outputStream write:(const uint8_t *)buf maxLength:len];
            
            if(written < len) {
                outputByteIndex += len;
            } else {
                outputByteIndex = 0;
                [self.outputMessages removeObject:message];
            }
            
            self.outputHasSpaceAvailable = NO;
        }
    }
}

- (NSError*)sendMessage:(id)JSON
{
    if(!self.outputMessages) {
        self.outputMessages = [NSMutableArray arrayWithCapacity:1];
    }
    NSError *err;
    NSData *serialized = [NSJSONSerialization dataWithJSONObject:JSON options:kNilOptions error:&err];
    if(serialized) {
        NSUInteger serializedLength = serialized.length;

        NSAssert(serializedLength < UINT_MAX, @"Tried to send a message that is too long");

        NSMutableData *message = [NSMutableData dataWithCapacity:(4 + serialized.length)];
        uint8_t size[4];
        
        size[0] = serializedLength >> 24;
        size[1] = serializedLength >> 16;
        size[2] = serializedLength >> 8;
        size[3] = serializedLength;
        
        [message appendBytes:(const uint8_t *)size length:4];
        [message appendData:serialized];
        
        [self.outputMessages addObject:message];
        [self trySendingAMessage];
        return nil;
    } else {
        return err;
    }
}

- (void)respondToMessage:(NSDictionary*)message withBody:(id)body orError:(NSError*)err
{
    NSMutableDictionary *buildUp = [NSMutableDictionary dictionary];
    
    buildUp[@"kind"] = @"reply";
    buildUp[@"id"] = message[@"id"];
    if (err) {
        buildUp[@"err"] = err.localizedDescription;
    } else if (body) {
        buildUp[@"body"] = body;
    }
    [self sendMessage:buildUp];
}

- (NSString *)createNewUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

#pragma mark - Public API

- (void)tell:(NSString *)event body:(NSDictionary *)body
{
    NSMutableDictionary *buildUp = [NSMutableDictionary dictionary];
    buildUp[@"function"] = event;
    buildUp[@"kind"] = @"tell";
    if (body) {
        buildUp[@"body"] = body;
    }
    [self sendMessage:buildUp];
}

- (void)ask:(NSString *)event body:(id)body completionHandler:(OctoSansaCompletionHandler)completionHandler
{
    NSString *askId = [self createNewUUID];
    
    NSMutableDictionary *buildUp = [NSMutableDictionary dictionary];
    buildUp[@"function"] = event;
    buildUp[@"id"] = askId;
    buildUp[@"kind"] = @"ask";
    if (body) {
        buildUp[@"body"] = body;
    }
    
    self.outstandingCallbacks[askId] = completionHandler;
    
    [self sendMessage:buildUp];
}

@end
