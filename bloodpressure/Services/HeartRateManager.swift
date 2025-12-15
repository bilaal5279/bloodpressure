import SwiftUI
import AVFoundation
import Combine

// MARK: - Frame Processor
// Detects pulse from video frames on a background thread.
private class FrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onHeartRateCalculated: ((Int) -> Void)?
    var onProgressUpdate: ((Double) -> Void)?
    var onFingerDetected: ((Bool) -> Void)?
    
    // Internal state (accessed only on the video queue)
    // Internal state (accessed only on the video queue)
    private var frameCount = 0
    private var brightnessHistory: [Double] = []
    private var validReadings: [Int] = []
    private var startTime: Date?
    private var isProcessing = false
    
    func reset() {
        frameCount = 0
        brightnessHistory.removeAll()
        validReadings.removeAll()
        startTime = Date()
        isProcessing = true
    }
    
    func stop() {
        isProcessing = false
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isProcessing else { return }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        
        // --- FAST BRIGHTNESS CALCULATION ---
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            return
        }
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var totalRed: Double = 0
        var totalGreen: Double = 0
        var samples = 0
        let step = 10 // Skip pixels for performance
        
        // Sampling safe center region
        let safeW = min(width, 100)
        let safeH = min(height, 100)
        let startX = (width - safeW) / 2
        let startY = (height - safeH) / 2
        
        for y in stride(from: startY, to: startY + safeH, by: step) {
            for x in stride(from: startX, to: startX + safeW, by: step) {
                let offset = y * bytesPerRow + x * 4
                // BGRA: B=0, G=1, R=2
                let g = Double(buffer[offset + 1])
                let r = Double(buffer[offset + 2])
                
                totalRed += r
                totalGreen += g
                samples += 1
            }
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        
        let avgRed = totalRed / Double(max(samples, 1))
        let avgGreen = totalGreen / Double(max(samples, 1))
        
        // --- SIGNAL PROCESSING ---
        // Use Red channel for pulse signal
        let avgBrightness = avgRed
        
        // Strict Finger Detection:
        // 1. Red must be bright (> 60)
        // 2. Red must be DOMINANT over Green (Red > Green * 3.0)
        //    Screens are R ~= G. Fingers are R >> G.
        let isFingerPresent = avgRed > 60 && avgRed > (avgGreen * 3.0)
        onFingerDetected?(isFingerPresent)
        
        guard isFingerPresent else {
            // If no finger, don't accumulate history or progress 
            // (Optional: reset history if finger lifted? For now, just pause)
            return
        }
        
        brightnessHistory.append(avgBrightness)
        if brightnessHistory.count > 300 { // ~10 seconds history
            brightnessHistory.removeFirst()
        }
        
        // Update Progress
        if let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            // Report progress (30 seconds duration)
            onProgressUpdate?(min(elapsed / 30.0, 1.0))
        }
        
        // Calculate HR every 30 frames
        if frameCount % 30 == 0 {
            calculateHeartRate()
        }
        
        frameCount += 1
    }
    
    private func calculateHeartRate() {
        guard brightnessHistory.count > 60 else { return } // Need ~2 seconds data
        
        // Basic peak detection
        // Basic localized processing
        // 1. Smooth the signal (Simple Moving Average, N=5)
        var smoothed = [Double]()
        for i in 0..<brightnessHistory.count {
            let start = max(0, i - 2)
            let end = min(brightnessHistory.count, i + 3)
            let slice = brightnessHistory[start..<end]
            let avg = slice.reduce(0, +) / Double(slice.count)
            smoothed.append(avg)
        }
        
        // 2. Adaptive Peak Detection
        // Calculate dynamic mean (DC component)
        let mean = smoothed.reduce(0, +) / Double(max(smoothed.count, 1))
        
        var peaks = 0
        var lastPeakIndex = -10
        
        for i in 1..<(smoothed.count - 1) {
            let prev = smoothed[i-1]
            let curr = smoothed[i]
            let next = smoothed[i+1]
            
            // Peak condition: Local max AND above mean
            if curr > prev && curr > next && curr > mean {
                // Debounce: Ensure peaks are at least ~10 frames apart (approx 200ms at 30fps -> max 300bpm)
                if i - lastPeakIndex > 8 {
                    peaks += 1
                    lastPeakIndex = i
                }
            }
        }
        
        // 30fps assumption
        let durationSeconds = Double(brightnessHistory.count) / 30.0
        let estimatedBPM = (Double(peaks) / durationSeconds) * 60.0
        
        // Filter realistic range
        // Filter realistic range
        // Filter realistic range
        if estimatedBPM > 40 && estimatedBPM < 200 {
            // Discard first 4 seconds of data (settling time)
            if let start = startTime, Date().timeIntervalSince(start) > 4.0 {
                validReadings.append(Int(estimatedBPM))
            }
            // Always update live prediction for UI feedback, even if not recording for average yet
            onHeartRateCalculated?(Int(estimatedBPM))
        }
    }
    
    func getAverageHeartRate() -> Int {
        guard !validReadings.isEmpty else { return 0 }
        let sum = validReadings.reduce(0, +)
        return sum / validReadings.count
    }
}

// MARK: - Camera Service
// Manages the AVCaptureSession in isolation from the MainActor.
private class CameraService {
    private let session = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private let output = AVCaptureVideoDataOutput()
    // STATIC queue ensures all camera start/stop operations across different instances are serialized.
    // This prevents race conditions with the Torch when quickly entering/exiting the view.
    private static let sessionQueue = DispatchQueue(label: "com.bloodpressure.cameraSessionQueue")
    
    static let shared = CameraService()
    
    private var isConfigured = false
    
    private init() {}
    
    func configure(with delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        Self.sessionQueue.async { [weak self] in
            guard let self = self else { return }
            // Smart Reconfiguration: If already configured, just update the delegate to the new FrameProcessor
            if self.isConfigured {
                let videoQueue = DispatchQueue(label: "com.bloodpressure.videoQueue")
                self.output.setSampleBufferDelegate(delegate, queue: videoQueue)
                self.session.commitConfiguration()
                return
            }
            
            self.session.sessionPreset = .high // Use high for better sensor readout
            
            // 1. Find Back Camera
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            )
            guard let device = discovery.devices.first else {
                self.session.commitConfiguration()
                return
            }
            self.videoDevice = device
            
            // 2. Input
            do {
                if let currentInput = self.session.inputs.first {
                    self.session.removeInput(currentInput)
                }
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                
                // CRITICAL: Enforce 30 FPS
                try device.lockForConfiguration()
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
                device.unlockForConfiguration()
            } catch {
                print("Error creating device input: \(error)")
            }
            
            // 3. Output
            if let currentOutput = self.session.outputs.first {
                self.session.removeOutput(currentOutput)
            }
            
            // Separate queue for frame processing to not block session management
            let videoQueue = DispatchQueue(label: "com.bloodpressure.videoQueue")
            self.output.setSampleBufferDelegate(delegate, queue: videoQueue)
            self.output.alwaysDiscardsLateVideoFrames = true
            
            // CRITICAL: Ensure we get BGRA pixels for our byte-level access logic
            self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.isConfigured = true
            self.session.commitConfiguration()
        }
    }
    
    func start() {
        Self.sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
            self.setTorch(on: true)
        }
    }
    
    func stop() {
        Self.sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.setTorch(on: false)
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    private func setTorch(on: Bool) {
        guard let device = videoDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on { try device.setTorchModeOn(level: 1.0) }
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
    
    func getSession() -> AVCaptureSession {
        return session
    }
}

// MARK: - Heart Rate Manager
// The ObservableObject driving the UI.
@MainActor
class HeartRateManager: NSObject, ObservableObject {
    @Published var heartRate: Int = 0
    @Published var isMeasuring = false
    @Published var progress: Double = 0.0
    @Published var permissionGranted = false
    @Published var isDetectingFinger = false
    
    private let cameraService = CameraService.shared
    private let frameProcessor = FrameProcessor()
    
    var previewSession: AVCaptureSession {
        cameraService.getSession()
    }
    
    override init() {
        super.init()
        checkPermission()
        
        // Setup Callbacks
        frameProcessor.onHeartRateCalculated = { [weak self] bpm in
            Task { @MainActor in
                self?.heartRate = bpm
                // Haptic on detection
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
        
        frameProcessor.onProgressUpdate = { [weak self] p in
            Task { @MainActor in
                self?.progress = p
                if p >= 1.0 {
                    self?.stopMeasurement()
                }
            }
        }
        
        frameProcessor.onFingerDetected = { [weak self] detected in
            Task { @MainActor in
                self?.isDetectingFinger = detected
            }
        }
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permissionGranted = true
            cameraService.configure(with: frameProcessor)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.permissionGranted = granted
                    if granted {
                        self.cameraService.configure(with: self.frameProcessor)
                    }
                }
            }
        default:
            self.permissionGranted = false
        }
    }
    
    func startMeasurement() {
        guard permissionGranted, !isMeasuring else { return }
        
        // Reset State
        isMeasuring = true
        progress = 0.0
        heartRate = 0
        frameProcessor.reset()
        
        // Start Camera
        cameraService.start()
    }
    
    func stopMeasurement() {
        guard isMeasuring else { return }
        isMeasuring = false
        
        frameProcessor.stop()
        cameraService.stop()
        
        // Final Average
        let avg = frameProcessor.getAverageHeartRate()
        if avg > 0 {
            self.heartRate = avg
        }
        
        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
