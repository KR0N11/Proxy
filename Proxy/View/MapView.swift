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
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @State private var friendVisibility: [String: Bool] = [:]
    @State private var showFriendPicker = false
    @State private var showLeaderboard = false

    @State private var selectedDistance: DistanceFilter = .fiveKm
    @State private var selectedCheckpoint: Checkpoint?
    @State private var showCheckpointChat = false
    @State private var syncTimer: Timer?
    @State private var showDistanceAlert = false

    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    enum DistanceFilter: String, CaseIterable {
        case all = "All"
        case fiveKm = "5 km"
        case oneKm = "1 km"
        case fiveHundredM = "500 m"
        case twoHundredM = "200 m"

        var meters: Double? {
            switch self {
            case .all: return nil
            case .fiveKm: return 5000
            case .oneKm: return 1000
            case .fiveHundredM: return 500
            case .twoHundredM: return 200
            }
        }

        var zoomDelta: Double {
            switch self {
            case .all: return 0.06
            case .fiveKm: return 0.05
            case .oneKm: return 0.012
            case .fiveHundredM: return 0.006
            case .twoHundredM: return 0.003
            }
        }
    }

    var visibleFriends: [AppUser] {
        viewModel.friends.filter { friend in
            guard friendVisibility[friend.id] ?? true else { return false }
            guard friend.latitude != 0 || friend.longitude != 0 else { return false }
            if let maxDist = selectedDistance.meters, let userLoc = locationManager.userLocation {
                let friendLoc = CLLocation(latitude: friend.latitude, longitude: friend.longitude)
                let myLoc = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                return friendLoc.distance(from: myLoc) <= maxDist
            }
            return true
        }
    }

    var nearbyCheckpoints: [Checkpoint] {
        viewModel.checkpoints
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: locationManager.useCurrentLocation,
                annotationItems: mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if item.isFriend {
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
                        glassButton(icon: "plus") {
                            withAnimation {
                                region.span.latitudeDelta /= 2
                                region.span.longitudeDelta /= 2
                            }
                        }
                        glassButton(icon: "minus") {
                            withAnimation {
                                region.span.latitudeDelta *= 2
                                region.span.longitudeDelta *= 2
                            }
                        }
                    }
                    .padding(.leading, 12)

                    Spacer()

                    VStack(spacing: 10) {
                        // Friend picker
                        glassButton(icon: "person.2.fill", tint: brandOrange) {
                            showFriendPicker = true
                        }

                        // Center on Montreal
                        glassButton(icon: "mappin.and.ellipse", tint: brandOrange) {
                            centerOnDefault()
                        }

                        // Use current location toggle
                        glassButton(
                            icon: locationManager.useCurrentLocation ? "location.fill" : "location.slash.fill",
                            tint: locationManager.useCurrentLocation ? .green : Color.white.opacity(0.5)
                        ) {
                            locationManager.useCurrentLocation.toggle()
                            if !locationManager.useCurrentLocation {
                                withAnimation {
                                    region.center = LocationManager.defaultCoordinate
                                }
                            }
                        }

                        // Leaderboard
                        glassButton(icon: "trophy.fill", tint: .yellow) {
                            showLeaderboard = true
                        }
                    }
                    .padding(.trailing, 12)
                }
                .padding(.top, 60)

                Spacer()

                // Distance filter bar
                HStack(spacing: 6) {
                    ForEach(DistanceFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedDistance = filter
                            withAnimation {
                                region.span = MKCoordinateSpan(
                                    latitudeDelta: filter.zoomDelta,
                                    longitudeDelta: filter.zoomDelta
                                )
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    Group {
                                        if selectedDistance == filter {
                                            brandOrange
                                        } else {
                                            Color.white.opacity(0.15)
                                        }
                                    }
                                )
                                .foregroundColor(selectedDistance == filter ? .white : .primary)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            startSyncTimer()
            Task {
                let center = LocationManager.defaultCoordinate
                await viewModel.fetchNearbyCheckpoints(latitude: center.latitude, longitude: center.longitude)
                await searchAndSaveLocalPlaces()
            }
        }
        .onDisappear {
            syncTimer?.invalidate()
            syncTimer = nil
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

    // MARK: - Glass Button

    @ViewBuilder
    func glassButton(icon: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }

    // MARK: - Annotations

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
        if type == "landmark" { return brandOrange }
        return .green
    }

    func centerOnDefault() {
        withAnimation {
            region.center = LocationManager.defaultCoordinate
        }
    }

    func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                let loc = locationManager.userLocation ?? LocationManager.defaultCoordinate
                await viewModel.updateMyLocation(latitude: loc.latitude, longitude: loc.longitude)
                await viewModel.refreshFriendsLocations()
                await viewModel.fetchNearbyCheckpoints(latitude: region.center.latitude, longitude: region.center.longitude)
            }
        }
        Task {
            let loc = locationManager.userLocation ?? LocationManager.defaultCoordinate
            await viewModel.updateMyLocation(latitude: loc.latitude, longitude: loc.longitude)
            await viewModel.refreshFriendsLocations()
        }
    }

    func checkCheckpointProximity(_ checkpoint: Checkpoint) {
        let userLoc = locationManager.userLocation ?? LocationManager.defaultCoordinate
        let cpLoc = CLLocation(latitude: checkpoint.latitude, longitude: checkpoint.longitude)
        let myLoc = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        let distanceMeters = cpLoc.distance(from: myLoc)

        if distanceMeters <= 80 {
            selectedCheckpoint = checkpoint
            showCheckpointChat = true
        } else {
            viewModel.errorMessage = "You need to be within 80m to interact! You are \(Int(distanceMeters))m away."
            showDistanceAlert = true
        }
    }

    // MARK: - Seed Checkpoints

    func searchAndSaveLocalPlaces() async {
        if !viewModel.checkpoints.isEmpty { return }

        // Always seed Montreal landmarks — don't rely on MapKit search
        await seedMontrealLandmarks()

        let center = LocationManager.defaultCoordinate
        await viewModel.fetchNearbyCheckpoints(latitude: center.latitude, longitude: center.longitude)
    }

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

// MARK: - Friend Picker Sheet (Glass UI)

struct FriendPickerSheet: View {
    let friends: [AppUser]
    @Binding var friendVisibility: [String: Bool]
    @Environment(\.dismiss) var dismiss

    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        if friends.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No friends added yet.")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(friends) { friend in
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(brandOrange.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(String(friend.username.prefix(1)).uppercased())
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(brandOrange)
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(friend.username)
                                            .font(.system(size: 16, weight: .semibold))
                                        if friend.latitude != 0 || friend.longitude != 0 {
                                            Label("Location available", systemImage: "location.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.green)
                                        } else {
                                            Label("No location", systemImage: "location.slash")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { friendVisibility[friend.id] ?? true },
                                        set: { friendVisibility[friend.id] = $0 }
                                    ))
                                    .labelsHidden()
                                    .tint(brandOrange)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Show Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(brandOrange)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
