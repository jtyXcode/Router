import UIKit
import Combine
import IndustrialRouter

final class PopToTargetLevelTwoViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let popToButton = UIButton(type: .system)

    deinit {
        DemoLogger.log("deinit PopToTargetLevelTwoViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray4
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

        popToButton.setTitleColor(.white, for: .normal)
        popToButton.backgroundColor = .systemBlue
        popToButton.layer.cornerRadius = 8
        popToButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        popToButton.titleLabel?.numberOfLines = 0
        popToButton.addTarget(self, action: #selector(popToTargetPage), for: .touchUpInside)

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(popToButton)

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
        title = demoText(.popToTargetLevelTwoTitle)
        messageLabel.text = demoText(.popToTargetLevelTwoMessage)
        popToButton.setTitle(demoText(.popToTargetLevelTwoButton), for: .normal)
    }

    @objc private func popToTargetPage() {
        demoRouter?.popTo(path: DemoRoute.popToTargetLevelOne, result: "pop_to_target_done")
    }
}
