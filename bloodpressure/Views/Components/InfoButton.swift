import SwiftUI

struct InfoButton: View {
    let type: InfoType
    @State private var showAlert = false
    
    enum InfoType {
        case bloodPressure
        case heartRate
        
        var title: String {
            switch self {
            case .bloodPressure: return "Blood Pressure Scale"
            case .heartRate: return "Heart Rate Scale"
            }
        }
        
        var message: String {
            switch self {
            case .bloodPressure:
                return "Blood Pressure categories (Low, Normal, Elevated, High) are based on the American Heart Association guidelines."
            case .heartRate:
                return "Heart Rate categories (Low, Normal, High) are derived from the American Heart Association's resting heart rate standards."
            }
        }
        
        var citationURL: URL {
            switch self {
            case .bloodPressure: return MedicalStandards.bpCitationURL
            case .heartRate: return MedicalStandards.hrCitationURL
            }
        }
    }
    
    var body: some View {
        Button(action: {
            showAlert = true
        }) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .alert(type.title, isPresented: $showAlert) {
            Button("Learn More") {
                UIApplication.shared.open(type.citationURL)
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(type.message)
        }
    }
}

#Preview {
    HStack {
        InfoButton(type: .bloodPressure)
        InfoButton(type: .heartRate)
    }
    .padding()
}
