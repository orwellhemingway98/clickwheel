import Foundation

enum HubStatus: Equatable {
    case ok
    case permissionDenied(SourceID)
    case error(String)
}

@MainActor
protocol PlayerControlling: AnyObject {
    func playPause()
    func next()
    func previous()
    func adjustVolume(by delta: Int)
}

/// Polls the music apps, decides which one is active and forwards commands to it.
@MainActor
final class PlayerHub: ObservableObject, PlayerControlling {
    @Published private(set) var activeSource: SourceID?
    @Published private(set) var snapshot: PlayerSnapshot?
    @Published private(set) var status: HubStatus = .ok

    /// The most recently issued command, so callers (and tests) can await it.
    private(set) var lastCommand: Task<Void, Never>?

    private let sources: [MusicSource]
    private let settings: AppSettings
    private let worker = DispatchQueue(label: "ClickWheel.PlayerHub")
    private var lastActive: SourceID?
    private var pollTimer: Timer?

    init(sources: [MusicSource], settings: AppSettings) {
        self.sources = sources
        self.settings = settings
    }

    var activeMusicSource: MusicSource? {
        sources.first { $0.id == activeSource }
    }

    func startPolling(interval: TimeInterval = 1.0) {
        stopPolling()
        Task { await refresh() }
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func refresh() async {
        let wanted = candidates()
        let results = await onWorker { () -> [(SourceID, Result<PlayerSnapshot, MusicSourceError>)] in
            wanted.compactMap { source in
                // Never script an app that isn't running: that would launch it.
                guard source.isRunning() else { return nil }
                do {
                    return (source.id, .success(try source.snapshot()))
                } catch let error as MusicSourceError {
                    return (source.id, .failure(error))
                } catch {
                    return (source.id, .failure(.scriptFailed(error.localizedDescription)))
                }
            }
        }
        apply(results)
    }

    func playPause() { command { try $0.playPause() } }
    func next() { command { try $0.next() } }
    func previous() { command { try $0.previous() } }

    func adjustVolume(by delta: Int) {
        guard let current = snapshot?.volume else { return }
        let target = min(100, max(0, current + delta))
        command { try $0.setVolume(target) }
    }

    // MARK: - Private

    private func candidates() -> [MusicSource] {
        switch settings.sourceMode {
        case .auto: return sources
        case .appleMusic: return sources.filter { $0.id == .appleMusic }
        case .spotify: return sources.filter { $0.id == .spotify }
        }
    }

    private func apply(_ results: [(SourceID, Result<PlayerSnapshot, MusicSourceError>)]) {
        var snapshots: [SourceID: PlayerSnapshot] = [:]
        var newStatus = HubStatus.ok
        for (id, result) in results {
            switch result {
            case .success(let snap): snapshots[id] = snap
            case .failure(.permissionDenied): newStatus = .permissionDenied(id)
            case .failure(.notRunning): break
            case .failure(.scriptFailed(let message)):
                if case .ok = newStatus { newStatus = .error(message) }
            }
        }

        let order = SourceID.allCases.filter { snapshots[$0] != nil }
        let playing = order.filter { snapshots[$0]?.state == .playing }
        let chosen: SourceID?
        if let last = lastActive, playing.contains(last) {
            chosen = last
        } else if let first = playing.first {
            chosen = first
        } else if let last = lastActive, order.contains(last) {
            chosen = last
        } else {
            chosen = order.first { snapshots[$0]?.track != nil } ?? order.first
        }

        if chosen != nil { lastActive = chosen }
        activeSource = chosen
        snapshot = chosen.flatMap { snapshots[$0] }
        status = newStatus
    }

    private func command(_ action: @escaping (MusicSource) throws -> Void) {
        guard let source = activeMusicSource else {
            lastCommand = nil
            return
        }
        lastCommand = Task {
            let error = await onWorker { () -> MusicSourceError? in
                do { try action(source); return nil }
                catch let error as MusicSourceError { return error }
                catch { return .scriptFailed(error.localizedDescription) }
            }
            if case .permissionDenied = error { status = .permissionDenied(source.id) }
            await refresh()
        }
    }

    private func onWorker<T>(_ work: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            worker.async { continuation.resume(returning: work()) }
        }
    }
}
