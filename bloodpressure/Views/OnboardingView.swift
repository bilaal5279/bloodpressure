import SwiftUI
import Charts
import StoreKit

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @Environment(\.requestReview) var requestReview
    @State private var currentPage = 0
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            Color.offWhite.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Device Content Area
                TabView(selection: $currentPage) {
                    OnboardingSlideView(
                        title: "Track with Ease",
                        subtitle: "Log your blood pressure and heart rate in seconds. Fast, simple, and accurate.",
                        content: AnyView(
                            Image("home")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        )
                    )
                    .tag(0)
                    
                    OnboardingSlideView(
                        title: "Visualize Your Health",
                        subtitle: "Spot trends instantly with beautiful, easy-to-read interactive charts.",
                        content: AnyView(
                            Image("insights")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        )
                    )
                    .tag(1)
                    
                    OnboardingSlideView(
                        title: "Measure Your BPM",
                        subtitle: "Use your camera to check your heart rate instantly. Fast, simple, and convenient.",
                        content: AnyView(
                            Image("measureheartrate")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        )
                    )
                    .tag(2)
                    
                    // Slide 4: Paywall
                    OnboardingPaywallSlide()
                        .tag(3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle()) // Ensure all touches are captured
                        .highPriorityGesture(DragGesture()) // Block swiping back with higher priority
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Controls
                VStack(spacing: 24) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(currentPage == index ? Color.softRed : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    Button(action: {
                        if currentPage < 3 {
                            // Logic for moving to next slide
                            withAnimation {
                                currentPage += 1
                            }
                            
                            // Trigger Rating when moving to Slide 2 (Index 1)
                            if currentPage == 1 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    requestReview()
                                }
                            }
                        } else {
                            // Final Slide (Paywall) Action
                            startPurchase()
                        }
                    }) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.softRed)
                                .cornerRadius(16)
                        } else {
                            VStack(spacing: 4) {
                                Text(buttonText)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                if currentPage == 3 {
                                    Text("Then \(RevenueCatManager.shared.localizedPrice)")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.softRed)
                            .cornerRadius(16)
                            .shadow(color: Color.softRed.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                    }
                    .disabled(isPurchasing)
                    
                    if currentPage == 3 {
                        HStack(spacing: 24) {
                            Button("Restore") {
                                RevenueCatManager.shared.restore { success in
                                    if success {
                                        hasCompletedOnboarding = true
                                    }
                                }
                            }
                            Link("Terms", destination: URL(string: "https://digitalsprout.org/bp/terms-of-service")!)
                            Link("Privacy", destination: URL(string: "https://digitalsprout.org/bp/privacypolicy")!)
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, -12) // Pull closer to button
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .padding(.top, 20)
                .background(Color.offWhite) // Seamless blend
            }
        }
    }

    var buttonText: String {
        switch currentPage {
        case 0, 1: return "Continue"
        case 2: return "Unlock Everything"
        case 3: return "Start 3-Day Free Trial"
        default: return "Continue"
        }
    }
    
    func startPurchase() {
        isPurchasing = true
        RevenueCatManager.shared.purchase { success in
            isPurchasing = false
            if success {
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

// MARK: - Slide Structure
struct OnboardingSlideView: View {
    let title: String
    let subtitle: String
    let content: AnyView
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Device Frame
            DeviceFrame {
                content
            }
            .frame(height: 480) // Reduced further to ensure text fits on all screens
            .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.slate)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 32)
                    .lineLimit(nil) // Allow multiple lines
                    .fixedSize(horizontal: false, vertical: true) // Force vertical expansion
            }
            
            Spacer()
        }
    }
}

// MARK: - Device Frame
struct DeviceFrame<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Outer Bezel (iPhone 13/14 style)
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.black)
                .padding(-12) // Slightly thicker for realism
            
            // Inner Screen Area
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.white)
                .overlay(
                    ZStack {
                        content
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                        
                        // Fake Notch
                        VStack {
                            ZStack(alignment: .top) {
                                // Notch Body
                                pathForNotch()
                                    .fill(Color.black)
                                    .frame(width: 130, height: 26) // Reduced size (was 160x32)
                            }
                            Spacer()
                        }
                        .edgesIgnoringSafeArea(.top)
                        .padding(.top, -2) // Slight overlap to blend with bezel
                        
                        // Home Indicator
                        VStack {
                            Spacer()
                            Capsule()
                                .fill(Color.black.opacity(0.4)) // Subtle visual indicator
                                .frame(width: 130, height: 5)
                                .padding(.bottom, 8)
                        }
                    }
                )
        }
        .padding(12) // Outer margin
        .aspectRatio(9/19.5, contentMode: .fit)
    }
    
    // Custom Notch Shape for smooth curves
    func pathForNotch() -> some Shape {
        NotchShape()
    }
}

struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 10
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: width - cornerRadius, y: height), control: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - cornerRadius), control: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Mock Content Views (Removed: Using Screenshots)

#Preview {
    OnboardingView()
}

// MARK: - Paywall Slide
struct OnboardingPaywallSlide: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header Image
            ZStack {
                Circle()
                    .fill(Color.softRed.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.softRed)
                    .shadow(color: .softRed.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                Text("Unlock Premium")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.slate)
                
                Text("Get unlimited access to all features and take control of your heart health.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 32)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                OnboardingFeatureRow(text: "Blood Pressure & Pulse Logging")
                OnboardingFeatureRow(text: "Unlimited History & Cloud Backup")
                OnboardingFeatureRow(text: "Smart Trend Analysis & Charts")
                OnboardingFeatureRow(text: "Export PDF Reports for Doctor")
                OnboardingFeatureRow(text: "No Ads & Distractions")
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            Spacer() // Push content up slightly to make room for bottom button
        }
    }
}

// Reusing FeatureRow from PaywallView if available, otherwise defining it here for safety
// Assuming FeatureRow is public or redefining it locally to avoid scope issues if PaywallView.swift is not shared scope
struct OnboardingFeatureRow: View {
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
