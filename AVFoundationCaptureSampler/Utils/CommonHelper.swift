import Foundation

var appVersion: String {
    guard let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    else { return "" }
    return appVersion
}

var appBuildNumber: String {
    guard let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    else { return "" }
    return buildNumber
}
