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
    
    public func create(intent: String, redirect_urls: RedirectUrls, payer: Payer, transactions: [Transaction]) throws -> EventLoopFuture<PayPalResponse>{
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
            return self.request.client.post(url, headers: self.request.headers) { (req) in
                try req.content.encode(p)
            }.flatMapThrowing{ response in
                guard response.status == .created else {
                    self.request.logger.debug("\(response.content)")
                    throw Abort(response.status, reason: "\(response.content)")
                }
                return try response.content.decode(PayPalResponse.self)
            }
        }
    }
    
    public func execute(payment_id: String, payer_id: String) throws -> EventLoopFuture<PayPalResponse>{
        let url = URI(string: "\(self.request.application.paypal.url)\(Endpoints.payment.rawValue)/\(payment_id)/execute")
        let auth = Authentication(self.request)
        return try auth.token().flatMap{ token in
            let t = "Bearer \(token.access_token)"
            self.request.headers.add(name: .authorization, value: t)
            let p = ExecutePayment(payer_id: payer_id)
            return self.request.client.post(url, headers: self.request.headers) { (req) in
                try req.content.encode(p)
            }.flatMapThrowing{ response in
                guard response.status == .ok else {
                    self.request.logger.debug("\(response.content)")
                    throw Abort(response.status, reason: "\(response.content)")
                }
                return try response.content.decode(PayPalResponse.self)
            }
        }
    }
}

public struct PayPalResponse: Content{
    public let id: String?
    public let redirect_urls: RedirectUrls?
    public let shipping_address: ShippingAddress?
    public let links: [Link]?
}


// MARK: - Payment
public struct PayPalPayment: Content {
    public let id: String?
    public let intent: String?
    public let redirect_urls: RedirectUrls?
    public let payer: Payer?
    public let transactions: [Transaction]?
    public let application_context: Context?
    public let state: String?
    public let links: [Link]?
    
    public init(id: String? = nil, intent: String, redirect_urls: RedirectUrls, payer: Payer, transactions: [Transaction], context: Context, state: String? = nil, links: [Link]? = nil) {
        self.id = id
        self.intent = intent
        self.redirect_urls = redirect_urls
        self.payer = payer
        self.transactions = transactions
        self.application_context = context
        self.state = state
        self.links = links
    }
}

public struct Link: Content{
    public let href: String
    public let rel: String
}

public struct ExecutePayment: Content{
    public let payer_id: String
    
    public init(payer_id: String){
        self.payer_id = payer_id
    }
}

// MARK: - ShippingAddress
public struct ShippingAddress: Content {
    public let recipient_name, line1, line2, city, state: String?
    public let postal_code, country_code: String?
}

// MARK: - Context
public struct Context: Content {
    public var user_action = "commit"
}

// MARK: - Payer
public struct Payer: Content {
    public var payment_method = "paypal"
    
    public init(){}
}

// MARK: - RedirectUrls
public struct RedirectUrls: Content {
    public let return_url, cancel_url: String
    
    public init(return_url: String, cancel_url: String){
        self.return_url = return_url
        self.cancel_url = cancel_url
    }
}

// MARK: - Transaction
public struct Transaction: Content {
    public let amount: Amount
    public let transaction_description: String?
    public let item_list: ItemList
    
    public init(amount: Amount, transaction_description: String? = nil, item_list: ItemList){
        self.amount = amount
        self.transaction_description = transaction_description
        self.item_list = item_list
    }
}

// MARK: - Amount
public struct Amount: Content {
    public let total, currency: String
    public let details: Details
    
    public init(total: String, currency: String, details: Details){
        self.total = total
        self.currency = currency
        self.details = details
    }
    
}

// MARK: - Details
public struct Details: Content {
    public let subtotal, tax, shipping, handling_fee: String?
    public let insurance, shipping_discount: String?
    
    public init(subtotal: String, tax: String, shipping: String? = nil, handling_fee: String? = nil, insurance: String? = nil, shipping_discount: String? = nil){
        self.subtotal = subtotal
        self.tax = tax
        self.shipping = shipping
        self.handling_fee = handling_fee
        self.insurance = insurance
        self.shipping_discount = shipping_discount
    }
}

// MARK: - ItemList
public struct ItemList: Content {
    public let items: [Item]
    public let shipping_address: ShippingAddress?
    
    public init(items: [Item], shipping_address: ShippingAddress? = nil){
        self.items = items
        self.shipping_address = shipping_address
    }
}

// MARK: - Item
public struct Item: Content {
    public let name, sku, price, currency: String?
    public let quantity, item_description, tax: String?
    
    public init(name: String, sku: String? = nil, price: String, currency: String, quantity: String, item_description: String? = nil, tax: String? = nil){
        self.name = name
        self.sku = sku
        self.price = price
        self.currency = currency
        self.quantity = quantity
        self.item_description = item_description
        self.tax = tax
    }
}

