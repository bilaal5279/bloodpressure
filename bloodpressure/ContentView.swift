//
//  ContentView.swift
//  bloodpressure
//
//  Created by Bilaal Ishtiaq on 14/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject var revenueCat = RevenueCatManager.shared
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
                .transition(.opacity)
        } else if revenueCat.isLoading {
            // Loading State (Optimistic)
            ZStack {
                Color.offWhite.ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
            .transition(.opacity)
        } else if revenueCat.isPro {
            MainTabView()
                .transition(.opacity)
        } else {
            PaywallView()
                .transition(.opacity)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BPLog.self, inMemory: true)
}
