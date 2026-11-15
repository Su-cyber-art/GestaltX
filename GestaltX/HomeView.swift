// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

/// The Tools tab: a dashboard built from cards instead of a long form.
///
/// Top to bottom: the device hero card, the live modification status, the
/// one-click unlock call to action, the MobileGestalt categories, the
/// customization tools, pairing and quick actions. Staged edits surface in a
/// floating bar so Apply/Discard are always one tap away.
struct HomeView: View {
    @EnvironmentObject private var model: GestaltManager
    @ObservedObject var systemSettings: SystemSettingsModel
    @ObservedObject var customizations: CustomizationModel
    @ObservedObject var launchCatalog: LaunchArtworkCatalogModel
    @Binding var showsChanges: Bool
    @Binding var asksRespring: Bool
    @Binding var asksImportedRestore: Bool
    let share: (TemporaryExport) -> Void

    private let twoColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let threeColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        // `changeCount` rebuilds the preview document; read it once per pass.
        let pending = model.changeCount
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DeviceHeroCard()
                if model.sourceIsDevice { DeviceStatusCard(pending: pending) }
                oneClickUnlock

                GXSectionHeader(title: "MobileGestalt")
                categories

                GXSectionHeader(title: L("Customization"))
                customization

                GXSectionHeader(title: L("Device Pairing"))
                NavigationLink { DeviceConnectionView() } label: {
                    GXRowCard(title: L("Pairing & Device Connection"), systemImage: "link.badge.plus",
                              tint: Color(red: 0.176, green: 0.682, blue: 0.851))
                }
                .buttonStyle(.gxPressable)

                GXSectionHeader(title: L("Quick Actions"))
                actions
                if model.needsRespring {
                    GXBanner(text: L("Some changes require a device restart."), systemImage: "restart.circle.fill",
                             tint: GestaltTheme.caution)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background { GXPageBackground() }
        .navigationTitle("GestaltX")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { if model.isBusy { ProgressView() } } }
        .safeAreaInset(edge: .bottom) {
            if pending > 0 {
                PendingChangesBar(count: pending, busy: model.isBusy,
                                  review: { showsChanges = true },
                                  discard: { model.clearStaged() })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: pending)
    }

    // MARK: One-click unlock

    private var oneClickUnlock: some View {
        Button {
            if model.stageOneClickUnlock() {
                if model.changeCount > 0 {
                    showsChanges = true
                } else {
                    model.message = L("These unlock settings are already applied.")
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.2))
                    Image(systemName: "sparkles").font(.title2.weight(.semibold))
                }
                .frame(width: 50, height: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("One-Click Unlock")).font(.headline)
                    Text(L("Configure the US region, AI and Siri capabilities, and Additional Options together. Review and apply the changes, then restart your device."))
                        .font(.caption)
                        .opacity(0.86)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.forward")
                    .font(.subheadline.weight(.bold))
                    .opacity(0.8)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .foregroundStyle(Color.white)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: GestaltTheme.cardRadius, style: .continuous)
                        .fill(GestaltTheme.gradient)
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .offset(x: 50, y: -60)
                }
                .clipShape(RoundedRectangle(cornerRadius: GestaltTheme.cardRadius, style: .continuous))
                .shadow(color: GestaltTheme.accent.opacity(0.32), radius: 14, y: 6)
            }
            .contentShape(RoundedRectangle(cornerRadius: GestaltTheme.cardRadius, style: .continuous))
        }
        .buttonStyle(.gxPressable)
        .disabled(!model.hasDocument || model.isBusy)
        .accessibilityIdentifier("one-click-unlock")
    }

    // MARK: Categories

    private func stagedCount(_ category: CapabilityCategory) -> Int {
        Capability.all.filter { $0.category == category && (model.choices[$0.id] ?? .keep) != .keep }.count
    }

    @ViewBuilder private var categories: some View {
        let all = CapabilityCategory.allCases
        let isEven = all.count.isMultiple(of: 2)
        LazyVGrid(columns: twoColumns, spacing: 12) {
            ForEach(isEven ? Array(all) : Array(all.dropLast())) { category in
                categoryLink(category, wide: false)
            }
        }
        if !isEven, let last = all.last {
            categoryLink(last, wide: true)
        }
    }

    private func categoryLink(_ category: CapabilityCategory, wide: Bool) -> some View {
        let staged = stagedCount(category)
        return NavigationLink { CategoryView(category: category) } label: {
            if wide {
                GXRowCard(title: L(category.rawValue), subtitle: L(category.subtitle),
                          systemImage: category.symbol, tint: category.tint)
            } else {
                GXTile(title: L(category.rawValue), subtitle: L(category.subtitle),
                       systemImage: category.symbol, tint: category.tint,
                       badge: staged > 0 ? String(staged) : nil)
            }
        }
        .buttonStyle(.gxPressable)
        .disabled(!model.hasDocument || model.isBusy)
    }

    // MARK: Customization

    private var customization: some View {
        LazyVGrid(columns: twoColumns, spacing: 12) {
            NavigationLink { SystemSettingsView(model: systemSettings) } label: {
                GXTile(title: L("System Settings"), systemImage: "gearshape.fill", tint: Color(uiColor: .systemGray))
            }
            .disabled(model.isBusy)
            NavigationLink { WallpapersView(model: customizations) } label: {
                GXTile(title: L("Wallpaper Settings"), systemImage: "photo.on.rectangle.angled",
                       tint: Color(red: 0.176, green: 0.682, blue: 0.851))
            }
            .disabled(model.isBusy)
            NavigationLink { LaunchArtworkApplicationsView(customizations: customizations, catalog: launchCatalog) } label: {
                GXTile(title: L("App Launch Images"), systemImage: "app.badge.fill",
                       tint: Color(red: 0.965, green: 0.584, blue: 0.180))
            }
            NavigationLink { AppSoundApplicationsView(customizations: customizations) } label: {
                GXTile(title: L("App Audio Library"), systemImage: "bell.badge.fill", tint: GestaltTheme.accentPink)
            }
            .disabled(model.isBusy)
        }
        .buttonStyle(.gxPressable)
    }

    // MARK: Quick actions

    private var actions: some View {
        LazyVGrid(columns: threeColumns, spacing: 12) {
            if model.snapshot?.source == .local && model.snapshot?.ownershipVerified == true {
                Button { asksImportedRestore = true } label: {
                    GXActionTile(title: L("Restore Imported Plist"), systemImage: "arrow.uturn.backward",
                                 tint: GestaltTheme.danger)
                }
                .disabled(!model.canRestoreImportedPlist)
            }
            Button { Task { await model.backup() } } label: {
                GXActionTile(title: L("Create Backup"), systemImage: "externaldrive.fill.badge.plus",
                             tint: GestaltTheme.positive)
            }
            .disabled(!model.hasDocument || model.isBusy)
            Button {
                if let export = model.exportDocument() { share(export) }
            } label: {
                GXActionTile(title: L("Export Plist"), systemImage: "square.and.arrow.up",
                             tint: Color(red: 0.200, green: 0.522, blue: 0.965))
            }
            .disabled(!model.hasDocument || model.isBusy)
            Button { asksRespring = true } label: {
                GXActionTile(title: L("Respring"), systemImage: "arrow.trianglehead.2.clockwise.rotate.90",
                             tint: GestaltTheme.caution)
            }
            .disabled(model.isBusy)
            NavigationLink { SessionLogView() } label: {
                GXActionTile(title: L("Log"), systemImage: "text.alignleft", tint: Color(uiColor: .systemGray))
            }
        }
        .buttonStyle(.gxPressable)
    }
}

// MARK: - Hero

private struct DeviceHeroCard: View {
    @EnvironmentObject private var model: GestaltManager

    /// Localization key and dot color for the connection state.
    private var status: (key: String, tint: Color) {
        guard model.hasDocument else {
            return model.isBusy ? ("Reading…", Color.yellow) : ("Not Loaded", Color.white.opacity(0.6))
        }
        guard model.sourceIsDevice else { return ("Local File", Color.cyan) }
        return model.deviceAccessible ? ("Connected", Color.green) : ("Not Connected", Color.orange)
    }

    var body: some View {
        let status = self.status
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                BrandMark(size: 34)
                    .overlay {
                        RoundedRectangle(cornerRadius: 34 * 0.22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    }
                Text(verbatim: "GestaltX").font(.subheadline.weight(.semibold)).opacity(0.9)
                Spacer(minLength: 8)
                StatusPill(text: L(status.key), tint: status.tint, onGradient: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(model.hasDocument ? model.displayedName : UIDevice.current.model)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 8) {
                    heroChip(systemImage: "gear", text: "iOS \(UIDevice.current.systemVersion)")
                    heroChip(systemImage: VersionSupport.current ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                             text: VersionSupport.label)
                    if let document = model.working {
                        heroChip(systemImage: "square.stack.3d.up.fill", text: "CacheExtra \(document.extra.count)")
                    }
                }
            }

            Button { Task { await model.connect() } } label: {
                HStack(spacing: 8) {
                    if model.isBusy {
                        ProgressView().tint(GestaltTheme.accent)
                    } else {
                        Image(systemName: "arrow.clockwise").font(.subheadline.weight(.bold))
                    }
                    Text(L(model.isBusy ? "Reading…" : model.hasDocument ? "Read Again" : "Read MobileGestalt"))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(GestaltTheme.accentDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Capsule().fill(Color.white))
                .contentShape(Capsule())
            }
            .buttonStyle(.gxPressable)
            .disabled(model.isBusy || model.changeCount > 0)
        }
        .foregroundStyle(Color.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { heroBackground }
        .shadow(color: GestaltTheme.accentDeep.opacity(0.35), radius: 18, y: 8)
    }

    private func heroChip(systemImage: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.caption2.weight(.bold))
            Text(verbatim: text).font(.caption.weight(.semibold)).lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.16)))
    }

    private var heroBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return ZStack {
            shape.fill(GestaltTheme.heroGradient)
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 4)
                .offset(x: 140, y: -90)
            Circle()
                .fill(GestaltTheme.accentPink.opacity(0.45))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: -120, y: 90)
            shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
        .clipShape(shape)
    }
}

// MARK: - Live status

private struct DeviceStatusCard: View {
    @EnvironmentObject private var model: GestaltManager
    let pending: Int

    var body: some View {
        NavigationLink { DeviceStatusView() } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(GestaltTheme.accent)
                        .symbolEffect(.pulse, options: .repeating, isActive: model.deviceStatus != nil && model.deviceStatusError == nil)
                    Text(L("Current Modification Status"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if let reading = model.deviceStatus {
                        Text(reading.readAt, format: .dateTime.hour().minute().second())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .flipsForRightToLeftLayoutDirection(true)
                }

                HStack(alignment: .top, spacing: 12) {
                    GXStat(value: modifiedValue, label: L("Modified Parameters"), tint: GestaltTheme.accent)
                    divider
                    GXStat(value: String(pending), label: L("Pending Changes"),
                           tint: pending > 0 ? GestaltTheme.caution : .primary)
                    divider
                    unlockStat
                }

                if let error = model.deviceStatusError {
                    GXBanner(text: L("Read failed. Showing the last successful reading."),
                             systemImage: "exclamationmark.triangle.fill", tint: GestaltTheme.caution, detail: error)
                } else if let reading = model.deviceStatus {
                    if !reading.report.issues.isEmpty {
                        GXBanner(text: L("Some parameters could not be compared."),
                                 systemImage: "exclamationmark.triangle.fill", tint: GestaltTheme.caution)
                    } else if !reading.report.hasRecordedOriginals {
                        GXBanner(text: L("No recorded originals yet."), systemImage: "info.circle.fill")
                    }
                }

                Text(L("Automatically reads the device every 5 seconds while the app is active. Pending edits are excluded."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .gxCard()
        }
        .buttonStyle(.gxPressable)
    }

    private var modifiedValue: String {
        guard let reading = model.deviceStatus else { return "…" }
        return reading.report.hasRecordedOriginals ? String(reading.report.changes.count) : "—"
    }

    @ViewBuilder private var unlockStat: some View {
        if model.deviceStatusError == nil, let configured = model.deviceStatus?.report.unlockConfigured {
            GXStat(value: L(configured ? "On" : "Off"), label: L("One-Click Unlock"),
                   tint: configured ? GestaltTheme.positive : .secondary,
                   systemImage: configured ? "checkmark.seal.fill" : "seal")
        } else {
            GXStat(value: "—", label: L("One-Click Unlock"), tint: .secondary)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(width: 1, height: 44)
    }
}

// MARK: - Pending bar

private struct PendingChangesBar: View {
    let count: Int
    let busy: Bool
    let review: () -> Void
    let discard: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(String(count))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.white)
                .frame(minWidth: 30, minHeight: 30)
                .padding(.horizontal, 2)
                .background(Capsule().fill(GestaltTheme.gradient))
                .contentTransition(.numericText())
            Text(L("Pending Changes"))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            Button(action: discard) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(GestaltTheme.danger)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(GestaltTheme.danger.opacity(0.12)))
                    .contentShape(Circle())
            }
            .buttonStyle(.gxPressable)
            .accessibilityLabel(L("Discard Changes"))
            Button(action: review) {
                Text(L("Review"))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Capsule().fill(GestaltTheme.gradient))
                    .contentShape(Capsule())
            }
            .buttonStyle(.gxPressable)
            .accessibilityIdentifier("review-pending-changes")
        }
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .disabled(busy)
    }
}
