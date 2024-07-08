import Vapor

struct DeviceCheckIn: Content {
    var MessageType: String
    var Topic: String
    var UDID: String
    var AwaitingConfiguration: Bool?
    var PushMagic: String?
    var Token: Data?
    var UnlockToken: Data?
}

//extension DeviceCheckIn {
//    var base64Token: String? {
//        return Token?.base64EncodedString()
//    }
//    
//    var hexToken: String? {
//        return Token?.map { String(format: "%02hhx", $0) }.joined()
//    }
//    
//    var base64UnlockToken: String? {
//        return UnlockToken?.base64EncodedString()
//    }
//    
//    var hexUnlockToken: String? {
//        return UnlockToken?.map { String(format: "%02hhx", $0) }.joined()
//    }
//}
