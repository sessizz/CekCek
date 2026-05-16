import SwiftData
import SwiftUI

struct MarketplaceUploadView: View {
    let checklist: Checklist

    @EnvironmentObject private var apiService: MarketplaceAPIService
    @EnvironmentObject private var authService: MarketplaceAuthService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategoryId: UUID?
    @State private var language = Locale.current.language.languageCode?.identifier == "tr" ? "tr" : "en"
    @State private var isPublishing = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var isAuthenticating = false
    @State private var authError: String?

    private var activeCategories: [MarketplaceCategory] {
        apiService.categories.filter(\.isActive)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String? {
        let value = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var isUpdate: Bool {
        checklist.marketplacePublishedId != nil
    }

    private var canPublish: Bool {
        !trimmedTitle.isEmpty && !checklist.sortedItems.isEmpty && !isPublishing
    }

    var body: some View {
        NavigationStack {
            Group {
                if isAuthenticating {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !authService.isAuthenticated {
                    authGate
                } else {
                    publishForm
                }
            }
            .navigationTitle(String(localized: "marketplace.upload.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                        .disabled(isPublishing)
                }
                if authService.isAuthenticated {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Task { await publish() }
                        } label: {
                            if isPublishing {
                                ProgressView()
                            } else {
                                Text(String(localized: isUpdate ? "marketplace.upload.update" : "marketplace.upload.publish"))
                            }
                        }
                        .disabled(!canPublish)
                    }
                }
            }
            .task {
                await checkAuth()
                title = checklist.displayTitle
                if apiService.categories.isEmpty {
                    await apiService.loadBrowseData()
                }
                selectedCategoryId = selectedCategoryId ?? activeCategories.first?.id
            }
            .alert(String(localized: "marketplace.upload.success"), isPresented: $showingSuccess) {
                Button(String(localized: "common.done")) { dismiss() }
            } message: {
                Text(String(localized: "marketplace.upload.successMessage"))
            }
        }
    }

    // MARK: - Subviews

    private var authGate: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)

            Text(String(localized: "marketplace.upload.authRequired.title"))
                .font(.title3.bold())

            Text(String(localized: "marketplace.upload.authRequired.message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let authError {
                Text(authError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await signIn() }
            } label: {
                Label(
                    String(localized: "marketplace.upload.authRequired.signIn"),
                    systemImage: "icloud"
                )
                .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var publishForm: some View {
        Form {
                if isUpdate {
                    Section {
                        Label(String(localized: "marketplace.upload.updateNotice"), systemImage: "arrow.triangle.2.circlepath")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.accentColor.opacity(0.08))
                }

                Section(String(localized: "marketplace.upload.checklist")) {
                    Label(checklist.displayTitle, systemImage: checklist.iconName)
                    Text(String(localized: "marketplace.upload.itemSummary \(checklist.sortedItems.count)"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(String(localized: "marketplace.upload.details")) {
                    TextField(String(localized: "marketplace.upload.titlePlaceholder"), text: $title)
                    TextField(
                        String(localized: "marketplace.upload.descriptionPlaceholder"),
                        text: $description,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section(String(localized: "marketplace.upload.category")) {
                    Picker(String(localized: "marketplace.upload.category"), selection: $selectedCategoryId) {
                        Text(String(localized: "marketplace.upload.noCategory"))
                            .tag(UUID?.none)

                        ForEach(activeCategories) { category in
                            Text(category.displayName)
                                .tag(Optional(category.id))
                        }
                    }

                    if apiService.isLoading && activeCategories.isEmpty {
                        ProgressView()
                    }
                }

                Section(String(localized: "marketplace.upload.language")) {
                    Picker(String(localized: "marketplace.upload.language"), selection: $language) {
                        Text(String(localized: "marketplace.upload.language.tr")).tag("tr")
                        Text(String(localized: "marketplace.upload.language.en")).tag("en")
                    }
                    .pickerStyle(.segmented)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
        }
    }

    private func checkAuth() async {
        guard !authService.isAuthenticated else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        _ = try? await authService.ensureAuthenticated()
    }

    private func signIn() async {
        isAuthenticating = true
        authError = nil
        defer { isAuthenticating = false }
        do {
            try await authService.ensureAuthenticated()
        } catch {
            authError = error.localizedDescription
        }
    }

    private func publish() async {
        isPublishing = true
        errorMessage = nil
        defer { isPublishing = false }

        do {
            let accessToken = try await authService.ensureAuthenticated()
            let request = MarketplacePublishRequest(
                title: trimmedTitle,
                description: trimmedDescription,
                iconName: checklist.iconName,
                categoryId: selectedCategoryId,
                language: language,
                sourceChecklistId: checklist.id,
                items: checklist.sortedItems.enumerated().map { index, item in
                    MarketplacePublishItem(title: item.displayTitle, sortOrder: index)
                }
            )

            if let publishedId = checklist.marketplacePublishedId {
                // Already on marketplace → update existing listing
                _ = try await apiService.updateChecklist(id: publishedId, request, accessToken: accessToken)
            } else {
                // New listing
                let published = try await apiService.publishChecklist(request, accessToken: accessToken)
                checklist.marketplacePublishedId = published.id
                try? modelContext.save()
            }
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
