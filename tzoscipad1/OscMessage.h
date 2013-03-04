//
//  OscMessage.h
//  ipadosctest
//
//  Created by Thomas Zicarelli on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OscArg;

// Osc Message class - contains a parsed message
//
@interface OscMessage : NSObject {
    
    NSString        *mAddressPattern;
    NSMutableArray  *mArg;
    NSString        *mSourceEndpoint;
    unsigned short       mPort;              
    
    
}

@property (nonatomic, retain)  NSString *mAddressPattern;
@property (nonatomic, retain)  NSMutableArray *mArg;
@property (nonatomic, retain)  NSString *mSourceEndpoint;
@property (nonatomic, assign)  unsigned short mPort;

- (id) initWithAddressPattern: (NSString *) addressPattern
                          arg: (NSMutableArray *) arg;


- (id) initWithAddressPattern: (NSString *) addressPattern
                          arg: (NSMutableArray *) arg
               sourceEndpoint: (NSString *) sourceEndpoint
                         port: (unsigned short) port;

- (void) print;
- (NSString *) stringPrint;

@end

