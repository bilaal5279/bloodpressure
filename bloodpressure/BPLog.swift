import Foundation
import SwiftData

@Model
final class BPLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var systolic: Int?
    var diastolic: Int?
    var heartRate: Int?
    
    // Computed property for grouping/filtering by day
    var dayComponent: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: date)
    }

    init(systolic: Int? = nil, diastolic: Int? = nil, heartRate: Int? = nil, date: Date = Date()) {
        self.id = UUID()
        self.systolic = systolic
        self.diastolic = diastolic
        self.heartRate = heartRate
        self.date = date
    }
}
