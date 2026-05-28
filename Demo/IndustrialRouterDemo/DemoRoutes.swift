import Foundation
import IndustrialRouter

enum DemoRoute: String, RoutePath {
    case home = "demo://home"
    case detail = "demo://goods/detail"
    case login = "demo://login"
    case protectedCenter = "demo://protected/center"
    case modal = "demo://modal"
    case intermediate = "demo://intermediate"
    case success = "demo://success"
    case popTest = "demo://pop/test"
    case popToTargetLevelOne = "demo://pop-to-target/level-one"
    case popToTargetLevelTwo = "demo://pop-to-target/level-two"
    case popRootLevelOne = "demo://pop-root/level-one"
    case popRootLevelTwo = "demo://pop-root/level-two"

    var stringValue: String {
        rawValue
    }
}

final class DemoSession {
    static let shared = DemoSession()
    var isLoggedIn = false

    private init() {}
}
