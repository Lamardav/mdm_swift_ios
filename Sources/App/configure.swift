import Vapor
import NIOSSL
import APNS
import VaporAPNS
import APNSCore


public func configure(_ app: Application) async throws {
    // Uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    let pemFile = "./Resources/Certs/PushCert.pem"
    let privateKeySource = NIOSSLPrivateKeySource.file(pemFile)
    let certificateSource =  NIOSSLCertificateSource.file(pemFile)
  
    let apnsConfig = APNSClientConfiguration(
        authenticationMethod: .tls(privateKey: privateKeySource, certificateChain: [certificateSource]),
        environment: .production
    )
    
    app.apns.containers.use(
        apnsConfig,
        eventLoopGroupProvider: .shared(app.eventLoopGroup),
        responseDecoder: JSONDecoder(),
        requestEncoder: JSONEncoder(),
        as: .default
    )
    
    try configureTLS(app)
    
    // Register routes
    try routes(app)
}

func loadTLSCertificate() throws -> NIOSSLCertificate {
    let certificatePath = "./Resources/Certs/Server.crt"
    let certificateData = try Data(contentsOf: URL(fileURLWithPath: certificatePath))
    let certificateBytes = [UInt8](certificateData)
    return try NIOSSLCertificate(bytes: certificateBytes, format: .pem)
}

func loadTLSPrivateKey() throws -> NIOSSLPrivateKey {
    let privateKeyPath = "./Resources/Certs/Server.key"
    let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))
    let privateKeyBytes = [UInt8](privateKeyData)
    return try NIOSSLPrivateKey(bytes: privateKeyBytes, format: .pem)
}

func configureTLS(_ app: Application) throws {
    let certificate = try loadTLSCertificate()
    let privateKey = try loadTLSPrivateKey()
    
    app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
        certificateChain: [.certificate(certificate)],
        privateKey: .privateKey(privateKey)
    )
}
