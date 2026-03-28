import SwiftUI
import UIKit

public struct HDRefreshableScrollView<Content: View, Header: View>: UIViewRepresentable {

    let configuration: RefreshConfiguration
    let action: @Sendable () async -> Void
    let header: (RefreshState, CGFloat) -> Header
    var loadMoreAction: (@Sendable () async -> Void)?
    var loadMoreAutoTrigger: Bool = false
    var footer: ((LoadMoreState) -> AnyView)?
    let content: Content

    init(
        configuration: RefreshConfiguration = .init(),
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder header: @escaping (RefreshState, CGFloat) -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = configuration
        self.action = action
        self.header = header
        self.content = content()
    }

    /// 链式添加上拉加载更多
    /// - Parameters:
    ///   - autoTrigger: 是否滚到底部自动触发（默认 false，需要松手触发）
    ///   - action: 异步加载操作
    ///   - footer: 底部视图
    public func loadMore<F: View>(
        autoTrigger: Bool = false,
        _ action: @Sendable @escaping () async -> Void,
        @ViewBuilder footer: @escaping (LoadMoreState) -> F
    ) -> HDRefreshableScrollView {
        var copy = self
        copy.loadMoreAction = action
        copy.loadMoreAutoTrigger = autoTrigger
        copy.footer = { state in AnyView(footer(state)) }
        return copy
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        scrollView.addSubview(context.coordinator.headerHostingController.view)
        scrollView.addSubview(context.coordinator.contentHostingController.view)
        scrollView.addSubview(context.coordinator.footerHostingController.view)

        context.coordinator.headerHostingController.view.backgroundColor = .clear
        context.coordinator.contentHostingController.view.backgroundColor = .clear
        context.coordinator.footerHostingController.view.backgroundColor = .clear

        context.coordinator.scrollView = scrollView
        return scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        coordinator.updateContent()
        coordinator.updateHeaderView()
        coordinator.updateFooterView()

        DispatchQueue.main.async {
            coordinator.relayout()
        }
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: HDRefreshableScrollView
        weak var scrollView: UIScrollView?

        var refreshState: RefreshState = .idle
        var progress: CGFloat = 0
        private var isRefreshing: Bool = false

        var loadMoreState: LoadMoreState = .idle
        var loadMoreProgress: CGFloat = 0
        private var isLoadingMore: Bool = false

        let headerHostingController: UIHostingController<AnyView>
        let contentHostingController: UIHostingController<AnyView>
        let footerHostingController: UIHostingController<AnyView>

        private let headerHeight: CGFloat = 60
        private let footerHeight: CGFloat = 60

        init(parent: HDRefreshableScrollView) {
            self.parent = parent
            self.headerHostingController = UIHostingController(rootView: AnyView(EmptyView()))
            self.contentHostingController = UIHostingController(rootView: AnyView(EmptyView()))
            self.footerHostingController = UIHostingController(rootView: AnyView(EmptyView()))
            super.init()
            headerHostingController._disableSafeArea = true
            contentHostingController._disableSafeArea = true
            footerHostingController._disableSafeArea = true
        }

        func updateContent() {
            contentHostingController.rootView = AnyView(parent.content)
        }

        func updateHeaderView() {
            headerHostingController.rootView = AnyView(
                parent.header(refreshState, progress)
            )
        }

        func updateFooterView() {
            if let footer = parent.footer {
                footerHostingController.rootView = AnyView(footer(loadMoreState))
                footerHostingController.view.isHidden = false
            } else {
                footerHostingController.view.isHidden = true
            }
        }

        func relayout() {
            guard let scrollView = scrollView else { return }
            let width = scrollView.bounds.width
            guard width > 0 else { return }

            headerHostingController.view.frame = CGRect(
                x: 0, y: -headerHeight,
                width: width, height: headerHeight
            )

            let fittingSize = contentHostingController.sizeThatFits(in:
                CGSize(width: width, height: .greatestFiniteMagnitude)
            )
            let contentHeight = max(fittingSize.height, scrollView.bounds.height)
            contentHostingController.view.frame = CGRect(
                x: 0, y: 0,
                width: width, height: contentHeight
            )

            if parent.footer != nil {
                footerHostingController.view.frame = CGRect(
                    x: 0, y: contentHeight,
                    width: width, height: footerHeight
                )
            }

            scrollView.contentSize = CGSize(width: width, height: contentHeight)
        }

        // MARK: - UIScrollViewDelegate

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            handlePullToRefresh(scrollView)
            handleLoadMore(scrollView)
        }

        public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if refreshState == .triggered {
                startRefreshing()
            }
            if loadMoreState == .triggered {
                startLoadingMore()
            }
        }

        // MARK: - Pull to Refresh

        private func handlePullToRefresh(_ scrollView: UIScrollView) {
            let offset = -(scrollView.contentOffset.y + scrollView.contentInset.top)
            guard !isRefreshing, !isLoadingMore else { return }

            let threshold = parent.configuration.threshold
            progress = calculateProgress(offset: offset, threshold: threshold)

            switch refreshState {
            case .idle:
                if offset > 0 {
                    refreshState = .pulling(progress: progress)
                    updateHeaderView()
                }
            case .pulling:
                if offset <= 0 {
                    refreshState = .idle
                    progress = 0
                    updateHeaderView()
                } else if offset >= threshold {
                    refreshState = .triggered
                    updateHeaderView()
                } else {
                    refreshState = .pulling(progress: progress)
                    updateHeaderView()
                }
            case .triggered:
                if offset < threshold && scrollView.isDragging {
                    refreshState = .pulling(progress: progress)
                    updateHeaderView()
                }
            default:
                break
            }
        }

        private func startRefreshing() {
            guard let scrollView = scrollView else { return }
            isRefreshing = true
            refreshState = .refreshing
            updateHeaderView()

            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                scrollView.contentInset.top = self.headerHeight
            } completion: { _ in
                if scrollView.contentOffset.y > -self.headerHeight {
                    scrollView.setContentOffset(
                        CGPoint(x: 0, y: -self.headerHeight), animated: true
                    )
                }
            }

            Task { [weak self] in
                await self?.parent.action()
                await MainActor.run { [weak self] in
                    self?.completeRefreshing()
                }
            }
        }

        private func completeRefreshing() {
            refreshState = .completed
            updateHeaderView()

            let duration = parent.configuration.completedDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self = self, let scrollView = self.scrollView else { return }
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                    scrollView.contentInset.top = 0
                } completion: { _ in
                    self.isRefreshing = false
                    self.refreshState = .idle
                    self.progress = 0
                    self.updateHeaderView()
                    self.relayout()
                }
            }
        }

        // MARK: - Load More

        private func handleLoadMore(_ scrollView: UIScrollView) {
            guard parent.loadMoreAction != nil,
                  !isLoadingMore,
                  !isRefreshing,
                  loadMoreState != .noMore,
                  loadMoreState != .loading,
                  loadMoreState != .completed else { return }

            let contentHeight = scrollView.contentSize.height
            let frameHeight = scrollView.bounds.height
            guard contentHeight > 0 else { return }

            let offsetY = scrollView.contentOffset.y
            // 距离底部的剩余距离
            let distanceToBottom = contentHeight - (offsetY + frameHeight)

            // 距离底部小于 footerHeight 时开始触发流程
            if distanceToBottom > footerHeight {
                if loadMoreState != .idle {
                    loadMoreState = .idle
                    loadMoreProgress = 0
                    updateFooterView()
                }
                return
            }

            // 计算进度：从 footerHeight 到 0 映射为 0~1
            loadMoreProgress = calculateProgress(
                offset: footerHeight - max(distanceToBottom, 0),
                threshold: footerHeight
            )

            switch loadMoreState {
            case .idle:
                loadMoreState = .pulling(progress: loadMoreProgress)
                updateFooterView()
            case .pulling:
                if distanceToBottom <= 0 {
                    loadMoreState = .triggered
                    updateFooterView()
                    // autoTrigger 模式下直接触发，否则等松手
                    if parent.loadMoreAutoTrigger {
                        startLoadingMore()
                    }
                } else {
                    loadMoreState = .pulling(progress: loadMoreProgress)
                    updateFooterView()
                }
            case .triggered:
                // 非 autoTrigger 模式下，如果手指拖回来了，回到 pulling
                if distanceToBottom > 0 && scrollView.isDragging {
                    loadMoreState = .pulling(progress: loadMoreProgress)
                    updateFooterView()
                }
            default:
                break
            }
        }

        private func startLoadingMore() {
            guard let scrollView = scrollView,
                  let loadMoreAction = parent.loadMoreAction else { return }
            isLoadingMore = true
            loadMoreState = .loading
            updateFooterView()

            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                scrollView.contentInset.bottom = self.footerHeight
            }

            Task { [weak self] in
                await loadMoreAction()
                await MainActor.run { [weak self] in
                    self?.completeLoadingMore()
                }
            }
        }

        private func completeLoadingMore() {
            guard scrollView != nil else { return }
            loadMoreState = .completed
            updateFooterView()

            let duration = parent.configuration.completedDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self = self, let scrollView = self.scrollView else { return }
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                    scrollView.contentInset.bottom = 0
                } completion: { _ in
                    self.isLoadingMore = false
                    self.loadMoreState = .idle
                    self.loadMoreProgress = 0
                    self.updateFooterView()
                    self.relayout()
                }
            }
        }

        func setNoMoreData() {
            loadMoreState = .noMore
            updateFooterView()
        }

        func resetLoadMore() {
            loadMoreState = .idle
            loadMoreProgress = 0
            updateFooterView()
        }
    }
}

