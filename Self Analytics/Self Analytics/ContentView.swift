//
//  ContentView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/9/25.
//

import SwiftUI

/// Minimal root view used for previews and simple embedding.
///
/// The app's real navigation root is `MainTabView`. Keeping this wrapper makes it easy to:
/// - preview the app shell in isolation
/// - embed the shell in alternate entry points/tests without duplicating setup
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}
