import UIKit
import Combine
import IndustrialRouter

final class PopRootLevelOneViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let nextButton = UIButton(type: .system)

    deinit {
        DemoLogger.log("deinit PopRootLevelOneViewController")
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

        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = .systemBlue
        nextButton.layer.cornerRadius = 8
        nextButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        nextButton.titleLabel?.numberOfLines = 0
        nextButton.addTarget(self, action: #selector(openLevelTwo), for: .touchUpInside)

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(nextButton)

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
        title = demoText(.popRootLevelOneTitle)
        messageLabel.text = demoText(.popRootLevelOneMessage)
        nextButton.setTitle(demoText(.popRootLevelOneButton), for: .normal)
    }

    @objc private func openLevelTwo() {
        demoRouter?
            .navigate(to: DemoRoute.popRootLevelTwo)
            .sink { result in
                DemoLogger.log("PopRoot level two callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }
}
