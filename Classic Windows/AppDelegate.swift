//
//  AppDelegate.swift
//  Classic Windows
//
//  Created by Daniel Muckerman on 2/2/15.
//  Copyright (c) 2015 Daniel Muckerman. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusApp: NSMenu!
    
    
    // Create status bar item, and set it's length
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    let defaults = NSUserDefaults.standardUserDefaults()
    
    /**
     * Initialize status bar item
     *
     * :param: aNotification
     */
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Initialize status bar app
        let icon = NSImage(named: "StatusIcon")
        icon?.setTemplate(true)
        
        // Create status item
        statusItem.image = icon
        //statusItem.title = "Classic"
        statusItem.menu = statusApp
        statusItem.highlightMode = true
    }
    
    /**
     * Create an observer for when applications are changed
     */
    override func awakeFromNib() {
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: "changeApp:", name:"NSWorkspaceDidActivateApplicationNotification", object: nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    /**
     * Enable special behaviors on app switching
     *
     * :param: notification Listen for the DidActivateApplication notification, then activate the app
     * with the proper options
     */
    func changeApp(notification: NSNotification){
        let state = defaults.stringForKey("pref2")?.toInt()
        
        if (state == 1) { // ON
            NSWorkspace.sharedWorkspace().frontmostApplication?.activateWithOptions(NSApplicationActivationOptions.ActivateAllWindows | NSApplicationActivationOptions.ActivateIgnoringOtherApps)
        }
    }
    
    /**
     * Terminate app
     *
     * :param: sender
     */
    @IBAction func quitApp(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    /**
     * Check if the app is in the login items list
     *
     * :returns: Is the app in the login items list
     */
    func applicationIsInStartUpItems() -> Bool {
        return (itemReferencesInLoginItems().existingReference != nil)
    }
    
    /**
     * Get list of login items
     *
     * :returns: A tuple, in which the first item is the existing application reference, if it exists,
     * and the second item is the last reference of the list.
     */
    func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        var itemUrl : UnsafeMutablePointer<Unmanaged<CFURL>?> = UnsafeMutablePointer<Unmanaged<CFURL>?>.alloc(1)
        if let appUrl : NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
            let loginItemsRef = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeRetainedValue(),
                nil
                ).takeRetainedValue() as LSSharedFileListRef?
            if loginItemsRef != nil {
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                //println("There are \(loginItems.count) login items")
                let lastItemRef: LSSharedFileListItemRef = loginItems.lastObject as! LSSharedFileListItemRef
                for var i = 0; i < loginItems.count; ++i {
                    let currentItemRef: LSSharedFileListItemRef = loginItems.objectAtIndex(i) as! LSSharedFileListItemRef
                    if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
                        if let urlRef: NSURL =  itemUrl.memory?.takeRetainedValue() {
                            //println("URL Ref: \(urlRef.lastPathComponent)")
                            if urlRef.isEqual(appUrl) {
                                return (currentItemRef, lastItemRef)
                            }
                        }
                    } else {
                        //println("Unknown login application")
                    }
                }
                //The application was not found in the startup list
                return (nil, lastItemRef)
            }
        }
        return (nil, nil)
    }
    
    /**
     * Add / remove app from login items
     *
     * :param: sender
     */
    @IBAction func toggleLaunchAtLogin(sender: AnyObject) {
        // Get checkmark state from user defaults
        let state = defaults.stringForKey("pref1")?.toInt()
        
        // Handle adding/removing application to login items
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
            ).takeRetainedValue() as LSSharedFileListRef?
        if loginItemsRef != nil {
            if shouldBeToggled && state == 0 {
                if let appUrl : CFURLRef = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
                    LSSharedFileListInsertItemURL(
                        loginItemsRef,
                        itemReferences.lastReference,
                        nil,
                        nil,
                        appUrl,
                        nil,
                        nil
                    )
                    println("Application was added to login items")
                }
            } else {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef);
                    println("Application was removed from login items")
                }
            }
        }
    }
}