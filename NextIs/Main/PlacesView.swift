//
//  Place.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import SwiftUI

private struct Place: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct PlacesView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: 3)

    private let places: [Place] = [
        Place(name: "Farm Room"),
        Place(name: "Fridge"),
        Place(name: "Construction"),
        Place(name: "Dinosaur Room"),
        Place(name: "Grocery Room"),
        Place(name: "Centers"),
        Place(name: "Town Room"),
        Place(name: "Four Seasons"),
        Place(name: "Vehicle Room"),
        Place(name: "Art Center"),
        Place(name: "Blue Room"),
        Place(name: "Ocean Room"),
        Place(name: "Gross Motor"),
        Place(name: "Forest Room"),
        Place(name: "Eating Area"),
        Place(name: "Train Room"),
        Place(name: "Unicorn Room"),
        Place(name: "Picnic Room"),
        Place(name: "Space Room"),
        Place(name: "Circle Time"),
        Place(name: "Speech Therapy"),
        Place(name: "Book Nook"),
        Place(name: "Dollhouse Room"),
        Place(name: "Gym"),
        Place(name: "Bathroom")
    ]

    @State private var path: [Place] = []
    @State private var showActiveRoomAlert: Bool = false
    @State private var activeRoomNameForAlert: String = ""
    @ObservedObject private var data = DataController.shared
    @AppStorage("CurrentKidID") private var currentKidID: String = "kid_default"

    @State private var activeKidTitle: String = "No kid active"

    private func refreshActiveKidTitle() {
        let dc = DataController.shared
        // 1) Prefer DataController.activeKidID
        if let activeID = dc.activeKidID,
           let uuid = UUID(uuidString: activeID) {
            if let kid = dc.kids.first(where: { $0.id == uuid }) {
                activeKidTitle = kid.name
                return
            }
            // Fallback: pull from persistent Kids_v1 in case DataController.kids hasn't populated yet
            if let data = UserDefaults.standard.data(forKey: "Kids_v1"),
               let decoded = try? JSONDecoder().decode([Kid].self, from: data),
               let kid = decoded.first(where: { $0.id == uuid }) {
                activeKidTitle = kid.name
                return
            }
        }
        // 2) Secondary fallback to AppStorage(CurrentKidID)
        if let uuid = UUID(uuidString: currentKidID) {
            if let kid = dc.kids.first(where: { $0.id == uuid }) {
                activeKidTitle = kid.name
                return
            }
            if let data = UserDefaults.standard.data(forKey: "Kids_v1"),
               let decoded = try? JSONDecoder().decode([Kid].self, from: data),
               let kid = decoded.first(where: { $0.id == uuid }) {
                activeKidTitle = kid.name
                return
            }
        }
        // 3) No match
        activeKidTitle = "No kid active"
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PlayfulBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
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
                                            path.append(place)
                                        } else {
                                            activeRoomNameForAlert = currentRoom
                                            showActiveRoomAlert = true
                                        }
                                    } else {
                                        dc.startRoomVisit(placeName: place.name)
                                        path.append(place)
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        if let imageName = placeImageMap[place.name] {
                                            Image(imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 110, height: 110)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else {
                                            Image(systemName: "questionmark.square")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 110, height: 110)
                                                .foregroundColor(.secondary)
                                        }
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
                                    // Disable only if there’s no active kid
                                    return dc.activeKidID == nil
                                }())
                                .opacity({
                                    let dc = DataController.shared
                                    if let kidID = dc.activeKidID {
                                        if let currentRoom = dc.currentRoomName(for: kidID) {
                                            return currentRoom == place.name ? 1.0 : 0.4
                                        } else {
                                            // Kid active but not in a room yet: all icons full opacity
                                            return 1.0
                                        }
                                    }
                                    // Dim when no active kid
                                    return 0.4
                                }())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text(activeKidTitle)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.85)
                            .layoutPriority(0)
                        if activeKidTitle != "No kid active" {
                            Text("Active")
                                .fixedSize(horizontal: true, vertical: false)
                                .layoutPriority(2)
                                .font(.caption2).bold()
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                                .overlay(Capsule().stroke(Color.accentColor, lineWidth: 1))
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { refreshActiveKidTitle() }
            .alert("Finish current room first", isPresented: $showActiveRoomAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You're currently in \(activeRoomNameForAlert). Drop the icon on All Done to finish before switching rooms.")
            }
            .navigationDestination(for: Place.self) { p in
                PlaceScreen(placeName: p.name)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tabReselected)) { note in
            if let index = note.userInfo?["index"] as? Int, index == 0 {
                path.removeAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPlace)) { note in
            guard let placeName = note.userInfo?["placeName"] as? String else { return }
            guard let target = places.first(where: { $0.name == placeName }) else { return }
            let dc = DataController.shared

            if let kidID = dc.activeKidID {
                if let currentRoom = dc.currentRoomName(for: kidID) {
                    if currentRoom == placeName {
                        path.append(target)
                    } else {
                        activeRoomNameForAlert = currentRoom
                        showActiveRoomAlert = true
                    }
                } else {
                    dc.startRoomVisit(placeName: placeName)
                    path.append(target)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .activeKidChanged)) { _ in
            refreshActiveKidTitle()
        }
        .onReceive(data.objectWillChange) { _ in
            // If DataController updates kids/activeKidID, refresh the title.
            refreshActiveKidTitle()
        }
        .onAppear {
            if DataController.shared.activeKidID == nil,
               let id = UUID(uuidString: currentKidID),
               let kid = data.kids.first(where: { $0.id == id }) {
                DataController.shared.activateKid(kid)
            }
        }
    }
}

private struct ViewFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct PlaceScreen: View {
    let placeName: String
    @Environment(\.dismiss) private var dismiss
    @AppStorage("CurrentKidID") private var currentKidID: String = "kid_default"

    @State private var dragOffset: CGSize = .zero
    @State private var iconStartLocation: CGPoint = .zero
    @State private var iconBaseFrame: CGRect = .zero
    @State private var dropFrame: CGRect = .zero

    @State private var isIconVisible: Bool = true
    @State private var showNextIs: Bool = false
    @State private var allDoneScale: CGFloat = 1.0
    @State private var isOverDrop: Bool = false
    @State private var iconScale: CGFloat = 1.0
    @State private var dropConfirmed: Bool = false
    @State private var showArrow: Bool = true

    @State private var elapsedSeconds: Int = 0
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let spaceName = "roomSheetSpace"
    @ObservedObject private var data = DataController.shared

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
        return "No kid active"
    }

    private func format(_ seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        return hrs > 0 ? String(format: "%d:%02d:%02d", hrs, mins, secs)
                       : String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        ZStack {
            PlayfulBackground()
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        if !dropConfirmed {
                            HStack(spacing: 10) {
                                Button(action: {
                                    if data.isPaused { DataController.shared.resumeRoomVisit() }
                                    else { DataController.shared.pauseRoomVisit() }
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

                        Text(placeName)
                            .font(.system(size: 34, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(format(elapsedSeconds))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Elapsed time")
                    }

                    // Insert draggable icon view here
                    if isIconVisible {
                        if let imageName = placeImageMap[placeName], UIImage(named: imageName) != nil {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .scaleEffect(iconScale)
                                .padding(.top)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: ViewFrameKey.self, value: geo.frame(in: .named(spaceName)))
                                    }
                                )
                                .onPreferenceChange(ViewFrameKey.self) { iconBaseFrame = $0 }
                                .offset(dragOffset)
                                .highPriorityGesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if iconStartLocation == .zero { iconStartLocation = value.startLocation }
                                            dragOffset = value.translation
                                            let currentFrame = iconBaseFrame.offsetBy(dx: dragOffset.width, dy: dragOffset.height)
                                            let nowOverDrop = currentFrame.intersects(dropFrame)
                                            if nowOverDrop != isOverDrop {
                                                isOverDrop = nowOverDrop
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    iconScale = isOverDrop ? 0.5 : 1.0
                                                }
                                            }
                                        }
                                        .onEnded { _ in handleDropAttempt() }
                                )
                        } else {
                            Image(systemName: "questionmark.square")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .foregroundColor(.secondary)
                                .scaleEffect(iconScale)
                                .padding(.top)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: ViewFrameKey.self, value: geo.frame(in: .named(spaceName)))
                                    }
                                )
                                .onPreferenceChange(ViewFrameKey.self) { iconBaseFrame = $0 }
                                .offset(dragOffset)
                                .highPriorityGesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if iconStartLocation == .zero { iconStartLocation = value.startLocation }
                                            dragOffset = value.translation
                                            let currentFrame = iconBaseFrame.offsetBy(dx: dragOffset.width, dy: dragOffset.height)
                                            let nowOverDrop = currentFrame.intersects(dropFrame)
                                            if nowOverDrop != isOverDrop {
                                                isOverDrop = nowOverDrop
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    iconScale = isOverDrop ? 0.5 : 1.0
                                                }
                                            }
                                        }
                                        .onEnded { _ in handleDropAttempt() }
                                )
                        }
                    }

                    if showArrow {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.black)
                            .transition(.opacity)
                            .padding(.top, 30)
                    }

                    Group {
                        if UIImage(named: "AllDone") != nil {
                            Image("AllDone")
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: 300, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .scaleEffect(allDoneScale)
                    .zIndex(0)
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.preference(key: ViewFrameKey.self, value: geo.frame(in: .named(spaceName)))
                        }
                    )
                    .onPreferenceChange(ViewFrameKey.self) { dropFrame = $0 }

                    Text(dropConfirmed ? "All Done!" : "All done?")
                        .font(.title)
                        .transition(.opacity)
                }
                .padding(20)

                if showNextIs {
                    Button { dismiss() } label: {
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
                Button {
                    DataController.shared.cancelRoomVisit()
                    dismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .principal) { Text(activeKidName).font(.headline) }
        }
        .onAppear {
            dropConfirmed = false
            elapsedSeconds = DataController.shared.currentElapsedSeconds()
        }
        .onReceive(ticker) { _ in
            guard !dropConfirmed else { return }
            elapsedSeconds = DataController.shared.currentElapsedSeconds()
        }
    }

    private func handleDropAttempt() {
        if isOverDrop {
            withAnimation(.easeInOut(duration: 0.2)) { showArrow = false }
            elapsedSeconds = DataController.shared.currentElapsedSeconds()
            DataController.shared.endRoomVisit()
            dropConfirmed = true
            withAnimation(.easeInOut(duration: 0.15)) { iconScale = 0.75 }
            withAnimation(.easeInOut(duration: 0.2)) { isIconVisible = false }
            withAnimation(.easeInOut(duration: 0.35)) { allDoneScale = 1.15 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { allDoneScale = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeInOut) { showNextIs = true }
                }
            }
        } else {
            dropConfirmed = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = .zero
                iconScale = 1.0
            }
        }
    }
}

