import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }.description("says hello")
    
    app.get("hello", "vapor") { req async -> String in
        "Hello, vapor!"
    }
    
    app.get("hello", ":name") { req async -> String in
        let name = req.parameters.get("name")!
        return "Hello, \(name)"
    }
    
    app.get("number", ":x") { req -> String in
        guard let int = req.parameters.get("x", as: Int.self) else {
            throw Abort(.badRequest)
        }
        return "\(int) is a great number"
    }
}
