import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) var modelContext
    @State private var selectedDate: Date = Date()
    @State private var showSettings: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showLogSelection: Bool = false
    @State private var showHeartRate: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.offWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("Heart Health")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 8) {
                                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundColor(.slate)
                                
                                Button(action: { showDatePicker = true }) {
                                    Image(systemName: "calendar")
                                        .font(.title3)
                                        .foregroundColor(.softRed)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Sheet Trigger
                        Button(action: { showLogSelection = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.softRed)
                                .shadow(color: Color.softRed.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Calendar
                    HorizontalCalendarView(selectedDate: $selectedDate)
                        .padding(.bottom, 16)
                    
                    // Optimized Content Subview
                    DailyDashContent(
                        date: selectedDate,
                        showLogSelection: $showLogSelection
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .padding()
                    
                    Button("Done") {
                        showDatePicker = false
                    }
                    .font(.headline)
                    .foregroundColor(.softRed)
                    .padding()
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showLogSelection) {
                NavigationStack {
                    LogSelectionView(isPresented: $showLogSelection)
                }
            }
            .fullScreenCover(isPresented: $showHeartRate) {
                HeartRateMeasurementView(isPresented: $showHeartRate)
            }
        }
    }
}

// MARK: - Daily Content Subview (Optimized Query)
struct DailyDashContent: View {
    @Environment(\.modelContext) var modelContext
    @Query var logs: [BPLog]
    @Binding var showLogSelection: Bool
    
    init(date: Date, showLogSelection: Binding<Bool>) {
        self._showLogSelection = showLogSelection
        
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.endOfDay(for: date)
        
        let predicate = #Predicate<BPLog> { log in
            log.date >= start && log.date <= end
        }
        
        self._logs = Query(filter: predicate, sort: \.date, order: .reverse)
    }
    
    var hasBPForDay: Bool {
        logs.contains { ($0.systolic ?? 0) > 0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Smart Prompts
                if !hasBPForDay {
                    PromptCard(
                        title: "Record Blood Pressure",
                        subtitle: "No reading logged for today.",
                        icon: "heart.text.square.fill",
                        color: .softTeal,
                        action: { showLogSelection = true }
                    )
                    .padding(.horizontal)
                }
                
                // List
                if logs.isEmpty {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 40)
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No logs yet.\nTap a card above to start tracking!")
                            .font(.system(.body, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(logs) { log in
                            BPCardView(log: log)
                                .padding(.horizontal)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteLog(log)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    func deleteLog(_ log: BPLog) {
        withAnimation {
            modelContext.delete(log)
        }
    }
}

// MARK: - Prompt Card Component
struct PromptCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.slate)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(color)
            }
            .padding()
            .background(Color.pureWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    DashboardView()
}
