//
//  File.swift
//  
//
//  Created by Simone Deriu on 27/02/2021.
//

import Vapor

public class Payment{
 
    var request: Request
    
    public init(_ req: Request) {
        self.request = req
    }
    
    public func create(intent: String, redirect_urls: RedirectUrls, payer: Payer, transactions: [Transaction]) throws -> EventLoopFuture<PayPalPayment>{
        let url = URI(string: "\(self.request.application.paypal.url)\(Endpoints.payment.rawValue)")
        let auth = Authentication(self.request)
        return try auth.token().flatMap{ token in
            let t = "Bearer \(token.access_token)"
            self.request.headers.add(name: .authorization, value: t)
            let p = PayPalPayment(intent: intent,
                                  redirect_urls: redirect_urls,
                                  payer: payer,
                                  transactions: transactions,
                                  context: Context())
            return self.request.client.post(url, headers: self.request.headers) { (request) in
                try request.content.encode(p)
            }.flatMapThrowing{ response in
                guard response.status == .ok else {
                    self.request.logger.debug("\(response.content)")
                    throw Abort(response.status)
                }
                return try response.content.decode(PayPalPayment.self)
            }
        }
    }
    
    public func execute(payment_id: String, payer_id: String) throws -> EventLoopFuture<PayPalPayment>{
        let url = URI(string: "\(self.request.application.paypal.url)\(Endpoints.payment.rawValue)/\(payment_id)/execute")
        let auth = Authentication(self.request)
        return try auth.token().flatMap{ token in
            let t = "Bearer \(token.access_token)"
            self.request.headers.add(name: .authorization, value: t)
            let p = ExecutePayment(payer_id: payer_id)
            return self.request.client.post(url, headers: self.request.headers) { (request) in
                try request.content.encode(p)
            }.flatMapThrowing{ response in
                guard response.status == .ok else {
                    self.request.logger.debug("\(response.content)")
                    throw Abort(response.status)
                }
                return try response.content.decode(PayPalPayment.self)
            }
        }
    }
}

// MARK: - Payment
public struct PayPalPayment: Content {
    let id: String?
    let intent: String
    let redirect_urls: RedirectUrls
    let payer: Payer
    let transactions: [Transaction]
    let context: Context
    let state: String?
    let shipping_address: ShippingAddress?
    
    init(id: String? = nil, intent: String, redirect_urls: RedirectUrls, payer: Payer, transactions: [Transaction], context: Context, state: String? = nil, shipping_address: ShippingAddress? = nil) {
        self.id = id
        self.intent = intent
        self.redirect_urls = redirect_urls
        self.payer = payer
        self.transactions = transactions
        self.context = context
        self.state = state
        self.shipping_address = shipping_address
    }
}

public struct ExecutePayment: Content{
    let payer_id: String
}

// MARK: - ShippingAddress
public struct ShippingAddress: Content {
    let recipient_name, line1, line2, city, state: String?
    let postal_code, country_code: String?
}

// MARK: - Context
public struct Context: Content {
    var user_action = "commit"
}

// MARK: - Payer
public struct Payer: Content {
    var payment_method = "paypal"
}

// MARK: - RedirectUrls
public struct RedirectUrls: Content {
    let return_url, cancel_url: String?
}

// MARK: - Transaction
public struct Transaction: Content {
    let amount: Amount
    let transaction_description: String?
    let item_list: ItemList
}

// MARK: - Amount
public struct Amount: Content {
    let total, currency: String?
    let details: Details?
}

// MARK: - Details
public struct Details: Content {
    let subtotal, tax, shipping, handling_fee: String?
    let insurance, shipping_discount: String?
}

// MARK: - ItemList
public struct ItemList: Content {
    let items: [Item]
}

// MARK: - Item
public struct Item: Content {
    let name, sku, price, currency: String?
    let quantity, item_description, tax: String?
}

