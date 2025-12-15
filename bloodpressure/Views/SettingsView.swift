import SwiftUI

struct SettingsView: View {
    @ObservedObject var revenueCat = RevenueCatManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Premium")) {
                    Button(action: {
                        revenueCat.restore { _ in }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.softRed)
                            Text("Restore Purchase")
                                .foregroundColor(.slate)
                        }
                    }
                }
                
                Section(header: Text("Support")) {
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Contact Us")
                                .foregroundColor(.slate)
                        }
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com/app/idYOUR_ID?action=write-review")!) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Rate App")
                                .foregroundColor(.slate)
                        }
                    }
                    
                    // Share App would be a ShareLink in iOS 16+ or custom UIActivityViewController
                }
                
                Section(header: Text("Legal")) {
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        .foregroundColor(.slate)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                        .foregroundColor(.slate)
                }
                
                Section {
                    Text("Version 1.0.0 (1)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.slate)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
