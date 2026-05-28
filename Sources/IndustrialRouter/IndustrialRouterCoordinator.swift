import UIKit
import Combine
import QuartzCore

// MARK: - Coordinator

private struct RouteRequestSignature: Equatable {
    let routeKey: String
    let paramsFingerprint: String
    let navigationKey: String
}

private struct RouteRequestStamp {
    let signature: RouteRequestSignature
    let time: CFTimeInterval
}

private extension RouterNavigationType {
    var reentryKey: String {
        switch self {
        case .push(let popCurrent, _):
            return "push:\(popCurrent)"
        case .modal(let style, let wrapInNavigation, _, _):
            return "modal:\(style.rawValue):\(wrapInNavigation)"
        }
    }
}

public final class IndustrialRouterCoordinator: NSObject {
    public static let shared = IndustrialRouterCoordinator()

    /// Return `.redirected(path: .login, type: .modal(), params: nil)` here to intercept login.
    public var interceptor: ((any RoutePath, [String: Any]?) -> AnyPublisher<RouteInterceptResult, Never>)?

    private weak var rootNavigationController: UINavigationController?
    private let routeRequestSubject = PassthroughSubject<RouteRequest, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var interceptionCancellables: [UUID: AnyCancellable] = [:]
    private var rootGeneration = 0
    private var lastAcceptedRoute: RouteRequestStamp?
    private let routeReentryInterval: CFTimeInterval = 1

    private var completionSubjects: [ObjectIdentifier: PassthroughSubject<Any?, Never>] = [:]
    private var ownerNavigationControllers: [ObjectIdentifier: WeakBox<UINavigationController>] = [:]

    private var pendingPushTransitionProvider: RouteTransitionProvider?
    private var pendingModalTransitionProvider: RouteTransitionProvider?
    private let maxRedirectDepth = 8

    fileprivate struct RouteRequest {
        let id: UUID
        let path: any RoutePath
        let type: RouterNavigationType
        let params: [String: Any]?
        let transitionProvider: RouteTransitionProvider?
        let responseSubject: PassthroughSubject<Any?, Never>
        let redirectDepth: Int
        let rootGeneration: Int
        let normalizedRouteKey: String
        let paramsFingerprint: String
        let routeFingerprint: String
        let reentrySignature: RouteRequestSignature

        init(
            id: UUID = UUID(),
            path: any RoutePath,
            type: RouterNavigationType,
            params: [String: Any]?,
            transitionProvider: RouteTransitionProvider?,
            responseSubject: PassthroughSubject<Any?, Never>,
            redirectDepth: Int = 0,
            rootGeneration: Int
        ) {
            self.id = id
            self.path = path
            self.type = type
            self.params = params
            self.transitionProvider = transitionProvider
            self.responseSubject = responseSubject
            self.redirectDepth = redirectDepth
            self.rootGeneration = rootGeneration
            self.normalizedRouteKey = Self.normalizeRouteKey(path.stringValue)
            self.paramsFingerprint = Self.makeParamsFingerprint(params)
            self.routeFingerprint = "\(normalizedRouteKey)|\(paramsFingerprint)"
            self.reentrySignature = RouteRequestSignature(
                routeKey: normalizedRouteKey,
                paramsFingerprint: paramsFingerprint,
                navigationKey: type.reentryKey
            )
        }

        func redirected(to path: any RoutePath, type: RouterNavigationType, params: [String: Any]?) -> RouteRequest {
            RouteRequest(
                path: path,
                type: type,
                params: params,
                transitionProvider: transitionProvider,
                responseSubject: responseSubject,
                redirectDepth: redirectDepth + 1,
                rootGeneration: rootGeneration
            )
        }

        private static func normalizeRouteKey(_ routeKey: String) -> String {
            routeKey.lowercased()
        }

        private static func makeParamsFingerprint(_ params: [String: Any]?) -> String {
            guard let params, !params.isEmpty else { return "" }

            return params.keys.sorted()
                .map { "\($0)=\(describe(params[$0]))" }
                .joined(separator: "&")
        }

        private static func describe(_ value: Any?) -> String {
            guard let value else { return "nil" }

            switch value {
            case let value as Bool:
                return "bool:\(value)"
            case let value as String:
                return "string:\(value)"
            case let value as NSNumber:
                return "number:\(value)"
            case let value as URL:
                return "url:\(value.absoluteString)"
            case let value as [String: Any]:
                return "dict:{\(makeParamsFingerprint(value))}"
            case let value as [Any]:
                return "array:[\(value.map { describe($0) }.joined(separator: ","))]"
            default:
                return "\(Swift.type(of: value)):\(String(describing: value))"
            }
        }
    }

    public override init() {
        super.init()
        setupRoutePipeline()
    }

    public func setup(rootNavigationController: UINavigationController) {
        replaceRootNavigationController(rootNavigationController)
    }

    /// Rebinds the coordinator to a new root navigation stack.
    /// Pending callbacks and async interceptions from the previous root are cancelled.
    public func replaceRootNavigationController(_ rootNavigationController: UINavigationController) {
        if Thread.isMainThread {
            bindRootNavigationController(rootNavigationController)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.bindRootNavigationController(rootNavigationController)
            }
        }
    }

    public func cancelPendingRoutes(result: Any? = nil) {
        if Thread.isMainThread {
            cancelPendingRoutesOnMain(result: result)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.cancelPendingRoutesOnMain(result: result)
            }
        }
    }

    /// Strongly typed route navigation.
    @discardableResult
    public func navigate(
        to path: any RoutePath,
        type: RouterNavigationType = .push(),
        params: [String: Any]? = nil,
        transitionProvider: RouteTransitionProvider? = nil
    ) -> AnyPublisher<Any?, Never> {
        let responseSubject = PassthroughSubject<Any?, Never>()
        let request = RouteRequest(
            path: path,
            type: type,
            params: params,
            transitionProvider: transitionProvider,
            responseSubject: responseSubject,
            rootGeneration: rootGeneration
        )

        send(request)
        return responseSubject.eraseToAnyPublisher()
    }

    /// Custom scheme or universal link navigation.
    @discardableResult
    public func open(
        link urlString: String,
        type: RouterNavigationType = .push(),
        transitionProvider: RouteTransitionProvider? = nil
    ) -> AnyPublisher<Any?, Never> {
        guard let parsed = DeepLinkParser.parse(urlString) else {
            return Just(nil).eraseToAnyPublisher()
        }

        return navigate(
            to: parsed.path,
            type: type,
            params: parsed.params,
            transitionProvider: transitionProvider
        )
    }

    /// Unified exit API for pushed pages and modal flows.
    public func dismissOrPop(result: Any? = nil, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.performDismissOrPop(result: result, animated: animated)
        }
    }

    /// Pops the top page from the active navigation stack without dismissing a modal root.
    public func pop(result: Any? = nil, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.performPop(result: result, animated: animated)
        }
    }

    /// Pops the active navigation stack back to the latest page matching the route path.
    public func popTo(path: any RoutePath, result: Any? = nil, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.performPopTo(routeKey: path.stringValue, result: result, animated: animated)
        }
    }

    /// Pops the active navigation stack to its root page and finishes callbacks for removed pages.
    public func popToRoot(result: Any? = nil, animated: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.performPopToRoot(result: result, animated: animated)
        }
    }

    private func setupRoutePipeline() {
        routeRequestSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] request in
                self?.executeRoute(request)
            }
            .store(in: &cancellables)
    }

    private func send(_ request: RouteRequest) {
        DispatchQueue.main.async { [weak self] in
            self?.handleIncomingRouteRequest(request)
        }
    }

    private func handleIncomingRouteRequest(_ request: RouteRequest) {
        let now = CACurrentMediaTime()

        if let lastAcceptedRoute,
           lastAcceptedRoute.signature == request.reentrySignature,
           now - lastAcceptedRoute.time < routeReentryInterval {
            finish(request.responseSubject, result: nil)
            return
        }

        lastAcceptedRoute = RouteRequestStamp(signature: request.reentrySignature, time: now)
        routeRequestSubject.send(request)
    }

    private func bindRootNavigationController(_ navigationController: UINavigationController) {
        if rootNavigationController === navigationController {
            navigationController.delegate = self
            return
        }

        if rootNavigationController?.delegate === self {
            rootNavigationController?.delegate = nil
        }

        cancelPendingRoutesOnMain(result: nil)
        navigationController.delegate = self
        rootNavigationController = navigationController
        rootGeneration += 1
        lastAcceptedRoute = nil
    }

    private func cancelPendingRoutesOnMain(result: Any?) {
        interceptionCancellables.removeAll()
        pendingPushTransitionProvider = nil
        pendingModalTransitionProvider = nil
        finishAllPendingCallbacks(result: result)
    }
}

// MARK: - Route Execution

private extension IndustrialRouterCoordinator {
    func executeRoute(_ request: RouteRequest) {
        guard request.rootGeneration == rootGeneration else {
            finish(request.responseSubject, result: nil)
            return
        }

        guard rootNavigationController != nil else {
            finish(request.responseSubject, result: nil)
            assertionFailure("[Router] Call setup(rootNavigationController:) before navigation.")
            return
        }

        if shouldRejectDuplicatedPush(request) {
            finish(request.responseSubject, result: nil)
            return
        }

        guard let interceptor else {
            performNavigation(request)
            return
        }

        let id = request.id
        interceptionCancellables[id] = interceptor(request.path, request.params)
            .prefix(1)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.interceptionCancellables.removeValue(forKey: id)
                },
                receiveValue: { [weak self] result in
                    self?.handleInterceptResult(result, for: request)
                }
            )
    }

    func handleInterceptResult(_ result: RouteInterceptResult, for request: RouteRequest) {
        switch result {
        case .allowed:
            performNavigation(request)

        case .rejected:
            finish(request.responseSubject, result: nil)

        case .redirected(let path, let type, let params):
            guard request.redirectDepth < maxRedirectDepth else {
                finish(request.responseSubject, result: nil)
                assertionFailure("[Router] Redirect depth exceeded. Check interceptor redirect loop.")
                return
            }

            // Redirects intentionally bypass the one-second external-entry throttle.
            executeRoute(request.redirected(to: path, type: type, params: params))
        }
    }

    func performNavigation(_ request: RouteRequest) {
        guard let activeNavigationController else {
            finish(request.responseSubject, result: nil)
            return
        }

        guard let targetViewController = RouteViewControllerRegistry.shared.makeViewController(path: request.path, params: request.params) else {
            finish(request.responseSubject, result: nil)
            assertionFailure("[Router] No UIViewController registered for route: \(request.path.stringValue)")
            return
        }

        targetViewController.routerRouteIdentity = request.path.stringValue
        targetViewController.routerRouteFingerprint = request.routeFingerprint
        targetViewController.routerTransitionProvider = request.transitionProvider
        completionSubjects[ObjectIdentifier(targetViewController)] = request.responseSubject

        switch request.type {
        case .push(let popCurrent, let animated):
            performPush(
                targetViewController,
                on: activeNavigationController,
                request: request,
                popCurrent: popCurrent,
                animated: animated
            )

        case .modal(let style, let wrapInNavigation, let animated, let completion):
            performModal(
                targetViewController,
                from: activeNavigationController,
                request: request,
                style: style,
                wrapInNavigation: wrapInNavigation,
                animated: animated,
                completion: completion
            )
        }
    }

    func performPush(
        _ targetViewController: UIViewController,
        on navigationController: UINavigationController,
        request: RouteRequest,
        popCurrent: Bool,
        animated: Bool
    ) {
        ownerNavigationControllers[ObjectIdentifier(targetViewController)] = WeakBox(navigationController)
        pendingPushTransitionProvider = request.transitionProvider

        let sourceViewController = navigationController.topViewController

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self, weak navigationController, weak sourceViewController] in
            guard popCurrent, let navigationController, let sourceViewController else { return }
            self?.removeSourcePage(sourceViewController, from: navigationController)
        }

        navigationController.pushViewController(targetViewController, animated: animated)
        CATransaction.commit()
    }

    func performModal(
        _ targetViewController: UIViewController,
        from presentingNavigationController: UINavigationController,
        request: RouteRequest,
        style: UIModalPresentationStyle,
        wrapInNavigation: Bool,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        let presentedController: UIViewController
        pendingModalTransitionProvider = request.transitionProvider

        if wrapInNavigation {
            let modalNavigationController = UINavigationController(rootViewController: targetViewController)
            modalNavigationController.delegate = self
            modalNavigationController.modalPresentationStyle = style
            modalNavigationController.presentationController?.delegate = self
            ownerNavigationControllers[ObjectIdentifier(targetViewController)] = WeakBox(modalNavigationController)
            presentedController = modalNavigationController
        } else {
            targetViewController.modalPresentationStyle = style
            targetViewController.presentationController?.delegate = self
            presentedController = targetViewController
        }

        if request.transitionProvider != nil {
            presentedController.transitioningDelegate = self
        }

        presentingNavigationController.present(presentedController, animated: animated, completion: completion)
    }

    func shouldRejectDuplicatedPush(_ request: RouteRequest) -> Bool {
        guard case .push = request.type,
              let topViewController = activeNavigationController?.topViewController else {
            return false
        }

        if let topFingerprint = topViewController.routerRouteFingerprint {
            return topFingerprint == request.routeFingerprint
        }

        return topViewController.routerRouteIdentity?.lowercased() == request.normalizedRouteKey
    }

    var activeNavigationController: UINavigationController? {
        guard let rootNavigationController else { return nil }

        if let presentedNavigationController = rootNavigationController.presentedViewController as? UINavigationController {
            return presentedNavigationController
        }

        return rootNavigationController
    }

    func animationController(
        from provider: RouteTransitionProvider?,
        operation: UINavigationController.Operation
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let provider else { return nil }

        if let navigationProvider = provider as? RouteNavigationTransitionProvider {
            return navigationProvider.animationController(for: operation)
        }

        return provider
    }
}

// MARK: - Exit And Cleanup

private extension IndustrialRouterCoordinator {
    func performDismissOrPop(result: Any?, animated: Bool) {
        guard let rootNavigationController else { return }

        if let presented = rootNavigationController.presentedViewController {
            if let modalNavigationController = presented as? UINavigationController {
                if modalNavigationController.viewControllers.count > 1,
                   let topViewController = modalNavigationController.topViewController {
                    finish(topViewController, result: result)
                    modalNavigationController.popViewController(animated: animated)
                } else {
                    modalNavigationController.viewControllers.forEach { finish($0, result: result) }
                    dismissPresentedController(from: rootNavigationController, animated: animated)
                }
            } else {
                finish(presented, result: result)
                dismissPresentedController(from: rootNavigationController, animated: animated)
            }

            return
        }

        guard let topViewController = rootNavigationController.topViewController else { return }
        finish(topViewController, result: result)
        rootNavigationController.popViewController(animated: animated)
    }

    func performPop(result: Any?, animated: Bool) {
        guard let navigationController = activeNavigationController,
              navigationController.viewControllers.count > 1,
              let topViewController = navigationController.topViewController else {
            return
        }

        finish(topViewController, result: result)
        navigationController.popViewController(animated: animated)
    }

    func performPopTo(routeKey: String, result: Any?, animated: Bool) {
        guard let navigationController = activeNavigationController else { return }

        let normalizedRouteKey = routeKey.lowercased()
        guard let targetIndex = navigationController.viewControllers.lastIndex(where: {
            $0.routerRouteIdentity?.lowercased() == normalizedRouteKey
        }) else {
            return
        }

        guard targetIndex < navigationController.viewControllers.count - 1 else { return }

        let targetViewController = navigationController.viewControllers[targetIndex]
        let removedViewControllers = Array(navigationController.viewControllers[(targetIndex + 1)...])
        removedViewControllers.forEach { finish($0, result: result) }
        navigationController.popToViewController(targetViewController, animated: animated)
    }

    func performPopToRoot(result: Any?, animated: Bool) {
        guard let navigationController = activeNavigationController,
              navigationController.viewControllers.count > 1 else {
            return
        }

        let removedViewControllers = Array(navigationController.viewControllers.dropFirst())
        removedViewControllers.forEach { finish($0, result: result) }
        navigationController.popToRootViewController(animated: animated)
    }

    func dismissPresentedController(from rootNavigationController: UINavigationController, animated: Bool) {
        rootNavigationController.dismiss(animated: animated) { [weak self] in
            self?.pendingModalTransitionProvider = nil
        }
    }

    func removeSourcePage(_ sourceViewController: UIViewController, from navigationController: UINavigationController) {
        guard navigationController.viewControllers.contains(sourceViewController) else { return }

        var viewControllers = navigationController.viewControllers
        viewControllers.removeAll { $0 === sourceViewController }
        navigationController.setViewControllers(viewControllers, animated: false)
        finish(sourceViewController, result: nil)
    }

    func cleanupPoppedControllers(in navigationController: UINavigationController) {
        let visibleIDs = Set(navigationController.viewControllers.map(ObjectIdentifier.init))
        let idsToFinish = ownerNavigationControllers.compactMap { id, owner -> ObjectIdentifier? in
            guard let ownerNavigationController = owner.value else { return id }
            guard ownerNavigationController === navigationController, !visibleIDs.contains(id) else { return nil }
            return id
        }

        for id in idsToFinish {
            completionSubjects[id]?.send(nil)
            completionSubjects[id]?.send(completion: .finished)
            completionSubjects.removeValue(forKey: id)
            ownerNavigationControllers.removeValue(forKey: id)
        }
    }

    func finish(_ viewController: UIViewController, result: Any?) {
        let id = ObjectIdentifier(viewController)
        completionSubjects[id]?.send(result)
        completionSubjects[id]?.send(completion: .finished)
        completionSubjects.removeValue(forKey: id)
        ownerNavigationControllers.removeValue(forKey: id)
    }

    func finish(_ subject: PassthroughSubject<Any?, Never>, result: Any?) {
        subject.send(result)
        subject.send(completion: .finished)
    }

    func finishAllPendingCallbacks(result: Any?) {
        completionSubjects.values.forEach {
            $0.send(result)
            $0.send(completion: .finished)
        }

        completionSubjects.removeAll()
        ownerNavigationControllers.removeAll()
    }
}

// MARK: - Navigation And Transition Delegates

extension IndustrialRouterCoordinator: UINavigationControllerDelegate, UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        pendingPushTransitionProvider = nil
        cleanupPoppedControllers(in: navigationController)
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return animationController(from: pendingPushTransitionProvider, operation: operation)
        case .pop:
            return animationController(from: fromVC.routerTransitionProvider, operation: operation)
        default:
            return nil
        }
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        pendingModalTransitionProvider
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        pendingModalTransitionProvider
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let presented = presentationController.presentedViewController

        if let navigationController = presented as? UINavigationController {
            navigationController.viewControllers.forEach { finish($0, result: nil) }
        } else {
            finish(presented, result: nil)
        }

        pendingModalTransitionProvider = nil
    }
}
