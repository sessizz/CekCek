import SwiftData
import SwiftUI

struct MarketplaceChecklistDetailView: View {
    let checklistID: UUID
    @EnvironmentObject private var apiService: MarketplaceAPIService
    @EnvironmentObject private var authService: MarketplaceAuthService
    @Environment(\.modelContext) private var modelContext

    @State private var checklist: MarketplaceChecklist?
    @State private var isLoading = true
    @State private var isDownloading = false
    @State private var errorMessage: String?

    // Download
    @State private var showDownloadSuccess = false
    @State private var showDownloadError = false
    @State private var downloadErrorMessage = ""
    @State private var didDownload = false

    // Rating
    @State private var pendingRating: Int = 0   // star user is hovering/tapping
    @State private var submittedRating: Int = 0  // persisted after submit
    @State private var isRating = false
    @State private var ratingError: String?
    @State private var showRatingError = false

    private var ratingDefaultsKey: String { "marketplace.rating.\(checklistID)" }

    private var sortedItems: [MarketplaceChecklistItem] {
        (checklist?.items ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        Group {
            if isLoading && checklist == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage, checklist == nil {
                MarketplaceErrorView(message: errorMessage) {
                    Task { await loadChecklist() }
                }
                .padding()
            } else if let checklist {
                List {
                    // ── Header ──────────────────────────────────────────
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 14) {
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

                            // Stats
                            HStack(spacing: 16) {
                                Label(
                                    String(localized: "marketplace.itemCount \(checklist.itemCount)"),
                                    systemImage: "checklist"
                                )
                                Label(
                                    "\(didDownload ? checklist.downloadCount : checklist.downloadCount)",
                                    systemImage: "arrow.down.circle"
                                )
                                MarketplaceRatingSummary(
                                    averageRating: checklist.averageRating,
                                    ratingCount: checklist.ratingCount
                                )
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowSeparator(.hidden)

                    // ── Rating ───────────────────────────────────────────
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "marketplace.rating.title"))
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 6) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: starIcon(for: star))
                                        .font(.title2)
                                        .foregroundStyle(star <= (pendingRating > 0 ? pendingRating : submittedRating) ? Color.yellow : Color.secondary.opacity(0.4))
                                        .onTapGesture {
                                            pendingRating = star
                                            Task { await submitRating(star) }
                                        }
                                }

                                if isRating {
                                    ProgressView()
                                        .padding(.leading, 6)
                                } else if submittedRating > 0 {
                                    Text(String(localized: "marketplace.rating.submitted"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 4)
                                }
                            }

                            if let ratingError {
                                Text(ratingError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // ── Item preview ─────────────────────────────────────
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
                .safeAreaInset(edge: .bottom) {
                    Button {
                        Task { await downloadChecklist() }
                    } label: {
                        if isDownloading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label(
                                String(localized: didDownload ? "marketplace.download.again" : "marketplace.download"),
                                systemImage: "arrow.down.circle.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isDownloading)
                    .padding()
                    .background(.regularMaterial)
                }
            }
        }
        .navigationTitle(String(localized: "marketplace.detail.title"))
        .alert(String(localized: "marketplace.download.success"), isPresented: $showDownloadSuccess) {
            Button(String(localized: "common.done")) {}
        } message: {
            Text(String(localized: "marketplace.download.successMessage"))
        }
        .alert(String(localized: "marketplace.download.error"), isPresented: $showDownloadError) {
            Button(String(localized: "common.done")) {}
        } message: {
            Text(downloadErrorMessage)
        }
        .onAppear {
            guard checklist == nil && isLoading else { return }
            Task { await loadChecklist() }
        }
        .task {
            await loadChecklist()
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private func starIcon(for star: Int) -> String {
        let active = pendingRating > 0 ? pendingRating : submittedRating
        return star <= active ? "star.fill" : "star"
    }

    // ── Actions ───────────────────────────────────────────────────────────

    private func loadChecklist() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            checklist = try await apiService.checklistDetail(id: checklistID)
            await restoreRating()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fetches the user's existing rating from the server if a valid token is
    /// available, otherwise falls back to the locally cached value.
    private func restoreRating() async {
        if let token = authService.currentTokenIfValid,
           let serverRating = try? await apiService.fetchMyRating(checklistId: checklistID, accessToken: token) {
            submittedRating = serverRating
            UserDefaults.standard.set(serverRating, forKey: ratingDefaultsKey)
            return
        }
        // Fallback: local cache (covers offline / not-yet-authenticated cases)
        let saved = UserDefaults.standard.integer(forKey: ratingDefaultsKey)
        if saved > 0 { submittedRating = saved }
    }

    private func downloadChecklist() async {
        guard !isDownloading else { return }
        isDownloading = true
        defer { isDownloading = false }

        // Check for an existing local copy BEFORE hitting the server so
        // we never increment the counter for a duplicate download.
        let sourceId = checklistID
        let duplicateDescriptor = FetchDescriptor<Checklist>(
            predicate: #Predicate { $0.marketplaceSourceId == sourceId }
        )
        if (try? modelContext.fetchCount(duplicateDescriptor) ?? 0) ?? 0 > 0 {
            downloadErrorMessage = ImportError.duplicate(title: checklist?.title ?? "").localizedDescription
            showDownloadError = true
            return
        }

        do {
            let detail = try await apiService.downloadChecklist(id: checklistID)
            try ChecklistImporter.importMarketplaceChecklist(detail, context: modelContext)
            didDownload = true
            showDownloadSuccess = true
            // Reload from server so the incremented download count is shown
            // and stays consistent on future visits
            await loadChecklist()
        } catch {
            downloadErrorMessage = error.localizedDescription
            showDownloadError = true
        }
    }

    private func submitRating(_ stars: Int) async {
        guard !isRating else { return }
        isRating = true
        ratingError = nil
        defer { isRating = false }

        do {
            let token = try await authService.ensureAuthenticated()
            let updated = try await apiService.rateChecklist(id: checklistID, rating: stars, accessToken: token)
            checklist = updated
            submittedRating = stars
            pendingRating = 0
            UserDefaults.standard.set(stars, forKey: ratingDefaultsKey)
        } catch {
            ratingError = error.localizedDescription
            pendingRating = 0
        }
    }
}
