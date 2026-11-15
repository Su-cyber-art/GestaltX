// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 huamidev
import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var model: GestaltManager
    var body: some View {
        List {
            Section { hero }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            Section {
                Link(destination: GestaltBrand.projects) {
                    linkRow(L("GitHub Repository"), detail: GestaltBrand.repositoryName) { GitHubChip() }
                }
                Link(destination: GestaltBrand.releases) {
                    linkRow(L("Releases"), detail: "v" + GestaltBrand.version) {
                        IconChip(systemName: "shippingbox.fill", tint: GestaltTheme.accent, size: 32, filled: true)
                    }
                }
            }
            Section {
                LabeledContent {
                    GXCapsule(text: VersionSupport.range, tint: GestaltTheme.positive, systemImage: "checkmark.seal.fill")
                } label: {
                    Label { Text(L("Supported OS")) } icon: {
                        IconChip(systemName: "iphone.gen3", tint: GestaltTheme.positive, size: 32, filled: true)
                    }
                }
                NavigationLink { CompatibilityView() } label: {
                    Label { Text(L("Compatibility")) } icon: {
                        IconChip(systemName: "iphone.badge.checkmark", tint: Color(red: 0.200, green: 0.522, blue: 0.965), size: 32, filled: true)
                    }
                }
            }
            Section(L("Special Thanks")) {
                Link(destination: URL(string: "https://github.com/forcequitOS/worse_query")!) {
                    linkRow("worse_query", detail: "forcequitOS · Taj C") {
                        IconChip(systemName: "cpu", tint: GestaltTheme.accentPink, size: 32, filled: true)
                    }
                }
            }
            Section {
                NavigationLink { CreditsView() } label: {
                    Label { Text(L("Credits & Licenses")) } icon: {
                        IconChip(systemName: "text.book.closed.fill", tint: Color(uiColor: .systemGray), size: 32, filled: true)
                    }
                }
            } footer: {
                aboutFooter.padding(.top, 8)
            }
        }
        .gxListBackground()
        .listSectionSpacing(20)
        .safeAreaPadding(.bottom, 20)
        .navigationTitle(L("About"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GestaltTheme.heroGradient)
                    .frame(width: 150, height: 150)
                    .blur(radius: 46)
                    .opacity(0.55)
                BrandMark(size: 96)
                    .shadow(color: GestaltTheme.accent.opacity(0.35), radius: 18, y: 8)
            }
            .frame(height: 120)
            Text(verbatim: "GestaltX")
                .font(.system(.title, design: .rounded).weight(.bold))
            Text(L("MobileGestalt Editor"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                GXCapsule(text: "v\(GestaltBrand.version) (\(GestaltBrand.build))", tint: GestaltTheme.accent)
                GXCapsule(text: GestaltBrand.buildDate, tint: Color(uiColor: .systemGray), systemImage: "calendar")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func linkRow<Icon: View>(_ title: String, detail: String?, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 12) {
            icon()
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.primary)
                if let detail {
                    Text(verbatim: detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var aboutFooter: some View {
        let year = Calendar.current.component(.year, from: .now)
        return VStack(spacing: 6) {
            Text(L("Maintained by Su-cyber-art"))
                .foregroundStyle(.secondary)
            Text(L("Based on the original work by huamidev"))
                .foregroundStyle(.secondary.opacity(0.75))
            Text(verbatim: "© \(String(year)) \(GestaltBrand.originalAuthor) & contributors · GNU GPL v3")
                .foregroundStyle(.secondary.opacity(0.55))
        }
        .font(.caption)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// The GitHub mark on an inverted rounded chip.
private struct GitHubChip: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 32 * 0.3, style: .continuous)
            .fill(Color(uiColor: .label))
            .frame(width: 32, height: 32)
            .overlay {
                Image("GitHubMark").renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Color(uiColor: .systemBackground))
            }
            .accessibilityHidden(true)
    }
}

struct CreditsView: View {
    var body: some View {
        List {
            Section(L("License")) {
                NavigationLink { LicenseTextView(name: "GestaltX-GPL-3.0", title: "GNU GPL v3") } label: { Text("GNU GPL v3") }
            }
            Section(L("Credits")) {
                credit("NeoSpring", author: "rooootdev · neonmodder123 · skadz108", url: "https://github.com/rooootdev/neospring")
                credit("Ketamine", author: "Nouvborne", url: "https://github.com/Nouvborne/Ketamine")
                credit("MGKeys", author: "PoomSmart", url: "https://github.com/PoomSmart/MGKeys")
                credit("Nugget", author: "leminlimez", url: "https://github.com/leminlimez/Nugget")
                credit("GestaltEdit", author: "frs0n", url: "https://github.com/frs0n/GestaltEdit")
                licensedCredit("Gester", author: "sasobhabha · KAMUI contributors", license: "MIT", file: "Gester-MIT", url: "https://github.com/sasobhabha/Gester")
                licensedCredit("Erosion", author: "lunginspector · jailbreak.party", license: "GPL v3", file: "Erosion-GPL-3.0", url: "https://github.com/jailbreakdotparty/Erosion")
                licensedCredit("ZIPFoundation", author: "Thomas Zoechling", license: "MIT", file: "ZIPFoundation-MIT", url: "https://github.com/weichsel/ZIPFoundation")
                licensedCredit("AirCard-iOS", author: "Johnny Franks", license: "MIT", file: "AirCard-MIT", url: "https://github.com/Mak5er/AirCard-iOS")
                licensedCredit("idevice", author: "Jackson Coxson", license: "MIT", file: "idevice-MIT", url: "https://github.com/jkcoxson/idevice")
            }
        }
        .gxListBackground()
        .navigationTitle(L("Credits & Licenses"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func credit(_ project: String, author: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            LabeledContent { Text(author).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.trailing) }
                label: { Text(project).foregroundStyle(.primary) }
        }
    }
    private func licensedCredit(_ project: String, author: String, license: String, file: String, url: String) -> some View {
        NavigationLink { LicenseTextView(name: file, title: project + " · " + license, source: URL(string: url)) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(project)
                    Text(author).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(license).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
struct CompatibilityView: View {
    var body: some View {
        List {
            Section(L("worse_query")) {
                Text(VersionSupport.range).font(.headline)
                LabeledContent("iOS 26.x", value: L("Unsupported"))
                Text(L("Available paths and MobileGestalt presets vary by device and OS build."))
                    .font(.subheadline).foregroundStyle(.secondary)
                Link(L("Read Upstream Compatibility"), destination: URL(string: "https://github.com/forcequitOS/worse_query")!)
            }
            Section(L("NeoSpring")) {
                Text(L("NeoSpring attempts a SpringBoard refresh using WebKit. Its effectiveness varies by OS build. Some MobileGestalt changes may still need a manual device restart."))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .gxListBackground()
        .navigationTitle(L("Compatibility"))
    }
}
struct LicenseTextView: View {
    let name: String
    let title: String
    var source: URL? = nil
    private var paragraphs: [String] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [L("License text could not be loaded.")] }
        // GPL's source text is wrapped at fixed columns. Reflow paragraphs for a phone screen.
        return text.components(separatedBy: "\n\n").map { paragraph in
            paragraph.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        }.filter { !$0.isEmpty }
    }
    private func isHeading(_ text: String) -> Bool {
        (text.count < 90 && text == text.uppercased()) || text == "Preamble"
            || text.range(of: #"^\d+\. [A-Z]"#, options: .regularExpression) != nil
            || text == "How to Apply These Terms to Your New Programs"
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(isHeading(paragraph) ? .headline : .body)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .textSelection(.enabled)
            .environment(\.layoutDirection, .leftToRight)
            .padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
        }
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let source {
                ToolbarItem(placement: .topBarTrailing) {
                    Link(destination: source) {
                        Image("GitHubMark").renderingMode(.template).resizable().scaledToFit().frame(width: 22, height: 22)
                    }.accessibilityLabel(L("GitHub Repository"))
                }
            }
        }
    }
}
