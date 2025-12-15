import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var revenueCat = RevenueCatManager.shared
    @Environment(\.modelContext) var modelContext
    @State private var showDevAlert = false
    
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
                    Link(destination: URL(string: "mailto:support@example.com")!) {
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
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        .foregroundColor(.slate)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                        .foregroundColor(.slate)
                }
                
                Section {
                    Text("Version 1.0.0 (1)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
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
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
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
}

#Preview {
    SettingsView()
}
