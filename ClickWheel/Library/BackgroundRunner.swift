import Foundation

/// Runs blocking work (AppleScript) on a serial background queue and awaits the result.
final class BackgroundRunner {
    private let queue: DispatchQueue

    init(label: String) {
        queue = DispatchQueue(label: label)
    }

    func run<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { continuation.resume(with: Result { try work() }) }
        }
    }
}
