import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50) { i in
                    ConfettiParticle(animate: $animate, index: i, size: geometry.size)
                }
            }
            .onAppear {
                animate = true
            }
        }
    }
}

struct ConfettiParticle: View {
    @Binding var animate: Bool
    let index: Int
    let size: CGSize
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    
    let colors: [Color] = [.softRed, .softTeal, .softOrange, .yellow, .blue]
    
    var body: some View {
        let randomColor = colors.randomElement()!
        
        Rectangle()
            .fill(randomColor)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .onAppear {
                // Start position (top, random x)
                let startX = Double.random(in: 0...size.width)
                position = CGPoint(x: startX, y: -50)
                
                // Animation
                if animate {
                    withAnimation(
                        .interpolatingSpring(stiffness: 50, damping: 5)
                        .speed(Double.random(in: 0.5...1.5))
                        .delay(Double.random(in: 0...0.5))
                        .repeatForever(autoreverses: false) // Or just play once for simple effect
                    ) {
                        position = CGPoint(x: startX + Double.random(in: -50...50), y: size.height + 50)
                        rotation = Double.random(in: 0...360)
                    }
                }
            }
    }
}
