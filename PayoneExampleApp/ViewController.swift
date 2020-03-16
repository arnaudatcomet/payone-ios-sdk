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
    
        if let manager = PayoneManager(mcid: "mch5e436d803c35d") {
            let transaction: PayoneTransaction = PayoneTransaction.createUniqueTransaction(amount: 1, currency: PayoneCurrencyCode.LAK)
            let qrcodeValue = manager.getQRCodeInfo(transaction: transaction)
            print("Generated QRCode for a payment of 1LAK : \(qrcodeValue)")
        }
    }


}

