//
//  ViewController.m
//  ObjcOSCipad1
//
//  Created by Thomas Zicarelli on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


// note: here is template for simulating a button press...
// this effectively presses the button
//
// [recordButton sendActionsForControlEvents:UIControlEventTouchUpInside];


/*d
// preference keys (for osc settings)

NSString * const ipadosctestOscSwitchPrefKey = @"ipadosctestOscSwitchPrefKey";
NSString * const ipadosctestReceiveMessageSwitchPrefKey = @"ipadosctestReceiveMessageSwitchPrefKey";
NSString * const ipadosctestReceivePortFieldPrefKey = @"ipadosctestReceivePortFieldPrefKey";

NSString * const ipadosctestSendMessageSwitchPrefKey = @"ipadosctestSendMessageSwitchPrefKey";
NSString * const ipadosctestSendPortFieldPrefKey = @"ipadosctestSendPortFieldPrefKey";
NSString * const ipadosctestSendIPFieldPrefKey = @"ipadosctestSendIPFieldPrefKey";

*/

#import "ViewController.h"


#import <QuartzCore/QuartzCore.h>

@implementation ViewController




@synthesize incomingMessageIndicatorLabel;

@synthesize outgoingMessageIndicatorLabel;
@synthesize sendTestField;

@synthesize playButton;
@synthesize stopButton;
@synthesize recordButton;
@synthesize recordIndicatorLabel;
@synthesize transportProgressView;
@synthesize mixerSwitch0;
@synthesize mixerSlider0;
@synthesize mixerSwitch1;
@synthesize mixerSlider1;
@synthesize metroStyleControl;
@synthesize metroBpmField;
@synthesize oscSwitch;
@synthesize receiveMessageSwitch;
@synthesize receivePortField;
@synthesize sendMessageSwitch;
@synthesize sendPortField;
@synthesize sendIPField;

@synthesize oscEngine;

@synthesize isPlaying;
@synthesize isRecording;

// midi

@synthesize midiEngine;
@synthesize midiPortsTableView;

@synthesize midiMasterSwitch;
@synthesize omniModeSwitch;
@synthesize baseChannelField;

// override NSObject initialize method to load factory default settings into the app
// 
// note - after the very first launch of the app, preferences will be saved in
// the application domain - so these register defaults will not be used. In other words,
// whatever the user enters for the settings fields will persist between sessions
//

/*d
+ (void) initialize
{
  
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys: 
                              [NSNumber numberWithBool:YES], ipadosctestOscSwitchPrefKey, 
                              [NSNumber numberWithBool:YES], ipadosctestReceiveMessageSwitchPrefKey,
                              @"7400", ipadosctestReceivePortFieldPrefKey, 
                              [NSNumber numberWithBool:YES], ipadosctestSendMessageSwitchPrefKey, 
                              @"7401", ipadosctestSendPortFieldPrefKey, 
                              @"192.168.1.1", ipadosctestSendIPFieldPrefKey, 
                              nil ];
   
 
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
                              
}

*/

 
// override init to initialize some instance vars
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        // NSLog(@"viewController init...");
        incomingBlinkTimer = nil;
        outgoingBlinkTimer = nil;
        transportTimer = nil;
        
        isPlaying = NO;
        isRecording = NO;
        
       
        
       
    }
    
    return self;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // start oscEngine
    oscEngine = [[OscEngine alloc] init];
    [oscEngine setDelegate:self];
 
    // initialize UI settings fields from default engine vals
    oscSwitch.on = oscEngine.oscEnabled;
    receiveMessageSwitch.on = oscEngine.receiveMessageEnabled;
    receivePortField.text = oscEngine.receivePort;
    sendMessageSwitch.on = oscEngine.sendMessageEnabled;
    sendPortField.text = oscEngine.sendPort;
    sendIPField.text = oscEngine.sendIP;
    
    // start midiEngine
    midiEngine = [[MidiEngine alloc] init];
    [midiEngine setDelegate:self];
 
    // initialize UI settings fields from default engine vals
    
    baseChannelField.text = [NSString stringWithFormat:@"%d", [midiEngine baseChannel] + 1];
    omniModeSwitch.on = [midiEngine omniMode];
    midiMasterSwitch.on = [midiEngine midiEnabled];
    
    
    // leftover stuff from pgmidi
    // [midiEngine listAllInterfaces];
    
    // midi switch arrays for table view of available ports
  
    [self initMidiSwitches];
    
    // some other ivar defaults
    
    metroBpmField.text = @"120";
    currentMixerOutChannel = -1;    // forces a change
 
        
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [playButton release];
    playButton = nil;
    [stopButton release];
    stopButton = nil;
    [recordButton release];
    recordButton = nil;
    [mixerSwitch0 release];
    mixerSwitch0 = nil;
    [mixerSlider0 release];
    mixerSlider0 = nil;
    [mixerSwitch1 release];
    mixerSwitch1 = nil;
    [mixerSlider1 release];
    mixerSlider1 = nil;
    [metroStyleControl release];
    metroStyleControl = nil;

    [oscSwitch release];
    oscSwitch = nil;
    [receivePortField release];
    receivePortField = nil;
    [sendPortField release];
    sendPortField = nil;
    [sendIPField release];
    sendIPField = nil;
  
    [incomingMessageIndicatorLabel release];
    incomingMessageIndicatorLabel = nil;
   
    [outgoingMessageIndicatorLabel release];
    outgoingMessageIndicatorLabel = nil;
    [sendTestField release];
    sendTestField = nil;
  
  
    [self setPlayButton:nil];
    [self setStopButton:nil];
    [self setRecordButton:nil];
    [self setMixerSwitch0:nil];
    [self setMixerSlider0:nil];
    [self setMixerSwitch1:nil];
    [self setMixerSlider1:nil];
    [self setMetroStyleControl:nil];
    [self setMetroBpmField:nil];
    [self setOscSwitch:nil];
    [self setReceivePortField:nil];
    [self setSendPortField:nil];
    [self setSendIPField:nil];
    [self setIncomingMessageIndicatorLabel:nil];
    
    [self setOutgoingMessageIndicatorLabel:nil];
    [self setSendTestField:nil];
    [recordIndicatorLabel release];
    recordIndicatorLabel = nil;
    [self setRecordIndicatorLabel:nil];
    [transportProgressView release];
    transportProgressView = nil;
    [self setTransportProgressView:nil];
    [receiveMessageSwitch release];
    receiveMessageSwitch = nil;
    [sendMessageSwitch release];
    sendMessageSwitch = nil;
    [self setReceiveMessageSwitch:nil];
    [self setSendMessageSwitch:nil];
    
    // midi
    
    [midiInSwitchArray release];
    [midiOutSwitchArray release];
    
    
    
    [midiMasterSwitch release];
    midiMasterSwitch = nil;
    [omniModeSwitch release];
    omniModeSwitch = nil;
  
    [baseChannelField release];
    baseChannelField = nil;
   
    [incomingMidiMessageTextView release];
    incomingMidiMessageTextView = nil;
    [incomingOscMessageTextView release];
    incomingOscMessageTextView = nil;
    [outgoingOscMessageTextView release];
    outgoingOscMessageTextView = nil;
    [outgoingMidiMessageTextView release];
    outgoingMidiMessageTextView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // make a border around the indicator lights
    
    incomingMessageIndicatorLabel.layer.cornerRadius = 8.0f;
    incomingMessageIndicatorLabel.layer.masksToBounds = YES;
    incomingMessageIndicatorLabel.layer.borderColor=[[UIColor blackColor] CGColor];
    incomingMessageIndicatorLabel.layer.borderWidth = 1.0f;
  
    outgoingMessageIndicatorLabel.layer.cornerRadius = 8.0f;
    outgoingMessageIndicatorLabel.layer.masksToBounds = YES;
    outgoingMessageIndicatorLabel.layer.borderColor=[[UIColor blackColor] CGColor];
    outgoingMessageIndicatorLabel.layer.borderWidth = 1.0f;
  
    incomingMidiMessageIndicatorLabel.layer.cornerRadius = 8.0f;
    incomingMidiMessageIndicatorLabel.layer.masksToBounds = YES;
    incomingMidiMessageIndicatorLabel.layer.borderColor=[[UIColor blackColor] CGColor];
    incomingMidiMessageIndicatorLabel.layer.borderWidth = 1.0f;
    
    outgoingMidiMessageIndicatorLabel.layer.cornerRadius = 8.0f;
    outgoingMidiMessageIndicatorLabel.layer.masksToBounds = YES;
    outgoingMidiMessageIndicatorLabel.layer.borderColor=[[UIColor blackColor] CGColor];
    outgoingMidiMessageIndicatorLabel.layer.borderWidth = 1.0f;
    
    
    recordIndicatorLabel.layer.cornerRadius = 8.0f;
    recordIndicatorLabel.layer.masksToBounds = YES;
    recordIndicatorLabel.layer.borderColor=[[UIColor blackColor] CGColor];
    recordIndicatorLabel.layer.borderWidth = 1.0f;
    
    // rewind progressView
    transportProgressView.progress = 0.0f;
    
    // update the table view of midi connections by simulating a connection event
    
    [self midiConnectionStatusChanged];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}



/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
*/
#pragma mark
#pragma mark IBActions

- (IBAction)doPlayButton:(id)sender {
    
    UInt8 msg[3];   // midi message buffer
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // send outgoing Osc Message
    
    OscMessage *om = 
        [[OscMessage alloc ] initWithAddressPattern: @"/play" arg: nil];                                       
                                                  
    [oscEngine sendMessage:om];
    [om release];
    
    // send midi message
    
    msg[0] = 0xC0 | midiEngine.baseChannel;  // make a pc 
    msg[1] = 7;
    
    NSData *data = [NSData dataWithBytes:&msg length:2];
    [midiEngine sendMidiMessage:data];
    
       
    // check current state
    
    if(isRecording) {
        [stopButton sendActionsForControlEvents:UIControlEventTouchUpInside];   // stop
        transportProgressView.progress = 0.0f;   // rewind
    }
    
    
    if(isPlaying) {
        return;
    }
    
    
    // set button attributes
    [sender setSelected:YES];
    
       
    // start transport
    
    if(transportTimer) {
        [transportTimer invalidate];        
    }
    
    transportTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.1
									 target:self
								   selector:@selector(updateTransportProgressView:)
								   userInfo:nil
									repeats: YES];
    
    isPlaying = YES;
	
    
}

   
// callback for transport timer
- (void) updateTransportProgressView:(NSTimer *)timer
{
    
    
    CGFloat progress = transportProgressView.progress + .005;
    if(progress > 1.0) {
        progress = 0.0f;
    }
    
    transportProgressView.progress = progress; 
}


- (IBAction)doStopButton:(id)sender {
    
    UInt8 msg[3];   // midi message buffer
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // send outgoing Osc Message
    
    OscMessage *om = 
    [[OscMessage alloc ] initWithAddressPattern: @"/stop" arg: nil];                                       
    
    
    [oscEngine sendMessage:om];
    [om release];
    
    // send midi message
    msg[0] = 0xC0 | midiEngine.baseChannel;  // make a pc 
    msg[1] = 5;
    
    NSData *data = [NSData dataWithBytes:&msg length:2];
    [midiEngine sendMidiMessage:data];
    
    
    // if not playing, do a rewind
    if(!isPlaying) {
        transportProgressView.progress = 0.0f;
        return;
    }
    
    // stop the transport
    if(transportTimer) {
        [transportTimer invalidate];
        transportTimer = nil;
    }
    
    isPlaying = NO;
    [playButton setSelected:NO];
    
    isRecording = NO;
    [recordButton setSelected:NO];
    recordIndicatorLabel.backgroundColor = [UIColor whiteColor];
    
    
    }

- (IBAction)doRecordButton:(id)sender {
    
     UInt8 msg[3];   // midi message buffer
    
     NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // send outgoing Osc Message
    
    OscMessage *om = 
    [[OscMessage alloc ] initWithAddressPattern: @"/record" arg: nil];                                       
    
    [oscEngine sendMessage:om];
    [om release];
    
    // send midi message
    msg[0] = 0xC0 | midiEngine.baseChannel;  // make a pc 
    msg[1] = 8;
    
    NSData *data = [NSData dataWithBytes:&msg length:2];
    [midiEngine sendMidiMessage:data];
    

        
    // toggle selection property
    // [sender setSelected:![sender isSelected]];
    
    if(isRecording || isPlaying) {
        return;
    }
    
    // hit play
    [playButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    // set indicator light
    recordIndicatorLabel.backgroundColor = [UIColor redColor];
    
    // set button attributes
    [sender setSelected:YES];
   
     isRecording = YES;
}

// mute switches
- (IBAction)doMixerSwitch:(id)sender {
    
     UInt8 msg[3];   // midi message buffer
    
     NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // tag is source channel
    
    UISwitch *sw = (UISwitch *) sender;    // explicit cast
    
    int mixerChannel = [sw tag];    
    int val = sw.on;     
    
    // NSLog(@"mixer channel: %d, value: %d", mixerChannel, val);
    
    
    // prepare and send osc message
    [oscEngine sendMixerMessageWithCommand:@"mute" channel:mixerChannel value: (float) val valueIsFloat:NO];

    // send midi message
    
    // do we need to select the mixer channel first
    
    if(mixerChannel != currentMixerOutChannel) {
        
        currentMixerOutChannel = mixerChannel;
        
        msg[0] = 0xB0 | midiEngine.baseChannel;  // make a cc 
        msg[1] = 0;
        msg[2] = mixerChannel;
        
        NSData *data0 = [NSData dataWithBytes:&msg length:3];
        [midiEngine sendMidiMessage:data0];
    }
    
    msg[0] = 0xB0 | midiEngine.baseChannel;  // make a cc 
    msg[1] = 18;
    msg[2] = val;
    
    NSData *data1 = [NSData dataWithBytes:&msg length:3];
    [midiEngine sendMidiMessage:data1];
    
    
}

// gain sliders
- (IBAction)doMixerSlider:(id)sender {

    UInt8 msg[3];   // midi message buffer

    // NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // tag is source channel

   
    UISlider *slider = (UISlider *) sender;    // explicit cast
    
    int mixerChannel = [slider tag];     
    float val = [slider value];     
    
    // NSLog(@"mixer channel: %d, value: %f", mixerChannel, val);
    
    // prepare and send osc message
    [oscEngine sendMixerMessageWithCommand:@"gain" channel:mixerChannel value:val valueIsFloat:YES];
   
    
    // do we need to select the mixer channel first
    
    if(mixerChannel != currentMixerOutChannel) {
        
        currentMixerOutChannel = mixerChannel;
        
        msg[0] = 0xB0 | midiEngine.baseChannel;  // make a cc 
        msg[1] = 0;
        msg[2] = mixerChannel;
        
        NSData *data0 = [NSData dataWithBytes:&msg length:3];
        [midiEngine sendMidiMessage:data0];
    }
    
    msg[0] = 0xB0 | midiEngine.baseChannel;  // make a cc 
    msg[1] = 16;
    msg[2] = (UInt8) ( val * 127.0);
    
    NSData *data1 = [NSData dataWithBytes:&msg length:3];
    [midiEngine sendMidiMessage:data1];
    

    
   
}

// set metronome style
- (IBAction)doMetroStyle:(id)sender 
{
    UInt8 msg[3];   // midi message buffer
    
    UISegmentedControl *segment = (UISegmentedControl *) sender;
    
    NSString *style = [segment titleForSegmentAtIndex:[segment selectedSegmentIndex]];
    
    // format osc /clicktype message
    
    // argument array
    NSMutableArray *tokens = [[NSMutableArray alloc] init ];
    
    // arg0 is clicktype style (ie, a or b)
    OscArg *arg0 = [[OscArg alloc] init ];
    arg0.mArgType = kOscString;
    arg0.mArgString = style;
    [tokens addObject:arg0];
    [arg0 release];
    
    // send outgoing osc message
    OscMessage *om = 
    [[OscMessage alloc ] initWithAddressPattern: @"/clicktype" arg: tokens];                                       
    
    [oscEngine sendMessage:om];
    [om release];

    // send midi
    
    msg[0] = 0xB0 | midiEngine.baseChannel;  // make a cc 
    msg[1] = 85;
    msg[2] = [segment selectedSegmentIndex];
    
    NSData *data0 = [NSData dataWithBytes:&msg length:3];
    [midiEngine sendMidiMessage:data0];
    
}

#pragma mark - Osc Settings IBActions & update methods

// handle osc on/off switch
- (IBAction)doOscSwitch:(id)sender {
    
    UISwitch *sw = (UISwitch *) sender;
    [oscEngine updateOscEnabled:sw.on];
    
 /*   
    if(sw.on) {         
        NSLog(@"Osc on");
        [oscEngine  setOSCStateWithReceivePort: [receivePortField.text intValue] 
                                        sendPort: [sendPortField.text intValue]
                                          sendIP: sendIPField.text];
    }
    else {
        NSLog(@"Osc off");
        [oscEngine stopOSC];
        
        // clear the msg monitor fields
        incomingMessageLabel.text = @"";
        outgoingMessageLabel.text = @"";
        
    }
    
    // save switch value to default settings 
    
    // NSLog(@"saving osc switch = %d", sw.on);
    
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:ipadosctestOscSwitchPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];                                                    
   
  */
  
}

// toggles ability to recieve osc Messages
- (IBAction)doReceiveMessageSwitch:(id)sender {
    
    UISwitch *sw = (UISwitch *) sender;
    [oscEngine updateReceiveMessageEnabled:sw.on];
    
    /*
    oscEngine.receiveEnabled = sw.on; 
    
    // clear the msg monitor field
    incomingMessageLabel.text = @"";
   
    // save switch value to default settings 
    
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:ipadosctestReceiveMessageSwitchPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];   
    
    */
    
}


   

// toggles ability to send osc Messages
- (IBAction)doSendMessageSwitch:(id)sender {
    
     UISwitch *sw = (UISwitch *) sender;
    [oscEngine updateSendMessageEnabled:sw.on];
    
    /*
    
    oscEngine.sendEnabled = sw.on;  
    
    // clear the msg monitor fields
    outgoingMessageLabel.text = @"";
    
    // save switch value to default settings 
    
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:ipadosctestSendMessageSwitchPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];   

    */
}

#pragma mark - Midi Settings IBActions & update methods
// midi stuff


- (IBAction)doMidiMasterSwitch:(id)sender 
{
    UISwitch *sw = (UISwitch *) sender;
    [midiEngine updateMidiEnabled:sw.on];
}

- (IBAction)doOmniModeSwitch:(id)sender 
{
    UISwitch *sw = (UISwitch *) sender;
    [midiEngine updateOmniMode:sw.on];
    
       
}


- (void) setBaseChannel:(int)channel
{
    // range check
    
    if(channel < 1) {
        channel = 1;
        baseChannelField.text = [NSString stringWithFormat:@"%d", channel];
    }
    
    if(channel > 16) {
        channel = 16;
        baseChannelField.text = [NSString stringWithFormat:@"%d", channel];
    }
    
    [midiEngine updateBaseChannel:channel - 1];
    
}



#pragma mark
#pragma mark OscEngine Delegate Methods

// method that fires when osc message is sent
- (void) oscMessageSent:(OscMessage *)om
{
    // blink the indicator light
    [self startOutgoingMessageBlink];
    
    // display message text
    
    [self addStringToTextView:[om stringPrint] textView:outgoingOscMessageTextView];
    

}

// method that fires when new message data arrives
- (void) oscMessageReceived:(OscMessage *)om
{
    // NSLog(@"oscMessageReceived <delegate>");
    
    // blink the indicator
    [self startIncomingMessageBlink];
    
    // display message
    // [om print];             // to console
     
    [self addStringToTextView:[om stringPrint] textView:incomingOscMessageTextView];
}


/*
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
    
    // transport: /play, /stop, /record
    
    if([om.mAddressPattern isEqualToString:@"/play"]) {
        [playButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }
    
    if ([om.mAddressPattern isEqualToString:@"/stop"]) {
        [stopButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }
    
    if ([om.mAddressPattern isEqualToString:@"/record"]) {
        [recordButton sendActionsForControlEvents:UIControlEventTouchUpInside];
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
                    mixerSlider0.value = arg2.mArgFloat;
                    [mixerSlider0 sendActionsForControlEvents:UIControlEventValueChanged];
                    break;
                case 1:
                    mixerSlider1.value = arg2.mArgFloat;
                    [mixerSlider1 sendActionsForControlEvents:UIControlEventValueChanged];
                    break;
                default:
                    // invalid channel number
                    break;
            }
            return;
        }   // end of gain block
        
        // mute block
        if([arg0.mArgString isEqualToString:@"mute"]) {     
            // NSLog(@"running /mixer gain...");
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
                    mixerSwitch0.on = (BOOL) arg2.mArgInt;
                    [mixerSwitch0 sendActionsForControlEvents:UIControlEventValueChanged];
                    break;
                case 1:
                    mixerSwitch1.on = (BOOL) arg2.mArgInt;
                    [mixerSwitch1 sendActionsForControlEvents:UIControlEventValueChanged];
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
        for(int i = 0; i < metroStyleControl.numberOfSegments ; i++) {
            if ([arg0.mArgString isEqualToString:[metroStyleControl titleForSegmentAtIndex:i]]) {
                metroStyleControl.selectedSegmentIndex = i;
                [metroStyleControl sendActionsForControlEvents:UIControlEventValueChanged];
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
        metroBpmField.text = [NSString stringWithFormat:@"%d", arg0.mArgInt];
        [self setBpm:arg0.mArgInt];
        return; // error, no match on style name
        
    }   // end of /bpm block
    
    
    
    
    
    
    
    // drop through to here if no matching address pattern
    NSLog(@"unknown address pattern: %@", om.mAddressPattern);
    return;
    
    
    
}
 */

// generic method to add text to end of scrolling textView (like for incoming midi messages)
- (void) addStringToTextView:(NSString*)string textView: (UITextView *) textView
{
    NSString *newText = [textView.text stringByAppendingFormat:@"\n%@", string];
    textView.text = newText;
    
    // scroll textView so newest message is visible
    if (newText.length) {
        NSRange range = NSMakeRange(newText.length, 1);
        [textView scrollRangeToVisible:range];
    }
}

#pragma mark
#pragma mark - Osc indicator blinking methods

// indicator blinking methods
- (void) startIncomingMessageBlink
{
    
    // this gets called by newMessageArrived:
    
    // turn on the blink
    incomingMessageIndicatorLabel.backgroundColor = [UIColor greenColor];
	
    // set timer to turn off blink after .2 seconds
    
    if(incomingBlinkTimer) {
        [incomingBlinkTimer invalidate];        
    }
    
    incomingBlinkTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.2
									 target:self
								   selector:@selector(endIncomingMessageBlink:)
								   userInfo:nil
									repeats: NO];
	

}

// timer callback methods for message indicator lights

// turn off the blink 
- (void) endIncomingMessageBlink: (NSTimer *) timer {
	
    if(incomingBlinkTimer){
        [incomingBlinkTimer invalidate];
        
    }
    
    incomingBlinkTimer = nil;
    
    incomingMessageIndicatorLabel.backgroundColor = [UIColor whiteColor];
    
}



// indicator blinking methods
- (void) startOutgoingMessageBlink
{
    
   
    
    // turn on the blink
    outgoingMessageIndicatorLabel.backgroundColor = [UIColor greenColor];
	
    // set timer to turn off blink after .2 seconds
    
    if(outgoingBlinkTimer) {
        [outgoingBlinkTimer invalidate];        
    }
    
    outgoingBlinkTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.2
									 target:self
								   selector:@selector(endOutgoingMessageBlink:)
								   userInfo:nil
									repeats: NO];
	
    
}

// timer callback methods for message indicator lights

// turn off the blink 
- (void) endOutgoingMessageBlink: (NSTimer *) timer {
	
    if(outgoingBlinkTimer){
        [outgoingBlinkTimer invalidate];
        
    }
    
    outgoingBlinkTimer = nil;
    
    outgoingMessageIndicatorLabel.backgroundColor = [UIColor whiteColor];
    
}


#pragma mark
#pragma mark - Midi indicator blinking methods

// indicator blinking methods
- (void) startMidiIncomingMessageBlink
{
    
    // this gets called by newMessageArrived:
    
    // turn on the blink
    incomingMidiMessageIndicatorLabel.backgroundColor = [UIColor greenColor];
	
    // set timer to turn off blink after .2 seconds
    
    if(incomingMidiBlinkTimer) {
        [incomingMidiBlinkTimer invalidate];        
    }
    
    incomingMidiBlinkTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.2
									 target:self
								   selector:@selector(endMidiIncomingMessageBlink:)
								   userInfo:nil
									repeats: NO];
	
    
}

// timer callback methods for message indicator lights

// turn off the blink 
- (void) endMidiIncomingMessageBlink: (NSTimer *) timer {
	
    if(incomingMidiBlinkTimer){
        [incomingMidiBlinkTimer invalidate];
        
    }
    
    incomingMidiBlinkTimer = nil;
    
    incomingMidiMessageIndicatorLabel.backgroundColor = [UIColor whiteColor];
    
}



// indicator blinking methods
- (void) startMidiOutgoingMessageBlink
{
    
   
    
    // turn on the blink
    outgoingMidiMessageIndicatorLabel.backgroundColor = [UIColor greenColor];
	
    // set timer to turn off blink after .2 seconds
    
    if(outgoingMidiBlinkTimer) {
        [outgoingMidiBlinkTimer invalidate];        
    }
    
    outgoingMidiBlinkTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.2
									 target:self
								   selector:@selector(endMidiOutgoingMessageBlink:)
								   userInfo:nil
									repeats: NO];
	
    
}

// timer callback methods for message indicator lights

// turn off the blink 
- (void) endMidiOutgoingMessageBlink: (NSTimer *) timer {
	
    if(outgoingMidiBlinkTimer){
        [outgoingMidiBlinkTimer invalidate];
        
    }
    
    outgoingMidiBlinkTimer = nil;
    
    outgoingMidiMessageIndicatorLabel.backgroundColor = [UIColor whiteColor];
    
}



#pragma mark
#pragma mark - Table View Handlers for list of midi ports

// midi
// section 0 = sources
// section 1 = destinations

- (NSInteger) numberOfSectionsInTableView: (UITableView *)tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        NSLog(@"number of destinations: %d", [midiEngine.midi.destinations count]);
        return [midiEngine.midi.sources count];
    }
    else if(section == 1) {
        
        NSLog(@"number of destinations: %d", [midiEngine.midi.destinations count]);
        return [midiEngine.midi.destinations count];
    }
    else {
        return 0;
    }
}


- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection:(NSInteger)section
{
    
    if(section == 0) {
        return @"midi inputs";
    }
    else if(section == 1) {
        return @"midi outputs";
    }
    else {
        return nil;
    }
}
 

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // switches
    UIControl *inControl;
    UIControl *outControl;
    
    // cell allocation reuse, etc,
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
   // cell.textLabel.text = @"hello";
   // return cell;
    
    // assign data
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    NSLog(@"section %d,row: %d", section, row);
    NSString *connectionType;
    
    // NSUInteger sourceCount = [midiEngine.midi.sources count];
    
    PGMidiConnection *connection;
    
   
    // outControl = [self midiOutCtl];
    
   
    
    switch (section) {
        case 0:  
            inControl = [midiInSwitchArray objectAtIndex:row];
            connection = [midiEngine.midi.sources objectAtIndex:row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@", connection.name];
            connectionType = (connection.isNetworkSession) ? @"network" : @"cable";
            cell.detailTextLabel.text = connectionType;
            [cell.contentView addSubview:inControl];
            break;
        case 1:
            outControl = [midiOutSwitchArray objectAtIndex:row];
            connection = [midiEngine.midi.destinations objectAtIndex:row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@", connection.name];
            connectionType = (connection.isNetworkSession) ? @"network" : @"cable";
            cell.detailTextLabel.text = connectionType;
            [cell.contentView addSubview:outControl];
            break;
        default:
            cell.textLabel.text = nil;
            break;
    }
     
    
    return cell;
    
}

// create on/off switch objects that will appear in table view cells for enabling/disabling
// midi ports. Switches are kept in variable length NSArray ivars. Length depends on number
// of ports available
//
// switch arrays need to be updated when a device is added or removed
//
- (void) initMidiSwitches
{
    // init instance vars
    
    if (midiInSwitchArray) {
        [midiInSwitchArray release];
    }
    
    if (midiOutSwitchArray) {
        [midiOutSwitchArray release];
    }
    

    midiInSwitchArray = [[NSMutableArray alloc] init];    
    midiOutSwitchArray = [[NSMutableArray alloc] init];    
    

    UISwitch *sw;   // general purpose switch object
    int i;          // loop index
    
// midi sources
    
    i = 0;
    for (PGMidiSource *source in midiEngine.midi.sources) {
        CGRect frame = CGRectMake(198.0, 12.0, 94.0, 27.0);
        sw = [[UISwitch alloc] initWithFrame:frame];
        [sw addTarget:self action:@selector(doMidiInCtl:) forControlEvents:UIControlEventValueChanged];
        // set the tag
        sw.tag = i;
        // get on/off default value
        sw.on = [[midiEngine.midiSourceStatus objectForKey:source.name] boolValue];
        // add switch to ivar array
        [midiInSwitchArray addObject:sw];
        [sw release];
        i++;
    }
    
    // midi destinations
    
    i = 0;
    for (PGMidiDestination *destination in midiEngine.midi.destinations) {
        CGRect frame = CGRectMake(198.0, 12.0, 94.0, 27.0);
        sw = [[UISwitch alloc] initWithFrame:frame];
        [sw addTarget:self action:@selector(doMidiOutCtl:) forControlEvents:UIControlEventValueChanged];
        // set the tag
        sw.tag = i;
        // get on/off default value
        sw.on = [[midiEngine.midiDestinationStatus objectForKey:destination.name] boolValue];
        // add switch to ivar array
        [midiOutSwitchArray addObject:sw];
        [sw release];
        i++;
    }
    
    
    
}



// user pressed on/off switch on source midi port table view cell
- (IBAction)doMidiInCtl:(id)sender
{
    UISwitch *sw = (UISwitch *) sender;
    
    NSLog(@"doMidiInCtl tag: %d, state %d",sw.tag, sw.on );
    
    // set status in engine to reflect state of switch
    [midiEngine sourceStatusChangedAtIndex:sw.tag status:sw.on];
    
    
}
// user pressed on/off switch on destination midi port table view cell
- (IBAction)doMidiOutCtl:(id)sender
{
    
    UISwitch *sw = (UISwitch *) sender;
    
    NSLog(@"doMidiOutCtl tag: %d, state %d", sw.tag, sw.on );
    
    // set status in engine to reflect state of switch
    [midiEngine destinationStatusChangedAtIndex:sw.tag status:sw.on];

    
}

 



#pragma mark - MidiEngineDelegate methods

// respond to delegate if status of midi ports changed
- (void) midiConnectionStatusChanged

{
    NSLog(@"midiConnectionStatusChanged (delegate)");
    // update the switch table
    [self initMidiSwitches];
    // reload table view which lists midi ports
    [midiPortsTableView reloadData];
}

// note, these delegate functions can really bog down the UI if there's lots of 
// incoming or outgoing midi messages

// blink on receipt of midi packet
- (void) midiDataReceived
{
    [self startMidiIncomingMessageBlink];
}

// here is the actual incoming midi message
- (void) midiMessageReceived:(int)status dataByte1:(int)byte1 dataByte2:(int)byte2 messageSize:(int)size sourceName:(NSString *)source
{
    
    NSString *p = [NSString stringWithFormat:@"[%02x]", status];
    if(size > 1) p = [p stringByAppendingFormat:@"[%02x]", byte1];
    if(size > 2) p = [p stringByAppendingFormat:@"[%02x]", byte2]; 
     
    p = [p stringByAppendingFormat:@" from: %@", source];
       
    [self addStringToTextView:p textView:incomingMidiMessageTextView];
}
 


// message has been sent out
- (void) midiMessageSent:(NSData *)midiMessage destination:(NSString *)destination
{
    
    int i;
    UInt8 msg[3];
    [midiMessage getBytes:&msg length:[midiMessage length]];
    
    // NSLog(@"midiMessageSent(delegate) length: %d", [midiMessage length]);
    
    // make the message printable
    // NSString *p = [NSString stringWithString:@""];
    NSString *p = @"";
    for(i = 0; i < [midiMessage length]; i++) {
        p = [p stringByAppendingFormat:@"[%02x]", msg[i] ];
    }
                   
    p = [p stringByAppendingFormat:@" to:%@", destination];
    
    [self addStringToTextView:p textView:outgoingMidiMessageTextView];    
    
    [self startMidiOutgoingMessageBlink];
    
}

#pragma mark
#pragma mark - Text field Handlers

// text field delegate methods
- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    // remove keyboard
    [textField resignFirstResponder];
    return YES;
}

// edit masks
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{   
    // implement basic edit checks on textField data entry
    
    // allow backspace
    if([string length] == 0) {
        return YES;
    }
    
    int maxLength;
    
    NSCharacterSet *charSet = nil;

    NSCharacterSet *nonNumberSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSCharacterSet *nonIPSet = 
        [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
    
    
    if((textField == receivePortField) || (textField == sendPortField)) {
        charSet = nonNumberSet;
        maxLength = 5;
    }
  
    else if(textField == sendIPField) {
        charSet = nonIPSet;
        maxLength = 15;
    }
    
    else if (textField == metroBpmField) {  // bpm field
        charSet = nonNumberSet;
        maxLength = 3;
    }
    else if (textField == baseChannelField) {
        charSet = nonNumberSet;
        maxLength = 2;
    }

    // reject characters not in set
    
    if ([string stringByTrimmingCharactersInSet:charSet].length == 0) {
        return NO;
    }
    
    // restrict length to maxLength
   
    int newLength = [textField.text length] + [string length] - range.length;

    return (newLength > maxLength) ? NO : YES;

 }

// dismiss keyboard when user taps background
- (IBAction)backgroundTapped:(id)sender {
    
    [[self view] endEditing:YES];
}

// delegate method called when editing completed
- (void) textFieldDidEndEditing:(UITextField *)textField
{
    // determine text field and take action
    if(textField == metroBpmField) {
        // setBpm
        [self setBpm:[textField.text intValue]];
        return;
    }
    
    if(textField == baseChannelField) {
        [self setBaseChannel:[textField.text intValue]];
        return;
    }
    
   
    // NSLog(@"ended editing an osc setting field...");
    
    // reset Osc socket with new port data
 /*  
    if(oscSwitch.on) {
    
        [oscEngine  setOSCStateWithReceivePort: [receivePortField.text intValue] 
                                        sendPort: [sendPortField.text intValue]
                                          sendIP: sendIPField.text];
    }
  */
    
    // update user preferences

    if(textField == receivePortField) {
        [oscEngine updateReceivePort:receivePortField.text];
        
    }
    
    else if(textField == sendPortField) {
        [oscEngine updateSendPort:sendPortField.text];
    }
    
    else if(textField == sendIPField) {
        [oscEngine updateSendIP:sendIPField.text];
       
    }
    
       
    
}

// set bpm with value 
- (void) setBpm:(int) bpm
{
      UInt8 msg[3];   // midi message buffer
    
    // new bpm is already in textfield     
    
    // this is where you would insert actual code for bpm change
    
    // format osc outgoing /bpm message
    
    // argument array
    NSMutableArray *tokens = [[NSMutableArray alloc] init ];
    
    // arg0 is bpm value
    OscArg *arg0 = [[OscArg alloc] init ];
    arg0.mArgType = kOscInt;
    arg0.mArgInt = bpm;
    [tokens addObject:arg0];
    [arg0 release];
    
    // send outgoing osc message
    OscMessage *om = 
    [[OscMessage alloc ] initWithAddressPattern: @"/bpm" arg: tokens];                                       
    
    [oscEngine sendMessage:om];
    [om release];
    
    // send midi
    // need to do actual scaling
    int scaledBpm = bpm;
    if(scaledBpm < 0) scaledBpm = 0;
    if(scaledBpm > 127) scaledBpm = 127;
    
    msg[0] = 0xB0 | midiEngine.baseChannel;  // make a cc 
    msg[1] = 22;
    msg[2] = scaledBpm;
    
    NSData *data0 = [NSData dataWithBytes:&msg length:3];
    [midiEngine sendMidiMessage:data0];
    
    
}

#pragma mark - housekeeping

- (void)dealloc {
    [playButton release];
    [stopButton release];
    [recordButton release];
    [mixerSwitch0 release];
    [mixerSlider0 release];
    [mixerSwitch1 release];
    [mixerSlider1 release];
    [metroStyleControl release];
   
   
    [receivePortField release];
    [sendPortField release];
    [sendIPField release];

    [incomingMessageIndicatorLabel release];
 
    [outgoingMessageIndicatorLabel release];
    [sendTestField release];
  
   
    [playButton release];
    [stopButton release];
    [recordButton release];
    [mixerSwitch0 release];
    [mixerSlider0 release];
    [mixerSwitch1 release];
    [mixerSlider1 release];
    [metroStyleControl release];
    [metroBpmField release];
    [oscSwitch release];
    [receivePortField release];
    [sendPortField release];
    [sendIPField release];
    
    [incomingMessageIndicatorLabel release];
    
    [outgoingMessageIndicatorLabel release];
    [sendTestField release];
    [recordIndicatorLabel release];
    [recordIndicatorLabel release];
    [transportProgressView release];
    [transportProgressView release];
    [receiveMessageSwitch release];
    [sendMessageSwitch release];
    [receiveMessageSwitch release];
    [sendMessageSwitch release];
    
    // midi
    
    [midiInSwitchArray release];
    [midiOutSwitchArray release];
    
    [midiMasterSwitch release];
    [omniModeSwitch release];
   
    [baseChannelField release];
    
    [incomingMidiMessageTextView release];
    [incomingOscMessageTextView release];
    [outgoingOscMessageTextView release];
    [outgoingMidiMessageTextView release];
    [super dealloc];
}
@end
