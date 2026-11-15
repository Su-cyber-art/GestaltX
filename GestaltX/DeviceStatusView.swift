// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

private struct DeviceStatusReadingRows: View {
    @EnvironmentObject private var model: GestaltManager

    var body: some View {
        if let error = model.deviceStatusError {
            VStack(alignment: .leading, spacing: 4) {
                Label(L("Read failed. Showing the last successful reading."), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(error).font(.caption).foregroundStyle(.secondary)
            }
        }
        if let reading = model.deviceStatus {
            LabeledContent(L("One-Click Unlock Configuration")) {
                if model.deviceStatusError == nil, let configured = reading.report.unlockConfigured {
                    GXCapsule(text: L(configured ? "Fully Configured" : "Not Fully Configured"),
                              tint: configured ? GestaltTheme.positive : Color(uiColor: .systemGray),
                              systemImage: configured ? "checkmark.seal.fill" : "seal")
                } else {
                    Text(L("Unavailable")).foregroundStyle(.secondary)
                }
            }
            LabeledContent(L("Last Read")) {
                Text(reading.readAt, format: .dateTime.hour().minute().second())
                    .foregroundStyle(.secondary)
            }
            if !reading.report.hasRecordedOriginals {
                Text(L("No recorded originals yet.")).font(.caption).foregroundStyle(.secondary)
            }
            if !reading.report.issues.isEmpty {
                Text(L("Some parameters could not be compared.")).font(.caption).foregroundStyle(.orange)
            }
        } else {
            Text(L("Reading…")).foregroundStyle(.secondary)
        }
    }
}

struct DeviceStatusView: View {
    @EnvironmentObject private var model: GestaltManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(L("Current Modification Status")) {
                DeviceStatusReadingRows()
            }
            if let reading = model.deviceStatus {
                Section {
                    if reading.report.changes.isEmpty {
                        if !reading.report.hasRecordedOriginals {
                            Text(L("No recorded originals yet."))
                        } else if reading.report.issues.isEmpty {
                            Text(L("Matches recorded originals."))
                        } else {
                            Text(L("Some parameters could not be compared."))
                        }
                    } else {
                        ForEach(reading.report.changes) { change in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L(change.title)).font(.subheadline.weight(.semibold))
                                Text(change.key).font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary).textSelection(.enabled)
                                GXValueDiff(beforeTitle: "Original Value", afterTitle: "Current Value",
                                            before: change.original, after: change.current)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text(L("Modified Parameters"))
                } footer: {
                    Text(L("Only parameters with recorded original values can be checked for modifications."))
                }
                if !reading.report.issues.isEmpty {
                    Section {
                        ForEach(reading.report.issues) { issue in
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L(issue.title)).fontWeight(.semibold)
                                    Text(issue.message).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(GestaltTheme.caution)
                            }
                        }
                    }
                }
            }
            if model.changeCount > 0 {
                Section(L("Pending Changes")) {
                    LabeledContent(L("Pending Changes"), value: String(model.changeCount))
                    NavigationLink(L("Review Changes")) { ChangeReviewView(isSheet: false) }
                }
            }
        }
        .gxListBackground()
        .navigationTitle(L("Modified Parameters"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.sourceIsDevice) { _, isDevice in
            if !isDevice { dismiss() }
        }
        .refreshable { await model.refreshDeviceStatus() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await model.refreshDeviceStatus() } } label: {
                    Label(L("Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(model.isBusy)
                .accessibilityIdentifier("refresh-device-status")
            }
        }
    }
}
