//
//  INTIPApp.swift
//  INTIP
//

import SwiftUI

@main
struct INTIPApp: App {
    // AppDelegate를 등록해줌
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
