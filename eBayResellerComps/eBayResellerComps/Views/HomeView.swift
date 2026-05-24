import SwiftUI

struct HomeView: View {
    @EnvironmentObject var historyService: SearchHistoryService
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var suggestedQuery = ""
    @State private var isLoadingQuery = false
    @State private var navigateToConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pickButton
                historyList
            }
            .navigationTitle("eBay Reseller Comps")
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView { image in
                    selectedImage = image
                    showingImagePicker = false
                    Task { await handleImageSelected(image) }
                }
            }
            .navigationDestination(isPresented: $navigateToConfirm) {
                if let image = selectedImage {
                    SearchConfirmView(image: image, suggestedQuery: suggestedQuery)
                }
            }
        }
    }

    private var pickButton: some View {
        Button(action: { showingImagePicker = true }) {
            Label("Take or Choose Photo", systemImage: "camera")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoadingQuery ? Color.accentColor.opacity(0.6) : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoadingQuery)
        .overlay(alignment: .trailing) {
            if isLoadingQuery {
                ProgressView().tint(.white).padding(.trailing, 16)
            }
        }
        .padding()
    }

    private var historyList: some View {
        Group {
            if historyService.records.isEmpty {
                ContentUnavailableView(
                    "No Recent Searches",
                    systemImage: "clock",
                    description: Text("Your search history will appear here.")
                )
            } else {
                List(historyService.records) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.query).font(.body)
                        Text(record.timestamp, style: .relative)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func handleImageSelected(_ image: UIImage) async {
        isLoadingQuery = true
        defer { isLoadingQuery = false }
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            navigateToConfirm = true
            return
        }
        do {
            suggestedQuery = try await EBayBrowseService.shared.searchByImage(imageData: data)
        } catch {
            suggestedQuery = ""
        }
        navigateToConfirm = true
    }
}

#Preview {
    let service = SearchHistoryService()
    service.records = [
        SearchRecord(id: UUID(), query: "Vintage Rolex Submariner", timestamp: Date(), imageThumbData: nil),
        SearchRecord(id: UUID(), query: "Nike Air Jordan 1 Retro", timestamp: Date().addingTimeInterval(-3600), imageThumbData: nil),
    ]
    return HomeView().environmentObject(service)
}
