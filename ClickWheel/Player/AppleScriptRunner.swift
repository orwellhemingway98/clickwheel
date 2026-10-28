import AppKit

/// Runs AppleScript source and maps failures to `MusicSourceError`.
/// NSAppleScript isn't thread-safe, so executions are serialized.
enum AppleScriptRunner {
    private static let lock = NSLock()

    static func run(_ source: String) throws -> NSAppleEventDescriptor {
        lock.lock()
        defer { lock.unlock() }
        guard let script = NSAppleScript(source: source) else {
            throw MusicSourceError.scriptFailed("Could not create script")
        }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            switch code {
            case -1743: throw MusicSourceError.permissionDenied
            case -600: throw MusicSourceError.notRunning
            default:
                let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "AppleScript error \(code)"
                throw MusicSourceError.scriptFailed(message)
            }
        }
        return result
    }
}

/// Shared plumbing for the AppleScript-backed sources.
class AppleScriptMusicSource {
    let bundleIdentifier: String
    let appName: String

    init(bundleIdentifier: String, appName: String) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
    }

    func isRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    /// Runs `body` inside `tell application "<app>"`, but only if the app is running,
    /// because telling a closed app launches it.
    @discardableResult
    func tell(_ body: String) throws -> NSAppleEventDescriptor {
        guard isRunning() else { throw MusicSourceError.notRunning }
        return try AppleScriptRunner.run("tell application \"\(appName)\"\n\(body)\nend tell")
    }
}
