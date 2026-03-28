import SwiftUI

/// 刷新状态枚举，驱动整个刷新流程
public enum RefreshState: Equatable {
    case idle
    case pulling(progress: CGFloat)
    case triggered
    case refreshing
    case completed
}

/// 上拉加载更多状态，与 RefreshState 对称
public enum LoadMoreState: Equatable {
    /// 空闲
    case idle
    /// 正在上拉，尚未达到阈值
    case pulling(progress: CGFloat)
    /// 已达到阈值，松手即触发加载
    case triggered
    /// 正在加载
    case loading
    /// 加载完成
    case completed
    /// 没有更多数据
    case noMore
}

/// 将偏移量映射为 0~1 的进度
func calculateProgress(offset: CGFloat, threshold: CGFloat) -> CGFloat {
    guard offset > 0, threshold > 0 else { return 0 }
    return min(offset / threshold, 1.0)
}
