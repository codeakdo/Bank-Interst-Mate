import Foundation
import Combine

// struct BankAllocationResult burada kaldırıldı, BankModels.swift'te tanımlı

class BankInterestViewModel: ObservableObject {
    @Published var totalAmount: String = ""
    @Published var selectedBanks: Set<String> = [] // Banka id'leri
    @Published var selectedModes: [String: RateMode] = [:] // [bankaId: RateMode]
    @Published var customRates: [String: String] = [:] // [bankaId: customRateString]
    @Published var results: [BankAllocationResult] = []
    @Published var totalGain: Decimal = 0
    @Published var effectiveRate: Decimal = 0
    @Published var errorMessage: String? = nil
    @Published var totalFirstDayNetGain: Decimal = 0
    
    private let banks: [Bank]
    private let optimizer: AllocationOptimizing
    
    init(banks: [Bank] = sampleBanks) {
        let calculator = InterestCalculator()
        self.optimizer = AllocationOptimizer(calculator: calculator)
        self.banks = banks
        self.selectedBanks = [] // Başlangıçta hiçbir banka seçili değil
        print("ViewModel initialized with \(banks.count) banks")
        for bank in banks {
            self.selectedModes[bank.id] = .welcome
            self.customRates[bank.id] = ""
        }
    }
    
    // Banka seçimi için yardımcı fonksiyonlar
    func selectBank(_ bankId: String) {
        selectedBanks.insert(bankId)
        print("Bank selected: \(bankId), Total selected: \(selectedBanks.count)")
    }
    
    func deselectBank(_ bankId: String) {
        selectedBanks.remove(bankId)
        print("Bank deselected: \(bankId), Total selected: \(selectedBanks.count)")
    }
    
    func calculate() {
        errorMessage = nil
        guard let amount = Decimal(string: totalAmount.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")), amount > 0 else {
            errorMessage = "Lütfen geçerli bir tutar girin."
            results = []
            totalGain = 0
            effectiveRate = 0
            totalFirstDayNetGain = 0
            return
        }
        let filteredBanks = banks.filter { selectedBanks.contains($0.id) }
        if filteredBanks.isEmpty {
            errorMessage = "Lütfen en az bir banka seçin."
            results = []
            totalGain = 0
            effectiveRate = 0
            totalFirstDayNetGain = 0
            return
        }
        let allocations = optimizer.optimizeCustomModes(total: amount, banks: filteredBanks, modes: selectedModes, customRates: customRates)
        if allocations.isEmpty {
            errorMessage = "Tutar, bankaların asgari limitlerinin altında."
        }
        results = allocations
        totalGain = allocations.reduce(0) { $0 + $1.gain30d }
        let totalAllocated = allocations.reduce(0) { $0 + $1.allocated }
        effectiveRate = totalAllocated > 0 ? allocations.reduce(0) { $0 + $1.allocated * $1.weightedDailyRate } / totalAllocated : 0
        totalFirstDayNetGain = allocations.reduce(0) { $0 + $1.firstDayNetGain }
    }
    
    func percent(for allocated: Decimal) -> String {
        let total = results.reduce(0) { $0 + $1.allocated }
        guard total > 0 else { return "-" }
        let pct = (allocated / total * 100 as NSDecimalNumber).doubleValue
        return String(format: "%.2f%%", pct)
    }
    
    func formatted(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: number) ?? "-"
    }
    
    func reset() {
        totalAmount = ""
        results = []
        totalGain = 0
        effectiveRate = 0
        errorMessage = nil
        totalFirstDayNetGain = 0
        selectedBanks = [] // Reset'te de hiçbir banka seçili değil
        for bank in banks {
            selectedModes[bank.id] = .welcome
            customRates[bank.id] = ""
        }
    }
    
    var allBanks: [Bank] { banks }
}
