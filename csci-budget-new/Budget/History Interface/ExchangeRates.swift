//
//  ExchangeRates.swift
//  Budget
//
//  Created by Arthur Guiot on 11/29/24.
//

import Foundation

enum ExangeError: Error {
    case stringToData
}
struct ExchangeRate: Decodable {
    struct Rates: Decodable {
        let EUR: Double = 1 // Starting from Euro
        var CAD: Double?
        var HKD: Double?
        var ISK: Double?
        var PHP: Double?
        var DKK: Double?
        var HUF: Double?
        var CZK: Double?
        var AUD: Double?
        var RON: Double?
        var SEK: Double?
        var IDR: Double?
        var INR: Double?
        var BRL: Double?
        var RUB: Double?
        var HRK: Double?
        var JPY: Double?
        var THB: Double?
        var CHF: Double?
        var SGD: Double?
        var PLN: Double?
        var BGN: Double?
        var TRY: Double?
        var CNY: Double?
        var NOK: Double?
        var NZD: Double?
        var ZAR: Double?
        var USD: Double?
        var MXN: Double?
        var ILS: Double?
        var GBP: Double?
        var KRW: Double?
        var MYR: Double?
        
        // Dictionary representation for dynamic lookup
        var ratesDictionary: [String: Double?] {
            return [
                "EUR": EUR,
                "CAD": CAD,
                "HKD": HKD,
                "ISK": ISK,
                "PHP": PHP,
                "DKK": DKK,
                "HUF": HUF,
                "CZK": CZK,
                "AUD": AUD,
                "RON": RON,
                "SEK": SEK,
                "IDR": IDR,
                "INR": INR,
                "BRL": BRL,
                "RUB": RUB,
                "HRK": HRK,
                "JPY": JPY,
                "THB": THB,
                "CHF": CHF,
                "SGD": SGD,
                "PLN": PLN,
                "BGN": BGN,
                "TRY": TRY,
                "CNY": CNY,
                "NOK": NOK,
                "NZD": NZD,
                "ZAR": ZAR,
                "USD": USD,
                "MXN": MXN,
                "ILS": ILS,
                "GBP": GBP,
                "KRW": KRW,
                "MYR": MYR
            ]
        }
        
        // Subscript for dynamic access
        subscript(_ currencyCode: String) -> Double? {
            return ratesDictionary[currencyCode] ?? nil
        }
    }
    
    var date: String
    var rates: Rates
    
    static func from(json: String) throws -> ExchangeRate {
        guard let data = json.data(using: .utf8) else { throw ExangeError.stringToData }
        let rate = try JSONDecoder().decode(ExchangeRate.self, from: data)
        return rate
    }
    
    static func purgeCache() {
        guard let url = URL(string: "https://api-euclid.pr1mer.tech") else { return }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            guard let json = String(data: data, encoding: .utf8) else { return }
            let defaults = UserDefaults.standard
            defaults.set(json, forKey: "currency")
        }
        task.resume()
    }
    
    static var shared: ExchangeRate {
        let defaults = UserDefaults.standard
        
        let known = "{\"date\":\"Wed Apr 07 2021\",\"rates\":{\"USD\":1.1884,\"JPY\":130.56,\"BGN\":1.9558,\"CZK\":25.919,\"DKK\":7.4365,\"GBP\":0.86065,\"HUF\":359.68,\"PLN\":4.5756,\"RON\":4.9185,\"SEK\":10.236,\"CHF\":1.1044,\"ISK\":150.4,\"NOK\":10.0535,\"HRK\":7.5763,\"RUB\":92.3359,\"TRY\":9.7227,\"AUD\":1.5581,\"BRL\":6.644,\"CAD\":1.4982,\"CNY\":7.7761,\"HKD\":9.2527,\"IDR\":17304.71,\"ILS\":3.9236,\"INR\":88.3675,\"KRW\":1328.05,\"MXN\":24.0091,\"MYR\":4.9099,\"NZD\":1.6907,\"PHP\":57.965,\"SGD\":1.5917,\"THB\":37.286,\"ZAR\":17.2803}}" // String known to work
        
        let json = defaults.string(forKey: "currency") ?? known
        
        do {
            let rate = try from(json: json)
            return rate
        } catch {
            return try! from(json: known)
        }
    }
}
