import SwiftUI

struct RulerPicker: View {
    var range: ClosedRange<Int>
    @Binding var value: Int
    var label: String
    
    @State private var offset: CGFloat = 0
    private let tickWidth: CGFloat = 2
    private let tickSpacing: CGFloat = 12
    
    var body: some View {
        VStack(spacing: 16) {
            // Value Display
            VStack {
                 Text(label.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text("\(value)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.slate)
            }
            
            // The Ruler
            GeometryReader { geometry in
                let midPoint = geometry.size.width / 2
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: tickSpacing) {
                        ForEach(range, id: \.self) { i in
                            TickMark(isMajor: i % 10 == 0, isCurrent: i == value)
                                .frame(width: tickWidth)
                                .id(i)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        value = i
                                        UISelectionFeedbackGenerator().selectionChanged()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, midPoint)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: .init(get: { value }, set: { if let new = $0 { value = new } }), anchor: .center)
            }
            .frame(height: 60)
            .mask(
                LinearGradient(gradient: Gradient(colors: [.clear, .black, .black, .clear]), startPoint: .leading, endPoint: .trailing)
            )
            
            // Pointer
            Image(systemName: "arrowtriangle.up.fill")
                .foregroundColor(.softRed)
                .offset(y: -10)
        }
    }
}

struct TickMark: View {
    let isMajor: Bool
    let isCurrent: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(isCurrent ? Color.slate : (isMajor ? Color.gray : Color.gray.opacity(0.3)))
                .frame(height: isMajor || isCurrent ? 40 : 25)
                .scaleEffect(isCurrent ? 1.2 : 1.0)
                .animation(.spring, value: isCurrent)
        }
    }
}
