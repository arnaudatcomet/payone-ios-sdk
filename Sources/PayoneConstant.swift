//
//  PayoneConstant.swift
//  BCEL-QRCode
//
//  Created by Arnaud Phommasone on 3/7/20.
//  Copyright © 2020 Arnaud Phommasone. All rights reserved.
//

import Foundation

public enum POCurrencyCode: Int {
    case LAK = 418
    case USD = 480
    case THB = 764
    case CNY = 156
}

public enum POtatusCategory: Int {
    case POUnknownCategory = 0
    case POAcknowledgmentCategory
    case POAccessDeniedCategory
    case POTimeoutCategory
    case PONetworkIssuesCategory
    case PORequestMessageCountExceededCategory
    case POConnectedCategory
    case POReconnectedCategory
    case PODisconnectedCategory
    case POUnexpectedDisconnectCategory
    case POCancelledCategory
    case POBadRequestCategory
    case PORequestURITooLongCategory
    case POMalformedFilterExpressionCategory
    case POMalformedResponseCategory
    case PODecryptionErrorCategory
    case POTLSConnectionFailedCategory
    case POTLSUntrustedCertificateCategory
}
