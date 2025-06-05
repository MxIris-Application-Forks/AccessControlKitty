import Foundation
import SwiftSyntax

public enum AccessChange {
    case singleLevel(Access)
    case increaseAccess
    case decreaseAccess
    case makeAPI
    case removeAPI
}

public enum Access: String {
    case `public`
    case `private`
    case `internal`
    case `fileprivate`
    case remove = ""
    case open
    case package
    
    
    static var allKeywords: [Keyword] {
        [.public, .private, .internal, .fileprivate, .open, .package]
    }
    
    var keyword: Keyword? {
        switch self {
        case .public:
            return .public
        case .private:
            return .private
        case .internal:
            return .internal
        case .fileprivate:
            return .fileprivate
        case .remove:
            return nil
        case .open:
            return .open
        case .package:
            return .package
        }
    }
}

extension Access: Comparable {
    public static func < (_ lhs: Access, _ rhs: Access) -> Bool {
        return lhs.order < rhs.order
    }

    var order: Int {
        switch self {
        case .private: return -2
        case .fileprivate: return -1
        case .internal: return 0
        case .remove: return 0
        case .public: return 1
        case .open: return 2
        case .package: return 3
        }
    }
}
