//
//  PGMidi.m
//  MidiMonitor
//
//  Created by Pete Goodliffe on 10/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PGMidi.h"
#import "PGMidiFind.h"

// For some reason, this is nut pulled in by the umbrella header
#import <CoreMIDI/MIDINetworkSession.h>

/// A helper that NSLogs an error message if "c" is an error code
#define NSLogError(c,str) do{if (c) NSLog(@"Error (%@): %ld:%@", str, (long)c,[NSError errorWithDomain:NSMachErrorDomain code:c userInfo:nil]);}while(false)

//==============================================================================

static void PGMIDINotifyProc(const MIDINotification *message, void *refCon);
static void PGMIDIReadProc(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon);

@interface PGMidi ()
- (void) scanExistingDevices;
- (MIDIPortRef) outputPort;
@end

//==============================================================================

static
NSString *NameOfEndpoint(MIDIEndpointRef ref)
{
    NSString *string = nil;

    MIDIEntityRef entity = 0;
    MIDIEndpointGetEntity(ref, &entity);

    CFPropertyListRef properties = nil;
    OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
    if (s)
    {
        string = @"Unknown name";
    }
    else
    {
        //NSLog(@"Properties = %@", properties);
        NSDictionary *dictionary = (NSDictionary*)properties;
        string = [NSString stringWithFormat:@"%@", [dictionary valueForKey:@"name"]];
        CFRelease(properties);
    }

    return string;
}

static
BOOL IsNetworkSession(MIDIEndpointRef ref)
{
    MIDIEntityRef entity = 0;
    MIDIEndpointGetEntity(ref, &entity);

    BOOL hasMidiRtpKey = NO;
    CFPropertyListRef properties = nil;
    OSStatus s = MIDIObjectGetProperties(entity, &properties, true);
    if (!s)
    {
        NSDictionary *dictionary = (NSDictionary*)properties;
        hasMidiRtpKey = [dictionary valueForKey:@"apple.midirtp.session"] != nil;
        CFRelease(properties);
    }

    return hasMidiRtpKey;
}

//==============================================================================

@implementation PGMidiConnection

@synthesize midi;
@synthesize endpoint;
@synthesize name;
@synthesize isNetworkSession;

- (id) initWithMidi:(PGMidi*)m endpoint:(MIDIEndpointRef)e
{
    if ((self = [super init]))
    {
        midi                = m;
        endpoint            = e;
        name                = [NameOfEndpoint(e) retain];
        isNetworkSession    = IsNetworkSession(e);
    }
    return self;
}

@end

//==============================================================================

@implementation PGMidiSource

@synthesize delegate;

- (id) initWithMidi:(PGMidi*)m endpoint:(MIDIEndpointRef)e
{
    if ((self = [super initWithMidi:m endpoint:e]))
    {
    }
    return self;
}

// NOTE: Called on a separate high-priority thread, not the main runloop
- (void) midiRead:(const MIDIPacketList *)pktlist
{
    [delegate midiSource:self midiReceived:pktlist];
}

static
void PGMIDIReadProc(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon)
{
    PGMidiSource *self = (PGMidiSource*)srcConnRefCon;
    [self midiRead:pktlist];
}

@end

//==============================================================================

@implementation PGMidiDestination

- (id) initWithMidi:(PGMidi*)m endpoint:(MIDIEndpointRef)e
{
    if ((self = [super initWithMidi:m endpoint:e]))
    {
        midi     = m;
        endpoint = e;
    }
    return self;
}

- (void) sendBytes:(const UInt8*)bytes size:(UInt32)size
{
    // NSLog(@"%s(%u bytes to core MIDI)", __func__, unsigned(size));
    assert(size < 65536);
    Byte packetBuffer[size+100];

    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, bytes);

    [self sendPacketList:packetList];
 
}

- (void) sendPacketList:(const MIDIPacketList *)packetList
{
    // Send it
    OSStatus s = MIDISend(midi.outputPort, endpoint, packetList);
    NSLogError(s, @"Sending MIDI");
}

@end

//==============================================================================

@implementation PGMidi

@synthesize delegate;
@synthesize sources,destinations;

- (id) init
{
    if ((self = [super init]))
    {
        sources      = [NSMutableArray new];
        destinations = [NSMutableArray new];

        OSStatus s = MIDIClientCreate((CFStringRef)@"MidiMonitor MIDI Client", PGMIDINotifyProc, self, &client);
        NSLogError(s, @"Create MIDI client");

        s = MIDIOutputPortCreate(client, (CFStringRef)@"MidiMonitor Output Port", &outputPort);
        NSLogError(s, @"Create output MIDI port");

        s = MIDIInputPortCreate(client, (CFStringRef)@"MidiMonitor Input Port", PGMIDIReadProc, self, &inputPort);
        NSLogError(s, @"Create input MIDI port");

        [self scanExistingDevices];
    }

    return self;
}

- (void) dealloc
{
    if (outputPort)
    {
        OSStatus s = MIDIPortDispose(outputPort);
        NSLogError(s, @"Dispose MIDI port");
    }

    if (inputPort)
    {
        OSStatus s = MIDIPortDispose(inputPort);
        NSLogError(s, @"Dispose MIDI port");
    }

    if (client)
    {
        OSStatus s = MIDIClientDispose(client);
        NSLogError(s, @"Dispose MIDI client");
    }

    [sources release];
    [destinations release];

    [super dealloc];
}

- (NSUInteger) numberOfConnections
{
    return sources.count + destinations.count;
}

- (MIDIPortRef) outputPort
{
    return outputPort;
}

- (void) enableNetwork:(BOOL)enabled
{
    MIDINetworkSession* session = [MIDINetworkSession defaultSession];
    session.enabled = YES;
    session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone;
}

//==============================================================================
#pragma mark Connect/disconnect

- (PGMidiSource*) getSource:(MIDIEndpointRef)source
{
    for (PGMidiSource *s in sources)
    {
        if (s.endpoint == source) return s;
    }
    return nil;
}

- (PGMidiDestination*) getDestination:(MIDIEndpointRef)destination
{
    for (PGMidiDestination *d in destinations)
    {
        if (d.endpoint == destination) return d;
    }
    return nil;
}

- (void) connectSource:(MIDIEndpointRef)endpoint
{
    //tz adding check for existing source
    PGMidiSource *existingSource = [self findSourceCalled:NameOfEndpoint(endpoint)];
    if(existingSource) {
        // NSLog(@"source already exists");
        return;
    }
    
    
    PGMidiSource *source = [[PGMidiSource alloc] initWithMidi:self endpoint:endpoint];
    [sources addObject:source];
    [delegate midi:self sourceAdded:source];
    
    OSStatus s = MIDIPortConnectSource(inputPort, endpoint, source);
    NSLogError(s, @"Connecting to MIDI source");
    NSLog(@"connectSource - added: %@", source.name);
    
    // [source release];        // this causes crash
}

- (void) disconnectSource:(MIDIEndpointRef)endpoint
{
    PGMidiSource *source = [self getSource:endpoint];
    
    if (source)
    {
        OSStatus s = MIDIPortDisconnectSource(inputPort, endpoint);
        NSLogError(s, @"Disconnecting from MIDI source");
        
        // tz reversed order of the next two statements so that the delegate would
        // receive properly updated source list

        [sources removeObject:source];
        [delegate midi:self sourceRemoved:source];
        [source release];       // i think its ok to release this here 
    }
}

- (void) connectDestination:(MIDIEndpointRef)endpoint
{
    
    //tz adding check for existing destination
    PGMidiDestination *existingDestination = [self findDestinationCalled:NameOfEndpoint(endpoint)];
    if(existingDestination) {
        // NSLog(@"destination already exists");
        return;
    }
    
    //[delegate midiInput:self event:@"Added a destination"];
    PGMidiDestination *destination = [[PGMidiDestination alloc] initWithMidi:self endpoint:endpoint];
    [destinations addObject:destination];
    NSLog(@"connectDestination - added: %@", destination.name);
    [delegate midi:self destinationAdded:destination];
}

- (void) disconnectDestination:(MIDIEndpointRef)endpoint
{
    //[delegate midiInput:self event:@"Removed a device"];
    
    PGMidiDestination *destination = [self getDestination:endpoint];
    
    if (destination)
    {
        // tz reversed order of the next two statements so that the delegate would
        // receive properly updated destination list
        
        [destinations removeObject:destination];
        [delegate midi:self destinationRemoved:destination];
        
        [destination release];  // i think its actually ok to do this - even though analyzer doesn't approve
    }
    
    
}

- (void) scanExistingDevices
{
    const ItemCount numberOfDestinations = MIDIGetNumberOfDestinations();
    const ItemCount numberOfSources      = MIDIGetNumberOfSources();

    for (ItemCount index = 0; index < numberOfDestinations; ++index)
        [self connectDestination:MIDIGetDestination(index)];
    for (ItemCount index = 0; index < numberOfSources; ++index)
        [self connectSource:MIDIGetSource(index)];
}

//==============================================================================
#pragma mark Notifications

- (void) midiNotifyAdd:(const MIDIObjectAddRemoveNotification *)notification
{
    if (notification->childType == kMIDIObjectType_Destination)
        [self connectDestination:(MIDIEndpointRef)notification->child];
    else if (notification->childType == kMIDIObjectType_Source)
        [self connectSource:(MIDIEndpointRef)notification->child];
}

- (void) midiNotifyRemove:(const MIDIObjectAddRemoveNotification *)notification
{
    if (notification->childType == kMIDIObjectType_Destination)
        [self disconnectDestination:(MIDIEndpointRef)notification->child];
    else if (notification->childType == kMIDIObjectType_Source)
        [self disconnectSource:(MIDIEndpointRef)notification->child];
}

- (void) midiNotify:(const MIDINotification*)notification
{
    // NSLog(@"midiNotify msgID: %ld", notification->messageID);
    switch (notification->messageID)
    {
        case kMIDIMsgObjectAdded:
            // NSLog(@"object added...");
            [self midiNotifyAdd:(const MIDIObjectAddRemoveNotification *)notification];
            break;
        case kMIDIMsgObjectRemoved:
            // NSLog(@"object removed...");
            [self midiNotifyRemove:(const MIDIObjectAddRemoveNotification *)notification];
            break;
        case kMIDIMsgSetupChanged:
            // NSLog(@"Setup Changed...");
            break;
        case kMIDIMsgPropertyChanged:
            // NSLog(@"Property Changed...");
            [self midiPropertyChanged: (MIDIObjectPropertyChangeNotification *) notification];
            break;
        case kMIDIMsgThruConnectionsChanged:
            // NSLog(@"ThruConnectionsChanged...");
            break;
        case kMIDIMsgSerialPortOwnerChanged:
            // NSLog(@"SerialPortOwnerChanged...");
            break;
        case kMIDIMsgIOError:
            // NSLog(@"messageIO error...");
            break;
    }
}

// tz - handle midi property change notification
//
// This is some silliness to work around an interesting bug.
//
// when plugging in the iRig-Midi interface - for the first time, while the app is running,
// an ObjectAdded message doesn't get generated.
//
// Instead, a propertyChanged message gets generated for the device.
//
// By finding available sources/destinations for the device, we can enable them for the
// app - 
// 
// Note that propertyChanged message is ignored if the connection is already in the
// list of sources or destinations
//
// this is all subject to change based on behavior of other devices. It might be necessary
// to create a list of hardware names and corresponding behavior
//
- (void) midiPropertyChanged: (MIDIObjectPropertyChangeNotification *) notification
{
    
    int i;
    
    // note: property name will be "offline"
    NSLog(@"propertyName: %@", notification->propertyName);
    NSLog(@"objectType: %ld", notification->objectType);
    
    // only dealing with devices
    if(notification->objectType != kMIDIObjectType_Device) return;
    
    MIDIDeviceRef device = (MIDIDeviceRef)notification->object;
    
    unsigned long entityCount = MIDIDeviceGetNumberOfEntities(device );
    NSLog(@"number of entities %lu", entityCount);
    
    if(entityCount < 1) return;
    
    // only going to deal with the first device entity (0)
    // not sure what it would mean to have more than one entity for a device 
    
    MIDIEntityRef entity = MIDIDeviceGetEntity(	device,0 );
    unsigned long sourceCount = MIDIEntityGetNumberOfSources(entity);
    NSLog(@"Number of sources in entity %lu", sourceCount);
    
    // for each source try to add it
    for(i = 0; i < sourceCount; i++ ) {
        MIDIEndpointRef endpoint = MIDIEntityGetSource(	entity, (ItemCount) i); 
        NSLog(@"Endpoint Name: %@, index: %d", NameOfEndpoint(endpoint), i);
        // try to connect the source
        [self connectSource:endpoint];
    }
    
    // now do the same thing with destinations
    ItemCount destinationCount = MIDIEntityGetNumberOfSources(entity);
    NSLog(@"Number of destinations in entity %lu", destinationCount);
    
    // for each source try to add it
    for(i = 0; i < destinationCount; i++ ) {
        MIDIEndpointRef endpoint = MIDIEntityGetDestination(entity, (ItemCount) i); 
        NSLog(@"Endpoint Name: %@, index: %d", NameOfEndpoint(endpoint), i);
        // try to connect the destination
        [self connectDestination:endpoint];
    }
    
    
}

void PGMIDINotifyProc(const MIDINotification *message, void *refCon)
{
    PGMidi *self = (PGMidi*)refCon;
    [self midiNotify:message];
}

//==============================================================================
#pragma mark MIDI Output

- (void) sendPacketList:(const MIDIPacketList *)packetList
{
    // NSLog(@"sendPacketList - destinations: %lu", MIDIGetNumberOfDestinations());
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index)
    {
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
        if (outputEndpoint)
        {

            // Send it
            OSStatus s = MIDISend(outputPort, outputEndpoint, packetList);
            NSLogError(s, @"Sending MIDI");
        }
    }
}

- (void) sendBytes:(const UInt8*)data size:(UInt32)size
{
    // NSLog(@"%s(%u bytes to core MIDI)", __func__, unsigned(size));
    assert(size < 65536);
    Byte packetBuffer[size+100];
    
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);

    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, data);

    [self sendPacketList:packetList];

}

// send packet list to endpoint name
- (void) sendPacketList:(const MIDIPacketList *)packetList toEndpointName: (NSString *) name
{
    //    NSLog(@"sendPacketList - destinations: %lu", MIDIGetNumberOfDestinations());
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index)
    {
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
        if([NameOfEndpoint(outputEndpoint) isEqualToString:name]) {
            
        
            if (outputEndpoint) {
                // Send it
                OSStatus s = MIDISend(outputPort, outputEndpoint, packetList);
                NSLogError(s, @"Sending MIDI");
            }
        }
    }
}

- (void) sendBytes:(const UInt8*)data size:(UInt32)size toEndpointName: (NSString *) name
{
    // NSLog(@"%s(%u bytes to core MIDI)", __func__, unsigned(size));
    assert(size < 65536);
    Byte packetBuffer[size+100];
    
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, data);
    
    [self sendPacketList:packetList toEndpointName:name];
    
}





@end
