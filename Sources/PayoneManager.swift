//
//  PayoneManager.swift
//  BCEL-QRCode
//
//  Created by Arnaud Phommasone on 3/7/20.
//  Copyright © 2020 Arnaud Phommasone. All rights reserved.
//

import Foundation
import PubNub


public typealias POSocketDidReceiveMessageBlock = (POMessageResult) -> Void
public typealias POSocketDidReceiveStatusBlock = (POStatus) -> Void

public typealias POStatus = PNStatus
public typealias POMessageResult = PNMessageResult
public typealias POResult = PNResult
public typealias POMessageData = PNMessageData
public typealias POPresenceEventResult = PNPresenceEventResult
public typealias POSubscribeStatus = PNSubscribeStatus
public typealias POStatusCategory = PNStatusCategory
public typealias POSignalResult = PNSignalResult
public typealias POSpaceEventResult = PNSpaceEventResult
public typealias POMembershipEventResult = PNMembershipEventResult
public typealias POUserEventResult = PNUserEventResult

public struct POQrcodeImage {
    public var info: String
    public var mcid: String
    public var uuid: String
    
    init(info: String, mcid: String, uuid: String) {
        self.info = info
        self.mcid = mcid
        self.uuid = uuid
    }
}

/// Payone helper to generate a qrcode to be able to be scanned with PayOne app
public struct POQrcodeGenerator {
    /// Build field such as a field number (ex: country), the value lenth and the value.
    /// - Parameter fields: Dictionary of field number and value
     private static func buildqr(fields: [String: Any]) -> String {
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
    public static func getQRCodeInfo(store:POStore, transaction:POTransaction) -> POQrcodeImage?{
        assert(POManager.shared.iin.isEmpty != true, "IIN must not be empty")
        assert(POManager.shared.applicationid.isEmpty != true, "ApplicationID must not be empty")
        let mcc = "4111"
        let ccy: String = "\(String(describing: transaction.currency?.rawValue ?? 0))"
        let country = "LA"
        let province = "VTE"
        
        // You set these data
        let amount = transaction.amount
        let invoiceid = transaction.invoiceid
        let transactionid = transaction.reference
        let terminalid = store.terminalid
        let description = transaction.description
      
        var qrcodeRaw: String = buildqr(fields: [
          "00" : "01",
          "01" : "11",
          "33" : buildqr(fields: [
            "00" : POManager.shared.iin,
            "01" : POManager.shared.applicationid,
            "02" : store.mcid
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
        
        return POQrcodeImage(info: qrcodeRaw, mcid: store.mcid, uuid: transaction.reference ?? "")
    }
    
    /// Checksum implementation of crc16 polynomial
    /// - Parameter data: Data in UInt8
    /// - Parameter polynome: polynome
    /// - Parameter start: start byte
    /// - Parameter final: end byte
    private static func crc16ccitt(data: [UInt8], polynome: UInt16 = 0x1021, start: UInt16 = 0xffff, final: UInt16 = 0)->UInt16{
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


/// A Store containing the merchandise ID (mcid), a terminal ID for POS system (terminalid), the country and the province of the shop
public struct POStore {
    public var mcid: String
    public var terminalid: String?
    public var country: String
    public var province: String
    
    public init(mcid: String, country: String, province: String, terminalID: String? = nil) {
        self.mcid = mcid
        self.terminalid = terminalID
        self.country = country
        self.province = province
    }
}

public struct POTransaction {
    public var invoiceid: String?
    public var amount: Int
    public var currency: POCurrencyCode?
    public var description: String?
    public var reference: String?
    
    public init() {
        amount = 0
    }
    
    public static func createUniqueTransaction(amount: Int, currency: POCurrencyCode, description: String) -> POTransaction {
        // Amount must be less than 13 characters
        assert("\(amount)".count < 13, "Amount must be up to 13 characters")
        
        var transaction = POTransaction()
        // Create a unique transaction ID
        transaction.reference = UUID().uuidString.lowercased()
        transaction.amount = amount
        transaction.currency = currency
        transaction.description = description
        
        return transaction
    }
}

public class POManager: NSObject {
    var iin: String
    var applicationid: String
    
    // Singleton part
    public static let shared = POManager(iin: "BCEL", applicationid: "ONEPAY")
    
    /// Websocket listening to Pubnub channel
    var client: PubNub!
    
    
    /// Handle a new message from a subscribed channel
    public var onReceivedMessage: POSocketDidReceiveMessageBlock?
    
    /// Handle a subscription status change
    public var onReceivedStatus: POSocketDidReceiveStatusBlock?
    
    public init(iin: String, applicationid: String) {
        self.iin = iin
        self.applicationid = applicationid
    }

    // There will be a closure to listen when there's a presence
    
    // TODO: Move publish and subscribe key to a constant / init functions
    public func start(qrcode: POQrcodeImage) {
        let configuration = PNConfiguration(publishKey: "sub-c-91489692-fa26-11e9-be22-ea7c5aada356", subscribeKey: "sub-c-91489692-fa26-11e9-be22-ea7c5aada356")
        self.client = PubNub.clientWithConfiguration(configuration)
        self.client.addListener(self)
        self.client.subscribeToChannels(["uuid-" + qrcode.mcid + "-" + qrcode.uuid], withPresence: false)
    }
}

extension POManager: PNObjectEventListener {
    // Handle a new message from a subscribed channel
    public func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        // Reference to the channel group containing the chat the message was sent to
        print("\(message.data.publisher) sent message to '\(message.data.channel)' at \(message.data.timetoken): \(message.data.message)")
        if let closure = onReceivedMessage {
            closure(message)
        }
    }
      
    // Handle a subscription status change
    public func client(_ client: PubNub, didReceive status: PNStatus) {
      if let closure = onReceivedStatus {
          closure(status)
      }
    }
     
    // Handle a new presence event
    public func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
          
        // Handle presence event event.data.presenceEvent (one of: join, leave, timeout, state-change).
        if event.data.channel != event.data.subscription {
              
            // Presence event received on a channel group stored in event.data.subscription
        }
        else {
              
            // Presence event received on a channel stored in event.data.channel
        }
          
        if event.data.presenceEvent != "state-change" {
              
            print("\(event.data.presence.uuid) \"\(event.data.presenceEvent)'ed\"\n" +
                  "at: \(event.data.presence.timetoken) on \(event.data.channel) " +
                  "(Occupancy: \(event.data.presence.occupancy))");
        }
        else {
              
            print("\(event.data.presence.uuid) changed state at: " +
                  "\(event.data.presence.timetoken) on \(event.data.channel) to:\n" +
                  "\(event.data.presence.state)");
        }
    }
     
    // Handle a new signal from a subscribed channel
    public func client(_ client: PubNub, didReceiveSignal signal: PNSignalResult) {
        print("\(signal) sent signal to")
    }

    // Handle a new user event (update or delete) from a subscribed user channel
    public func client(_ client: PubNub, didReceiveUserEvent event: PNUserEventResult) {
        print("'\(event.data.identifier)' user has been \(event.data.event)'ed at \(event.data.timestamp)")
    }

    // Handle a new space event (update or delete) from a subscribed space channel
    public func client(_ client: PubNub, didReceiveSpaceEvent event: PNSpaceEventResult) {
        print("'\(event.data.identifier)' space has been \(event.data.event)'ed at \(event.data.timestamp)")
    }

    // Handle a new membership event from a subscribed user or space channel
    public func client(_ client: PubNub, didReceiveMembershipEvent event: PNMembershipEventResult) {
        print("Membership between '\(event.data.userId)' user '\(event.data.spaceId)' space has been \(event.data.event)'ed at \(event.data.timestamp)")
    }

    // Handle message actions (added or removed) from one of channels on which client has been subscribed.
    public func client(_ client: PubNub, didReceiveMessageAction action: PNUserEventResult) {
        print("'\(action.data) action with")
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
