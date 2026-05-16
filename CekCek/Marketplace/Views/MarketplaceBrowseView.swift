import SwiftUI

struct MarketplaceBrowseView: View {
    @EnvironmentObject private var apiService: MarketplaceAPIService
    @State private var searchText = ""
    @State private var showingProfile = false
    @State private var selectedCategory: MarketplaceCategory?
    @State private var selectedChecklistId: UUID?

    private var visibleChecklists: [MarketplaceChecklist] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return apiService.featuredChecklists }

        return apiService.featuredChecklists.filter { checklist in
            checklist.title.localizedCaseInsensitiveContains(trimmedSearch)
                || checklist.authorDisplayName.localizedCaseInsensitiveContains(trimmedSearch)
                || (checklist.description?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
        }
    }

    var body: some View {
        List {
            if let errorMessage = apiService.errorMessage {
                Section {
                    MarketplaceErrorView(message: errorMessage) {
                        Task { await apiService.loadBrowseData() }
                    }
                }
            }

            if apiService.isLoading && apiService.categories.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else {
                Section(String(localized: "marketplace.categories")) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 132), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(apiService.categories.filter(\.isActive)) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                MarketplaceCategoryTile(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(String(localized: "marketplace.featured")) {
                    if visibleChecklists.isEmpty {
                        ContentUnavailableView(
                            String(localized: "marketplace.empty.title"),
                            systemImage: "magnifyingglass",
                            description: Text(String(localized: "marketplace.empty.description"))
                        )
                    } else {
                        ForEach(visibleChecklists) { checklist in
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
        }
        .navigationTitle(String(localized: "marketplace.title"))
        .searchable(
            text: $searchText,
            prompt: String(localized: "marketplace.search.placeholder")
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task { await apiService.loadBrowseData() }
                } label: {
                    Label(String(localized: "common.refresh"), systemImage: "arrow.clockwise")
                }

                Button {
                    showingProfile = true
                } label: {
                    Label(String(localized: "marketplace.profile.title"), systemImage: "person.crop.circle")
                }
            }
        }
        .navigationDestination(item: $selectedCategory) { category in
            MarketplaceCategoryView(category: category)
        }
        .navigationDestination(item: $selectedChecklistId) { id in
            MarketplaceChecklistDetailView(checklistID: id)
        }
        .sheet(isPresented: $showingProfile) {
            MarketplaceProfileView()
        }
        .task {
            if apiService.categories.isEmpty && apiService.featuredChecklists.isEmpty {
                await apiService.loadBrowseData()
            }
        }
    }
}

private struct MarketplaceCategoryTile: View {
    let category: MarketplaceCategory

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(category.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(minHeight: 52)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MarketplaceChecklistRowView: View {
    let checklist: MarketplaceChecklist

    var body: some View {
        HStack(spacing: 12) {
            // Icon badge
            Group {
                if checklist.iconName.isEmoji {
                    Text(checklist.iconName)
                        .font(.system(size: 26))
                } else {
                    Image(systemName: checklist.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 38, height: 38)
            .background(checklist.iconName.isEmoji ? Color.clear : Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 9))

            // Title + author + stats
            VStack(alignment: .leading, spacing: 3) {
                Text(checklist.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(String(localized: "marketplace.byAuthor \(checklist.authorDisplayName)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Compact stats: icon + number only, no wrapping text
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "checklist")
                        Text("\(checklist.itemCount)")
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.circle")
                        Text("\(checklist.downloadCount)")
                    }
                    if checklist.ratingCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(checklist.averageRating.formatted(.number.precision(.fractionLength(1))))
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Rating pill — only show if rated
            if checklist.ratingCount == 0 {
                Text(String(localized: "marketplace.noRating"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MarketplaceRatingSummary: View {
    let averageRating: Double
    let ratingCount: Int

    private var formattedRating: String {
        averageRating.formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if ratingCount > 0 {
                Label(formattedRating, systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                Text("\(ratingCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(String(localized: "marketplace.noRating"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MarketplaceErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(String(localized: "marketplace.error.title"), systemImage: "wifi.exclamationmark")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(String(localized: "common.retry"), action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 6)
    }
}
