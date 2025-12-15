import SwiftUI
import SwiftData
import AVFoundation
import StoreKit

struct HeartRateMeasurementView: View {
    @Binding var isPresented: Bool
    @StateObject private var hrManager = HeartRateManager()
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(\.requestReview) var requestReview
    @AppStorage("hasLoggedFirstTime") private var hasLoggedFirstTime = false
    
    @State private var showManualEntry = false
    @State private var manualPulse: Double = 72
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                // Header
                Text(showManualEntry ? "Manual Entry" : (hrManager.isMeasuring ? "Measuring..." : "Measurement Complete"))
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Spacer()
                
                if showManualEntry {
                    // Manual Entry UI
                    VStack(spacing: 32) {
                        Text("Enter your Heart Rate")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("\(Int(manualPulse))")
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                        
                        Text("BPM")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // Simple Slider/Stepper for Manual Entry
                        // Keeping it simple with a Slider for "Ruler-like" feel without full dependency
                        Slider(value: $manualPulse, in: 30...200, step: 1)
                            .accentColor(.softRed)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            saveManualLog()
                            // No dismiss needed for manual save as it handles binding
                        }) {
                            Text("Save Manual Entry")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.softRed)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 32)
                        
                        Button("Cancel") {
                            showManualEntry = false
                            hrManager.startMeasurement()
                        }
                        .foregroundColor(.gray)
                    }
                } else {
                    // existing Camera UI logic...
                    // Camera Area Animation
                    if hrManager.isMeasuring {
                        ZStack {
                            Circle()
                                .fill(Color.softRed.opacity(0.1))
                                .frame(width: 250, height: 250)
                            
                            Circle()
                                .stroke(Color.softRed.opacity(0.3), lineWidth: 5)
                                .frame(width: 220, height: 220)
                            
                            // Live Camera Preview (Masked)
                            CameraPreview(session: hrManager.previewSession)
                                .frame(width: 210, height: 210)
                                .mask(Circle())
                            
                            // Beat Animation Overlay
                            Image(systemName: "heart.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.8)) // White heart over potential red camera feed
                                .shadow(radius: 4)
                                .scaleEffect(hrManager.heartRate > 0 ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: hrManager.heartRate)
                            
                            // Progress Ring
                            Circle()
                                .trim(from: 0.0, to: hrManager.progress)
                                .stroke(Color.softRed, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 220, height: 220)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: hrManager.progress)
                        }
                    }
                    
                    Spacer()
                    
                    if hrManager.isMeasuring {
                        if hrManager.isDetectingFinger {
                            // Hiding live BPM as requested
                        } else {
                            Text("Place your finger gently covering the camera and flash")
                                .font(.headline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                        
                        // Option to switch to Manual
                        Button("Enter Manually") {
                            hrManager.stopMeasurement()
                            showManualEntry = true
                        }
                        .font(.headline)
                        .foregroundColor(.softRed)
                        .padding(.top, 40)
                        
                    } else {
                         // Result State
                        ScrollView {
                            VStack(spacing: 24) {
                                // Result Card
                                VStack(spacing: 16) {
                                    Text("Average Heart Rate")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                        .padding(.top, 24)
                                    
                                    Text("\(hrManager.heartRate)")
                                        .font(.system(size: 80, weight: .black, design: .rounded))
                                        .foregroundColor(.black)
                                    
                                    Text("BPM")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 24)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                                
                                // Scale Information
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("About your result")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 4) {
                                        ScaleSegment(color: .blue, label: "Low", isSelected: hrManager.heartRate < 60)
                                        ScaleSegment(color: .green, label: "Normal", isSelected: hrManager.heartRate >= 60 && hrManager.heartRate <= 100)
                                        ScaleSegment(color: .orange, label: "High", isSelected: hrManager.heartRate > 100)
                                    }
                                    .frame(height: 12)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(.vertical, 8)
                                    
                                    HStack {
                                        Text("Low (<60)")
                                        Spacer()
                                        Text("Normal (60-100)")
                                        Spacer()
                                        Text("High (>100)")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    
                                    Text(getAdvice(for: hrManager.heartRate))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.top, 8)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(16)
                                .padding(.horizontal)
                                
                                // Save Button
                                Button(action: {
                                    saveLog()
                                }) {
                                    Text("Save Result")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color.softRed)
                                        .cornerRadius(16)
                                }
                                .padding(.horizontal, 32)
                                .padding(.top, 16)
                                
                                // Retake Button
                                Button(action: {
                                    hrManager.startMeasurement()
                                }) {
                                    Text("Retake Measurement")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.gray)
                                }
                                .padding(.bottom, 40)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            if !showManualEntry {
                hrManager.startMeasurement()
            }
        }
        .onDisappear {
            hrManager.stopMeasurement()
        }
    }
    
    func saveLog() {
        // Save heart rate only
        let newLog = BPLog(heartRate: hrManager.heartRate, date: Date())
        modelContext.insert(newLog)
        
        // Rating Logic
        if !hasLoggedFirstTime {
            hasLoggedFirstTime = true
            requestReview()
        }
        
        isPresented = false
    }
    
    func saveManualLog() {
        let newLog = BPLog(heartRate: Int(manualPulse), date: Date())
        modelContext.insert(newLog)
        
        // Rating Logic (Duplicate logic or shared func)
        if !hasLoggedFirstTime {
            hasLoggedFirstTime = true
            requestReview()
        }
        
        isPresented = false
    }
    func getAdvice(for bpm: Int) -> String {
        if bpm < 60 {
            return "A resting heart rate below 60 BPM is considered slow (Bradycardia), though it can be normal for athletes."
        } else if bpm > 100 {
            return "A resting heart rate above 100 BPM is considered fast (Tachycardia). Consult a doctor if this persists."
        } else {
            return "Your heart rate is within the normal range for adults (60-100 BPM)."
        }
    }
}

struct ScaleSegment: View {
    let color: Color
    let label: String
    let isSelected: Bool
    
    var body: some View {
        Rectangle()
            .fill(color.opacity(isSelected ? 1.0 : 0.3))
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(isSelected ? 0.1 : 0.0), lineWidth: 1)
            )
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        if let connection = view.videoPreviewLayer.connection {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}
