//
//  LottieHeaderView.swift
//  HDRfresherDemo
//
//  Created by Chris on 2026/3/27.
//

import SwiftUI
import HDRefresher

struct LottieHeaderView: View {
    var body: some View {
        VStack {
            ForEach(0..<30) { index in
                Spacer().frame(height: 20)
                Text("这是第\(index+1)行")
                    .font(.system(size: 14, weight: .medium))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(radius: 4)
                    )
                    .offset(x: CGFloat.random(in: -(kScreenWidth - 100)/2...(kScreenWidth - 100)/2))
            }
        }
        .pullToRefresh(config: .init(completedDuration: 3), action: {
            try? await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000))
        }, header: { state, progress in
            LottieRefreshHeader(state: state, progress: progress)
                .equatable()
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
