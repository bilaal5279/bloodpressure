import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \BPLog.date, order: .reverse) var allLogs: [BPLog]
    
    @State private var selectedDate: Date = Date()
    @State private var showSettings: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showLogSelection: Bool = false
    
    // Filtered Logs matching selected date
    var filteredLogs: [BPLog] {
        allLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.offWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.slate.opacity(0.7))
                        }
                        
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
                    
                    // List
                    if filteredLogs.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No logs for today.\nKeep tracking!")
                                .font(.system(.body, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredLogs) { log in
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
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }
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
            // Removed other sheets as they are now part of navigation stack flow or sub-views
        }
    }
    
    func deleteLog(_ log: BPLog) {
        withAnimation {
            modelContext.delete(log)
        }
    }
}

#Preview {
    DashboardView()
}
