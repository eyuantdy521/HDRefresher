import SwiftUI

/// 默认下拉刷新头部视图，根据 RefreshState 显示不同 UI
/// - idle/pulling：进度旋转动画
/// - triggered："松开刷新" 文字提示
/// - refreshing：ProgressView 旋转动画
/// - completed：刷新完成
public struct DefaultRefreshHeader: View, @MainActor Equatable {
    public let state: RefreshState
    public let progress: CGFloat

    public var isCompleted: Bool {
        state == .completed
    }

    @State private var isRefreshing: Bool = false

    public init(state: RefreshState, progress: CGFloat) {
        self.state = state
        self.progress = progress
    }

    // Equatable 优化：帮助 SwiftUI 跳过不必要的 diff 计算
    public static func == (lhs: DefaultRefreshHeader, rhs: DefaultRefreshHeader) -> Bool {
        lhs.state == rhs.state && lhs.progress == rhs.progress
    }

    public var body: some View {
        ZStack {
            Group {
                switch state {
                case .idle, .pulling:
                    idlePullingView
                case .triggered:
                    triggeredView
                case .refreshing:
                    refreshingView
                case .completed:
                    completedView
                }
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Idle / Pulling

    /// 随下拉进度旋转
    private var idlePullingView: some View {
        Image(systemName: "swirl.circle.righthalf.filled")
            .font(.system(size: 20, weight: .medium))
            .foreGColor(.red)
            .rotationEffect(.degrees(-progress * 360))
    }

    // MARK: - Triggered

    /// 达到阈值后提示松手刷新
    private var triggeredView: some View {
        Text("松开刷新")
            .font(.subheadline)
            .foreGColor(.gray)
    }

    // MARK: - Refreshing

    /// 刷新中旋转指示器
    private var refreshingView: some View {
        Image(systemName: "swirl.circle.righthalf.filled")
            .font(.system(size: 20, weight: .medium))
            .foreGColor(.red)
            .rotationEffect(.degrees(isRefreshing ? 0 : 360))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isRefreshing = true
                }
            }
            .onDisappear {
                isRefreshing = false
            }
    }

    // MARK: - Completed

    /// 刷新完成
    private var completedView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foreGColor(.green)
            Text("刷新完成")
                .font(.subheadline)
                .foreGColor(.gray)
        }
    }
}

// MARK: - Default Load More Footer

/// 默认上拉加载更多底部视图
public struct DefaultLoadMoreFooter: View, @MainActor Equatable {
    public let state: LoadMoreState
    @State private var isRefreshing: Bool = false

    public init(state: LoadMoreState) {
        self.state = state
    }

    public var body: some View {
        ZStack {
            switch state {
            case .idle:
                Image(systemName: "swirl.circle.righthalf.filled")
                    .font(.system(size: 20, weight: .medium))
                    .foreGColor(.red)
            case .pulling(let progress):
                Image(systemName: "swirl.circle.righthalf.filled")
                    .font(.system(size: 20, weight: .medium))
                    .foreGColor(.red)
                    .rotationEffect(.degrees(-progress * 360))
            case .triggered:
                Text("松开加载")
                    .font(.subheadline)
                    .foreGColor(.gray)
            case .loading:
                Image(systemName: "swirl.circle.righthalf.filled")
                    .font(.system(size: 20, weight: .medium))
                    .foreGColor(.red)
                    .rotationEffect(.degrees(isRefreshing ? 0 : 360))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            isRefreshing = true
                        }
                    }
                    .onDisappear {
                        isRefreshing = false
                    }
            case .completed:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foreGColor(.green)
                    Text("刷新完成")
                        .font(.subheadline)
                        .foreGColor(.gray)
                }
            case .noMore:
                Text("没有更多了")
                    .font(.subheadline)
                    .foreGColor(.gray)
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }
    
    // Equatable 优化：帮助 SwiftUI 跳过不必要的 diff 计算
    public static func == (lhs: DefaultLoadMoreFooter, rhs: DefaultLoadMoreFooter) -> Bool {
        lhs.state == rhs.state
    }
}

extension LoadMoreState {
    var pullProgress: CGFloat {
        if case .pulling(let p) = self { return p }
        return 0
    }
}


extension View {
    func foreGColor(_ color: Color) -> some View {
        if #available(iOS 15.0, *) {
            return self.foregroundStyle(color)
        } else {
            return self.foregroundColor(color)
        }
    }
}
