import ComposableArchitecture
import Foundation

extension DependencyValues {
    var audioPlayer: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}

struct AudioPlayerClient {
    var loadAudio: (URL) async throws -> TimeInterval
    var play: () async -> Void
    var pause: () async -> Void
    var stop: () async -> Void
    var seekBy: (TimeInterval) async -> Void
    var seekTo: (TimeInterval) async -> Void
    var setSpeed: (Float) async -> Void
    var currentTime: () async -> TimeInterval
    var duration: () async -> TimeInterval
    var onPlaybackEnded: () async -> AsyncStream<Void>
    var stopTrackingAudioEnd: () async -> Void
}

extension AudioPlayerClient: DependencyKey {
    static let liveValue = AudioPlayerClient(
        loadAudio: { url in
            try await AudioPlayerManager.shared.loadAudio(from: url)
        },
        play: {
            await MainActor.run {
                AudioPlayerManager.shared.play()
            }
        },
        pause: {
            await MainActor.run {
                AudioPlayerManager.shared.pause()
            }
        },
        stop: {
            await MainActor.run {
                AudioPlayerManager.shared.stop()
            }
        },
        seekBy: { time in
            await MainActor.run {
                AudioPlayerManager.shared.seek(by: time)
            }
        },
        seekTo: { time in
            await MainActor.run {
                AudioPlayerManager.shared.seek(to: time)
            }
        },
        setSpeed: { speed in
            await MainActor.run {
                AudioPlayerManager.shared.setSpeed(speed)
            }
        },
        currentTime: {
            await MainActor.run {
                AudioPlayerManager.shared.currentTime()
            }
        },
        duration: {
            await MainActor.run {
                AudioPlayerManager.shared.duration()
            }
        },
        onPlaybackEnded: {
            AudioPlayerManager.shared.playbackFinishedStream
        },
        stopTrackingAudioEnd: {
            AudioPlayerManager.shared.stopTrackingFinishedStream()
        }
    )
}
