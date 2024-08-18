import ComposableArchitecture
import XCTest

@testable import TestProject

final class PlayerFeatureTests: XCTestCase {
    @MainActor
    func testLoadAudioHappyPath() async {
        let (store, clock, yield) = makeTestStore(initialState: .init(book: .mock))
        
        let loadAudioTask = await store.send(.loadAudio) {
            $0.playerProgress.isLoading = true
            $0.playerControl.isLoading = true
        }
        
        await store.receive(\.audioLoaded.success) {
            $0.playerProgress = .init(currentTime: 0, audioDuration: 0.2)
            $0.playerControl.isLoading = false
        }
        
        await store.receive(\.playAudio) {
            $0.playerControl.isPlaying = true
        }
        await clock.advance(by: .seconds(0.1))
        await store.receive(\.updateCurrentTime)
        
        yield()
        await store.receive(\.audioDidEnd)
        
        await loadAudioTask.cancel()
    }
    
    @MainActor
    func testLoadAudioFailure() async {
        let dismissed = self.expectation(description: "dismissed")
        let store = TestStore(initialState: PlayerFeature.State(book: .mock)) {
            PlayerFeature()
        } withDependencies: {
            $0.audioPlayer.loadAudio = { _ in throw NSError(domain: "Test", code: 0) }
            $0.dismiss = DismissEffect { dismissed.fulfill() }
        }
        store.exhaustivity = .off
        await store.send(.loadAudio) {
            $0.playerControl.isLoading = true
            $0.playerProgress.isLoading = true
        }
        
        await store.receive(\.audioLoaded.failure) {
            $0.playerControl.isLoading = false
            $0.playerProgress.isLoading = false
            $0.alert = .failedToLoadAudio
        }
        
        await store.send(.alert(.presented(.tryLoadAudioAgain))) {
            $0.alert = nil
        }
        
        await store.receive(\.loadAudio)
        await store.receive(\.audioLoaded.failure)
        
        await store.send(.alert(.presented(.dismissPlayer))) {
            $0.alert = nil
        }
        await self.fulfillment(of: [dismissed], timeout: 0)
    }
    
    @MainActor
    func testAudioDidEnd() async {
        let (store, _, _) = makeTestStore(initialState: .init(book: .mockWithMultipleChapters))
        
        let task1 = await store.send(.playAudio) {
            $0.playerControl.isPlaying = true
        }
        let task2 = await store.send(.audioDidEnd)
        await store.receive(/.playerControl(.previousChapterButtonTapped)) {
            $0.currentChapterIndex = 1
        }
        await assertChapterChange(store: store, expectedIndex: 1)
        
        await task1.cancel()
        await task2.cancel()
    }
    
    @MainActor
    func testAudioDidEndLastChapter() async {
        let dismissed = self.expectation(description: "dismissed")
        let (store, _, _) = makeTestStore(initialState: .init(book: .mock))
        store.dependencies.dismiss = DismissEffect { dismissed.fulfill() }
        
        await store.send(.audioDidEnd)
        
        await self.fulfillment(of: [dismissed], timeout: 0)
    }
    
    @MainActor
    func testChapterNavigation() async {
        let (store, _, _) = makeTestStore(initialState: .init(book: .mockWithMultipleChapters))
        
        await store.send(\.playAudio) {
            $0.playerControl.isPlaying = true
        }
        
        // next chapter
        await store.send(.playerControl(.nextChapterButtonTapped)) {
            $0.currentChapterIndex = 1
        }.cancel()
        await assertChapterChange(store: store, expectedIndex: 1)
        
        // previous chapter
        await store.send(.playerControl(.previousChapterButtonTapped)) {
            $0.currentChapterIndex = 0
        }.cancel()
        await assertChapterChange(store: store, expectedIndex: 0)
    }
    
    @MainActor
    func testChangePlaybackSpeed() async {
        let (store, _, _) = makeTestStore()
        
        await store.send(.playerProgress(.speedButtonTapped)) {
            $0.currentSpeedIndex = 2
            $0.playerProgress.speed = 1.5
        }
    }
    
    @MainActor
    func testToggleBetweenPlayerAndTextView() async {
        let (store, _, _) = makeTestStore()
        
        await store.send(.togglePage) {
            $0.currentPage = .text
            $0.alert = .togglePageAlert
        }
        
        await store.receive(\.pauseAudio)
        
        await store.send(.alert(.presented(.togglePageAlert))) {
            $0.alert = nil
        }.cancel()
        
        await store.receive(\.playAudio) {
            $0.playerControl.isPlaying = true
        }
        
        await store.receive(\.togglePage) {
            $0.currentPage = .player
        }
    }
    
    @MainActor
    func testDragProgressSlider() async {
        let (store, _, _) = makeTestStore()
        
        await store.send(.playerProgress(.editingMode(true))) {
            $0.isEditing = true
        }
        
        await store.send(.playerProgress(.updateCurrentTime(30))) {
            $0.playerProgress.draggedTime = 30
        }
        
        await store.send(.playerProgress(.editingMode(false))) {
            $0.playerProgress.draggedTime = nil
            $0.playerProgress.currentTime = 30
        }
    }
    
}

extension PlayerFeatureTests {
    func makeTestStore(initialState: PlayerFeature.State = .init(book: .mock)) -> (
        store: TestStore<PlayerFeature.State, PlayerFeature.Action>,
        clock: TestClock<Duration>,
        yield: () -> Void
    ) {
        let clock = TestClock<Duration>()
        var continuation: AsyncStream<Void>.Continuation!
        let stream = AsyncStream<Void> { continuation = $0 }
        
        let store = TestStore(initialState: initialState) {
            PlayerFeature()
        } withDependencies: {
            $0.audioPlayer.loadAudio = { _ in return 0.2 }
            $0.audioPlayer.play = {}
            $0.audioPlayer.pause = {}
            $0.audioPlayer.currentTime = { 0 }
            $0.audioPlayer.onPlaybackEnded = { stream }
            $0.continuousClock = clock
        }
        
        return (store, clock, { continuation.yield(()) })
    }
    
    func assertChapterChange(store: TestStore<PlayerFeature.State, PlayerFeature.Action>, expectedIndex: Int) async {
        await store.receive(\.chapterUpdated) {
            $0.playerControl.isPreviousChapterButtonDisabled = expectedIndex == 0
            $0.playerControl.isNextChapterButtonDisabled = expectedIndex == $0.book.chapters.count - 1
            $0.playerControl.chapter = $0.book.chapters[expectedIndex]
        }
        await store.receive(\.pauseAudio) {
            $0.playerControl.isPlaying = false
        }
        await store.receive(\.loadAudio) {
            $0.playerProgress.isLoading = true
            $0.playerControl.isLoading = true
        }
        await store.receive(\.audioLoaded.success) {
            $0.playerProgress = .init(currentTime: 0, audioDuration: 0.2)
            $0.playerProgress.isLoading = false
            $0.playerControl.isLoading = false
        }
        await store.receive(\.playAudio) {
            $0.playerControl.isPlaying = true
        }
    }
}

// MARK: - Mock Extensions

extension Book {
    static let mock = Book(
        id: UUID(),
        imageUrl: "https://example.com/book.jpg",
        chapters: IdentifiedArrayOf<Chapter>(uniqueElements: [.mock])
    )
    
    static let mockWithMultipleChapters = Book(
        id: UUID(),
        imageUrl: "https://example.com/book.jpg",
        chapters: IdentifiedArrayOf<Chapter>(uniqueElements: [
            .init(id: UUID(), audioUrl: "https://example.com/chapter1.mp3", keyPointNumber: "1", description: "Chapter 1"),
            .init(id: UUID(), audioUrl: "https://example.com/chapter2.mp3", keyPointNumber: "2", description: "Chapter 2")
        ])
    )
}

extension Chapter {
    static let mock = Chapter(
        id: UUID(),
        audioUrl: "https://example.com/chapter1.mp3",
        keyPointNumber: "1",
        description: "Test Chapter"
    )
}
