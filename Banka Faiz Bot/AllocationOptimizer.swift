import Foundation

protocol AllocationOptimizing {
    func optimize(total: Decimal, mode: RateMode, banks: [Bank]) -> [BankAllocationResult]
    func optimizeCustomModes(total: Decimal, banks: [Bank], modes: [String: RateMode], customRates: [String: String]) -> [BankAllocationResult]
}

class AllocationOptimizer: AllocationOptimizing {
    let blockSize: Decimal = 10_000
    let calculator: InterestCalculating
    
    init(calculator: InterestCalculating) {
        self.calculator = calculator
    }
    
    func optimize(total: Decimal, mode: RateMode, banks: [Bank]) -> [BankAllocationResult] {
        return optimizeCustomModes(total: total, banks: banks, modes: Dictionary(uniqueKeysWithValues: banks.map { ($0.id, mode) }), customRates: [:])
    }
    
    func optimizeCustomModes(total: Decimal, banks: [Bank], modes: [String: RateMode], customRates: [String: String]) -> [BankAllocationResult] {
        var allocations: [String: Decimal] = [:]
        var remaining = total
        for bank in banks {
            allocations[bank.id] = 0
        }
        while remaining >= blockSize {
            var bestBankId: String? = nil
            var bestGain: Decimal = -1
            for bank in banks {
                let current = allocations[bank.id] ?? 0
                let mode = modes[bank.id] ?? .welcome
                let plan = (mode == .welcome ? bank.welcome : bank.standard) ?? bank.standard
                if let maxCap = plan.maxCap, current + blockSize > maxCap {
                    continue
                }
                if current == 0 && blockSize < bank.minDeposit {
                    continue
                }
                let (gainBefore, _, _, _) = calculator.gainOver30Days(for: bank, amount: current, mode: mode, customRate: customRates[bank.id])
                let (gainAfter, _, _, _) = calculator.gainOver30Days(for: bank, amount: current + blockSize, mode: mode, customRate: customRates[bank.id])
                let marginalGain = gainAfter - gainBefore
                if marginalGain > bestGain {
                    bestGain = marginalGain
                    bestBankId = bank.id
                }
            }
            if let bestId = bestBankId, bestGain > 0 {
                allocations[bestId]! += blockSize
                remaining -= blockSize
            } else {
                break
            }
        }
        if remaining > 0.01 {
            var bestBankId: String? = nil
            var bestGain: Decimal = -1
            for bank in banks {
                let current = allocations[bank.id] ?? 0
                let mode = modes[bank.id] ?? .welcome
                let plan = (mode == .welcome ? bank.welcome : bank.standard) ?? bank.standard
                if let maxCap = plan.maxCap, current + remaining > maxCap {
                    continue
                }
                if current == 0 && remaining < bank.minDeposit {
                    continue
                }
                let (gainBefore, _, _, _) = calculator.gainOver30Days(for: bank, amount: current, mode: mode, customRate: customRates[bank.id])
                let (gainAfter, _, _, _) = calculator.gainOver30Days(for: bank, amount: current + remaining, mode: mode, customRate: customRates[bank.id])
                let marginalGain = gainAfter - gainBefore
                if marginalGain > bestGain {
                    bestGain = marginalGain
                    bestBankId = bank.id
                }
            }
            if let bestId = bestBankId, bestGain > 0 {
                allocations[bestId]! += remaining
                remaining = 0
            }
        }
        var results: [BankAllocationResult] = []
        for bank in banks {
            let allocated = allocations[bank.id] ?? 0
            let mode = modes[bank.id] ?? .welcome
            if allocated >= bank.minDeposit {
                let (gain, weightedRate, breakdown, firstDayNetGain) = calculator.gainOver30Days(for: bank, amount: allocated, mode: mode, customRate: customRates[bank.id])
                results.append(BankAllocationResult(bank: bank, allocated: allocated, weightedDailyRate: weightedRate, gain30d: gain, breakdown: breakdown, firstDayNetGain: firstDayNetGain, selectedMode: mode))
            }
        }
        return results
    }
}
