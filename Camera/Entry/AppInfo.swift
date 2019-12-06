//
//  AppInfo.swift
//  Camera
//
//  Created by WON on 27/09/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import Foundation

enum AppInfo {

    static let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    static let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    static let bundleVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    static let versionAndBuild: String = "\(AppInfo.shortVersion ?? "")(\(AppInfo.bundleVersion ?? ""))"
    static let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(Bundle.main.bundleIdentifier ?? "")")

    static func saveVersionStringForSettingBundle() {
        let defaults = UserDefaults.standard
        defaults.setValue(AppInfo.versionAndBuild, forKey: "appVersion")
        defaults.synchronize()
    }

    /// To get AppStore version string
    static func appStoreVersion(completion: @escaping (String?) -> Void) {
        let task = URLSession.shared.dataTask(with: AppInfo.url!) { data, _, _ in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]

                if
                    let json = json,
                    let result = (json["results"] as? [Any])?.first as? [String: Any],
                    let version = result["version"] as? String {
                    completion(version)
                }
            }
        }
        task.resume()
    }
}
