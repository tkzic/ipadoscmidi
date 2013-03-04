//
//  OscManager.h
//  
//  Tom Zicarelli 01.01.2012
//
//  Based on code by 
//  C. Ramakrishnan on 09.03.08.
//
//  original source:
//  http://www.illposed.com/software/dls/cocoaoscpack.zip
//


//
//  Mr. Ramakrishnan's code solved the big problem of how to run oscpack in objective-c
//
//  Here's what's been added:
//
//  updated for newest version of oscpack 1/1/2012 (fixed int32 conversion)
//  updated for iOS
//  fixed ip endpoint formatting issue on listener
//  provide obj-c OSC interface (ie, you can use OscManager outside of c++)
//  new classes: OscManager, OscMessage, OscArg to completely wrap oscpack
//  delegate protocol for incoming messages
//  ability to start/stop/restart engine & enable/disable send and receive
//  generic send/recieve methods

// #import <Cocoa/Cocoa.h>


// tz: this chunk of defines, prefixed with ZKM, (from the Zirkonium project)
// helps with wrapping c++ inside obj-c 
// 
// a pointer to a c++ OSC socket listener is an instance variable in an obj-c class.
//
// But the c++ needs to be opaque (hidden) so that the obj-c class header file (this file)
// can be included in other code that wants to use the class (like a view controller)
// without forcing that code to become objective c++.
//
// This method lets the preprocessor decide whether to use the c++ or c method of declaring
// the instance variables.
//
// Another way to do this would be to wrap the c++ class in a struct
// http://robnapier.net/blog/wrapping-c-take-2-1-486
//
// 
#ifdef __cplusplus
#  define ZKMOR_C_BEGIN extern "C" {
#  define ZKMOR_C_END   }
#  define ZKMCPPT(objtype) objtype*
#  define ZKMDECLCPPT(decl) class decl;
#else
#  define ZKMOR_C_BEGIN
#  define ZKMOR_C_END
#  define ZKMCPPT(objtype) void*
#  define ZKMDECLCPPT(decl) 
#endif


ZKMDECLCPPT(OMOscListener)  // opaque c++ class pointer declaration (see above)
                              // essentially a forward reference

// For OSC Output               // osc message buffer size
#define IP_MTU_SIZE 1536        // note: find out min/max possible values here


#import "OscArg.h"         // imported here because its not likely to be used independent of OscManager
#import "OscMessage.h"     // imported here because its not likely to be used independent of OscManager

// @class OscManager;


@protocol OscManagerDelegate <NSObject>

@optional
- (void) newMessageArrived: (OscMessage *) om ;
- (void) failedToSendMessage: (CFSocketError) err;

@end


@interface OscManager : NSObject {
	// OSC State
	ZKMCPPT(OMOscListener)	mOSCListener;   // pointer to c++ listener (see notes above on syntax)
                                                
	CFDataRef					mOSCReceiverAddressData;  // receiver (destination) ip/port
	CFMutableDataRef			mMessageData;             // outgoing msg data 
	CFIndex						mMessageDataSize;         // not used?  
	char						mMessageBuffer[IP_MTU_SIZE];  // oscpack buf to format msg
    
    // on/off switches for send and receive
    
    BOOL sendEnabled;       // for client to enable/disable send and receive
    BOOL receiveEnabled;
    
    // engine status 
    BOOL isRunning;         // should not be set directly by client
                            // but can be read by client
}


- (void) receivedOscMessage: (OscMessage *) om;
- (void) sendOscMessage: (OscMessage *) om;

-(void) setOSCStateWithReceivePort: (int) receivePort 
                           sendPort: (int) sendPort 
                             sendIP: (NSString *) sendIP;

- (void) stopOSC;
- (void) initOscState;

@property (nonatomic, assign ) id <OscManagerDelegate> delegate;

@property (nonatomic, assign ) BOOL sendEnabled;
@property (nonatomic, assign ) BOOL receiveEnabled;
@property (nonatomic, assign ) BOOL isRunning;

@end





