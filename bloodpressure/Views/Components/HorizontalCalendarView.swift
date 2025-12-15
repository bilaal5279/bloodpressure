import SwiftUI

struct HorizontalCalendarView: View {
    @Binding var selectedDate: Date
    @State private var dates: [Date] = []
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dates, id: \.self) { date in
                        DatePill(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                            .id(date)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                generateDates()
                // Scroll to today initially
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(Calendar.current.startOfDay(for: Date()), anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                withAnimation {
                    proxy.scrollTo(Calendar.current.startOfDay(for: newValue), anchor: .center)
                }
            }
        }
        .frame(height: 80)
    }
    
    private func generateDates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Generate past 30 days and next 7 days
        guard let _ = calendar.date(byAdding: .year, value: -100, to: today) else { return } // Fallback
        
        var tempDates: [Date] = []
         //  Let's show a reasonable range, e.g. -30 days to + 0 days (today) for MVP logging
         //  Spec says "7-14 day pills". Let's do past 14 days + today.
        for i in -14...0 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                tempDates.append(date)
            }
        }
        self.dates = tempDates
    }
}

struct DatePill: View {
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
            
            Text(date.formatted(.dateTime.day()))
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : Color.slate)
            
            if Calendar.current.isDateInToday(date) {
                Circle()
                    .fill(isSelected ? .white : Color.softRed)
                    .frame(width: 4, height: 4)
            } else {
                 Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 50, height: 75)
        .background(isSelected ? Color.softRed : Color.pureWhite)
        .clipShape(Capsule())
        .shadow(color: isSelected ? Color.softRed.opacity(0.3) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HorizontalCalendarView(selectedDate: .constant(Date()))
        .background(Color.offWhite)
}
