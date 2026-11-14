// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct DeviceStatusSection: View {
    @EnvironmentObject private var model: GestaltManager

    var body: some View {
        Section {
            DeviceStatusReadingRows()
            NavigationLink {
                DeviceStatusView()
            } label: {
                HStack {
                    Text(L("Modified Parameters"))
                    Spacer()
                    if let reading = model.deviceStatus {
                        Text(reading.report.hasRecordedOriginals ? String(reading.report.changes.count) : L("Unavailable"))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            LabeledContent(L("Pending Changes"), value: String(model.changeCount))
        } header: {
            Text(L("Current Modification Status"))
        } footer: {
            Text(L("Automatically reads the device every 5 seconds while the app is active. Pending edits are excluded."))
        }
    }
}

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
                    Text(L(configured ? "Fully Configured" : "Not Fully Configured"))
                        .foregroundStyle(configured ? Color.green : Color.secondary)
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
                                Text(L(change.title)).fontWeight(.semibold)
                                Text(change.key).font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary).textSelection(.enabled)
                                valueRow("Original Value", value: change.original)
                                valueRow("Current Value", value: change.current)
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L(issue.title)).fontWeight(.semibold)
                                Text(issue.message).font(.caption).foregroundStyle(.secondary)
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

    private func valueRow(_ title: String, value: Any?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L(title)).font(.caption).foregroundStyle(.secondary)
            Text(value.map { PlistValueKind.detect($0).text(for: $0) } ?? L("Not present"))
                .font(.system(.caption, design: .monospaced)).lineLimit(6).textSelection(.enabled)
        }
    }
}
