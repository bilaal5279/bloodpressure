import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.offWhite.ignoresSafeArea()
            
            VStack {
                // Header (Premium Touch)
                Text("BP DIARY")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                
                TabView(selection: $currentPage) {
                    OnboardingSlide(
                        title: "Simplicity",
                        description: "Effortlessly log your blood pressure in seconds.",
                        imageName: "heart.text.square.fill"
                    )
                    .tag(0)
                    
                    OnboardingSlide(
                        title: "Security",
                        description: "Your health data is encrypted and synced with iCloud.",
                        imageName: "lock.shield.fill"
                    )
                    .tag(1)
                    
                    OnboardingSlide(
                        title: "Insights",
                        description: "Visualize trends and share reports with your doctor.",
                        imageName: "chart.xyaxis.line"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < 2 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // Smooth Transition Trigger
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasCompletedOnboarding = true
                        }
                    }
                }) {
                    Text(currentPage < 2 ? "Continue" : "Get Started")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.softRed)
                        .cornerRadius(16)
                        .shadow(color: Color.softRed.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .transition(.opacity) // Supports the transition out
    }
}

struct OnboardingSlide: View {
    let title: String
    let description: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with Premium Glow
            ZStack {
                Circle()
                    .fill(Color.softRed.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .foregroundColor(.softRed)
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.slate)
                
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
