import UIKit
import Combine
import IndustrialRouter

final class SuccessViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let finishButton = UIButton(type: .system)

    deinit {
        DemoLogger.log("deinit SuccessViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPurple
        configureLayout()
        observeLanguageChanges()
        applyLocalizedText()
        DemoLogger.log("Success opened; previous page should be removed from stack.")
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

        finishButton.setTitleColor(.white, for: .normal)
        finishButton.backgroundColor = .systemBlue
        finishButton.layer.cornerRadius = 8
        finishButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        finishButton.titleLabel?.numberOfLines = 0
        finishButton.addTarget(self, action: #selector(finish), for: .touchUpInside)

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(finishButton)

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
        title = demoText(.successTitle)
        messageLabel.text = demoText(.successMessage)
        finishButton.setTitle(demoText(.finishWithCallback), for: .normal)
    }

    @objc private func finish() {
        demoRouter?.dismissOrPop(result: "success_done")
    }
}
