import SwiftUI
import Combine
import RevenueCat

class RevenueCatManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = RevenueCatManager()
    
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = true
    @Published var localizedPrice: String = "$6.99/week" // Default fallback
    @Published var currentOffering: Offering?
    
    override private init() {
        super.init()
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_ONcAYuvNiLtrUigQCZgIzTztKTO")
        Purchases.shared.delegate = self
        checkSubscriptionStatus()
        fetchOfferings()
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] (info, error) in
            guard let self = self else { return }
            if let info = info {
                self.handleCustomerInfo(info)
            } else {
                // Return default state if error, but stop loading
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleCustomerInfo(_ info: CustomerInfo) {
        DispatchQueue.main.async {
            // Check specific entitlement
            self.isPro = info.entitlements["BP Log Pro"]?.isActive == true
            self.isLoading = false
        }
    }
    
    func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            guard let self = self else { return }
            if let offerings = offerings {
                // Try to find the specific weekly offering
                if let weekly = offerings.offering(identifier: "$rc_weekly") {
                    self.currentOffering = weekly
                    self.updateLocalizedPrice(for: weekly)
                } else if let current = offerings.current {
                    // Fallback to current if specific not found
                    self.currentOffering = current
                    self.updateLocalizedPrice(for: current)
                }
            }
        }
    }
    
    private func updateLocalizedPrice(for offering: Offering) {
        if let package = offering.availablePackages.first {
            DispatchQueue.main.async {
                // Formats price e.g., "£5.99" -> "£5.99/week"
                self.localizedPrice = "\(package.localizedPriceString)/week"
            }
        }
    }

    func purchase(completion: @escaping (Bool) -> Void) {
        guard let package = currentOffering?.availablePackages.first else {
            completion(false)
            return
        }
        
        Purchases.shared.purchase(package: package) { [weak self] (transaction, info, error, userCancelled) in
            if let info = info, error == nil && !userCancelled {
                self?.handleCustomerInfo(info)
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func restore(completion: @escaping (Bool) -> Void) {
        Purchases.shared.restorePurchases { [weak self] (info, error) in
            guard let self = self else { return }
            if let info = info {
                self.handleCustomerInfo(info)
                // Return success if they have the entitlement now
                let hasEntitlement = info.entitlements["BP Log Pro"]?.isActive == true
                completion(hasEntitlement)
            } else {
                completion(false)
            }
        }
    }
    
    // Delegate method for real-time updates
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        handleCustomerInfo(customerInfo)
    }
}
