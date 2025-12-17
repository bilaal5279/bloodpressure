import SwiftUI
import SwiftData

struct HealthDetailView: View {
    let logs: [BPLog]
    
    // Group logs by category (Only valid BP logs)
    var groupedLogs: [(MedicalStandards.BPCategory, [BPLog])] {
        let groups = Dictionary(grouping: logs.filter { ($0.systolic ?? 0) > 0 }) { log in
            MedicalStandards.analyzeBP(systolic: log.systolic ?? 0, diastolic: log.diastolic ?? 0)
        }
        
        // Return sorted by severity (Low -> Normal -> Elevated -> High)
        let order: [MedicalStandards.BPCategory] = [.normal, .elevated, .highStage1, .highStage2, .low]
        return order.compactMap { category in
            if let items = groups[category], !items.isEmpty {
                return (category, items.sorted(by: { $0.date > $1.date }))
            }
            return nil
        }
    }
    
    // Pulse Only Logs (No BP data)
    var pulseOnlyLogs: [BPLog] {
        logs.filter { ($0.systolic ?? 0) <= 0 && ($0.heartRate ?? 0) > 0 }.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        ZStack {
            Color.offWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if groupedLogs.isEmpty && pulseOnlyLogs.isEmpty {
                        EmptyStateView()
                            .padding(.top, 40)
                    } else {
                        // BP Sections
                        ForEach(groupedLogs, id: \.0) { category, logs in
                            Section(header: HeaderView(category: category, count: logs.count)) {
                                ForEach(logs) { log in
                                    HealthLogRow(log: log, category: category)
                                }
                            }
                        }
                        
                        // Pulse Only Section
                        if !pulseOnlyLogs.isEmpty {
                            Section(header: PulseHeaderView(count: pulseOnlyLogs.count)) {
                                ForEach(pulseOnlyLogs) { log in
                                    PulseOnlyRow(log: log)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Health Breakdown")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

struct HeaderView: View {
    let category: MedicalStandards.BPCategory
    let count: Int
    
    var body: some View {
        HStack {
            Text(category.displayName)
                .font(.headline)
                .foregroundColor(.slate)
            
            Spacer()
            
            Text("\(count) readings")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.pureWhite)
                .cornerRadius(8)
            
            InfoButton(type: .bloodPressure)
        }
        .padding(.top, 8)
    }
}

struct PulseHeaderView: View {
    let count: Int
    
    var body: some View {
        HStack {
            Text("Heart Rate Only")
                .font(.headline)
                .foregroundColor(.slate)
            
            Spacer()
            
            Text("\(count) readings")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.pureWhite)
                .cornerRadius(8)
            
            InfoButton(type: .heartRate)
        }
        .padding(.top, 8)
    }
}

struct HealthLogRow: View {
    let log: BPLog
    let category: MedicalStandards.BPCategory
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(log.systolic ?? 0)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(category.color)
                    Text("/")
                        .font(.body)
                        .foregroundColor(.gray)
                    Text("\(log.diastolic ?? 0)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(category.color)
                    Text("mmHg")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let hr = log.heartRate, hr > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.softRed)
                    Text("\(hr)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.slate)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.offWhite)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.pureWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

struct PulseOnlyRow: View {
    let log: BPLog
    
    var body: some View {
        HStack {
            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            if let hr = log.heartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.softRed)
                    Text("\(hr)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.slate)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.offWhite)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.pureWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    HealthDetailView(logs: [])
}
