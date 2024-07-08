import Vapor

final class DeviceCheckInController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.put("checkin", use: checkInHandler)
    }

    @Sendable
    func checkInHandler(req: Request) async throws -> HTTPStatus {
        print("req \(req)")
        guard let body = req.body.data else {
            throw Abort(.badRequest, reason: "Request body is missing")
        }
        
        let decoder = PropertyListDecoder()
        let data = Data(buffer: body)
        let customPreferences = try decoder.decode(DeviceCheckIn.self, from: data)
        try saveCustomPreferences(customPreferences)

        return .ok
    }
    
    private func saveCustomPreferences(_ customPreferences: DeviceCheckIn) throws {
        let filePath = "./device.plist"
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let encodedData = try encoder.encode(customPreferences)
        try encodedData.write(to: URL(fileURLWithPath: filePath))
    }
}

extension DeviceCheckInController: Sendable {}

