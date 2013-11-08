//
//  SIAppDelegate.h
//  SpeakIt
//
//  Created by Gregory Casamento on 11/7/13.
//  Copyright (c) 2013 Gregory Casamento. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SIAppDelegate : NSObject <NSApplicationDelegate, NSSpeechSynthesizerDelegate>
{
    IBOutlet NSTextField   *text;
    IBOutlet NSButton      *speak;
    IBOutlet NSPopUpButton *output;
    IBOutlet NSPopUpButton *voice;
    IBOutlet NSButton      *monitor;
    IBOutlet NSSlider      *volume;
    
    NSDictionary *devicesDictionary;
    NSMutableDictionary *voicesDictionary;
    NSMutableDictionary *reverseVoicesDict;
    NSURL *tempFileURL;
    NSSpeechSynthesizer *synthesizer;
    NSString *currentVolume;
}

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// Controller methods...
- (IBAction)speak:(id)sender;
- (IBAction)output:(id)sender;
- (IBAction)voice:(id)sender;
- (IBAction)monitor:(id)sender;
- (IBAction)volume:(id)sender;

// DB actions...
- (IBAction)saveAction:(id)sender;

@end
