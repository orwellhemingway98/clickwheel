import AVFoundation

/// The clicker: a 4 ms, 1 kHz tick like the 5G's piezo (about four cycles of a
/// softened square wave). Generated at launch, so no audio files ship.
/// The audio engine only runs while clicking: a running output keeps the
/// audio device busy and can stop the Mac from sleeping.
final class ClickSound {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffer: AVAudioPCMBuffer?
    private var idleStop: DispatchWorkItem?

    init() {
        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frames = AVAudioFrameCount(sampleRate * 0.004)
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)
        if let buffer, let samples = buffer.floatChannelData?[0] {
            buffer.frameLength = frames
            let ramp = sampleRate * 0.0005  // 0.5 ms attack and release
            for i in 0..<Int(frames) {
                let t = Double(i) / sampleRate
                // Square-ish: a sine pushed through tanh keeps the edges soft.
                let wave = tanh(4 * sin(2 * .pi * 1_000 * t))
                let envelope = min(1, Double(i) / ramp, Double(Int(frames) - i) / ramp)
                samples[i] = Float(wave * envelope * 0.3)
            }
        }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play() {
        guard let buffer else { return }
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
        scheduleIdleStop()
    }

    private func scheduleIdleStop() {
        idleStop?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.player.stop()
            self?.engine.stop()
        }
        idleStop = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }
}
