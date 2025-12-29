//
//  AppDelegate.swift
//  DoppelgangersHunter-Cocoa
//
//  Created by imurashov on 22.12.2025.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if
            let window = NSApplication.shared.windows.first,
            let screenRect = NSScreen.main?.frame
        {
            let size = NSSize(width: 1000, height: 600)
            let origin = NSPoint(
                x: (screenRect.width - size.width) / 2,
                y: (screenRect.height - size.height) / 2
            )
            let desiredFrame = NSRect(origin: origin, size: size)
            window.setFrame(desiredFrame, display: true, animate: false)
            window.minSize = size
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

