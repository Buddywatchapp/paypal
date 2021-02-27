//
//  File.swift
//  
//
//  Created by Simone Deriu on 27/02/2021.
//
import Vapor

extension Request{
    
    //MARK: - Wordpress
    public var paypal: PayPal{
        let cred = "\(self.application.paypal.client):\(self.application.paypal.secret)"
            .data(using: .utf8)?.base64EncodedString() ?? ""
        let auth = "Basic \(cred)"
        self.headers = HTTPHeaders([])
        self.headers.add(name: "Authorization", value: auth)
        return PayPal(self)
    }
    
}
