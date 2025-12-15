import SwiftUI

struct LogSelectionView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.offWhite.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header (No handle needed if pushed, title is enough)
                Text("What would you like to log?")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.slate)
                    .padding(.top, 20)
                
                // Card 1: Blood Pressure
                NavigationLink(destination: AddLogView(isPresented: $isPresented)) {
                    HStack(spacing: 20) {
                        Circle()
                            .fill(Color.softTeal.opacity(0.15))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "drop.fill")
                                    .font(.title2)
                                    .foregroundColor(.softTeal)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blood Pressure")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.slate)
                            Text("Log manual readings")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(20)
                    .background(Color.pureWhite)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                
                // Card 2: Heart Rate
                NavigationLink(destination: HeartRateMeasurementView(isPresented: $isPresented)) {
                    HStack(spacing: 20) {
                        Circle()
                            .fill(Color.softRed.opacity(0.15))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundColor(.softRed)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Heart Rate")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.slate)
                            Text("Measure with camera")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(20)
                    .background(Color.pureWhite)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
