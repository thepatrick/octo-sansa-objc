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


typedef void (^OctoSansaCompletionHandler)(NSError*, NSDictionary*);

@protocol OctoSansaDelegate <NSObject>

- (void)tell:(NSString*)event body:(NSDictionary*)body;

- (void)ask:(NSString*)event body:(NSDictionary*)body completionHandler:(OctoSansaCompletionHandler)callback;

@end

@interface OctoSansa : NSObject<NSStreamDelegate>


@property OctoSansaConnection connectionStatus;
@property (assign) id <OctoSansaDelegate> delegate;

- (void)connect:(NSURL*)connectTo;
- (void)tell:(NSString*)event body:(NSDictionary*)body;
- (void)ask:(NSString*)event body:(NSDictionary*)body completionHandler:(OctoSansaCompletionHandler)completionHandler;

@end
