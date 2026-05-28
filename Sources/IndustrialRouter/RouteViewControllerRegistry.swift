import UIKit

// MARK: - View Controller Registry

public final class RouteViewControllerRegistry {
    public static let shared = RouteViewControllerRegistry()

    public typealias Builder = (RouteContext) -> UIViewController

    private let lock = NSLock()
    private var builders: [String: Builder] = [:]

    private init() {}

    public func register(_ path: any RoutePath, builder: @escaping Builder) {
        register(path.stringValue, builder: builder)
    }

    public func register(_ routeKey: String, builder: @escaping Builder) {
        lock.lock()
        builders[routeKey.lowercased()] = builder
        lock.unlock()
    }

    public func removeAll() {
        lock.lock()
        builders.removeAll()
        lock.unlock()
    }

    public func makeViewController(path: any RoutePath, params: [String: Any]?) -> UIViewController? {
        lock.lock()
        let builder = builders[path.stringValue.lowercased()]
        lock.unlock()

        return builder?(RouteContext(path: path, params: params))
    }
}
