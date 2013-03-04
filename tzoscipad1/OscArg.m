//
//  OscArg.m
//  ipadosctest
//
//  Created by Thomas Zicarelli on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OscArg.h"

// OscArg class

@implementation OscArg

@synthesize mArgType;
@synthesize mArgBool;
@synthesize mArgInt;
@synthesize mArgFloat;
@synthesize mArgString;

- (id) init
{
    
    
    // NSLog(@"OscArg init"); 
    
    if (self = [super init]) {
        mArgType = kOscOther;           // set to undefined arg type
        // can we just leave the other ivars undefined?
        
    }
    return self;
}


- (void)dealloc
{
    
	[super dealloc];
}

// displays type and arg value to console
- (void) print
{
    
    switch (mArgType) {
        case kOscBool:
            NSLog(@"bool: %@", mArgBool ? @"yes" : @"no");
            break;
        case kOscInt:
            NSLog(@"int: %d", mArgInt );
            break;
        case kOscFloat:
            NSLog(@"float: %f", mArgFloat );
            break;
        case kOscString:
            NSLog(@"string: %@", mArgString );
            break;    
        case kOscOther:
            NSLog(@"other:");
            break;    
        default:
            break;
    }
}

// return string containing osc arg
- (NSString *) stringPrint
{
    NSString *arg = [[[NSString alloc] initWithString:@""] autorelease];
    
    
    switch (mArgType) {
        case kOscBool:
            arg = [arg stringByAppendingFormat:@"%@", mArgBool ? @"yes" : @"no"];
            break;
        case kOscInt:
            arg = [arg stringByAppendingFormat:@"%d", mArgInt];
            break;
        case kOscFloat:
            arg = [arg stringByAppendingFormat:@"%f", mArgFloat];
            break;
        case kOscString:
            arg = [arg stringByAppendingString:mArgString];
            break;    
        case kOscOther:
            arg = [arg stringByAppendingString:@"other"];
            break;    
        default:
            break;
    }
    
    return arg;
    
    
}

@end


