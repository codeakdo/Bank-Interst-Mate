import Foundation

let STOPAJ_RATE: Decimal = 0.175

protocol InterestCalculating {
    /// Verilen banka, tutar ve faiz tipi için 30 günlük net bileşik getiri, ağırlıklı ortalama oran ve detaylı breakdown döndürür
    /// Ayrıca ilk gün net getirisini de döndürür
    func gainOver30Days(for bank: Bank, amount: Decimal, mode: RateMode, customRate: String?) -> (gain: Decimal, weightedDailyRate: Decimal, breakdown: [String: Decimal], firstDayNetGain: Decimal)
}

class InterestCalculator: InterestCalculating {
    let days: Int = 30
    
    func gainOver30Days(for bank: Bank, amount: Decimal, mode: RateMode, customRate: String?) -> (gain: Decimal, weightedDailyRate: Decimal, breakdown: [String: Decimal], firstDayNetGain: Decimal) {
        guard amount >= bank.minDeposit else {
            return (0, 0, [:], 0)
        }
        
        // Özel oran varsa, basit hesaplama yap
        if mode == .custom, let customRateStr = customRate, !customRateStr.isEmpty, let customRateDecimal = Decimal(string: customRateStr.replacingOccurrences(of: ",", with: ".")) {
            // Kullanıcı %50 girerse, 50 olarak hesapla (yani %50)
            let annualRate = customRateDecimal
            let dailyRate = (annualRate / 100) / 365
            
            // Özel oran girilse bile, aralık bazlı faizsiz kısım hesaplamaya dahil edilecek
            var interestPrincipal = amount
            var breakdown: [String: Decimal] = [:]
            
            // Önce nonInterestLimit (faizsiz kısım)
            if bank.nonInterestLimit > 0 {
                let nonInterest = min(amount, bank.nonInterestLimit)
                if nonInterest > 0 {
                    breakdown["nonInterest"] = nonInterest
                    interestPrincipal -= nonInterest
                }
            }
            
            // Girilen tutarın hangi aralıkta olduğunu bul ve faizsiz kısım uygula
            let plan = bank.standard // Özel oran için standard plan kullan
            for tier in plan.tiers {
                if amount >= tier.min && (tier.max == nil || amount <= tier.max!) {
                    // Bu aralıkta faizsiz kalan miktar varsa, onu kes
                    if let nonInterest = tier.nonInterestAmount, nonInterest > 0 {
                        let nonInterestHere = min(interestPrincipal, nonInterest)
                        if nonInterestHere > 0 {
                            breakdown["tier_faizsiz"] = nonInterestHere
                            interestPrincipal -= nonInterestHere
                        }
                    }
                    break
                }
            }
            
            if interestPrincipal > 0 {
                let result = compoundInterest(principal: interestPrincipal, dailyRate: dailyRate, days: days)
                let grossGain = result - interestPrincipal
                let netGain = grossGain * (1 - STOPAJ_RATE)
                let firstDayGross = interestPrincipal * dailyRate
                let firstDayNet = firstDayGross * (1 - STOPAJ_RATE)
                
                breakdown["customRate"] = interestPrincipal
                breakdown["customRate_netGetiri"] = netGain
                breakdown["customRate_ilkGunNetGetiri"] = firstDayNet
                
                return (netGain, dailyRate, breakdown, firstDayNet)
            } else {
                // Tüm tutar faizsiz
                return (0, dailyRate, breakdown, 0)
            }
        }
        
        // Normal tier hesaplaması - sadece girilen tutarın bulunduğu aralık için
        let plan = (mode == .welcome ? bank.welcome : bank.standard) ?? bank.standard
        var breakdown: [String: Decimal] = [:]
        var totalNetGain: Decimal = 0
        var weightedDailyRate: Decimal = 0
        var totalFirstDayNetGain: Decimal = 0
        
        // Önce nonInterestLimit (faizsiz kısım)
        if bank.nonInterestLimit > 0 {
            let nonInterest = min(amount, bank.nonInterestLimit)
            if nonInterest > 0 {
                breakdown["nonInterest"] = nonInterest
            }
        }
        
        // Girilen tutarın hangi aralıkta olduğunu bul
        var foundTier: RateTier? = nil
        for tier in plan.tiers {
            let tierMin = tier.min
            let tierMax = tier.max ?? Decimal.greatestFiniteMagnitude
            if amount >= tierMin && amount <= tierMax {
                foundTier = tier
                break
            }
        }
        
        // Sadece bulunan aralık için hesaplama yap
        if let tier = foundTier {
            var interestPrincipal = amount
            
            // Bu aralıkta faizsiz kalan miktar varsa, onu kes
            if let nonInterest = tier.nonInterestAmount, nonInterest > 0 {
                let nonInterestHere = min(amount, nonInterest)
                if nonInterestHere > 0 {
                    breakdown["tier_faizsiz"] = nonInterestHere
                    interestPrincipal -= nonInterestHere
                }
            }
            
            if interestPrincipal > 0 {
                let annualRate = tier.dailyRate
                let dailyRate = (annualRate / 100) / 365
                let result = compoundInterest(principal: interestPrincipal, dailyRate: dailyRate, days: days)
                let grossGain = result - interestPrincipal
                let netGain = grossGain * (1 - STOPAJ_RATE)
                let firstDayGross = interestPrincipal * dailyRate
                let firstDayNet = firstDayGross * (1 - STOPAJ_RATE)
                
                breakdown["tier_tutar"] = interestPrincipal
                breakdown["tier_netGetiri"] = netGain
                breakdown["tier_ilkGunNetGetiri"] = firstDayNet
                
                totalNetGain = netGain
                totalFirstDayNetGain = firstDayNet
                weightedDailyRate = annualRate // Yıllık oranı döndür (tablo için)
            }
        }
        
        // maxCap kontrolü (hoş geldin için üst sınır)
        if let maxCap = plan.maxCap, amount > maxCap {
            let over = amount - maxCap
            breakdown["overCap"] = over
        }
        
        return (totalNetGain, weightedDailyRate, breakdown, totalFirstDayNetGain)
    }
    
    /// Bileşik faiz formülü
    private func compoundInterest(principal: Decimal, dailyRate: Decimal, days: Int) -> Decimal {
        let p = (principal as NSDecimalNumber).doubleValue
        let r = (dailyRate as NSDecimalNumber).doubleValue
        let result = p * pow(1 + r, Double(days))
        return Decimal(result)
    }
}
