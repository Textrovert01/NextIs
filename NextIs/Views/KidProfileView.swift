//
//  KidProfileView.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import SwiftUI

struct KidProfileView: View {
    let kid: Kid

    private var todaysVisits: [String: VisitData] {
        DataController.shared.todaysVisits(for: kid.id.uuidString)
    }

    var body: some View {
        ZStack {
            PlayfulBackground()
            VStack(spacing: 8) {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let roomName = DataController.shared.currentRoomName(for: kid.id.uuidString) ?? ""
                    let secs = DataController.shared.currentElapsedSeconds(for: kid.id.uuidString)
                    if !roomName.isEmpty {
                        Button {
                            NotificationCenter.default.post(name: .tabReselected, object: nil, userInfo: ["index": 0])
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .navigateToPlace, object: nil, userInfo: ["placeName": roomName])
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
                            Text("No visits yet today").font(.headline)
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
        .popToKidListViewHandler()
        .navigationTitle(kid.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func format(_ seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        return hrs > 0 ? String(format: "%d:%02d:%02d", hrs, mins, secs)
                       : String(format: "%02d:%02d", mins, secs)
    }
}
