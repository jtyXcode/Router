import UIKit
import Combine
import IndustrialRouter

final class PopToTargetLevelOneViewController: UIViewController {
    private let scenarioId: String
    private let targetScenarioId: String?
    private var cancellables = Set<AnyCancellable>()
    private let messageLabel = UILabel()
    private let nextButton = UIButton(type: .system)

    init(scenarioId: String?, targetScenarioId: String? = nil) {
        self.scenarioId = scenarioId ?? "target-A"
        self.targetScenarioId = targetScenarioId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DemoLogger.log("deinit PopToTargetLevelOneViewController scenarioId=\(scenarioId)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
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
        title = "\(demoText(.popToTargetLevelOneTitle)) \(scenarioId)"
        messageLabel.text = "\(demoText(.popToTargetLevelOneMessage))\nscenarioId: \(scenarioId)"
        nextButton.setTitle(demoText(.popToTargetLevelOneButton), for: .normal)
    }

    @objc private func openLevelTwo() {
        if scenarioId == "target-A" {
            demoRouter?
                .navigate(
                    to: DemoRoute.popToTargetLevelOne,
                    params: [
                        "scenarioId": "target-B",
                        "targetScenarioId": scenarioId
                    ]
                )
                .sink { result in
                    DemoLogger.log("PopTo target-B callback: \(String(describing: result))")
                }
                .store(in: &cancellables)
            return
        }

        demoRouter?
            .navigate(
                to: DemoRoute.popToTargetLevelTwo,
                params: ["targetScenarioId": targetScenarioId ?? "target-A"]
            )
            .sink { result in
                DemoLogger.log("PopTo target level two callback: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }
}
