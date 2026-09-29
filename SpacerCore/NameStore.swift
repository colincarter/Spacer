import Foundation

/// Custom desktop names keyed by desktop id, persisted in UserDefaults.
public final class NameStore {
    public static let retention: TimeInterval = 30 * 24 * 60 * 60

    private struct Entry: Codable {
        var name: String
        var lastSeen: Date
    }

    private static let key = "desktopNames"
    private let defaults: UserDefaults
    private let now: () -> Date
    private var entries: [String: Entry]

    public init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) {
            entries = decoded
        } else {
            entries = [:]
        }
    }

    public func name(for id: String) -> String? {
        entries[id]?.name
    }

    /// Stores the name exactly as typed; whitespace-only removes it.
    public func setName(_ name: String, for id: String) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            entries[id] = nil
        } else {
            entries[id] = Entry(name: name, lastSeen: now())
        }
        save()
    }

    /// Refreshes the given ids and prunes entries not seen within `retention`.
    public func markSeen(_ ids: [String]) {
        let current = now()
        for id in ids where entries[id] != nil {
            entries[id]?.lastSeen = current
        }
        entries = entries.filter { current.timeIntervalSince($0.value.lastSeen) <= Self.retention }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
