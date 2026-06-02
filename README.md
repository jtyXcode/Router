# IndustrialRouter

[中文](#中文) | [English](#english)

## 中文

`IndustrialRouter` 是一个基于 UIKit + Combine 的路由 Coordinator 框架，用于统一处理 App 内页面跳转、登录拦截、DeepLink、Modal 流程、回调、自定义转场、root 切换和多 `UIWindowScene`。

详细中文框架说明：[FRAMEWORK.md](FRAMEWORK.md)

### 安装

CocoaPods:

```ruby
pod 'IndustrialRouter'
pod 'IndustrialRouter', :git => 'https://github.com/jtyXcode/Router.git'
```

Swift Package Manager:

```swift
.package(url: "https://github.com/jtyXcode/Router.git", from: "0.1.0")
```

Xcode 添加方式：`File` -> `Add Package Dependencies...`，输入 `https://github.com/jtyXcode/Router.git`，Dependency Rule 选择 `Up to Next Major Version`，版本填 `0.1.0`，最后把 `IndustrialRouter` product 添加到 App target。

Carthage:

```ruby
github "jtyXcode/Router" ~> 0.1.0
```

构建：

```bash
carthage update --use-xcframeworks --platform iOS
```

然后在 Xcode 中打开 App target：`General` -> `Frameworks, Libraries, and Embedded Content`，添加 `Carthage/Build/IndustrialRouter.xcframework`，Embed 选择 `Embed & Sign`。

### Demo 测试场景

Demo App 提供手动测试场景，首页支持中文 / English 切换。

- 强类型 push：参数传递 + 回调
- 1 秒内防重入
- 重复 push 当前页面拦截
- 登录拦截并重定向到 Modal 登录页
- Modal 路由和 Modal 内部继续 push
- 自定义 push / pop / Modal 转场动画
- 显式 `pop`
- `popTo(path:)` 指定返回页面
- `popToRoot`
- `push(popCurrent: true)` 后移除来源页
- 自定义 DeepLink 跳转
- rootViewController 替换
- 多 `UIWindowScene`
- 侧滑返回后的回调关闭和页面释放


## English

`IndustrialRouter` is a UIKit + Combine router coordinator for centralized in-app navigation, login interception, DeepLink handling, modal flows, callbacks, custom transitions, root replacement, and multiple `UIWindowScene` support.

Full Chinese framework guide: [FRAMEWORK.md](FRAMEWORK.md)

### Install

CocoaPods:

```ruby
pod 'IndustrialRouter'
```

Swift Package Manager:

```swift
.package(url: "https://github.com/jtyXcode/Router.git", from: "0.1.0")
```

In Xcode: `File` -> `Add Package Dependencies...`, enter `https://github.com/jtyXcode/Router.git`, choose `Up to Next Major Version`, set the version to `0.1.0`, then add the `IndustrialRouter` product to your app target.

Carthage:

```ruby
github "jtyXcode/Router" ~> 0.1.0
```

Build:

```bash
carthage update --use-xcframeworks --platform iOS
```

Then open your app target in Xcode: `General` -> `Frameworks, Libraries, and Embedded Content`, add `Carthage/Build/IndustrialRouter.xcframework`, and set Embed to `Embed & Sign`.

### Demo Scenarios

The demo app contains manual scenario tests. The home screen supports Chinese / English switching.

- typed push with params and callback
- one-second route reentry protection
- duplicate push of the current route
- login interception and modal redirect
- modal routing with nested navigation stack
- custom push, pop, and modal transitions
- explicit `pop`
- `popTo(path:)` to a specific page
- `popToRoot`
- `push(popCurrent: true)`
- custom DeepLink routing
- root view controller replacement
- one coordinator per `UIWindowScene`
- callback cleanup and view controller release after interactive swipe back

