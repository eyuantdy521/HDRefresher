//
//  ContentView.swift
//  HDRfresherDemo
//
//  Created by Chris on 2026/3/27.
//

import SwiftUI
import HDRefresher
import Lottie

let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width

struct ContentView: View {
    
    enum Title: String, CaseIterable {
        case `default`
        case lottie
    }
    
    let titles: [Title] = Title.allCases
    var body: some View {
        NavigationStack {
            List(titles, id: \.self) { title in
                NavigationLink {
                    switch title {
                    case .default:
                        DefaultHeaderView()
                            .navigationTitle(
                                Text(title.rawValue)
                            )
                    case .lottie:
                        LottieHeaderView()
                            .navigationTitle(
                                Text(title.rawValue)
                            )
                    }
                } label: {
                    HStack {
                        Text(title.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .padding(8)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
