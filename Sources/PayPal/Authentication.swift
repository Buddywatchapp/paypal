//
//  File.swift
//  
//
//  Created by Simone Deriu on 27/02/2021.
//
import Vapor

public class Authentication{
    
    var request: Request
    
    public init(_ req: Request) {
        self.request = req
    }
    
    func token() throws -> EventLoopFuture<PayPal.Auth>{
        let url = URI(string: "\(self.request.application.paypal.url)\(Endpoints.authentication.rawValue)")
        return self.request.client.post(url, headers: self.request.headers) { (req) in
            req.headers.add(name: .contentType, value: "application/x-www-form-urlencoded")
            try req.content.encode(["grant_type":"client_credentials"])
        }.flatMapThrowing{ response in
            guard response.status == .ok else {
                self.request.logger.debug("\(response.content)")
                throw Abort(response.status)
            }
            return try response.content.decode(PayPal.Auth.self)
        }
    }
    
}

