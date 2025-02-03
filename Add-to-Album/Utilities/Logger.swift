import Foundation

class Logger {
    static func log(_ message: String) {
        print("[\(Date())] \(message)")
    }
}
