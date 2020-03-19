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
        let agencyStore = POStore(mcid: "mch5e436d803c35d", country: "LA", province: "VTE")
        let transaction: POTransaction = POTransaction.createUniqueTransaction(amount: 1, currency: POCurrencyCode.LAK)
        if let qrcodeValue: POQrcodeImage = POQrcodeGenerator.getQRCodeInfo(store: agencyStore, transaction: transaction) {
            qrcodeImageView?.image = generateQRCode(from: qrcodeValue.info)
            POManager.shared.start(qrcode: qrcodeValue)
            
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

