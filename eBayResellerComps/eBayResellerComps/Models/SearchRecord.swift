import Foundation

struct SearchRecord: Codable, Identifiable {
    var id: UUID
    var query: String
    var timestamp: Date
    var imageThumbData: Data?
}
