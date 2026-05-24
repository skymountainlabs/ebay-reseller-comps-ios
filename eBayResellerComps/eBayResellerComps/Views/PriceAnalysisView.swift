import SwiftUI

struct PriceAnalysisView: View {
    let items: [ItemSummary]

    private let analysisService = PriceAnalysisService()

    private var summaries: [PriceSummary] {
        analysisService.analyze(items: items)
    }

    var body: some View {
        Group {
            if summaries.isEmpty {
                ContentUnavailableView(
                    "No Price Data",
                    systemImage: "magnifyingglass",
                    description: Text("No listings with parseable prices were returned.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("\(items.count) listing\(items.count == 1 ? "" : "s") analysed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ForEach(summaries, id: \.condition) { summary in
                            PriceSummaryCard(summary: summary)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Price Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PriceSummaryCard: View {
    let summary: PriceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(summary.condition.capitalized)
                    .font(.headline)
                Spacer()
                Text("\(summary.count) listing\(summary.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    statLabel("Average")
                    statValue(summary.average)
                    statLabel("Median")
                    statValue(summary.median)
                }
                GridRow {
                    statLabel("Min")
                    statValue(summary.min)
                    statLabel("Max")
                    statValue(summary.max)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statLabel(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary)
    }

    private func statValue(_ amount: Double) -> some View {
        Text(amount, format: .currency(code: "USD"))
            .font(.body)
            .fontWeight(.semibold)
    }
}

#Preview {
    NavigationStack {
        PriceAnalysisView(items: [
            ItemSummary(itemId: "1", title: "Rolex Submariner New", price: .init(value: "8500.00", currency: "USD"), condition: "NEW"),
            ItemSummary(itemId: "2", title: "Rolex Submariner Used A", price: .init(value: "6200.00", currency: "USD"), condition: "USED"),
            ItemSummary(itemId: "3", title: "Rolex Submariner Used B", price: .init(value: "5800.00", currency: "USD"), condition: "USED"),
            ItemSummary(itemId: "4", title: "Rolex Submariner Used C", price: .init(value: "6800.00", currency: "USD"), condition: "USED"),
        ])
    }
}
