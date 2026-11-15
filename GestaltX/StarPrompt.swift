// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UIKit
import Combine

/// A lightweight, App Store-style "enjoying the app?" prompt that asks for a
/// GitHub star. It never appears on the first launch, waits five seconds after
/// launch, and can be postponed or disabled permanently.
@MainActor
final class StarPromptController: ObservableObject {
    static let shared = StarPromptController()

    @Published var isPresented = false

    private let defaults = UserDefaults.standard
    private var didSchedule = false
    private let repositoryURL = GestaltBrand.projects

    private enum Key {
        static let state = "GestaltX.starPrompt.state"
    }

    private var state: String? { defaults.string(forKey: Key.state) }

    func startIfEligible() {
        guard !didSchedule else { return }
        didSchedule = true
        guard state == nil else { return }
        Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            // This prompt is shown at most once for the lifetime of the install.
            defaults.set("shown", forKey: Key.state)
            isPresented = true
        }
    }

    func star() {
        defaults.set("starred", forKey: Key.state)
        isPresented = false
        UIApplication.shared.open(repositoryURL)
    }

    func sheetDismissed() {
        isPresented = false
    }
}

struct StarPromptView: View {
    @ObservedObject var controller: StarPromptController

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(GestaltTheme.heroGradient)
                        .frame(width: 120, height: 120)
                        .blur(radius: 30)
                        .opacity(0.5)
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color(red: 1.0, green: 0.82, blue: 0.29), .orange],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: .orange.opacity(0.4), radius: 12, y: 6)
                    Image(systemName: "star.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(height: 96)

                VStack(spacing: 7) {
                    Text(L("Enjoying GestaltX?"))
                        .font(.title2.bold())
                    Text(L("If GestaltX is useful to you, a GitHub star helps a lot."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 30)

            Spacer(minLength: 18)

            VStack(spacing: 10) {
                Button {
                    controller.star()
                } label: {
                    Label(L("Star on GitHub"), systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(GestaltTheme.gradient))
                        .contentShape(Capsule())
                }
                .buttonStyle(.gxPressable)
            }
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
