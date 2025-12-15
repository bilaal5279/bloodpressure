import SwiftUI
import SwiftData
import Charts

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "7 Days"
    case month = "30 Days"
    case all = "All Time"
    case custom = "Custom"
    
    var id: String { self.rawValue }
}

struct InsightsView: View {
    @Query(sort: \BPLog.date, order: .forward) var logs: [BPLog]
    @State private var selectedRange: TimeRange = .week
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var customEndDate = Date()
    @State private var selectedBPDate: Date? // Independent state for BP chart
    @State private var selectedHRDate: Date? // Independent state for HR chart
    
    // MARK: - Computed Data
    var filteredLogs: [BPLog] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedRange {
        case .week:
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
            return logs.filter { $0.date >= startDate }
        case .month:
            guard let startDate = calendar.date(byAdding: .day, value: -30, to: now) else { return [] }
            return logs.filter { $0.date >= startDate }
        case .all:
            return logs
        case .custom:
            return logs.filter { $0.date >= customStartDate && $0.date <= customEndDate }
        }
    }
    
    var averagedBP: (sys: Int, dia: Int)? {
        let bpLogs = filteredLogs.filter { ($0.systolic ?? 0) > 0 }
        guard !bpLogs.isEmpty else { return nil }
        
        let totalSys = bpLogs.reduce(0) { $0 + ($1.systolic ?? 0) }
        let totalDia = bpLogs.reduce(0) { $0 + ($1.diastolic ?? 0) }
        return (totalSys / bpLogs.count, totalDia / bpLogs.count)
    }
    
    var averagedHR: Int? {
        let hrLogs = filteredLogs.filter { ($0.heartRate ?? 0) > 0 }
        guard !hrLogs.isEmpty else { return nil }
        
        let total = hrLogs.reduce(0) { $0 + ($1.heartRate ?? 0) }
        return total / hrLogs.count
    }
    
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.offWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time Range Picker
                        Picker("Range", selection: $selectedRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if selectedRange == .custom {
                            HStack {
                                DatePicker("Start", selection: $customStartDate, displayedComponents: .date)
                                    .labelsHidden()
                                Text("-")
                                    .foregroundColor(.gray)
                                DatePicker("End", selection: $customEndDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }
                        
                        if filteredLogs.isEmpty {
                            EmptyStateView()
                        } else {
                            // Summary Cards
                            HStack(spacing: 16) {
                                if let bp = averagedBP {
                                    SummaryCard(title: "Avg BP", value: "\(bp.sys)/\(bp.dia)", unit: "mmHg", color: .softTeal, icon: "drop.fill")
                                }
                                if let hr = averagedHR {
                                    SummaryCard(title: "Avg HR", value: "\(hr)", unit: "BPM", color: .softRed, icon: "heart.fill")
                                }
                            }
                            .padding(.horizontal)
                            
                            // BP Chart
                            ChartCard(title: "Blood Pressure Trends", icon: "waveform.path.ecg", accent: .softTeal) {
                                BPChartContent(logs: filteredLogs, selectedDate: $selectedBPDate)
                            }
                            
                            // HR Chart
                            ChartCard(title: "Heart Rate Trends", icon: "heart.text.square.fill", accent: .softRed) {
                                HRChartContent(logs: filteredLogs, selectedDate: $selectedHRDate)
                            }
                            
                            // Health Breakdown
                            NavigationLink(destination: HealthDetailView(logs: filteredLogs)) {
                                HealthBreakdownCard(logs: filteredLogs)
                            }
                            
                            Spacer().frame(height: 40)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.offWhite, for: .navigationBar)
        }
    }
}

// MARK: - Subviews

struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                    .padding(6)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.slate)
                
                Text(unit)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.pureWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.2))
            Text("No Data for this Period")
                .font(.headline)
                .foregroundColor(.slate)
            Text("Try selecting a different range or add new logs.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(height: 300)
    }
}

struct HealthBreakdownCard: View {
    let logs: [BPLog]
    
    var normalCount: Int {
        logs.filter { MedicalStandards.analyzeBP(systolic: $0.systolic ?? 0, diastolic: $0.diastolic ?? 0) == .normal }.count
    }
    
    var elevatedCount: Int {
        logs.filter {
            let cat = MedicalStandards.analyzeBP(systolic: $0.systolic ?? 0, diastolic: $0.diastolic ?? 0)
            return cat == .elevated || cat == .highStage1 || cat == .highStage2
        }.count
    }
    
    var hasBPData: Bool {
        logs.contains { ($0.systolic ?? 0) > 0 }
    }
    
    var body: some View {
        if hasBPData {
            VStack(alignment: .leading, spacing: 16) {
                Text("Health Overview")
                    .font(.headline)
                    .foregroundColor(.slate)
                
                HStack(spacing: 0) {
                    if normalCount > 0 {
                        Rectangle()
                            .fill(Color.softTeal)
                            .frame(height: 8)
                            .frame(maxWidth: .infinity * CGFloat(normalCount) / CGFloat(normalCount + elevatedCount))
                    }
                    
                    if elevatedCount > 0 {
                        Rectangle()
                            .fill(Color.softRed)
                            .frame(height: 8)
                            .frame(maxWidth: .infinity * CGFloat(elevatedCount) / CGFloat(normalCount + elevatedCount))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                HStack {
                    Label("\(normalCount) Normal", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.softTeal)
                        .font(.caption)
                    
                    Spacer()
                    
                    Label("\(elevatedCount) Elevated+", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.softRed)
                        .font(.caption)
                        
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.leading, 4)
                }
            }
            .padding()
            .background(Color.pureWhite)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
        }
    }
}

// MARK: - Extracted Chart Content to reduce compiler complexity
struct BPChartContent: View {
    let logs: [BPLog]
    @Binding var selectedDate: Date?
    
    var body: some View {
        Chart {
            ForEach(logs) { log in
                if let sys = log.systolic, let dia = log.diastolic, sys > 0 {
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Systolic", sys)
                    )
                    .foregroundStyle(Color.softRed)
                    .interpolationMethod(.catmullRom)
                    .symbol(by: .value("Type", "Systolic"))
                    
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Diastolic", dia)
                    )
                    .foregroundStyle(Color.softTeal)
                    .interpolationMethod(.catmullRom)
                    .symbol(by: .value("Type", "Diastolic"))
                    
                    AreaMark(
                        x: .value("Date", log.date),
                        yStart: .value("Min", dia),
                        yEnd: .value("Max", sys)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [Color.softRed.opacity(0.1), Color.softTeal.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)
                }
            }
            
            if let selectedDate, let log = findClosestLog(to: selectedDate, logs: logs) {
                RuleMark(x: .value("Selected", log.date))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .annotation(position: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            if let sys = log.systolic, let dia = log.diastolic {
                                Text("\(sys)/\(dia) mmHg")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.slate)
                            }
                        }
                        .padding(8)
                        .background(Color.pureWhite)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                    }
            }
        }
        .chartForegroundStyleScale([
            "Systolic": Color.softRed,
            "Diastolic": Color.softTeal
        ])
        .chartYScale(domain: 40...200)
        .chartXSelection(value: $selectedDate)
    }
    
    func findClosestLog(to date: Date, logs: [BPLog]) -> BPLog? {
        logs.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
}

struct HRChartContent: View {
    let logs: [BPLog]
    @Binding var selectedDate: Date?
    
    var body: some View {
        Chart {
            ForEach(logs) { log in
                if let hr = log.heartRate, hr > 0 {
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("BPM", hr)
                    )
                    .foregroundStyle(Color.softRed)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", log.date),
                        y: .value("BPM", hr)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.softRed.opacity(0.3), Color.softRed.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            
            if let selectedDate, let log = findClosestLog(to: selectedDate, logs: logs) {
                RuleMark(x: .value("Selected", log.date))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .annotation(position: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            if let hr = log.heartRate {
                                Text("\(hr) BPM")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.slate)
                            }
                        }
                        .padding(8)
                        .background(Color.pureWhite)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                    }
            }
        }
        .chartYScale(domain: 40...180)
        .chartXSelection(value: $selectedDate)
    }
    
    func findClosestLog(to date: Date, logs: [BPLog]) -> BPLog? {
        logs.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.slate)
                Spacer()
            }
            
            content
                .frame(height: 200)
        }
        .padding()
        .background(Color.pureWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}
