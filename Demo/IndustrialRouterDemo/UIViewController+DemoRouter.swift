import UIKit
import IndustrialRouter

extension UIViewController {
    var demoRouter: IndustrialRouterCoordinator? {
        guard let scene = view.window?.windowScene else { return nil }
        return RouterSceneCoordinatorStore.shared.coordinator(for: scene)
    }
}

