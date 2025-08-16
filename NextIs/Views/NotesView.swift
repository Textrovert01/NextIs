//
//  NotesView.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import SwiftUI

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
        .onAppear { notesText = UserDefaults.standard.string(forKey: storageKey) ?? "" }
        .onDisappear { UserDefaults.standard.set(notesText, forKey: storageKey) }
    }
}