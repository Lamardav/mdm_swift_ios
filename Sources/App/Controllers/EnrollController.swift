import Vapor

final class EnrollController: RouteCollection {
    static let enrollConfigPath = "./Resources/Certs/enroll.mobileconfig";
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("enroll", use: enrollHandler)
    }

    @Sendable
    func enrollHandler(req: Request) async throws -> Response {
        guard let fileData = FileManager.default.contents(atPath: EnrollController.enrollConfigPath) else {
            throw Abort(.notFound)
        }
        
        return Response(status: .ok, headers: ["Content-Type": "application/x-apple-aspen-config"], body: .init(data: fileData))
    }
}

extension EnrollController: Sendable {}
