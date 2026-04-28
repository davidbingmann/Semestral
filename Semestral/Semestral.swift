import SwiftUI
import SwiftData

@main
struct SemestralApp: App {
    let container: ModelContainer

    init() {
        let storeURL = SemestralApp.storeURL()
        SemestralApp.migrateLegacyStoreIfNeeded(to: storeURL)
        SemestralApp.snapshotStoreIfNeeded(at: storeURL)
        do {
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(
                for: Semester.self, Module.self, KanbanTask.self, Grade.self, Exam.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // App-private store path. With App Sandbox enabled this resolves under
    // ~/Library/Containers/com.davidbingmann.KanbanApp/Data/...; the
    // "Semestral" subfolder also keeps an unsandboxed build out of the
    // shared ~/Library/Application Support/default.store path that other
    // unsandboxed apps (e.g. iCloudMailAgent) write to.
    static func storeURL() -> URL {
        let dir = URL.applicationSupportDirectory.appending(path: "Semestral", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "default.store")
    }

    // One-time copy from the pre-sandbox app-private path
    // (~/Library/Application Support/Semestral/default.store) into the
    // sandboxed location, when this build first runs on a machine that
    // had data under the previous fix. Skipped once the sandboxed store
    // exists. The shared ~/Library/Application Support/default.store is
    // intentionally NOT migrated: it can hold a foreign app's data
    // under a different schema (e.g. iCloudMailAgent), which SwiftData's
    // lightweight migration would silently rewrite.
    //
    // Read access for the legacy path is granted by the
    // `com.apple.security.temporary-exception.files.home-relative-path.read-write`
    // entitlement, which is honored for both Developer ID and ad-hoc
    // (`-`) local signing. Verified end-to-end with a fingerprinted file.
    private static func migrateLegacyStoreIfNeeded(to storeURL: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: storeURL.path) else { return }

        // Inside a sandboxed app NSHomeDirectory() points at the container,
        // not the user's real home; getpwuid(getuid()) returns the latter.
        let realHome: URL = {
            if let pw = getpwuid(getuid()), let cstr = pw.pointee.pw_dir {
                return URL(fileURLWithPath: String(cString: cstr))
            }
            return URL(fileURLWithPath: NSHomeDirectory())
        }()
        let legacyStoreURL = realHome
            .appending(path: "Library/Application Support/Semestral/default.store")
        guard fm.fileExists(atPath: legacyStoreURL.path) else { return }

        try? fm.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        for suffix in ["", "-shm", "-wal"] {
            let src = URL(fileURLWithPath: legacyStoreURL.path + suffix)
            guard fm.fileExists(atPath: src.path) else { continue }
            let dst = URL(fileURLWithPath: storeURL.path + suffix)
            try? fm.copyItem(at: src, to: dst)
        }
    }

    // Copies default.store + WAL siblings into Backups/<yyyy-MM-dd>/ once a
    // day, keeping the last 7. Runs before ModelContainer opens, so the
    // snapshot is consistent. Survives schema-migration mistakes that an
    // empty-store sandbox cannot.
    private static func snapshotStoreIfNeeded(at storeURL: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: storeURL.path) else { return }

        let lastKey = "lastBackupAt"
        let last = UserDefaults.standard.object(forKey: lastKey) as? Date ?? .distantPast
        let now = Date()
        guard now.timeIntervalSince(last) > 86_400 else { return }

        let backupsDir = storeURL.deletingLastPathComponent()
            .appending(path: "Backups", directoryHint: .isDirectory)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let snapshotDir = backupsDir.appending(path: dayFormatter.string(from: now), directoryHint: .isDirectory)
        try? fm.createDirectory(at: snapshotDir, withIntermediateDirectories: true)

        for suffix in ["", "-shm", "-wal"] {
            let src = URL(fileURLWithPath: storeURL.path + suffix)
            guard fm.fileExists(atPath: src.path) else { continue }
            let dst = snapshotDir.appending(path: "default.store" + suffix)
            try? fm.removeItem(at: dst)
            try? fm.copyItem(at: src, to: dst)
        }

        if let entries = try? fm.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) {
            let sorted = entries.sorted { lhs, rhs in
                let l = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let r = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return l > r
            }
            for old in sorted.dropFirst(7) {
                try? fm.removeItem(at: old)
            }
        }

        UserDefaults.standard.set(now, forKey: lastKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
