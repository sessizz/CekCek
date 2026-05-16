import SwiftUI

/// Sheet shown from ChecklistDetailView when the checklist was downloaded from the marketplace.
/// Fetches and displays the original marketplace listing (author, description, stats) — no download action.
struct MarketplaceInfoSheet: View {
    let marketplaceSourceId: UUID
    @EnvironmentObject private var apiService: MarketplaceAPIService
    @Environment(\.dismiss) private var dismiss

    @State private var checklist: MarketplaceChecklist?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && checklist == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, checklist == nil {
                    MarketplaceErrorView(message: errorMessage) {
                        Task { await load() }
                    }
                    .padding()
                } else if let checklist {
                    List {
                        // ── Header ──────────────────────────────────────
                        Section {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .top, spacing: 14) {
                                    // Icon
                                    Group {
                                        if checklist.iconName.isEmoji {
                                            Text(checklist.iconName)
                                                .font(.system(size: 36))
                                        } else {
                                            Image(systemName: checklist.iconName)
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(width: 54, height: 54)
                                    .background(checklist.iconName.isEmoji ? Color.clear : Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(
                                        color: Color(red: 1.0, green: 0.78, blue: 0.1).opacity(0.75),
                                        radius: 10, x: 0, y: 3
                                    )

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(checklist.title)
                                            .font(.title2.bold())
                                        Text(String(localized: "marketplace.byAuthor \(checklist.authorDisplayName)"))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }

                                if let description = checklist.description, !description.isEmpty {
                                    Text(description)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }

                                // Stats row
                                HStack(spacing: 16) {
                                    Label(
                                        String(localized: "marketplace.itemCount \(checklist.itemCount)"),
                                        systemImage: "checklist"
                                    )
                                    Label(
                                        String(localized: "marketplace.downloadCount \(checklist.downloadCount)"),
                                        systemImage: "arrow.down.circle"
                                    )
                                    MarketplaceRatingSummary(
                                        averageRating: checklist.averageRating,
                                        ratingCount: checklist.ratingCount
                                    )
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                // "Downloaded" badge
                                Label(String(localized: "marketplace.info.downloaded"), systemImage: "checkmark.seal.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.1))
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowSeparator(.hidden)

                        // ── Item preview ─────────────────────────────────
                        let sortedItems = (checklist.items ?? []).sorted { $0.sortOrder < $1.sortOrder }
                        if !sortedItems.isEmpty {
                            Section(String(localized: "marketplace.preview")) {
                                ForEach(sortedItems) { item in
                                    HStack(spacing: 12) {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                        Text(item.title)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                }
            }
            .navigationTitle(String(localized: "marketplace.info.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) { dismiss() }
                }
            }
            .onAppear {
                guard checklist == nil && !isLoading else { return }
                Task { await load() }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            checklist = try await apiService.checklistDetail(id: marketplaceSourceId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
