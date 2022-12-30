//
//  LoopKitAnalytics.swift
//  LoopSupportKitUI
//
//  Created by Pete Schwamb on 12/29/22.
//

import Amplitude
import LoopKit

public enum UsageDataPrivacyPreference: String {
    case noSharing
    case shareInstallationStatsOnly
    case shareUsageDetailsWithDevelopers
}

public class LoopKitAnalytics {

    static public let shared = LoopKitAnalytics()

    private var client: Amplitude?

    public private(set) var usageDataPrivacyPreference: UsageDataPrivacyPreference {
        get {
            return UserDefaults.standard.usageDataPrivacyPreference
        }
        set {
            let oldValue = usageDataPrivacyPreference

            guard newValue != oldValue else {
                return
            }

            UserDefaults.standard.usageDataPrivacyPreference = newValue

            if newValue == .noSharing {
                client = nil
            } else if oldValue == .noSharing {
                createClient()
            }
        }
    }

    public func updateUsageDataPrivacyPreference(newValue: UsageDataPrivacyPreference) {
        usageDataPrivacyPreference = newValue
    }

    public init() {
        createClient()
    }

    private func createClient() {
        guard usageDataPrivacyPreference != .noSharing else {
            return
        }
        let amplitude = Amplitude()
        amplitude.setTrackingOptions(AMPTrackingOptions().disableCity().disableCarrier().disableIDFA().disableLatLng())
        amplitude.initializeApiKey("7dd7414785560c0dd1ef802ac10c00b4")
        client = amplitude
        client?.logEvent("LoopKitAnalytics instantiation")
    }

    public func recordAnalyticsEvent(_ name: String, withProperties properties: [AnyHashable : Any]?, outOfSession: Bool) {
        if usageDataPrivacyPreference == .shareUsageDetailsWithDevelopers {
            client?.logEvent(name, withEventProperties: properties, outOfSession: outOfSession)
        }
    }

}

extension UserDefaults {

    private enum Key: String {
        case UsageDataPrivacyPreference = "com.loopkit.Loop.UsageDataPrivacyPreference"
    }

    // Information for the extension from Loop
    var usageDataPrivacyPreference: UsageDataPrivacyPreference {
        get {
            if let rawValue = string(forKey: Key.UsageDataPrivacyPreference.rawValue),
               let preference = UsageDataPrivacyPreference(rawValue: rawValue)
            {
                return preference
            } else {
                return .shareInstallationStatsOnly
            }
        }
        set {
            set(newValue.rawValue, forKey: Key.UsageDataPrivacyPreference.rawValue)
        }
    }
}

