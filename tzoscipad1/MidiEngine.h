//
//  MidiEngine.h
//
//  Created by Thomas Zicarelli on 1/30/12.
//
//  A generic wrapper for Midi implementation 
//  which can be implemented from a view controller
//
//  the view controller should provide controls for settings
// 
//  delegate methods are provided to display incoming/outgoing message data
//  
//  the only thing you would definitely need to change are the command parsing methods

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

#import "PGMidi.h"

// max length of sysex message
#define SYSEX_LENGTH 1024

UInt8 RandomNoteNumber();   // for pgmidi test

@protocol MidiEngineDelegate <NSObject>

@optional
- (void) midiConnectionStatusChanged;
- (void) midiDataReceived;
- (void) midiMessageReceived: (int) status 
                   dataByte1: (int) byte1 
                   dataByte2: (int) byte2 
                   messageSize: (int) size
                  sourceName: (NSString *) source;

- (void) midiMessageSent: (NSData *)midiMessage destination: (NSString *) destination;

//- (void) midiDataSent;

@end


@interface MidiEngine : NSObject <PGMidiDelegate, PGMidiSourceDelegate>
{
    PGMidi *midi;

    
    // flags to process or ignore midi data based on connection name
    //
    // key is endpoint name
    // value is encoded boolean, yes=active, no=inactive
    //
    // these settings don't actually disable the ports, but the engine provides IO methods
    // that an app can use which respect the settings
    //
    
    NSMutableDictionary *midiSourceStatus;
    NSMutableDictionary *midiDestinationStatus;
    
    BOOL omniMode;
    int baseChannel;                    // 0->15
    
    // Note that the midiEnabled (master switch) is just a flag - it doesn't actually
    // enable or disable midi ports - because most likely the user interface will want
    // to have a current list of available ports even if the application elects not to 
    // globally send and receive midi data
    
    BOOL midiEnabled;                   // master switch

}

@property (nonatomic, assign ) id <MidiEngineDelegate> delegate;

@property (nonatomic,assign) PGMidi *midi;

@property (nonatomic,copy) NSMutableDictionary *midiSourceStatus;
@property (nonatomic,copy) NSMutableDictionary *midiDestinationStatus;

@property (nonatomic, assign) int baseChannel;
@property (nonatomic, assign) BOOL omniMode;
@property (nonatomic, assign) BOOL midiEnabled;


- (void) addString:(NSString*)string;   // (pgmidi) alias for nslog


// io methods

// pgmidi test stuff
- (void) sendMidiDataInBackground;
- (void) sendMidiData;

// actual io methods
- (void) sendMidiMessage: (NSData *) midiMessage; 
- (void) didSendMidiMessage: (NSData *)midiData destination: (NSString *)dest;
- (void) sendMidiMessageInBackground: (NSData *) midiMessage;


// info methods
- (void) listAllInterfaces;
NSString *ToString(PGMidiConnection *connection);
- (void) displayInterfaceStatus;

// parsing & formatting methods
- (void) parseMidiPacketList: (const MIDIPacketList *) packetList fromSource: (PGMidiSource *) source;

- (void) runMidiMessage: (int) status 
              dataByte1: (int) byte1 
              dataByte2: (int) byte2 
            messageSize: (int) size
             fromSource: (NSString *) source;


// engine startup/reset methods

- (void) attachToAllExistingSources;

// settings update methods

- (void) sourceStatusChangedAtIndex: (int) index 
                            status: (BOOL)status;

- (void) destinationStatusChangedAtIndex: (int) index 
                          status: (BOOL)status;

- (void) resetMidiConnectionStatus;

- (void) updateBaseChannel: (int) channel;
- (void) updateOmniMode: (BOOL) state;
- (void) updateMidiEnabled: (BOOL) state;

- (void) loadUserDefaults;

// debugging methods
- (void) killSources;
- (void) killDestinations;


@end
