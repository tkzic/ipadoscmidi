//
//  OscEngine.m
//  app
//
//  Created by Thomas Zicarelli on 1/24/12.
//



// note: here is template for simulating a button press...
// this effectively presses the button
//
// [recordButton sendActionsForControlEvents:UIControlEventTouchUpInside];

// preference keys (for osc settings)


NSString * const appOscEnabledPrefKey = @"appOscEnabledPrefKey";
NSString * const appReceiveMessageEnabledPrefKey = @"appReceiveMessageEnbaledPrefKey";
NSString * const appReceivePortPrefKey = @"appReceivePortPrefKey";

NSString * const appSendMessageEnabledPrefKey = @"appSendMessageEnabledPrefKey";
NSString * const appSendPortPrefKey = @"appSendPortPrefKey";
NSString * const appSendIPPrefKey = @"appSendIPPrefKey";


#import "OscEngine.h"

// the app needs to to supply header files with methods to be called from the parser

#import "AppDelegate.h"
#import "ViewController.h"

// #import "appAppDelegate.h"
// #import "TransportBarViewController.h"


@implementation OscEngine

@synthesize oscEnabled;
@synthesize receiveMessageEnabled;
@synthesize receivePort;
@synthesize sendMessageEnabled;

@synthesize sendPort;
@synthesize sendIP;

@synthesize oscManager;
@synthesize delegate;

@synthesize feedbackGateOpen;

#pragma mark - init methods

// override NSObject initialize method to load factory default settings into the app
// 
// note - after the very first launch of the app, preferences will be saved in
// the application domain - so these register defaults will not be used. In other words,
// whatever the user enters for the settings fields will persist between sessions
//

+ (void) initialize
{
    
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys: 
                              [NSNumber numberWithBool:YES], appOscEnabledPrefKey,
                              [NSNumber numberWithBool:YES], appReceiveMessageEnabledPrefKey,
                              @"7400", appReceivePortPrefKey, 
                              [NSNumber numberWithBool:YES], appSendMessageEnabledPrefKey, 
                              @"7401", appSendPortPrefKey, 
                              @"192.168.1.107", appSendIPPrefKey, 
                              nil ];
    
    
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
}


- (id) init
{
    
    self = [super init];
    
    if(self) {
       
        oscManager = [[OscManager alloc] init];
        [oscManager setDelegate:self ];

         [self loadUserDefaults];
        
        // set Osc engine using defaults
        
        if(oscEnabled) {         
            
            [oscManager  setOSCStateWithReceivePort: [receivePort intValue] 
                                          sendPort: [sendPort intValue]
                                            sendIP: sendIP];
        }
        else {
            
            [oscManager stopOSC];
            
        }
        
        oscManager.receiveEnabled = receiveMessageEnabled; 
        oscManager.sendEnabled = sendMessageEnabled;
        
        feedbackGateOpen = YES; // will be used to prevent controller fb loops
        
    }
    
    return self;
    
}


#pragma mark -
#pragma mark Settings Handlers

// set instance vars with NSUserDefaults
- (void) loadUserDefaults
{
    
    oscEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:appOscEnabledPrefKey];
    
    
    receiveMessageEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:appReceiveMessageEnabledPrefKey]; 
    
    receivePort = [[NSUserDefaults standardUserDefaults] objectForKey:appReceivePortPrefKey];
    
    sendMessageEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:appSendMessageEnabledPrefKey];
    
    sendPort = [[NSUserDefaults standardUserDefaults] objectForKey:appSendPortPrefKey];
    
    sendIP = [[NSUserDefaults standardUserDefaults] objectForKey:appSendIPPrefKey];
}


// handle osc on/off switch
- (void) updateOscEnabled: (BOOL) state {
        
    oscEnabled = state;
    
    if(state) {         
        NSLog(@"Osc on");
        [oscManager  setOSCStateWithReceivePort: [receivePort intValue] 
                                      sendPort: [sendPort intValue]
                                        sendIP: sendIP];
    }
    else {
        NSLog(@"Osc off");
        [oscManager stopOSC];
        
    }
    
    // save switch value to default settings 
    [[NSUserDefaults standardUserDefaults] setBool:oscEnabled forKey:appOscEnabledPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];                                                    
    
}

// toggles ability to recieve osc Messages
- (void) updateReceiveMessageEnabled:(BOOL) state {
    
    receiveMessageEnabled = state;
    oscManager.receiveEnabled = state; 
    
    // save switch value to default settings 
    
    [[NSUserDefaults standardUserDefaults] setBool:receiveMessageEnabled forKey:appReceiveMessageEnabledPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];   
    
}

// toggles ability to send osc Messages
- (void) updateSendMessageEnabled:(BOOL) state {
    
    sendMessageEnabled = state;
    oscManager.sendEnabled = state; 
    
    // save switch value to default settings 
    
    [[NSUserDefaults standardUserDefaults] setBool:sendMessageEnabled forKey:appSendMessageEnabledPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];   
    
}

- (void) updateReceivePort: (NSString *) port
{
    
    receivePort = port;
    
    // if active, reset the socket with current address
    if(oscEnabled) {
        [oscManager  setOSCStateWithReceivePort: [receivePort intValue] 
                                      sendPort: [sendPort intValue]
                                        sendIP: sendIP];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:receivePort forKey:appReceivePortPrefKey];
    
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];  
       
}
- (void) updateSendPort: (NSString *) port
{
    
    sendPort = port;
   
    // if active, reset the socket with current address
    if(oscEnabled) {
        [oscManager  setOSCStateWithReceivePort: [receivePort intValue] 
                                      sendPort: [sendPort intValue]
                                        sendIP: sendIP];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:sendPort forKey:appSendPortPrefKey];
    
    
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];  
    
}
- (void) updateSendIP: (NSString *) IP
{
    sendIP = IP;
    
    // if active, reset the socket with current address
    if(oscEnabled) {
        [oscManager  setOSCStateWithReceivePort: [receivePort intValue] 
                                      sendPort: [sendPort intValue]
                                        sendIP: sendIP];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:sendIP forKey:appSendIPPrefKey];
    
    
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];  
    
}

  


#pragma mark -
#pragma mark Osc IO

// wrapper to send outgoing osc messages
- (void) sendMessage:(OscMessage *)om
{
    
    
    if(oscEnabled && sendMessageEnabled && feedbackGateOpen) {
        [oscManager sendOscMessage:om];
        
        // notify delegate
            if([delegate respondsToSelector:@selector(oscMessageSent:)]) {
                [delegate oscMessageSent:om];
            }
        
        // display message text
        // outgoingMessageLabel.text = [om stringPrint];
        
    }
}


#pragma mark -
#pragma mark Osc Delegate Methods

// error occurred in sending message
- (void) failedToSendMessage:(CFSocketError)err
{
    NSLog(@"failed to send message. CFSocketErr: %ld", err);
}

// delegate that fires when new message data arrives
- (void) newMessageArrived: (OscMessage *) om
{
    // NSLog(@"newMessageArrived <delegate>");
    
    // display message
    // [om print];             // to console
    // incomingMessageLabel.text = [om stringPrint]; // to field
    
    if(oscEnabled && receiveMessageEnabled) {
       
        feedbackGateOpen = NO;   // close gate to prevent feedback
        [self parseAndRun:om];   // execute osc command
        feedbackGateOpen = YES;  // reopen the gate
    
        //notify delegate
        if([delegate respondsToSelector:@selector(oscMessageReceived:)])
            [delegate oscMessageReceived: (OscMessage *) om];
    }
    
    
}

#pragma mark -
#pragma mark app command parser & formatting methods

// parse and run an osc command (this is hard coded command spec)
- (void) parseAndRun:(OscMessage *)om
{
    
    // an old-school parser using address pattern matching blocks
    //
    // three possible outcomes
    //
    // 1. command matches syntax pattern and is executed , return
    // 2. syntax error within block, return
    // 3. drops through to end without matching an address pattern, return 
    
    // there is currently no action taken with syntax errors, or unkown address pattern.
    // and no range checking of parameter values
    
 //   appAppDelegate *app = (appAppDelegate *) [[UIApplication sharedApplication] delegate];
    AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // Note: this example demonstrates 'faking' the gesture for the control 
    // the advantage to doing it this way is that any UI details associated with
    // touch events will occur
    
    // transport:  /stop, /play, /record
    // 0,1,2 respectively on transportSegmentedControl
       

    if ([om.mAddressPattern isEqualToString:@"/stop"]) {
        [[app.viewController stopButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
        //[app.viewController doStopButton:nil];
        return;
    }
    
     
    
    if ([om.mAddressPattern isEqualToString:@"/play"]) {
        [[app.viewController  playButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
        // [app.viewController doPlayButton:nil];
        return;
    }   
    
    
    
    if ([om.mAddressPattern isEqualToString:@"/record"]) {
        [[app.viewController  recordButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }   
     
    
    // /mixer
    
    
    if ([om.mAddressPattern isEqualToString:@"/mixer"]) {
        // check number of args - should be three (cmd channel value)
        if([om.mArg count] < 3) {
            return; // syntax error, not enough args
        }
        // select command based on arg0
        OscArg *arg0 = [om.mArg objectAtIndex:0];
        if(arg0.mArgType != kOscString) {
            return;  // syntax error, arg is not a string
        }
        
        // gain block
        if([arg0.mArgString isEqualToString:@"gain"]) {     
            // NSLog(@"running /mixer gain...");
            // arg1 is channel number
            OscArg *arg1 = [om.mArg objectAtIndex:1];
            if(arg1.mArgType != kOscInt) {
                return;  // syntax error, not type int
            }
            // get value arg (ie, gain level)
            OscArg *arg2 = [om.mArg objectAtIndex:2];
            if(arg2.mArgType != kOscFloat) {
                return;  // syntax error, not type float
            }
            // breakout by channel number
            //
            // when executing command, first set the control value using IBOutlet,
            // then trigger IBAction method by generating event.
            // This should be equivalent to the control being triggered by touch gesture
            //
            switch (arg1.mArgInt) {
                case 0:
                    app.viewController.mixerSlider0.value = arg2.mArgFloat;
                    [[app.viewController mixerSlider0] sendActionsForControlEvents:UIControlEventValueChanged];
                    // NSLog(@"osc will trigger mixer 0 gain");
                    break;
                case 1:
                    app.viewController.mixerSlider1.value = arg2.mArgFloat;
                    [[app.viewController mixerSlider1] sendActionsForControlEvents:UIControlEventValueChanged];
                    // NSLog(@"osc will trigger mixer 1 gain");
                    break;
                default:
                    // invalid channel number
                    break;
            }
            return;
        }   // end of gain block
        
        // mute block
        if([arg0.mArgString isEqualToString:@"mute"]) {     
            // NSLog(@"running /mixer mute...");
            // arg1 is channel number
            OscArg *arg1 = [om.mArg objectAtIndex:1];
            if(arg1.mArgType != kOscInt) {
                return;  // syntax error, not type int
            }
            // get value arg (ie 0=off, 1=on)
            OscArg *arg2 = [om.mArg objectAtIndex:2];
            if(arg2.mArgType != kOscInt) {
                return;  // syntax error, not type int
            }
            // breakout by channel number
            //
            // when executing command, first set the control value using IBOutlet,
            // then trigger IBAction method by generating event.
            // This should be equivalent to the control being triggered by touch gesture
            //
            switch (arg1.mArgInt) {
                case 0:
                    app.viewController.mixerSwitch0.on = (BOOL) arg2.mArgInt;
                    [[app.viewController mixerSwitch0] sendActionsForControlEvents:UIControlEventValueChanged];
                    // NSLog(@"osc will trigger mixer 0 mute button");
                    break;
                case 1:
                    app.viewController.mixerSwitch1.on = (BOOL) arg2.mArgInt;
                    [[app.viewController mixerSwitch1] sendActionsForControlEvents:UIControlEventValueChanged];
                    // NSLog(@"osc will trigger mixer 1 mute button");
                    break;
                default:
                    // invalid channel number
                    break;
            }
            return;
        }   // end of mute block
        
        
        
        
        NSLog(@"/mixer: unknown command: %@", arg0 );
        return;
    }   // end of /mixer block
    
    
    // /clicktype
    
    
    if ([om.mAddressPattern isEqualToString:@"/clicktype"]) {
        // check number of args - should be 1 (style)
        if([om.mArg count] < 1) {
            return; // syntax error, not enough args
        }
        // get style name from arg0
        OscArg *arg0 = [om.mArg objectAtIndex:0];
        if(arg0.mArgType != kOscString) {
            return;  // syntax error, not type string
        }
        // find matching style name in segment control and select it
        // 
         for(int i = 0; i < app.viewController.metroStyleControl.numberOfSegments ; i++) {
            if ([arg0.mArgString isEqualToString:[app.viewController.metroStyleControl titleForSegmentAtIndex:i]]) {
                app.viewController.metroStyleControl.selectedSegmentIndex = i;
                [[app.viewController metroStyleControl] sendActionsForControlEvents:UIControlEventValueChanged];
                return;
            }
         }
        
        return; // error, no match on style name
        
    }   // end of /clicktype block
    
    
    
    // /bpm
    
    
    if ([om.mAddressPattern isEqualToString:@"/bpm"]) {
        // check number of args - should be 1 (value)
        if([om.mArg count] < 1) {
            return; // syntax error, not enough args
        }
        // get bpm value from arg0
        OscArg *arg0 = [om.mArg objectAtIndex:0];
        if(arg0.mArgType != kOscInt) {
            return;  // syntax error, not type integer
        }
        // run
        app.viewController.metroBpmField.text = [NSString stringWithFormat:@"%d", arg0.mArgInt];
        [app.viewController setBpm:arg0.mArgInt];
        // NSLog(@"osc will trigger bpm: %d", arg0.mArgInt);
        return;
        
    }   // end of /bpm block
    
    
    
    
    
    
    
    // drop through to here if no matching address pattern
    NSLog(@"unknown address pattern: %@", om.mAddressPattern);
    return;
    
    
    
}

//  method to format and send osc mixer messages
- (void) sendMixerMessageWithCommand:(NSString *)cmd channel:(int)chan value:(float)val valueIsFloat:(BOOL)valIsFloat
{
    
    // msg style is: /mixer <cmd> <chan> <val>
    // eg., /mixer gain 1 0.4
    
    // format args: 
    
    // argument array
    NSMutableArray *tokens = [[NSMutableArray alloc] init ];
    
    // arg0 is command type (ie, 'gain')
    OscArg *arg0 = [[OscArg alloc] init ];
    arg0.mArgType = kOscString;
    arg0.mArgString = cmd;
    [tokens addObject:arg0];
    [arg0 release];
    
    // arg1 is channel number
    OscArg *arg1 = [[OscArg alloc] init ];
    arg1.mArgType = kOscInt;
    arg1.mArgInt = chan;
    [tokens addObject:arg1];
    [arg1 release];
    
    // arg2 is control value (ie, gain slider value)
    
    OscArg *arg2 = [[OscArg alloc] init ];
    if(valIsFloat) {
        arg2.mArgType = kOscFloat;
        arg2.mArgFloat = val;
    }
    else {  // cast to int for switches
        arg2.mArgType = kOscInt;
        arg2.mArgInt = (int) val;
    }
    [tokens addObject:arg2];
    [arg2 release];
    
    // send outgoing osc message
    OscMessage *om = 
    [[OscMessage alloc ] initWithAddressPattern: @"/mixer" arg: tokens];  
   
    
    [self sendMessage:om];
    [om release];   // i believe this also releases tokens array
    
    
}




#pragma mark -
#pragma mark housekeeping

- (void)dealloc {
    
    
    [receivePort release];
    [sendPort release];
    [sendIP release];
    
    [oscManager release];
    
    
    [super dealloc];
}


@end




