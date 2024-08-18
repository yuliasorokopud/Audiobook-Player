import ComposableArchitecture
import AVFAudio
import Foundation

class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackFinishedSubject: (stream: AsyncStream<Void>, continuation: AsyncStream<Void>.Continuation)?


    private override init() {
        super.init()
    }
    
    func loadAudio(from url: URL) async throws -> TimeInterval {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try await withCheckedThrowingContinuation { continuation in
            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.enableRate = true
                self.audioPlayer?.prepareToPlay()
                continuation.resume(returning: self.audioPlayer?.duration ?? 0)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func createPlaybackFinishedStream() {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        playbackFinishedSubject = (stream, continuation)
    }
    
    func play() {
        audioPlayer?.play()
    }
    
    func pause() {
        audioPlayer?.pause()
    }
    
    func stop() {
        audioPlayer = nil
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
    }
    
    func seek(by interval: TimeInterval) {
        guard let player = audioPlayer else { return }
        let newTime = player.currentTime + interval
        player.currentTime = max(0, min(newTime, player.duration))
    }
    
    func setSpeed(_ speed: Float) {
        audioPlayer?.rate = speed
    }
    
    func currentTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    func duration() -> TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    var playbackFinishedStream: AsyncStream<Void> {
        if playbackFinishedSubject == nil {
            createPlaybackFinishedStream()
        }
        return playbackFinishedSubject!.stream
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playbackFinishedSubject?.continuation.yield()
    }
    
    func stopTrackingFinishedStream() {
        playbackFinishedSubject?.continuation.finish()
        playbackFinishedSubject = nil
    }
}
