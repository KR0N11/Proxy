import SwiftUI
import MapKit

struct MapScreenView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var firebaseService: FirebaseService

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showFriendsFilter = false
    @State private var hiddenFriendIds: Set<String> = []
    @State private var maxDistance: Double = 0 // 0 = no filter
    @State private var nearbyCheckpoints: [Checkpoint] = []
    @State private var selectedCheckpoint: Checkpoint?
    @State private var showCheckpointChat = false
    @State private var updateTimer: Timer?
    @State private var searchedRegion: MKCoordinateRegion?

    // Distance filter options in miles
    let distanceOptions: [(String, Double)] = [
        ("All", 0),
        ("0.5 mi", 0.5),
        ("1 mi", 1),
        ("5 mi", 5),
        ("10 mi", 10)
    ]

    var visibleFriends: [FriendLocation] {
        firebaseService.friendLocations.filter { friend in
            // Check if hidden
            if hiddenFriendIds.contains(friend.id) { return false }

            // Check distance filter
            if maxDistance > 0, let userLoc = locationManager.userLocation {
                let friendLoc = CLLocation(latitude: friend.latitude, longitude: friend.longitude)
                let distanceInMiles = userLoc.distance(from: friendLoc) / 1609.34
                if distanceInMiles > maxDistance { return false }
            }

            return true
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()

                // Friend annotations
                ForEach(visibleFriends) { friend in
                    Annotation(friend.name, coordinate: friend.coordinate) {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text(String(friend.name.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .shadow(radius: 3)
                            Text(friend.name)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(4)
                        }
                    }
                }

                // Checkpoint annotations (schools & parks)
                ForEach(nearbyCheckpoints) { checkpoint in
                    Annotation(checkpoint.name, coordinate: checkpoint.coordinate) {
                        Button {
                            handleCheckpointTap(checkpoint)
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: checkpoint.type == "school" ? "building.columns.fill" : "leaf.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(checkpoint.type == "school" ? Color.orange : Color.green)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(isWithinRange(checkpoint) ? Color.yellow : Color.clear, lineWidth: 3)
                                    )
                                    .shadow(radius: 3)
                                Text(checkpoint.name)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.85))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            // Friends filter button
            VStack(spacing: 12) {
                Button {
                    showFriendsFilter = true
                } label: {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
            .padding(.top, 60)
            .padding(.trailing, 16)
        }
        .onAppear {
            locationManager.requestPermission()
            startUpdateCycle()
        }
        .onDisappear {
            updateTimer?.invalidate()
        }
        .sheet(isPresented: $showFriendsFilter) {
            FriendsFilterView(
                hiddenFriendIds: $hiddenFriendIds,
                maxDistance: $maxDistance,
                distanceOptions: distanceOptions
            )
        }
        .sheet(isPresented: $showCheckpointChat) {
            if let checkpoint = selectedCheckpoint {
                CheckpointDetailView(checkpoint: checkpoint)
            }
        }
    }

    // MARK: - Helpers

    private func isWithinRange(_ checkpoint: Checkpoint) -> Bool {
        guard let userLoc = locationManager.userLocation else { return false }
        let checkpointLoc = CLLocation(latitude: checkpoint.latitude, longitude: checkpoint.longitude)
        let distanceInFeet = userLoc.distance(from: checkpointLoc) * 3.28084
        return distanceInFeet <= 30
    }

    private func handleCheckpointTap(_ checkpoint: Checkpoint) {
        if isWithinRange(checkpoint) {
            // Fetch latest checkpoint data from Firebase, then show chat
            firebaseService.fetchCheckpoint(id: checkpoint.id) { updated in
                DispatchQueue.main.async {
                    self.selectedCheckpoint = updated ?? checkpoint
                    self.showCheckpointChat = true
                }
            }
        }
    }

    private func startUpdateCycle() {
        // Initial fetch
        performUpdate()

        // Repeat every 30 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            performUpdate()
        }
    }

    private func performUpdate() {
        // Update own location to Firebase
        if let location = locationManager.userLocation {
            firebaseService.updateLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            // Search for nearby schools and parks
            searchNearbyPlaces(around: location.coordinate)
        }
        // Fetch friend locations from Firebase
        firebaseService.fetchFriendLocations()
    }

    private func searchNearbyPlaces(around coordinate: CLLocationCoordinate2D) {
        // Only re-search if moved significantly (500m) from last search
        if let lastRegion = searchedRegion {
            let lastCenter = CLLocation(latitude: lastRegion.center.latitude, longitude: lastRegion.center.longitude)
            let current = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if lastCenter.distance(from: current) < 500 { return }
        }

        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        searchedRegion = region

        searchPlaces(query: "school", type: "school", region: region)
        searchPlaces(query: "park", type: "park", region: region)
    }

    private func searchPlaces(query: String, type: String, region: MKCoordinateRegion) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let items = response?.mapItems else { return }
            let checkpoints = items.prefix(10).map { item -> Checkpoint in
                let coord = item.placemark.coordinate
                let name = item.name ?? query.capitalized
                let id = "\(type)_\(String(format: "%.5f", coord.latitude))_\(String(format: "%.5f", coord.longitude))"
                return Checkpoint(
                    id: id,
                    name: name,
                    type: type,
                    latitude: coord.latitude,
                    longitude: coord.longitude
                )
            }

            DispatchQueue.main.async {
                // Merge with existing, avoiding duplicates
                for cp in checkpoints {
                    if !self.nearbyCheckpoints.contains(where: { $0.id == cp.id }) {
                        self.nearbyCheckpoints.append(cp)
                        // Save to Firebase so chat can be attached
                        self.firebaseService.saveCheckpoint(cp)
                    }
                }
            }
        }
    }
}
