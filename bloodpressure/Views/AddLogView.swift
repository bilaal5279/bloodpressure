import SwiftUI
import SwiftData
import StoreKit
 
struct AddLogView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(\.requestReview) var requestReview
    @AppStorage("hasLoggedFirstTime") private var hasLoggedFirstTime = false
    
    @State private var systolic: Int = 120
    @State private var diastolic: Int = 80
    @State private var pulse: Int = 75
    @State private var includePulse: Bool = false
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.offWhite.ignoresSafeArea()
                
                VStack(spacing: 0) { // Main clean container
                    ScrollView {
                        VStack(spacing: 24) {
                            // Date Picker (Compact)
                            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color.pureWhite)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            // Dynamic Gauge
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Current Reading Scale")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                
                                // Systolic Gauge
                                VStack(spacing: 4) {
                                    HStack {
                                        Text("Systolic")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(systolicCategory)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(colorForSystolic(systolic))
                                    }
                                    
                                    DetailedGaugeView(value: Double(systolic), minValue: 70, maxValue: 180, segments: MedicalStandards.systolicRanges)
                                }
                                
                                // Diastolic Gauge
                                VStack(spacing: 4) {
                                    HStack {
                                        Text("Diastolic")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(diastolicCategory)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(colorForDiastolic(diastolic))
                                    }
                                    
                                    DetailedGaugeView(value: Double(diastolic), minValue: 40, maxValue: 120, segments: MedicalStandards.diastolicRanges)
                                }
                            }
                            .padding()
                            .background(Color.pureWhite)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Input Rulers
                            VStack(spacing: 24) {
                                RulerPicker(range: 70...250, value: $systolic, label: "Systolic")
                                RulerPicker(range: 40...150, value: $diastolic, label: "Diastolic")
                                
                                Divider()
                                
                                Toggle(isOn: $includePulse.animation()) {
                                    Text("Record Heart Rate (Optional)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.slate)
                                }
                                .tint(.softRed)
                                
                                if includePulse {
                                    RulerPicker(range: 40...200, value: $pulse, label: "Pulse (BPM)")
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding()
                            .background(Color.pureWhite)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            
                            // Medical Reference
                            VStack(spacing: 4) {
                                Text("Scale Sources:")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                HStack(spacing: 12) {
                                    Link("BP Readings", destination: MedicalStandards.bpCitationURL)
                                    Link("Heart Rate", destination: MedicalStandards.hrCitationURL)
                                }
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            }
                            .padding(.top, -8)
                            
                            Spacer(minLength: 24) // Bottom scroll padding
                        }
                        .padding(.top, 40) // Keep the nice top spacing
                    }
                    
                    // Pinned Save Button
                    VStack {
                        Button(action: saveLog) {
                            Text("Save Reading")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.softRed)
                                .cornerRadius(16)
                                .shadow(color: Color.softRed.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    .background(Color.offWhite.ignoresSafeArea()) // Seamless background
                    .padding(.bottom, 8) // Safe area adjustment
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Logic: Color Helpers

    func colorForSystolic(_ value: Int) -> Color {
        MedicalStandards.colorForSystolic(value)
    }
    
    func colorForDiastolic(_ value: Int) -> Color {
        MedicalStandards.colorForDiastolic(value)
    }
    
    
    var systolicCategory: String {
        MedicalStandards.analyzeSystolic(systolic).displayName
    }
    
    var diastolicCategory: String {
        MedicalStandards.analyzeDiastolic(diastolic).displayName
    }
    
    // Haptics
    func triggerHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Save Action
    func saveLog() {
        // Saving BP with optional Pulse
        let newLog = BPLog(
            systolic: systolic,
            diastolic: diastolic,
            heartRate: includePulse ? pulse : nil,
            date: date
        )
        modelContext.insert(newLog)
        
        // Optional: Simple success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Rating Logic
        if !hasLoggedFirstTime {
            hasLoggedFirstTime = true
            requestReview()
        }
        
        // Dismiss the entire sheet
        isPresented = false
    }
}

#Preview {
    AddLogView(isPresented: .constant(true))
}
