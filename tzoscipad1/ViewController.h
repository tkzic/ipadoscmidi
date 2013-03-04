//
//  ViewController.h
//  ObjcOSCipad1
//
//  Created by Thomas Zicarelli on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "OscEngine.h"
#import "MidiEngine.h"

@interface ViewController : UIViewController <OscEngineDelegate, MidiEngineDelegate, UITextFieldDelegate, UITableViewDelegate> 
{

    IBOutlet UIButton *playButton;
    IBOutlet UIButton *stopButton;
    IBOutlet UIButton *recordButton;
    IBOutlet UILabel *recordIndicatorLabel;
    IBOutlet UIProgressView *transportProgressView;
    
    
    IBOutlet UISwitch *mixerSwitch0;
    IBOutlet UISlider *mixerSlider0;
    IBOutlet UISwitch *mixerSwitch1;
    IBOutlet UISlider *mixerSlider1;
    
    
    IBOutlet UISegmentedControl *metroStyleControl;
    IBOutlet UITextField *metroBpmField;
    
    //settings
    
    IBOutlet UISwitch *oscSwitch;
    
    IBOutlet UISwitch *receiveMessageSwitch;
    IBOutlet UITextField *receivePortField;
    
    IBOutlet UISwitch *sendMessageSwitch;
    IBOutlet UITextField *sendPortField;
    IBOutlet UITextField *sendIPField;
    
    // monitor
    
    
    IBOutlet UILabel *incomingMessageIndicatorLabel;
    IBOutlet UITextView *incomingOscMessageTextView;
    
    
    
  
    IBOutlet UILabel *outgoingMessageIndicatorLabel;
    IBOutlet UITextView *outgoingOscMessageTextView;
   
    NSTimer *incomingBlinkTimer;
    NSTimer *outgoingBlinkTimer;
    
    IBOutlet UITextField *sendTestField;
    
    // midi monitor
    
    
    
  
    IBOutlet UILabel *incomingMidiMessageIndicatorLabel;
    IBOutlet UITextView *incomingMidiMessageTextView;
    
    
   
    IBOutlet UILabel *outgoingMidiMessageIndicatorLabel;
    IBOutlet UITextView *outgoingMidiMessageTextView;

    NSTimer *incomingMidiBlinkTimer;
    NSTimer *outgoingMidiBlinkTimer;
    
    //
    
    OscEngine *oscEngine;
    
    
   
    NSTimer *transportTimer;
    
    BOOL isPlaying;
    BOOL isRecording;
    
    // midi stuff
    
    MidiEngine *midiEngine;
    
    int currentMixerOutChannel;    // for sending midi mixer out msgs 
    
    IBOutlet UISwitch *midiMasterSwitch;
    
    IBOutlet UITextField *baseChannelField;
    IBOutlet UISwitch *omniModeSwitch;
   
    IBOutlet UITableView *midiPortsTableView;
    
    NSMutableArray  *midiInSwitchArray;
    NSMutableArray  *midiOutSwitchArray;
    
   
    
    
//    OscMessage *oscMessage;
    
}


@property (retain, nonatomic) IBOutlet UIButton *playButton;
@property (retain, nonatomic) IBOutlet UIButton *stopButton;
@property (retain, nonatomic) IBOutlet UIButton *recordButton;
@property (retain, nonatomic) IBOutlet UILabel *recordIndicatorLabel;
@property (retain, nonatomic) IBOutlet UIProgressView *transportProgressView;


@property (retain, nonatomic) IBOutlet UISwitch *mixerSwitch0;
@property (retain, nonatomic) IBOutlet UISlider *mixerSlider0;
@property (retain, nonatomic) IBOutlet UISwitch *mixerSwitch1;
@property (retain, nonatomic) IBOutlet UISlider *mixerSlider1;

@property (retain, nonatomic) IBOutlet UISegmentedControl *metroStyleControl;
@property (retain, nonatomic) IBOutlet UITextField *metroBpmField;

@property (retain, nonatomic) IBOutlet UISwitch *oscSwitch;
@property (retain, nonatomic) IBOutlet UISwitch *receiveMessageSwitch;
@property (retain, nonatomic) IBOutlet UITextField *receivePortField;
@property (retain, nonatomic) IBOutlet UISwitch *sendMessageSwitch;
@property (retain, nonatomic) IBOutlet UITextField *sendPortField;
@property (retain, nonatomic) IBOutlet UITextField *sendIPField;

@property (retain, nonatomic) IBOutlet UISwitch *midiMasterSwitch;
@property (retain, nonatomic) IBOutlet UITextField *baseChannelField;
@property (retain, nonatomic) IBOutlet UISwitch *omniModeSwitch;


@property (retain, nonatomic) IBOutlet UILabel *incomingMessageIndicatorLabel;

@property (retain, nonatomic) IBOutlet UILabel *outgoingMessageIndicatorLabel;

@property (retain, nonatomic) IBOutlet UITextField *sendTestField;

@property (nonatomic, retain) OscEngine *oscEngine;

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isRecording;

// midi


@property (nonatomic, retain) MidiEngine *midiEngine;

@property (nonatomic, retain) IBOutlet UITableView *midiPortsTableView;

// UI simulator controls

- (IBAction)doPlayButton:(id)sender;
- (IBAction)doStopButton:(id)sender;
- (IBAction)doRecordButton:(id)sender;

- (IBAction)doMixerSwitch:(id)sender;
- (IBAction)doMixerSlider:(id)sender;

- (IBAction)doMetroStyle:(id)sender;

// osc settings

- (IBAction)doOscSwitch:(UISwitch *)sender;

- (IBAction)doReceiveMessageSwitch:(id)sender;
- (IBAction)doSendMessageSwitch:(id)sender;


// midi settings

- (IBAction)doMidiMasterSwitch:(id)sender;
- (IBAction)doOmniModeSwitch:(id)sender;
- (void) setBaseChannel: (int) channel;

// midi table view handlers

- (IBAction)doMidiInCtl:(id)sender;
- (IBAction)doMidiOutCtl:(id)sender;

- (void) initMidiSwitches;

// midi blink monitor methods

- (void) startMidiIncomingMessageBlink;
- (void) endMidiIncomingMessageBlink: (NSTimer *)timer;

- (void) startMidiOutgoingMessageBlink;
- (void) endMidiOutgoingMessageBlink: (NSTimer *)timer;

// text field handlers

- (IBAction)backgroundTapped:(id)sender;

// UI update methods

- (void) setBpm: (int) bpm;
- (void) updateTransportProgressView: (NSTimer *) timer;
- (void) addStringToTextView:(NSString*)string textView: (UITextView *) textView;



// osc blink monitor methods

- (void) startIncomingMessageBlink;
- (void) endIncomingMessageBlink: (NSTimer *)timer;

- (void) startOutgoingMessageBlink;
- (void) endOutgoingMessageBlink: (NSTimer *)timer;







@end
