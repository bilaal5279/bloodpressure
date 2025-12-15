import SwiftUI

struct BPCardView: View {
    let log: BPLog
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: Time
            HStack {
                Text(log.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Card 1: Blood Pressure
            if let systolic = log.systolic, let diastolic = log.diastolic {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(bpColor)
                            .font(.title3)
                        Text("Blood Pressure")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.slate)
                        Spacer()
                        Text(bpCategory)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(bpColor.opacity(0.1))
                            .foregroundColor(bpColor)
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Systolic")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            Text("\(systolic)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.slate)
                            Text("mmHg")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Diastolic")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            Text("\(diastolic)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.slate)
                            Text("mmHg")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Detailed Gauge
                    DetailedGaugeView(value: Double(systolic), minValue: 70, maxValue: 180, segments: MedicalStandards.systolicRanges)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(Color.pureWhite)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
            
            // Card 2: Pulse
            if let heartRate = log.heartRate {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.softRed)
                            .font(.title3)
                        Text("Pulse")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.slate)
                        Spacer()
                        Text(hrCategory) // Placeholder logic for now
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(hrColor.opacity(0.1))
                            .foregroundColor(hrColor)
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Heart Rate")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            Text("\(heartRate)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.slate)
                            Text("BPM")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Detailed Gauge (Pulse)
                    DetailedGaugeView(value: Double(heartRate), minValue: 40, maxValue: 140, segments: MedicalStandards.heartRateRanges)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(Color.pureWhite)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    var bpColor: Color {
        guard let systolic = log.systolic, let diastolic = log.diastolic else { return .gray }
        return MedicalStandards.analyzeBP(systolic: systolic, diastolic: diastolic).color
    }
    
    var bpCategory: String {
        guard let systolic = log.systolic, let diastolic = log.diastolic else { return "N/A" }
        return MedicalStandards.analyzeBP(systolic: systolic, diastolic: diastolic).displayName
    }
    
    var hrColor: Color {
        guard let hr = log.heartRate else { return .gray }
        return MedicalStandards.analyzeHR(hr).color
    }
    
    var hrCategory: String {
        guard let hr = log.heartRate else { return "N/A" }
        return MedicalStandards.analyzeHR(hr).rawValue
    }
}


#Preview {
    ZStack {
        Color.offWhite.ignoresSafeArea()
        BPCardView(log: BPLog(systolic: 120, diastolic: 80, heartRate: 72))
            .padding()
    }
}
