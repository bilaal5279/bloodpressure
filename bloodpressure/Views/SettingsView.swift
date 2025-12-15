import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var revenueCat = RevenueCatManager.shared
    @Environment(\.modelContext) var modelContext
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("hasLoggedFirstTime") var hasLoggedFirstTime: Bool = false
    @State private var showDevAlert = false
    @State private var showExportSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Premium")) {
                    Button(action: {
                        revenueCat.restore { _ in }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.softRed)
                            Text("Restore Purchase")
                                .foregroundColor(.slate)
                        }
                    }
                }
                
                Section(header: Text("Support")) {
                    Link(destination: URL(string: "mailto:info@digitalsprout.org")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Contact Us")
                                .foregroundColor(.slate)
                        }
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com/app/idYOUR_ID?action=write-review")!) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Rate App")
                                .foregroundColor(.slate)
                        }
                    }
                    
                    // Share App would be a ShareLink in iOS 16+ or custom UIActivityViewController
                }
                
                Section(header: Text("Legal")) {
                    Link("Privacy Policy", destination: URL(string: "https://digitalsprout.org/bp/privacypolicy")!)
                        .foregroundColor(.slate)
                    Link("Terms of Service", destination: URL(string: "https://digitalsprout.org/bp/terms-of-service")!)
                        .foregroundColor(.slate)
                }
                
                Section(header: Text("Data")) {
                    Button(action: {
                        showExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            .foregroundColor(.blue)
                            Text("Export Data (CSV)")
                            .foregroundColor(.slate)
                        }
                    }
                }
                
                Section {
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section {
                    Text("Disclaimer: This application is for informational purposes only and does not constitute medical advice. Always consult a healthcare professional for diagnosis or treatment.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                }
                
                #if DEBUG
                Section(header: Text("Developer Mode")) {
                    Button(action: generateMockData) {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.purple)
                            Text("Generate Mock Data")
                                .foregroundColor(.slate)
                        }
                    }
                    .alert("Success", isPresented: $showDevAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Added 20 random logs.")
                    }
                    
                    Button(action: clearAllData) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Remove All Data")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: resetOnboarding) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.orange)
                            Text("Reset Onboarding")
                                .foregroundColor(.slate)
                        }
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExportSheet) {
                ExportView()
            }
        }
    }
    
    // ... helper functions ...
    func generateMockData() {
        for _ in 0..<20 {
            let daysAgo = Int.random(in: 0...30)
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            
            // Randomize types: BP only, HR only, or Both
            let type = Int.random(in: 0...2)
            
            var sys = 0
            var dia = 0
            var hr = 0
            
            if type == 0 || type == 2 { // BP
                sys = Int.random(in: 110...150)
                dia = Int.random(in: 70...95)
            }
            
            if type == 1 || type == 2 { // HR
                hr = Int.random(in: 60...100)
            }
            
            let log = BPLog(systolic: sys, diastolic: dia, heartRate: hr, date: date)
            modelContext.insert(log)
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        showDevAlert = true
    }
    
    func clearAllData() {
        do {
            try modelContext.delete(model: BPLog.self)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasLoggedFirstTime = false
        
        // Optional: Trigger haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    SettingsView()
}

// MARK: - Export View
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \BPLog.date, order: .reverse) var logs: [BPLog]
    
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate = Date()
    
    var filteredLogs: [BPLog] {
        logs.filter { log in
            log.date >= Calendar.current.startOfDay(for: startDate) &&
            log.date <= Calendar.current.endOfDay(for: endDate)
        }
    }
    
    var csvDocument: CSVDocument {
        let header = "Date,Time,Systolic (mmHg),Diastolic (mmHg),Heart Rate (BPM),Category\n"
        let rows = filteredLogs.map { log -> String in
            let dateStr = log.date.formatted(date: .numeric, time: .omitted)
            let timeStr = log.date.formatted(date: .omitted, time: .shortened)
            let sys = log.systolic.map(String.init) ?? ""
            let dia = log.diastolic.map(String.init) ?? ""
            let hr = log.heartRate.map(String.init) ?? ""
            
            // Determine Category
            var category = "-"
            if let s = log.systolic, let d = log.diastolic, s > 0 {
                category = MedicalStandards.analyzeBP(systolic: s, diastolic: d).displayName
            }
            
            return "\(dateStr),\(timeStr),\(sys),\(dia),\(hr),\(category)"
        }.joined(separator: "\n")
        
        return CSVDocument(initialText: header + rows)
    }
    
    var csvURL: URL {
        let fileName = "Blood_Pressure_History.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? csvDocument.text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    HStack {
                        Text("Total Readings")
                        Spacer()
                        Text("\(filteredLogs.count)")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    ShareLink(item: csvURL) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export to CSV")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfDay(for: date))!
    }
}

// MARK: - CSV Document
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String
    
    init(initialText: String = "") {
        self.text = initialText
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
