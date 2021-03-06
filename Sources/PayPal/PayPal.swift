
import Vapor
public class PayPal{
    
    public var authentication: Authentication
    public var order: PayPalOrder
    
    init(_ req: Request) {
        self.authentication = Authentication(req)
        self.order = PayPalOrder(req)
    }

    struct Auth: Content {
        let scope: String
        let access_token, token_type, app_id: String
        let expires_in: Int
        let nonce: String
    }
    
    public enum Environment: String{
        case sandbox = "https://api-m.sandbox.paypal.com"
        case live = "https://api-m.paypal.com"
    }
}
