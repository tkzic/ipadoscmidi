//
//  MidiEngine.m
//
//  Created by Thomas Zicarelli on 1/30/12.
//

#import "MidiEngine.h"
#import "PGMidi.h"

// app specific stuff to run commands
// 

#import "AppDelegate.h"
#import "ViewController.h"


// preference keys (for midi settings)
//
// note, that midi enpoint names will also be used as boolean preference keys
// in the key format:
//
// midiSource:<endpoint name>
// midiDestination:<endpoint name>
//
// for example: midiSource:iRigMidi
//
// these key value pairs will be added as ports are detected and will default to "on"
//

// midi settings preference keys

NSString * const appMidiEnabledPrefKey = @"appMidiEnabledPrefKey";
NSString * const appOmniModePrefKey = @"appOmniModePrefKey";
NSString * const appBaseChannelPrefKey = @"appBaseChannelPrefKey";

// for pgmidi testing
UInt8 RandomNoteNumber() {
    return (UInt8) (rand() / (RAND_MAX / 127)); 

}


@implementation MidiEngine

@synthesize midi;
@synthesize midiSourceStatus, midiDestinationStatus;
@synthesize baseChannel;
@synthesize omniMode;
@synthesize midiEnabled;

@synthesize delegate;


// override NSObject initialize method to load factory default settings into the app
// 
// note - after the very first launch of the app, preferences will be saved in
// the application domain - so these register defaults will not be used. In other words,
// whatever the user enters for the settings fields will persist between sessions
//

#pragma mark - init methods

+ (void) initialize
{
    
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys: 
                              [NSNumber numberWithBool:YES], appMidiEnabledPrefKey,
                              [NSNumber numberWithBool:YES], appOmniModePrefKey,
                              [NSNumber numberWithInt:0], appBaseChannelPrefKey,
                              nil ];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
}

- (id) init
{
    
// note: we should really check NSUser default for midi: on/off for whether or not to
// enable the network & attach to sources
//
    self = [super init];
    
    if(self) {
        
        midi = [[PGMidi alloc] init];
        [midi enableNetwork:YES];  
        midi.delegate = self;
        [self attachToAllExistingSources];
 
        [self loadUserDefaults];
        
        midiSourceStatus = nil;
        midiDestinationStatus = nil;
        
        [self resetMidiConnectionStatus];
        [self displayInterfaceStatus];
        
    }
    
    return self;
        
}



#pragma mark - engine startup/reset methods

// makes us the delegate for all sources
- (void) attachToAllExistingSources
{
    for (PGMidiSource *source in midi.sources)
    {
        source.delegate = self;
    }
}


#pragma mark -
#pragma mark Settings Handlers

// set instance vars with NSUserDefaults
- (void) loadUserDefaults
{
    
    midiEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:appMidiEnabledPrefKey];
    omniMode = [[NSUserDefaults standardUserDefaults] boolForKey:appOmniModePrefKey]; 
    baseChannel = [[NSUserDefaults standardUserDefaults] integerForKey:appBaseChannelPrefKey];

}

// set midi master switch
- (void) updateMidiEnabled:(BOOL)state  
{
    midiEnabled = state;
    
    // save state value to default settings 
    [[NSUserDefaults standardUserDefaults] setBool:midiEnabled forKey:appMidiEnabledPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];        

}

// set midi omni mode
- (void) updateOmniMode:(BOOL)state  
{
    omniMode = state;
    
    // save state value to default settings 
    [[NSUserDefaults standardUserDefaults] setBool:omniMode forKey:appOmniModePrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];        
    
}

// set midi base channel 0-15
- (void) updateBaseChannel:(int)channel  
{
    baseChannel = channel;
    
    // save channel value to default settings 
    [[NSUserDefaults standardUserDefaults] setBool:baseChannel forKey:appBaseChannelPrefKey];
    // this shouldn't be necessary, but pressing 'stop' in xcode loses un-synched data
    [[NSUserDefaults standardUserDefaults] synchronize];        
    
}


// build ivar dictionaries with on/off status of midi ports
- (void) resetMidiConnectionStatus
{
    // create the ivar dictionaries
    if(midiSourceStatus) {
        [midiSourceStatus release];
    }
    if(midiDestinationStatus) {
        [midiDestinationStatus release];
    }
    midiSourceStatus = [[NSMutableDictionary alloc] init ];
    midiDestinationStatus = [[NSMutableDictionary alloc] init ];
    
    BOOL val;
    NSString *key;
    NSObject *obj;
    
    // get midi source on/off values from NSUser defaults, or create records if they don't exist
    for (PGMidiSource *source in midi.sources)
    {
        // look for this midi source in NSUser defaults
        key = [NSString stringWithFormat:@"midiSource:%@", source.name]; 
        obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if(obj) {   // if NSUserDefault record exists for this source, then load value
            val = [[NSUserDefaults standardUserDefaults] boolForKey:key];     
        }
        else {  // no NSUserDefault record, create one and set to enabled
            val = YES;
            [[NSUserDefaults standardUserDefaults] setBool:val forKey:key];
        }
        // set instance variable with status of this midi Source
        [midiSourceStatus setObject:[NSNumber numberWithBool:val] forKey:source.name];
    }
    
    // Now do the same thing for midi destinations
    
    
    for (PGMidiDestination *destination in midi.destinations)
    {
        
        key = [NSString stringWithFormat:@"midiDestination:%@", destination.name]; 
        obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if(obj) {   
            val = [[NSUserDefaults standardUserDefaults] boolForKey:key];     
        }
        else {  
            val = YES;
            [[NSUserDefaults standardUserDefaults] setBool:val forKey:key];
        }
        
        [midiDestinationStatus setObject:[NSNumber numberWithBool:val] forKey:destination.name];
    }
    
    // synchronize any changes to user defaults
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

// view controller is telling us that user switched a port on/off
- (void) sourceStatusChangedAtIndex:(int)index status:(BOOL)status
{
    NSString *key;
    // get source name
    key = [[midi.sources objectAtIndex:index] name];
    
    // NSLog(@"key is: %@", key);
    
    // set instance variable with status of this midi Source
    [midiSourceStatus setObject:[NSNumber numberWithBool:status] forKey:key];
    
    // replace NSUser Default
    key = [NSString stringWithFormat:@"midiSource:%@", key];
    [[NSUserDefaults standardUserDefaults] setBool:status forKey:key];
    
    // synchronize
    [[NSUserDefaults standardUserDefaults] synchronize]; 
    
    
    
}

// view controller is telling us that user switched a port on/off
- (void) destinationStatusChangedAtIndex:(int)index status:(BOOL)status
{
    
    NSString *key;
    // get destination name
    key = [[midi.destinations objectAtIndex:index] name];
    
    // NSLog(@"key is: %@", key);
    
    // set instance variable with status of this midi Source
    [midiDestinationStatus setObject:[NSNumber numberWithBool:status] forKey:key];
    
    // replace NSUser Default
    key = [NSString stringWithFormat:@"midiDestination:%@", key];
    [[NSUserDefaults standardUserDefaults] setBool:status forKey:key];
    
    // synchronize
    [[NSUserDefaults standardUserDefaults] synchronize]; 
    
    
}



#pragma mark - info methods

// pgmidi info method
NSString *ToString(PGMidiConnection *connection)
{
    return [NSString stringWithFormat:@"< PGMidiConnection: name=%@ isNetwork=%d >",
            connection.name, connection.isNetworkSession];
}

// display all interfaces
- (void) listAllInterfaces
{
    
    
    [self addString:@"\n\nInterface list:"];
    for (PGMidiSource *source in midi.sources)
    {
        NSString *description = [NSString stringWithFormat:@"Source: %@", ToString(source)];
        [self addString:description];
    }
    [self addString:@""];
    for (PGMidiDestination *destination in midi.destinations)
    {
        NSString *description = [NSString stringWithFormat:@"Destination: %@", ToString(destination)];
        [self addString:description];
    }
    
}

// this was a UI thing in pgmidi, now it just does an NSLog
- (void) addString:(NSString*)string
{
    NSLog(@"%@", string);
    
}

/*
 // this shows how to count connections
 - (void) updateCountLabel
 {
 countLabel = [NSString stringWithFormat:@"sources=%u destinations=%u", midi.sources.count, midi.destinations.count];
 }
 */


// show midi interface status - for debugging
- (void) displayInterfaceStatus
{
    int i, count;
    id key; 
    BOOL value;
    
    // sources
    NSArray *keys = [midiSourceStatus allKeys];
    count = [keys count];
    for(i=0; i < count; i++) {
        key = [keys objectAtIndex:i];
        value = [[midiSourceStatus objectForKey:key] boolValue];
        
        NSLog(@"midiSource: %@, status: %d", key, value);
    }
    
    // destinations
    keys = [midiDestinationStatus allKeys];
    count = [keys count];
    for(i=0; i < count; i++) {
        key = [keys objectAtIndex:i];
        value = [[midiDestinationStatus objectForKey:key] boolValue];
        
        NSLog(@"midiDestination: %@, status: %d", key, value);
    }
    
}


#pragma mark - delegate methods for port changes

- (void) midi:(PGMidi*)midi sourceAdded:(PGMidiSource *)source
{
    source.delegate = self;
    // [self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Source added: %@", ToString(source)]];
    [self resetMidiConnectionStatus];
    
    // notify delegate
    
    if([delegate respondsToSelector:@selector(midiConnectionStatusChanged)]) {
        [delegate midiConnectionStatusChanged];
    }

}

- (void) midi:(PGMidi*)midi sourceRemoved:(PGMidiSource *)source
{
    // [self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Source removed: %@", ToString(source)]];
 
    
    [self resetMidiConnectionStatus];
    
    // notify delegate
    
    if([delegate respondsToSelector:@selector(midiConnectionStatusChanged)]) {
        [delegate midiConnectionStatusChanged];
    }
     
}



- (void) midi:(PGMidi*)midi destinationAdded:(PGMidiDestination *)destination
{
    // [self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Desintation added: %@", ToString(destination)]];
    [self resetMidiConnectionStatus];
    
    // notify delegate
    
    if([delegate respondsToSelector:@selector(midiConnectionStatusChanged)]) {
        [delegate midiConnectionStatusChanged];
    }
    
}

- (void) midi:(PGMidi*)midi destinationRemoved:(PGMidiDestination *)destination
{
    // [self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Desintation removed: %@", ToString(destination)]];
    [self resetMidiConnectionStatus];
    
    // notify delegate
    
    if([delegate respondsToSelector:@selector(midiConnectionStatusChanged)]) {
        [delegate midiConnectionStatusChanged];
    }
    
    
}


#pragma mark - more debug tests

// debugging test
- (void) killSources
{
    NSLog(@"kill sources");
    
    while([midi.sources count] > 0) {
        [midi disconnectSource:[[midi.sources objectAtIndex:0] endpoint]];
    }
  
    
}

// debugging test
- (void) killDestinations
{
    NSLog(@"kill destinations");
    
    // int count = [midi.destinations count];
    // int i;
    
    while( [midi.destinations count] > 0) {
        [midi disconnectDestination: [[midi.destinations objectAtIndex:0]endpoint]]; 
    }
   
    
}

#pragma mark - pgmidi (old) io methods

// leftover test method from original pgmidi app
- (void) sendMidiDataInBackground
{
    for (int n = 0; n < 20; ++n)
    {
        const UInt8 note      = RandomNoteNumber();
        //        NSLog(@"note number: %d", note);
        const UInt8 noteOn[]  = { 0x90, note, 127 };
        const UInt8 noteOff[] = { 0x80, note, 0   };
        
        [midi sendBytes:noteOn size:sizeof(noteOn)];
        [NSThread sleepForTimeInterval:0.1];
        [midi sendBytes:noteOff size:sizeof(noteOff)];
    }
}
- (void) sendMidiData
{
    [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
}



#pragma mark
#pragma mark receive message delegate method

// note: this is running in high priority background thread
// its a pgmidi delegate method
// try with blocks - wow it works!
- (void) midiSource:(PGMidiSource*)source midiReceived:(const MIDIPacketList *)packetList
{
    // just hand off the packetlist to the main thread for processing
    
       dispatch_async(dispatch_get_main_queue(), ^{ [self parseMidiPacketList:packetList fromSource:source]; }); 

}

#pragma mark
#pragma mark parsing and commands

//
// runs in main thread
// Parses packet list into usable MIDI messages, (with rudimentary sysex and mtc identification)
// although anything other than note, cc, pc, at, cp, pw is just ignored
//
// executes method to run midi commands
// notifies delegate 
//
- (void) parseMidiPacketList:(const MIDIPacketList *)packetList fromSource:(PGMidiSource *)source
{
   
    // NSLog(@"parseMidiPacketList: FromSource:");
       
    
    bool continueSysEx = false;         // for tracking sysex over multiple packets
    UInt16 nBytes;                      // packet length
    
    unsigned char sysExMessage[SYSEX_LENGTH];   // sysex buffer
    unsigned int sysExLength = 0;               // sysex length
    
    // message description fields
    // int messageType;
    // int messageChannel;
    int dataByte1;
    int dataByte2;    
    BOOL isActive;
    
    // bail, if midi not enabled
    if(!midiEnabled) {
        return;
    }
  
    // if packetlist isn't from an active source then bail
    isActive = [[midiSourceStatus objectForKey:source.name] boolValue];
    if(!isActive) {
        return;
    }
    
    // get the first packet 
    const MIDIPacket *packet = &packetList->packet[0];  
    
    // iterate through packet list
    for (unsigned int i = 0; i < packetList->numPackets; i++) {
        nBytes = packet->length;
        // Check if this is the end of a continued SysEx message
        if (continueSysEx) {
            unsigned int lengthToCopy = MIN (nBytes, SYSEX_LENGTH - sysExLength);
            // Copy the message into our SysEx message buffer,
            // making sure not to overrun the buffer
            memcpy(sysExMessage + sysExLength, packet->data, lengthToCopy);
            sysExLength += lengthToCopy;
            // Check if the last byte is SysEx End.
            continueSysEx = (packet->data[nBytes - 1] == 0xF7);
            if (!continueSysEx || sysExLength == SYSEX_LENGTH) {
                // We would process the (continued) SysEx message here, as it is we're just ignoring it
                // NSLog(@"sysex received %d bytes", sysExLength);
                sysExLength = 0;
            }
        } 
        else {          // not a continuation of sysex, figure out what it is
            UInt16 iByte, size;     // index into packet, size of message
            
            iByte = 0;
            while (iByte < nBytes) {    // iterate through entire packet
                // size = 0;
                
                // First byte should be status
                unsigned char status = packet->data[iByte];
                if (status < 0xC0) {    //  cc, at, note
                    size = 3;
                } 
                else if (status < 0xE0) { //  pc, cp
                    size = 2;
                } 
                else if (status < 0xF0) { // pw
                    size = 3;
                } 
                else if (status == 0xF0) {    // sysex
                    // MIDI SysEx then we copy the rest of the message into the SysEx message buffer
                    unsigned int lengthLeftInMessage = nBytes - iByte;
                    unsigned int lengthToCopy = MIN (lengthLeftInMessage, SYSEX_LENGTH);
                    
                    memcpy(sysExMessage + sysExLength, packet->data, lengthToCopy);
                    sysExLength += lengthToCopy;
                    
                    size = 0;
                    iByte = nBytes;
                    
                    // Check whether the message at the end is the end of the SysEx
                    continueSysEx = (packet->data[nBytes - 1] != 0xF7);
                } 
                else if (status == 0xF1) { // F1 quarterframe (time code with data)
                    size = 2;
                } 
                else if (status == 0xF2) { // F2 SPP
                    size = 3;    
                } 
                else if (status == 0xF3) {    // F3 songselect
                    size = 2;
                } 
                else if (status < 0xF6) {    // F4, F5 not used (error)
                    size = 0;
                    iByte = nBytes;     // skip remainder of this packet to resync
                } 
                else if (status == 0xF6) {    // F6=tunerequest
                    size = 1;
                } 
                else if (status == 0xF7) {    // F7=sysex end (error as a status byte?)
                    size = 0;
                    iByte = nBytes;     // skip remainder of this packet to resync
                } 
                else if (status < 0xFC) {    // F8->FB time code
                    size = 1;
                } 
                else if (status < 0xFE) {    // FC, FD error
                    size = 0;
                    iByte = nBytes;     // skip remainder of this packet to resync
                } 
                else if (status == 0xFE) {    // FE active sense
                    size = 1;
                } 
                else if (status == 0xFF) {    // FF reset (we really should use this)
                    size = 1;    
                } 
                else {                // my OCD compels a check for the impossible
                    size = 1;
                }
                
                // assign message type and channel from status byte
                // messageType = status & 0xF0;
                // messageChannel = status & 0xF;
                
                // assign data bytes with array bounds check
                dataByte1 =  (nBytes > iByte + 1) ? packet->data[iByte + 1] : 0;
                dataByte2 =  (nBytes > iByte + 2) ? packet->data[iByte + 2] : 0;
                
                // NSLog(@"messageType: %d, channel: %d", messageType, messageChannel);
                
       
                // hand off the message to be executed
                [self runMidiMessage:status dataByte1:dataByte1 dataByte2:dataByte2 messageSize:size fromSource:source.name];
                
                // move index pointer to beginning of next message in the packet
                iByte += size;  // note kludge above where iByte is set to nBytes to skip rest of packet
                
            }   // there may be more messages in this packet - keep processing
        }
        // read the next packet in the packet list
        packet = MIDIPacketNext(packet);
    }
    
    
    // notify delegate of incoming packet list - this can be used to blink an indicator
    
    if([delegate respondsToSelector:@selector(midiDataReceived)]) {
       [delegate midiDataReceived];
    }
    
    
/*
    // this code left in to show a compact way to monitor input
    // although it doesn't parse out multiple messages within a packet
 
    const MIDIPacket *packet = &packetList->packet[0];
    for (int i = 0; i < packetList->numPackets; ++i)
    {
        NSString *p = [[NSString alloc] initWithFormat:@"  %u bytes: [%02x,%02x,%02x]",
                       packet->length,
                       (packet->length > 0) ? packet->data[0] : 0,
                       (packet->length > 1) ? packet->data[1] : 0,
                       (packet->length > 2) ? packet->data[2] : 0
                       ];
        
        NSLog(@"packet: %@", p);
        
        // [self addString:p];
        
        
        [p release];
        packet = MIDIPacketNext(packet);
    }
*/
    
    
 
}

// called for each complete incoming midi message
//
// this is where the actual command parsing for the application occurs
//
- (void) runMidiMessage:(int)status dataByte1:(int)byte1 dataByte2:(int)byte2 messageSize:(int)size fromSource:(NSString *)source
{
    
    // unused data bytes are set to 0
    // size is actual message length
    
    int msg = status & 0xF0;
    int channel = status & 0xF;
    
    
    // for calculating data vals
    float fval;
    BOOL bval;
    // int ival;
    
    // links to instance of view where the command runs
    AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // mixer channel selected by last cc 0 message
    static int mixerChannel = 0;

    // check channel and omni mode
    if((!omniMode) && (channel != baseChannel)) {
        return;
    }
    
    // NSLog(@"channel: %d", channel);
    
    // notify delegate of message
    
    if([delegate respondsToSelector:@selector(midiMessageReceived:dataByte1:dataByte2:messageSize:sourceName:)]) {
        [delegate midiMessageReceived:status dataByte1:byte1 dataByte2:byte2 messageSize:size sourceName:source];
    }
    
    // run the command based on midi implementation table
   
    if(msg == 0xB0) {   // control change
        switch (byte1)
        {
            case 0:     // mixer channel select
                mixerChannel = byte2;
                // NSLog(@"mixerChannel set to %0d", byte2);
                break;
            case 16:    // mixer gain
                fval = (float) byte2 / 127.0;
                // NSLog(@"fval: %f", fval);
                
                if(mixerChannel == 0) {
                    app.viewController.mixerSlider0.value = fval;
                    [[app.viewController mixerSlider0] sendActionsForControlEvents:UIControlEventValueChanged];
                }
                else if(mixerChannel == 1) {
                    app.viewController.mixerSlider1.value = fval;
                    [[app.viewController mixerSlider1] sendActionsForControlEvents:UIControlEventValueChanged];
                }
                break;
            case 18:    // mixer mute
                bval = (BOOL) byte2;
                if(mixerChannel == 0) {
                    app.viewController.mixerSwitch0.on = bval;
                    [[app.viewController mixerSwitch0] sendActionsForControlEvents:UIControlEventValueChanged];
                }
                else if(mixerChannel == 1) {
                    app.viewController.mixerSwitch1.on = bval;
                    [[app.viewController mixerSwitch1] sendActionsForControlEvents:UIControlEventValueChanged];
                }
                break; 
            case 22:    // bpm
                app.viewController.metroBpmField.text = [NSString stringWithFormat:@"%d", byte2];
                [app.viewController setBpm:byte2];
                break;
                
            case 85:    // clicktype
                
                // find matching style name in segment control and select it
                // 
                app.viewController.metroStyleControl.selectedSegmentIndex = byte2;
                [[app.viewController metroStyleControl] sendActionsForControlEvents:UIControlEventValueChanged];
                break;    
            default:
                break;
        }
        return;
    }
    
    
    
    
    if(msg == 0xC0) {   // program change
        switch (byte1)
        {
            case 5:     // stop
                [[app.viewController stopButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
                return;
                break;
            case 7:     // play
                [[app.viewController playButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
                return;
                break;
            case 8:     // record
                [[app.viewController recordButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
                return;
                break;   
            default:
                break;
        }
        return;
    }
    
    // this stuff left in to show other things you may want to parse... 

    /*
    // parse data for each message
    switch (status & 0xF0) {
        case 0x80:
            NSLog(@"Note off: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
            break;
            
        case 0x90:
            NSLog(@"Note on: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
            break;
            
        case 0xA0:
            NSLog(@"Aftertouch: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
            break;
            
        case 0xB0:
            NSLog(@"Control Change: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
            break;
            
        case 0xC0:
            NSLog(@"Program Change: %d", packet->data[iByte + 1]);
            break;
            
        case 0xD0:
            NSLog(@"Channel Pressure: %d", packet->data[iByte + 1]);
            break;
            
        case 0xE0:
            NSLog(@"Pitch Bend: %d, %d", packet->data[iByte + 1], packet->data[iByte + 2]);
            break;
            
            // non-continued sysex processed here    
        default:
            NSLog(@"Some other message");
            break;
    }
*/
    
    
}

#pragma mark
#pragma mark midi send methods

// wrapper to send message out to all valid destinations
- (void) sendMidiMessage: (NSData *)midiMessage;
{
    
    // bail, if midi disabled
    if(!midiEnabled) {
        return;
    }
    
    // send message in background
    [self performSelectorInBackground:@selector(sendMidiMessageInBackground:) 
                           withObject:midiMessage];
    
}


// background thread - method to send out the message to all active destinations
// don't call this directly from the main thread!
// use 'performSelectorinBackground'
//
- (void) sendMidiMessageInBackground: (NSData *) midiMessage
{
    
    
    // unpack message from object
    UInt8 msg[3];
    [midiMessage getBytes:&msg length:[midiMessage length]];
    
    
    int i, count;
    id key; 
    BOOL isActive;
    NSArray *keys;
    
    // find active destinations
    keys = [midiDestinationStatus allKeys];
    count = [keys count];
    for(i=0; i < count; i++) {
        key = [keys objectAtIndex:i];
        isActive = [[midiDestinationStatus objectForKey:key] boolValue];
        if(isActive) {
            [midi sendBytes:msg size:[midiMessage length] toEndpointName:(NSString *) key];
            // NSLog(@"sending to midiDestination: %@, status: %d", key, isActive);
            
            // notify main thread that data was sent
            dispatch_async(dispatch_get_main_queue(), ^{ [self didSendMidiMessage:midiMessage destination:key]; }); 
            
        }
        
    }
    
}

// runs on main thread. gets notification from background that a message was
// send to a destination
- (void) didSendMidiMessage: (NSData *)midiData destination: (NSString *)dest
{
    // notify delegate
    if([delegate respondsToSelector:@selector(midiMessageSent:destination:)]) {
        [delegate midiMessageSent:midiData destination:dest];
    }
    
}



#pragma mark
#pragma mark housekeeping

- (void) dealloc
{
    [midi release];
    [midiSourceStatus release];
    [midiDestinationStatus release];
    // [messageOutData release];
    
    
    [super dealloc];
}

@end
