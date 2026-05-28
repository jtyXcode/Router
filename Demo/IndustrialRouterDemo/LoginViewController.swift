import UIKit
import Combine
import IndustrialRouter

final class LoginViewController: UIViewController {
    private let reason: String?
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let loginButton = UIButton(type: .system)

    init(reason: String?) {
        self.reason = reason
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DemoLogger.log("deinit LoginViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange
        configureLayout()
        observeLanguageChanges()
        applyLocalizedText()
    }

    private func configureLayout() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.layer.cornerRadius = 8
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        loginButton.titleLabel?.numberOfLines = 0
        loginButton.addTarget(self, action: #selector(loginSuccess), for: .touchUpInside)

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(loginButton)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.publisher(for: DemoLocalization.didChangeNotification)
            .sink { [weak self] _ in
                self?.applyLocalizedText()
            }
            .store(in: &cancellables)
    }

    private func applyLocalizedText() {
        title = demoText(.loginTitle)
        messageLabel.text = "\(demoText(.loginMessage))\(reason ?? "nil")"
        loginButton.setTitle(demoText(.loginSuccess), for: .normal)
    }

    @objc private func loginSuccess() {
        DemoSession.shared.isLoggedIn = true
        DemoLogger.log("Login success.")
        demoRouter?.dismissOrPop(result: true)
    }
}
