import Foundation

/// Routes wheel and keyboard input to the navigator: presses and releases go
/// through the tap/hold recognizer, and a 10 Hz tick drives holds, repeats and
/// on-screen timeouts.
@MainActor
final class WheelInput: ObservableObject {
    private let navigator: Navigator
    private var recognizer = ButtonGestureRecognizer()
    private var timer: Timer?

    init(navigator: Navigator) {
        self.navigator = navigator
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
