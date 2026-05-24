import Foundation

final class EBayBrowseService {
    static let shared = EBayBrowseService()

    private let authService = EBayAuthService.shared
    private let baseURL = "https://api.ebay.com/buy/browse/v1/item_summary"

    // Returns the top-ranked item title from a visual search.
    func searchByImage(imageData: Data) async throws -> String {
        let token = try await authService.validToken()

        guard let url = URL(string: "\(baseURL)/search_by_image") else {
            throw BrowseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = SearchByImageRequest(image: imageData.base64EncodedString())
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BrowseError.requestFailed
        }

        let searchResponse = try JSONDecoder().decode(ItemSummaryPage.self, from: data)
        guard let title = searchResponse.itemSummaries?.first?.title else {
            throw BrowseError.noResults
        }
        return title
    }

    // Returns active listings matching the query, filtered by condition when non-empty.
    func search(query: String, conditions: [String]) async throws -> [ItemSummary] {
        let token = try await authService.validToken()

        var components = URLComponents(string: "\(baseURL)/search")!
        var queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "limit", value: "50")]
        if !conditions.isEmpty {
            let filter = "conditions:{\(conditions.joined(separator: "|"))}"
            queryItems.append(URLQueryItem(name: "filter", value: filter))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw BrowseError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BrowseError.requestFailed
        }

        let searchResponse = try JSONDecoder().decode(ItemSummaryPage.self, from: data)
        return searchResponse.itemSummaries ?? []
    }

    enum BrowseError: Error, LocalizedError {
        case requestFailed
        case noResults
        case invalidURL

        var errorDescription: String? {
            switch self {
            case .requestFailed: return "eBay search request failed."
            case .noResults: return "No results found for this image."
            case .invalidURL: return "Could not construct request URL."
            }
        }
    }

    private struct SearchByImageRequest: Encodable {
        let image: String
    }

    private struct ItemSummaryPage: Decodable {
        let itemSummaries: [ItemSummary]?
    }
}
