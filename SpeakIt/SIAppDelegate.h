//
//  SIAppDelegate.h
//  SpeakIt
//
//  Created by Gregory Casamento on 11/7/13.
//  Copyright (c) 2013 Gregory Casamento. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SIAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
