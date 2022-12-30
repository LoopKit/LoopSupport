//
//  LoopSupportUI.swift
//  LoopSupportKitUI
//
//  Created by Darin Krauss on 1/23/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation
import SwiftUI
import LoopKit
import LoopKitUI

public final class LoopSupportUI: SupportUI {

    public static var supportIdentifier: String = "LoopSupportUI"

    private var analytics = LoopKitAnalytics.shared

    public func checkVersion(bundleIdentifier: String, currentVersion: String, completion: @escaping (Result<VersionUpdate?, Error>) -> Void) { }
        
    public func softwareUpdateView(bundleIdentifier: String, currentVersion: String, guidanceColors: GuidanceColors, openAppStore: (() -> Void)?) -> AnyView? { nil }
    
    public init?(rawState: RawStateValue) {
        self.rawState = rawState
    }
    
    public var rawState: RawStateValue
    
    public init() {
        rawState = [:]
    }

    public func configurationMenuItems() -> [AnyView] {
        return [AnyView(NavigationLink("Usage Data Sharing") {
            UsageDataPrivacyPreferenceView(preference: analytics.usageDataPrivacyPreference, onboardingMode: false) { newValue in
                self.analytics.updateUsageDataPrivacyPreference(newValue: newValue)
            }
        })]
    }

    public func supportMenuItem(supportInfoProvider: SupportInfoProvider, urlHandler: @escaping (URL) -> Void) -> AnyView? {
        return AnyView(Button("Submit Bug Report", action: {
            let url = URL(string: "https://github.com/LoopKit/Loop/issues")!
            urlHandler(url)
        }))
    }
    
    public weak var delegate: SupportUIDelegate?
}

// LoopSupport also provides analytics
extension LoopSupportUI: AnalyticsService {
    public static var localizedTitle = LocalizedString("LoopKit Analytics", comment: "Title for LoopKit Analytics")

    public func recordAnalyticsEvent(_ name: String, withProperties properties: [AnyHashable : Any]?, outOfSession: Bool) {
        analytics.recordAnalyticsEvent(name, withProperties: properties, outOfSession: outOfSession)
    }

    public static var serviceIdentifier = "LoopKitAnalytics"

    public var serviceDelegate: LoopKit.ServiceDelegate? {
        get {
            return nil
        }
        set(newValue) {}
    }

    public var isOnboarded: Bool {
        return true
    }
}
