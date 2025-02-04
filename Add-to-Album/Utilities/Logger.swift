import Foundation

class Logger {
    static func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"  // ✅ Show only hours, minutes, seconds
        let timeString = formatter.string(from: Date())
        
        print("[\(timeString)] \(message)")
    }
}
