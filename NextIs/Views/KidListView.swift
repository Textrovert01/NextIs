//
//  KidsManagerView.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import SwiftUI

extension Notification.Name {
    static let activeKidChanged = Notification.Name("activeKidChanged")
}

struct KidListView: View {
    @StateObject private var store = KidsStore()
    @AppStorage("CurrentKidID") private var currentKidID: String = "kid_default"
    @State private var newKidName: String = ""
    @State private var kidBeingRenamed: Kid? = nil
    @State private var renameText: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var showKidSwitchAlert: Bool = false
    @State private var blockingKidName: String = ""
    @State private var refreshToken = UUID()
    
    private func refreshView() {
        // Sync with DataController in case active kid changed elsewhere
        if let activeID = DataController.shared.activeKidID {
            currentKidID = activeID
        }
        // Force a visual refresh of the List rows
        refreshToken = UUID()
    }

    private func format(_ seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        return hrs > 0 ? String(format: "%d:%02d:%02d", hrs, mins, secs)
                       : String(format: "%02d:%02d", mins, secs)
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
                        if store.kids.isEmpty {
                            VStack(spacing: 8) {
                                Text("No kids yet").font(.headline)
                                Text("Add a Kid to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            List {
                                Section(footer: Text("Tap a kid to view places visited.").font(.footnote)) {
                                    ForEach(store.kids) { kid in
                                        HStack(spacing: 12) {
                                            Button {
                                                setActiveKid(kid)
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .stroke((currentKidID == kid.id.uuidString) ? Color.accentColor : .secondary, lineWidth: 2)
                                                        .frame(width: 22, height: 22)
                                                    if currentKidID == kid.id.uuidString {
                                                        Circle().frame(width: 10, height: 10)
                                                    }
                                                }
                                                .contentShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel((currentKidID == kid.id.uuidString) ? "Active kid" : "Set active kid")

                                            NavigationLink(destination: KidProfileView(kid: kid)) {
                                                HStack {
                                                    Text(kid.name)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                    if let roomName = DataController.shared.currentRoomName(for: kid.id.uuidString),
                                                       !roomName.isEmpty {
                                                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                                                            let secs = DataController.shared.currentElapsedSeconds(for: kid.id.uuidString)
                                                            Text("\(roomName) · \(format(secs))")
                                                                .font(.subheadline)
                                                                .monospacedDigit()
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                                .truncationMode(.tail)
                                                                .minimumScaleFactor(0.8)
                                                                .layoutPriority(1)
                                                                .accessibilityLabel("\(roomName), elapsed \(format(secs))")
                                                        }
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
                                        if currentKidID == "kid_default" {
                                            DataController.shared.cancelRoomVisit()
                                            DataController.shared.clearActiveKid()
                                        }
                                        NotificationCenter.default.post(name: .activeKidChanged, object: nil, userInfo: ["id": DataController.shared.activeKidID ?? "kid_default"])
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .listStyle(.insetGrouped)
                            .id(refreshToken)
                            .refreshable {
                                refreshView()
                            }
                        }

                        Spacer()

                        // Always-visible add bar
                        HStack(spacing: 10) {
                            TextField("Add kid name", text: $newKidName)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                                .onSubmit { addKid() }
                            Button { addKid() } label: {
                                Image(systemName: "plus.circle.fill").imageScale(.large)
                            }
                            .accessibilityLabel("Add kid")
                        }
                        .padding()
//                        .background(.ultraThinMaterial) // optional: makes it pop over the background
//                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            
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
                    NotificationCenter.default.post(name: .activeKidChanged, object: nil, userInfo: ["id": kid.id.uuidString, "name": kid.name])
                } else if let activeID = DataController.shared.activeKidID {
                    currentKidID = activeID
                    NotificationCenter.default.post(name: .activeKidChanged, object: nil, userInfo: ["id": activeID])
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .activeKidChanged)) { _ in
                refreshView()
            }
        }
    }

    private func setActiveKid(_ kid: Kid) {
        let dc = DataController.shared
        if let activeID = dc.activeKidID,
           let currentRoom = dc.currentRoomName(for: activeID),
           activeID != kid.id.uuidString,
           !currentRoom.isEmpty {
            if let uuid = UUID(uuidString: activeID),
               let blockingKid = store.kids.first(where: { $0.id == uuid }) {
                blockingKidName = blockingKid.name
            } else {
                blockingKidName = "the current kid"
            }
            showKidSwitchAlert = true
            return
        }
        currentKidID = kid.id.uuidString
        dc.activateKid(kid)
        NotificationCenter.default.post(name: .activeKidChanged, object: nil, userInfo: ["id": kid.id.uuidString, "name": kid.name])
        NotificationCenter.default.post(name: .tabReselected, object: nil, userInfo: ["index": 0])
    }

    private func addKid() {
        store.addKid(named: newKidName)
        newKidName = ""
    }
}
extension Optional {
    /// Returns true when the Optional has a value.
    var isSome: Bool { self != nil }
}
