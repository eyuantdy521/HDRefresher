import SwiftUI

// MARK: - View Extension for Pull-to-Refresh

public extension View {

    /// 带自定义头部的下拉刷新
    /// - Parameters:
    ///   - config: 刷新配置，支持链式调用自定义阈值、动画等参数
    ///   - action: 异步刷新操作
    ///   - header: 自定义头部视图构建闭包，接收当前刷新状态和下拉进度
    /// - Returns: 应用了下拉刷新功能的视图
    func pullToRefresh<Header: View>(
        config: RefreshConfiguration = .init(),
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder header: @escaping (RefreshState, CGFloat) -> Header
    ) -> some View {
        self.modifier(
            RefreshModifier(
                configuration: config,
                action: action,
                header: header
            )
        )
    }

    /// 使用默认头部的下拉刷新
    /// - Parameters:
    ///   - config: 刷新配置，支持链式调用自定义阈值、动画等参数
    ///   - action: 异步刷新操作
    /// - Returns: 应用了下拉刷新功能的视图（使用 DefaultRefreshHeader）
    func pullToRefresh(
        config: RefreshConfiguration = .init(),
        action: @Sendable @escaping () async -> Void
    ) -> some View {
        self.pullToRefresh(config: config, action: action) { state, progress in
            // 性能优化：使用 .equatable() 让 SwiftUI 利用
            // DefaultRefreshHeader 的 Equatable 一致性跳过不必要的 diff
            DefaultRefreshHeader(state: state, progress: progress)
                .equatable()
        }
    }
}
