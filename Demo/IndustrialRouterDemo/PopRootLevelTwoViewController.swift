import UIKit
import Combine
import IndustrialRouter

final class PopRootLevelTwoViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let popRootButton = UIButton(type: .system)

    deinit {
        DemoLogger.log("deinit PopRootLevelTwoViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
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

        popRootButton.setTitleColor(.white, for: .normal)
        popRootButton.backgroundColor = .systemBlue
        popRootButton.layer.cornerRadius = 8
        popRootButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        popRootButton.titleLabel?.numberOfLines = 0
        popRootButton.addTarget(self, action: #selector(popToRoot), for: .touchUpInside)

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(popRootButton)

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
        title = demoText(.popRootLevelTwoTitle)
        messageLabel.text = demoText(.popRootLevelTwoMessage)
        popRootButton.setTitle(demoText(.popRootLevelTwoButton), for: .normal)
    }

    @objc private func popToRoot() {
        demoRouter?.popToRoot(result: "pop_root_done")
    }
}
