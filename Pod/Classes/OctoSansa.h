//
//  OctoSansa.h
//  Drone
//
//  Created by Patrick Quinn-Graham on 3/6/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OctoSansaSocketPair.h"

/**
 *  These constants describe the connection status of an OctoSansa client.
 */
typedef NS_ENUM(NSUInteger, OctoSansaConnection){
    /**
     *  The client has started connecting.
     */
    OctoSansaConnectionConnecting,
    /**
     *  The client is connected.
     */
    OctoSansaConnectionConnected,
    /**
     *  The client is not connected.
     */
    OctoSansaConnectionDisconnected,
};


typedef NS_ENUM(NSInteger, MRBrewError) {
    /** Indicates the absence of an error condition. Used exclusively for unit
     * testing.
     */
    MRBrewErrorNone,
    /** Indicates that an unknown Homebrew error occurred when performing the
     * operation.
     */
    MRBrewErrorUnknown,
    /** Indicates that the operation failed to complete due to a cancellation
     * message.
     */
    MRBrewErrorOperationCancelled
};


@class OctoSansa;

/**
 *  The completion handler signature used by OctoSansa.
 *
 *  @param NSError An error (if present). Must have a localizedDescription set.
 *  @param id      Message body. Must be serializable/deserializable with NSJSONSerialization.
 */
typedef void (^OctoSansaCompletionHandler)(NSError*, id);

/**
 *  This protocol describes the delegate for a OctoSansa client, receiving connection
 *  updates and incoming messages from the server.
 */
@protocol OctoSansaDelegate <NSObject>

/**
 *  Called when an incoming "tell" message is received from the server.
 *
 *  @param event The event name
 *  @param body  The event body (the type is determined by the message sent by the server,
 *               it will be a type that can be deserialized by NSJSONSerialization such as
 *               NSString, NSDictionary, NSArray, NSNumber, or NSNull.
 */
- (void)tell:(NSString*)event body:(id)body;

/**
 *  Called when an incoming "ask" message is received from the server.
 *
 *  @param event    The event name
 *  @param body     The event body (the type is determined by the message sent by the server,
 *                  it will be a type that can be deserialized by NSJSONSerialization such as
 *                  NSString, NSDictionary, NSArray, NSNumber, or NSNull.
 *  @param callback Send a response back to the server. You should ensure you call the completion
 *                  handler before disconnecting - or the server will receive automatic callbacks
 *                  with an error.
 */
- (void)ask:(NSString*)event body:(id)body completionHandler:(OctoSansaCompletionHandler)callback;

@optional

/**
 *  This method is called whenever the connection status is changed.
 *
 *  @param octoSansa The OctoSansa connection that changed status.
 *  @param oldStatus The status before the change.
 */
- (void)octoSansa:(OctoSansa*)octoSansa connectionStatusChanged:(OctoSansaConnection)oldStatus;

/**
 *  This method is called whenever an error ocurrs in the connection - either because
 *  the connection failed to connect or the connection was disconnected unexpectedly.
 *
 *  @param octoSansa The OctoSansa object that generated the error
 *  @param error     An error objecting containg details of why the connection failed.
 */
- (void)octoSansa:(OctoSansa *)octoSansa didError:(NSError*)error;

@end


/**
 *  OctoSansa: An Objective-C client for the sansa protocol.
 *
 *  The OctoSansa class is your connection to an a sansa speaking server, such as 
 *  https://github.com/thepatrick/octo-sansa
 */
@interface OctoSansa : NSObject<NSStreamDelegate>

/**
 *  The current connection status. Initially will be OctoSansaConnectionDisconnected.
 */
@property OctoSansaConnection connectionStatus;

/**
 *  The delegate receives connection updates and incoming messages from the server,
 *  as is defined in the OctoSansaDelegate protocol.
 */
@property (assign) id <OctoSansaDelegate> delegate;

/**-----------------------------------------------------------------------------
 * @name Initialising an OctoSansa client
 * -----------------------------------------------------------------------------
 */

/**
 *  Returns a new OctoSansa client, with the specified delegate.
 *
 *  @param delegate The delegate object for this client. he delegate receives
 *  connection updates and incoming messages from the server.
 *
 *  @return An OctoSansa client.
 */
- (instancetype)initWithDelegate:(id <OctoSansaDelegate>)delegate NS_DESIGNATED_INITIALIZER;


/**-----------------------------------------------------------------------------
 * @name Connecting and Disconnecting
 * -----------------------------------------------------------------------------
 */

/**
 *  Connect to a server using the sansa protocol.
 *
 *  @param connectTo An NSURL to connect to. The protocol should be "octo", and you should
 *  always include a port. The path and query string will be ignored.
 */
- (void)connect:(NSURL*)connectTo;

/**
 *  Disconnect the current connection (you can re-connect using -connect: afterwards).
 */
- (void)disconnect;


/**-----------------------------------------------------------------------------
 * @name Sending messages
 * -----------------------------------------------------------------------------
 */


/**
 *  Send a "tell" message to the server - that is a message that does not get a response.
 *
 *  @param event The event name that this message will emit with on the server
 *  @param body  The message body. This value must be serializable with NSJSONSerialization.
 */
- (void)tell:(NSString*)event body:(id)body;

/**
 *  Send an "ask" message to the server - this is a message that is expected to get a
 *  response from the server.
 *
 *  @param event             The event name that this message will emit with on the server
 *  @param body              The message body. This value must be serializable with NSJSONSerialization
 *  @param completionHandler Called when the server responds, or potentially with an error if the connection
 *                           is disconnected before the server can respond.
 */
- (void)ask:(NSString*)event body:(id)body completionHandler:(OctoSansaCompletionHandler)completionHandler;

@end
