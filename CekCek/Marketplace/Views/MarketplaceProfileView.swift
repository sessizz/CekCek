import SwiftUI

struct MarketplaceProfileView: View {
    @EnvironmentObject private var authService: MarketplaceAuthService
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var isAuthenticating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            #if os(macOS)
            macOSBody
            #else
            iOSBody
            #endif
        }
    }

    // ── iOS: Form layout ──────────────────────────────────────────────────
    private var iOSBody: some View {
        Form {
            authStatusSection
            displayNameSection
            connectSection
        }
        .navigationTitle(String(localized: "marketplace.profile.title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { doneButton }
        .onAppear { displayName = authService.currentUser?.displayName ?? "" }
    }

    // ── macOS: plain VStack layout ────────────────────────────────────────
    private var macOSBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Auth status card
                Group {
                    if authService.isAuthenticated, let user = authService.currentUser {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.cloudKitUserId)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "icloud.slash")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text(String(localized: "marketplace.profile.browseOnly"))
                                .font(.headline)
                            Text(String(localized: "marketplace.profile.browseOnlyDescription"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
                .padding(.bottom, 20)

                Divider()
                    .padding(.bottom, 16)

                // Display name
                Text(String(localized: "marketplace.profile.displayName"))
                    .font(.headline)
                    .padding(.bottom, 8)

                TextField(
                    String(localized: "marketplace.profile.displayNamePlaceholder"),
                    text: $displayName
                )
                .textFieldStyle(.roundedBorder)
                .disabled(!authService.isAuthenticated)

                Button(String(localized: "common.save")) {
                    authService.updateDisplayName(displayName)
                }
                .disabled(!authService.isAuthenticated || displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.top, 8)

                Divider()
                    .padding(.vertical, 16)

                // Connect / error
                Button {
                    Task { await authenticate() }
                } label: {
                    if isAuthenticating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label(String(localized: "marketplace.profile.connect"), systemImage: "icloud")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }
            }
            .padding(24)
            .frame(minWidth: 340)
        }
        .navigationTitle(String(localized: "marketplace.profile.title"))
        .toolbar { doneButton }
        .onAppear { displayName = authService.currentUser?.displayName ?? "" }
    }

    // ── Shared sections (iOS Form) ────────────────────────────────────────
    @ViewBuilder
    private var authStatusSection: some View {
        Section {
            if authService.isAuthenticated, let user = authService.currentUser {
                Label(user.displayName, systemImage: "person.crop.circle.fill")
                    .font(.headline)
                Text(user.cloudKitUserId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } else {
                ContentUnavailableView(
                    String(localized: "marketplace.profile.browseOnly"),
                    systemImage: "icloud.slash",
                    description: Text(String(localized: "marketplace.profile.browseOnlyDescription"))
                )
            }
        }
    }

    @ViewBuilder
    private var displayNameSection: some View {
        Section(String(localized: "marketplace.profile.displayName")) {
            TextField(
                String(localized: "marketplace.profile.displayNamePlaceholder"),
                text: $displayName
            )
            .disabled(!authService.isAuthenticated)

            Button(String(localized: "common.save")) {
                authService.updateDisplayName(displayName)
            }
            .disabled(!authService.isAuthenticated || displayName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    @ViewBuilder
    private var connectSection: some View {
        Section {
            Button {
                Task { await authenticate() }
            } label: {
                if isAuthenticating {
                    ProgressView()
                } else {
                    Label(String(localized: "marketplace.profile.connect"), systemImage: "icloud")
                }
            }
            .disabled(isAuthenticating)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var doneButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "common.done")) { dismiss() }
        }
    }

    // ── Auth ──────────────────────────────────────────────────────────────
    private func authenticate() async {
        isAuthenticating = true
        errorMessage = nil
        defer { isAuthenticating = false }
        do {
            try await authService.ensureAuthenticated()
            displayName = authService.currentUser?.displayName ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
