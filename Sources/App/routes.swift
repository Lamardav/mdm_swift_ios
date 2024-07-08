import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.put("action") { req in
        print("req \(req)")
        let flagFilePath = "action_executed.flag"
        let fileManager = FileManager.default

        // Check if the flag file exists
        if fileManager.fileExists(atPath: flagFilePath) {
            return "error"
        } else {
            fileManager.createFile(atPath: flagFilePath, contents: nil, attributes: nil)
          

            let response = """
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>Command</key>
                    <dict>
                        <key>Identifier</key>
                        <string>com.apple.mgmt.External.8aa6060a-d07b-483d-9509-6aaab021cb75</string>
                        <key>RequestType</key>
                        <string>RemoveProfile</string>
                    </dict>
                    <key>CommandUUID</key>
                    <string>d8dcd9a2-67ef-4f5e-9f4b-7f8a9d01b024</string>
                </dict>
                </plist>
                """

            return response
        }
    }
    
    try app.register(collection: EnrollController())
    try app.register(collection: DeviceCheckInController())
    try app.register(collection: MagicPushController())
}
