import SwiftUI

struct MarketplaceCategoryView: View {
    let category: MarketplaceCategory
    @EnvironmentObject private var apiService: MarketplaceAPIService
    @State private var checklists: [MarketplaceChecklist] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedChecklistId: UUID?

    var body: some View {
        List {
            // ── Category header ──────────────────────────────────────────
            Section {
                HStack(spacing: 16) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.displayName)
                            .font(.title2.bold())

                        Group {
                            if isLoading {
                                Text(String(localized: "marketplace.loading"))
                                    .foregroundStyle(.secondary)
                            } else if !checklists.isEmpty {
                                Text(String(localized: "marketplace.checklistCount \(checklists.count)"))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(String(localized: "marketplace.category.empty"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowSeparator(.hidden)

            // ── Content ──────────────────────────────────────────────────
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 40)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else if let errorMessage {
                    MarketplaceErrorView(message: errorMessage) {
                        Task { await loadChecklists() }
                    }
                    .listRowSeparator(.hidden)
                } else if checklists.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 44))
                            .foregroundStyle(.tertiary)
                        Text(String(localized: "marketplace.category.emptyDescription"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(checklists) { checklist in
                        Button {
                            selectedChecklistId = checklist.id
                        } label: {
                            MarketplaceChecklistRowView(checklist: checklist)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(category.displayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(item: $selectedChecklistId) { id in
            MarketplaceChecklistDetailView(checklistID: id)
        }
        .onAppear {
            guard checklists.isEmpty && isLoading else { return }
            Task { await loadChecklists() }
        }
        .task {
            await loadChecklists()
        }
    }

    private func loadChecklists() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            checklists = try await apiService.checklists(in: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
