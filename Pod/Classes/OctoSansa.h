//
//  OctoSansa.h
//  Drone
//
//  Created by Patrick Quinn-Graham on 3/6/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    OctoSansaConnectionConnecting,
    OctoSansaConnectionConnected,
    OctoSansaConnectionDisconnected,
} OctoSansaConnection;

@class OctoSansa;

typedef void (^OctoSansaCompletionHandler)(NSError*, id);

@protocol OctoSansaDelegate <NSObject>

- (void)tell:(NSString*)event body:(id)body;
- (void)ask:(NSString*)event body:(id)body completionHandler:(OctoSansaCompletionHandler)callback;

@optional
- (void)octoSansa:(OctoSansa*)octoSansa connectionStatusChanged:(OctoSansaConnection)oldStatus;
- (void)octoSansa:(OctoSansa *)octoSansa didError:(NSError*)error;

@end

@interface OctoSansa : NSObject<NSStreamDelegate>


@property OctoSansaConnection connectionStatus;
@property (assign) id <OctoSansaDelegate> delegate;

- (instancetype)initWithDelegate:(id <OctoSansaDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void)connect:(NSURL*)connectTo;
- (void)disconnect;

- (void)tell:(NSString*)event body:(id)body;
- (void)ask:(NSString*)event body:(id)body completionHandler:(OctoSansaCompletionHandler)completionHandler;

@end
