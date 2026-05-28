import UIKit
import Combine
import IndustrialRouter

final class HomeViewController: UIViewController {
    private let titleKey: DemoTextKey
    private var cancellables = Set<AnyCancellable>()
    private let logView = UITextView()
    private let languageControl = UISegmentedControl(items: [
        DemoLanguage.zhHans.segmentedTitle,
        DemoLanguage.en.segmentedTitle
    ])

    private var localizedButtons: [(UIButton, DemoTextKey)] = []

    init(titleKey: DemoTextKey = .homeTitle) {
        self.titleKey = titleKey
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DemoLogger.log("deinit HomeViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureLayout()
        observeLogs()
        observeLanguageChanges()
        applyLocalizedText()
    }

    private func configureLayout() {
        let scrollView = UIScrollView()
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        languageControl.addTarget(self, action: #selector(languageChanged), for: .valueChanged)
        languageControl.selectedSegmentIndex = DemoLocalization.shared.language == .zhHans ? 0 : 1

        logView.isEditable = false
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.backgroundColor = .secondarySystemBackground
        logView.layer.cornerRadius = 8
        logView.heightAnchor.constraint(equalToConstant: 180).isActive = true

        [
            languageControl,
            makeButton(.pushWithParams, action: #selector(pushWithParams)),
            makeButton(.reentryGuard, action: #selector(triggerReentryGuard)),
            makeButton(.openDeepLink, action: #selector(openDeepLink)),
            makeButton(.loginIntercept, action: #selector(openProtectedRoute)),
            makeButton(.presentModal, action: #selector(presentModal)),
            makeButton(.customAnimation, action: #selector(pushWithCustomAnimation)),
            makeButton(.explicitPop, action: #selector(openPopTest)),
            makeButton(.popToTarget, action: #selector(openPopToTargetScenario)),
            makeButton(.popCurrent, action: #selector(openPopCurrentScenario)),
            makeButton(.popRoot, action: #selector(openPopRootScenario)),
            makeButton(.replaceRoot, action: #selector(replaceRoot)),
            makeButton(.openNewScene, action: #selector(openNewScene)),
            makeButton(.resetLogin, action: #selector(resetLoginState)),
            logView
        ].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func makeButton(_ textKey: DemoTextKey, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.titleLabel?.numberOfLines = 0
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        button.contentHorizontalAlignment = .leading
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        localizedButtons.append((button, textKey))
        return button
    }

    private func observeLogs() {
        NotificationCenter.default.publisher(for: DemoLogger.notificationName)
            .compactMap { $0.object as? String }
            .sink { [weak self] line in
                guard let self else { return }
                self.logView.text = ([line] + self.logView.text.components(separatedBy: "\n")).prefix(80).joined(separator: "\n")
            }
            .store(in: &cancellables)
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.publisher(for: DemoLocalization.didChangeNotification)
            .sink { [weak self] _ in
                self?.applyLocalizedText()
            }
            .store(in: &cancellables)
    }

    private func applyLocalizedText() {
        title = demoText(titleKey)
        navigationItem.prompt = demoText(.languageTitle)
        languageControl.selectedSegmentIndex = DemoLocalization.shared.language == .zhHans ? 0 : 1
        localizedButtons.forEach { button, key in
            button.setTitle(demoText(key), for: .normal)
        }
    }

    @objc private func languageChanged() {
        DemoLocalization.shared.language = languageControl.selectedSegmentIndex == 0 ? .zhHans : .en
        DemoLogger.log("Demo language changed: \(DemoLocalization.shared.language.rawValue)")
    }

    @objc private func pushWithParams() {
        demoRouter?
            .navigate(
                to: DemoRoute.detail,
                params: ["itemId": "SKU-1001", "source": "typed_push"]
            )
            .sink { result in
                DemoLogger.log("Detail callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func triggerReentryGuard() {
        let first = demoRouter?.navigate(to: DemoRoute.detail, params: ["itemId": "R-1", "source": "first"])
        let second = demoRouter?.navigate(to: DemoRoute.detail, params: ["itemId": "R-2", "source": "blocked"])

        first?.sink { result in
            DemoLogger.log("First reentry request finished: \(String(describing: result))")
        }.store(in: &cancellables)

        second?.sink { result in
            DemoLogger.log("Second reentry request finished, expected nil: \(String(describing: result))")
        }.store(in: &cancellables)
    }

    @objc private func openDeepLink() {
        demoRouter?
            .open(link: "myapp://goods/detail?itemId=DL-999&source=deeplink_button")
            .sink { result in
                DemoLogger.log("Deep link callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func openProtectedRoute() {
        demoRouter?
            .navigate(to: DemoRoute.protectedCenter)
            .sink { result in
                DemoLogger.log("Protected route callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func presentModal() {
        demoRouter?
            .navigate(
                to: DemoRoute.modal,
                type: .modal(style: .pageSheet)
            )
            .sink { result in
                DemoLogger.log("Modal callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func pushWithCustomAnimation() {
        demoRouter?
            .navigate(
                to: DemoRoute.detail,
                params: ["itemId": "ANIM-1", "source": "custom_animation"],
                transitionProvider: DemoFadeAnimator()
            )
            .sink { result in
                DemoLogger.log("Custom animation callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func openPopCurrentScenario() {
        demoRouter?
            .navigate(to: DemoRoute.intermediate)
            .sink { result in
                DemoLogger.log("Intermediate callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func openPopTest() {
        demoRouter?
            .navigate(to: DemoRoute.popTest)
            .sink { result in
                DemoLogger.log("Pop test callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func openPopToTargetScenario() {
        demoRouter?
            .navigate(to: DemoRoute.popToTargetLevelOne)
            .sink { result in
                DemoLogger.log("PopTo target level one callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func openPopRootScenario() {
        demoRouter?
            .navigate(to: DemoRoute.popRootLevelOne)
            .sink { result in
                DemoLogger.log("PopRoot level one callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func replaceRoot() {
        guard let scene = view.window?.windowScene,
              let window = view.window else { return }

        let home = HomeViewController(titleKey: .replacedRootTitle)
        let nav = DemoNavigationController(rootViewController: home)
        window.rootViewController = nav

        RouterSceneCoordinatorStore.shared
            .coordinator(for: scene)
            .replaceRootNavigationController(nav)

        DemoLogger.log("Root navigation controller replaced for current scene.")
    }

    @objc private func openNewScene() {
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil) { error in
            DemoLogger.log("Open scene error: \(error.localizedDescription)")
        }
    }

    @objc private func resetLoginState() {
        DemoSession.shared.isLoggedIn = false
        DemoLogger.log("Login state reset.")
    }
}
