import SwiftUI

struct PaywallView: View {
    @ObservedObject var revenueCat = RevenueCatManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showConfetti = false
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Premium Gradient Background
            LinearGradient(
                colors: [Color.softRed.opacity(0.15), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Image
                        ZStack {
                            Circle()
                                .fill(Color.softRed.opacity(0.1))
                                .frame(width: 180, height: 180)
                                .blur(radius: 20)
                            
                            Image(systemName: "heart.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.softRed)
                                .shadow(color: Color.softRed.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        .padding(.top, 40)
                        
                        // Title
                        Text("Unlock Your\nHeart Health")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.slate)
                            .padding(.top, 24)
                            .padding(.horizontal)
                        
                        // Features List
                        VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(text: "Blood Pressure & Pulse Logging")
                            FeatureRow(text: "Unlimited History & Cloud Backup")
                            FeatureRow(text: "Smart Trend Analysis & Charts")
                            FeatureRow(text: "Export PDF Reports for Doctor")
                            FeatureRow(text: "No Ads & Distractions")
                        }
                        .padding(.vertical, 32)
                        .padding(.horizontal, 40)
                    }
                }
                
                // Bottom Section: Pricing & Action
                VStack(spacing: 24) {
                    Button(action: {
                        revenueCat.purchase { success in
                            if success {
                                withAnimation {
                                    showConfetti = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    dismiss() // Note: Dismiss relies on usage context
                                }
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text("Start 3-Day Free Trial")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Then \(revenueCat.localizedPrice)")
                                .font(.caption)
                                .opacity(0.9)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(colors: [.softRed, .softRed.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.softRed.opacity(0.4), radius: 12, x: 0, y: 6)
                        .scaleEffect(isPulsing ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
                        .onAppear {
                            isPulsing = true
                        }
                    }
                    
                    // Footer
                    HStack(spacing: 24) {
                        Button("Restore") {
                            revenueCat.restore { _ in dismiss() }
                        }
                        Link("Terms", destination: URL(string: "https://digitalsprout.org/bp/terms-of-service")!)
                        Link("Privacy", destination: URL(string: "https://digitalsprout.org/bp/privacypolicy")!)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .padding(.top, 20)
                .background(
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .ignoresSafeArea()
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
            
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.softTeal)
                .font(.title3)
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.slate)
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
