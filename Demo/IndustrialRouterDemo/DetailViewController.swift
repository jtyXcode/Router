import UIKit
import Combine
import IndustrialRouter

final class DetailViewController: UIViewController {
    private let itemId: String?
    private let source: String?
    private var cancellables = Set<AnyCancellable>()
    private let infoLabel = UILabel()
    private let finishButton = UIButton(type: .system)
    private let duplicateButton = UIButton(type: .system)

    init(itemId: String?, source: String?) {
        self.itemId = itemId
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DemoLogger.log("deinit DetailViewController itemId=\(itemId ?? "nil")")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        configureLayout()
        observeLanguageChanges()
        applyLocalizedText()
        DemoLogger.log("Detail opened itemId=\(itemId ?? "nil"), source=\(source ?? "nil")")
    }

    private func configureLayout() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        infoLabel.numberOfLines = 0

        configureButton(finishButton, action: #selector(finishWithCallback))
        configureButton(duplicateButton, action: #selector(duplicatePushCurrentRoute))

        stackView.addArrangedSubview(infoLabel)
        stackView.addArrangedSubview(finishButton)
        stackView.addArrangedSubview(duplicateButton)

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
        title = demoText(.detailTitle)
        infoLabel.text = "itemId: \(itemId ?? "nil")\nsource: \(source ?? "nil")"
        finishButton.setTitle(demoText(.finishWithCallback), for: .normal)
        duplicateButton.setTitle(demoText(.duplicatePush), for: .normal)
    }

    @objc private func finishWithCallback() {
        demoRouter?.dismissOrPop(result: ["itemId": itemId ?? "", "favorite": true])
    }

    @objc private func duplicatePushCurrentRoute() {
        var params: [String: Any] = ["itemId": itemId ?? "DUP"]
        if let source {
            params["source"] = source
        }

        demoRouter?
            .navigate(to: DemoRoute.detail, params: params)
            .sink { result in
                DemoLogger.log("Duplicate push blocked callback, expected nil: \(String(describing: result))")
            }
            .store(in: &cancellables)
    }
}
