//
//  octo-sansaTests.m
//  octo-sansaTests
//
//  Created by Patrick Quinn-Graham on 06/03/2015.
//  Copyright (c) 2015 Patrick Quinn-Graham. All rights reserved.
//

#import "OctoSansa.h"

// https://github.com/Specta/Specta

SpecBegin(InitialSpecs)

describe(@"OctoSansa", ^{
    
    __block id delegateMock = nil;
    __block id inputStreamMock = nil;
    __block id outputStreamMock = nil;
    __block id socketPairMock = nil;
    
    beforeEach(^{
        delegateMock = OCMProtocolMock(@protocol(OctoSansaDelegate));
        
        inputStreamMock = OCMClassMock([NSInputStream class]);
        outputStreamMock = OCMClassMock([NSInputStream class]);
        
        socketPairMock = OCMClassMock([OctoSansaSocketPair class]);
        OCMStub([socketPairMock inputStream]).andReturn(inputStreamMock);
        OCMStub([socketPairMock outputStream]).andReturn(outputStreamMock);
        
        OCMStub([socketPairMock forHost:[OCMArg any] onPort:10301]).andReturn(socketPairMock);
        
    });
    
    it(@"initializes with a delegate", ^{
        
        OctoSansa *octo = [[OctoSansa alloc] initWithDelegate:delegateMock];

        expect(octo.delegate).to.equal(delegateMock);
        expect(octo.connectionStatus).to.equal(OctoSansaConnectionDisconnected);
        
    });
    
    it(@"connects", ^{
        
        OctoSansa *octo = [[OctoSansa alloc] initWithDelegate:delegateMock];
        
        [octo connect:[NSURL URLWithString:@"octo://some-host:10301/"]];
        
        OCMVerify([socketPairMock forHost:@"some-host" onPort:10301]);
        
        expect(octo.connectionStatus).to.equal(OctoSansaConnectionConnecting);
        
        OCMStub([inputStreamMock streamStatus]).andReturn(NSStreamStatusOpen);
        [octo stream:inputStreamMock handleEvent:NSStreamEventOpenCompleted];
        
        OCMVerify([inputStreamMock streamStatus]);
        OCMVerify([outputStreamMock streamStatus]);
        expect(octo.connectionStatus).to.equal(OctoSansaConnectionConnecting);
        
        OCMStub([outputStreamMock streamStatus]).andReturn(NSStreamStatusOpen);
        [octo stream:outputStreamMock handleEvent:NSStreamEventOpenCompleted];
        
        expect(octo.connectionStatus).to.equal(OctoSansaConnectionConnected);
    });
    
});

//describe(@"these will pass", ^{
//    
//    it(@"can do maths", ^{
//        expect(1).beLessThan(23);
//    });
//    
//    it(@"can read", ^{
//        expect(@"team").toNot.contain(@"I");
//    });
//    
//    it(@"will wait and succeed", ^{
//        waitUntil(^(DoneCallback done) {
//            done();
//        });
//    });
//});

SpecEnd
