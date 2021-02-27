//
//  File.swift
//  
//
//  Created by Simone Deriu on 27/02/2021.
//
import Vapor

extension Application {

    public struct PayPalConfiguration{
        var client: String
        var secret: String
        var env: PayPal.Environment
        var url: String
        
        public init(client: String, secret: String, env: PayPal.Environment) {
            self.client = client
            self.secret = secret
            self.env = env
            self.url = env.rawValue
        }
    }
    
    public struct PayPalConfigurationKey: StorageKey {
        public typealias Value = PayPalConfiguration
    }
    
    public var paypal: PayPalConfiguration {
        get {
            guard let key = self.storage[PayPalConfigurationKey.self] else{
                fatalError("Paypal credentials missing")
            }
            return key
        }
        set {
            self.storage[PayPalConfigurationKey.self] = newValue
        }
    }
}

