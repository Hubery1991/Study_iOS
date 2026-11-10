import AVFoundation

/// Original tones synthesized on device. Nothing is loaded from a file or the network.
@MainActor
final class ToneBed {
    static let shared = ToneBed()

    enum Cue {
        case ui
        case drop
        case reject
        case clear(chain: Int)
        case rise
        case over
        case record
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var started = false
    private var unavailable = false

    private init() {}

    func play(_ cue: Cue) {
        guard Scorebook.shared.soundEnabled, !unavailable else { return }
        startIfNeeded()
        guard started, let buffer = buffer(for: cue) else { return }
        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }

    private func startIfNeeded() {
        guard !started else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            try engine.start()
            started = true
        } catch {
            unavailable = true
        }
    }

    private func buffer(for cue: Cue) -> AVAudioPCMBuffer? {
        switch cue {
        case .ui:
            return chord([784], seconds: 0.045, gain: 0.10)
        case .drop:
            return chord([392, 523], seconds: 0.09, gain: 0.13)
        case .reject:
            return chord([164], seconds: 0.12, gain: 0.11)
        case .clear(let chain):
            switch chain {
            case ...1:
                return chord([523, 659], seconds: 0.18, gain: 0.14)
            case 2:
                return chord([523, 659, 784], seconds: 0.22, gain: 0.15)
            default:
                return chord([659, 784, 1046], seconds: 0.28, gain: 0.16)
            }
        case .rise:
            return chord([146, 220], seconds: 0.18, gain: 0.10)
        case .over:
            return sweep(from: 440, to: 196, seconds: 0.42, gain: 0.12)
        case .record:
            return chord([523, 659, 784, 1046], seconds: 0.36, gain: 0.15)
        }
    }

    private func chord(_ frequencies: [Double], seconds: Double, gain: Float) -> AVAudioPCMBuffer? {
        render(seconds: seconds) { time in
            let envelope = envelope(time: time, seconds: seconds)
            let mixed = frequencies.reduce(0) { partial, frequency in
                partial + sin(2 * Double.pi * frequency * time)
            }
            return Float(mixed / Double(frequencies.count)) * gain * envelope
        }
    }

    private func sweep(from start: Double, to end: Double, seconds: Double, gain: Float) -> AVAudioPCMBuffer? {
        render(seconds: seconds) { time in
            let progress = min(1, time / seconds)
            let frequency = start + (end - start) * progress
            let envelope = envelope(time: time, seconds: seconds)
            return Float(sin(2 * Double.pi * frequency * time)) * gain * envelope
        }
    }

    private func render(seconds: Double, sample: (Double) -> Float) -> AVAudioPCMBuffer? {
        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(sampleRate * seconds)
        guard frameCount > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = frameCount
        for index in 0..<Int(frameCount) {
            channel[index] = sample(Double(index) / sampleRate)
        }
        return buffer
    }

    private func envelope(time: Double, seconds: Double) -> Float {
        let attack = min(1, time / 0.012)
        let release = max(0, 1 - time / seconds)
        return Float(attack * release * release)
    }
}
