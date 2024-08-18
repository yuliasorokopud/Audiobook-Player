import ComposableArchitecture
import SwiftUI

@Reducer
struct BooksListFeature {
    @ObservableState
    struct State: Equatable {
        var books: IdentifiedArrayOf<TheBook> = []
        @Presents var destination: Destination.State?
    }
    
    @Reducer(state: .equatable)
    enum Destination {
        case player(PlayerFeature)
        case alert(AlertState<BooksListFeature.Action.Alert>)
    }
    
    enum Action {
        case loadBooks
        case destination(PresentationAction<Destination.Action>)
        case bookTapped(TheBook)
        
        enum Alert: Equatable {
            case failedToLoadBooksAlert
        }
    }
    
    @Dependency(\.bookService) var bookService
    @Dependency(\.uuid) var uuid
    
    var body: some ReducerOf<BooksListFeature> {
        Reduce { state, action in
            switch action {
            case .loadBooks:
                do {
                    let books = try bookService.retrieveBooks()
                    state.books = IdentifiedArrayOf<TheBook>(uniqueElements: books)
                } catch {
                    state.destination = .alert(.failedToLoadBooks)
                }
                return .none
            case .bookTapped(let book):
                state.destination = createPlayerState(for: book)
                return .none
            case .destination(.presented(.alert(let action))):
                switch action {
                case .failedToLoadBooksAlert:
                    return .run { send in
                        await send(.loadBooks)
                    }
                }
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    private func createPlayerState(for book: TheBook) -> BooksListFeature.Destination.State {
        let chapters = book.chapters.map { chapter in
            Chapter(
                id: self.uuid(),
                audioUrl: chapter.audioUrl,
                keyPointNumber: chapter.keyPointNumber,
                description: chapter.description
            )
        }
        
        let bookNew = Book(
            id: self.uuid(),
            imageUrl: book.imageUrl,
            chapters: IdentifiedArrayOf<Chapter>(uniqueElements: chapters)
        )
        let playerState = PlayerFeature.State(
            book: bookNew
        )
        return .player(playerState)
    }
}

extension AlertState where Action == BooksListFeature.Action.Alert {
    static let failedToLoadBooks = Self {
        TextState("Something is wrong here, book loading failed")
    } actions: {
        ButtonState(action: .failedToLoadBooksAlert) {
            TextState("Retry🥹")
        }
    }
}

