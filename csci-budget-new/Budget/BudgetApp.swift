//
//  BudgetApp.swift
//  Budget
//
//  Created by Arthur Guiot on 10/13/24.
//

import SwiftUI
import SwiftData
import Supabase

let LOCALHOST = false // Flag to toggle between localhost and production

let supabase = SupabaseClient(
    supabaseURL: LOCALHOST ?
    URL(string: "http://127.0.0.1:54321")! :
        URL(string: "https://dkgrbhsnhubowckwzdot.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZ3JiaHNuaHVib3dja3d6ZG90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk1NTgxMjgsImV4cCI6MjA0NTEzNDEyOH0.x-XI4Co-QrtYtzxyup5aa8Fv8jp8ohDh1kfiSkcztgU"
)


@main
struct BudgetApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    supabase.auth.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
