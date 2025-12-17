import SwiftUI

struct MedicalStandards {
    
    // MARK: - Blood Pressure Categories
    enum BPCategory: String {
        case low = "Low"
        case normal = "Normal"
        case elevated = "Elevated"
        case highStage1 = "High (Stage 1)" // Internal unique raw value
        case highStage2 = "High (Stage 2)" // Internal unique raw value
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .elevated: return "Elevated"
            case .highStage1, .highStage2: return "High"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .softBlue
            case .normal: return .softTeal
            case .elevated: return .softOrange
            case .highStage1: return .orange
            case .highStage2: return .bpHigh
            }
        }
    }
    
    static func analyzeBP(systolic: Int, diastolic: Int) -> BPCategory {
        if systolic < 90 || diastolic < 60 { return .low }
        if systolic >= 140 || diastolic >= 90 { return .highStage2 }
        if systolic >= 130 { return .highStage1 } // Diastolic 80-89 is now Elevated, so only Systolic triggers Stage 1 High
        if (systolic >= 120 && systolic < 130) || (diastolic >= 80 && diastolic < 90) { return .elevated } // 80-89 Diastolic is Elevated
        return .normal
    }
    
    // Helper for individual gauges
    static func analyzeSystolic(_ value: Int) -> BPCategory {
        if value < 90 { return .low }
        if value >= 140 { return .highStage2 }
        if value >= 130 { return .highStage1 }
        if value >= 120 { return .elevated }
        return .normal
    }
    
    static func analyzeDiastolic(_ value: Int) -> BPCategory {
        if value < 60 { return .low }
        if value >= 90 { return .highStage2 }
        if value >= 80 { return .elevated } // Renamed logic: 80-89 is Elevated
        return .normal
    }
    
    static func colorForSystolic(_ value: Int) -> Color {
        analyzeSystolic(value).color
    }
    
    static func colorForDiastolic(_ value: Int) -> Color {
        analyzeDiastolic(value).color
    }
    
    // MARK: - Heart Rate Categories
    enum HRCategory: String {
        case low = "Low"
        case normal = "Normal"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .softBlue
            case .normal: return .softTeal
            case .high: return .softRed
            }
        }
    }
    
    static func analyzeHR(_ bpm: Int) -> HRCategory {
        if bpm < 60 { return .low }
        if bpm > 100 { return .high }
        return .normal
    }
    
    // MARK: - Ranges for Gauges
    // Using GaugeSegment for better labelling support
    
    static let systolicRanges: [GaugeSegment] = [
        GaugeSegment(start: 0, end: 90, color: .softBlue, label: "Low"),
        GaugeSegment(start: 90, end: 120, color: .softTeal, label: "Normal"),
        GaugeSegment(start: 120, end: 130, color: .softOrange, label: "Elevated"),
        GaugeSegment(start: 130, end: 300, color: .bpHigh, label: "High") // Merging Stage 1 & 2 for simpler gauge label
    ]
    
    static let diastolicRanges: [GaugeSegment] = [
        GaugeSegment(start: 0, end: 60, color: .softBlue, label: "Low"),
        GaugeSegment(start: 60, end: 80, color: .softTeal, label: "Normal"),
        GaugeSegment(start: 80, end: 90, color: .softOrange, label: "Elevated"), // Changed color to softOrange match
        GaugeSegment(start: 90, end: 200, color: .bpHigh, label: "High")
    ]
    
    static let heartRateRanges: [GaugeSegment] = [
        GaugeSegment(start: 0, end: 60, color: .softBlue, label: "Low"),
        GaugeSegment(start: 60, end: 100, color: .softTeal, label: "Normal"),
        GaugeSegment(start: 100, end: 220, color: .softRed, label: "High")
    ]
    
    // MARK: - Citations
    static let citationName = "American Heart Association"
    static let bpCitationURL = URL(string: "https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings")!
    static let hrCitationURL = URL(string: "https://www.heart.org/en/health-topics/high-blood-pressure/the-facts-about-high-blood-pressure/all-about-heart-rate-pulse")!
}

// Add new color extension if missing
extension Color {
    static let softBlue = Color(hue: 0.6, saturation: 0.6, brightness: 0.9)
}
