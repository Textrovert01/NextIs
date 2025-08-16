
import Foundation
import Combine

final class DataController: ObservableObject {
    static let shared = DataController()

    @Published private(set) var kids: [Kid] = []
    @Published private(set) var activeKidID: String? = nil
    @Published private(set) var isPaused: Bool = false

    private let kidsKey = "Kids_v1"
    private let activeKidKey = "active_kid_id"
    private let visitsKey = "visits_by_kid"

    private struct Session {
        var roomName: String
        var startTime: Date?
        var accumulated: TimeInterval
        var isPaused: Bool
    }

    private var sessions: [String: Session] = [:]

    private init() {
        loadKids()
        loadActiveKid()
    }

    // Kid Management
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
        syncPublishedPauseState()
    }

    func clearActiveKid() {
        activeKidID = nil
        UserDefaults.standard.removeObject(forKey: activeKidKey)
        syncPublishedPauseState()
    }

    private func loadKids() {
        if let data = UserDefaults.standard.data(forKey: kidsKey),
           let decoded = try? JSONDecoder().decode([Kid].self, from: data) {
            DispatchQueue.main.async { [weak self] in self?.kids = decoded }
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

    // Visits
    func startRoomVisit(placeName: String) {
        guard let kidID = activeKidID else { return }
        if let sess = sessions[kidID], (sess.startTime != nil || sess.accumulated > 0) { return }
        sessions[kidID] = Session(roomName: placeName, startTime: Date(), accumulated: 0, isPaused: false)
        syncPublishedPauseState()
    }

    func pauseRoomVisit() {
        guard let kidID = activeKidID, var sess = sessions[kidID], !sess.isPaused, let start = sess.startTime else { return }
        sess.accumulated += Date().timeIntervalSince(start)
        sess.startTime = nil
        sess.isPaused = true
        sessions[kidID] = sess
        syncPublishedPauseState()
    }

    func resumeRoomVisit() {
        guard let kidID = activeKidID, var sess = sessions[kidID], sess.isPaused else { return }
        sess.startTime = Date()
        sess.isPaused = false
        sessions[kidID] = sess
        syncPublishedPauseState()
    }

    func cancelRoomVisit() {
        guard let kidID = activeKidID else { return }
        sessions.removeValue(forKey: kidID)
        syncPublishedPauseState()
    }

    func endRoomVisit() {
        guard let kidID = activeKidID, var sess = sessions[kidID] else { syncPublishedPauseState(); return }
        let duration: TimeInterval
        if sess.isPaused {
            duration = sess.accumulated
        } else if let start = sess.startTime {
            duration = sess.accumulated + Date().timeIntervalSince(start)
        } else {
            duration = sess.accumulated
        }

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

        sessions.removeValue(forKey: kidID)
        syncPublishedPauseState()
    }

    func currentRoomName(for kidID: String) -> String? {
        sessions[kidID]?.roomName
    }

    func todaysVisits(for kidID: String) -> [String: VisitData] {
        let visitsByKid = loadVisits()
        let todayKey = todayDateKey()
        return visitsByKid[kidID]?[todayKey] ?? [:]
    }

    func currentElapsedSeconds() -> Int {
        guard let kidID = activeKidID, let sess = sessions[kidID] else { return 0 }
        if sess.isPaused { return max(0, Int(sess.accumulated)) }
        if let start = sess.startTime { return max(0, Int(sess.accumulated + Date().timeIntervalSince(start))) }
        return max(0, Int(sess.accumulated))
    }

    func currentElapsedSeconds(for kidID: String) -> Int {
        guard let sess = sessions[kidID] else { return 0 }
        if sess.isPaused { return max(0, Int(sess.accumulated)) }
        if let start = sess.startTime { return max(0, Int(sess.accumulated + Date().timeIntervalSince(start))) }
        return max(0, Int(sess.accumulated))
    }

    // Storage
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

    private func syncPublishedPauseState() {
        if let kidID = activeKidID, let sess = sessions[kidID] {
            self.isPaused = sess.isPaused
        } else {
            self.isPaused = false
        }
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
}
