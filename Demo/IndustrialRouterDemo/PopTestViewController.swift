import UIKit
import Combine
import IndustrialRouter

final class PopTestViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let popButton = UIButton(type: .system)

    deinit {
        DemoLogger.log("deinit PopTestViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGreen
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

        popButton.setTitleColor(.white, for: .normal)
        popButton.backgroundColor = .systemBlue
        popButton.layer.cornerRadius = 8
        popButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        popButton.titleLabel?.numberOfLines = 0
        popButton.addTarget(self, action: #selector(popToPreviousPage), for: .touchUpInside)

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(popButton)

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
        title = demoText(.popTestTitle)
        messageLabel.text = demoText(.popTestMessage)
        popButton.setTitle(demoText(.popTestButton), for: .normal)
    }

    @objc private func popToPreviousPage() {
        demoRouter?.pop(result: "explicit_pop_done")
    }
}
