import UIKit

final class DemoNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    deinit {
        DemoLogger.log("deinit DemoNavigationController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.isEnabled = true
        interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
