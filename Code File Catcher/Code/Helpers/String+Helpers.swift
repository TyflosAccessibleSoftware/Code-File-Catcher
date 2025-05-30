import Foundation

extension String {
    var localized: String {
        get {
            NSLocalizedString(self, comment: "")
        }
    }
    
    func localizedWith(_ arguments: Any...) -> String {
        return String(format: self.localized, arguments: arguments.map { "\($0)" })
    }
    
    var withDotPrefix: String {
        hasPrefix(".") ? self : "." + self
    }
}
