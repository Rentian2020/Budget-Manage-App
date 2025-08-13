//
//  Transactions.swift
//  Budget
//
//  Created by Arthur Guiot on 11/13/24.
//

import Gravity
import Foundation

struct Transaction: RemoteRepresentable {
    let id: String
    let accountId: String
    let amount: Float
    let isoCurrencyCode: String?
    let unofficialCurrencyCode: String?
    let categoryId: String?
    let date: Date?
    let merchantName: String?
    let pending: Bool
    let logoUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case amount
        case isoCurrencyCode = "iso_currency_code"
        case unofficialCurrencyCode = "unofficial_currency_code"
        case categoryId = "category_id"
        case date
        case merchantName = "merchant_name"
        case pending
        case logoUrl = "logo_url"
    }
}

extension Array<Transaction> {
    var sumInUSD: Double {
        let sumInEUR = reduce(0) { $0 + abs(Double($1.amount.isFinite ? $1.amount : 0)) / (ExchangeRate.shared.rates[$1.isoCurrencyCode ?? "EUR"] ?? 1.0) }
        
        return sumInEUR * (ExchangeRate.shared.rates["USD"] ?? 1.0)
    }
}
