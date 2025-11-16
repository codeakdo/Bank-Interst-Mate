import Foundation

// Faiz tipi
enum RateMode {
    case welcome
    case standard
    case custom
}

// Oran kademesi
struct RateTier {
    let min: Decimal
    let max: Decimal? // nil = sonsuz
    let dailyRate: Decimal
    let nonInterestAmount: Decimal? // Bu aralıkta faizsiz kalan miktar (opsiyonel)
}

// Banka faiz planı
struct BankRatePlan {
    let tiers: [RateTier]
    let maxCap: Decimal? // Hoş geldin için üst sınır olabilir
}

// Banka ana modeli
struct Bank {
    let id: String
    let name: String
    let nonInterestLimit: Decimal
    let welcome: BankRatePlan?
    let standard: BankRatePlan
    let minDeposit: Decimal
    var customRate: Decimal? // Kullanıcının girebileceği özel günlük faiz oranı
}

// Banka bazında dağıtım ve getiri sonucu
struct BankAllocationResult {
    let bank: Bank
    let allocated: Decimal
    let weightedDailyRate: Decimal
    let gain30d: Decimal
    let breakdown: [String: Decimal] // ["nonInterest": x, "tier1": y, ...]
    let firstDayNetGain: Decimal
    let selectedMode: RateMode // Hangi faiz tipi kullanıldı
}

// Örnek sabit banka veri seti (oranları ve limitleri sen doldurabilirsin)
let sampleBanks: [Bank] = [
    Bank(
        id: "vakifbank",
        name: "Vakıfbank",
        nonInterestLimit: 0,
        welcome: BankRatePlan(
            tiers: [
                RateTier(min: 0, max: 10_000, dailyRate: 45, nonInterestAmount: 5_000),
                RateTier(min: 10_001, max: 50_000, dailyRate: 45, nonInterestAmount: 7_500),
                RateTier(min: 50_001, max: 100_000, dailyRate: 45, nonInterestAmount: 10_000),
                RateTier(min: 100_001, max: 150_000, dailyRate: 45, nonInterestAmount: 15_000),
                RateTier(min: 150_001, max: 200_000, dailyRate: 45, nonInterestAmount: 17_500),
                RateTier(min: 200_001, max: 250_000, dailyRate: 45, nonInterestAmount: 20_000),
                RateTier(min: 250_001, max: 300_000, dailyRate: 45, nonInterestAmount: 20_000),
                RateTier(min: 300_001, max: 300_000, dailyRate: 45, nonInterestAmount: 35_000),
                RateTier(min: 500_001, max: 750_000, dailyRate: 45, nonInterestAmount: 75_000),
                RateTier(min: 750_001, max: 1_000_000, dailyRate: 45, nonInterestAmount: 75_000),
                RateTier(min: 1_000_001, max: 1_500_000, dailyRate: 45, nonInterestAmount: 150_000),
                RateTier(min: 1_500_001, max: 2_000_000, dailyRate: 45, nonInterestAmount: 160_000),
            ],
            maxCap: 2_000_001
        ),
        standard: BankRatePlan(
            tiers: [
                RateTier(min: 0, max: 10_000, dailyRate: 13, nonInterestAmount: 5_000),
                RateTier(min: 10_001, max: 50_000, dailyRate: 18, nonInterestAmount: 7_500),
                RateTier(min: 50_001, max: 100_000, dailyRate: 21, nonInterestAmount: 10_000),
                RateTier(min: 100_001, max: 150_000, dailyRate: 31, nonInterestAmount: 15_000),
                RateTier(min: 150_001, max: 250_000, dailyRate: 31, nonInterestAmount: 17_500),
                RateTier(min: 250_001, max: 300_000, dailyRate: 36, nonInterestAmount: 20_000),
                RateTier(min: 300_001, max: 500_000, dailyRate: 36, nonInterestAmount: 35_000),
                RateTier(min: 500_001, max: 750_000, dailyRate: 37, nonInterestAmount: 75_000),
                RateTier(min: 750_001, max: 1_000_000, dailyRate: 37, nonInterestAmount: 75_000),
                RateTier(min: 1_000_001, max: 1_500_000, dailyRate: 40, nonInterestAmount: 150_000),
                RateTier(min: 1_500_001, max: 2_000_000, dailyRate: 40, nonInterestAmount: 160_000),
            ],
            maxCap: nil
        ),
        minDeposit: 5_000
    ),
    Bank(
        id: "yapikredi",
        name: "Yapı Kredi",
        nonInterestLimit: 0,
        welcome: BankRatePlan(
            tiers: [
                RateTier(min: 0, max: 10_000, dailyRate: 0, nonInterestAmount: nil),
                RateTier(min: 10_000, max: 49_999, dailyRate: 39, nonInterestAmount: 5_000),
                RateTier(min: 50_000, max: 99_999, dailyRate: 39, nonInterestAmount: 7_500),
                RateTier(min: 100_000, max: 249_999, dailyRate: 39, nonInterestAmount: 15_000),
                RateTier(min: 250_000, max: 499_999, dailyRate: 39, nonInterestAmount: 30_000),
                RateTier(min: 500_000, max: 999_999, dailyRate: 39, nonInterestAmount: 60_000),
                RateTier(min: 1_000_000, max: 1_999_999, dailyRate: 39, nonInterestAmount: 120_000),

            
            ],
            maxCap: 2_000_000
        ),
        standard: BankRatePlan(
            tiers: [
                RateTier(min: 0, max: 10_000, dailyRate: 34, nonInterestAmount: 5_000),
                RateTier(min: 10_001, max: 50_000, dailyRate: 34, nonInterestAmount: 7_500),
                RateTier(min: 50_001, max: 100_000, dailyRate: 34, nonInterestAmount: 10_000),
                RateTier(min: 100_001, max: 150_000, dailyRate: 34, nonInterestAmount: 15_000),
                RateTier(min: 150_001, max: 250_000, dailyRate: 34, nonInterestAmount: 15_000),
                RateTier(min: 250_001, max: 300_000, dailyRate: 34, nonInterestAmount: 20_000),
                RateTier(min: 300_001, max: 500_000, dailyRate: 34, nonInterestAmount: 35_000),
                RateTier(min: 500_001, max: 750_000, dailyRate: 34, nonInterestAmount: 75_000),
                RateTier(min: 750_001, max: 1_000_000, dailyRate: 34, nonInterestAmount: 75_000),
                
            ],
            maxCap: nil
        ),
        minDeposit: 5_000
    ),
    Bank(
        id: "isbankasi",
        name: "İş Bankası",
        nonInterestLimit: 0, // Örnek: faizsiz limit yok
        welcome: BankRatePlan(
            tiers: [
                RateTier(min: 0, max: 4_999, dailyRate: 0, nonInterestAmount: 0),
                RateTier(min: 5_000, max: 24_999, dailyRate: 38, nonInterestAmount: 0),
                RateTier(min: 25_000, max: 100_000, dailyRate: 38, nonInterestAmount: 0),
                RateTier(min: 100_001, max: 250_000, dailyRate: 38, nonInterestAmount: 0),
                RateTier(min: 250_001, max: 2_000_000, dailyRate: 38, nonInterestAmount: 0),

               
            ],
            maxCap: 2_000_000
        ),
        
        standard: BankRatePlan(
            tiers: [
                RateTier(min: 0, max: 4_999, dailyRate: 0, nonInterestAmount: 0),
                RateTier(min: 5_000, max: 24_999, dailyRate: 38, nonInterestAmount: 0),
                RateTier(min: 25_000, max: 100_000, dailyRate: 38, nonInterestAmount: 0),
                RateTier(min: 100_001, max: 250_000, dailyRate: 38, nonInterestAmount: 0),
                RateTier(min: 250_001, max: 2_000_000, dailyRate: 38, nonInterestAmount: 0),

            ],
            maxCap: 2_000_000
        ),
        minDeposit: 5_000
    ),
    Bank(
        id: "ingbank",
        name: "ING Bank",
        nonInterestLimit: 0, // Örnek: faizsiz limit yok
        welcome: BankRatePlan(
            tiers: [
                RateTier(min: 3_000, max: 9_999, dailyRate: 49, nonInterestAmount: 3_000),
                RateTier(min: 10_000, max: 49_999, dailyRate: 49, nonInterestAmount: 5_000),
                RateTier(min: 50_000, max: 99_999, dailyRate: 49, nonInterestAmount: 7_500),
                RateTier(min: 100_000, max: 249_999, dailyRate: 49, nonInterestAmount: 15_000),
                RateTier(min: 250_000, max: 499_999, dailyRate: 49, nonInterestAmount: 30_000),
                RateTier(min: 500_000, max: 999_999, dailyRate: 49, nonInterestAmount: 75_000),
                RateTier(min: 1_000_000, max: 1_999_999, dailyRate: 49, nonInterestAmount: 150_000),

               
            ],
            maxCap: 2_000_000
        ),
        
        standard: BankRatePlan(
            tiers: [
                RateTier(min: 3_000, max: 9_999, dailyRate: 23, nonInterestAmount: 3_000),
                RateTier(min: 10_000, max: 49_999, dailyRate: 23, nonInterestAmount: 5_000),
                RateTier(min: 50_000, max: 99_999, dailyRate: 23, nonInterestAmount: 7_500),
                RateTier(min: 100_000, max: 249_999, dailyRate: 23, nonInterestAmount: 15_000),
                RateTier(min: 250_000, max: 499_999, dailyRate: 23, nonInterestAmount: 30_000),
                RateTier(min: 500_000, max: 999_999, dailyRate: 23, nonInterestAmount: 75_000),
                RateTier(min: 1_000_000, max: 1_999_999, dailyRate: 23, nonInterestAmount: 150_000),
            ],
            maxCap: 2_000_000
        ),
        minDeposit: 3_000
    ),
]
