//
//  OscEngine.h
//  
//
//  Created by Thomas Zicarelli on 2/8/2012
//
//  A generic wrapper for Osc implementation 
//  which can be implemented from a view controller
//
//  the view controller should provide controls for settings
//  delegate methods are provided to display incoming/outgoing message data
//  
//  the only thing you would definitely need to change are the command parsing methods

#import <Foundation/Foundation.h>
#import "OscManager.h"

@protocol OscEngineDelegate <NSObject>

@optional
// - (void) oscDataReceived;
- (void) oscMessageReceived: (OscMessage *) om;
- (void) oscMessageSent: (OscMessage *) om;

@end

@interface OscEngine : NSObject  <OscManagerDelegate> 
{
    //settings

    BOOL oscEnabled;
    BOOL receiveMessageEnabled;
    BOOL sendMessageEnabled;
    BOOL feedbackGateOpen;
    
    NSString *receivePort;   
    NSString *sendPort;
    NSString *sendIP;
    
    OscManager *oscManager;
    
    
}


@property (nonatomic, assign)  BOOL oscEnabled;
@property (nonatomic, assign)  BOOL receiveMessageEnabled;
@property (nonatomic, assign)  BOOL sendMessageEnabled;
@property (nonatomic, assign)  BOOL feedbackGateOpen;

@property (nonatomic, copy) NSString *receivePort;
@property (nonatomic, copy) NSString *sendPort;
@property (nonatomic, copy) NSString *sendIP;

@property (nonatomic, retain) OscManager *oscManager;

@property (nonatomic, assign ) id <OscEngineDelegate> delegate;

// settings & settings instance var update methods

- (void) loadUserDefaults;

- (void) updateOscEnabled: (BOOL) state;
- (void) updateReceiveMessageEnabled:(BOOL) state;
- (void) updateSendMessageEnabled:(BOOL) state;

- (void) updateReceivePort: (NSString *) port;
- (void) updateSendPort: (NSString *) port;
- (void) updateSendIP: (NSString *) IP;

// osc parsing formatting

- (void) parseAndRun: (OscMessage *) om;
- (void) sendMixerMessageWithCommand:(NSString *)cmd channel:(int)chan value:(float)val valueIsFloat:(BOOL)valIsFloat;

// osc IO

- (void) sendMessage: (OscMessage *) om;


@end


