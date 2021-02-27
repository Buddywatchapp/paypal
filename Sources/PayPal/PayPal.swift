
import Vapor
public class PayPal{
    
    public var authentication: Authentication
    public var payment: Payment
    
    init(_ req: Request) {
        self.authentication = Authentication(req)
        self.payment = Payment(req)
    }

    struct Auth: Content {
        let scope: String
        let access_token, token_type, app_id: String
        let expires_in: Int
        let nonce: String
    }
    
    public enum Environment: String{
        case sandbox = "https://api.sandbox.paypal.com"
        case live = "https://api.paypal.com"
    }
}
