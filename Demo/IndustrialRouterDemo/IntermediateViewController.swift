import UIKit
import Combine
import IndustrialRouter

final class IntermediateViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let pushButton = UIButton(type: .system)

    deinit {
        DemoLogger.log("deinit IntermediateViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemIndigo
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
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center

        pushButton.setTitleColor(.white, for: .normal)
        pushButton.backgroundColor = .systemBlue
        pushButton.layer.cornerRadius = 8
        pushButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        pushButton.titleLabel?.numberOfLines = 0
        pushButton.addTarget(self, action: #selector(pushSuccessAndRemoveCurrent), for: .touchUpInside)

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(pushButton)

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
        title = demoText(.intermediateTitle)
        messageLabel.text = demoText(.intermediateMessage)
        pushButton.setTitle(demoText(.intermediatePushSuccess), for: .normal)
    }

    @objc private func pushSuccessAndRemoveCurrent() {
        demoRouter?
            .navigate(to: DemoRoute.success, type: .push(popCurrent: true))
            .sink { result in
                DemoLogger.log("Success callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }
}
