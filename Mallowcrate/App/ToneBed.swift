import AVFoundation
import Foundation

/// Short original tones. No audio files, no network.
final class ToneBed {
    static let shared = ToneBed()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat?
    private var ready = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        if let format {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0.85
        }
    }

    func step() { note(frequency: 620, duration: 0.07, volume: 0.18) }
    func push() { note(frequency: 196, duration: 0.09, volume: 0.22, harmonic: 0.35) }
    func goal() { notes([(784, 0.08), (1046, 0.12)]) }
    func blocked() { note(frequency: 140, duration: 0.08, volume: 0.16) }
    func undo() { notes([(520, 0.06), (360, 0.08)]) }
    func win() { notes([(523, 0.1), (659, 0.1), (784, 0.1), (1046, 0.22)]) }
    func tap() { note(frequency: 740, duration: 0.05, volume: 0.12) }

    private func note(frequency: Double, duration: Double, volume: Float, harmonic: Float = 0.18) {
        notes([(frequency, duration)], volume: volume, harmonic: harmonic)
    }

    private func notes(_ sequence: [(Double, Double)], volume: Float = 0.2, harmonic: Float = 0.18) {
        guard begin() else { return }
        for (frequency, duration) in sequence {
            guard let buffer = buffer(frequency: frequency, duration: duration, volume: volume, harmonic: harmonic) else { continue }
            player.scheduleBuffer(buffer)
        }
        if !player.isPlaying {
            player.play()
        }
    }

    private func begin() -> Bool {
        if ready { return true }
        guard format != nil else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            ready = true
            return true
        } catch {
            return false
        }
    }

    private func buffer(frequency: Double, duration: Double, volume: Float, harmonic: Float) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let frames = max(1, Int(format.sampleRate * duration))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
              let samples = buffer.floatChannelData else { return nil }
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = samples[0]
        let attack = min(0.012, duration * 0.25)
        for index in 0..<frames {
            let time = Double(index) / format.sampleRate
            let envelope: Float
            if time < attack {
                envelope = Float(time / attack)
            } else {
                let rest = max(0.0001, duration - attack)
                envelope = Float(max(0, 1 - (time - attack) / rest))
            }
            let phase = 2 * Double.pi * frequency * time
            let voice = sin(phase) + Double(harmonic) * sin(phase * 2)
            data[index] = Float(voice) * volume * envelope
        }
        return buffer
    }
}
