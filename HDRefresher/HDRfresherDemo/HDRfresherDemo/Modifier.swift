import SwiftUI

struct FadeInOutRepeatStyle: ViewModifier {
    let duration: Double
    var minimumOpacity: Double = 0
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                startAnimation()
            }
    }
    
    private func startAnimation() {
        withAnimation(
            Animation
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
        ) {
            opacity = max(1 - opacity, minimumOpacity)
        }
    }
}

struct FadeTransition: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transition(.opacity.animation(.easeInOut(duration: 0.5)))
    }
}
