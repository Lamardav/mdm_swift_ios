import Vapor
import APNS
import VaporAPNS
import APNSCore

struct Payload: Codable {
    let mdm: String
}

final class MagicPushController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("magic", use: sendPushMagic)
    }
    
    @Sendable
    func sendPushMagic(req: Request) async throws -> Response {
        let plistPath = "./device.plist"
                
        guard let plistData = FileManager.default.contents(atPath: plistPath) else {
            throw Abort(.internalServerError, reason: "Failed to read device.plist")
        }
        
        let decoder = PropertyListDecoder()
        let deviceCheckIn = try decoder.decode(DeviceCheckIn.self, from: plistData)
        guard let deviceTokenData = deviceCheckIn.Token else {
           throw Abort(.internalServerError, reason: "Token is nil")
        }
        
        let deviceTokenHex = deviceTokenData.map { String(format: "%02x", $0) }.joined()
    
        let magicToken = deviceCheckIn.PushMagic
        let topic = deviceCheckIn.Topic
        
        let payload = Payload(mdm: magicToken!)
        let alert = APNSAlertNotification(
            alert: .init(
                title: .raw("Hello")
            ),
            expiration: .immediately,
            priority: .immediately,
            topic: topic,
            payload: payload
        )
        try await req.apns.client.sendAlertNotification(
            alert,
            deviceToken: deviceTokenHex
        )
        
        return Response(status: .ok)
    }
}

extension MagicPushController: Sendable {}

