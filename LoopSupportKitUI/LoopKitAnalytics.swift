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

    private var identifiedProperties: [String: NSObject] = [:]

    public private(set) var usageDataPrivacyPreference: UsageDataPrivacyPreference? {
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

            resendIdentifiedProperties()
        }
    }

    public func updateUsageDataPrivacyPreference(newValue: UsageDataPrivacyPreference) {
        usageDataPrivacyPreference = newValue
    }

    public init() {
        if UserDefaults.standard.usageDataPrivacyPreference == nil {
            UserDefaults.standard.usageDataPrivacyPreference = .shareInstallationStatsOnly
        }
        createClient()
    }

    private func createClient() {
#if targetEnvironment(simulator)
        return
#else
        guard let usageDataPrivacyPreference = usageDataPrivacyPreference, usageDataPrivacyPreference != .noSharing else {
            return
        }
        let amplitude = Amplitude()
        amplitude.setTrackingOptions(AMPTrackingOptions().disableCity().disableCarrier().disableIDFA().disableLatLng().disableIPAddress().disableRegion())
        amplitude.initializeApiKey("7dd7414785560c0dd1ef802ac10c00b4")
        client = amplitude
        client?.logEvent("LoopKitAnalytics instantiation", withEventProperties: buildProperties)
#endif
    }

    private var buildProperties: [String: Any] {
        var properties: [String: Any] = [:]
        properties["buildNumber"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        guard let url = Bundle.main.url(forResource: "BuildDetails", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let details = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return properties
        }
        properties["workspaceBranch"] = details["com-loopkit-LoopWorkspace-git-branch"]
        properties["workspaceRevision"] = details["com-loopkit-LoopWorkspace-git-revision"]
        properties["loopBranch"] = details["com-loopkit-Loop-git-branch"]
        properties["loopRevision"] = details["com-loopkit-Loop-git-revision"]
        properties["customizations"] = details["com-loopkit-Loop-customizations"]
        return properties
    }

    public func recordAnalyticsEvent(_ name: String, withProperties properties: [AnyHashable : Any]?, outOfSession: Bool) {
        if usageDataPrivacyPreference == .shareUsageDetailsWithDevelopers {
            client?.logEvent(name, withEventProperties: properties, outOfSession: outOfSession)
        }
    }

    public func recordIdentify(_ property: String, value: String) {
        recordIdentify(property, object: value as NSString)
    }

    public func recordIdentify(_ property: String, array: [String]) {
        recordIdentify(property, object: array as NSArray)
    }

    private func recordIdentify(_ property: String, object: NSObject) {
        identifiedProperties[property] = object
        if usageDataPrivacyPreference == .shareUsageDetailsWithDevelopers {
            client?.identify(AMPIdentify().set(property, value: object))
        }
    }

    private func resendIdentifiedProperties() {
        guard usageDataPrivacyPreference == .shareUsageDetailsWithDevelopers, let client, !identifiedProperties.isEmpty else {
            return
        }
        let identify = AMPIdentify()
        for (property, object) in identifiedProperties {
            identify.set(property, value: object)
        }
        client.identify(identify)
    }

}

extension UserDefaults {

    private enum Key: String {
        case UsageDataPrivacyPreference = "com.loopkit.Loop.UsageDataPrivacyPreference"
    }

    // Information for the extension from Loop
    var usageDataPrivacyPreference: UsageDataPrivacyPreference? {
        get {
            if let rawValue = string(forKey: Key.UsageDataPrivacyPreference.rawValue),
               let preference = UsageDataPrivacyPreference(rawValue: rawValue)
            {
                return preference
            } else {
                return nil
            }
        }
        set {
            set(newValue?.rawValue, forKey: Key.UsageDataPrivacyPreference.rawValue)
        }
    }
}

