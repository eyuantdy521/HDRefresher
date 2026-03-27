import SwiftUI

/// 刷新状态枚举，驱动整个刷新流程
public enum RefreshState: Equatable {
    /// 空闲，未触发任何下拉
    case idle
    /// 正在下拉，尚未达到阈值
    case pulling(progress: CGFloat)
    /// 已达到阈值，松手即触发刷新
    case triggered
    /// 正在执行刷新操作
    case refreshing
    /// 刷新完成，即将回弹
    case completed
}

/// 根据偏移量和阈值计算下拉进度，结果 clamped 到 0.0~1.0
/// - Parameters:
///   - offset: 当前下拉偏移量
///   - threshold: 触发刷新的阈值
/// - Returns: 进度值，范围 [0.0, 1.0]
func calculateProgress(offset: CGFloat, threshold: CGFloat) -> CGFloat {
    guard offset > 0, threshold > 0 else { return 0 }
    return min(offset / threshold, 1.0)
}
