// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 huamidev
import SwiftUI

// MARK: - Tokens

/// Shared visual language for GestaltX.
///
/// The app is built from a small set of pieces: an ambient page background,
/// rounded "cards" on top of it, tinted icon chips and capsule badges. Every
/// screen composes these so spacing, corner radii and colors stay consistent.
enum GestaltTheme {
    /// Indigo-violet accent. The asset catalog's AccentColor mirrors this so
    /// stock iOS controls (toggles, text selection) match the custom chrome.
    static let accent = Color(red: 0.420, green: 0.306, blue: 0.941)
    static let accentBright = Color(red: 0.608, green: 0.400, blue: 0.965)
    static let accentDeep = Color(red: 0.235, green: 0.180, blue: 0.690)
    static let accentPink = Color(red: 0.882, green: 0.384, blue: 0.776)

    static let cardRadius: CGFloat = 22
    static let tileRadius: CGFloat = 20
    static let spacing: CGFloat = 14

    static let gradient = LinearGradient(
        colors: [accent, accentBright],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// The hero gradient used for the device card and the welcome header.
    static let heroGradient = LinearGradient(
        colors: [accentDeep, accent, accentPink],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// A soft tinted gradient for icon chips and headers.
    static func softGradient(_ color: Color = accent) -> LinearGradient {
        LinearGradient(colors: [color.opacity(0.24), color.opacity(0.10)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// A saturated gradient for filled icon chips.
    static func solidGradient(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color.opacity(0.92), color],
                       startPoint: .top, endPoint: .bottom)
    }

    static let positive = Color.green
    static let caution = Color.orange
    static let danger = Color.red
}

extension Color {
    static let gestaltAccent = GestaltTheme.accent
}

extension CapabilityCategory {
    /// Per-category tint used by the home grid and category headers.
    var tint: Color {
        switch self {
        case .display: Color(red: 0.200, green: 0.522, blue: 0.965)
        case .device: Color(red: 0.180, green: 0.698, blue: 0.588)
        case .ipad: Color(red: 0.965, green: 0.584, blue: 0.180)
        case .intelligence: GestaltTheme.accentBright
        case .advanced: Color(red: 0.937, green: 0.329, blue: 0.392)
        }
    }
}

extension PlistValueKind {
    var tint: Color {
        switch self {
        case .string: Color(red: 0.200, green: 0.522, blue: 0.965)
        case .integer, .real: Color(red: 0.180, green: 0.698, blue: 0.588)
        case .boolean: Color(red: 0.965, green: 0.584, blue: 0.180)
        case .data: Color(uiColor: .systemGray)
        case .date: Color(red: 0.176, green: 0.682, blue: 0.851)
        case .array, .dictionary: GestaltTheme.accentBright
        }
    }
}

// MARK: - Backgrounds and cards

/// Grouped background with a faint accent glow at the top of the page.
struct GXPageBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground)
            LinearGradient(
                colors: [GestaltTheme.accent.opacity(0.16), GestaltTheme.accentPink.opacity(0.05), .clear],
                startPoint: .top, endPoint: .bottom)
                .frame(height: 460)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct GXCardModifier: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
    }
}

extension View {
    /// Places the view on a rounded card surface.
    func gxCard(padding: CGFloat = 16, radius: CGFloat = GestaltTheme.cardRadius) -> some View {
        modifier(GXCardModifier(padding: padding, radius: radius))
    }

    /// Hides a List/Form's default background and shows the ambient page background.
    func gxListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background { GXPageBackground() }
    }
}

// MARK: - Buttons

/// Gentle press feedback for custom card buttons, dimming when disabled.
struct GXPressableStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? (configuration.isPressed ? 0.88 : 1) : 0.45)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GXPressableStyle {
    static var gxPressable: GXPressableStyle { GXPressableStyle() }
}

// MARK: - Headers

struct GXSectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Icon chips and badges

/// A rounded icon chip used in rows and tiles for a touch of depth.
struct IconChip: View {
    let systemName: String
    var tint: Color = GestaltTheme.accent
    var size: CGFloat = 30
    /// Filled chips use a saturated background with a white glyph.
    var filled = false

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(filled ? GestaltTheme.solidGradient(tint) : GestaltTheme.softGradient(tint))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(filled ? Color.white : tint)
            }
            .accessibilityHidden(true)
    }
}

/// A small tinted capsule label.
struct GXCapsule: View {
    let text: String
    var tint: Color = GestaltTheme.accent
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.caption2.weight(.bold)) }
            Text(text).font(.caption2.weight(.bold))
        }
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(0.15)))
        .foregroundStyle(tint)
    }
}

/// A status capsule with a colored dot, designed for dark/gradient surfaces.
struct StatusPill: View {
    let text: String
    let tint: Color
    var onGradient = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .shadow(color: tint.opacity(0.8), radius: 3)
            Text(text).font(.caption.weight(.semibold)).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(onGradient ? Color.white.opacity(0.18) : tint.opacity(0.14)))
        .foregroundStyle(onGradient ? Color.white : tint)
    }
}

/// A capsule showing a capability's real current state (On / Off / Custom),
/// read live from the previewed document, so menus are never "blind".
struct StateBadge: View {
    let state: CapabilityState

    private var tint: Color {
        switch state {
        case .on: GestaltTheme.positive
        case .off: Color(uiColor: .systemGray)
        case .custom: GestaltTheme.accent
        }
    }

    var body: some View {
        Text(L(state.title))
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.4)
            .lineLimit(1)
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

// MARK: - Tiles

/// A grid tile with an icon chip, a title and an optional subtitle.
struct GXTile: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    var tint: Color = GestaltTheme.accent
    /// Shown in the top-trailing corner instead of the chevron, e.g. a staged count.
    var badge: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                IconChip(systemName: systemImage, tint: tint, size: 38, filled: true)
                Spacer(minLength: 4)
                if let badge {
                    GXCapsule(text: badge, tint: GestaltTheme.accent, systemImage: "pencil")
                } else {
                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .flipsForRightToLeftLayoutDirection(true)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: subtitle == nil ? 96 : 122, alignment: .topLeading)
        .gxCard(padding: 14, radius: GestaltTheme.tileRadius)
        .contentShape(RoundedRectangle(cornerRadius: GestaltTheme.tileRadius, style: .continuous))
    }
}

/// A compact, centered action tile for the quick actions grid.
struct GXActionTile: View {
    let title: String
    let systemImage: String
    var tint: Color = GestaltTheme.accent

    var body: some View {
        VStack(spacing: 8) {
            IconChip(systemName: systemImage, tint: tint, size: 40)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .gxCard(padding: 12, radius: GestaltTheme.tileRadius)
        .contentShape(RoundedRectangle(cornerRadius: GestaltTheme.tileRadius, style: .continuous))
    }
}

/// A full-width navigation row card.
struct GXRowCard: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    var tint: Color = GestaltTheme.accent

    var body: some View {
        HStack(spacing: 14) {
            IconChip(systemName: systemImage, tint: tint, size: 38, filled: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Image(systemName: "chevron.forward")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .gxCard(padding: 14, radius: GestaltTheme.tileRadius)
        .contentShape(RoundedRectangle(cornerRadius: GestaltTheme.tileRadius, style: .continuous))
    }
}

/// A single statistic: a large value over a small caption.
struct GXStat: View {
    let value: String
    let label: String
    var tint: Color = .primary
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage).font(.headline)
                }
                Text(value)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A tinted inline notice.
struct GXBanner: View {
    let text: String
    var systemImage: String = "info.circle.fill"
    var tint: Color = GestaltTheme.accent
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(text).font(.footnote.weight(.medium)).foregroundStyle(.primary)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.12)))
    }
}

// MARK: - Values

/// A labelled, monospaced plist value block. Before/after pairs use a red and
/// a green tint so diffs read at a glance.
struct GXValueBlock: View {
    let title: String
    let value: Any?
    var tint: Color = Color(uiColor: .systemGray)

    private var text: String {
        value.map { PlistValueKind.detect($0).text(for: $0) } ?? L("Not present")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 6, height: 6)
                Text(L(title)).font(.caption2.weight(.bold)).textCase(.uppercase).foregroundStyle(tint)
                if let value {
                    Spacer(minLength: 4)
                    Text(L(PlistValueKind.detect(value).rawValue)).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(value == nil ? .secondary : .primary)
                .lineLimit(6)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.09)))
    }
}

/// Before → after comparison for one parameter.
struct GXValueDiff: View {
    var beforeTitle = "Before"
    var afterTitle = "After"
    let before: Any?
    let after: Any?

    var body: some View {
        VStack(spacing: 6) {
            GXValueBlock(title: beforeTitle, value: before, tint: GestaltTheme.danger)
            Image(systemName: "arrow.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            GXValueBlock(title: afterTitle, value: after, tint: GestaltTheme.positive)
        }
    }
}
