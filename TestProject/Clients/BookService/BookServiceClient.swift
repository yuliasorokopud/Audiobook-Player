import ComposableArchitecture
import Foundation

class BookServiceManager {
    static let shared = BookServiceManager()
    
    func retrieveBooks() throws -> [TheBook] {
        guard let url = Bundle.main.url(forResource: "BooksResponse", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw URLError(.badURL)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Books.self, from: data).books
    }
}

struct BookServiceClient {
    var retrieveBooks: () throws -> [TheBook]
}

extension DependencyValues {
    var bookService: BookServiceClient {
        get { self[BookServiceClient.self] }
        set { self[BookServiceClient.self] = newValue }
    }
}

extension BookServiceClient: DependencyKey {
    static let liveValue = BookServiceClient(
        retrieveBooks: {
            try BookServiceManager.shared.retrieveBooks()
        }
    )
}
