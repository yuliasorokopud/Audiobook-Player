import XCTest
import ComposableArchitecture

@testable import TestProject

final class BooksListFeatureTests: XCTestCase {
    @MainActor
    func testLoadBooks() async {
        let store = TestStore(initialState: BooksListFeature.State()) {
            BooksListFeature()
        } withDependencies: {
            $0.bookService.retrieveBooks = { [TheBook.mockBook] }
        }
        
        await store.send(.loadBooks)  {
            $0.books = IdentifiedArrayOf<TheBook>(uniqueElements: [TheBook.mockBook])
        }
    }
    
    @MainActor
    func testLoadBooksError() async {
        let store = TestStore(initialState: BooksListFeature.State()) {
            BooksListFeature()
        } withDependencies: {
            $0.bookService.retrieveBooks = { throw URLError(.badServerResponse) }
        }
        
        await store.send(.loadBooks) {
            $0.destination = .alert(.failedToLoadBooks)
        }
        
        await store.send(.destination(.presented(.alert(.failedToLoadBooksAlert)))) {
            $0.destination = nil
        }
        
        await store.receive(\.loadBooks) {
            $0.destination = .alert(.failedToLoadBooks)
        }
        
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }
    }
    
    @MainActor
    func testBookTapped() async {
        let store = TestStore(initialState: BooksListFeature.State(books: [TheBook.mockBook])) {
            BooksListFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        
        await store.send(.bookTapped(TheBook.mockBook)) {
            $0.destination = .player(
                PlayerFeature.State(
                    book: Book(
                        id: UUID(2),
                        imageUrl: TheBook.mockBook.imageUrl,
                        chapters: IdentifiedArrayOf<Chapter>(uniqueElements: [
                            Chapter(
                                id: UUID(0),
                                audioUrl: TheBook.mockBook.chapters[0].audioUrl,
                                keyPointNumber: TheBook.mockBook.chapters[0].keyPointNumber,
                                description: TheBook.mockBook.chapters[0].description
                            ),
                            Chapter(
                                id: UUID(1),
                                audioUrl: TheBook.mockBook.chapters[1].audioUrl,
                                keyPointNumber: TheBook.mockBook.chapters[1].keyPointNumber,
                                description: TheBook.mockBook.chapters[1].description
                            )
                        ])
                    )
                )
            )
        }
    }
}

extension TheBook {
    static let mockBook = TheBook(
        id: "id",
        imageUrl: "url1",
        chapters: [
            .init(id: "id", audioUrl: "audio1", keyPointNumber: "1", description: "Chapter 1"),
            .init(id: "id", audioUrl: "audio2", keyPointNumber: "2", description: "Chapter 2"),
        ]
    )
}
