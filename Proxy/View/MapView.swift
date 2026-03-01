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
        center: CLLocationCoordinate2D(latitude: 45.4883, longitude: -73.5837),
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
                showsUserLocation: true,
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
            locationManager.requestPermission()
            locationManager.startTracking()
            startSyncTimer()
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
        if let loc = locationManager.userLocation {
            withAnimation {
                region.center = loc
            }
        }
    }

    func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                // Upload my location
                if let loc = locationManager.userLocation {
                    await viewModel.updateMyLocation(latitude: loc.latitude, longitude: loc.longitude)
                }
                // Refresh friend locations
                await viewModel.refreshFriendsLocations()
                // Refresh checkpoints
                await viewModel.fetchNearbyCheckpoints(latitude: region.center.latitude, longitude: region.center.longitude)
            }
        }
        // Also do an immediate sync
        Task {
            if let loc = locationManager.userLocation {
                await viewModel.updateMyLocation(latitude: loc.latitude, longitude: loc.longitude)
            }
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
        guard let userLoc = locationManager.userLocation else { return }

        // Only search if we have no checkpoints yet
        if !viewModel.checkpoints.isEmpty { return }

        let searchTypes = ["school", "park", "landmark"]

        for type in searchTypes {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = type
            request.region = MKCoordinateRegion(
                center: userLoc,
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
                }
            } catch {
                print("Search error for \(type): \(error)")
            }
        }

        // Re-fetch after creating
        await viewModel.fetchNearbyCheckpoints(latitude: userLoc.latitude, longitude: userLoc.longitude)
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
