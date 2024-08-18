import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct PlayerFeature {
    enum Page {
        case text
        case player
        
        var isPlayer: Bool {
            return self == .player
        }
    }
    
    @ObservableState
    struct State: Equatable {
        var book: Book
        @Presents var alert: AlertState<Action.Alert>?
        var playerProgress: PlayerProgressFeature.State
        var playerControl: PlayerControlFeature.State
        
        var currentSpeedIndex: Int = 1
        let audioRates = [0.5, 1.0, 1.5, 2.0]
        
        var currentChapterIndex: Int = 0
        var isEditing = false
        
        var currentPage: Page = .player
                
        internal init(
            book: Book
        ) {
            self.book = book
            self.playerProgress = .init()
            self.playerControl = .init(chapter: book.chapters.first ?? .init())
        }
        
        var currentChapter: Chapter {
            book.chapters[currentChapterIndex]
        }
        
        var audioRate: Double {
            audioRates[currentSpeedIndex]
        }
        
        var isLastChapter: Bool {
            book.chapters.last == currentChapter
        }
        
        var isFirstChapter: Bool {
            book.chapters.first == currentChapter
        }
    }
    
    enum Action {
        case alert(PresentationAction<Alert>)
        case playerProgress(PlayerProgressFeature.Action)
        case playerControl(PlayerControlFeature.Action)
        
        case loadAudio
        case audioLoaded(TaskResult<TimeInterval>)
        case audioDidEnd
        
        case chapterUpdated
        case updateCurrentTime(TimeInterval)
        
        case playAudio
        case pauseAudio
        
        case togglePage
        
        enum Alert: Equatable {
            case togglePageAlert
            case tryLoadAudioAgain
            case dismissPlayer
        }
    }
    
    private enum CancelID {
        case observeAudio
        case observeAudioEnding
        case loadAudio
    }
    
    private enum Constant {
        static let seekForwardSeconds: TimeInterval = 10
        static let seekBackwardSeconds: TimeInterval = -5
        static let clockSecondsStep = 0.1
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.audioPlayer) var audioPlayer
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Scope(state: \.playerControl, action: \.playerControl) {
            PlayerControlFeature()
        }
        Scope(state: \.playerProgress, action: \.playerProgress) {
            PlayerProgressFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .audioDidEnd:
                guard !state.isLastChapter else {
                    return .merge(
                        .run { send in
                            await audioPlayer.pause()
                            await audioPlayer.stopTrackingAudioEnd()
                            await self.dismiss()
                        },
                        .cancel(id: CancelID.observeAudioEnding),
                        .cancel(id: CancelID.observeAudio)
                    )
                }
                
                return .run { send in
                    await send(.playerControl(.nextChapterButtonTapped))
                }
            case .updateCurrentTime(let time):
                state.playerProgress.currentTime = time
                return .none
            case .chapterUpdated:
                state.playerControl.isPreviousChapterButtonDisabled = state.isFirstChapter
                state.playerControl.isNextChapterButtonDisabled = state.isLastChapter
                
                state.playerControl.chapter = state.currentChapter
                
                return .run { send in
                    await send(.pauseAudio)
                    await send(.loadAudio)
                }
            case .loadAudio:
                guard let url = URL(string: state.book.chapters[state.currentChapterIndex].audioUrl) else {
                    return .none
                }
                
                state.playerProgress.isLoading = true
                state.playerControl.isLoading = true
                
                return .run { send in
                    await send(.audioLoaded(
                        TaskResult {
                            try await audioPlayer.loadAudio(url)
                        }
                    ))
                }
                .cancellable(id: CancelID.loadAudio, cancelInFlight: true)
            case .audioLoaded(.success(let duration)):
                state.playerProgress.currentTime = .zero
                state.playerProgress.audioDuration = duration
                
                state.playerControl.isLoading = false
                state.playerProgress.isLoading = false
                let currentSpeed = state.playerProgress.speed
                return .run { send in
                    await audioPlayer.setSpeed(Float(currentSpeed))
                    await send(.playAudio)
                }
            case .audioLoaded(.failure(_)):
                state.playerControl.isLoading = false
                state.playerProgress.isLoading = false
                state.alert = .failedToLoadAudio
                return .none
            case .playAudio:
                state.playerControl.isPlaying = true
                return .merge(
                    .run { _ in
                        await audioPlayer.play()
                    },
                    observePlayback(),
                    observePlaybackFinished()
                )
            case .pauseAudio:
                state.playerControl.isPlaying = false
                return .merge(
                    .run { send in
                        await audioPlayer.pause()
                    },
                    .cancel(id: CancelID.observeAudio)
                )
            case .togglePage:
                state.currentPage = state.currentPage.isPlayer ? .text : .player
                if !state.currentPage.isPlayer {
                    state.alert = .togglePageAlert
                    return .run { send in
                        await send(.pauseAudio)
                    }
                }
                return .none
            case .alert(.presented(.togglePageAlert)):
                return .run { send in
                    await send(.playAudio)
                    await send(.togglePage)
                }
            case .alert(.presented(.tryLoadAudioAgain)):
                return .run { send in
                    await send(.loadAudio)
                }
            case .alert(.presented(.dismissPlayer)):
                state.alert = nil
                return .run { send in
                    await self.dismiss()
                }
            case .alert(.dismiss):
                state.alert = nil
                return .none
                // MARK: - Player Controls Actions
            case .playerControl(let action):
                switch action {
                case .previousChapterButtonTapped:
                    guard !state.isFirstChapter else {
                        return .none
                    }
                    
                    state.currentChapterIndex -= 1
                    return .run { send in
                        await send(.chapterUpdated)
                    }
                case .seekBackward:
                    return .run { _ in
                        await audioPlayer.seekBy(Constant.seekBackwardSeconds)
                    }
                case .togglePlayPause:
                    state.playerControl.isPlaying.toggle()
                    let isPlaying = state.playerControl.isPlaying
                    return .run { send in
                        await send(isPlaying ? .playAudio : .pauseAudio)
                    }
                case .seekForward:
                    return .run { _ in
                        await audioPlayer.seekBy(Constant.seekForwardSeconds)
                    }
                case .nextChapterButtonTapped:
                    guard !state.isLastChapter else {
                        return .none
                    }
                    
                    state.currentChapterIndex += 1
                    return .run { send in
                        await send(.chapterUpdated)
                    }
                }
                // MARK: - Player Progress Actions
            case .playerProgress(let playerProgressAction):
                switch playerProgressAction {
                case .speedButtonTapped:
                    state.currentSpeedIndex = (state.currentSpeedIndex + 1) % state.audioRates.count
                    let newSpeed = Float(state.audioRates[state.currentSpeedIndex])
                    state.playerProgress.speed = CGFloat(newSpeed)
                    return .run { _ in
                        await audioPlayer.setSpeed(newSpeed)
                    }
                case .updateCurrentTime(let time):
                    if state.isEditing {
                        state.playerProgress.draggedTime = time
                    }
                    return .none
                case .editingMode(let isEditing):
                    guard !isEditing, let draggedTime = state.playerProgress.draggedTime else {
                        state.isEditing = isEditing
                        return .none
                    }
                    state.playerProgress.draggedTime = nil
                    let newTime = draggedTime
                    state.playerProgress.currentTime = newTime
                    return .run { _ in
                        await audioPlayer.seekTo(newTime)
                    }
                }
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    private func observePlayback() -> Effect<Action> {
        return .run { send in
            for await _ in  self.clock.timer(interval: .seconds(Constant.clockSecondsStep)) {
                let currentTime = await audioPlayer.currentTime()
                await send(.updateCurrentTime(currentTime))
            }
        }
        .cancellable(id: CancelID.observeAudio)
    }
    
    private func observePlaybackFinished() -> Effect<Action> {
        return .run { send in
            for await _ in await audioPlayer.onPlaybackEnded() {
                await send(.audioDidEnd)
            }
        }
        .cancellable(id: CancelID.observeAudioEnding)
    }
}

extension AlertState where Action == PlayerFeature.Action.Alert {
    static let togglePageAlert = Self {
        TextState("Ohh, no text here:(")
    } actions: {
        ButtonState(action: .togglePageAlert) {
            TextState("Keep listening👍🏻")
        }
    }
    
    static let failedToLoadAudio = Self {
        TextState("Something is wrong here, audio loading failed")
    } actions: {
        ButtonState(role: .cancel, action: .tryLoadAudioAgain) {
            TextState("Try again☺️")
        }
        ButtonState(role: .destructive, action: .dismissPlayer) {
            TextState("Close😭")
        }
    }
}
