import SwiftUI

struct PaywallView: View {
    @ObservedObject var revenueCat = RevenueCatManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showConfetti = false
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.offWhite.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ... content ...
                // Header Image
                ZStack {
                    Color.softRed.opacity(0.1)
                    Image(systemName: "heart.fill") // Placeholder for 3D render
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.softRed)
                        .shadow(color: Color.softRed.opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .frame(height: 250)
                .mask(RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .padding(.bottom, -32)) // Curved bottom effect
                
                VStack(spacing: 24) {
                    Text("Unlock Your\nHeart Health")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.black)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.slate)
                        .padding(.top, 32)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(text: "Unlimited History & Cloud Backup")
                        FeatureRow(text: "Smart Trend Analysis")
                        FeatureRow(text: "Export for your Doctor (PDF)")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Pricing
                    VStack(spacing: 12) {
                        Button(action: {
                            revenueCat.purchase { success in
                                if success {
                                    withAnimation {
                                        showConfetti = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        dismiss()
                                    }
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text("Start 3-Day Free Trial")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Then $6.99/week")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.softRed)
                            .cornerRadius(16)
                            .shadow(color: Color.softRed.opacity(0.4), radius: 10, x: 0, y: 5)
                            .scaleEffect(isPulsing ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                            .onAppear {
                                isPulsing = true
                            }
                        }
                        
                        Button(action: {
                             // Monthly plan logic
                        }) {
                            Text("Continue with Weekly Plan")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Footer
                    HStack(spacing: 24) {
                        Button("Restore") {
                            revenueCat.restore { _ in dismiss() }
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        
                        Button("Terms") {}
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button("Privacy") {}
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom)
                }
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
