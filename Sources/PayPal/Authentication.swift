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
        return self.request.client.post(url, headers: self.request.headers) { (request) in
            try request.content.encode(GrantType())
        }.flatMapThrowing{ response in
            guard response.status == .ok else {
                self.request.logger.debug("\(response.content)")
                throw Abort(response.status)
            }
            return try response.content.decode(PayPal.Auth.self)
        }
    }
    
}

struct GrantType: Content{
    var grant_type = "client_credentials"
}
