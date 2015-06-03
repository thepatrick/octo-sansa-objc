//
//  PQGViewController.m
//  octo-sansa
//
//  Created by Patrick Quinn-Graham on 06/03/2015.
//  Copyright (c) 2014 Patrick Quinn-Graham. All rights reserved.
//

#import "PQGViewController.h"
#import "OctoSansa.h"

@interface PQGViewController () <OctoSansaDelegate>

@property (nonatomic) OctoSansa *octo;

@end

@implementation PQGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.octo = [[OctoSansa alloc] init];
    self.octo.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connect:(id)sender {
    NSLog(@"Connect! %@", self.octo);
    NSURL *connectTo = [NSURL URLWithString:@"octo://127.0.0.1:10301/"];
    [self.octo connect:connectTo];
}

- (IBAction)testEcho:(id)sender {
    NSLog(@"test echo!");
    if (self.octo.connectionStatus == OctoSansaConnectionConnected) {
        [self.octo ask:@"client ask" body:@{ @"hello": @"world" } completionHandler:^(NSError *err, NSDictionary *body) {
            if (err) {
                NSLog(@"Error! %@", err);
            } else {
                NSLog(@"Ok! %@", body);
            }
        }];
    } else {
        NSLog(@"Client is not connected :(");
    }
}

- (void)tell:(NSString *)event body:(NSDictionary *)body {
    NSLog(@"told %@ %@", event, body);
}

- (void)ask:(NSString *)event body:(NSDictionary *)body completionHandler:(OctoSansaCompletionHandler)callback {
    NSLog(@"asked %@ %@", event, body);
    if ([event isEqualToString:@"who are you"]) {
        callback(nil, @{ @"I am: ": @"I am a test app!" });
    } else {
        callback([NSError errorWithDomain:@"" code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"Unsupported ask method!" }], nil);
    }
}

@end
