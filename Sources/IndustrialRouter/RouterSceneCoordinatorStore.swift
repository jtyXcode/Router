import UIKit

/// Keeps one router coordinator per UIWindowScene.
///
/// Use this in multi-window apps instead of routing through
/// `IndustrialRouterCoordinator.shared`.
public final class RouterSceneCoordinatorStore {
    public static let shared = RouterSceneCoordinatorStore()

    private var coordinators: [String: IndustrialRouterCoordinator] = [:]
    private let lock = NSLock()

    private init() {}

    public func coordinator(for scene: UIWindowScene) -> IndustrialRouterCoordinator {
        let key = scene.session.persistentIdentifier

        lock.lock()
        defer { lock.unlock() }

        if let coordinator = coordinators[key] {
            return coordinator
        }

        let coordinator = IndustrialRouterCoordinator()
        coordinators[key] = coordinator
        return coordinator
    }

    @discardableResult
    public func setup(
        rootNavigationController: UINavigationController,
        for scene: UIWindowScene
    ) -> IndustrialRouterCoordinator {
        let coordinator = coordinator(for: scene)
        coordinator.setup(rootNavigationController: rootNavigationController)
        return coordinator
    }

    public func removeCoordinator(for scene: UIWindowScene, result: Any? = nil) {
        removeCoordinator(forSceneIdentifier: scene.session.persistentIdentifier, result: result)
    }

    func coordinator(forSceneIdentifier identifier: String) -> IndustrialRouterCoordinator {
        lock.lock()
        defer { lock.unlock() }

        if let coordinator = coordinators[identifier] {
            return coordinator
        }

        let coordinator = IndustrialRouterCoordinator()
        coordinators[identifier] = coordinator
        return coordinator
    }

    func removeCoordinator(forSceneIdentifier identifier: String, result: Any? = nil) {
        lock.lock()
        let coordinator = coordinators.removeValue(forKey: identifier)
        lock.unlock()

        coordinator?.cancelPendingRoutes(result: result)
    }
}
