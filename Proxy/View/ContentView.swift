//
//  ContentView.swift
//  Proxy
//
//  Created by Kevin Alinazar on 2026-02-05.
//

import SwiftUI

struct ContentView: View {
    // We use the EnvironmentObject that we will set up in Step 2
    @EnvironmentObject var viewModel: AppViewModel
    
    // Default to the Messages tab (0)
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Tab 1: Messages (The Inbox)
            NavigationView {
                MessagesInboxView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chats")
            }
            .tag(0)
            
            // Tab 2: Map (Your existing map)
            NavigationView {
                MapView() // Make sure you have a MapView struct, or replace with Text("Map")
            }
            .tabItem {
                Image(systemName: "map.fill")
                Text("Map")
            }
            .tag(1)
            
            // Tab 3: People (Find Friends)
            NavigationView {
                UserListView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("People")
            }
            .tag(2)
            
            // Tab 4: Profile
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("Profile")
            }
            .tag(3)
        }
        .accentColor(.orange) // Sets the button color
    }
}
