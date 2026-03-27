import SwiftUI
import UIKit

// MARK: - RefreshModifier

struct RefreshModifier<Header: View>: ViewModifier {

    let configuration: RefreshConfiguration
    let action: @Sendable () async -> Void
    let header: (RefreshState, CGFloat) -> Header

    func body(content: Content) -> some View {
        HDRefreshableScrollView(
            configuration: configuration,
            action: action,
            header: header
        ) {
            content
        }
    }
}

// MARK: - RefreshableScrollView

struct HDRefreshableScrollView<Content: View, Header: View>: UIViewRepresentable {

    let configuration: RefreshConfiguration
    let action: @Sendable () async -> Void
    let header: (RefreshState, CGFloat) -> Header
    let content: Content

    init(
        configuration: RefreshConfiguration,
        action: @Sendable @escaping () async -> Void,
        @ViewBuilder header: @escaping (RefreshState, CGFloat) -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = configuration
        self.action = action
        self.header = header
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let headerHost = context.coordinator.headerHostingController
        headerHost.view.backgroundColor = .clear
        scrollView.addSubview(headerHost.view)

        let contentHost = context.coordinator.contentHostingController
        contentHost.view.backgroundColor = .clear
        scrollView.addSubview(contentHost.view)

        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        coordinator.updateContent()
        coordinator.updateHeaderView()

        DispatchQueue.main.async {
            coordinator.relayout()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: HDRefreshableScrollView
        weak var scrollView: UIScrollView?

        var refreshState: RefreshState = .idle
        var progress: CGFloat = 0

        let headerHostingController: UIHostingController<AnyView>
        let contentHostingController: UIHostingController<AnyView>

        private let headerHeight: CGFloat = 60
        private var isRefreshing: Bool = false

        init(parent: HDRefreshableScrollView) {
            self.parent = parent
            self.headerHostingController = UIHostingController(rootView: AnyView(EmptyView()))
            self.contentHostingController = UIHostingController(rootView: AnyView(EmptyView()))
            super.init()
            // 禁用 safe area insets 对 hosting controller 的影响
            headerHostingController._disableSafeArea = true
            contentHostingController._disableSafeArea = true
        }

        func updateContent() {
            contentHostingController.rootView = AnyView(parent.content)
        }

        func updateHeaderView() {
            headerHostingController.rootView = AnyView(
                parent.header(refreshState, progress)
            )
        }

        func relayout() {
            guard let scrollView = scrollView else { return }
            let width = scrollView.bounds.width
            guard width > 0 else { return }

            // 头部：放在 y = -headerHeight，即内容区域上方
            headerHostingController.view.frame = CGRect(
                x: 0, y: -headerHeight,
                width: width, height: headerHeight
            )

            // 内容：计算 intrinsic size
            let fittingSize = contentHostingController.sizeThatFits(in:
                CGSize(width: width, height: .greatestFiniteMagnitude)
            )
            let contentHeight = max(fittingSize.height, scrollView.bounds.height)
            contentHostingController.view.frame = CGRect(
                x: 0, y: 0,
                width: width, height: contentHeight
            )
            scrollView.contentSize = CGSize(width: width, height: contentHeight)
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // offset: 正值 = 下拉
            let offset = -(scrollView.contentOffset.y + scrollView.contentInset.top)

            guard !isRefreshing else { return }

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

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            guard refreshState == .triggered else { return }
            startRefreshing()
        }

        // MARK: - Refresh Logic

        private func startRefreshing() {
            guard let scrollView = scrollView else { return }
            isRefreshing = true
            refreshState = .refreshing
            updateHeaderView()

            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                scrollView.contentInset.top = self.headerHeight
            } completion: { _ in
                // 确保 contentOffset 停在正确位置
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
            guard scrollView != nil else { return }
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
                }
            }
        }
    }
}
