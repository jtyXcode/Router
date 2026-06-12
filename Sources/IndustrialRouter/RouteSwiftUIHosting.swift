import UIKit

#if canImport(SwiftUI)
import SwiftUI

// MARK: - SwiftUI Hosting Registration

@available(iOS 13.0, *)
public extension RouteViewControllerRegistry {
    func registerHosting<Content: View>(
        _ path: any RoutePath,
        builder: @escaping (RouteContext) -> Content
    ) {
        register(path) { context in
            UIHostingController(rootView: builder(context))
        }
    }

    func registerHosting<Content: View>(
        _ routeKey: String,
        builder: @escaping (RouteContext) -> Content
    ) {
        register(routeKey) { context in
            UIHostingController(rootView: builder(context))
        }
    }
}
#endif
