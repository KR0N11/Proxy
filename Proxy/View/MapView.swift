//
//  MapView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Local landmark data (always visible, no Firestore dependency)

struct LocalLandmark: Identifiable {
    let id: String
    let name: String
    let type: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Deterministic Firestore doc ID (must match Location.swift logic)
    var firestoreID: String {
        name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ê", with: "e")
            .replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ô", with: "o")
    }

    static let allLandmarks: [LocalLandmark] = [
        // === Schools & Colleges ===
        LocalLandmark(id: "lasalle-college", name: "LaSalle College", type: "school", latitude: 45.4916, longitude: -73.5818),
        LocalLandmark(id: "dawson-college", name: "Dawson College", type: "school", latitude: 45.4890, longitude: -73.5785),
        LocalLandmark(id: "concordia-sgw", name: "Concordia University (SGW)", type: "school", latitude: 45.4953, longitude: -73.5788),
        LocalLandmark(id: "concordia-loyola", name: "Concordia University (Loyola)", type: "school", latitude: 45.4584, longitude: -73.6401),
        LocalLandmark(id: "mcgill", name: "McGill University", type: "school", latitude: 45.5048, longitude: -73.5772),
        LocalLandmark(id: "ets", name: "ETS", type: "school", latitude: 45.4945, longitude: -73.5627),
        LocalLandmark(id: "uqam", name: "UQAM", type: "school", latitude: 45.5095, longitude: -73.5685),
        LocalLandmark(id: "udem", name: "Université de Montréal", type: "school", latitude: 45.5017, longitude: -73.6153),
        LocalLandmark(id: "polytechnique", name: "Polytechnique Montréal", type: "school", latitude: 45.5046, longitude: -73.6130),
        LocalLandmark(id: "hec", name: "HEC Montréal", type: "school", latitude: 45.5013, longitude: -73.6192),
        LocalLandmark(id: "maisonneuve", name: "Collège de Maisonneuve", type: "school", latitude: 45.5535, longitude: -73.5490),
        LocalLandmark(id: "vanier", name: "Vanier College", type: "school", latitude: 45.4672, longitude: -73.6286),
        LocalLandmark(id: "brebeuf", name: "Collège Jean-de-Brébeuf", type: "school", latitude: 45.5015, longitude: -73.6232),
        LocalLandmark(id: "marianopolis", name: "Marianopolis College", type: "school", latitude: 45.4862, longitude: -73.5843),

        // === Parks ===
        LocalLandmark(id: "mont-royal", name: "Parc du Mont-Royal", type: "park", latitude: 45.5048, longitude: -73.5874),
        LocalLandmark(id: "dorchester", name: "Square Dorchester", type: "park", latitude: 45.4988, longitude: -73.5726),
        LocalLandmark(id: "gamelin", name: "Parc Émilie-Gamelin", type: "park", latitude: 45.5162, longitude: -73.5610),
        LocalLandmark(id: "place-des-arts", name: "Place des Arts", type: "park", latitude: 45.5081, longitude: -73.5668),
        LocalLandmark(id: "jardin-botanique", name: "Jardin botanique de Montréal", type: "park", latitude: 45.5596, longitude: -73.5507),
        LocalLandmark(id: "la-fontaine", name: "Parc La Fontaine", type: "park", latitude: 45.5268, longitude: -73.5696),
        LocalLandmark(id: "jean-drapeau", name: "Parc Jean-Drapeau", type: "park", latitude: 45.5134, longitude: -73.5340),
        LocalLandmark(id: "jarry", name: "Parc Jarry", type: "park", latitude: 45.5339, longitude: -73.6271),
        LocalLandmark(id: "parc-maisonneuve", name: "Parc Maisonneuve", type: "park", latitude: 45.5551, longitude: -73.5525),
        LocalLandmark(id: "angrignon", name: "Parc Angrignon", type: "park", latitude: 45.4467, longitude: -73.6042),
        LocalLandmark(id: "saint-louis", name: "Square Saint-Louis", type: "park", latitude: 45.5165, longitude: -73.5669),
        LocalLandmark(id: "jeanne-mance", name: "Parc Jeanne-Mance", type: "park", latitude: 45.5110, longitude: -73.5815),
        LocalLandmark(id: "westmount-park", name: "Westmount Park", type: "park", latitude: 45.4843, longitude: -73.5955),

        // === Landmarks & Culture ===
        LocalLandmark(id: "centre-bell", name: "Centre Bell", type: "landmark", latitude: 45.4960, longitude: -73.5693),
        LocalLandmark(id: "notre-dame", name: "Basilique Notre-Dame", type: "landmark", latitude: 45.5046, longitude: -73.5566),
        LocalLandmark(id: "oratoire", name: "Oratoire Saint-Joseph", type: "landmark", latitude: 45.4920, longitude: -73.6170),
        LocalLandmark(id: "stade-olympique", name: "Stade olympique", type: "landmark", latitude: 45.5579, longitude: -73.5515),
        LocalLandmark(id: "vieux-port", name: "Vieux-Port de Montréal", type: "landmark", latitude: 45.5075, longitude: -73.5530),
        LocalLandmark(id: "marche-atwater", name: "Marché Atwater", type: "landmark", latitude: 45.4810, longitude: -73.5768),
        LocalLandmark(id: "jean-talon", name: "Marché Jean-Talon", type: "landmark", latitude: 45.5362, longitude: -73.6154),
        LocalLandmark(id: "musee-beaux-arts", name: "Musée des beaux-arts", type: "landmark", latitude: 45.4985, longitude: -73.5796),
        LocalLandmark(id: "musee-mccord", name: "Musée McCord", type: "landmark", latitude: 45.5033, longitude: -73.5742),
        LocalLandmark(id: "gare-centrale", name: "Gare Centrale", type: "landmark", latitude: 45.4998, longitude: -73.5670),
        LocalLandmark(id: "cathedrale", name: "Cathédrale Marie-Reine-du-Monde", type: "landmark", latitude: 45.4993, longitude: -73.5680),
        LocalLandmark(id: "habitat-67", name: "Habitat 67", type: "landmark", latitude: 45.4978, longitude: -73.5432),
        LocalLandmark(id: "biosphere", name: "Biosphère", type: "landmark", latitude: 45.5145, longitude: -73.5312),
        LocalLandmark(id: "tour-horloge", name: "Tour de l'Horloge", type: "landmark", latitude: 45.5048, longitude: -73.5451),
        LocalLandmark(id: "place-ville-marie", name: "Place Ville Marie", type: "landmark", latitude: 45.5014, longitude: -73.5693),
        LocalLandmark(id: "complexe-desjardins", name: "Complexe Desjardins", type: "landmark", latitude: 45.5082, longitude: -73.5632),
        LocalLandmark(id: "palais-congres", name: "Palais des congrès", type: "landmark", latitude: 45.5047, longitude: -73.5612),
        LocalLandmark(id: "quartier-spectacles", name: "Quartier des spectacles", type: "landmark", latitude: 45.5088, longitude: -73.5668),
        LocalLandmark(id: "canal-lachine", name: "Canal de Lachine", type: "landmark", latitude: 45.4820, longitude: -73.5705),
        LocalLandmark(id: "chinatown", name: "Chinatown Gate", type: "landmark", latitude: 45.5072, longitude: -73.5602),
    ]
}

// MARK: - MapView

struct MapView: View {
    @EnvironmentObject var viewModel: AppViewModel

    static let lasalle = CLLocationCoordinate2D(latitude: 45.4916, longitude: -73.5818)

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4916, longitude: -73.5818),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @State private var friendVisibility: [String: Bool] = [:]
    @State private var showFriendPicker = false
    @State private var showLeaderboard = false

    @State private var selectedDistance: DistanceFilter = .fiveKm
    @State private var selectedLandmark: LocalLandmark?
    @State private var selectedCheckpoint: Checkpoint?
    @State private var showCheckpointChat = false
    @State private var syncTimer: Timer?
    @State private var showDistanceAlert = false
    @State private var hasSynced = false

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
            if let maxDist = selectedDistance.meters {
                let friendLoc = CLLocation(latitude: friend.latitude, longitude: friend.longitude)
                let myLoc = CLLocation(latitude: MapView.lasalle.latitude, longitude: MapView.lasalle.longitude)
                return friendLoc.distance(from: myLoc) <= maxDist
            }
            return true
        }
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: false,
                annotationItems: mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if item.isMe {
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(brandOrange.opacity(0.25))
                                    .frame(width: 48, height: 48)
                                Circle()
                                    .fill(brandOrange)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: brandOrange.opacity(0.5), radius: 6)
                            }
                            Text("You")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(brandOrange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(6)
                                .shadow(radius: 1)
                        }
                    } else if item.isFriend {
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
                        // Checkpoint / Landmark pin
                        Button {
                            handleLandmarkTap(item)
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

            // Overlay buttons
            VStack {
                HStack {
                    VStack(spacing: 8) {
                        glassButton(icon: "plus", tint: brandOrange) {
                            withAnimation {
                                region.span.latitudeDelta = max(region.span.latitudeDelta / 2, 0.001)
                                region.span.longitudeDelta = max(region.span.longitudeDelta / 2, 0.001)
                            }
                        }
                        glassButton(icon: "minus", tint: brandOrange) {
                            withAnimation {
                                region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 1.0)
                                region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 1.0)
                            }
                        }
                    }
                    .padding(.leading, 12)

                    Spacer()

                    VStack(spacing: 10) {
                        glassButton(icon: "person.2.fill", tint: brandOrange) {
                            showFriendPicker = true
                        }
                        glassButton(icon: "mappin.and.ellipse", tint: brandOrange) {
                            withAnimation {
                                region.center = MapView.lasalle
                                region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            }
                        }
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
                                region.center = MapView.lasalle
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
            // Seed to Firestore in background (idempotent) so chat works
            if !hasSynced {
                hasSynced = true
                Task {
                    await seedCheckpointsToFirestore()
                    await viewModel.fetchNearbyCheckpoints(latitude: MapView.lasalle.latitude, longitude: MapView.lasalle.longitude)
                }
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

    // MARK: - Annotations (local landmarks — always visible!)

    var mapAnnotations: [MapItem] {
        var items: [MapItem] = []

        // "Me" pin at LaSalle
        let myName = viewModel.currentUser?.username ?? "You"
        items.append(MapItem(
            id: "me_\(viewModel.currentUser?.id ?? "self")",
            name: myName,
            coordinate: MapView.lasalle,
            isFriend: false,
            isMe: true,
            checkpointType: "",
            landmarkID: nil
        ))

        // Friends
        for friend in visibleFriends {
            items.append(MapItem(
                id: friend.id,
                name: friend.username,
                coordinate: CLLocationCoordinate2D(latitude: friend.latitude, longitude: friend.longitude),
                isFriend: true,
                isMe: false,
                checkpointType: "",
                landmarkID: nil
            ))
        }

        // Local landmarks — always visible, no Firestore dependency
        for lm in LocalLandmark.allLandmarks {
            items.append(MapItem(
                id: "lm_\(lm.id)",
                name: lm.name,
                coordinate: lm.coordinate,
                isFriend: false,
                isMe: false,
                checkpointType: lm.type,
                landmarkID: lm.id
            ))
        }

        return items
    }

    // MARK: - Landmark Tap → Open Chat

    func handleLandmarkTap(_ item: MapItem) {
        guard let lmID = item.landmarkID,
              let landmark = LocalLandmark.allLandmarks.first(where: { $0.id == lmID }) else { return }

        let distanceMeters = checkDistance(to: landmark.coordinate)

        if distanceMeters <= 80 {
            // Find or create a Checkpoint object for the chat
            let firestoreID = landmark.firestoreID
            if let existing = viewModel.checkpoints.first(where: { $0.id == firestoreID }) {
                selectedCheckpoint = existing
            } else {
                // Build a local Checkpoint so chat can open
                selectedCheckpoint = Checkpoint(id: firestoreID, dict: [
                    "name": landmark.name,
                    "type": landmark.type,
                    "latitude": landmark.latitude,
                    "longitude": landmark.longitude
                ])
            }
            showCheckpointChat = true
        } else {
            viewModel.errorMessage = "You need to be within 80m to interact! You are \(Int(distanceMeters))m away."
            showDistanceAlert = true
        }
    }

    func checkDistance(to coordinate: CLLocationCoordinate2D) -> Double {
        let myLoc = CLLocation(latitude: MapView.lasalle.latitude, longitude: MapView.lasalle.longitude)
        let targetLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return targetLoc.distance(from: myLoc)
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

    func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                await viewModel.updateMyLocation(latitude: MapView.lasalle.latitude, longitude: MapView.lasalle.longitude)
                await viewModel.refreshFriendsLocations()
            }
        }
        Task {
            await viewModel.updateMyLocation(latitude: MapView.lasalle.latitude, longitude: MapView.lasalle.longitude)
            await viewModel.refreshFriendsLocations()
        }
    }

    // MARK: - Seed to Firestore (background, idempotent)

    func seedCheckpointsToFirestore() async {
        for lm in LocalLandmark.allLandmarks {
            await viewModel.createCheckpoint(name: lm.name, type: lm.type, latitude: lm.latitude, longitude: lm.longitude)
        }
    }
}

// MARK: - Map annotation item

struct MapItem: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let isFriend: Bool
    let isMe: Bool
    let checkpointType: String
    let landmarkID: String?  // links to LocalLandmark.id for tap handling
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
