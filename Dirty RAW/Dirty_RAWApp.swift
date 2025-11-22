//
//  Dirty_RAWApp.swift
//  Dirty RAW
//

import SwiftUI

@main
struct Dirty_RAWApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Initialize Nikon SDK
        // SDK initialization moved to AppDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open File...") {
                    NSApp.sendAction(#selector(AppDelegate.openFile(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

// App Delegate for SDK lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Nikon SDK
        if !NikonSDKWrapper.initializeLibrary() {
            print("Warning: Failed to initialize Nikon Image SDK")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NikonSDKWrapper.closeLibrary()
    }

    @objc func openFile(_ sender: Any?) {
        NotificationCenter.default.post(name: .openFile, object: nil)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            NotificationCenter.default.post(name: .openFileURL, object: url)
        }
    }
}

extension Notification.Name {
    static let openFile = Notification.Name("openFile")
    static let openFileURL = Notification.Name("openFileURL")
}
