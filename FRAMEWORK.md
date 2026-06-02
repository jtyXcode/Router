# IndustrialRouter 框架说明

`IndustrialRouter` 是一个基于 UIKit + Combine 的工业级路由 Coordinator 框架，面向中大型 iOS App 的页面跳转、登录拦截、DeepLink、Modal 流程、多 Scene、回调和自定义转场统一管理。

最低支持版本：iOS 13.0  
语言：Swift 5.7+  
依赖：UIKit、Combine、QuartzCore

## 设计目标

- 页面跳转入口统一，避免业务页面直接互相依赖。
- 支持强类型路由枚举，降低字符串路由误用。
- 支持 DeepLink / Universal Link 映射到业务路由。
- 支持登录拦截、异步拦截和路由重定向。
- 支持 push、Modal、Modal 内继续 push。
- 支持显式 pop、popTo 指定页面和 popToRoot。
- 支持 push 后移除当前页面，适用于登录成功、支付成功、流程重定向。
- 支持基于 `RoutePath + params + NavigationType` 签名的 1 秒防重入，以及重复 push 当前页面拦截。
- 支持参数传递和 Combine 回调。
- 支持自定义 push、pop、Modal 动画。
- 支持频繁切换 rootViewController 时取消旧回调，避免旧路由污染新栈。
- 支持多个 `UIWindowScene`，每个 Scene 独立 Coordinator。
- 支持系统返回、侧滑返回后的回调关闭和资源释放。

## 目录结构

```text
Sources/IndustrialRouter
├── RouteContracts.swift              # 路由协议、导航类型、拦截结果、动画协议
├── RouteViewControllerRegistry.swift # 路由到 UIViewController 的注册工厂
├── DeepLinkParser.swift              # 自定义 link 解析和映射
├── IndustrialRouterCoordinator.swift # 核心 Coordinator
├── RouterSceneCoordinatorStore.swift # 多 UIWindowScene 管理
├── UIViewController+Router.swift     # 路由身份和动画 provider 绑定
├── WeakBox.swift                     # 弱引用容器
└── Resources
    └── PrivacyInfo.xcprivacy         # Apple 隐私清单
```

Demo 目录：

```text
Demo/IndustrialRouterDemo
├── DemoNavigationController.swift    # Demo 侧滑返回测试导航控制器
├── DemoLocalization.swift            # Demo 中英文切换
├── DemoRouteBootstrap.swift          # Demo 路由注册
├── DemoRoutes.swift                  # Demo 路由枚举
└── *ViewController.swift             # 手动测试页面
```

## 安装

### CocoaPods

```ruby
pod 'IndustrialRouter'
```


### Carthage

```ruby
github "jtyXcode/Router" ~> 0.1.0
```

构建：

```bash
carthage update --use-xcframeworks --platform iOS
```

集成到 App：

1. 打开 App target
2. 进入 `General` -> `Frameworks, Libraries, and Embedded Content`
3. 添加 `Carthage/Build/IndustrialRouter.xcframework`
4. Embed 选择 `Embed & Sign`
5. 代码中使用 `import IndustrialRouter`

### Swift Package Manager

当前仓库也包含 `Package.swift`：

```swift
.package(url: "https://github.com/jtyXcode/Router.git", from: "0.1.0")
```

Xcode 图形界面安装：

1. `File` -> `Add Package Dependencies...`
2. 输入 `https://github.com/jtyXcode/Router.git`
3. Dependency Rule 选择 `Up to Next Major Version`
4. Version 填 `0.1.0`
5. 勾选 `IndustrialRouter` product，并添加到 App target

## 快速接入

### 1. 定义业务路由

```swift
import IndustrialRouter

enum AppRoute: String, RoutePath {
    case home = "app://home"
    case detail = "app://goods/detail"
    case login = "app://login"

    var stringValue: String {
        rawValue
    }
}
```

### 2. 注册路由工厂

```swift
RouteViewControllerRegistry.shared.register(AppRoute.detail) { context in
    let vc = GoodsDetailViewController()
    vc.itemId = context.params?["itemId"] as? String
    return vc
}

RouteViewControllerRegistry.shared.register(AppRoute.login) { context in
    LoginViewController()
}
```

### 3. Scene 中初始化 Coordinator

单 Scene 项目：

```swift
let nav = UINavigationController(rootViewController: HomeViewController())
window.rootViewController = nav
window.makeKeyAndVisible()

IndustrialRouterCoordinator.shared.setup(rootNavigationController: nav)
```

多 Scene 项目推荐：

```swift
let router = RouterSceneCoordinatorStore.shared.setup(
    rootNavigationController: nav,
    for: windowScene
)
```

Scene 释放时：

```swift
RouterSceneCoordinatorStore.shared.removeCoordinator(for: windowScene, result: nil)
```

## 核心 API

### 强类型跳转

```swift
router.navigate(
    to: AppRoute.detail,
    type: .push(),
    params: ["itemId": "SKU-1001"]
)
.sink { result in
    print("detail callback:", result as Any)
}
.store(in: &cancellables)
```

### Modal 跳转

```swift
router.navigate(
    to: AppRoute.login,
    type: .modal(style: .fullScreen)
)
```

默认 `wrapInNavigation` 为 `true`，Modal 页面会被包进新的 `UINavigationController`，因此 Modal 内部仍然可以继续 push。

```swift
router.navigate(
    to: AppRoute.detail,
    type: .modal(style: .pageSheet, wrapInNavigation: true)
)
```

### push 后移除当前页面

适用于登录成功、支付成功、流程完成后进入结果页，并把来源页从栈中移除。

```swift
router.navigate(
    to: AppRoute.home,
    type: .push(popCurrent: true)
)
```

### 统一返回并回调

```swift
router.dismissOrPop(result: ["favorite": true])
```

如果当前处于 Modal，会 dismiss Modal；如果当前处于普通导航栈，会 pop 当前页面。对应的 `navigate` 返回 publisher 会收到 result 并完成。

### 显式 Pop

```swift
router.pop(result: "explicit_pop_done")
```

`pop` 只操作当前活跃导航栈的顶部页面，不会把 Modal 根页面 dismiss 掉。适用于需要明确测试或明确表达“只做导航栈 pop”的场景。

### PopTo 指定页面

```swift
router.popTo(path: AppRoute.detail, result: "pop_to_target_done")
```

`popTo(path:)` 会在当前活跃导航栈中查找最近一个匹配该路由 identity 的页面，并返回到该页面。目标页面本身不会收到 result；目标页之上的所有页面会收到 result、完成 publisher、移除回调缓存。

### PopToRoot

```swift
router.popToRoot(result: "pop_root_done")
```

`popToRoot` 会把当前活跃导航栈返回到 root 页面，并对所有被移出栈的页面发送 result、完成 publisher、移除回调缓存。

## 登录拦截

拦截器支持 Combine 异步流程，可用于登录态、权限、网络状态检查。

```swift
router.interceptor = { path, params in
    if path.stringValue == AppRoute.detail.stringValue,
       !Session.shared.isLoggedIn {
        return Just(
            .redirected(
                path: AppRoute.login,
                type: .modal(),
                params: ["reason": "login_required"]
            )
        )
        .eraseToAnyPublisher()
    }

    return Just(.allowed).eraseToAnyPublisher()
}
```

拦截结果：

```swift
public enum RouteInterceptResult {
    case allowed
    case rejected
    case redirected(path: any RoutePath, type: RouterNavigationType, params: [String: Any]?)
}
```

框架内置最大重定向深度保护，避免拦截器循环重定向。

## DeepLink

注册规则：

```swift
DeepLinkParser.register("goods/detail") { query in
    (
        AppRoute.detail,
        [
            "itemId": query["itemId"] ?? "",
            "source": query["source"] ?? "deeplink"
        ]
    )
}
```

打开链接：

```swift
router.open(link: "myapp://goods/detail?itemId=999&source=banner")
```

解析规则：

- `myapp://goods/detail?itemId=999` 对应 pattern：`goods/detail`
- query 会转换为 `[String: Any]`
- 未命中规则时返回 `nil` publisher 结果，不执行跳转

## 自定义动画

### push / pop 动画

如果 push 和 pop 使用同一个动画对象，实现 `RouteTransitionProvider` 即可。

如果 push 和 pop 需要不同动画，推荐实现 `RouteNavigationTransitionProvider`：

```swift
final class FadeAnimator: NSObject, RouteNavigationTransitionProvider {
    func animationController(
        for operation: UINavigationController.Operation
    ) -> UIViewControllerAnimatedTransitioning? {
        FadeAnimatorForOperation(operation: operation)
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        0.35
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // fallback animation
    }
}
```

使用：

```swift
router.navigate(
    to: AppRoute.detail,
    transitionProvider: FadeAnimator()
)
```

框架行为：

- push 时使用当前请求传入的 `transitionProvider`
- pop 时从被 pop 的 `fromVC` 上读取当初绑定的 `transitionProvider`
- 系统返回按钮和侧滑返回都会走同一套 pop 动画

### Modal 动画

```swift
router.navigate(
    to: AppRoute.login,
    type: .modal(style: .fullScreen),
    transitionProvider: FadeAnimator()
)
```

Modal present 和 dismiss 会使用同一个 transitioning delegate provider。


当前框架只负责 UIKit 页面路由、Combine 回调、DeepLink 解析和转场调度，不采集用户数据，不做跨 App / 跨网站追踪，也没有在库源码中使用需要声明 reason 的敏感系统 API。因此清单声明为：

- `NSPrivacyTracking = false`
- `NSPrivacyTrackingDomains = []`
- `NSPrivacyCollectedDataTypes = []`
- `NSPrivacyAccessedAPITypes = []`

三种集成方式的处理：

- CocoaPods：通过 `s.resource_bundles` 打入 `IndustrialRouterPrivacy.bundle`
- Swift Package Manager：通过 target resources 处理 `Resources`
- Carthage / Xcode framework：`IndustrialRouter` target 的 Resources phase 会把清单拷入 framework

## 防重入与重复 Push

### 1 秒防重入

Coordinator 会为每次路由请求生成一个稳定签名：

```text
normalized(RoutePath.stringValue) + paramsFingerprint + navigationTypeKey
```

其中：

- `RoutePath.stringValue` 会统一转成小写，避免大小写不同导致签名不一致。
- `paramsFingerprint` 会按参数 key 排序后生成稳定字符串，支持 `Bool`、`String`、`NSNumber`、`URL`、`[String: Any]`、`[Any]`。
- `navigationTypeKey` 会区分 `push(popCurrent:)`、`modal(style:wrapInNavigation:)` 等跳转方式。

同一个 Coordinator 在 1 秒内只会拦截签名完全一致的路由请求。被拦截的请求会立即返回 `nil` 并结束 publisher，避免调用方等待。

因此下面两次请求会被视为重复进入：

```swift
router.navigate(
    to: AppRoute.detail,
    params: ["itemId": "SKU-1001", "source": "home"]
)

router.navigate(
    to: AppRoute.detail,
    params: ["source": "home", "itemId": "SKU-1001"]
)
```

而下面两次请求不会被误拦截，因为参数不同：

```swift
router.navigate(to: AppRoute.detail, params: ["itemId": "SKU-1001"])
router.navigate(to: AppRoute.detail, params: ["itemId": "SKU-1002"])
```

签名只用于短时间防重入，不替代业务幂等。下单、支付、提交表单等高风险动作仍建议在业务层做请求级幂等保护。

### 重复 push 当前页面拦截

框架会在目标页面入栈前写入两个内部标识：

```text
routerRouteIdentity    = RoutePath.stringValue
routerRouteFingerprint = normalized(RoutePath.stringValue) + paramsFingerprint
```

如果当前栈顶页面的 `routerRouteFingerprint` 与目标路由一致，框架会拒绝本次 push，并返回 `nil`。如果历史页面没有 fingerprint，则回退使用 `routerRouteIdentity` 判断。

这能避免按钮连点、网络回调重复触发导致同一个页面连续入栈。

由于重复 push 当前页面也包含参数指纹，同一个详情页不同业务参数可以继续进入，例如从商品 `SKU-1001` 进入商品 `SKU-1002`。

## rootViewController 切换

频繁切换 root 时，必须重新绑定 Coordinator：

```swift
let nav = UINavigationController(rootViewController: HomeViewController())
window.rootViewController = nav

router.replaceRootNavigationController(nav)
```

框架处理：

- 取消旧 root 上的异步拦截任务
- 结束旧页面的 pending callback
- 增加 root generation，旧 root 的异步请求返回后不会污染新栈
- 重置 1 秒防重入签名

## 多 UIWindowScene

多窗口场景不要使用全局单例 Coordinator 绑定所有窗口，推荐使用：

```swift
let router = RouterSceneCoordinatorStore.shared.setup(
    rootNavigationController: nav,
    for: windowScene
)
```

获取当前 VC 所在 Scene 的 router：

```swift
extension UIViewController {
    var demoRouter: IndustrialRouterCoordinator? {
        guard let scene = view.window?.windowScene else { return nil }
        return RouterSceneCoordinatorStore.shared.coordinator(for: scene)
    }
}
```

这样每个窗口拥有独立导航栈、独立拦截器、独立回调中心。

## 侧滑返回与释放验证

框架在 `UINavigationControllerDelegate.didShow` 中清理已经离栈的页面：

- 发送 `nil`
- 完成 Combine publisher
- 移除 callback subject
- 移除 owner navigation weak box

Demo 中 `DemoNavigationController` 已打开侧滑返回：

```swift
interactivePopGestureRecognizer?.isEnabled = true
interactivePopGestureRecognizer?.delegate = self
```

各测试页面都带有 `deinit` 日志。真机测试方式：

1. 打开 Demo。
2. 点击“强类型 Push：参数传递 + 回调”。
3. 进入详情页后从左边缘侧滑返回。
4. 首页日志区应看到：

```text
Detail callback: nil
deinit DetailViewController itemId=SKU-1001
```

这表示侧滑返回能正常触发回调关闭和页面释放。

## Demo 测试场景

Demo 首页支持中文 / English 切换，所有测试场景都可以直接点按钮验证。

- 强类型 push：参数传递 + 回调
- 1 秒内防重入
- 重复 push 当前页面拦截
- 自定义 DeepLink 跳转
- 登录拦截并重定向到 Modal 登录页
- Modal 路由和 Modal 内部继续 push
- 自定义 push / pop 动画
- 显式 pop 单页返回
- popTo 指定页面返回
- popToRoot 多级返回
- `push(popCurrent: true)` 后移除来源页
- rootViewController 替换
- 多 UIWindowScene
- 侧滑返回释放验证

## 真机运行

打开工程：

```text
IndustrialRouter.xcodeproj
```

选择 scheme：

```text
IndustrialRouterDemo
```

不要选择 `IndustrialRouter` framework scheme 运行到手机，framework 本身不是 App。

如果出现：

```text
An executable path on the remote device is required for launching.
```

通常是选中了 framework scheme，切换到 `IndustrialRouterDemo`。

如果出现：

```text
Library not loaded: /Library/Frameworks/IndustrialRouter.framework/IndustrialRouter
```

说明动态库 install name 或旧 DerivedData 有问题。当前工程已配置：

```text
LD_DYLIB_INSTALL_NAME = @rpath/$(EXECUTABLE_PATH)
LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks
```

清理方式：

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/IndustrialRouter-*
```

然后删除手机上的旧 Demo，重新 Run。

## 构建验证

Pod 验证：

```bash
pod lib lint IndustrialRouter.podspec --quick --allow-warnings --skip-import-validation
```

Demo Debug 构建：

```bash
xcodebuild \
  -project IndustrialRouter.xcodeproj \
  -scheme IndustrialRouterDemo \
  -configuration Debug \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath /private/tmp/IndustrialRouterDemoDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Carthage framework 入口：

```text
IndustrialRouter.xcodeproj
IndustrialRouter scheme
```

## 接入建议

- 业务模块只暴露 `RoutePath` 枚举，不直接暴露 ViewController 构造细节。
- 路由注册集中放在模块启动或 App 启动阶段。
- 登录、权限、风控等横切逻辑放入 `interceptor`。
- 多 Scene 项目优先使用 `RouterSceneCoordinatorStore`。
- root 替换必须调用 `replaceRootNavigationController`。
- Demo 验证侧滑释放时，以 callback 结束和 `deinit` 日志同时出现为准。
