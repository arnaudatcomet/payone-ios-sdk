//
//  PayoneManager.swift
//  BCEL-QRCode
//
//  Created by Arnaud Phommasone on 3/7/20.
//  Copyright © 2020 Arnaud Phommasone. All rights reserved.
//

import Foundation
import PubNub

public class PayoneTransaction {
    var invoiceid: String?
    var amount: Int
    var currency: PayoneCurrencyCode?
    var description: String?
    var reference: String?
    
    init() {
        amount = 0
    }
    
    static func createUniqueTransaction(invoiceid: String? = nil, amount: Int, currency: PayoneCurrencyCode, description: String? = nil, reference: String? = nil) -> PayoneTransaction {
        // Amount must be less than 13 characters
        assert("\(amount)".count < 13, "Amount must be up to 13 characters")
        
        let transaction = PayoneTransaction()
        // Create a unique transaction ID
        transaction.reference = UUID().uuidString.lowercased()
        transaction.invoiceid = invoiceid
        transaction.amount = amount
        transaction.currency = currency
        
        return transaction
    }
}

public class PayoneManager {
    // Bank providing these data
    var iin: String = "BCEL"
    var applicationid: String = "ONEPAY"
    var mcid: String
    var terminalid: String = "101"
    var country = "LA"
    var province = "VTE"
    
    // For listening if payment was done

    init?(mcid: String) {
        // perform some initialization here
        if mcid.isEmpty { return nil }
        self.mcid = mcid
    }
   
    private func buildqr(fields: [String: Any]) -> String {
        var result: String = ""
        
        // Order the keyvalues
        let fieldsOrdered = fields.sorted(by: { $0.0 < $1.0 })
        
        for (key, value) in fieldsOrdered {
            let valueToString = "\(value)"
            if valueToString.isEmpty || valueToString == "nil" {
                continue
            }
            
            var unwrappedValue: String = ""
            if value is String {
                unwrappedValue = value as! String
            }
            else if value is Int {
                unwrappedValue = "\(value)"
            }
            else if value is UInt16 {
                unwrappedValue = "\(value)"
            }
            
           let valueLength = "\(unwrappedValue.count)"
            result += key.leftPadding(toLength: 2, withPad: "0")
            result += valueLength.leftPadding(toLength: 2, withPad: "0")
            result += unwrappedValue
        }
        return result
    }
    
    /// Generate a representation string deducted from a PayoneTransaction object. This string can be passed to generate a QRCode using CIFilter
    /// - Parameter transaction: an object of PayoneTransaction, containing a mandatory amount and currency
    public func getQRCodeInfo(transaction: PayoneTransaction) -> String?{
        assert(self.mcid != nil, "MCID must not be empty")
        let mcc = "4111"
        let ccy: String = "\(String(describing: transaction.currency?.rawValue ?? 0))"
        let country = "LA"
        let province = "VTE"
        
        // You set these data
        let amount = transaction.amount
        let invoiceid = transaction.invoiceid
        let transactionid = transaction.reference
        let terminalid = self.terminalid
        let description = transaction.description
      
        var qrcodeRaw: String = buildqr(fields: [
          "00" : "01",
          "01" : "11",
          "33" : buildqr(fields: [
            "00" : self.iin,
            "01" : self.applicationid,
            "02" : self.mcid
          ]),
          "52" : mcc,
          "53" : ccy,
          "54" : amount,
          "58" : country,
          "60" : province,
          "62" : buildqr(fields: [
              "01" : invoiceid ?? nil,
              "05" : transactionid ?? nil,
              "07" : terminalid,
              "8" : description ?? nil
          ]),
        ])
        
        qrcodeRaw += buildqr(fields: [
                      "63" : crc16ccitt(data: (qrcodeRaw + "6304").utf8.map{$0}),
                  ])
        
        return qrcodeRaw
    }
    
    private func crc16ccitt(data: [UInt8], polynome: UInt16 = 0x1021, start: UInt16 = 0xffff, final: UInt16 = 0)->UInt16{
        var crc = start
        data.forEach { (byte) in
            crc ^= UInt16(byte) << 8
            crc &= 0xffff
            (0..<8).forEach({ _ in
                crc = (crc & UInt16(0x8000)) != 0 ? (crc << 1) ^ polynome : crc << 1
                crc &= UInt16(0xffff)
            })
        }
        crc ^= final
        return crc
    }
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
}
