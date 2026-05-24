import SwiftUI

struct SearchConfirmView: View {
    let image: UIImage
    let suggestedQuery: String

    @EnvironmentObject var historyService: SearchHistoryService
    @State private var query: String
    @State private var selectedConditions: Set<String> = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchResults: [ItemSummary] = []
    @State private var navigateToPriceAnalysis = false

    private let conditionOptions = ["NEW", "USED"]

    init(image: UIImage, suggestedQuery: String) {
        self.image = image
        self.suggestedQuery = suggestedQuery
        _query = State(initialValue: suggestedQuery)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Search Query").font(.subheadline).foregroundStyle(.secondary)
                    TextField("e.g. Vintage Rolex Submariner", text: $query)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                conditionPicker

                if let error = searchError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button(action: performSearch) {
                    Group {
                        if isSearching {
                            ProgressView()
                        } else {
                            Text("Search eBay Active Listings")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Confirm Search")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPriceAnalysis) {
            PriceAnalysisView(items: searchResults)
        }
    }

    private var conditionPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Condition (optional)").font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(conditionOptions, id: \.self) { condition in
                    let selected = selectedConditions.contains(condition)
                    Button {
                        if selected { selectedConditions.remove(condition) }
                        else { selectedConditions.insert(condition) }
                    } label: {
                        Text(condition.capitalized)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selected ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                }
                Text("(none = Any)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private func performSearch() {
        isSearching = true
        searchError = nil
        Task {
            defer { isSearching = false }
            do {
                let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
                let results = try await EBayBrowseService.shared.search(
                    query: trimmedQuery,
                    conditions: Array(selectedConditions)
                )
                searchResults = results
                let thumbData = image.jpegData(compressionQuality: 0.2)
                let record = SearchRecord(id: UUID(), query: trimmedQuery, timestamp: Date(), imageThumbData: thumbData)
                await historyService.save(record)
                navigateToPriceAnalysis = true
            } catch {
                searchError = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchConfirmView(
            image: UIImage(systemName: "photo")!,
            suggestedQuery: "Vintage Rolex Submariner"
        )
        .environmentObject(SearchHistoryService())
    }
}
