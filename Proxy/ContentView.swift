import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var firebaseService = FirebaseService()

    var body: some View {
        Group {
            if firebaseService.isAuthenticated {
                TabView {
                    MapScreenView()
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }

                    LeaderboardView()
                        .tabItem {
                            Label("Leaderboard", systemImage: "trophy.fill")
                        }

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
            } else {
                AuthView()
            }
        }
        .environmentObject(locationManager)
        .environmentObject(firebaseService)
    }
}
