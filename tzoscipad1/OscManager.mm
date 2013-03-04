//
//  OscManager.m
//  cocoaoscpack
//

// tz- contains a bunch of annoying comments to help me wade through the c++ syntax
//

#import "OscManager.h"

//  For OSC
#include "OscReceivedElements.h"
#include "OscPacketListener.h"
#include "OscOutboundPacketStream.h"
#include "IpEndpointName.h"
#include <netinet/in.h>

//  For std:: output
#include <iostream>
#include "OscPrintReceivedElements.h"

//  For Networking
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

// This a trick to make these methods private - otherwise they would be declared in the header file

@interface OscManager (OscManagerPrivate) // category
                                                  
    -(void)initializeOSCState;                         
    - (void)clearMessageData;

@end

// Class for listener inherits from OscPacketListener
// this is also the definition to satisfy forward reference in the header file for the 
// OscManager class


// OMOscListener class is a c++ bridge between ios and the oscpack library
//
// oscpack lacks the ability to operate the socket/callback listener methods in an obj-c
// thread-friendly style. So this class, which is an instance var in the main obj-class
// handles setting up the socket, the listener callback, and calling oscpack parser.
// 


class OMOscListener : public osc::OscPacketListener {
public:
//  CTOR / DTOR (constructor destructor )
    //
    // the stuff after the colon is the initalizer list
    // 
    // note that first item calls the constructor of the parent class: OscPacketListener
    // the rest of the items are instance variables 
    //
	OMOscListener(OscManager* parent) : 
                                            OscPacketListener(),
                                            mParent(parent),
                                            mSocket(NULL),
                                            mIsSocketInitialized(false),
                                            mInputSocketRunLoopSource(NULL)
	{ 
        // NSLog(@"OMOscListener constructor...");
		CreateSocket();
	}
	
	~OMOscListener()    // destructor
	{
		if (mSocket) DeleteInputSocket();
		if (mInputSocketRunLoopSource) CFRelease(mInputSocketRunLoopSource);
	}
	
//  Accessors
    
    // set socket address with a port number (for listening)
    //
	void SetSocketPort(short portNumber)
	{
			// Can't change the address of a socket, so we need to reallocate
		if (mIsSocketInitialized) { DeleteInputSocket(); CreateSocket(); }
		
		mInputPortNumber = portNumber;
		struct sockaddr_in addr;        // this is system socket struct...

		addr.sin_family = AF_INET;                  // for udp/tcp, etc.
		addr.sin_addr.s_addr = htonl(INADDR_ANY);	// accept input from any address
		addr.sin_port = htons(portNumber);          // arcane byte ordering
		
        // create CF data object with addr struct just filled in
        // then use it to set the socket port
        
		CFDataRef addressData = CFDataCreateWithBytesNoCopy(NULL,  (UInt8 *)&addr, sizeof(struct sockaddr_in), kCFAllocatorNull);
		CFSocketError error = CFSocketSetAddress(mSocket, addressData);

        // ridiculously complex error message handling... 
        
		if (kCFSocketSuccess != error) {
			if (kCFSocketError == error) {
				NSLog(@"kSocketErr err %i", errno);     // general socket error
				NSDictionary* userInfo = 
					[NSDictionary 
						dictionaryWithObjectsAndKeys: 
							@"Could not start OSC listener.", NSLocalizedDescriptionKey, 
							@"Could not set addr for OSC listener socket: kCFSocketError.", NSLocalizedFailureReasonErrorKey, nil];
				NSError* errorObject = [NSError errorWithDomain: NSPOSIXErrorDomain  code: error userInfo: userInfo];
				// [[NSApplication sharedApplication] presentError: errorObject];
                NSLog(@"%@", [errorObject localizedDescription]);
			} else {
				NSLog(@"kCFSocketTimeout err %i", errno);   // socket timetout error
				NSDictionary* userInfo = 
				[NSDictionary 
					dictionaryWithObjectsAndKeys: 
						@"Could not start OSC listener.", NSLocalizedDescriptionKey, 
						@"Could not set addr for OSC listener socket: kCFSocketTimeout.", NSLocalizedFailureReasonErrorKey, nil];
				NSError* errorObject = [NSError errorWithDomain: NSPOSIXErrorDomain  code: error userInfo: userInfo];
				// [[NSApplication sharedApplication] presentError: errorObject];
                NSLog(@"%@", [errorObject localizedDescription]);
			}
		}
		
        // release CF data object - the socket retains the address data
        
		CFRelease(addressData);
		mIsSocketInitialized = true;   // set instance variable flag to show socket running
	}
	
    // accessor for msocket instance variable - this is the only way to get a pointer to the
    // current socket
    //
	CFSocketRef GetSocket() {
        return mSocket;
    }
	
public:
//  Internal Callback Functions (must be public)
    //
    // this is the callback for receiving data that runs on the socket
    // Its triggered when data shows up on the socket
    //
    // after some housekeeping it calls osc::ProcessPacket which in turn
    // calls a local virtual void method called ProcessMessage() (below) 
    // (beware the cult of polymorphism)
    // 
	static void InputSocketCallback(CFSocketRef s,            
                                    CFSocketCallBackType callbackType,  
                                    CFDataRef address,
                                    const void *primData,   // actual data
                                    void *info) {           // context ref to superclass
        
        // i don't like the scary 'reinterpret_casts'... 
        //
        // cast raw data into a CFData ref
        
		CFDataRef data = reinterpret_cast<CFDataRef>(primData);
		
        // get pointer and length of packet
		
        const char* bytes = (const char*) CFDataGetBytePtr(data);
		int bytesSize = CFDataGetLength(data);
		
		// exact source ip/port (this is working now)

        struct sockaddr_in addr;
		CFRange addrRange = { 0, sizeof(addr) };

        CFDataGetBytes(address , addrRange, (UInt8 *) &addr);
		IpEndpointName remoteEndpoint(ntohl(addr.sin_addr.s_addr), ntohs(addr.sin_port));
        
        // send this packet to be parsed for OSC messages
        
		reinterpret_cast<OMOscListener*>(info)->ProcessPacket(bytes, bytesSize, remoteEndpoint);
	}

protected:
//  Internal Functions
    //
    // actual parsing of received data... triggered by inputSocketCallback() &
    // processPacket()
    //
    // overrides the virtual function of same name in the base class...
    //
    // this is where you would add logic for processing received osc commands
    //
    //
    virtual void ProcessMessage( const osc::ReceivedMessage& m,             // message data
                                const IpEndpointName& remoteEndpoint ) {    // ip endpoint 
        
        // NSLog(@"ProcessMessage...");
        // const_iterator method parses message into tokens
        // interesting c++ syntax...
        //
        
        NSMutableArray *tokens = [[NSMutableArray alloc] init ];
        int argc;   // number of args
        
        
        
        argc = 0;   
        try {
                       
            char addressString[64];     // format source ip/port as a string
			remoteEndpoint.AddressAndPortAsString(addressString);

            
			osc::ReceivedMessage::const_iterator arg = m.ArgumentsBegin();
		
                      
            // display the message to console...
            // note this is very useful place to display received message before any parsing, etc.,

			// std::cout << (unsigned short) mInputPortNumber << " " << addressString << " " << m << std::endl;
            
            // break it down
            
            while(arg != m.ArgumentsEnd()) {
                
                // create OscArg instance
                
                OscArg *oa = [[OscArg alloc] init ];
                
                if( arg->IsBool() ){
                    bool a = (arg)->AsBoolUnchecked();
                    // std::cout << "received message with bool argument: " << a << "\n";
                    oa.mArgType = kOscBool;
                    oa.mArgBool = a;
                }
                else if( arg->IsInt32() ){
                    int a = (arg)->AsInt32Unchecked();
                    // std::cout << "received message with int32 argument: " << a << "\n";
                    oa.mArgType = kOscInt;
                    oa.mArgInt = a;
                }
                else if( arg->IsFloat() ){
                    float a = (arg)->AsFloatUnchecked();
                    // std::cout << "received message with float argument: " << a << "\n";
                    oa.mArgType = kOscFloat;
                    oa.mArgFloat = a;
                }
                else if( arg->IsString() ){
                    const char *a = (arg)->AsStringUnchecked();
                    // std::cout << "received message with string argument: '" << a << "'\n";
                    oa.mArgType = kOscString;
                    oa.mArgString = [NSString stringWithFormat:@"%s", a];
                }
                else{
                    // std::cout << "received message with unexpected argument type\n";
                    oa.mArgType = kOscOther;
                }
                [tokens addObject:oa];
                [oa release];
                arg++;
            }         
                
   
            OscMessage *om = [[OscMessage alloc ] initWithAddressPattern: [NSString stringWithFormat:@"%s", m.AddressPattern()]
                                                               arg: tokens
                                                    sourceEndpoint: [NSString stringWithFormat:@"%s", addressString]
                                                                    port: (unsigned short) mInputPortNumber];
                
                
                
            
            
            
            // at this point we'll pass the parsed message m, addressString, and mInputPortNumber
            // to a method in the wrapper - which in turn will fire off a delegate message
            //  
            
            [mParent receivedOscMessage: om ];
            

            [om release];
            
            
            
        } catch(osc::Exception& e) {
            // any parsing errors such as unexpected argument types, or 
            // missing arguments get thrown as exceptions.
			NSLog(@"Could not parse OSC %s:%s", m.AddressPattern(), e.what());
        }
    }
    
    // called by constructor to create new socket
    // 
    // setup socket
    // create socket (assign listener callback & context ref
    // then put in in a new thread
    // 
    //
	
	void CreateSocket()
	{
        
        // NSLog(@"Create Socket...");
		CFSocketContext socketContext;  // core foundation socket context

		socketContext.version = 0;
		socketContext.info = (void *) this;     // self reference for callback
		socketContext.retain = NULL;
		socketContext.release = NULL;
		socketContext.copyDescription = NULL;

        // actually create the socket
        
		mSocket = CFSocketCreate(NULL, PF_INET, SOCK_DGRAM, IPPROTO_UDP, kCFSocketDataCallBack, OMOscListener::InputSocketCallback, &socketContext);
		if (!mSocket) { NSLog(@"Failed to create socket"); return; }

        // create new thread for socket handling
        // see: www.cocoacast.com/shownotes/Episode42.pdf page 12
        // CFFunLoopGetCurrent() - does this get the current thread? yes
        
		mInputSocketRunLoopSource = CFSocketCreateRunLoopSource(NULL, mSocket, 0);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), mInputSocketRunLoopSource, kCFRunLoopCommonModes);
		mIsSocketInitialized = false;
	}
    
	// delete and release memory for existing socket
    //
	void DeleteInputSocket()
	{
		if (mSocket) {
			CFSocketInvalidate(mSocket);
			CFRelease(mSocket);
		}
	}
	
//  State
    // instance vars
    //
	OscManager*         mParent;                // ptr to parent
	short					mInputPortNumber;       // listening port
	CFSocketRef				mSocket;                // socket 
	bool					mIsSocketInitialized;   // socket init flag
	CFRunLoopSourceRef		mInputSocketRunLoopSource;  // thread run loop 
};

//////////////////////////////////////////////////////


// OscManager Class
@implementation OscManager

@synthesize delegate;
@synthesize sendEnabled;
@synthesize receiveEnabled;
@synthesize isRunning;

#pragma mark -
#pragma mark NSObject Overrides
// dealloc
- (void)dealloc
{
	delete mOSCListener;
	if (mOSCReceiverAddressData) CFRelease(mOSCReceiverAddressData);
	if (mMessageData) CFRelease(mMessageData);
	[super dealloc];
}

//  init
- (id)init
{
	if (!(self = [super init])) return nil;

    // NSLog(@"%@", NSStringFromSelector(_cmd));
    [self initOscState];
  
	return self;
}
//////////////////////////////////////////////
- (void) receivedOscMessage:(OscMessage *)om
{
    // NSLog(@"%@", NSStringFromSelector(_cmd));
    
    
    // [om print]; // display to console
    
       
    // pass Osc message to the delegate
    
    if(receiveEnabled && [delegate respondsToSelector:@selector(newMessageArrived:)])
        [delegate newMessageArrived: (OscMessage *) om];
    
}



// send an osc message
- (void) sendOscMessage:(OscMessage *)om 
{
    
    // NSLog(@"%@", NSStringFromSelector(_cmd));

    // check if sending enabled
     
    if(!sendEnabled) {
        return;
    }
    
	[self clearMessageData];
	
    // format the data into OSC
    //
    // first initialize a message buffer and clear it
    // then format the message with the slider value as float
    // then send it 
    
	osc::OutboundPacketStream p(mMessageBuffer, IP_MTU_SIZE);
	p.Clear();
	

	
    // translate Osc message object into OscPack format
    
    const char *addressPattern = [om.mAddressPattern UTF8String];
    p << osc::BeginMessage(addressPattern);
    
    for(int i = 0 ; i < [om.mArg count]; i++) {
        OscArg *oa = [om.mArg objectAtIndex:i];
    
        // note - if the case clauses aren't wrapped in {} braces you get
        // "switch case in protected scope" error
        
        switch (oa.mArgType) {
            case kOscBool: {
                p << (bool) oa.mArgBool;
                break;
            }    
            case kOscInt: {
                p << (int) oa.mArgInt;
                break;
            }    
            case kOscFloat: {
                p << (float) oa.mArgFloat;
                break;
            }    
            case kOscString: {
                const char *argStr = [oa.mArgString UTF8String];
                p << argStr;
                break;
            }   
            case kOscOther: {
                break;    
            }
            default: {
                break;
            }
        }

    }
    
    p << osc::EndMessage;
    
    
    
	CFDataAppendBytes(mMessageData, (const UInt8*) p.Data(), p.Size());
    
    // mOSCReceiverAddressData contains socket addresss for outgoing packets
    // 
    // send formatted message out over the socket
    //
    // note: the error message should go to the delegate too
    
    
	CFSocketError err = CFSocketSendData(mOSCListener->GetSocket(), mOSCReceiverAddressData, mMessageData, 0.1);
	if (kCFSocketSuccess != err) {
		// NSLog(@"Failed to send Osc Message %ld", err);
        
        // pass error message to the delegate
        if([delegate respondsToSelector:@selector(failedToSendMessage:)])
            [delegate failedToSendMessage: (CFSocketError) err];

	}
}




- (void) initOscState
{
    // this is the bare minimum for setup, without actually setting the socket...

   NSLog(@"%@", NSStringFromSelector(_cmd));
 
          
    mOSCListener = new OMOscListener(self);     // constructor to create listener, c++
    
    mOSCReceiverAddressData = NULL;
    mMessageData = NULL;
    
    
    sendEnabled = NO;
    receiveEnabled = NO;
    isRunning = NO;
    
}


// close down the socket and release all the buffers
- (void) stopOSC
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    if(mOSCListener) {
        delete mOSCListener;     // call destructor
        mOSCListener = nil;

	}
       
    if (mOSCReceiverAddressData) {
        
        CFRelease(mOSCReceiverAddressData);
        mOSCReceiverAddressData = NULL;
    }
    
    if (mMessageData) {
        
        CFRelease(mMessageData);
        mMessageData = NULL;
    }
    
    sendEnabled = NO;
    receiveEnabled = NO;
    isRunning = NO;

}

// start up socket given port numbers and ip
-(void)setOSCStateWithReceivePort: (int) receivePort 
                           sendPort: (int) sendPort 
                             sendIP: (NSString *) sendIP 
{
    // reset address data for socket
    // 
    // after this method completes, socket is ready to run...
    //
    // received data gets handled by delegate: newMessageArrived: (OscMessage *) om 
    // sent data is handled by: sendOscMessage:(OscMessage *)om    
    
    NSLog(@"setOSCState... rp %d, sp: %d, ip: %@", receivePort, sendPort, sendIP);
    
    // data conversion from obj-c types
    
    const char *ipStr = [sendIP UTF8String];
    
    unsigned short rp = (unsigned short) receivePort;
    unsigned short sp = (unsigned short) sendPort;
    
    // create listener object, set socket address, start listening
    
    if(!mOSCListener) {
        mOSCListener = new OMOscListener(self);     // constructor to create listener, c++
	}
    mOSCListener->SetSocketPort(rp);         // set socket port address
	
	
    // send send (receiver) port and ipaddress
    
    struct sockaddr_in addr;
    
	addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr(ipStr);
    
	addr.sin_port = htons(sp);   // convert byte order
    
	
    // set buffers with info from addr. above
    // then create a message data block
    // this is all thats needed for sending 
    
	if (mOSCReceiverAddressData) CFRelease(mOSCReceiverAddressData), mOSCReceiverAddressData = NULL;
	mOSCReceiverAddressData = CFDataCreate(NULL,  (UInt8 *)&addr, sizeof(struct sockaddr_in));
	
	if (mMessageData) CFRelease(mMessageData), mMessageData = NULL;
	mMessageData = CFDataCreateMutable(NULL, IP_MTU_SIZE);

    // turn on send and receive capability
    
    sendEnabled = YES;
    receiveEnabled = YES;
    isRunning = YES;

    NSLog(@"osc delegate is: %@",delegate);
}


- (void)clearMessageData
{
	CFRange range = CFRangeMake(0, CFDataGetLength(mMessageData));
	CFDataDeleteBytes(mMessageData, range);
}




@end
