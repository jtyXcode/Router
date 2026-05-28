import UIKit
import ObjectiveC

// MARK: - UIViewController Route Identity

private var routerRouteIdentityKey: UInt8 = 0
private var routerRouteFingerprintKey: UInt8 = 0
private var routerTransitionProviderKey: UInt8 = 0

extension UIViewController {
    var routerRouteIdentity: String? {
        get {
            objc_getAssociatedObject(self, &routerRouteIdentityKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &routerRouteIdentityKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    var routerTransitionProvider: RouteTransitionProvider? {
        get {
            objc_getAssociatedObject(self, &routerTransitionProviderKey) as? RouteTransitionProvider
        }
        set {
            objc_setAssociatedObject(self, &routerTransitionProviderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var routerRouteFingerprint: String? {
        get {
            objc_getAssociatedObject(self, &routerRouteFingerprintKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &routerRouteFingerprintKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}
