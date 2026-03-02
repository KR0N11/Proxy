//
//  MapView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject private var locationManager = LocationManager()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4916, longitude: -73.5818),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // Friend visibility toggles: friendID -> visible
    @State private var friendVisibility: [String: Bool] = [:]
    @State private var showFriendPicker = false
    @State private var showLeaderboard = false
    @State private var hasInitiallyPanned = false

    // Distance filter
    @State private var selectedDistance: DistanceFilter = .all

    // Checkpoint interaction
    @State private var selectedCheckpoint: Checkpoint?
    @State private var showCheckpointChat = false

    // Sync timer
    @State private var syncTimer: Timer?
    @State private var showDistanceAlert = false

    enum DistanceFilter: String, CaseIterable {
        case all = "All"
        case halfMile = "0.5 mi"
        case oneMile = "1 mi"
        case fiveMiles = "5 mi"

        var meters: Double? {
            switch self {
            case .all: return nil
            case .halfMile: return 804.7
            case .oneMile: return 1609.3
            case .fiveMiles: return 8046.7
            }
        }
    }

    // Friends filtered by visibility + distance
    var visibleFriends: [AppUser] {
        viewModel.friends.filter { friend in
            // Check toggle
            guard friendVisibility[friend.id] ?? true else { return false }
            // Check if they have a location
            guard friend.latitude != 0 || friend.longitude != 0 else { return false }
            // Check distance filter
            if let maxDist = selectedDistance.meters, let userLoc = locationManager.userLocation {
                let friendLoc = CLLocation(latitude: friend.latitude, longitude: friend.longitude)
                let myLoc = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                return friendLoc.distance(from: myLoc) <= maxDist
            }
            return true
        }
    }

    // All checkpoints (shown on map, 80m check is only for interaction)
    var nearbyCheckpoints: [Checkpoint] {
        viewModel.checkpoints
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: !locationManager.ghostMode,
                annotationItems: mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if item.isFriend {
                        // Friend marker
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(item.name.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(radius: 3)
                            Text(item.name)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(4)
                                .shadow(radius: 1)
                        }
                    } else {
                        // Checkpoint marker
                        Button {
                            selectedCheckpoint = viewModel.checkpoints.first { $0.id == item.id }
                            if let cp = selectedCheckpoint {
                                checkCheckpointProximity(cp)
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: iconForCheckpoint(item.checkpointType))
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(colorForCheckpoint(item.checkpointType))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                                Text(item.name)
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(4)
                                    .shadow(radius: 1)
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .including([
                .park, .nationalPark, .school, .university, .museum, .library, .stadium
            ])))
            .edgesIgnoringSafeArea(.top)

            // Side buttons
            VStack {
                HStack {
                    // Zoom buttons (top left)
                    VStack(spacing: 8) {
                        Button {
                            withAnimation {
                                region.span.latitudeDelta /= 2
                                region.span.longitudeDelta /= 2
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        Button {
                            withAnimation {
                                region.span.latitudeDelta *= 2
                                region.span.longitudeDelta *= 2
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding(.leading, 12)

                    Spacer()
                    VStack(spacing: 12) {
                        // Friend picker button
                        Button {
                            showFriendPicker = true
                        } label: {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        // Center on me button
                        Button {
                            centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        // Location toggle button (off by default)
                        Button {
                            locationManager.ghostMode.toggle()
                            if locationManager.ghostMode {
                                // Switched to ghost mode — back to Montreal
                                withAnimation {
                                    region.center = LocationManager.defaultCoordinate
                                }
                            } else {
                                // User turned on real location — will request permission
                                hasInitiallyPanned = false
                            }
                        } label: {
                            Image(systemName: locationManager.ghostMode ? "location.slash.fill" : "location.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(locationManager.ghostMode ? Color.gray : Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }

                        // Leaderboard button
                        Button {
                            showLeaderboard = true
                        } label: {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.yellow)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding(.trailing, 12)
                }
                .padding(.top, 60)

                Spacer()

                // Distance filter bar
                HStack(spacing: 8) {
                    ForEach(DistanceFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedDistance = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedDistance == filter ? Color.orange : Color.white.opacity(0.9))
                                .foregroundColor(selectedDistance == filter ? .white : .primary)
                                .cornerRadius(16)
                                .shadow(radius: 2)
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            // Do NOT request permission or start tracking on appear
            // Location is off by default (ghost mode = on)
            startSyncTimer()
            // Fetch checkpoints immediately using Montreal default
            Task {
                let center = locationManager.userLocation ?? LocationManager.defaultCoordinate
                await viewModel.fetchNearbyCheckpoints(latitude: center.latitude, longitude: center.longitude)
                await searchAndSaveLocalPlaces()
            }
        }
        .onDisappear {
            syncTimer?.invalidate()
            syncTimer = nil
        }
        .onReceive(locationManager.$userLocation) { newLoc in
            if let loc = newLoc, !hasInitiallyPanned {
                region.center = loc
                hasInitiallyPanned = true
                // Now that we have real location, fetch checkpoints and search for places
                Task {
                    await viewModel.fetchNearbyCheckpoints(latitude: loc.latitude, longitude: loc.longitude)
                    await searchAndSaveLocalPlaces()
                }
            }
        }
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(
                friends: viewModel.friends,
                friendVisibility: $friendVisibility
            )
        }
        .sheet(isPresented: $showCheckpointChat) {
            if let cp = selectedCheckpoint {
                CheckpointChatView(checkpoint: cp)
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
        .alert("Too Far Away", isPresented: $showDistanceAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // Combine friends + checkpoints into one annotation array for the map
    var mapAnnotations: [MapItem] {
        var items: [MapItem] = []

        for friend in visibleFriends {
            items.append(MapItem(
                id: friend.id,
                name: friend.username,
                coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude),
                isFriend: true,
                checkpointType: ""
            ))
        }

        for cp in nearbyCheckpoints {
            items.append(MapItem(
                id: cp.id,
                name: cp.name,
                coordinate: CLLocationCoordinate2D(latitude: cp.latitude, longitude: cp.longitude),
                isFriend: false,
                checkpointType: cp.type
            ))
        }

        return items
    }

    // MARK: - Helpers

    func iconForCheckpoint(_ type: String) -> String {
        if type == "school" { return "building.columns.fill" }
        if type == "landmark" { return "mappin.circle.fill" }
        return "leaf.fill"
    }

    func colorForCheckpoint(_ type: String) -> Color {
        if type == "school" { return .purple }
        if type == "landmark" { return .orange }
        return .green
    }

    func centerOnUser() {
        let loc = locationManager.userLocation ?? LocationManager.defaultCoordinate
        withAnimation {
            region.center = loc
        }
    }

    func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                // Upload my location (ghost mode sends LaSalle College coords)
                let loc = locationManager.userLocation ?? LocationManager.defaultCoordinate
                await viewModel.updateMyLocation(latitude: loc.latitude, longitude: loc.longitude)
                // Refresh friend locations
                await viewModel.refreshFriendsLocations()
                // Refresh checkpoints
                await viewModel.fetchNearbyCheckpoints(latitude: region.center.latitude, longitude: region.center.longitude)
            }
        }
        // Also do an immediate sync
        Task {
            let loc = locationManager.userLocation ?? LocationManager.defaultCoordinate
            await viewModel.updateMyLocation(latitude: loc.latitude, longitude: loc.longitude)
            await viewModel.refreshFriendsLocations()
        }
    }

    func checkCheckpointProximity(_ checkpoint: Checkpoint) {
        guard let userLoc = locationManager.userLocation else {
            selectedCheckpoint = checkpoint
            showCheckpointChat = true
            return
        }
        let cpLoc = CLLocation(latitude: checkpoint.latitude, longitude: checkpoint.longitude)
        let myLoc = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        let distanceMeters = cpLoc.distance(from: myLoc)

        if distanceMeters <= 80 {
            selectedCheckpoint = checkpoint
            showCheckpointChat = true
        } else {
            viewModel.errorMessage = "You need to be within 80 meters to interact! You are \(Int(distanceMeters))m away."
            showDistanceAlert = true
        }
    }

    // Search for schools and parks near the user and save them as checkpoints
    func searchAndSaveLocalPlaces() async {
        let center = locationManager.userLocation ?? LocationManager.defaultCoordinate

        // Only search if we have no checkpoints yet
        if !viewModel.checkpoints.isEmpty { return }

        let searchTypes = ["school", "park", "landmark"]
        var createdAny = false

        for type in searchTypes {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = type
            request.region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )

            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                for mapItem in response.mapItems.prefix(5) {
                    let name = mapItem.name ?? type.capitalized
                    let lat = mapItem.placemark.coordinate.latitude
                    let lon = mapItem.placemark.coordinate.longitude
                    await viewModel.createCheckpoint(name: name, type: type, latitude: lat, longitude: lon)
                    createdAny = true
                }
            } catch {
                print("Search error for \(type): \(error)")
            }
        }

        // If MapKit search returned nothing, seed hardcoded Montreal landmarks
        if !createdAny {
            await seedMontrealLandmarks()
        }

        // Re-fetch after creating
        await viewModel.fetchNearbyCheckpoints(latitude: center.latitude, longitude: center.longitude)
    }

    // Hardcoded Montreal landmarks — always seeded as fallback
    func seedMontrealLandmarks() async {
        let landmarks: [(name: String, type: String, lat: Double, lon: Double)] = [
            // === Schools & Colleges ===
            ("LaSalle College", "school", 45.4916, -73.5818),
            ("Dawson College", "school", 45.4890, -73.5785),
            ("Concordia University (SGW)", "school", 45.4953, -73.5788),
            ("Concordia University (Loyola)", "school", 45.4584, -73.6401),
            ("McGill University", "school", 45.5048, -73.5772),
            ("ETS", "school", 45.4945, -73.5627),
            ("UQAM", "school", 45.5095, -73.5685),
            ("Université de Montréal", "school", 45.5017, -73.6153),
            ("Polytechnique Montréal", "school", 45.5046, -73.6130),
            ("HEC Montréal", "school", 45.5013, -73.6192),
            ("Collège de Maisonneuve", "school", 45.5535, -73.5490),
            ("Vanier College", "school", 45.4672, -73.6286),
            ("Collège Jean-de-Brébeuf", "school", 45.5015, -73.6232),
            ("Marianopolis College", "school", 45.4862, -73.5843),

            // === Parks ===
            ("Parc du Mont-Royal", "park", 45.5048, -73.5874),
            ("Square Dorchester", "park", 45.4988, -73.5726),
            ("Parc Émilie-Gamelin", "park", 45.5162, -73.5610),
            ("Place des Arts", "park", 45.5081, -73.5668),
            ("Jardin botanique de Montréal", "park", 45.5596, -73.5507),
            ("Parc La Fontaine", "park", 45.5268, -73.5696),
            ("Parc Jean-Drapeau", "park", 45.5134, -73.5340),
            ("Parc Jarry", "park", 45.5339, -73.6271),
            ("Parc Maisonneuve", "park", 45.5551, -73.5525),
            ("Parc Angrignon", "park", 45.4467, -73.6042),
            ("Square Saint-Louis", "park", 45.5165, -73.5669),
            ("Parc Jeanne-Mance", "park", 45.5110, -73.5815),
            ("Westmount Park", "park", 45.4843, -73.5955),

            // === Landmarks & Culture ===
            ("Centre Bell", "landmark", 45.4960, -73.5693),
            ("Basilique Notre-Dame", "landmark", 45.5046, -73.5566),
            ("Oratoire Saint-Joseph", "landmark", 45.4920, -73.6170),
            ("Stade olympique", "landmark", 45.5579, -73.5515),
            ("Vieux-Port de Montréal", "landmark", 45.5075, -73.5530),
            ("Marché Atwater", "landmark", 45.4810, -73.5768),
            ("Marché Jean-Talon", "landmark", 45.5362, -73.6154),
            ("Musée des beaux-arts", "landmark", 45.4985, -73.5796),
            ("Musée McCord", "landmark", 45.5033, -73.5742),
            ("Gare Centrale", "landmark", 45.4998, -73.5670),
            ("Cathédrale Marie-Reine-du-Monde", "landmark", 45.4993, -73.5680),
            ("Habitat 67", "landmark", 45.4978, -73.5432),
            ("Biosphère", "landmark", 45.5145, -73.5312),
            ("Tour de l'Horloge", "landmark", 45.5048, -73.5451),
            ("Place Ville Marie", "landmark", 45.5014, -73.5693),
            ("Complexe Desjardins", "landmark", 45.5082, -73.5632),
            ("Palais des congrès", "landmark", 45.5047, -73.5612),
            ("Quartier des spectacles", "landmark", 45.5088, -73.5668),
            ("Canal de Lachine", "landmark", 45.4820, -73.5705),
            ("Chinatown Gate", "landmark", 45.5072, -73.5602),
        ]

        for lm in landmarks {
            await viewModel.createCheckpoint(name: lm.name, type: lm.type, latitude: lm.lat, longitude: lm.lon)
        }
    }
}

// MARK: - Map annotation item

struct MapItem: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let isFriend: Bool
    let checkpointType: String
}

// MARK: - Friend Picker Sheet

struct FriendPickerSheet: View {
    let friends: [AppUser]
    @Binding var friendVisibility: [String: Bool]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                if friends.isEmpty {
                    Text("No friends added yet.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(friends) { friend in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(friend.username.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.username)
                                    .font(.headline)
                                if friend.latitude != 0 || friend.longitude != 0 {
                                    Text("Location available")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("No location shared")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { friendVisibility[friend.id] ?? true },
                                set: { friendVisibility[friend.id] = $0 }
                            ))
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Show Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
