//
//  SIAppDelegate.m
//  SpeakIt
//
//  Created by Gregory Casamento on 11/7/13.
//  Copyright (c) 2013 Gregory Casamento. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudio.h>

#import "SIAppDelegate.h"
#import "SIDeviceDescriptor.h"
#import "NSString+SHA1.h"

NSDictionary *GetAudioDevices()
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:10];
    UInt32 sz;
    AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,&sz,NULL);
    AudioDeviceID *audioDevices=(AudioDeviceID *)malloc(sz);
    AudioHardwareGetProperty(kAudioHardwarePropertyDevices,&sz,audioDevices);
    UInt32 deviceCount = (sz / sizeof(AudioDeviceID));
    
    UInt32 i;
    for(i=0;i<deviceCount;++i)
    {
        NSString *s;
        
        // get buffer list
        UInt32 outputChannelCount=0;
        {
            AudioDeviceGetPropertyInfo(
                                       audioDevices[i],0,false,
                                       kAudioDevicePropertyStreamConfiguration,
                                       &sz,NULL
                                       );
            AudioBufferList *bufferList=(AudioBufferList *)malloc(sz);
            AudioDeviceGetProperty(
                                   audioDevices[i],0,false,
                                   kAudioDevicePropertyStreamConfiguration,
                                   &sz,&bufferList
                                   );
            
            UInt32 j;
            for(j=0;j<bufferList->mNumberBuffers;++j)
                outputChannelCount += bufferList->mBuffers[j].mNumberChannels;
            
            // free(bufferList);
        }
        
        // skip devices without any output channels
        if(outputChannelCount==0)
            continue;
        
        // output some device info
        {
            SIDeviceDescriptor *descriptor = [[SIDeviceDescriptor alloc] init];
            sz=sizeof(CFStringRef);
            
            AudioDeviceGetProperty(
                                   audioDevices[i],0,false,
                                   kAudioDevicePropertyDeviceUID,
                                   &sz,&s
                                   );
            NSLog(@"DeviceUID: [%@]",s);
            // [s release];
            NSString *deviceUID = s;
            
            AudioDeviceGetProperty(
                                   audioDevices[i],0,false,
                                   kAudioObjectPropertyName,
                                   &sz,&s
                                   );
            NSLog(@"    Name: [%@]",s);
            // [s release];
            NSString *deviceName = s;
            
            NSLog(@"    OutputChannels: %d",outputChannelCount);
            [result setObject:deviceUID
                       forKey:deviceName];
        }
    }
    return result;
}

@implementation SIAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

// Controller methods...
- (IBAction)speak:(id)sender
{
    NSString *textToSpeak = [text stringValue];
    NSString *fileName = [textToSpeak stringByHashingStringWithSHA1];
    NSURL *cacheDir = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"Cache"];
    if([[NSFileManager defaultManager] fileExistsAtPath:[cacheDir path]] == NO)
    {
        [[NSFileManager defaultManager] createDirectoryAtURL:cacheDir withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    tempFileURL = [cacheDir URLByAppendingPathComponent:fileName];
    [tempFileURL retain];
    NSLog(@"Speak the following text: %@",textToSpeak);
    [synthesizer startSpeakingString:textToSpeak toURL:tempFileURL];
}

- (IBAction)output:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[voice titleOfSelectedItem] forKey:@"Output"];
    [defaults synchronize];
}

- (IBAction)voice:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[voice titleOfSelectedItem] forKey:@"Voice"];
    [defaults synchronize];
}

- (IBAction)monitor:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:([monitor state] == NSOnState) forKey:@"MonitorOutput"];
    [defaults synchronize];
}

- (IBAction)volume:(id)sender
{
    currentVolume = [sender stringValue];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentVolume forKey:@"CurrentVolume"];
    [defaults synchronize];
}

// Speech Synthesis Delegate methods...
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
    if([monitor state] == NSOnState)
    {
        NSSound *sound = [[NSSound alloc] initWithContentsOfFile:[tempFileURL path] byReference:NO];
        [sound setVolume:[currentVolume floatValue]];
        [sound play];
        [tempFileURL release];
        [text setStringValue:@""];
    }
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)characterRange ofString:(NSString *)string
{
    
}
                          
// App Delegate methods...
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    synthesizer = [[NSSpeechSynthesizer alloc] init];
    
    [synthesizer setDelegate:self];
    
    // Get audio output
    devicesDictionary = GetAudioDevices();
    [devicesDictionary retain];
    NSArray *keys = [[devicesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [output removeAllItems];
    for(NSString *k in keys)
    {
        [output addItemWithTitle:k];
    }
    
    // Get all voices
    voicesDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
    reverseVoicesDict = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSArray *voices = [NSSpeechSynthesizer availableVoices];
    for(NSString *v in voices)
    {
        NSDictionary *voiceAttrs = [NSSpeechSynthesizer attributesForVoice:v];
        NSString *name = [voiceAttrs objectForKey:NSVoiceName];
        [voicesDictionary setObject:v forKey:name];
        [reverseVoicesDict setObject:name forKey:v];
        [voice addItemWithTitle:name];
    }

    // Select current voice..
    NSString *defaultVoiceKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"Voice"];
    if(defaultVoiceKey == nil)
    {
        defaultVoiceKey = [NSSpeechSynthesizer defaultVoice];
    }
    NSString *defaultVoice = [reverseVoicesDict objectForKey:defaultVoiceKey];
    [voice selectItemWithTitle:defaultVoice];
    
    // Select current output..
    NSString *defaultOutputKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"Output"];
    if(defaultOutputKey != nil)
    {
        [output selectItemWithTitle:defaultOutputKey];
    }
    
    // Set current volume..
    currentVolume = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentVolume"];
    if(currentVolume == nil)
    {
        currentVolume = @"1.0";
    }
    [volume setFloatValue:[currentVolume floatValue]];
}

//
// Returns the directory the application uses to store the Core Data store file.
// This code uses a directory named "com.openlogiccorp.SpeakIt" in the user's
// Application Support directory.
//
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.openlogiccorp.SpeakIt"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SpeakIt" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

//
// Returns the persistent store coordinator for the application. This implementation creates
// and return a coordinator, having added the store for the application to it. (The
// directory for the store is created, if necessary.)
//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"SpeakIt.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

//
// Returns the managed object context for the application (which is already
// bound to the persistent store coordinator for the application.)
//
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

//
// Returns the NSUndoManager for the application. In this case, the manager
// returned is that of the managed object context for the application.
//
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

//
// Performs the save action for the application, which is to send the
// save: message to the application's managed object context. Any
// encountered errors are presented to the user.
//
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
