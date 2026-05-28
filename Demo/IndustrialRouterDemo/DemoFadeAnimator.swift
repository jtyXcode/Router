import UIKit
import IndustrialRouter

final class DemoFadeAnimator: NSObject, RouteNavigationTransitionProvider {
    private let duration: TimeInterval
    private let operation: UINavigationController.Operation

    init(duration: TimeInterval = 0.35, operation: UINavigationController.Operation = .push) {
        self.duration = duration
        self.operation = operation
    }

    func animationController(for operation: UINavigationController.Operation) -> UIViewControllerAnimatedTransitioning? {
        DemoFadeAnimator(duration: duration, operation: operation)
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView

        switch operation {
        case .push:
            toView.alpha = 0
            container.addSubview(toView)

            UIView.animate(withDuration: duration, animations: {
                toView.alpha = 1
            }, completion: { finished in
                transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
            })

        case .pop:
            container.insertSubview(toView, belowSubview: fromView)
            toView.alpha = 1

            UIView.animate(withDuration: duration, animations: {
                fromView.alpha = 0
            }, completion: { finished in
                fromView.alpha = 1
                transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
            })

        default:
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
