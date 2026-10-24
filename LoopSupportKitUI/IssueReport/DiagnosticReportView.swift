//
//  DiagnosticReportView.swift
//  LoopSupportKitUI
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import SwiftUI

/// Shows the diagnostic report as text, with a button to share it as a file.
struct DiagnosticReportView: View {
    let generateReport: () async -> String

    @State private var report: String?
    @State private var reportFile: ReportFile?

    private struct ReportFile: Identifiable {
        let url: URL
        let name: String
        var id: URL { url }
    }

    var body: some View {
        Group {
            if let report {
                ReportTextView(text: report)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ProgressView(LocalizedString("Preparing Report…", comment: "Shown while the diagnostic report is generated"))
            }
        }
        .navigationTitle(LocalizedString("Diagnostic Report", comment: "Title of the diagnostic report viewer"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: share) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(LocalizedString("Share", comment: "Button to share the diagnostic report"))
                .disabled(report == nil)
            }
        }
        .sheet(item: $reportFile, onDismiss: removeReportFile) { file in
            ActivityView(activityItems: [ReportItem(url: file.url, subject: file.name)])
        }
        .task {
            if report == nil {
                report = "Generated: \(Date())\n\n" + (await generateReport())
            }
        }
    }

    private func share() {
        guard let report else {
            return
        }
        let name = "Loop Report \(ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withSpaceBetweenDateAndTime, .withInternetDateTime])).md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name.replacingOccurrences(of: ":", with: "-"))
        if (try? report.write(to: url, atomically: true, encoding: .utf8)) != nil {
            reportFile = ReportFile(url: url, name: name)
        }
    }

    private func removeReportFile() {
        if let url = reportFile?.url {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// A UITextView keeps scrolling smooth for reports of several hundred kilobytes
private struct ReportTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.dataDetectorTypes = []
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .monospacedSystemFont(ofSize: 12, weight: .regular))
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.text = text
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
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

// Supplies the report name as the subject, e.g. for Mail
private final class ReportItem: NSObject, UIActivityItemSource {
    let url: URL
    let subject: String

    init(url: URL, subject: String) {
        self.url = url
        self.subject = subject
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        subject
    }
}
