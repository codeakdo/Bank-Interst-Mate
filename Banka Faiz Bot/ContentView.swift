//
//  ContentView.swift
//  Banka Faiz Bot
//
//  Created by Ege Işık Akdoğan on 17.08.2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = BankInterestViewModel()
    @State private var showResults = false
    
    var body: some View {
        NavigationStack {
            if showResults {
                ResultsView(viewModel: viewModel) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showResults = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                CalculationView(viewModel: viewModel) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showResults = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
    }
}

struct CalculationView: View {
    @ObservedObject var viewModel: BankInterestViewModel
    var onCalculate: () -> Void
    
    var body: some View {
        ZStack {
            // Arka plan gradyanı
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Form {
                Section(header: Text("Toplam Tutar").font(.headline).foregroundColor(.primary)) {
                    TextField("Toplam Tutar (TL)", text: $viewModel.totalAmount)
                           .keyboardType(.decimalPad)
                           .onChange(of: viewModel.totalAmount) { oldValue, newValue in
                               handleAmountInput(newValue)
                           }
                           .toolbar {
                               ToolbarItemGroup(placement: .keyboard) {
                                   Spacer()
                                   Button("Bitti") {
                                       UIApplication.shared.sendAction(
                                           #selector(UIResponder.resignFirstResponder),
                                           to: nil, from: nil, for: nil
                                       )
                                   }
                               }
                           }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hangi bankalardan hesabınız var?").font(.subheadline).fontWeight(.medium)
                        ForEach(viewModel.allBanks, id: \.id) { bank in
                            BankSelectionRow(bank: bank, viewModel: viewModel)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    HStack(spacing: 16) {
                        Button("Hesapla") {
                            viewModel.calculate()
                            // Sadece hata yoksa geçiş yap
                            if viewModel.errorMessage == nil && !viewModel.results.isEmpty {
                                onCalculate()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Temizle") {
                            viewModel.reset()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.white.opacity(0.9))
                
                if let error = viewModel.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.red.opacity(0.1))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Banka Faiz Bot")
    }
    
    private func handleAmountInput(_ newValue: String) {
        let filtered = newValue.filter { "0123456789,.".contains($0) }
        let components = filtered.components(separatedBy: ",")
        if components.count > 2 {
            let beforeDecimal = components.dropLast(2).joined()
            let decimalPart = components.suffix(2).joined(separator: ",")
            viewModel.totalAmount = beforeDecimal + "," + decimalPart
        } else {
            viewModel.totalAmount = filtered
        }
        if let number = Double(filtered.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = "."
            formatter.decimalSeparator = ","
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            if let formatted = formatter.string(from: NSNumber(value: number)) {
                viewModel.totalAmount = formatted
            }
        }
    }
}

struct ResultsView: View {
    @ObservedObject var viewModel: BankInterestViewModel
    var goBack: () -> Void
    
    var body: some View {
        ZStack {
            // Güzel arka plan geçişi
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.15),
                    Color.orange.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Sonuçlar Özeti
                    VStack(spacing: 16) {
                        Text("Sonuçlar")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            ResultCard(
                                title: "Toplam Net Getiri (30g)",
                                value: "₺" + viewModel.formatted(viewModel.totalGain),
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            )
                            
                            ResultCard(
                                title: "Toplam İlk Gün Net Getiri",
                                value: "₺" + viewModel.formatted(viewModel.totalFirstDayNetGain),
                                icon: "calendar.badge.clock",
                                color: .blue
                            )
                            
                            ResultCard(
                                title: "Efektif Ortalama Oran",
                                value: String(format: "%.3f%%", (viewModel.effectiveRate as NSDecimalNumber).doubleValue),
                                icon: "percent",
                                color: .orange
                            )
                        }
                        
                        VStack(spacing: 8) {
                            Text("Getiriler stopaj (%17,5) sonrası net tutardır.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Efektif Ortalama Oran: Tüm bankalardaki ağırlıklı ortalama günlük faiz oranıdır.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    
                    // Banka Dağılımı
                    VStack(spacing: 16) {
                        Text("Banka Dağılımı")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        PieChartView(results: viewModel.results)
                            .frame(height: 240)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                        
                        // Kademe Açıklaması
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Kademe Hesaplama Açıklaması")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(text: "• Her banka farklı tutar aralıklarında farklı faiz oranları uygular")
                                InfoRow(text: "• Her kademede belirli bir miktar faizsiz kalabilir (örn: 0-10k arası 5k faizsiz)")
                                InfoRow(text: "• Sistem paranızı kademelere göre böler ve her kademe için ayrı hesaplama yapar")
                                InfoRow(text: "• Bu sayede gerçek bankacılık kurallarına uygun hesaplama yapılır")
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // Detaylı Sonuçlar
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet.clipboard.fill")
                                    .foregroundColor(.purple)
                                Text("Detaylı Sonuçlar")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            ScrollView([.horizontal, .vertical]) {
                                TableView(results: viewModel.results, percent: viewModel.percent, formatted: viewModel.formatted, viewModel: viewModel)
                                    .padding(.bottom, 16)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        )
                    }
                    
                    // Geri Dön Butonu
                    Button(action: goBack) {
                        HStack {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.title2)
                            Text("Geri Dön")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Sonuçlar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Yeni UI bileşenleri
struct ResultCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct InfoRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.blue)
                .fontWeight(.bold)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// CheckboxToggleStyle for bank selection
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { 
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .blue : .gray)
                configuration.label
            }
        }
        .buttonStyle(.plain)
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}

// BankSelectionRow for each bank selection
struct BankSelectionRow: View {
    let bank: Bank
    @ObservedObject var viewModel: BankInterestViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(isOn: Binding(
                    get: { viewModel.selectedBanks.contains(bank.id) },
                    set: { isOn in
                        if isOn {
                            viewModel.selectBank(bank.id)
                        } else {
                            viewModel.deselectBank(bank.id)
                        }
                    }
                )) {
                    Text(bank.name)
                        .fontWeight(.medium)
                }
                .toggleStyle(CheckboxToggleStyle())
            }
            
            if viewModel.selectedBanks.contains(bank.id) {
                HStack {
                    Picker("Faiz Tipi", selection: Binding(
                        get: { 
                            // Eğer özel oran girilmişse custom seç
                            if !(viewModel.customRates[bank.id] ?? "").isEmpty {
                                return .custom
                            }
                            return viewModel.selectedModes[bank.id] ?? .welcome
                        },
                        set: { (newMode: RateMode) in
                            viewModel.selectedModes[bank.id] = newMode
                            // Eğer custom seçilirse, özel oran kutusunu temizle
                            if newMode != .custom {
                                viewModel.customRates[bank.id] = ""
                            }
                        }
                    )) {
                        Text("Hoş Geldin").tag(RateMode.welcome)
                        Text("Normal").tag(RateMode.standard)
                        Text("Özel Oran").tag(RateMode.custom)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                    .onChange(of: viewModel.selectedModes[bank.id] ?? .welcome) { oldValue, newValue in
                        // Kullanıcı manuel seçim yaparsa özel oran kutusunu temizle
                        if newValue != .custom {
                            viewModel.customRates[bank.id] = ""
                        }
                    }
                    
                    // Özel oran girişi
                    TextField("Özel %", text: Binding(
                        get: { viewModel.customRates[bank.id] ?? "" },
                        set: { newValue in
                            viewModel.customRates[bank.id] = newValue
                            // Eğer özel oran girilirse, otomatik olarak custom seç
                            if !newValue.isEmpty {
                                viewModel.selectedModes[bank.id] = .custom
                            }
                        }
                    ))
                    .onChange(of: viewModel.customRates[bank.id] ?? "") { oldValue, newValue in
                        // Kullanıcı özel oran yazmaya başlarsa otomatik custom seç
                        if !newValue.isEmpty {
                            viewModel.selectedModes[bank.id] = .custom
                        }
                    }
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Bitti") {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil
                                )
                            }
                        }
                    }
                    .placeholder(when: viewModel.customRates[bank.id]?.isEmpty ?? true) {
                        Text("Oran %")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Placeholder extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct PieChartView: View {
    let results: [BankAllocationResult]
    private let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .teal, .indigo]
    
    var total: Decimal {
        results.reduce(0) { $0 + $1.allocated }
    }
    
    var slices: [(name: String, percent: Double, color: Color)] {
        var idx = 0
        return results.map { result in
            let pct = total > 0 ? (result.allocated / total * 100 as NSDecimalNumber).doubleValue : 0
            let color = colors[idx % colors.count]
            idx += 1
            return (result.bank.name, pct, color)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2 - 16
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<slices.count, id: \ .self) { i in
                    let startAngle = Angle(degrees: slices.prefix(i).map { $0.percent }.reduce(0, +) / 100 * 360)
                    let endAngle = Angle(degrees: (slices.prefix(i+1).map { $0.percent }.reduce(0, +)) / 100 * 360)
                    PieSlice(startAngle: startAngle, endAngle: endAngle)
                        .fill(slices[i].color)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                // Etiketler - daha iyi konumlandırma
                ForEach(0..<slices.count, id: \ .self) { i in
                    let midAngle = Angle(degrees: (slices.prefix(i).map { $0.percent }.reduce(0, +) + slices[i].percent / 2) / 100 * 360)
                    let labelRadius = radius * 0.6
                    let x = center.x + CGFloat(cos(midAngle.radians)) * labelRadius
                    let y = center.y + CGFloat(sin(midAngle.radians)) * labelRadius
                    
                    if slices[i].percent > 5 {
                        Text(slices[i].name)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 8
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle - Angle(degrees: 90), endAngle: endAngle - Angle(degrees: 90), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct TableView: View {
    let results: [BankAllocationResult]
    let percent: (Decimal) -> String
    let formatted: (Decimal) -> String
    let viewModel: BankInterestViewModel // viewModel'i parametre olarak al
    @State private var expandedBankIds: Set<String> = []
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Banka").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Tutar").bold().frame(width: 100, alignment: .trailing)
                Text("% Dağılım").bold().frame(width: 80, alignment: .trailing)
                Text("Faiz Oranı").bold().frame(width: 80, alignment: .trailing)
                Text("İlk Gün Net Getiri").bold().frame(width: 120, alignment: .trailing)
                Text("Net Getiri (30g)").bold().frame(width: 120, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            ForEach(results, id: \ .bank.id) { result in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedBankIds.contains(result.bank.id) },
                        set: { expanded in
                            if expanded { expandedBankIds.insert(result.bank.id) }
                            else { expandedBankIds.remove(result.bank.id) }
                        }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(result.breakdown.sorted(by: { $0.key < $1.key }), id: \ .key) { key, value in
                                HStack {
                                    Text(breakdownLabel(for: key))
                                    Spacer()
                                    if key.contains("ilkGunNetGetiri") {
                                        Text("İlk Gün Net: ₺" + formatted(value)).foregroundColor(.blue)
                                    } else if key.contains("netGetiri") {
                                        Text("Net Getiri: ₺" + formatted(value)).foregroundColor(.green)
                                    } else {
                                        Text("₺" + formatted(value))
                                    }
                                }
                                .font(.callout)
                                .foregroundColor(key.contains("netGetiri") ? .green : (key.contains("ilkGunNetGetiri") ? .blue : .secondary))
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(6)
                    },
                    label: {
                        HStack {
                            Text(result.bank.name).frame(maxWidth: .infinity, alignment: .leading)
                            Text("₺" + formatted(result.allocated)).frame(width: 100, alignment: .trailing)
                            Text(percent(result.allocated)).frame(width: 80, alignment: .trailing)
                            Text(getFaizOraniText(for: result)).frame(width: 80, alignment: .trailing)
                            Text("₺" + formatted(result.firstDayNetGain)).frame(width: 120, alignment: .trailing)
                            Text("₺" + formatted(result.gain30d)).frame(width: 120, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                    }
                )
            }
        }
    }
    
    private func getFaizOraniText(for result: BankAllocationResult) -> String {
        let userMode = viewModel.selectedModes[result.bank.id] ?? .welcome
        if userMode == .custom, let customRateStr = viewModel.customRates[result.bank.id], !customRateStr.isEmpty {
            if let customRate = Double(customRateStr.replacingOccurrences(of: ",", with: ".")) {
                return String(format: "%.2f%%", customRate)
            }
        }
        // Hoşgeldin/Normal için weightedDailyRate'i yüzde olarak göster
        if result.weightedDailyRate > 0 {
            return String(format: "%.2f%%", (result.weightedDailyRate as NSDecimalNumber).doubleValue)
        }
        return "-"
    }
    
    private func breakdownLabel(for key: String) -> String {
        switch key {
        case "nonInterest": return "Faiz İşeltilmeyen Tutar"
        case "overCap": return "Üst Sınır Üzeri (Faizsiz)"
        case "customRate": return "Özel Oran Tutarı"
        case "customRate_netGetiri": return "Özel Oran Net Getiri"
        case "customRate_ilkGunNetGetiri": return "Özel Oran İlk Gün Net Getiri"
        case "tier_faizsiz": return "Faiz İşletilmeyen Tutar"
        case "tier_tutar": return "Faizli Tutar"
        case "tier_netGetiri": return "Net Getiri(30g)"
        case "tier_ilkGunNetGetiri": return "İlk Gün Net Getiri"
        default:
            return key
        }
    }
}

#Preview {
    ContentView()
}
