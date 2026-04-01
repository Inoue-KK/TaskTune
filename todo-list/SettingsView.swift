//
//  SettingsView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/04/01.
//

import SwiftUI
import AVFoundation

enum CompletionSound: String, CaseIterable {
    case bubble, boing, levelUp, sparkle, click, clack, fanfare

    var label: String {
        switch self {
        case .bubble:  return "Bubble"
        case .boing:   return "Boing"
        case .levelUp: return "Level Up"
        case .sparkle: return "Sparkle"
        case .click:   return "Click"
        case .clack:   return "Clack"
        case .fanfare: return "Fanfare"
        }
    }

    var description: String {
        switch self {
        case .bubble:  return "Soap bubble pop"
        case .boing:   return "Springy bounce"
        case .levelUp: return "3-note victory"
        case .sparkle: return "Glittery shimmer"
        case .click:   return "Mechanical click"
        case .clack:   return "Deep click"
        case .fanfare: return "Big celebration"
        }
    }
}

// MARK: - Sound Player

private let sharedSoundPlayer = SoundPlayer()

func playSound(_ sound: CompletionSound) {
    sharedSoundPlayer.play(sound)
}

private class SoundPlayer {
    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? engine.start()
    }

    func play(_ sound: CompletionSound) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = makeBuffer(for: sound, format: format) else { return }
        if !engine.isRunning { try? engine.start() }
        node.stop()
        node.scheduleBuffer(buffer)
        node.play()
    }

    private struct Note {
        var freqStart: Double
        var freqEnd: Double
        var duration: Double
        var decay: Double
        var gap: Double = 0
        var volume: Double = 1.0
    }

    private func notes(for sound: CompletionSound) -> [Note] {
        switch sound {
        case .bubble: return [Note(freqStart: 300,  freqEnd: 1000, duration: 0.10, decay: 20)]
        case .boing: return [
            Note(freqStart: 784,  freqEnd: 784,  duration: 0.09, decay: 22, gap: 0.03),
            Note(freqStart: 1319, freqEnd: 1319, duration: 0.30, decay: 8, volume: 0.3)
        ]
        case .levelUp: return [
            Note(freqStart: 523,  freqEnd: 523,  duration: 0.08, decay: 25, gap: 0.02),
            Note(freqStart: 659,  freqEnd: 659,  duration: 0.08, decay: 25, gap: 0.02),
            Note(freqStart: 784,  freqEnd: 784,  duration: 0.20, decay: 10, volume: 0.6)
        ]
        case .sparkle: return [
            Note(freqStart: 1568, freqEnd: 1568, duration: 0.05, decay: 40, gap: 0.02),
            Note(freqStart: 1760, freqEnd: 1760, duration: 0.05, decay: 40, gap: 0.02),
            Note(freqStart: 1976, freqEnd: 1976, duration: 0.05, decay: 40, gap: 0.02),
            Note(freqStart: 2093, freqEnd: 2093, duration: 0.12, decay: 20)
        ]
        case .click: return [
            Note(freqStart: 1200, freqEnd: 1200, duration: 0.03, decay: 180, gap: 0.1),
            Note(freqStart: 3000, freqEnd: 3000, duration: 0.01, decay: 200, volume: 0.1)
        ]
        case .clack: return [
            Note(freqStart: 600, freqEnd: 600, duration: 0.02, decay: 150, gap: 0.05),
            Note(freqStart: 1400,  freqEnd: 1400,  duration: 0.04, decay: 120, volume: 0.3)
        ]
        case .fanfare: return [
            Note(freqStart: 523,  freqEnd: 523,  duration: 0.07, decay: 20, gap: 0.01),
            Note(freqStart: 659,  freqEnd: 659,  duration: 0.07, decay: 20, gap: 0.01),
            Note(freqStart: 784,  freqEnd: 784,  duration: 0.07, decay: 20, gap: 0.01),
            Note(freqStart: 1047, freqEnd: 1047, duration: 0.07, decay: 20, gap: 0.01),
            Note(freqStart: 1319, freqEnd: 1319, duration: 0.30, decay: 7)
        ]
        }
    }

    private func makeBuffer(for sound: CompletionSound, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let noteList = notes(for: sound)
        let noteLengths = noteList.map { (frames: Int($0.duration * sampleRate), gap: Int($0.gap * sampleRate)) }
        let totalFrames = AVAudioFrameCount(noteLengths.reduce(0) { $0 + $1.frames + $1.gap })
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return nil }
        buffer.frameLength = totalFrames
        let data = buffer.floatChannelData![0]

        var offset = 0
        for (note, length) in zip(noteList, noteLengths) {
            var phase = 0.0
            for i in 0..<length.frames {
                let t = Double(i) / sampleRate
                let progress = t / note.duration
                let freq = note.freqStart + (note.freqEnd - note.freqStart) * progress
                phase += 2 * .pi * freq / sampleRate
                data[offset + i] = Float(sin(phase) * exp(-t * note.decay) * 0.5 * note.volume)
            }
            offset += length.frames + length.gap
        }
        return buffer
    }
}

// MARK: - Views

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("selectedSound") private var selectedSoundRaw = CompletionSound.bubble.rawValue

    var body: some View {
        Form {
            Section {
                Toggle("Sound", isOn: $soundEnabled)
                if soundEnabled {
                    NavigationLink {
                        SoundPickerView(selectedSoundRaw: $selectedSoundRaw)
                    } label: {
                        LabeledContent("Sound Effect") {
                            Text(CompletionSound(rawValue: selectedSoundRaw)?.label ?? "Bubble")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
            }

            Section("Widget") {
                NavigationLink("Widget Themes") {
                    WidgetThemeListView()
                }
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SoundPickerView: View {
    @Binding var selectedSoundRaw: String

    var body: some View {
        List(CompletionSound.allCases, id: \.rawValue) { sound in
            Button {
                selectedSoundRaw = sound.rawValue
                playSound(sound)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sound.label)
                            .foregroundStyle(.primary)
                        Text(sound.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedSoundRaw == sound.rawValue {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .navigationTitle("Sound Effect")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
