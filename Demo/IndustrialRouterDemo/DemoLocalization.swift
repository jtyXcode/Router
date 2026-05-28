import Foundation

enum DemoLanguage: String {
    case zhHans
    case en

    var segmentedTitle: String {
        switch self {
        case .zhHans: return "中文"
        case .en: return "English"
        }
    }
}

enum DemoTextKey {
    case homeTitle
    case replacedRootTitle
    case languageTitle
    case pushWithParams
    case reentryGuard
    case openDeepLink
    case loginIntercept
    case presentModal
    case customAnimation
    case explicitPop
    case popToTarget
    case popCurrent
    case popRoot
    case replaceRoot
    case openNewScene
    case resetLogin
    case detailTitle
    case finishWithCallback
    case duplicatePush
    case loginTitle
    case loginMessage
    case loginSuccess
    case modalTitle
    case modalMessage
    case modalPushDetail
    case modalClose
    case intermediateTitle
    case intermediateMessage
    case intermediatePushSuccess
    case successTitle
    case successMessage
    case popTestTitle
    case popTestMessage
    case popTestButton
    case popToTargetLevelOneTitle
    case popToTargetLevelOneMessage
    case popToTargetLevelOneButton
    case popToTargetLevelTwoTitle
    case popToTargetLevelTwoMessage
    case popToTargetLevelTwoButton
    case popRootLevelOneTitle
    case popRootLevelOneMessage
    case popRootLevelOneButton
    case popRootLevelTwoTitle
    case popRootLevelTwoMessage
    case popRootLevelTwoButton
    case protectedTitle
    case protectedMessage
}

final class DemoLocalization {
    static let shared = DemoLocalization()
    static let didChangeNotification = Notification.Name("IndustrialRouterDemoLocalizationDidChange")

    private let storageKey = "IndustrialRouterDemoLanguage"

    var language: DemoLanguage {
        didSet {
            guard oldValue != language else { return }
            UserDefaults.standard.set(language.rawValue, forKey: storageKey)
            NotificationCenter.default.post(name: Self.didChangeNotification, object: language)
        }
    }

    private init() {
        if let rawValue = UserDefaults.standard.string(forKey: storageKey),
           let language = DemoLanguage(rawValue: rawValue) {
            self.language = language
        } else {
            self.language = .zhHans
        }
    }

    func text(_ key: DemoTextKey) -> String {
        switch language {
        case .zhHans:
            return zhHansText(key)
        case .en:
            return englishText(key)
        }
    }

    private func zhHansText(_ key: DemoTextKey) -> String {
        switch key {
        case .homeTitle: return "路由测试 Demo"
        case .replacedRootTitle: return "已切换 Root"
        case .languageTitle: return "测试语言"
        case .pushWithParams: return "强类型 Push：参数传递 + 回调"
        case .reentryGuard: return "1 秒内防重入测试"
        case .openDeepLink: return "自定义 DeepLink 跳转"
        case .loginIntercept: return "登录拦截受保护页面"
        case .presentModal: return "Modal 路由弹出"
        case .customAnimation: return "自定义 Push 动画"
        case .explicitPop: return "显式 Pop 单页测试"
        case .popToTarget: return "Pop 到指定页面测试"
        case .popCurrent: return "Push 后移除当前页面"
        case .popRoot: return "PopToRoot 多级返回测试"
        case .replaceRoot: return "频繁切换 RootViewController"
        case .openNewScene: return "打开另一个 UIWindowScene"
        case .resetLogin: return "重置登录状态"
        case .detailTitle: return "商品详情"
        case .finishWithCallback: return "完成并回传数据"
        case .duplicatePush: return "重复 Push 当前页面测试"
        case .loginTitle: return "登录"
        case .loginMessage: return "受保护路由需要先登录。\n原因："
        case .loginSuccess: return "登录成功并回调"
        case .modalTitle: return "Modal 页面"
        case .modalMessage: return "Modal 路由拥有独立导航栈"
        case .modalPushDetail: return "在 Modal 导航栈内 Push 详情"
        case .modalClose: return "关闭 Modal 并回调"
        case .intermediateTitle: return "中间页"
        case .intermediateMessage: return "点击下方按钮 Push 成功页，并把当前页面从栈中移除。"
        case .intermediatePushSuccess: return "Push 成功页并 popCurrent"
        case .successTitle: return "成功页"
        case .successMessage: return "返回时应回到首页，而不是中间页。"
        case .popTestTitle: return "Pop 测试页"
        case .popTestMessage: return "点击按钮调用 router.pop，并观察首页日志中的 callback 和 deinit。"
        case .popTestButton: return "调用 pop 返回首页"
        case .popToTargetLevelOneTitle: return "指定 Pop 目标页"
        case .popToTargetLevelOneMessage: return "这是目标页面。继续进入第二级后，会从第二级指定返回到这里。"
        case .popToTargetLevelOneButton: return "进入第二级"
        case .popToTargetLevelTwoTitle: return "指定 Pop 第二级"
        case .popToTargetLevelTwoMessage: return "点击按钮调用 router.popTo(path:)，只返回到目标页，不回到首页。"
        case .popToTargetLevelTwoButton: return "Pop 到目标页"
        case .popRootLevelOneTitle: return "PopRoot 第一级"
        case .popRootLevelOneMessage: return "这是 PopToRoot 测试的第一级页面，继续进入第二级。"
        case .popRootLevelOneButton: return "进入第二级"
        case .popRootLevelTwoTitle: return "PopRoot 第二级"
        case .popRootLevelTwoMessage: return "点击按钮调用 router.popToRoot，一级和二级都应收到回调并释放。"
        case .popRootLevelTwoButton: return "调用 popToRoot 返回首页"
        case .protectedTitle: return "受保护页面"
        case .protectedMessage: return "登录态有效，受保护页面已展示。"
        }
    }

    private func englishText(_ key: DemoTextKey) -> String {
        switch key {
        case .homeTitle: return "Router Demo"
        case .replacedRootTitle: return "Replaced Root"
        case .languageTitle: return "Demo Language"
        case .pushWithParams: return "Typed push: params + callback"
        case .reentryGuard: return "Trigger one-second reentry guard"
        case .openDeepLink: return "Open custom deep link"
        case .loginIntercept: return "Login intercept protected route"
        case .presentModal: return "Present modal route"
        case .customAnimation: return "Push with custom animation"
        case .explicitPop: return "Explicit pop single page"
        case .popToTarget: return "Pop to specific page"
        case .popCurrent: return "Push popCurrent scenario"
        case .popRoot: return "PopToRoot multi-level scenario"
        case .replaceRoot: return "Replace root view controller"
        case .openNewScene: return "Open another UIWindowScene"
        case .resetLogin: return "Reset login state"
        case .detailTitle: return "Detail"
        case .finishWithCallback: return "Finish with callback"
        case .duplicatePush: return "Try duplicate push current route"
        case .loginTitle: return "Login"
        case .loginMessage: return "Protected route requires login.\nreason: "
        case .loginSuccess: return "Login success and callback"
        case .modalTitle: return "Modal"
        case .modalMessage: return "Modal route with its own navigation stack"
        case .modalPushDetail: return "Push detail inside modal stack"
        case .modalClose: return "Close modal with callback"
        case .intermediateTitle: return "Intermediate"
        case .intermediateMessage: return "Tap below to push Success and remove this page from the stack."
        case .intermediatePushSuccess: return "Push Success with popCurrent"
        case .successTitle: return "Success"
        case .successMessage: return "Back should return to Home, not Intermediate."
        case .popTestTitle: return "Pop Test"
        case .popTestMessage: return "Tap the button to call router.pop, then check callback and deinit logs on Home."
        case .popTestButton: return "Call pop to Home"
        case .popToTargetLevelOneTitle: return "Pop Target Page"
        case .popToTargetLevelOneMessage: return "This is the target page. Continue to level two, then pop back here by route."
        case .popToTargetLevelOneButton: return "Open Level Two"
        case .popToTargetLevelTwoTitle: return "Pop Target Level Two"
        case .popToTargetLevelTwoMessage: return "Tap the button to call router.popTo(path:). It returns to the target page, not Home."
        case .popToTargetLevelTwoButton: return "Pop to Target"
        case .popRootLevelOneTitle: return "PopRoot Level One"
        case .popRootLevelOneMessage: return "This is the first page in the PopToRoot test. Continue to level two."
        case .popRootLevelOneButton: return "Open Level Two"
        case .popRootLevelTwoTitle: return "PopRoot Level Two"
        case .popRootLevelTwoMessage: return "Tap the button to call router.popToRoot. Both level one and level two should callback and deinit."
        case .popRootLevelTwoButton: return "Call popToRoot to Home"
        case .protectedTitle: return "Protected"
        case .protectedMessage: return "Protected center is visible because login state is valid."
        }
    }
}

func demoText(_ key: DemoTextKey) -> String {
    DemoLocalization.shared.text(key)
}
