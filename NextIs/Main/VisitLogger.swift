//
//  DailyVisits.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//


import Foundation

struct DailyVisits: Codable {
    var dateKey: String
    var placeCounts: [String: Int]
}


import SwiftUI

extension View {
    func popToKidListViewHandler() -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .popToKidListView)) { _ in
            UIApplication.shared.sendAction(#selector(UINavigationController.popToRootViewController(animated:)), to: nil, from: nil, for: nil)
        }
    }
}

struct KidVisitBook: Codable {
    var days: [String: DailyVisits] = [:]
}

final class VisitLogger {
    static let shared = VisitLogger()
    private init() {}

    private let storageKey = "KidVisitLogs_v1"
    private var cache: [String: KidVisitBook] = [:]

    private func ensureLoaded() {
        if !cache.isEmpty { return }
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do { cache = try JSONDecoder().decode([String: KidVisitBook].self, from: data) }
            catch { cache = [:] }
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(cache)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch { }
    }

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

    func todaysPlaces(for kidID: String) -> [String] {
        ensureLoaded()
        let key = todayKey()
        return Array(cache[kidID]?.days[key]?.placeCounts.keys ?? [:].keys)
    }

    func todaysCounts(for kidID: String) -> [String: Int] {
        ensureLoaded()
        let key = todayKey()
        return cache[kidID]?.days[key]?.placeCounts ?? [:]
    }

    func places(for kidID: String, on dateKey: String) -> [String] {
        ensureLoaded()
        return Array(cache[kidID]?.days[dateKey]?.placeCounts.keys ?? [:].keys)
    }

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
