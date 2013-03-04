//
//  OscArg.h
//  ipadosctest
//
//  Created by Thomas Zicarelli on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Osc Arg class - contains an argument (parameter) of an Osc Message
//
// first version limits available data types to:
//
//  int32
//  float
//  string
//
//  next version will add pointers to data objects for sending blobs of binary data
//
//  if this runs too slowly, you can limit the number and type of args and just include a simple structure directly
//  in the OscMessage class
//

typedef enum {
    kOscBool,
    kOscInt,
    kOscFloat,
    kOscString,
    kOscOther
} OscArgType;

@interface OscArg : NSObject {
    
    OscArgType mArgType;
    BOOL mArgBool;
    NSInteger mArgInt;
    CGFloat mArgFloat;
    NSString *mArgString;
    
    
}

@property (nonatomic, assign) OscArgType    mArgType;
@property (nonatomic, assign) BOOL          mArgBool;
@property (nonatomic, assign) NSInteger     mArgInt;
@property (nonatomic, assign) CGFloat       mArgFloat;
@property (nonatomic, retain) NSString      *mArgString;

- (void) print;
- (NSString *) stringPrint;

@end



