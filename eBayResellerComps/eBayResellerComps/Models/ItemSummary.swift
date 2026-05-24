import Foundation

struct ItemSummary: Codable, Identifiable {
    let itemId: String
    let title: String
    let price: Price
    let condition: String?

    struct Price: Codable {
        let value: String
        let currency: String
    }

    var id: String { itemId }
}
