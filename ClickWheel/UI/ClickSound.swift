import AVFoundation

/// A short synthesized "tick" for wheel steps: a 4 ms, 2 kHz sine burst
/// with an exponential decay. Generated at launch, so no audio files ship.
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
            for i in 0..<Int(frames) {
                let t = Double(i) / sampleRate
                samples[i] = Float(sin(2 * .pi * 2_000 * t) * exp(-t * 1_200) * 0.35)
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
