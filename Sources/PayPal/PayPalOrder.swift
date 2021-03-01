//
//  File.swift
//  
//
//  Created by Simone Deriu on 27/02/2021.
//

import Vapor

public class PayPalOrder{
 
    var request: Request
    
    public init(_ req: Request) {
        self.request = req
    }
    
    public func create(intent: String, purchase_units: [PurchaseUnit], items: [Item], application_context: ApplicationContext) throws -> EventLoopFuture<PayPalResponse>{
        let url = URI(string: "\(self.request.application.paypal.url)\(Endpoints.orders.rawValue)")
        let auth = Authentication(self.request)
        return try auth.token().flatMap{ token in
            let t = "Bearer \(token.access_token)"
            self.request.headers.add(name: .authorization, value: t)
            let p = Order(intent: intent,
                          purchase_units: purchase_units,
                          items: items,
                          application_context: application_context)
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
    
    public func capture(payment_id: String, payer_id: String) throws -> EventLoopFuture<PayPalResponse>{
        let url = URI(string: "\(self.request.application.paypal.url)\(Endpoints.orders.rawValue)/\(payment_id)/capture")
        let auth = Authentication(self.request)
        return try auth.token().flatMap{ token in
            let t = "Bearer \(token.access_token)"
            self.request.headers.add(name: .authorization, value: t)
            return self.request.client.post(url, headers: self.request.headers).flatMapThrowing{ response in
                guard response.status == .ok else {
                    self.request.logger.debug("\(response.content)")
                    throw Abort(response.status, reason: "\(response.content)")
                }
                return try response.content.decode(PayPalResponse.self)
            }
        }
    }
}


public struct Order: Content{
    public let intent: String
    public let purchase_units: [PurchaseUnit]
    public let items: [Item]
    public let application_context: ApplicationContext
    
    public init(intent: String, purchase_units: [PurchaseUnit], items: [Item], application_context: ApplicationContext) {
        self.intent = intent
        self.purchase_units = purchase_units
        self.items = items
        self.application_context = application_context
    }
}

public struct PurchaseUnit: Content{
    public let amount_breakdown: Amount
    
    public init(amount_breakdown: Amount){
        self.amount_breakdown = amount_breakdown
    }
}

public struct Amount: Content {
    public let item_total: Money
    public let discount: Money
    
    public init(item_total: Money, discount: Money){
        self.item_total = item_total
        self.discount = discount
    }
}

public struct Money: Content {
    public let currency_code: String
    public let value: String
    
    public init(currency_code: String, value: String){
        self.currency_code = currency_code
        self.value = value
    }
}

public struct Item: Content{
    public let name: String
    public let unit_amount: Money
    public let quantity: String
    
    public init(name: String, unit_amount: Money, quantity: String){
        self.name = name
        self.unit_amount = unit_amount
        self.quantity = quantity
    }
}

public struct ApplicationContext: Content{
    public let user_action: String?
    public let return_url: String
    public let cancel_url: String
    
    public init(user_action: String? = "PAY_NOW", return_url: String, cancel_url: String){
        self.user_action = user_action
        self.return_url = return_url
        self.cancel_url = cancel_url
    }
}

//MARK: - Response

public struct PayPalResponse: Content{
    public let id: String
    public let status: String
    public let links: [Link]
    public let purchase_units: [PurchaseUnitResponse]
}

public struct Link: Content{
    public let href: String
    public let rel: String
}

public struct PurchaseUnitResponse: Content {
    let shipping: Shipping?
}

// MARK: - Shipping
public struct Shipping: Content{
    let address: Address?
}

// MARK: - Address
public struct Address: Content{
    let addressLine1, addressLine2, adminArea2, adminArea1: String?
    let postalCode, countryCode: String?
}
