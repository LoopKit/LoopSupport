//
//  IssueReportContext.swift
//  LoopSupportKitUI
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import UIKit
import LoopKit
import LoopKitUI

enum IssueReportContext {
    /// Build, device and pump/CGM details sent with every issue report.
    @MainActor
    static func current(supportInfo: SupportInfoProvider?) -> [String: IssueReportContextValue] {
        let info = Bundle.main.infoDictionary ?? [:]
        let buildDetails = Bundle.main.url(forResource: "BuildDetails", withExtension: "plist")
            .flatMap { NSDictionary(contentsOf: $0) as? [String: Any] } ?? [:]

        var context: [String: IssueReportContextValue] = [
            "appVersion": .string(info["CFBundleShortVersionString"] as? String ?? ""),
            "buildNumber": .string(info["CFBundleVersion"] as? String ?? ""),
            "customizations": .strings(buildDetails["com-loopkit-Loop-customizations"] as? [String] ?? []),
            "deviceModel": .string(modelIdentifier),
            "osVersion": .string(UIDevice.current.systemVersion),
        ]
        let branch = buildDetails["com-loopkit-LoopWorkspace-git-branch"] as? String ?? buildDetails["com-loopkit-Loop-git-branch"] as? String
        context["branch"] = branch.map { .string($0) }
        context["workspaceRevision"] = (buildDetails["com-loopkit-LoopWorkspace-git-revision"] as? String).map { .string($0) }
        context["loopRevision"] = (buildDetails["com-loopkit-Loop-git-revision"] as? String).map { .string($0) }
        context["pumpModel"] = supportInfo?.pumpStatus.map { .string($0.device.model ?? "Unknown") }
        context["cgmModel"] = supportInfo?.cgmStatus.map { .string($0.device?.model ?? "Unknown") }
        return context
    }

    private static var modelIdentifier: String {
        #if targetEnvironment(simulator)
        return "\(UIDevice.current.model)Simulator"
        #else
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) { $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(validatingUTF8: $0) } } ?? "unknown"
        #endif
    }
}
