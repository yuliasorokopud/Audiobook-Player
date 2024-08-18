import Foundation
import IdentifiedCollections
import SwiftUI

struct Book: Equatable, Identifiable, Sendable {
    let id: UUID
    var imageUrl: String = ""
    var chapters: IdentifiedArrayOf<Chapter> = []
}

struct Chapter: Equatable, Identifiable {
    var id = UUID()
    var audioUrl: String = ""
    var keyPointNumber: String = ""
    var description: String = ""
}
