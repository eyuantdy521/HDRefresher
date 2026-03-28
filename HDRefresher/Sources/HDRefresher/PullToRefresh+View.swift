import SwiftUI

// MARK: - View Extension for Pull-to-Refresh

extension View {

    /// 下拉刷新（自定义头部）
    public func pullToRefresh<Header: View>(
        config: RefreshConfiguration = .init(),
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder header: @escaping (RefreshState, CGFloat) -> Header
    ) -> HDRefreshableScrollView<Self, Header> {
        HDRefreshableScrollView(
            configuration: config,
            action: action,
            header: header
        ) {
            self
        }
    }

    /// 下拉刷新（默认头部）
    public func pullToRefresh(
        config: RefreshConfiguration = .init(),
        action: @Sendable @escaping () async -> Void
    ) -> HDRefreshableScrollView<Self, DefaultRefreshHeader> {
        self.pullToRefresh(config: config, action: action) { state, progress in
            DefaultRefreshHeader(state: state, progress: progress)
        }
    }
}
