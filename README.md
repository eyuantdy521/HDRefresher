# HDRefresher

SwiftUI 下拉刷新组件
## 之前一直用一些第三方的，有的能满足需求，但是代码量太大，有的代码量小，但是功能有瑕疵。所以就自己鼓捣出来一个，凑合能用😂

## 功能特性

- 下拉刷新
- 自定义header
- 调用简单

## 系统要求

- iOS 13.0+
- Xcode 14.0+
- Swift 5.7+

## 安装

### Swift Package Manager

在 Xcode 中：
1. 选择 `File` → `Add Packages...`
2. 输入仓库 URL：
https://github.com/eyuantdy521/HDRefresher.git

text
3. 选择版本规则（推荐使用 "Up to Next Major"）
4. 点击 "Add Package"

或在 `Package.swift` 中添加依赖：

```swift
dependencies: [
 .package(url: "https://github.com/eyuantdy521/HDRefresher.git", from: "1.0.0")
]
```

## 快速开始
### 基础使用
swift
import HDRefresher

#### 在 需要外套 scrollView 的 view下：
```swift
VStack {
    ForEach(0..<30) { index in
        ...
    }
}
.pullToRefresh {
    try? await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000))
}
```

#### 自定义 config、header
```swift
VStack {
    ForEach(0..<30) { index in
        ...
    }
}
.pullToRefresh(config: .init(completedDuration: 3), action: {
    try? await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000))
}, header: { state, progress in
    LottieRefreshHeader(state: state, progress: progress)
        .equatable()
})
```
