//
//  SAM2_DemoApp.swift
//  SAM2-Demo
//
//  Created by Cyril Zakka on 8/19/24.
//

import SwiftUI

@main
struct SAM2_DemoApp: App {
    var body: some Scene {
#if canImport(UIKit)
        WindowGroup {
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
#else
        WindowGroup {
            ContentView()
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
#endif
    }
}
