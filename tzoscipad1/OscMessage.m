//
//  OscMessage.m
//  ipadosctest
//
//  Created by Thomas Zicarelli on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OscMessage.h"


@implementation OscMessage

@synthesize mAddressPattern;
@synthesize mArg;
@synthesize mSourceEndpoint;
@synthesize mPort;

- (id) init
{
    
    
    // NSLog(@"OscMessage init"); 
    
    if (!(self = [super init])) return nil;
    
    
    return self;
}

- (id) initWithAddressPattern: (NSString *) addressPattern
                          arg: (NSMutableArray *) arg
               sourceEndpoint: (NSString *) sourceEndpoint
                         port: (unsigned short) port
{
    
    // NSLog(@"OscMessage init"); 
    
    if (!(self = [super init])) return nil;
    
    mAddressPattern = addressPattern;
    mArg = arg;
    mSourceEndpoint = sourceEndpoint;
    mPort = port;
    
    
    
    return self;
}

- (id) initWithAddressPattern: (NSString *) addressPattern
                          arg: (NSMutableArray *) arg

{
    
    // NSLog(@"OscMessage init"); 
    
    if (!(self = [super init])) return nil;
    
    mAddressPattern = addressPattern;
    mArg = arg;
    mSourceEndpoint = nil;
    mPort = 0;
    
    
    
    return self;
}

// display message object to console
- (void) print
{
    
    NSLog(@"OscMessage[source: %@ port: %i]", mSourceEndpoint, mPort  );
    
    NSLog(@"addressPattern: %@", mAddressPattern);
    
    for(int i = 0 ; i < [mArg count]; i++) {
        OscArg *oa = [mArg objectAtIndex:i];
        [oa print];
    }
}

// return a string containing the osc message
- (NSString *) stringPrint
{
    NSString *message = [[[NSString alloc] initWithString:mAddressPattern] autorelease];
    
    for(int i = 0 ; i < [mArg count]; i++) {
        OscArg *oa = [mArg objectAtIndex:i];
        message = [message stringByAppendingFormat:@" %@",[oa stringPrint]];       
    }
    
    return message;
    
}
- (void)dealloc
{
    //    [mAddressPattern release];
    [mArg release];
    //    [mSourceEndpoint release];
    
	[super dealloc];
}


@end


