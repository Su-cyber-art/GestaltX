// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 huamidev
import SwiftUI

/// Shared visual language for GestaltX: an indigo-violet accent with a subtle
/// depth gradient, plus the small state components reused across the parameter
/// screens so the current value is always visible without opening a menu.
enum GestaltTheme {
    /// Indigo-violet accent. The asset catalog's AccentColor mirrors this so
    /// stock iOS controls (toggles, text selection) match the custom chrome.
    static let accent = Color(red: 0.420, green: 0.306, blue: 0.941)
    static let accentBright = Color(red: 0.608, green: 0.400, blue: 0.965)

    static let gradient = LinearGradient(
        colors: [accent, accentBright],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// A soft tinted gradient for icon chips and headers.
    static func softGradient(_ color: Color = accent) -> LinearGradient {
        LinearGradient(colors: [color.opacity(0.22), color.opacity(0.10)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    static let gestaltAccent = GestaltTheme.accent
}

/// A capsule showing a capability's real current state (On / Off / Custom),
/// read live from the previewed document. This is what makes the menus no
/// longer "blind": the resolved value is shown on the row's trailing edge.
struct StateBadge: View {
    let state: CapabilityState

    private var tint: Color {
        switch state {
        case .on: .green
        case .off: Color(uiColor: .systemGray)
        case .custom: GestaltTheme.accent
        }
    }

    var body: some View {
        Text(L(state.title))
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.4)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint.opacity(0.16)))
            .foregroundStyle(tint)
            .accessibilityLabel(L(state.title))
    }
}

/// Trailing accessory for a capability row: the current state, plus a pencil
/// mark when an edit is staged that will change it.
struct CapabilityStatusView: View {
    let current: CapabilityState
    let isStaged: Bool

    var body: some View {
        HStack(spacing: 6) {
            StateBadge(state: current)
            if isStaged {
                Image(systemName: "pencil.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(GestaltTheme.accent)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A rounded icon chip used in section rows for a touch of depth.
struct IconChip: View {
    let systemName: String
    var tint: Color = GestaltTheme.accent
    var size: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(GestaltTheme.softGradient(tint))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)
    }
}
