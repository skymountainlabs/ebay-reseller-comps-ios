import Foundation

struct PriceAnalysisService {
    func analyze(items: [ItemSummary]) -> [PriceSummary] {
        let grouped = Dictionary(grouping: items) { $0.condition ?? "Unknown" }
        return grouped.compactMap { condition, groupItems -> PriceSummary? in
            let prices = groupItems.compactMap { Double($0.price.value) }
            guard !prices.isEmpty else { return nil }
            let sorted = prices.sorted()
            let count = prices.count
            let average = prices.reduce(0, +) / Double(count)
            let median: Double
            if count % 2 == 0 {
                median = (sorted[count / 2 - 1] + sorted[count / 2]) / 2
            } else {
                median = sorted[count / 2]
            }
            return PriceSummary(
                condition: condition,
                count: count,
                average: average,
                median: median,
                min: sorted.first!,
                max: sorted.last!
            )
        }
        .sorted { $0.condition < $1.condition }
    }
}
