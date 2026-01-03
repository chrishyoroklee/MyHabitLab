import SwiftUI

struct ConfettiModifier: ViewModifier {
    @State private var circleSize: CGFloat = 0.0
    @State private var strokeMultiplier: CGFloat = 1.0
    @State private var confettiIsHidden = true
    @State private var confettiMovement = false
    
    @Binding var counter: Int
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if !confettiIsHidden {
                ZStack {
                    ForEach(0..<20) { index in
                        Circle()
                            .fill(Color(
                                red: .random(in: 0...1),
                                green: .random(in: 0...1),
                                blue: .random(in: 0...1)
                            ))
                            .frame(width: 8, height: 8)
                            .modifier(ConfettiGeometryEffect(time: confettiMovement ? 1 : 0))
                            .opacity(confettiMovement ? 0 : 1)
                    }
                }
            }
        }
        .onChange(of: counter) { _, _ in
            guard counter > 0 else { return }
            
            // Reset
            confettiIsHidden = false
            confettiMovement = false
            
            withAnimation(.easeOut(duration: 1.2)) {
                confettiMovement = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                confettiIsHidden = true
            }
        }
    }
}

struct ConfettiGeometryEffect: GeometryEffect {
    var time: Double
    var speed = Double.random(in: 100...200)
    var direction = Double.random(in: -Double.pi...Double.pi)
    
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let xTranslation = speed * cos(direction) * time
        let yTranslation = speed * sin(direction) * time
        let affineTranslation =  CGAffineTransform(translationX: xTranslation, y: yTranslation)
        return ProjectionTransform(affineTranslation)
    }
}

extension View {
    func confetti(counter: Binding<Int>) -> some View {
        self.modifier(ConfettiModifier(counter: counter))
    }
}
