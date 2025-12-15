import SwiftUI

struct GaugeSegment {
    let start: Double
    let end: Double
    let color: Color
    let label: String?
}

struct DetailedGaugeView: View {
    let value: Double
    let minValue: Double
    let maxValue: Double
    let segments: [GaugeSegment] // Updated from simpler tuple
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                // The Gauge Bar
                ZStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        ForEach(0..<segments.count, id: \.self) { index in
                            let segment = segments[index]
                            let width = calculateSegmentWidth(segment: segment, totalWidth: geometry.size.width)
                            Rectangle()
                                .fill(segment.color.opacity(0.3))
                                .frame(width: width)
                        }
                    }
                    .clipShape(Capsule())
                    .frame(height: 8)
                    
                    // Marker
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.caption)
                        .foregroundColor(.slate)
                        .offset(x: calculateMarkerOffset(totalWidth: geometry.size.width) - 6, y: -12)
                }
                
                // Labels Row
                ZStack(alignment: .topLeading) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        if let labelText = segments[index].label {
                            let offset = calculateLabelCenter(segment: segments[index], totalWidth: geometry.size.width)
                            Text(labelText)
                                .font(.system(size: 10, weight: .bold)) // Small font to fit
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .fixedSize()
                                .position(x: offset, y: 8) // Center X on segment center
                        }
                    }
                }
                .frame(height: 16) // Reserve space for labels
            }
        }
        .frame(height: 32) // Total height increased for labels
    }
    
    func calculateSegmentWidth(segment: GaugeSegment, totalWidth: CGFloat) -> CGFloat {
        let totalRange = maxValue - minValue
        
        // Clamp to visible
        let visibleStart = max(segment.start, minValue)
        let visibleEnd = min(segment.end, maxValue)
        
        if visibleEnd <= visibleStart { return 0 }
        
        let rangeSpan = visibleEnd - visibleStart
        return max(0, (totalWidth * CGFloat(rangeSpan / totalRange)) - 2)
    }
    
    func calculateLabelCenter(segment: GaugeSegment, totalWidth: CGFloat) -> CGFloat {
        let totalRange = maxValue - minValue
        
        let visibleStart = max(segment.start, minValue)
        let visibleEnd = min(segment.end, maxValue)
        
        if visibleEnd <= visibleStart { return -1000 } // Hide if not visible
        
        let centerValue = (visibleStart + visibleEnd) / 2
        let percentage = (centerValue - minValue) / totalRange
        
        return totalWidth * CGFloat(percentage)
    }
    
    func calculateMarkerOffset(totalWidth: CGFloat) -> CGFloat {
        let totalRange = maxValue - minValue
        let clampedValue = min(max(value, minValue), maxValue)
        let percentage = (clampedValue - minValue) / totalRange
        return totalWidth * CGFloat(percentage)
    }
}
