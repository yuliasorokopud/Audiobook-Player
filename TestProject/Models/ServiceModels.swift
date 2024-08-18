import Foundation

struct Books: Decodable {
    let books: [TheBook]
}

struct TheBook:  Equatable, Identifiable, Decodable, Sendable {
    let id: String
    let imageUrl: String
    let chapters: [TheChapter]
}

struct TheChapter:  Equatable, Identifiable, Decodable, Sendable {
    let id: String
    let audioUrl: String
    let keyPointNumber: String
    let description: String
}
