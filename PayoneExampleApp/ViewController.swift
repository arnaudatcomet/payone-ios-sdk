//
//  ViewController.swift
//  PayOneExampleApp
//
//  Created by Arnaud Phommasone on 3/15/20.
//  Copyright © 2020 Comet Digital Agency. All rights reserved.
//

import UIKit
import PayOneSDK

class ViewController: UIViewController {
    @IBOutlet weak var qrcodeImageView: UIImageView?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var responseLabel: UILabel?
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Create a store
        let store = POStore(mcid: "mch5e436d803c35d", country: "LA", province: "VTE")
        
        // Create a transaction
        var transaction: POTransaction = POTransaction.createUniqueTransaction(amount: 1, currency: POCurrencyCode.LAK, description: "A call from PayOneSDK iOS")
        
        // Manually set the invoice ID as it's non mandatory
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
        transaction.invoiceid = "#INVOICE"+dateFormatterGet.string(from: Date())
        
        // Generate the qrcode raw value
        if let qrcodeValue: POQrcodeImage = POQrcodeGenerator.getQRCodeInfo(store: store, transaction: transaction) {
            // Set into a QRCode image
            qrcodeImageView?.image = generateQRCode(from: qrcodeValue.info)
            
            // Start listening to payment
            POManager.shared.start(qrcode: qrcodeValue)
            
            // Check if socket is connected to payment gateways
            POManager.shared.onReceivedStatus = { status in
                print("status has change \(status)")
                if status.operation == .subscribeOperation {
                    // Check to see if the message is about a successful subscription or restore
                    if status.category == .PNConnectedCategory || status.category == .PNReconnectedCategory {
                        let subscribeStatus: POSubscribeStatus = status as! POSubscribeStatus
                        if subscribeStatus.category == .PNConnectedCategory {
                              
                            // For a subscribe, this is expected, and means there are no errors or issues
                            DispatchQueue.main.async {
                                self.statusLabel?.text = "OK Connected"
                            }
                        }
                    }
                }
            }
            
            // Check if received message from socket
            POManager.shared.onReceivedMessage = { message in
                let subscription = message.data.subscription
                print("\(message.data.publisher) sent message to '\(message.data.channel)' at \(message.data.timetoken): \(message.data.message)")
                
                DispatchQueue.main.async {
                    self.responseLabel?.text = "\(message.data.message)"
                }
            }
        }
    }
}

