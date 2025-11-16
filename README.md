# Bank Interest Optimizer (Banka Faiz Bot)

A SwiftUI-based financial utility that helps users calculate and optimize their bank deposit allocations across multiple banks. The app analyzes selected banks, interest modes, custom rates, and tiered rate structures to find the most profitable 30-day return and effective daily rate.

---

📌 **Table of Contents**
- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Data Models](#data-models)
- [Configuration](#configuration)
- [Example Workflow](#example-workflow)
- [Troubleshooting](#troubleshooting)
- [Contributors](#contributors)
- [License](#license)

---

## 📖 Introduction

**Bank Interest Optimizer** is an iOS app built using **SwiftUI**, designed to calculate and optimize short-term interest earnings across various banks. Each bank has multiple interest tiers, welcome rates, standard rates, and custom rate options. The app allows the user to select banks, choose interest types, enter custom daily rates, and compute ideal allocations automatically.

It is particularly useful for:

* Comparing banks' interest structures
* Optimizing profit based on tiered daily rates
* Calculating first-day net gain and 30-day total gain
* Managing different rate modes: `welcome`, `standard`, `custom`

## ✨ Features

* 🏦 **Multiple bank support**, each with detailed tier-based interest plans
* 📊 **Automatic allocation optimization** using a dedicated optimizer backend
* 🔢 **Daily rate calculation**, effective rate, and 30-day gain calculation
* 🛠 **Custom interest rate mode** per bank
* 🧮 **Tier-based breakdown** of interest earnings
* ❗ **Error handling** for invalid amounts, unselected banks, or insufficient deposit
* 🔄 **Reset functionality** to clear all selections and calculations
* 🧵 **Combine-based ViewModel** for real-time UI updates
### Key Components

* **`Banka_Faiz_BotApp.swift`**
    * Main entry point
    * Launches `ContentView`

* **`BankInterestViewModel.swift`**
    * Handles:
        * Validation
        * Bank selection
        * Calculation logic
        * Total effective rate
        * 30-day profit
        * First day net gain
        * Result formatting
    * Integrates with an `AllocationOptimizer` and `InterestCalculator`

* **`BankModels.swift`**
    * Defines all financial data structures:
        * `RateMode` (welcome, standard, custom)
        * `RateTier`
        * `BankRatePlan`
        * `Bank`
        * `BankAllocationResult`
    * `sampleBanks` dataset with real tier values

## ⚙️ Installation

### Requirements
* iOS 15+
* Xcode 14+
* Swift 5.7+

### Steps
1.  Clone the repository:
    ```bash
    git https://github.com/codeakdo/Bank-Interst-Mate.git
    ```
2.  Open the project in Xcode:
    ```bash
    open BankaFaizBot.xcodeproj
    ```
3.  Build & Run on simulator or device.

## 🚀 Usage

1.  Enter your **total deposit amount**
2.  Select one or more **banks**
3.  Choose rate mode per bank:
    * Welcome rate
    * Standard rate
    * Custom daily rate
4.  Tap **Calculate**
5.  View:
    * Optimal allocations
    * Daily weighted interest
    * 30-day gain
    * First-day net gain
    * Tier breakdown
6.  **Reset** anytime to start over.

## 🧩 Data Models

The app uses a flexible tier-based interest system:

### Rate Tiers (`RateTier`)
Each tier defines:
* Minimum & maximum amount
* Daily interest rate
* Optional non-interestable amount

### Bank (`Bank`)
Each bank includes:
* Welcome & standard rate plans
* Minimum deposit requirement
* Custom rate support
* Non-interest limits

### Calculation Output (`BankAllocationResult`)
Contains:
* Allocated amount per bank
* Effective weighted daily rate
* First-day net gain
* 30-day total gain
* Tier breakdown mapping

## 🔧 Configuration

Modify `sampleBanks` in `BankModels.swift` to adjust:

* Interest rates
* Tiers
* Non-interestable portions
* Minimum deposits
* Welcome rate caps

All logic automatically adapts to your dataset.

## 📝 Example Workflow

1.  User enters: **₺200,000**
2.  Selects **Vakıfbank**, **ING**, **İş Bankası**
3.  Chooses:
    * Vakıfbank → `Welcome`
    * ING → `Custom` (49 daily)
    * İş Bankası → `Standard`
4.  App:
    * Validates inputs
    * Filters selected banks
    * Calculates tiered returns
    * Finds optimal distribution
    * Displays results with charts/percentages

## 🛠 Troubleshooting

| Issue | Explanation |
| :--- | :--- |
| **"Please enter a valid amount"** | Amount was empty, zero, or invalid format. |
| **"Select at least one bank"** | No bank was chosen. |
| **"Amount below minimum deposit"** | Deposit does not meet selected bank’s minimum requirement. |
| **Empty results** | All selected banks rejected allocation due to tier constraints. |

## 👤 Contributors

* **Ege Işık Akdoğan** — Developer & Project Owner
* Made by ❤️ **CodeAkdo** 

## 📄 License
* *MIT*
* *Apache 2.0*
* *GPL*
