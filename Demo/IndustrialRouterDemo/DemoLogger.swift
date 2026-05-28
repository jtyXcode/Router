import Foundation

enum DemoLogger {
    static let notificationName = Notification.Name("IndustrialRouterDemoLoggerDidAppend")

    static func log(_ message: String) {
        let line = "[\(timestamp)] \(message)"
        print(line)
        NotificationCenter.default.post(name: notificationName, object: line)
    }

    private static var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}

