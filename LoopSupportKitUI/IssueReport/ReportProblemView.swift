//
//  ReportProblemView.swift
//  LoopSupportKitUI
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct ReportProblemView: View {
    let delegate: SupportUIDelegate?

    @State private var isPreparingReport = false
    @State private var reportFile: ReportFile?
    @State private var writtenReportURL: URL?

    private struct ReportFile: Identifiable {
        let url: URL
        var id: URL { url }
    }

    var body: some View {
        List {
            Section {
                NavigationLink(destination: SendIssueReportView(
                    context: IssueReportContext.current(supportInfo: delegate),
                    generateDiagnosticReport: delegate.map { delegate in { await delegate.generateIssueReport() } }
                )) {
                    option(
                        LocalizedString("Send to the Loop Developers", comment: "Report a problem option: submit an issue report to the developers"),
                        detail: LocalizedString("Private. Describe the problem and attach screenshots and a diagnostic report. Only the LoopKit development team can see it.", comment: "Report a problem option detail: submit an issue report to the developers")
                    )
                }

                if delegate != nil {
                    Button(action: shareDiagnosticReport) {
                        HStack {
                            option(
                                LocalizedString("Share a Diagnostic Report", comment: "Report a problem option: share the diagnostic report yourself"),
                                detail: LocalizedString("Save the report or send it to someone helping you, for example on Zulip or Facebook. It contains health data such as glucose, insulin, carbs and your therapy settings.", comment: "Report a problem option detail: share the diagnostic report yourself")
                            )
                            if isPreparingReport {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isPreparingReport)
                }

                Button(action: { delegate?.openURL(url: URL(string: "https://github.com/LoopKit/Loop/issues")!) }) {
                    option(
                        LocalizedString("Open a GitHub Issue", comment: "Report a problem option: open the public GitHub issues page"),
                        detail: LocalizedString("Public. For bugs you can describe without any personal or health data.", comment: "Report a problem option detail: open the public GitHub issues page")
                    )
                }

                if let delegate {
                    NavigationLink(destination: delegate.criticalEventLogExportView()) {
                        option(
                            LocalizedString("Export Critical Event Logs", comment: "Report a problem option: export the critical event logs"),
                            detail: LocalizedString("Detailed logs as files. Only needed when a developer asks for them.", comment: "Report a problem option detail: export the critical event logs")
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizedString("Report a Problem", comment: "Title of the report a problem screen"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $reportFile, onDismiss: removeReportFile) { file in
            ActivityView(activityItems: [file.url])
        }
    }

    private func option(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(.primary)
            Text(detail)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func shareDiagnosticReport() {
        guard let delegate else {
            return
        }
        isPreparingReport = true
        Task { @MainActor in
            let date = Date()
            let report = "Generated: \(date)\n\n" + (await delegate.generateIssueReport())
            let name = "Loop Report \(ISO8601DateFormatter.string(from: date, timeZone: .current, formatOptions: [.withSpaceBetweenDateAndTime, .withInternetDateTime])).md"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name.replacingOccurrences(of: ":", with: "-"))
            do {
                try report.write(to: url, atomically: true, encoding: .utf8)
                writtenReportURL = url
                reportFile = ReportFile(url: url)
            } catch {
                reportFile = nil
            }
            isPreparingReport = false
        }
    }

    private func removeReportFile() {
        if let url = writtenReportURL {
            try? FileManager.default.removeItem(at: url)
        }
        writtenReportURL = nil
    }
}

struct ReportProblemMenuItem: View {
    let support: LoopSupportUI

    var body: some View {
        NavigationLink(destination: ReportProblemView(delegate: support.delegate)) {
            Text(LocalizedString("Report a Problem", comment: "The title text for the report a problem menu item"))
        }
    }
}

/// Report a Problem shown on its own, outside settings.
struct ReportProblemModal: View {
    let delegate: SupportUIDelegate?

    @Environment(\.dismissAction) private var dismiss

    var body: some View {
        NavigationView {
            ReportProblemView(delegate: delegate)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedString("Done", comment: "Button to close the report a problem screen"), action: dismiss)
                    }
                }
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension SupportInfoProvider {
    func generateIssueReport() async -> String {
        await withCheckedContinuation { continuation in
            generateIssueReport { continuation.resume(returning: $0) }
        }
    }
}
