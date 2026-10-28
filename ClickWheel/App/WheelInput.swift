import CoreGraphics
import Foundation

/// Routes wheel and keyboard input to the navigator: presses and releases go
/// through the tap/hold recognizer, and a 10 Hz tick drives holds, repeats and
/// on-screen timeouts.
@MainActor
final class WheelInput: ObservableObject {
    private let navigator: Navigator
    private var recognizer = ButtonGestureRecognizer()
    private var trackpad = TrackpadWheel()
    /// Degrees of two-finger rotation per step: the current model's wheel step.
    private let degreesPerStep: () -> Double
    private var timer: Timer?

    init(navigator: Navigator, degreesPerStep: @escaping () -> Double = { 15 }) {
        self.navigator = navigator
        self.degreesPerStep = degreesPerStep
    }

    /// Two-finger rotation on the trackpad turns the wheel.
    func rotate(degrees: Double) {
        let steps = trackpad.rotate(degrees: degrees, degreesPerStep: degreesPerStep())
        if steps != 0 { scroll(steps) }
    }

    /// Two-finger swipes and mouse wheels scroll like the wheel.
    func scrollWheel(deltaY: CGFloat, precise: Bool, momentum: Bool) {
        let steps = trackpad.scroll(deltaY: deltaY, precise: precise, momentum: momentum)
        if steps != 0 { scroll(steps) }
    }

    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    func press(_ button: WheelButton) { send(recognizer.press(button, now: now)) }
    func release(_ button: WheelButton) { send(recognizer.release(button, now: now)) }
    func cancel() { send(recognizer.cancel()) }
    func scroll(_ steps: Int) { navigator.handle(.scroll(steps: steps)) }

    func handle(_ key: KeyInput) {
        switch key {
        case .scroll(let steps): scroll(steps)
        case .press(let button): press(button)
        case .release(let button): release(button)
        }
    }

    func startTicking() {
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        let time = now
        send(recognizer.poll(now: time))
        navigator.handle(.tick(now: time))
    }

    private func send(_ events: [WheelEvent]) {
        events.forEach(navigator.handle)
    }
}
