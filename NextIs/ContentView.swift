//
//  ContentView.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/15/25.
//


import SwiftUI

// MARK: - Place model for sheet(item:)
private struct Place: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let imageName: String
}


struct PlacesView: View {
    // MARK: - Properties
    
    // Grid layout: 3 columns for the main screen
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: 3)
    
    // List of rooms/places with their image names
    private let places: [Place] = [
        Place(name: "Farm Room", imageName: "farmRoom"),
        Place(name: "Fridge", imageName: "fridge"),
        Place(name: "Construction", imageName: "construction"),
        Place(name: "Dinosaur Room", imageName: "dinosaurRoom"),
        Place(name: "Grocery Room", imageName: "groceryRoom"),
        Place(name: "Centers", imageName: "centers"),
        Place(name: "Town Room", imageName: "townRoom"),
        Place(name: "Four Seasons", imageName: "fourSeasons"),
        Place(name: "Vehicle Room", imageName: "vehicleRoom"),
        Place(name: "Art Center", imageName: "artCenter"),
        Place(name: "Blue Room", imageName: "blueRoom"),
        Place(name: "Ocean Room", imageName: "oceanRoom"),
        Place(name: "Gross Motor", imageName: "grossMotor"),
        Place(name: "Forest Room", imageName: "forestRoom"),
        Place(name: "Eating Area", imageName: "eatingArea"),
        Place(name: "Train Room", imageName: "trainRoom"),
        Place(name: "Unicorn Room", imageName: "unicornRoom"),
        Place(name: "Picnic Room", imageName: "picnicRoom"),
        Place(name: "Space Room", imageName: "spaceRoom"),
        Place(name: "Circle Time", imageName: "circleTime"),
        Place(name: "Speech Therapy", imageName: "speechTherapy"),
        Place(name: "Book Nook", imageName: "bookNook"),
        Place(name: "Dollhouse Room", imageName: "dollhouseRoom"),
        Place(name: "Gym", imageName: "gym"),
        Place(name: "Bathroom", imageName: "bathroom")
    ]
    
    // Which place the user tapped
    @State private var selectedPlace: Place? = nil
    @State private var navigateToPlace: Bool = false
    // Navigation stack path for NavigationStack
    @State private var path: [Place] = []
    // Alert when trying to switch rooms while a session is active
    @State private var showActiveRoomAlert: Bool = false
    @State private var activeRoomNameForAlert: String = ""

    // Show the Kids screen
    // @State private var showKidsManager: Bool = false
    // Remember which kid is active across the app
    @AppStorage("CurrentKidID") private var currentKidID: String = "kid_default"

    // Observe central data controller so the toolbar title updates live
    @ObservedObject private var data = DataController.shared

    // Resolve active kid name from the central DataController
    private var activeKidName: String {
        if let idStr = data.activeKidID,
           let id = UUID(uuidString: idStr),
           let kid = data.kids.first(where: { $0.id == id }) {
            return kid.name
        }
        if let id = UUID(uuidString: currentKidID),
           let kid = data.kids.first(where: { $0.id == id }) {
            return kid.name
        }
        return "Kids"
    }
    
    // MARK: - Body layout
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PlayfulBackground()
                // Scrollable grid of place buttons
                // When a place is tapped, show the room sheet for that place
                ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Big title at the top
                    Text("PLACES")
                        .font(.system(size: 40, weight: .bold))
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                        ForEach(places) { place in
                            Button {
                                let dc = DataController.shared
                                guard let kidID = dc.activeKidID else { return }

                                if let currentRoom = dc.currentRoomName(for: kidID) {
                                    if currentRoom == place.name {
                                        // Already in this room: just navigate without restarting timer
                                        self.path.append(place)
                                    } else {
                                        // Block switching rooms; show alert
                                        self.activeRoomNameForAlert = currentRoom
                                        self.showActiveRoomAlert = true
                                    }
                                } else {
                                    // No active session for this kid: start and navigate
                                    dc.startRoomVisit(placeName: place.name)
                                    self.path.append(place)
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(place.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 110, height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text(place.name)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .minimumScaleFactor(0.7)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled({
                                let dc = DataController.shared
                                guard let kidID = dc.activeKidID else { return false }
                                guard let currentRoom = dc.currentRoomName(for: kidID) else { return false }
                                // Disable other rooms, but keep the CURRENT room tappable
                                return currentRoom != place.name
                            }())
                            .opacity({
                                let dc = DataController.shared
                                if let kidID = dc.activeKidID, let currentRoom = dc.currentRoomName(for: kidID) {
                                    return currentRoom == place.name ? 1.0 : 0.4
                                }
                                return 1.0
                            }())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    // Removed .sheet(isPresented: $showRoomSheet) from here (was attached to grid)
                }
            }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Text(activeKidName)
                                .font(.headline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .minimumScaleFactor(0.85)
                                .layoutPriority(0)
                            Text("Active")
                                .fixedSize(horizontal: true, vertical: false)
                                .layoutPriority(2)
                                .font(.caption2).bold()
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(
                                    Capsule().fill(Color.accentColor.opacity(0.18))
                                )
                                .overlay(
                                    Capsule().stroke(Color.accentColor, lineWidth: 1)
                                )
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .alert("Finish current room first", isPresented: $showActiveRoomAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("You're currently in \(activeRoomNameForAlert). Drop the icon on All Done to finish before switching rooms.")
                }
            }
            .navigationDestination(for: Place.self) { p in
                PlaceScreen(place: (name: p.name, imageName: p.imageName))
            }
            .onReceive(NotificationCenter.default.publisher(for: .tabReselected)) { note in
                if let index = note.userInfo?["index"] as? Int, index == 0 {
                    path.removeAll() // pop to root of Places
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPlace)) { note in
                guard let placeName = note.userInfo?["placeName"] as? String else { return }
                guard let target = places.first(where: { $0.name == placeName }) else { return }
                let dc = DataController.shared

                if let kidID = dc.activeKidID {
                    if let currentRoom = dc.currentRoomName(for: kidID) {
                        if currentRoom == placeName {
                            path.append(target) // already in this room → just navigate
                        } else {
                            self.activeRoomNameForAlert = currentRoom
                            self.showActiveRoomAlert = true
                        }
                    } else {
                        dc.startRoomVisit(placeName: placeName)
                        path.append(target)
                    }
                }
            }
        }
        .onAppear {
            if DataController.shared.activeKidID == nil,
               let id = UUID(uuidString: currentKidID),
               let kid = data.kids.first(where: { $0.id == id }) {
                DataController.shared.activateKid(kid)
            }
        }
    }
    
    // MARK: - Helper structs
    
    // Geometry Preference Key to capture frames on screen
    private struct ViewFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }
    
    // PlaceScreen view showing the All Done drop zone and draggable place icon
    private struct PlaceScreen: View {
        let place: (name: String, imageName: String)
        @Environment(\.dismiss) private var dismiss

        @AppStorage("CurrentKidID") private var currentKidID: String = "kid_default"

        // Drag state
        @State private var dragOffset: CGSize = .zero
        @State private var iconStartLocation: CGPoint = .zero
        @State private var iconBaseFrame: CGRect = .zero
        @State private var dropFrame: CGRect = .zero

        // Interaction state
        @State private var isIconVisible: Bool = true
        @State private var showNextIs: Bool = false
        @State private var allDoneScale: CGFloat = 1.0
        @State private var isOverDrop: Bool = false
        @State private var iconScale: CGFloat = 1.0
        @State private var dropConfirmed: Bool = false
        // Arrow state for drop guidance
        @State private var showArrow: Bool = true
        // Live timer state
        @State private var elapsedSeconds: Int = 0
        private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        // A named coordinate space to compare frames
        private let spaceName = "roomSheetSpace"
        // Observe central data controller so pause/play button updates live
        @ObservedObject private var data = DataController.shared

        // Computed property to resolve the active kid name from DataController
        private var activeKidName: String {
            if let idStr = DataController.shared.activeKidID,
               let id = UUID(uuidString: idStr),
               let kid = DataController.shared.kids.first(where: { $0.id == id }) {
                return kid.name
            }
            if let id = UUID(uuidString: currentKidID),
               let kid = DataController.shared.kids.first(where: { $0.id == id }) {
                return kid.name
            }
            return "Kids"
        }
        // Format seconds as H:MM:SS or MM:SS
        private func format(_ seconds: Int) -> String {
            let hrs = seconds / 3600
            let mins = (seconds % 3600) / 60
            let secs = seconds % 60
            if hrs > 0 {
                return String(format: "%d:%02d:%02d", hrs, mins, secs)
            } else {
                return String(format: "%02d:%02d", mins, secs)
            }
        }
        var body: some View {
            ZStack {
                PlayfulBackground()
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            // Timer control toggle button (hidden once dropped)
                            if !dropConfirmed {
                                HStack(spacing: 10) {
                                    Button(action: {
                                        if data.isPaused {
                                            DataController.shared.resumeRoomVisit()
                                        } else {
                                            DataController.shared.pauseRoomVisit()
                                        }
                                    }) {
                                        Image(systemName: data.isPaused ? "play.fill" : "pause.fill")
                                            .imageScale(.large)
                                            .padding(6)
                                            .background(Color.primary.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding()
                            }

                            Text(place.name)
                                .font(.system(size: 34, weight: .bold))
                                .multilineTextAlignment(.center)

                            Text(format(elapsedSeconds))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Elapsed time")
                        }
                        
                        
                        
                        
                        // Draggable place icon placeholder (real image is drawn in an overlay so it stays on top of everything)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(maxWidth: 150, maxHeight: 150)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: ViewFrameKey.self, value: geo.frame(in: .named(spaceName)))
                                }
                            )
                            
                            .onPreferenceChange(ViewFrameKey.self) { value in
                                iconBaseFrame = value
                                    
                            }

                        // Down arrow appears above All Done until drop is completed
                        if showArrow {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.black)
                                .transition(.opacity)
                                .padding(.top, 30)
                        }
                        // Drop target: All Done
                        Image("AllDone")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .scaleEffect(allDoneScale)
                            .zIndex(0)
                            .overlay(
                                // Capture drop target frame in the named coordinate space
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: ViewFrameKey.self, value: geo.frame(in: .named(spaceName)))
                                }
                            )
                            .onPreferenceChange(ViewFrameKey.self) { value in
                                dropFrame = value
                            }
                        Text(dropConfirmed ? "All Done!" : "All done?")
                            .font(.title)
                            .transition(.opacity)
                    }
                    .padding(20)
                    .overlay(
                        Group {
                            if isIconVisible {
                                Image(place.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 200, maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .scaleEffect(iconScale)
                                    .padding(.top)
                                    // Absolute positioning so the icon can be dragged anywhere and remain visually on top
                                    .position(x: iconBaseFrame.midX + dragOffset.width,
                                              y: iconBaseFrame.midY + dragOffset.height)
                                    // High-priority gesture so it wins over other gestures beneath
                                    .highPriorityGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if iconStartLocation == .zero {
                                                    iconStartLocation = value.startLocation
                                                }
                                                dragOffset = CGSize(width: value.translation.width, height: value.translation.height)
                                                let currentFrame = iconBaseFrame.offsetBy(dx: dragOffset.width, dy: dragOffset.height)
                                                let nowOverDrop = currentFrame.intersects(dropFrame)
                                                if nowOverDrop != isOverDrop {
                                                    isOverDrop = nowOverDrop
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        iconScale = isOverDrop ? 0.5 : 1.0
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                handleDropAttempt()
                                            }
                                    )
                                    // Ensure this layer stays above all other content in this view
                                    .zIndex(1000)
                            }
                        }
                    )

                    // Next Is appears only after successful drop and zoom
                    if showNextIs {
                        Button {
                            // Just dismiss, timer already stopped on drop
                            dismiss()
                        } label: {
                            Image("nextIs")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 300, maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 20)
                    }
                }
                .coordinateSpace(name: spaceName)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 0) {
                            Text(" < Back")
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(activeKidName)
                        .font(.headline)
                }
            }
            .onAppear {
                // Timer already started on tap in the previous screen
                dropConfirmed = false
                elapsedSeconds = DataController.shared.currentElapsedSeconds()
            }
            .onReceive(ticker) { _ in
                // Freeze the timer after a successful drop
                guard !dropConfirmed else { return }
                elapsedSeconds = DataController.shared.currentElapsedSeconds()
            }
        }

        // MARK: - Helper methods

        // Check if the icon was dropped on All Done and run animations accordingly
        private func handleDropAttempt() {
            if isOverDrop {
                // Hide the arrow with animation
                withAnimation(.easeInOut(duration: 0.2)) { showArrow = false }
                // Capture final time before ending visit so UI can display the frozen total
                elapsedSeconds = DataController.shared.currentElapsedSeconds()
                DataController.shared.endRoomVisit()
                dropConfirmed = true
                // Hide the icon, animate AllDone zoom, then reveal Next Is
                withAnimation(.easeInOut(duration: 0.15)) {
                    iconScale = 0.75 // slight extra shrink just before disappearing
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isIconVisible = false
                }
                withAnimation(.easeInOut(duration: 0.35)) {
                    allDoneScale = 1.15
                }
                // Spring back to 1 and then show Next Is
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        allDoneScale = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut) {
                            showNextIs = true
                        }
                    }
                }
            } else {
                dropConfirmed = false
                // Not dropped on target: snap back and reset scale
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dragOffset = .zero
                    iconScale = 1.0
                }
            }
        }
    }
}

#Preview {
    ContentView()
}


struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PlacesView()
                .tabItem { Label("Places", systemImage: "square.grid.3x3.fill") }
                .tag(0)

            KidsManagerView()
                .tabItem { Label("Kids", systemImage: "person.3.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .background(TabBarIntrospector())
        .onReceive(NotificationCenter.default.publisher(for: .tabReselected)) { note in
            guard let index = note.userInfo?["index"] as? Int else { return }
            // 1) Switch to the tapped tab immediately
            selectedTab = index
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PlayfulBackground()
                VStack(spacing: 16) {
                    Text("Settings")
                        .font(.title)
                        .bold()
                    Text("Configure the app here.")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            
        }
    }
}


// MARK: - Tab bar reselection bridge and notification helper

extension Notification.Name {
    static let tabReselected = Notification.Name("TabReselectedNotification")
}
extension Notification.Name {
    static let navigateToPlace = Notification.Name("NavigateToPlaceNotification")
}
private final class TabBarDelegateProxy: NSObject, UITabBarControllerDelegate {
    static let shared = TabBarDelegateProxy()
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let index = tabBarController.viewControllers?.firstIndex(of: viewController) ?? 0
        NotificationCenter.default.post(name: .tabReselected, object: nil, userInfo: ["index": index])
    }
}

private struct TabBarIntrospector: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { ProxyVC() }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private final class ProxyVC: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // Walk up the parent chain to find the UITabBarController and set delegate
            var parentResponder: UIResponder? = self
            while let responder = parentResponder {
                if let tbc = responder as? UITabBarController {
                    tbc.delegate = TabBarDelegateProxy.shared
                    break
                }
                parentResponder = responder.next
            }
        }
    }
}



// MARK: - Kid model & storage (UserDefaults)
struct Kid: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
}

/// Simple store that saves/loads kids from UserDefaults
final class KidsStore: ObservableObject {
    @Published var kids: [Kid] = [] { didSet { save() } }
    private let storageKey = "Kids_v1"

    init() { load() }

    // Save to UserDefaults
    private func save() {
        do {
            let data = try JSONEncoder().encode(kids)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // Ignore for now
        }
    }

    // Load from UserDefaults
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([Kid].self, from: data) {
            kids = decoded
        }
    }

    // CRUD helpers
    func addKid(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kids.append(Kid(name: trimmed))
    }

    func deleteKids(at offsets: IndexSet, currentKidID: inout String) {
        let idsToDelete = offsets.map { kids[$0].id }
        kids.remove(atOffsets: offsets)
        // If current kid was deleted, clear selection
        if let uuid = UUID(uuidString: currentKidID), idsToDelete.contains(uuid) {
            currentKidID = "kid_default"
        }
    }

    func rename(kid: Kid, to newName: String) {
        guard let idx = kids.firstIndex(of: kid) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kids[idx].name = trimmed
    }
}

// MARK: - Visit Logger (UserDefaults)
struct DailyVisits: Codable {
    var dateKey: String              // "YYYY-MM-DD"
    var placeCounts: [String: Int]   // Place name -> visit count
}

struct KidVisitBook: Codable {
    // dateKey -> DailyVisits
    var days: [String: DailyVisits] = [:]
}

final class VisitLogger {
    static let shared = VisitLogger()
    private init() {}

    private let storageKey = "KidVisitLogs_v1"

    // kidID -> KidVisitBook
    private var cache: [String: KidVisitBook] = [:]

    // Load once from storage
    private func ensureLoaded() {
        if !cache.isEmpty { return }
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoded = try JSONDecoder().decode([String: KidVisitBook].self, from: data)
                cache = decoded
            } catch {
                cache = [:]
            }
        }
    }

    // Persist to storage
    private func save() {
        do {
            let data = try JSONEncoder().encode(cache)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // Handle error if needed
        }
    }

    // Helper: make a local "YYYY-MM-DD" key for today (respects system time zone)
    private func todayKey() -> String {
        let now = Date()
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: now)
        let dateOnly = cal.date(from: comps) ?? now
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: dateOnly)
    }

    // MARK: - Public API

    /// Log a place for a kid for "today".
    func logVisit(kidID: String, placeName: String) {
        ensureLoaded()
        let key = todayKey()
        var book = cache[kidID] ?? KidVisitBook()
        var day = book.days[key] ?? DailyVisits(dateKey: key, placeCounts: [:])
        day.placeCounts[placeName, default: 0] += 1
        book.days[key] = day
        cache[kidID] = book
        save()
    }

    /// Read today's places for a kid.
    func todaysPlaces(for kidID: String) -> [String] {
        ensureLoaded()
        let key = todayKey()
        return Array(cache[kidID]?.days[key]?.placeCounts.keys ?? Dictionary<String, Int>().keys)
    }

    /// Read today's place visit counts for a kid.
    func todaysCounts(for kidID: String) -> [String: Int] {
        ensureLoaded()
        let key = todayKey()
        return cache[kidID]?.days[key]?.placeCounts ?? [:]
    }

    /// Read any day's places (use "yyyy-MM-dd").
    func places(for kidID: String, on dateKey: String) -> [String] {
        ensureLoaded()
        return Array(cache[kidID]?.days[dateKey]?.placeCounts.keys ?? Dictionary<String, Int>().keys)
    }

    /// Read a simple history for a kid (date -> places…)
    func history(for kidID: String) -> [String: [String]] {
        ensureLoaded()
        var result: [String: [String]] = [:]
        if let book = cache[kidID] {
            for (dateKey, daily) in book.days {
                result[dateKey] = Array(daily.placeCounts.keys)
            }
        }
        return result
    }
}


// MARK: - Shared playful background
private struct PlayfulBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.98, green: 0.86, blue: 0.99), location: 0.0),   // soft lavender
                .init(color: Color(red: 0.86, green: 0.95, blue: 1.00), location: 0.25),  // sky blue
                .init(color: Color(red: 1.00, green: 0.95, blue: 0.80), location: 0.50),  // pastel peach/yellow
                .init(color: Color(red: 0.87, green: 1.00, blue: 0.90), location: 0.75),  // mint green
                .init(color: Color(red: 0.95, green: 0.87, blue: 1.00), location: 1.00)   // lilac
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Shared place image map
private let placeImageMap: [String: String] = [
    "Farm Room": "farmRoom",
    "Fridge": "fridge",
    "Construction": "construction",
    "Dinosaur Room": "dinosaurRoom",
    "Grocery Room": "groceryRoom",
    "Centers": "centers",
    "Town Room": "townRoom",
    "Four Seasons": "fourSeasons",
    "Vehicle Room": "vehicleRoom",
    "Art Center": "artCenter",
    "Blue Room": "blueRoom",
    "Ocean Room": "oceanRoom",
    "Gross Motor": "grossMotor",
    "Forest Room": "forestRoom",
    "Eating Area": "eatingArea",
    "Train Room": "trainRoom",
    "Unicorn Room": "unicornRoom",
    "Picnic Room": "picnicRoom",
    "Space Room": "spaceRoom",
    "Circle Time": "circleTime",
    "Speech Therapy": "speechTherapy",
    "Book Nook": "bookNook",
    "Dollhouse Room": "dollhouseRoom",
    "Gym": "gym",
    "Bathroom": "bathroom"
]

struct KidsManagerView: View {
    @StateObject private var store = KidsStore()
    @AppStorage("CurrentKidID") private var currentKidID: String = "kid_default"
    @State private var newKidName: String = ""
    @State private var kidBeingRenamed: Kid? = nil
    @State private var renameText: String = ""
    @State private var showAddPrompt: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var showKidSwitchAlert: Bool = false
    @State private var blockingKidName: String = ""
    
    private var activeKidName: String {
        if let id = UUID(uuidString: currentKidID), let kid = store.kids.first(where: { $0.id == id }) {
            return kid.name
        }
        return "None"
    }

    private func format(_ seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PlayfulBackground()
                
                VStack {
                    Text("KIDS")
                        .font(.system(size: 40, weight: .bold))
                        .padding(.top, 8)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                        
                    VStack(spacing: 12) {
                        // Active kid indicator (only one active at a time)
                        
                        // Empty state message
                        if store.kids.isEmpty {
                            VStack(spacing: 8) {
                                Text("No kids yet")
                                    .font(.headline)
                                Text("Add a Kid to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                            }
                        }
                        
                        // Kids list (only show when there are kids)
                        if !store.kids.isEmpty {
                            List {
                                Section(footer: Text("Tap a kid to view places visited.").font(.footnote)) {
                                    ForEach(store.kids) { kid in
                                        HStack(spacing: 12) {
                                            // Circle selector — sets the active kid without navigating
                                            Button {
                                                setActiveKid(kid)
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .stroke((currentKidID == kid.id.uuidString) ? Color.accentColor : .secondary, lineWidth: 2)
                                                        .frame(width: 22, height: 22)
                                                    if currentKidID == kid.id.uuidString {
                                                        Circle()
                                                            .frame(width: 10, height: 10)
                                                    }
                                                }
                                                .contentShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel((currentKidID == kid.id.uuidString) ? "Active kid" : "Set active kid")

                                            // Everything else navigates
                                            NavigationLink(destination: KidProfileView(kid: kid)) {
                                                HStack {
                                                    Text(kid.name)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                                                        let roomName = DataController.shared.currentRoomName(for: kid.id.uuidString) ?? ""
                                                        let secs = DataController.shared.currentElapsedSeconds(for: kid.id.uuidString)
                                                        Text("\(roomName.isEmpty ? "—" : roomName) · \(format(secs))")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                            .truncationMode(.tail)
                                                            .layoutPriority(1)
                                                            .accessibilityLabel(roomName.isEmpty
                                                                ? "No room, elapsed \(format(secs))"
                                                                : "\(roomName), elapsed \(format(secs))")
                                                    }
                                                }
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, 6)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .contextMenu {
                                            Button("Rename") {
                                                kidBeingRenamed = kid
                                                renameText = kid.name
                                            }
                                        }
                                        if kidBeingRenamed == kid {
                                            HStack {
                                                Spacer(minLength: 24)
                                                TextField("Name", text: $renameText)
                                                    .textFieldStyle(.roundedBorder)
                                                Button("Save") {
                                                    store.rename(kid: kid, to: renameText)
                                                    kidBeingRenamed = nil
                                                }
                                            }
                                        }
                                    }
                                    .onDelete { offsets in
                                        var id = currentKidID
                                        store.deleteKids(at: offsets, currentKidID: &id)
                                        currentKidID = id
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .listStyle(.insetGrouped)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            TextField("Add kid name", text: $newKidName)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                                .onSubmit { addKid() }
                            Button {
                                addKid()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                            }
                            
                            .accessibilityLabel("Add kid")
                        }
                        .padding()
                        
                    }
                }
                .alert("Add Kid", isPresented: $showAddPrompt) {
                    TextField("Name", text: $newKidName)
                    Button("Cancel", role: .cancel) { }
                    Button("Add") { addKid() }
                }
            }
        }
        // No longer need timer for live row updates thanks to TimelineView
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 0) {
                        Text(" < Back")
                    }
                }
            }
        }
        .alert("Finish current room first", isPresented: $showKidSwitchAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You're currently with \(blockingKidName). Please finish up before switching.")
        }
        .onAppear {
            if DataController.shared.activeKidID == nil,
               let id = UUID(uuidString: currentKidID),
               let kid = store.kids.first(where: { $0.id == id }) {
                DataController.shared.activateKid(kid)
            }
        }
    }
    
    private func setActiveKid(_ kid: Kid) {
        let dc = DataController.shared
        // If someone is in a room and it's not the tapped kid, block the switch
        if let activeID = dc.activeKidID,
           let currentRoom = dc.currentRoomName(for: activeID),
           activeID != kid.id.uuidString,
           !currentRoom.isEmpty {
            // Resolve the blocking kid's name for the alert
            if let uuid = UUID(uuidString: activeID),
               let blockingKid = store.kids.first(where: { $0.id == uuid }) {
                blockingKidName = blockingKid.name
            } else {
                blockingKidName = "the current kid"
            }
            showKidSwitchAlert = true
            return
        }
        // Otherwise safe to activate this kid
        currentKidID = kid.id.uuidString
        dc.activateKid(kid)
        // Navigate to Places tab immediately
        NotificationCenter.default.post(name: .tabReselected, object: nil, userInfo: ["index": 0])
    }

    private func addKid() {
        store.addKid(named: newKidName)
        // If no active kid yet, activate the one we just added
        if currentKidID == "kid_default", let newID = store.kids.last?.id.uuidString {
            currentKidID = newID
        }
        newKidName = ""
    }
// MARK: - Kid Profile Screen
struct KidProfileView: View {
    let kid: Kid
    @Environment(\.dismiss) private var dismiss
    @AppStorage("CurrentKidID") private var currentKidID: String = "kid_default"

    private let placeImageMap: [String: String] = [
        "Farm Room": "farmRoom",
        "Fridge": "fridge",
        "Construction": "construction",
        "Dinosaur Room": "dinosaurRoom",
        "Grocery Room": "groceryRoom",
        "Centers": "centers",
        "Town Room": "townRoom",
        "Four Seasons": "fourSeasons",
        "Vehicle Room": "vehicleRoom",
        "Art Center": "artCenter",
        "Blue Room": "blueRoom",
        "Ocean Room": "oceanRoom",
        "Gross Motor": "grossMotor",
        "Forest Room": "forestRoom",
        "Eating Area": "eatingArea",
        "Train Room": "trainRoom",
        "Unicorn Room": "unicornRoom",
        "Picnic Room": "picnicRoom",
        "Space Room": "spaceRoom",
        "Circle Time": "circleTime",
        "Speech Therapy": "speechTherapy",
        "Book Nook": "bookNook",
        "Dollhouse Room": "dollhouseRoom",
        "Gym": "gym",
        "Bathroom": "bathroom"
    ]

    private var todaysVisits: [String: VisitData] {
        DataController.shared.todaysVisits(for: kid.id.uuidString)
    }

    var body: some View {
        ZStack {
            PlayfulBackground()
            VStack(spacing: 8) {
                // Live room + timer for this kid (only visible if actually in a room)
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let roomName = DataController.shared.currentRoomName(for: kid.id.uuidString) ?? ""
                    let secs = DataController.shared.currentElapsedSeconds(for: kid.id.uuidString)
                    if !roomName.isEmpty {
                        Button {
                            // Switch to Places tab
                            NotificationCenter.default.post(
                                name: .tabReselected,
                                object: nil,
                                userInfo: ["index": 0]
                            )
                            // Then tell PlacesView which room to open
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(
                                    name: .navigateToPlace,
                                    object: nil,
                                    userInfo: ["placeName": roomName]
                                )
                            }
                        } label: {
                            HStack(alignment: .firstTextBaseline) {
                                if let imgName = placeImageMap[roomName] {
                                    Image(imgName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }
                                }
                                Text("Now in: \(roomName)")
                                    .font(.headline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Text(format(secs))
                                    .font(.headline)
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                                    .accessibilityLabel("Elapsed time")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }

                Group {
                    if todaysVisits.isEmpty && (DataController.shared.currentRoomName(for: kid.id.uuidString) ?? "").isEmpty {
                        VStack(spacing: 12) {
                            Text("No visits yet today")
                                .font(.headline)
                            Text("When a room session ends, it will show up here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            Section(header: Text("Today's Places")) {
                                let sorted = todaysVisits.sorted { lhs, rhs in
                                    if lhs.value.count == rhs.value.count {
                                        return lhs.key < rhs.key
                                    }
                                    return lhs.value.count > rhs.value.count
                                }
                                ForEach(sorted, id: \.key) { (place, data) in
                                    let minutes = Int(data.totalTime / 60)
                                    NavigationLink {
                                        NotesView(kidID: kid.id.uuidString, placeName: place)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(placeImageMap[place] ?? "")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 32, height: 32)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                            VStack(alignment: .leading) {
                                                Text(place)
                                                Text("\(data.count) visits · \(minutes) min")
                                                    .font(.footnote)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .listStyle(.insetGrouped)
                    }
                }
            }
        }
        .navigationTitle(kid.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    // Formats seconds as H:MM:SS or MM:SS
    private func format(_ seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}

// NotesView for per-kid, per-place, per-day notes
struct NotesView: View {
    let kidID: String
    let placeName: String

    @State private var notesText: String = ""

    private var todayKey: String {
        let now = Date()
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: now)
        let dateOnly = cal.date(from: comps) ?? now
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: dateOnly)
    }

    private var storageKey: String { "notes_\(kidID)_\(todayKey)_\(placeName)" }

    var body: some View {
        ZStack {
            PlayfulBackground()
            VStack(spacing: 12) {
                Text("Notes for \(placeName)")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Text("Today: \(todayKey)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                TextEditor(text: $notesText)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.top)
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notesText = UserDefaults.standard.string(forKey: storageKey) ?? ""
        }
        .onDisappear {
            UserDefaults.standard.set(notesText, forKey: storageKey)
        }
    }
}
}
    
   

//
//  DataController.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/15/25.
//


// MARK: - DataController
import Foundation
import Combine

final class DataController: ObservableObject {
    static let shared = DataController()
    
    @Published private(set) var kids: [Kid] = []
    @Published private(set) var activeKidID: String? = nil
    
    private let kidsKey = "Kids_v1"
    private let activeKidKey = "active_kid_id"
    private let visitsKey = "visits_by_kid"

    // Per-kid active session model
    private struct Session {
        var roomName: String
        var startTime: Date?        // non-nil when running
        var accumulated: TimeInterval // seconds accumulated while paused/stopped
        var isPaused: Bool
    }

    // kidID -> Session
    private var sessions: [String: Session] = [:]

    // Published view of the **current** kid's pause state for UI bindings
    @Published private(set) var isPaused: Bool = false
    
    private init() {
        loadKids()
        loadActiveKid()
    }
    
    // MARK: - Kid Management
    func addKid(name: String) {
        let newKid = Kid(name: name)
        kids.append(newKid)
        saveKids()
    }
    
    func renameKid(_ kid: Kid, to newName: String) {
        if let index = kids.firstIndex(where: { $0.id == kid.id }) {
            kids[index].name = newName
            saveKids()
        }
    }
    
    func activateKid(_ kid: Kid) {
        activeKidID = kid.id.uuidString
        UserDefaults.standard.set(activeKidID, forKey: activeKidKey)
    }
    
    private func loadKids() {
        if let data = UserDefaults.standard.data(forKey: kidsKey),
           let decoded = try? JSONDecoder().decode([Kid].self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.kids = decoded
            }
        }
    }
    
    private func saveKids() {
        if let data = try? JSONEncoder().encode(kids) {
            UserDefaults.standard.set(data, forKey: kidsKey)
        }
    }
    
    private func loadActiveKid() {
        if let stored = UserDefaults.standard.string(forKey: activeKidKey), !stored.isEmpty {
            activeKidID = stored
            return
        }
        if let appStorageID = UserDefaults.standard.string(forKey: "CurrentKidID"),
           !appStorageID.isEmpty {
            activeKidID = appStorageID
            UserDefaults.standard.set(appStorageID, forKey: activeKidKey)
        }
    }
    
    // MARK: - Visit Logging
    func startRoomVisit(placeName: String) {
        guard let kidID = activeKidID else { return }
        if let sess = sessions[kidID], (sess.startTime != nil || sess.accumulated > 0) {
            // Session already exists (running or paused) — do not restart
            return
        }
        sessions[kidID] = Session(roomName: placeName, startTime: Date(), accumulated: 0, isPaused: false)
        syncPublishedPauseState()
    }

    /// Pause the current room timer for the active kid.
    func pauseRoomVisit() {
        guard let kidID = activeKidID, var sess = sessions[kidID], !sess.isPaused, let start = sess.startTime else { return }
        sess.accumulated += Date().timeIntervalSince(start)
        sess.startTime = nil
        sess.isPaused = true
        sessions[kidID] = sess
        syncPublishedPauseState()
    }

    /// Resume a paused room timer for the active kid.
    func resumeRoomVisit() {
        guard let kidID = activeKidID, var sess = sessions[kidID], sess.isPaused else { return }
        sess.startTime = Date()
        sess.isPaused = false
        sessions[kidID] = sess
        syncPublishedPauseState()
    }

    /// Cancel the current room timing without saving (rarely used now).
    func cancelRoomVisit() {
        guard let kidID = activeKidID else { return }
        sessions.removeValue(forKey: kidID)
        syncPublishedPauseState()
    }

    func endRoomVisit() {
        guard let kidID = activeKidID, var sess = sessions[kidID] else {
            syncPublishedPauseState(); return
        }
        let duration: TimeInterval
        if sess.isPaused {
            duration = sess.accumulated
        } else if let start = sess.startTime {
            duration = sess.accumulated + Date().timeIntervalSince(start)
        } else {
            duration = sess.accumulated
        }

        // Save visit
        var visitsByKid = loadVisits()
        var visitsForKid = visitsByKid[kidID] ?? [:]
        let todayKey = todayDateKey()
        var placeData = visitsForKid[todayKey] ?? [:]
        var visit = placeData[sess.roomName] ?? VisitData(count: 0, totalTime: 0)
        visit.count += 1
        visit.totalTime += duration
        placeData[sess.roomName] = visit
        visitsForKid[todayKey] = placeData
        visitsByKid[kidID] = visitsForKid
        saveVisits(visitsByKid)

        // Clear session for this kid
        sessions.removeValue(forKey: kidID)
        syncPublishedPauseState()
    }

    /// Return the current room name for the given kid if they are the active kid and currently in a room.
    func currentRoomName(for kidID: String) -> String? {
        return sessions[kidID]?.roomName
    }
    
    func todaysVisits(for kidID: String) -> [String: VisitData] {
        let visitsByKid = loadVisits()
        let todayKey = todayDateKey()
        return visitsByKid[kidID]?[todayKey] ?? [:]
    }
    
    // MARK: - Storage Helpers
    private func loadVisits() -> [String: [String: [String: VisitData]]] {
        if let data = UserDefaults.standard.data(forKey: visitsKey),
           let decoded = try? JSONDecoder().decode([String: [String: [String: VisitData]]].self, from: data) {
            return decoded
        }
        return [:]
    }
    
    private func saveVisits(_ visits: [String: [String: [String: VisitData]]]) {
        if let data = try? JSONEncoder().encode(visits) {
            UserDefaults.standard.set(data, forKey: visitsKey)
        }
    }
    
    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    /// Returns the current elapsed seconds for the active room timer, or 0 if none.
    func currentElapsedSeconds() -> Int {
        guard let kidID = activeKidID, let sess = sessions[kidID] else { return 0 }
        if sess.isPaused { return max(0, Int(sess.accumulated)) }
        if let start = sess.startTime { return max(0, Int(sess.accumulated + Date().timeIntervalSince(start))) }
        return max(0, Int(sess.accumulated))
    }

    /// Returns the current elapsed seconds for the given kid's room timer, or 0 if none.
    func currentElapsedSeconds(for kidID: String) -> Int {
        guard let sess = sessions[kidID] else { return 0 }
        if sess.isPaused { return max(0, Int(sess.accumulated)) }
        if let start = sess.startTime { return max(0, Int(sess.accumulated + Date().timeIntervalSince(start))) }
        return max(0, Int(sess.accumulated))
    }

    // Keep the published pause state in sync with the active kid's session
    private func syncPublishedPauseState() {
        if let kidID = activeKidID, let sess = sessions[kidID] {
            self.isPaused = sess.isPaused
        } else {
            self.isPaused = false
        }
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
}

struct VisitData: Codable {
    var count: Int
    var totalTime: TimeInterval
}
