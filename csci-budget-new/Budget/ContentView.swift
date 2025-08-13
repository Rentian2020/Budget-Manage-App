//
//  ContentView.swift
//  Budget
//
//  Created by Arthur Guiot on 10/13/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authStore = AuthStore.shared
    
    var body: some View {
        if authStore.account_setup {
            OverviewScreen()
        } else {
            Welcome()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
