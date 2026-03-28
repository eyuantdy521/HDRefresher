//
//  HDRefreshHeader.swift
//  HDRfresherDemo
//
//  Created by Chris on 2026/3/27.
//

import HDRefresher
import Lottie
import SwiftUI

struct LottieRefreshHeader: View, Equatable {
    let state: RefreshState
    let progress: CGFloat

    static func == (lhs: LottieRefreshHeader, rhs: LottieRefreshHeader) -> Bool {
        lhs.state == rhs.state && lhs.progress == rhs.progress
    }

    var body: some View {
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
            .modifier(FadeTransition())
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }

    private var idlePullingView: some View {
        LottieView(animation: .named("refresh_progressing"))
            .fillColor(.blue)
            .playing(.fromProgress(progress, toProgress: progress, loopMode: .playOnce))
            .frame(maxWidth: .infinity, maxHeight: 30)
    }

    private var triggeredView: some View {
        LottieView(animation: .named("refresh_progressing"))
            .fillColor(.red)
            .frame(maxWidth: .infinity, maxHeight: 30)
            .modifier(FadeInOutRepeatStyle(duration: 1))
    }
    
    private var refreshingView: some View {
        LottieView(animation: .named("refresh_progressing"))
            .fillColor(.red)
            .playing(loopMode: .loop)
            .frame(maxWidth: .infinity, maxHeight: 30)
    }
    
    private var completedView: some View {
        LottieView(animation: .named("refresh_complete"))
            .fillColor(.blue)
            .playing(loopMode: .playOnce)
            .animationSpeed(2)
            .frame(maxWidth: .infinity, maxHeight: 30)
    }
}


extension LottieView {
    func fillColor(_ color: UIColor) -> LottieView<Placeholder> {
        self
            .configure { view in
                let keyPath = AnimationKeypath(keypath: "**.Fill 1.Color")
                let newColor = ColorValueProvider(color.lottieColorValue)
                view.setValueProvider(newColor, keypath: keyPath)
            }
    }
}
