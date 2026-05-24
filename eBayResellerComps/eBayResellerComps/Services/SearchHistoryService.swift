import Foundation

@MainActor
final class SearchHistoryService: ObservableObject {
    @Published var records: [SearchRecord] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("search_history.json")
    }

    func load() async {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            records = try JSONDecoder().decode([SearchRecord].self, from: data)
        } catch {
            records = []
        }
    }

    func save(_ record: SearchRecord) async {
        records.insert(record, at: 0)
        persist()
    }

    func clearAll() async {
        records = []
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // History is non-critical; silently swallow write failures.
        }
    }
}
