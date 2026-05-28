import UIKit
import Combine

// MARK: - Route Contracts

/// Route presentation style.
public enum RouterNavigationType {
    /// Push into the active navigation stack.
    /// When `popCurrent` is true, the source page is removed after the push animation finishes.
    case push(popCurrent: Bool = false, animated: Bool = true)

    /// Present modally. By default the destination is wrapped in a fresh UINavigationController
    /// so routes inside the modal flow continue to push within that modal stack.
    case modal(
        style: UIModalPresentationStyle = .fullScreen,
        wrapInNavigation: Bool = true,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    )
}

/// Business route identity. App modules normally implement this with enums.
public protocol RoutePath {
    var stringValue: String { get }
}

/// Global route interception result.
public enum RouteInterceptResult {
    case allowed
    case rejected
    case redirected(path: any RoutePath, type: RouterNavigationType, params: [String: Any]?)
}

/// Custom transition provider for push and modal animations.
public protocol RouteTransitionProvider: UIViewControllerAnimatedTransitioning {}

/// Optional provider that can return different animation controllers for push and pop.
public protocol RouteNavigationTransitionProvider: RouteTransitionProvider {
    func animationController(for operation: UINavigationController.Operation) -> UIViewControllerAnimatedTransitioning?
}

public struct RouteContext {
    public let path: any RoutePath
    public let params: [String: Any]?

    public init(path: any RoutePath, params: [String: Any]?) {
        self.path = path
        self.params = params
    }
}
