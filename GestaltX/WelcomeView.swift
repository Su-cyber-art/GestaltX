// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 huamidev
import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    GXSectionHeader(title: L("Compatibility"))
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            IconChip(systemName: "iphone.gen3", tint: GestaltTheme.positive, size: 38, filled: true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(VersionSupport.range).font(.headline)
                                Text(verbatim: "iOS \(UIDevice.current.systemVersion)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            GXCapsule(text: VersionSupport.label,
                                      tint: VersionSupport.current ? GestaltTheme.positive : GestaltTheme.caution,
                                      systemImage: VersionSupport.current ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        }
                        Divider()
                        LabeledContent("iOS 26.x") {
                            GXCapsule(text: L("Unsupported"), tint: Color(uiColor: .systemGray))
                        }
                        .font(.subheadline)
                        Text(L("System access and available features vary by OS version, device and signing."))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .gxCard()

                    GXSectionHeader(title: L("Disclaimer"))
                    VStack(alignment: .leading, spacing: 14) {
                        point("exclamationmark.triangle.fill", GestaltTheme.danger,
                              L("Changing MobileGestalt may cause system instability, missing features or a boot loop. Recovering the device may require a restore."))
                        point("externaldrive.fill.badge.timemachine", GestaltTheme.accent,
                              L("Back up your device before making changes, and export a copy of the original plist."))
                        point("cpu.fill", Color(red: 0.200, green: 0.522, blue: 0.965),
                              L("Capability flags cannot add missing hardware. Some changes require a device restart."))
                        point("person.badge.shield.checkmark.fill", GestaltTheme.positive,
                              L("Use only devices you own or are authorized to manage. You are responsible for the changes you choose to apply."))
                        point("doc.text.fill", Color(uiColor: .systemGray),
                              L("This software is provided without warranty. Read the included license before use."))
                    }
                    .gxCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background { GXPageBackground() }
            .navigationTitle(L("Welcome"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Text(L("I Understand, Continue"))
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Capsule().fill(GestaltTheme.gradient))
                        .shadow(color: GestaltTheme.accent.opacity(0.3), radius: 12, y: 5)
                        .contentShape(Capsule())
                }
                .buttonStyle(.gxPressable)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.bar)
            }
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandMark(size: 64)
                .overlay {
                    RoundedRectangle(cornerRadius: 64 * 0.22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Welcome to GestaltX"))
                    .font(.system(.title, design: .rounded).weight(.bold))
                Text(L("MobileGestalt Editor"))
                    .font(.subheadline.weight(.medium))
                    .opacity(0.85)
            }
        }
        .foregroundStyle(Color.white)
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous).fill(GestaltTheme.heroGradient)
                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 200, height: 200)
                    .offset(x: 130, y: -70)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .shadow(color: GestaltTheme.accentDeep.opacity(0.3), radius: 16, y: 8)
        .padding(.top, 8)
    }

    private func point(_ systemImage: String, _ tint: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconChip(systemName: systemImage, tint: tint, size: 30)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
