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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        if let manager = POManager(mcid: "mch5e436d803c35d") {
            let transaction: POTransaction = POTransaction.createUniqueTransaction(amount: 1, currency: POCurrencyCode.LAK)
            let qrcodeValue = manager.getQRCodeInfo(transaction: transaction)
            print("Generated QRCode for a payment of 1LAK : \(qrcodeValue)")
        }
    }
}

