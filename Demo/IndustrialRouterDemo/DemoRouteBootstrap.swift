import UIKit
import IndustrialRouter

enum DemoRouteBootstrap {
    private static var didRegister = false

    static func registerRoutesIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        RouteViewControllerRegistry.shared.register(DemoRoute.home) { _ in
            HomeViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.detail) { context in
            DetailViewController(
                itemId: context.params?["itemId"] as? String,
                source: context.params?["source"] as? String
            )
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.login) { context in
            LoginViewController(reason: context.params?["reason"] as? String)
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.protectedCenter) { _ in
            ProtectedCenterViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.modal) { context in
            ModalViewController(message: context.params?["message"] as? String)
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.intermediate) { _ in
            IntermediateViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.success) { _ in
            SuccessViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.popTest) { _ in
            PopTestViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.popToTargetLevelOne) { _ in
            PopToTargetLevelOneViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.popToTargetLevelTwo) { _ in
            PopToTargetLevelTwoViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.popRootLevelOne) { _ in
            PopRootLevelOneViewController()
        }

        RouteViewControllerRegistry.shared.register(DemoRoute.popRootLevelTwo) { _ in
            PopRootLevelTwoViewController()
        }

        DeepLinkParser.register("goods/detail") { query in
            (
                DemoRoute.detail,
                [
                    "itemId": query["itemId"] ?? "missing",
                    "source": query["source"] ?? "deeplink"
                ]
            )
        }
    }
}
