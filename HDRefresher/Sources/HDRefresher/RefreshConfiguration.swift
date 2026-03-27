import SwiftUI

/// 刷新配置，支持链式调用设置各项参数
public struct RefreshConfiguration {
    /// 触发刷新的下拉阈值（默认 60pt）
    public var threshold: CGFloat

    /// 刷新中保持的偏移量，为 nil 时使用 threshold 值
    public var refreshingOffset: CGFloat?

    /// 刷新完成后停留时长（默认 0.5s）
    public var completedDuration: TimeInterval

    /// 下拉/刷新过程中的动画
    public var animation: Animation

    /// 回弹重置动画
    public var resetAnimation: Animation

    /// 获取实际的刷新偏移量，若未设置则回退到 threshold
    public var effectiveRefreshingOffset: CGFloat {
        refreshingOffset ?? threshold
    }
    
    public init(
        threshold: CGFloat = 80,
        refreshingOffset: CGFloat? = nil,
        completedDuration: TimeInterval = 0.5,
        animation: Animation = .spring(response: 0.35, dampingFraction: 0.85),
        resetAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.9)
    ) {
        self.threshold = threshold
        self.refreshingOffset = refreshingOffset
        self.completedDuration = completedDuration
        self.animation = animation
        self.resetAnimation = resetAnimation
    }

    public func threshold(_ v: CGFloat) -> Self {
        var copy = self
        copy.threshold = v
        return copy
    }

    public func refreshingOffset(_ v: CGFloat) -> Self {
        var copy = self
        copy.refreshingOffset = v
        return copy
    }

    public func completedDuration(_ v: TimeInterval) -> Self {
        var copy = self
        copy.completedDuration = v
        return copy
    }

    public func animation(_ v: Animation) -> Self {
        var copy = self
        copy.animation = v
        return copy
    }

    public func resetAnimation(_ v: Animation) -> Self {
        var copy = self
        copy.resetAnimation = v
        return copy
    }
}
