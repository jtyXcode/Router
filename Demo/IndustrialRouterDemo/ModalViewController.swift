import UIKit
import Combine
import IndustrialRouter

final class ModalViewController: UIViewController {
    private let message: String?
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let pushButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    init(message: String?) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DemoLogger.log("deinit ModalViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal
        configureLayout()
        observeLanguageChanges()
        applyLocalizedText()
    }

    private func configureLayout() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        configureButton(pushButton, action: #selector(pushInsideModal))
        configureButton(closeButton, action: #selector(closeModal))

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(pushButton)
        stackView.addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func configureButton(_ button: UIButton, action: Selector) {
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func observeLanguageChanges() {
        NotificationCenter.default.publisher(for: DemoLocalization.didChangeNotification)
            .sink { [weak self] _ in
                self?.applyLocalizedText()
            }
            .store(in: &cancellables)
    }

    private func applyLocalizedText() {
        title = demoText(.modalTitle)
        messageLabel.text = message ?? demoText(.modalMessage)
        pushButton.setTitle(demoText(.modalPushDetail), for: .normal)
        closeButton.setTitle(demoText(.modalClose), for: .normal)
    }

    @objc private func pushInsideModal() {
        demoRouter?
            .navigate(to: DemoRoute.detail, params: ["itemId": "MODAL-1", "source": "modal_stack"])
            .sink { result in
                DemoLogger.log("Modal nested detail callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }

    @objc private func closeModal() {
        demoRouter?.dismissOrPop(result: "modal_done")
    }
}
