import UIKit
import Combine
import IndustrialRouter

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        DemoRouteBootstrap.registerRoutesIfNeeded()

        let home = HomeViewController()
        let nav = DemoNavigationController(rootViewController: home)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window

        let router = RouterSceneCoordinatorStore.shared.setup(rootNavigationController: nav, for: windowScene)
        configureInterceptor(router)

        DemoLogger.log("Scene connected: \(session.persistentIdentifier)")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        RouterSceneCoordinatorStore.shared.removeCoordinator(for: windowScene, result: nil)
    }

    private func configureInterceptor(_ router: IndustrialRouterCoordinator) {
        router.interceptor = { path, params in
            if path.stringValue == DemoRoute.protectedCenter.stringValue,
               !DemoSession.shared.isLoggedIn {
                DemoLogger.log("Interceptor redirected protected route to login.")
                return Just(.redirected(path: DemoRoute.login, type: .modal(), params: ["reason": "login_required"]))
                    .delay(for: .milliseconds(250), scheduler: RunLoop.main)
                    .eraseToAnyPublisher()
            }

            return Just(.allowed).eraseToAnyPublisher()
        }
    }
}
