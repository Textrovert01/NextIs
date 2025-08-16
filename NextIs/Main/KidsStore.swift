//
//  KidsStore.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import Foundation

final class KidsStore: ObservableObject {
    @Published var kids: [Kid] = [] { didSet { save() } }
    private let storageKey = "Kids_v1"

    init() { load() }

    private func save() {
        do {
            let data = try JSONEncoder().encode(kids)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch { /* ignore */ }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([Kid].self, from: data) {
            kids = decoded
        }
    }

    func addKid(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kids.append(Kid(name: trimmed))
    }

    func deleteKids(at offsets: IndexSet, currentKidID: inout String) {
        let idsToDelete = offsets.map { kids[$0].id }
        kids.remove(atOffsets: offsets)
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